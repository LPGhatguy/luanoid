local CharacterState = require(script.Parent.CharacterState)

local Simulation = {}
Simulation.__index = Simulation

function Simulation.new(character)
	local simulation = {
		character = character,
	}

	simulation.states = {
		Walking = CharacterState.Walking.new(simulation),
		Ragdoll = CharacterState.Ragdoll.new(simulation),
	}

	simulation.state = "Walking"

	simulation.states[simulation.state]:enterState()

	setmetatable(simulation, Simulation)

	return simulation
end

function Simulation:setState(stateName)
	if stateName == self.state then
		return
	end

	if not self.states[stateName] then
		error("Invalid state name " .. stateName, 2)
	end

	self.states[self.state]:leaveState()
	self.state = stateName
	self.states[self.state]:enterState()
end

function Simulation:step(dt, input)
	self.states[self.state]:step(dt, input)
end

return Simulation