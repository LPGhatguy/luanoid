local function getModelMass(model)
	local mass = 0

	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("BasePart") then
			mass = mass + child:GetMass()
		else
			mass = mass + getModelMass(child)
		end
	end

	return mass
end

return getModelMass