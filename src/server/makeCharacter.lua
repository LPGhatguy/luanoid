local StarterPlayer = game:GetService("StarterPlayer")

local function makeCharacter(name)
	name = name or "Unnamed Character"

	local instance = StarterPlayer.StarterCharacter:Clone()
	instance.Name = name

	local targetOrientPart = Instance.new("Part")
	targetOrientPart.Anchored = true
	targetOrientPart.Size = Vector3.new(1, 1, 1)
	targetOrientPart.Color = Color3.new(1, 1, 0)
	targetOrientPart.CanCollide = false
	targetOrientPart.Transparency = 0.95
	targetOrientPart.Parent = instance

	local attachment0 = Instance.new("Attachment")
	attachment0.Name = "Align0"
	attachment0.Axis = Vector3.new(0, 1, 0)
	attachment0.SecondaryAxis = Vector3.new(-1, 0, 0)
	attachment0.Parent = instance.PrimaryPart

	local attachment1 = Instance.new("Attachment")
	attachment1.Name = "Align1"
	attachment1.Parent = targetOrientPart

	local aligner = Instance.new("AlignOrientation")
	aligner.RigidityEnabled = true
	aligner.Attachment0 = attachment0
	aligner.Attachment1 = attachment1
	aligner.Parent = instance.PrimaryPart

	return {
		instance = instance,
		targetOrientPart = targetOrientPart,
	}
end

return makeCharacter