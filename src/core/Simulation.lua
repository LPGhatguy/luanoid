local CharacterState = require(script.Parent.CharacterState)

local Simulation = {}
Simulation.__index = Simulation

function Simulation.new(character)
	local simulation = {
		character = character,
	}

	simulation.state = CharacterState.Walking.new(simulation)

	setmetatable(simulation, Simulation)

	return simulation
end

function Simulation:step(dt, input)
	self.state:step(dt, input)
end

return Simulation