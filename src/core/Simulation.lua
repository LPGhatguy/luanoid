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

local Simulation = {}
Simulation.__index = Simulation

function Simulation.new(character)
	local simulation = {
		character = character,
		accumulatedTime = 0,
		currentAccelerationX = 0,
		currentAccelerationY = 0,
	}

	setmetatable(simulation, Simulation)

	return simulation
end

function Simulation:step(dt, inputX, inputY, inputJump)
	local characterMass = getModelMass(self.character.instance)
	local onGround = isOnGround(self.character.instance)

	local targetX = TARGET_SPEED * inputX
	local targetY = TARGET_SPEED * inputY

	self.accumulatedTime = self.accumulatedTime + dt

	local currentX = self.character.instance.PrimaryPart.Velocity.X
	local currentY = self.character.instance.PrimaryPart.Velocity.Z

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