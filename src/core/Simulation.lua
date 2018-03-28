local Workspace = game:GetService("Workspace")

local stepSpring = require(script.Parent.stepSpring)
local getModelMass = require(script.Parent.getModelMass)
local DebugHandle = require(script.Parent.DebugHandle)

local TARGET_SPEED = 24
local FRAMERATE = 1 / 240
local STIFFNESS = 170
local DAMPING = 26
local PRECISION = 0.001
local PI = math.pi
local THETA = math.pi * 2

-- (1,0) = 0, (1, -1) = 5.4977871437821...
local function atan2(x, y)
	local atan = math.atan(y/x)
	if x < 0 then
		if atan > 0 then
			return atan - PI
		end
		return atan + PI
	end
	return atan
end

-- loop between 0 - 2*pi
local function angleAbs(angle)
	while angle < 0 do
		angle = angle + THETA
	end
	while angle > THETA do
		angle = angle - THETA
	end
	return angle
end

local function angleShortest(a0, a1)
	local d1 = angleAbs(a1 - a0)
	local d2 = -angleAbs(a0 - a1)
	return math.abs(d1) > math.abs(d2) and d2 or d1
end

local function lerpAngle(a0, a1, alpha)
	return a0 + angleShortest(a0, a1)*alpha
end

local function makeCFrame(up, look)
	local upu = up.Unit
	local looku = (Vector3.new() - look).Unit
	local rightu = upu:Cross(looku).Unit
	-- orthonormalize, keeping up vector
	looku = -upu:Cross(rightu).Unit
	return CFrame.new(0, 0, 0, rightu.x, upu.x, looku.x, rightu.y, upu.y, looku.y, rightu.z, upu.z, looku.z)
end

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
		maxHorAccel = TARGET_SPEED / 0.25, -- velocity / time to reach it squared
		maxVerAccel = 50 / 0.1, -- massless max vertical force against gravity
		hipHeight = 2.5,
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
	local start = self.character.castPoint.WorldPosition

	local onGround = false
	local totalWeight = 0
	local totalHeight = 0
	for i, x, z in sunflower(self.castCount, 2) do
		local p = start + Vector3.new(x*radius, 0, z*radius)
		local ray = Ray.new(p, vector)
		local part, point, normal = Workspace:FindPartOnRay(ray, self.character.instance)
		local length = (point - p).Magnitude
		local legHit = length <= self.hipHeight + 0.25

		-- add to weighted average
		if part then
			local weight = 1
			totalWeight = totalWeight + weight
			totalHeight = totalHeight + point.y
		end

		onGround = onGround or legHit

		local adorn = self.adorns[i]
		adorn:move(point)

		if legHit then
			adorn:setColor(Color3.new(0, 1, 0))
		elseif part then
			adorn:setColor(Color3.new(0, 1, 1))
		else
			adorn:setColor(Color3.new(1, 0, 0))
		end
	end

	return onGround, totalHeight / totalWeight
end

function Simulation:step(dt, input)
	local characterMass = getModelMass(self.character.instance)

	local targetX = TARGET_SPEED * input.movementX
	local targetY = TARGET_SPEED * input.movementY

	self.accumulatedTime = self.accumulatedTime + dt

	local currentVelocity = self.character.instance.PrimaryPart.Velocity;
	local currentX = currentVelocity.X
	local currentY = currentVelocity.Z

	local onGround, groundHeight = self:castCylinder(Vector3.new(0, -5, 0))
	local targetHeight = groundHeight + self.hipHeight
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

	self.character.orientation.Enabled = not input.ragdoll

	if onGround and not input.ragdoll then
		local up
		if input.jump then
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
	local lookVector = self.character.instance.PrimaryPart.CFrame.lookVector

	if velocity.Magnitude > 0.1 and lookVector.y < 0.9 then
		-- Fix "tumbling" where AlignOrientation might pick the "wrong" axis when we cross through 0, lerp angles...
		local currentAngle = atan2(lookVector.x, lookVector.z)
		local targetAngle = atan2(currentX, currentY)
		-- If we crossed through 0 (shortest arc angle is close to pi) then lerp the angle...
		if math.abs(angleShortest(currentAngle, targetAngle)) > math.pi*0.95 then
			targetAngle = lerpAngle(currentAngle, targetAngle, 0.95)
		end

		local up = Vector3.new(0, 1, 0)
		local look = Vector3.new(math.cos(targetAngle), 0, math.sin(targetAngle))
		self.character.orientationAttachment.CFrame = makeCFrame(up, look)
	end
end

return Simulation