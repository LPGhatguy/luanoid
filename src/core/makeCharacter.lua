local StarterPlayer = game:GetService("StarterPlayer")

local function makeCharacter(name)
	name = name or "Unnamed Character"

	local instance = StarterPlayer.StarterCharacter:Clone()
	instance.Name = name

	local castPoint = instance.PrimaryPart:WaitForChild("CastPoint")

	return {
		instance = instance,
		castPoint = castPoint,
	}
end

return makeCharacter