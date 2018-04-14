local function getModelMass(model)
	local root = assert(model.PrimaryPart)
	local mass = 0
	for _, part in ipairs(root:GetConnectedParts(true)) do
		mass = mass + part:GetMass()
	end
	return mass
end

return getModelMass
