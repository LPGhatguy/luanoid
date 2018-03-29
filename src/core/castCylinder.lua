local Workspace = game:GetService("Workspace")

local DebugHandle = require(script.Parent.DebugHandle)

local CAST_COUNT = 32

-- TODO: more appropriate cast distribution algorithm
-- https://stackoverflow.com/a/28572551/367100
local function radius(k,n,b)
	if k > n - b then
		return 1 -- put on the boundary
	else
		return math.sqrt(k - 1/2)/math.sqrt(n - (b + 1)/2) -- apply square root
	end
end

local function sunflower(n, alpha) --  example: n=500, alpha=2
	local b = math.ceil(alpha*math.sqrt(n)) -- number of boundary points
	local phi = (math.sqrt(5) + 1)/2 -- golden ratio
	local i = 1
	return function()
		if i <= n then
			i = i + 1
			local r = radius(i, n, b)
			local theta = 2*math.pi*i/(phi*phi)
			return i - 1, r*math.cos(theta), r*math.sin(theta)
		end
		return
	end
end

-- direction is direction + mag
local function castCylinder(options)
	local origin = assert(options.origin)
	local direction = assert(options.direction)
	local bias = assert(options.bias)
	local hipHeight = assert(options.hipHeight)
	local adorns = options.adorns
	local ignoreInstance = options.ignoreInstance

	-- max len, min length
	-- update part points and part velocities
	local radius = 1.5

	if bias.Magnitude > radius*0.75 then
		bias = bias.Unit * radius*0.75
	end

	local onGround = false
	local totalWeight = 0
	local totalHeight = 0

	for index, x, z in sunflower(CAST_COUNT, 2) do
		local offset = Vector3.new(x*radius, 0, z*radius)

		local biasDist = (offset - bias).Magnitude / radius
		local weight = 1 - biasDist*biasDist
		-- weight = math.max(weight, 0.1)
		
		local start = origin + offset
		local ray = Ray.new(start, direction)
		
		local part, point = Workspace:FindPartOnRay(ray, ignoreInstance)
		local length = (point - start).Magnitude
		local legHit = length <= hipHeight + 0.25

		if weight > 0 then
			onGround = onGround or legHit
			
			-- add to weighted average
			if part then
				totalWeight = totalWeight + weight
				totalHeight = totalHeight + point.y*weight
			end
		end

		if adorns then
			local adorn = adorns[index]

			if not adorn then
				adorn = DebugHandle.new()
				adorns[index] = adorn
			end

			adorn:move(point)
			
			if legHit then
				adorn:setColor(Color3.new(0, weight, 0))
			elseif part then
				adorn:setColor(Color3.new(0, weight, weight))
			else
				adorn:setColor(Color3.new(1, 0, 0))
			end
		end
	end

	return onGround, totalHeight / totalWeight
end

return castCylinder