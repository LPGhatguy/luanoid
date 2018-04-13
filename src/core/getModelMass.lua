local function getModelMass(model)
	local mass = 0
	local visited = {}
	
	local function sumMass(part)
		mass = mass + part:GetMass()
		visited[part] = true
		
		for _, p in ipairs(part:GetConnectedParts()) do
			if not visited[p] then
				sumMass(p)
			end
		end
	end
	
	sumMass(assert(model.PrimaryPart))
	
	return mass
end

return getModelMass
