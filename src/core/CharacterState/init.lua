--[[
	Bundle up each CharacterState and expose it through one object
]]

local result = {}

for _, instance in pairs(script:GetChildren()) do
	result[instance.Name] = require(instance)
end

return result