local Climbing = {}
Climbing.__index = Climbing

function Climbing.new(simulation)
	local state = {}

	setmetatable(state, Climbing)

	return state
end

function Climbing:enterState(oldState, options)
	-- TODO
end

function Climbing:leaveState()
	-- TODO
end

function Climbing:step(dt, input)
	-- TODO
end

return Climbing