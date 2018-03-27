--[[
	Renders points in the world for debugging things.

	Usually used when dealing with finnicky 3D math.
]]

local Terrain = game:GetService("Workspace").Terrain

local DebugHandle = {}
DebugHandle.__index = DebugHandle

function DebugHandle.new(color)
	color = color or Color3.new(0, 0, 1)

	local instance = Instance.new("SphereHandleAdornment")
	instance.Color3 = color
	instance.ZIndex = 1
	instance.Name = "Debug Handle"
	instance.AlwaysOnTop = true
	instance.Radius = 0.12
	instance.Adornee = Terrain
	instance.Parent = Terrain

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