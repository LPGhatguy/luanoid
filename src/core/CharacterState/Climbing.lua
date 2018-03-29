local Workspace = game:GetService("Workspace")

local DebugHandle = require(script.Parent.Parent.DebugHandle)

local Climbing = {}
Climbing.__index = Climbing

function Climbing.new(simulation)
	local state = {
		simulation = simulation,
		character = simulation.character,
		checkAdorn = DebugHandle.new(),
	}

	setmetatable(state, Climbing)

	return state
end

function Climbing:check()
	local rayOrigin = self.character.castPoint.WorldPosition
	local rayDirection = self.character.instance.PrimaryPart.CFrame.lookVector * 3

	local climbRay = Ray.new(rayOrigin, rayDirection)
	local hit, position, normal = Workspace:FindPartOnRay(climbRay, self.character.instance)

	-- TODO: Use CollectionService?
	local isClimbable = hit and not not hit:FindFirstChild("Climbable")

	local adornColor
	if isClimbable then
		adornColor = Color3.new(0, 1, 0)
	elseif hit then
		adornColor = Color3.new(0, 0, 1)
	else
		adornColor = Color3.new(1, 0, 0)
	end

	self.checkAdorn:setColor(adornColor)
	self.checkAdorn:move(position)

	if not isClimbable then
		return nil
	end

	return {
		object = hit,
		position = position,
		normal = normal,
	}
end

function Climbing:enterState(oldState, options)
	assert(options.object)
	assert(options.position)
	assert(options.normal)

	print("Start climbing object", options.object)
end

function Climbing:leaveState()
	-- TODO
end

function Climbing:step(dt, input)
	if input.jump then
		return self.simulation:setState(self.simulation.states.Walking)
	end
end

return Climbing