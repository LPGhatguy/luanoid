local Terrain = game:GetService("Workspace").Terrain

local unusedPoints = {}
local usedPoints = {}
local unusedVectors = {}
local usedVectors = {}

local DebugVisualize = {
	enabled = true,
}

function DebugVisualize.point(position, color)
	if not DebugVisualize.enabled then
		return
	end

	local instance = table.remove(unusedPoints)

	if not instance then
		instance = Instance.new("SphereHandleAdornment")
		instance.ZIndex = 1
		instance.Name = "Debug Handle"
		instance.AlwaysOnTop = true
		instance.Radius = 0.12
		instance.Adornee = Terrain
		instance.Parent = Terrain
	end

	instance.CFrame = CFrame.new(position)
	instance.Color3 = color

	table.insert(usedPoints, instance)
end

function DebugVisualize.vector(position, direction, color)
	if not DebugVisualize.enabled then
		return
	end

	local instance = table.remove(unusedVectors)

	if not instance then
		instance = Instance.new("BoxHandleAdornment")
		instance.Color3 = Color3.new(1, 1, 1)
		instance.AlwaysOnTop = true
		instance.ZIndex = 2
		instance.Transparency = 0.25
		instance.Size = Vector3.new(0.1, 0.1, 1)
		instance.Parent = Terrain
		instance.Adornee = Terrain
	end

	instance.CFrame = CFrame.new(position, position + direction)
	instance.Color3 = color

	table.insert(usedVectors, instance)
end

function DebugVisualize.step()
	while #unusedPoints > 0 do
		table.remove(unusedPoints):Destroy()
	end

	while #unusedVectors > 0 do
		table.remove(unusedVectors):Destroy()
	end

	usedPoints, unusedPoints = unusedPoints, usedPoints
	usedVectors, unusedVectors = unusedVectors, usedVectors
end

return DebugVisualize