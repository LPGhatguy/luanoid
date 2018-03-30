local Workspace = game:GetService("Workspace")

local Animation = require(script.Parent.Parent.Animation)
local DebugHandle = require(script.Parent.Parent.DebugHandle)

local CLIMB_DISTANCE = 1.5 -- How far away can you be from the surface to climb?
local FLOOR_DISTANCE = 2.2
local CLIMB_DEBOUNCE = 0.2

local Climbing = {}
Climbing.__index = Climbing

function Climbing.new(simulation)
	local state = {
		simulation = simulation,
		character = simulation.character,
		animation = simulation.animation,

		checkAdorn = DebugHandle.new(),
		objects = {},
		refs = {},
		options = nil,
		lastClimbTime = -math.huge,
	}

	setmetatable(state, Climbing)

	return state
end

function Climbing:nearFloor()
	local rayOrigin = self.character.castPoint.WorldPosition
	local rayDirection = Vector3.new(0, -FLOOR_DISTANCE, 0)

	local climbRay = Ray.new(rayOrigin, rayDirection)
	local hit = Workspace:FindPartOnRay(climbRay, self.character.instance)

	return not not hit
end

function Climbing:cast()
	local rayOrigin = self.character.castPoint.WorldPosition
	local rayDirection = self.character.instance.PrimaryPart.CFrame.lookVector * CLIMB_DISTANCE

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

--[[
	Intended to be used to check whether it's appropriate to transition to the
	Climbing state.
]]
function Climbing:check()
	-- If we just stopped climbing, don't climb again yet
	if Workspace.DistributedGameTime - self.lastClimbTime <= CLIMB_DEBOUNCE then
		return nil
	end

	return self:cast()
end

function Climbing:enterState(oldState, options)
	assert(options.object)
	assert(options.position)
	assert(options.normal)

	self.options = options

	self.character.instance.LeftFoot.CanCollide = false
	self.character.instance.LeftLowerLeg.CanCollide = false
	self.character.instance.LeftHand.CanCollide = false
	self.character.instance.LeftLowerArm.CanCollide = false
	self.character.instance.RightFoot.CanCollide = false
	self.character.instance.RightLowerLeg.CanCollide = false
	self.character.instance.RightHand.CanCollide = false
	self.character.instance.RightLowerArm.CanCollide = false

	self.lastClimbTime = Workspace.DistributedGameTime

	local position0 = Instance.new("Attachment")
	position0.Parent = self.character.instance.PrimaryPart
	position0.Position = Vector3.new(0, 0, -1)
	self.objects[position0] = true

	local orientation = CFrame.new(Vector3.new(), -options.normal) + options.position - options.object.Position

	local position1 = Instance.new("Attachment")
	position1.CFrame = orientation
	position1.Parent = options.object
	self.refs.positionAttachment = position1
	self.objects[position1] = true

	local position = Instance.new("AlignPosition")
	position.Attachment0 = position0
	position.Attachment1 = position1
	position.Parent = self.character.instance.PrimaryPart
	position.MaxForce = 50000
	position.Responsiveness = 30
	self.objects[position] = true

	local align = Instance.new("AlignOrientation")
	align.Attachment0 = position0
	align.Attachment1 = position1
	align.Parent = self.character.instance.PrimaryPart
	self.objects[align] = true

	self.animation:setState(Animation.State.Climbing)
end

function Climbing:leaveState()
	self.character.instance.LeftFoot.CanCollide = true
	self.character.instance.LeftLowerLeg.CanCollide = true
	self.character.instance.LeftHand.CanCollide = true
	self.character.instance.LeftLowerArm.CanCollide = true
	self.character.instance.RightFoot.CanCollide = true
	self.character.instance.RightLowerLeg.CanCollide = true
	self.character.instance.RightHand.CanCollide = true
	self.character.instance.RightLowerArm.CanCollide = true

	self.refs = {}

	for object in pairs(self.objects) do
		object:Destroy()
	end

	self.objects = {}

	self.lastClimbTime = Workspace.DistributedGameTime

	self.animation.animations.climb:AdjustSpeed(1)
	self.animation:setState(Animation.State.None)
end

function Climbing:step(dt, input)
	if input.jump and Workspace.DistributedGameTime - self.lastClimbTime >= CLIMB_DEBOUNCE then
		return self.simulation:setState(self.simulation.states.Walking)
	end

	-- If the user is moving down, check if they could be hitting the floor
	if input.movementY < 0 and self:nearFloor() then
		return self.simulation:setState(self.simulation.states.Walking)
	end

	-- TODO: Change this placeholder movement code
	if input.movementY ~= 0 then
		local change = Vector3.new(0, input.movementY * dt * 10, 0)
		self.refs.positionAttachment.CFrame = self.refs.positionAttachment.CFrame + change
	end

	self.animation.animations.climb:AdjustSpeed(input.movementY)

	local nextClimb = self:cast()

	-- We can't climb anymore!
	if not nextClimb then
		return self.simulation:setState(self.simulation.states.Walking)
	end

	-- We're transitioning to a new climbable
	if nextClimb.object ~= self.options.object then
		return self.simulation:setState(self, nextClimb)
	end
end

return Climbing