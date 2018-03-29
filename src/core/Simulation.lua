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

	simulation.currentStateName = "Walking"

	simulation.states[simulation.currentStateName]:enterState()

	setmetatable(simulation, Simulation)

	return simulation
end

function Simulation:setState(stateName)
	if stateName == self.currentStateName then
		return
	end

	local oldState = self.states[self.currentStateName]
	local newState = self.states[stateName]

	if not newState then
		error(("Invalid state %q"):format(stateName), 2)
	end

	if oldState.leaveState then
		oldState:leaveState()
	end

	self.currentStateName = stateName

	if newState.enterState then
		newState:enterState()
	end
end

function Simulation:step(dt, input)
	local currentState = self.states[self.currentStateName]

	if currentState.step then
		currentState:step(dt, input)
	end
end

return Simulation