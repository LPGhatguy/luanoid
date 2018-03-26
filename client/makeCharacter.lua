local StarterPlayer = game:GetService("StarterPlayer")

local function makeCharacter(player)
	local instance = StarterPlayer.StarterCharacter:Clone()
	instance.Name = player.Name

	local character = {
		instance = instance,
	}

	return character
end

return makeCharacter