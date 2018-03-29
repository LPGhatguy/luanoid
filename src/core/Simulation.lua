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