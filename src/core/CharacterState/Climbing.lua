local Workspace = game:GetService("Workspace")

local Animation = require(script.Parent.Parent.Animation)
local DebugHandle = require(script.Parent.Parent.DebugHandle)

local START_CLIMB_DISTANCE = 2.5
local KEEP_CLIMB_DISTANCE = 3
local FLOOR_DISTANCE = 2.2
local CLIMB_DEBOUNCE = 0.2
local CLIMB_OFFSET = Vector3.new(0, 0, 0.5) -- In object space

local function getClimbCFrame(result)
	return CFrame.new(Vector3.new(), -result.normal) + result.position - result.object.Position
end

local Climbing = {}
Climbing.__index = Climbing

function Climbing.new(simulation)
	local state = {
		simulation = simulation,
		character = simulation.character,
		animation = simulation.animation,

		checkAdorn = DebugHandle.new(),
		checkAdorn2 = DebugHandle.new(Color3.new(1, 1, 1)),
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
	local object = Workspace:FindPartOnRay(climbRay, self.character.instance)

	return not not object
end

function Climbing:cast(distance)
	distance = distance or START_CLIMB_DISTANCE

	local rayOrigin = self.character.instance.PrimaryPart.Position + self.character.instance.PrimaryPart.CFrame:vectorToWorldSpace(CLIMB_OFFSET)
	local rayDirection = self.character.instance.PrimaryPart.CFrame.lookVector * distance

	local climbRay = Ray.new(rayOrigin, rayDirection)
	local object, position, normal = Workspace:FindPartOnRay(climbRay, self.character.instance)

	-- TODO: Use CollectionService?
	local isClimbable = object and not not object:FindFirstChild("Climbable")

	local adornColor
	if isClimbable then
		adornColor = Color3.new(0, 1, 0)
	elseif object then
		adornColor = Color3.new(0, 0, 1)
	else
		adornColor = Color3.new(1, 0, 0)
	end

	self.checkAdorn2:move(rayOrigin)
	self.checkAdorn:setColor(adornColor)
	self.checkAdorn:move(position)

	if not isClimbable then
		return nil
	end

	return {
		object = object,
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
	self.character.instance.LeftUpperLeg.CanCollide = false
	self.character.instance.LeftHand.CanCollide = false
	self.character.instance.LeftLowerArm.CanCollide = false
	self.character.instance.LeftUpperArm.CanCollide = false
	self.character.instance.RightFoot.CanCollide = false
	self.character.instance.RightLowerLeg.CanCollide = false
	self.character.instance.RightUpperLeg.CanCollide = false
	self.character.instance.RightHand.CanCollide = false
	self.character.instance.RightLowerArm.CanCollide = false
	self.character.instance.RightUpperArm.CanCollide = false

	self.lastClimbTime = Workspace.DistributedGameTime

	local position0 = Instance.new("Attachment")
	position0.Parent = self.character.instance.PrimaryPart
	position0.Position = -CLIMB_OFFSET
	self.objects[position0] = true

	local position1 = Instance.new("Attachment")
	position1.CFrame = getClimbCFrame(options)
	position1.Parent = options.object
	self.refs.positionAttachment = position1
	self.objects[position1] = true

	local position = Instance.new("AlignPosition")
	position.Attachment0 = position0
	position.Attachment1 = position1
	position.Parent = self.character.instance.PrimaryPart
	position.MaxForce = 100000
	position.Responsiveness = 50
	position.MaxVelocity = 7
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
	self.character.instance.LeftUpperLeg.CanCollide = true
	self.character.instance.LeftHand.CanCollide = true
	self.character.instance.LeftLowerArm.CanCollide = true
	self.character.instance.LeftUpperArm.CanCollide = true
	self.character.instance.RightFoot.CanCollide = true
	self.character.instance.RightLowerLeg.CanCollide = true
	self.character.instance.RightUpperLeg.CanCollide = true
	self.character.instance.RightHand.CanCollide = true
	self.character.instance.RightLowerArm.CanCollide = true
	self.character.instance.RightUpperArm.CanCollide = true

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

	local nextStep = self:cast(KEEP_CLIMB_DISTANCE)

	-- We ran out of surface to climb!
	if not nextStep then
		-- TODO: Pop character up?
		return self.simulation:setState(self.simulation.states.Walking)
	end

	self.animation.animations.climb:AdjustSpeed(input.movementY * 2)

	-- We're transitioning to a new climbable
	if nextStep.object ~= self.options.object then
		return self.simulation:setState(self, nextStep)
	end

	local reference = self.character.instance.PrimaryPart.CFrame

	local change = reference.upVector * input.movementY - reference.rightVector * input.movementX

	if input.movementX ~= 0 or input.movementY ~= 0 then
		self.refs.positionAttachment.CFrame = getClimbCFrame(nextStep) + change.unit
	end
end

return Climbing