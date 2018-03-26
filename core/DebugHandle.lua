--[[
	Renders points in the world for debugging things.

	Usually used when dealing with finnicky 3D math.
]]

local anchorPoint
local function init()
	anchorPoint = Instance.new("Part")
	anchorPoint.Name = "Graphical Debug Anchor"
	anchorPoint.Anchored = true
	anchorPoint.CanCollide = false
	anchorPoint.Size = Vector3.new(1, 1, 1)
	anchorPoint.CFrame = CFrame.new(Vector3.new(0, 0, 0))
	anchorPoint.Transparency = 1
	anchorPoint.Parent = game.Workspace
end

local DebugHandle = {}
DebugHandle.__index = DebugHandle

function DebugHandle.new(color)
	color = color or Color3.new(0, 0, 1)

	if not anchorPoint then
		init()
	end

	local instance = Instance.new("SphereHandleAdornment")
	instance.Color3 = color
	instance.ZIndex = 1
	instance.Name = "Debug Handle"
	instance.AlwaysOnTop = true
	instance.Radius = 0.3
	instance.Adornee = anchorPoint
	instance.Parent = anchorPoint

	return setmetatable({
		instance = instance,
	}, DebugHandle)
end

function DebugHandle:move(pos)
	if pos then
		self.instance.Visible = true
		self.instance.CFrame = CFrame.new(pos)
	else
		self.instance.Visible = false
	end
end

function DebugHandle:destroy()
	self.instance:Destroy()
end

return DebugHandle