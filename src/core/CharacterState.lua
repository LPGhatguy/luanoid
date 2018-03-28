local CharacterState = {}
CharacterState.__index = CharacterState

CharacterState.Status = {
	Stable = "Stable",
}

function CharacterState.new()
	local state = {
		input = {
			movementX = 0,
			movementY = 0,
			jump = false,
		},
		status = CharacterState.Status.Stable,
	}

	setmetatable(state, CharacterState)

	return state
end

function CharacterState:setInput(input)
	self.input = input
end

return CharacterState