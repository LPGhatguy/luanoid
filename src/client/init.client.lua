local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local Simulation = require(ReplicatedFirst.CharacterControllerCore.Simulation)

local Input = require(script.Input)
local Api = require(script.Api)

while not Players.LocalPlayer do
	wait()
end

local character = Api.requestMakeCharacter()
local simulation = Simulation.new(character)

Workspace.CurrentCamera.CameraSubject = character.instance.PrimaryPart
Workspace.CurrentCamera.CameraType = Enum.CameraType.Track

RunService.Heartbeat:Connect(function(dt)
	local movementX = 0
	local movementY = 0

	local jump = not not Input.keysDown[Enum.KeyCode.Space]

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

		simulation:step(dt, direction.X, direction.Z, jump)
	else
		simulation:step(dt, 0, 0, jump)
	end
end)

Input.start()