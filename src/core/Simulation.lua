local Climbing = require(script.Parent.CharacterState.Climbing)
local Ragdoll = require(script.Parent.CharacterState.Ragdoll)
local Walking = require(script.Parent.CharacterState.Walking)

local Simulation = {}
Simulation.__index = Simulation

function Simulation.new(character)
	local simulation = {
		character = character,
	}

	simulation.states = {
		Climbing = Climbing.new(simulation),
		Ragdoll = Ragdoll.new(simulation),
		Walking = Walking.new(simulation),
	}

	simulation.currentState = simulation.states.Walking
	simulation.currentState:enterState()

	setmetatable(simulation, Simulation)

	return simulation
end

function Simulation:setState(newState, options)
	assert(newState, "setState requires a state parameter!")

	local oldState = self.currentState

	if oldState.leaveState then
		oldState:leaveState(newState)
	end

	self.currentState = newState

	if newState.enterState then
		newState:enterState(oldState, options)
	end
end

function Simulation:step(dt, input)
	if self.currentState.step then
		self.currentState:step(dt, input)
	end
end

return Simulation