local Workspace = game:GetService("Workspace")

local stepSpring = require(script.Parent.stepSpring)
local getModelMass = require(script.Parent.getModelMass)
local DebugHandle = require(script.Parent.DebugHandle)

local TARGET_SPEED = 24
local FRAMERATE = 1 / 240
local STIFFNESS = 170
local DAMPING = 26
local PRECISION = 0.001

-- TODO: more appropriate cast distribution algorithm
-- https://stackoverflow.com/a/28572551/367100
local function radius(k,n,b)
	if k > n - b then
		return 1 -- put on the boundary
	else
		return math.sqrt(k - 1/2)/math.sqrt(n - (b + 1)/2) -- apply square root
	end
end

local function sunflower(n, alpha) --  example: n=500, alpha=2
	local b = math.ceil(alpha*math.sqrt(n)) -- number of boundary points
	local phi = (math.sqrt(5) + 1)/2 -- golden ratio
	local i = 1
	return function()
		if i <= n then
			i = i + 1
			local r = radius(i, n, b)
			local theta = 2*math.pi*i/(phi*phi)
			return i - 1, r*math.cos(theta), r*math.sin(theta)
		end
		return
	end
end

local function createHandles(n)
	local handles = {}
	for i = 1, n do
		handles[i] = DebugHandle.new()
	end
	return handles
end

local Simulation = {}
Simulation.__index = Simulation

function Simulation.new(character)
	local castCount = 32
	local simulation = {
		character = character,
		accumulatedTime = 0,
		currentAccelerationX = 0,
		currentAccelerationY = 0,
		castCount = castCount,
		adorns = createHandles(castCount),
		ignoreList = character.instance:GetDescendants(),
		maxHorAccel = TARGET_SPEED / 0.25, -- velocity / time to reach it squared
		maxVerAccel = 50 / 0.1, -- massless max vertical force against gravity
		hipHeight = 3.5,
		popTime = 0.05, -- target time to reach target height
	}

	setmetatable(simulation, Simulation)

	return simulation
end

-- vector is direction + mag
function Simulation:castCylinder(vector)
	-- max len, min length
	-- update part points and part velocities
	local radius = 1.5
	local ignoreList = self.ignoreList
	local adorns = self.adorns
	local start = self.character.castPoint.WorldPosition
	local legLength = self.hipHeight

	local onGround = false
	local totalWeight = 0
	local totalHeight = 0
	for i, x, z in sunflower(self.castCount, 2) do
		local p = start + Vector3.new(x*radius, 0, z*radius)
		local ray = Ray.new(p, vector)
		local part, point, normal = Workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
		local hit = not not part
		local length = (point - p).Magnitude
		local legHit = length <= legLength + 0.25

		-- add to weighted average
		if hit then
			local weight = 1
			totalWeight = totalWeight + weight
			totalHeight = totalHeight + point.y
		end

		onGround = onGround or legHit

		local adorn = adorns[i]
		adorn:move(point)
		adorn.instance.Color3 = legHit and Color3.new(0, 1, 0) or (part and Color3.new(0, 1, 1) or Color3.new(1, 0, 0))
	end

	return onGround, totalHeight / totalWeight
end

function Simulation:step(dt, inputX, inputY, inputJump, inputRagdoll)
	local characterMass = getModelMass(self.character.instance)
	--local onGround = isOnGround(self.character.instance)

	local targetX = TARGET_SPEED * inputX
	local targetY = TARGET_SPEED * inputY

	self.accumulatedTime = self.accumulatedTime + dt

	local currentVelocity = self.character.instance.PrimaryPart.Velocity;
	local currentX = currentVelocity.X
	local currentY = currentVelocity.Z

	local onGround, groughtHeight = self:castCylinder(Vector3.new(0, -5, 0))
	local targetHeight = groughtHeight + self.hipHeight
	local currentHeight = self.character.castPoint.WorldPosition.Y

	while self.accumulatedTime >= FRAMERATE do
		self.accumulatedTime = self.accumulatedTime - FRAMERATE

		currentX, self.currentAccelerationX = stepSpring(
			FRAMERATE,
			currentX,
			self.currentAccelerationX,
			targetX,
			STIFFNESS,
			DAMPING,
			PRECISION
		)

		currentY, self.currentAccelerationY = stepSpring(
			FRAMERATE,
			currentY,
			self.currentAccelerationY,
			targetY,
			STIFFNESS,
			DAMPING,
			PRECISION
		)
	end

	local bottomColor = onGround and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
	self.character.instance.PrimaryPart.Color = bottomColor

	self.character.orientation.Enabled = not inputRagdoll

	if onGround and not inputRagdoll then
		local up = 0
		if inputJump then
			up = 5000 * characterMass
		else
			local t = self.popTime
			-- counter gravity and then solve constant acceleration eq (x1 = x0 + v*t + 0.5*a*t*t) for a to aproach target height over time
			up = workspace.gravity + 2*((targetHeight-currentHeight) - currentVelocity.Y*t)/(t*t)
			-- very low downward acceleration cuttoff (limited ability to push yourself down)
			if up < -1 then
				up = 0
			end
			up = up*characterMass
		end

		self.character.vectorForce.Force = Vector3.new(
			self.currentAccelerationX * characterMass,
			up,
			self.currentAccelerationY * characterMass
		)
	else
		self.character.vectorForce.Force = Vector3.new(0, 0, 0)
	end

	local velocity = Vector3.new(currentX, 0, currentY)

	self.character.orientationAttachment.Position = self.character.instance.PrimaryPart.Position + velocity
end

return Simulation