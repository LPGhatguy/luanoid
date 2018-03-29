local Workspace = game:GetService("Workspace")

local DebugHandle = require(script.Parent.Parent.DebugHandle)

local CLIMB_DEBOUNCE = 0.3

local Climbing = {}
Climbing.__index = Climbing

function Climbing.new(simulation)
	local state = {
		simulation = simulation,
		character = simulation.character,
		checkAdorn = DebugHandle.new(),
		objects = {},
		lastClimbTime = nil,
	}

	setmetatable(state, Climbing)

	return state
end

function Climbing:check()
	local rayOrigin = self.character.castPoint.WorldPosition
	local rayDirection = self.character.instance.PrimaryPart.CFrame.lookVector * 1

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

	-- If we just stopped climbing, don't climb again yet
	if self.lastClimbTime and Workspace.DistributedGameTime - self.lastClimbTime <= CLIMB_DEBOUNCE then
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

	self.checkAdorn:move(nil)

	self.lastClimbTime = Workspace.DistributedGameTime

	local position0 = Instance.new("Attachment")
	position0.Parent = self.character.instance.PrimaryPart
	self.objects[position0] = true

	local position1 = Instance.new("Attachment")
	position1.CFrame = CFrame.new(options.position - options.object.Position)
	position1.Parent = options.object
	self.objects[position1] = true

	local position = Instance.new("AlignPosition")
	position.Attachment0 = position0
	position.Attachment1 = position1
	position.Parent = self.character.instance.PrimaryPart
	self.objects[position] = true

	local align = Instance.new("AlignOrientation")
	align.Attachment0 = position0
	align.Attachment1 = position1
	align.Parent = self.character.instance.PrimaryPart
	self.objects[align] = true

	print("Start climbing object", options.object)
end

function Climbing:leaveState()
	for object in pairs(self.objects) do
		object:Destroy()
	end

	self.objects = {}

	self.lastClimbTime = Workspace.DistributedGameTime
end

function Climbing:step(dt, input)
	if input.jump and Workspace.DistributedGameTime - self.lastClimbTime >= CLIMB_DEBOUNCE then
		return self.simulation:setState(self.simulation.states.Walking)
	end
end

return Climbing