local Workspace = game:GetService("Workspace")
local StarterPlayer = game:GetService("StarterPlayer")

local function makeCharacter(name)
	name = name or "Unnamed Character"

	local instance = StarterPlayer.StarterCharacter:Clone()
	instance.Name = name

	local orient0 = Instance.new("Attachment")
	orient0.Name = "Align0"
	-- orient0.Axis = Vector3.new(0, 1, 0)
	-- orient0.SecondaryAxis = Vector3.new(-1, 0, 0)
	orient0.Parent = instance.PrimaryPart

	-- TODO: Track attachments in Terrain for cleanup

	local orient1 = Instance.new("Attachment")
	orient1.Name = "Align1"
	orient1.Parent = Workspace.Terrain

	local orientation = Instance.new("AlignOrientation")
	orientation.RigidityEnabled = true
	orientation.Attachment0 = orient0
	orientation.Attachment1 = orient1
	orientation.Parent = instance.PrimaryPart

	local velocity0 = Instance.new("Attachment")
	velocity0.Name = "Velocity0"
	velocity0.Parent = instance.PrimaryPart

	local vectorForce = Instance.new("VectorForce")
	vectorForce.ApplyAtCenterOfMass = true
	vectorForce.Force = Vector3.new(0, 0, 0)
	vectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
	vectorForce.Attachment0 = velocity0
	vectorForce.Parent = instance.PrimaryPart

	local castPoint = instance.PrimaryPart:WaitForChild("CastPoint")

	return {
		instance = instance,
		vectorForce = vectorForce,
		orientationAttachment = orient1,
		orientation = orientation,
		castPoint = castPoint,
	}
end

return makeCharacter