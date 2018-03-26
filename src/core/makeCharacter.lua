local StarterPlayer = game:GetService("StarterPlayer")

local function makeCharacter(name)
	name = name or "Unnamed Character"

	local instance = StarterPlayer.StarterCharacter:Clone()
	instance.Name = name

	local targetOrientPart = Instance.new("Part")
	targetOrientPart.Name = "OrientationTarget"
	targetOrientPart.Anchored = true
	targetOrientPart.Size = Vector3.new(1, 1, 1)
	targetOrientPart.Color = Color3.new(1, 1, 0)
	targetOrientPart.CanCollide = false
	targetOrientPart.Transparency = 0.95
	targetOrientPart.Parent = instance

	local orient0 = Instance.new("Attachment")
	orient0.Name = "Align0"
	orient0.Axis = Vector3.new(0, 1, 0)
	orient0.SecondaryAxis = Vector3.new(-1, 0, 0)
	orient0.Parent = instance.PrimaryPart

	local orient1 = Instance.new("Attachment")
	orient1.Name = "Align1"
	orient1.Parent = targetOrientPart

	local aligner = Instance.new("AlignOrientation")
	aligner.RigidityEnabled = true
	aligner.Attachment0 = orient0
	aligner.Attachment1 = orient1
	aligner.Parent = instance.PrimaryPart

	local velocity0 = Instance.new("Attachment")
	velocity0.Name = "Velocity0"
	velocity0.Parent = instance.PrimaryPart

	local vectorForce = Instance.new("VectorForce")
	vectorForce.ApplyAtCenterOfMass = true
	vectorForce.Force = Vector3.new(0, 0, 0)
	vectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
	vectorForce.Attachment0 = velocity0
	vectorForce.Parent = instance.PrimaryPart

	local avatarModel = instance:WaitForChild("Avatar")
	local avatarRoot = avatarModel.PrimaryPart

	return {
		instance = instance,
		vectorForce = vectorForce,
		targetOrientPart = targetOrientPart,
		avatarModel = avatarModel,
		avatarRoot = avatarRoot
	}
end

return makeCharacter