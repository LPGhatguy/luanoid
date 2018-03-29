local ANIMATIONS = {
	idle = "http://www.roblox.com/asset/?id=507766666",
	walk = "http://www.roblox.com/asset/?id=507767714",
	climb = "http://www.roblox.com/asset/?id=507765644",
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
			self.animations.climb:Play()
		end,
		leave = function(self)
			self.animations.climb:Stop()
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

	for name, id in pairs(ANIMATIONS) do
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