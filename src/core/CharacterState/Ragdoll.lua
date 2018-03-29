local Animation = require(script.Parent.Parent.Animation)

local Ragdoll = {}
Ragdoll.__index = Ragdoll

function Ragdoll.new(simulation)
	local state = {
		simulation = simulation,
		animation = simulation.animation,
	}

	setmetatable(state, Ragdoll)

	return state
end

function Ragdoll:enterState()
	self.animation:setState(Animation.State.Ragdoll)
end

function Ragdoll:leaveState()
	self.animation:setState(Animation.State.None)
end

function Ragdoll:step(dt, input)
	if not input.ragdoll then
		self.simulation:setState(self.simulation.states.Walking)
	end
end

return Ragdoll