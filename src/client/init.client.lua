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
	local input = {
		movementX = 0,
		movementY = 0,
		jump = Input.keysDown[Enum.KeyCode.Space],
		ragdoll = Input.keysDown[Enum.KeyCode.F],
	}

	local inputX = 0
	local inputY = 0

	if Input.keysDown[Enum.KeyCode.W] then
		inputY = inputY + 1
	end

	if Input.keysDown[Enum.KeyCode.S] then
		inputY = inputY - 1
	end

	if Input.keysDown[Enum.KeyCode.D] then
		inputX = inputX - 1
	end

	if Input.keysDown[Enum.KeyCode.A] then
		inputX = inputX + 1
	end

	-- TODO: Move transformation into Walking controller
	if inputX ~= 0 or inputY ~= 0 then
		local cameraLook = Workspace.CurrentCamera.CFrame.lookVector
		local cameraAngle = math.atan2(cameraLook.x, cameraLook.z)

		local magnitude = math.sqrt(inputX^2 + inputY^2)
		local relativeX = inputX / magnitude
		local relativeY = inputY / magnitude

		input.movementX = relativeX * math.cos(cameraAngle) + relativeY * math.sin(cameraAngle)
		input.movementY = -relativeX * math.sin(cameraAngle) + relativeY * math.cos(cameraAngle)
	end

	simulation:step(dt, input)
end)

Input.start()