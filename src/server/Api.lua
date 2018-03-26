local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ApiSpec = require(ReplicatedFirst.CharacterControllerCore.ApiSpec)

local apiObjects = Instance.new("Folder")
apiObjects.Name = "CharacterControllerApi"
apiObjects.Parent = ReplicatedStorage

local Api = {}

function Api.implement(implementation)
	for _, methodName in ipairs(ApiSpec.clientMethods) do
		local object = Instance.new("RemoteFunction")
		object.Name = methodName

		local serverMethod = implementation[methodName]

		if not serverMethod then
			error(string.format("Server is missing implementation for client method %q", methodName))
		end

		object.OnServerInvoke = function(...)
			return serverMethod(...)
		end

		object.Parent = apiObjects
	end
end

return Api