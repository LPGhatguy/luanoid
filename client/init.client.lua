local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local stepSpring = require(ReplicatedStorage.CharacterControllerCore.stepSpring)

local Input = require(script.Input)
local makeCharacter = require(script.makeCharacter)

local FRAMERATE = 1 / 240
local STIFFNESS = 170
local DAMPING = 26
local PRECISION = 0.001
local GROUND_TOLERANCE = 0.15

local accumulatedTime = 0
local currentAccelerationX = 0
local currentAccelerationY = 0

local aligner = Instance.new("AlignOrientation")
aligner.RigidityEnabled = true

local attachment0 = Instance.new("Attachment")
attachment0.Name = "Align0"
attachment0.Axis = Vector3.new(0, 1, 0)
attachment0.SecondaryAxis = Vector3.new(-1, 0, 0)

local attachment1 = Instance.new("Attachment")
attachment1.Name = "Align1"

aligner.Attachment0 = attachment0
aligner.Attachment1 = attachment1

local targetOrientPart = Instance.new("Part")
targetOrientPart.Anchored = true
targetOrientPart.Size = Vector3.new(1, 1, 1)
targetOrientPart.Color = Color3.new(1, 1, 0)
targetOrientPart.CanCollide = false
targetOrientPart.Transparency = 0.95

attachment1.Parent = targetOrientPart

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

local function updateCharacter(characterInstance, targetX, targetY, dt)
	local characterMass = getModelMass(characterInstance)
	local onGround = isOnGround(characterInstance)

	accumulatedTime = accumulatedTime + dt

	local currentX = characterInstance.PrimaryPart.Velocity.X
	local currentY = characterInstance.PrimaryPart.Velocity.Z

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
	characterInstance.BottomSphere.Color = bottomColor

	if onGround then
		local up
		if Input.keysDown[Enum.KeyCode.Space] then
			up = 5000 * characterMass
		else
			up = 0
		end

		characterInstance.PrimaryPart.VectorForce.Force = Vector3.new(
			currentAccelerationX * characterMass,
			up,
			currentAccelerationY * characterMass
		)
	else
		characterInstance.PrimaryPart.VectorForce.Force = Vector3.new(0, 0, 0)
	end

	local velocity = Vector3.new(currentX, 0, currentY)

	targetOrientPart.CFrame = CFrame.new(characterInstance.PrimaryPart.Position + velocity / 3)
end

local character = makeCharacter(Players.LocalPlayer)
character.instance.Parent = Workspace

targetOrientPart.Parent = character.instance
attachment0.Parent = character.instance.PrimaryPart
aligner.Parent = character.instance.PrimaryPart

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

		local absoluteDirection = (CFrame.Angles(0, cameraAngle, 0) * CFrame.new(relativeDirection)).p
		local movement = absoluteDirection.unit * dt

		updateCharacter(character.instance, movement.X * 2000, movement.Z * 2000, dt)
	else
		updateCharacter(character.instance, 0, 0, dt)
	end
end)

Input.start()