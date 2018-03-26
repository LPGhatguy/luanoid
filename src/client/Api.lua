local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ApiSpec = require(ReplicatedFirst.CharacterControllerCore.ApiSpec)

local apiObjects = ReplicatedStorage:WaitForChild("CharacterControllerApi")

local Api = {}

for _, methodName in ipairs(ApiSpec.clientMethods) do
	local object = apiObjects:WaitForChild(methodName)

	Api[methodName] = function(...)
		return object:InvokeServer(...)
	end
end

return Api