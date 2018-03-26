local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local stepSpring = require(ReplicatedFirst.CharacterControllerCore.stepSpring)

local Input = require(script.Input)
local Api = require(script.Api)

while not Players.LocalPlayer do
	wait()
end

local TARGET_SPEED = 24
local FRAMERATE = 1 / 240
local STIFFNESS = 170
local DAMPING = 26
local PRECISION = 0.001
local GROUND_TOLERANCE = 0.15

local accumulatedTime = 0
local currentAccelerationX = 0
local currentAccelerationY = 0

local character = Api.requestMakeCharacter()

local function isOnGround(characterInstance)
	local startPos = characterInstance.PrimaryPart.Position
	local offset = -Vector3.new(0, (characterInstance.PrimaryPart.Size.X / 2) + 1.5 + GROUND_TOLERANCE, 0)

	local ray = Ray.new(startPos, offset)
	local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {characterInstance})

	return not not hit
end

local function getModelMass(model)
	local mass = 0

	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("BasePart") then
			mass = mass + child:GetMass()
		end
	end

	return mass
end

local function updateCharacter(character, inputX, inputY, dt)
	local characterMass = getModelMass(character.instance)
	local onGround = isOnGround(character.instance)

	local targetX = TARGET_SPEED * inputX
	local targetY = TARGET_SPEED * inputY

	accumulatedTime = accumulatedTime + dt

	local currentX = character.instance.PrimaryPart.Velocity.X
	local currentY = character.instance.PrimaryPart.Velocity.Z

	while accumulatedTime >= FRAMERATE do
		accumulatedTime = accumulatedTime - FRAMERATE

		currentX, currentAccelerationX = stepSpring(
			FRAMERATE,
			currentX,
			currentAccelerationX,
			targetX,
			STIFFNESS,
			DAMPING,
			PRECISION
		)

		currentY, currentAccelerationY = stepSpring(
			FRAMERATE,
			currentY,
			currentAccelerationY,
			targetY,
			STIFFNESS,
			DAMPING,
			PRECISION
		)
	end

	local bottomColor = onGround and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
	character.instance.BottomSphere.Color = bottomColor

	if onGround then
		local up
		if Input.keysDown[Enum.KeyCode.Space] then
			up = 5000 * characterMass
		else
			up = 0
		end

		character.vectorForce.Force = Vector3.new(
			currentAccelerationX * characterMass,
			up,
			currentAccelerationY * characterMass
		)
	else
		character.vectorForce.Force = Vector3.new(0, 0, 0)
	end

	local velocity = Vector3.new(currentX, 0, currentY)

	character.targetOrientPart.CFrame = CFrame.new(character.instance.PrimaryPart.Position + velocity / 3)
end

Workspace.CurrentCamera.CameraSubject = character.instance.PrimaryPart
Workspace.CurrentCamera.CameraType = Enum.CameraType.Track

RunService.Heartbeat:Connect(function(dt)
	local movementX = 0
	local movementY = 0

	if Input.keysDown[Enum.KeyCode.W] then
		movementY = movementY + 1
	end

	if Input.keysDown[Enum.KeyCode.S] then
		movementY = movementY - 1
	end

	if Input.keysDown[Enum.KeyCode.D] then
		movementX = movementX - 1
	end

	if Input.keysDown[Enum.KeyCode.A] then
		movementX = movementX + 1
	end

	if movementX ~= 0 or movementY ~= 0 then
		local relativeDirection = Vector3.new(movementX, 0, movementY)

		local cameraLook = Workspace.CurrentCamera.CFrame.lookVector
		local cameraAngle = math.atan2(cameraLook.x, cameraLook.z)

		local direction = (CFrame.Angles(0, cameraAngle, 0) * CFrame.new(relativeDirection)).p.unit

		updateCharacter(character, direction.X, direction.Z, dt)
	else
		updateCharacter(character, 0, 0, dt)
	end
end)

Input.start()