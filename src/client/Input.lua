local UserInputService = game:GetService("UserInputService")

local Input = {
	keysDown = {},
	previousKeysDown = {},
}

function Input.start()
	UserInputService.InputBegan:Connect(function(inputObject)
		if inputObject.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end

		Input.keysDown[inputObject.KeyCode] = true
	end)

	UserInputService.InputEnded:Connect(function(inputObject)
		if inputObject.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end

		Input.keysDown[inputObject.KeyCode] = nil
	end)
end

function Input.step()
	local newKeysDown = {}

	for key, value in pairs(Input.keysDown) do
		newKeysDown[key] = value
	end

	Input.previousKeysDown = Input.keysDown
	Input.keysDown = newKeysDown
end

return Input