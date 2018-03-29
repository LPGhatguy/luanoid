local Climbing = {}
Climbing.__index = Climbing

function Climbing.new(simulation)
	local state = {}

	setmetatable(state, Climbing)

	return state
end

function Climbing:enterState()
end

function Climbing:leaveState()
end

function Climbing:step(dt, input)
end

return Climbing