local ANIMATION_IDS = {
	idle = "rbxassetid://507766666",
	walk = "rbxassetid://507767714",
	climb = "rbxassetid://507765644",
	jump = "rbxassetid://507765000",
}

local Animation = {}
Animation.__index = Animation

Animation.State = {
	None = {
		enter = function()
		end,
		leave = function()
		end,
	},
	Idle = {
		enter = function(self)
			self.animations.idle:Play()
		end,
		leave = function(self)
			self.animations.idle:Stop()
		end,
	},
	Walking = {
		enter = function(self)
			self.animations.walk:Play()
		end,
		leave = function(self)
			self.animations.walk:Stop()
		end,
	},
	Climbing = {
		enter = function(self)
			self.animations.climb:Play()
		end,
		leave = function(self)
			self.animations.climb:Stop()
		end,
	},
	Falling = {
		enter = function(self)
			self.animations.jump:Play()
		end,
		leave = function(self)
			self.animations.jump:Stop()
		end,
	},
	Ragdoll = {
		enter = function(self)
			self.animations.climb:Play()
		end,
		leave = function(self)
			self.animations.climb:Stop()
		end,
	},
}

function Animation.new(simulation)
	local self = {
		simulation = simulation,
		character = simulation.character,
		animations = {},
		animationState = Animation.State.None,
	}

	self.controller = Instance.new("AnimationController")
	self.controller.Parent = simulation.character.instance

	for name, id in pairs(ANIMATION_IDS) do
		local animation = Instance.new("Animation")
		animation.AnimationId = id
		animation.Parent = self.controller

		self.animations[name] = self.controller:LoadAnimation(animation)
	end

	setmetatable(self, Animation)

	return self
end

function Animation:setState(newState, options)
	assert(newState, "Need to specify state for Animation:setState")

	if newState == self.animationState then
		return
	end

	self.animationState.leave(self)
	self.animationState = newState
	self.animationState.enter(self)
end

return Animation
