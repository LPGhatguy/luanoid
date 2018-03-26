local UserInputService = game:GetService("UserInputService")

local Input = {
	keysDown = {},
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

return Input