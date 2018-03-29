local Workspace = game:GetService("Workspace")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local makeCharacter = require(ReplicatedFirst.CharacterControllerCore.makeCharacter)

local Api = require(script.Api)

local ApiImplementation = {}

function ApiImplementation.requestMakeCharacter(player)
	-- TODO: Validation

	local character = makeCharacter(player.Name)
	character.instance.Parent = Workspace

	for _, object in ipairs(character.instance:GetDescendants()) do
		if object:IsA("BasePart") then
			object:SetNetworkOwner(player)
		end
	end

	return character
end

Api.implement(ApiImplementation)