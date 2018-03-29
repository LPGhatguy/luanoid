local Ragdoll = {}
Ragdoll.__index = Ragdoll

function Ragdoll.new(simulation)
	local state = {
		simulation = simulation,
	}

	setmetatable(state, Ragdoll)

	return state
end

function Ragdoll:step(dt, input)
	if not input.ragdoll then
		self.simulation:setState(self.simulation.states.Walking)
	end
end

return Ragdoll