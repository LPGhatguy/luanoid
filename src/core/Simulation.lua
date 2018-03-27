local Workspace = game:GetService("Workspace")

local stepSpring = require(script.Parent.stepSpring)
local getModelMass = require(script.Parent.getModelMass)

local TARGET_SPEED = 24
local FRAMERATE = 1 / 240
local STIFFNESS = 170
local DAMPING = 26
local PRECISION = 0.001
local GROUND_TOLERANCE = 0.15

local function isOnGround(characterInstance)
	local startPos = characterInstance.PrimaryPart.Position
	local offset = -Vector3.new(0, (characterInstance.PrimaryPart.Size.X / 2) + 1.5 + GROUND_TOLERANCE, 0)

	local ray = Ray.new(startPos, offset)
	local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {characterInstance})

	return not not hit
end

-- TODO: more appropriate cast distribution algorithm
-- https://stackoverflow.com/a/28572551/367100
function radius(k,n,b)
	if k > n - b then
		return 1 -- put on the boundary
	else
		return math.sqrt(k - 1/2)/math.sqrt(n - (b + 1)/2) -- apply square root
	end
end
function sunflower(n, alpha) --  example: n=500, alpha=2
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

function createHandles(n)
	local handles = {}
	for i = 1, n do
		local adorn = Instance.new("BoxHandleAdornment")
		adorn.Size = Vector3.new(0.5, 0.5, 0.5)
		adorn.Adornee = workspace.Terrain
		adorn.Parent = workspace.Terrain
		handles[i] = adorn
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
	local start = self.character.instance.PrimaryPart.CFrame

	for i, x, z in sunflower(self.castCount, 2) do
		local p = start.p + Vector3.new(x*radius, 0, z*radius)
		local ray = Ray.new(p, vector)
		local part, point, normal = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
		adorns[i].CFrame = CFrame.new(point)
		print(i)
	end
end

function Simulation:step(dt, inputX, inputY, inputJump)
	local characterMass = getModelMass(self.character.instance)
	local onGround = isOnGround(self.character.instance)

	local targetX = TARGET_SPEED * inputX
	local targetY = TARGET_SPEED * inputY

	self.accumulatedTime = self.accumulatedTime + dt

	local currentX = self.character.instance.PrimaryPart.Velocity.X
	local currentY = self.character.instance.PrimaryPart.Velocity.Z

	self:castCylinder(Vector3.new(0, -5, 0))

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
	self.character.instance.BottomSphere.Color = bottomColor

	if onGround then
		local up
		if inputJump then
			up = 5000 * characterMass
		else
			up = 0
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
	local speed = velocity.Magnitude

	self.character.targetOrientPart.CFrame = CFrame.new(self.character.instance.PrimaryPart.Position + velocity / 3)

	if speed > 0.1 then
		local velocityRot = CFrame.new(Vector3.new(), velocity)
		self.character.avatarRoot.CFrame = velocityRot + self.character.avatarRoot.Position
	end
end

return Simulation