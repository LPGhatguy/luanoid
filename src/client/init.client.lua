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

	if Input.keysDown[Enum.KeyCode.W] then
		input.movementY = input.movementY + 1
	end

	if Input.keysDown[Enum.KeyCode.S] then
		input.movementY = input.movementY - 1
	end

	if Input.keysDown[Enum.KeyCode.D] then
		input.movementX = input.movementX - 1
	end

	if Input.keysDown[Enum.KeyCode.A] then
		input.movementX = input.movementX + 1
	end

	simulation:step(dt, input)
end)

Input.start()