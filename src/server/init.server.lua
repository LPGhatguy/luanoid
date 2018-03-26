local Workspace = game:GetService("Workspace")

local makeCharacter = require(script.makeCharacter)
local Api = require(script.Api)

local ApiImplementation = {}

function ApiImplementation.requestMakeCharacter(player)
	-- TODO: Validation
	-- TODO: Mark ownership of character to this player

	local character = makeCharacter(player.Name)
	character.instance.Parent = Workspace

	return character
end

Api.implement(ApiImplementation)