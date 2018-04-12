local Workspace = game:GetService("Workspace")

local DebugVisualize = require(script.Parent.DebugVisualize)

local CAST_COUNT = 32

-- TODO: use normals to get a better plane with fewer points
-- http://www.ilikebigbits.com/blog/2015/3/2/plane-from-points
local function planeFromPoints(points, weights)
	if #points < 3 then
		error("planeFromPoints requires at least 3 points", 2)
	end

	local pointSum = Vector3.new()
	local weightSum = 0
	for i, p in pairs(points) do
		local weight = weights[i]
		weightSum = weightSum + weight
		centroid = centroid + p*weight
	end
	local centroid = pointSum/weightSum

	-- Calc full 3x3 covariance matrix, excluding symmetries:
	local xx = 0 local xy = 0 local xz = 0
	local yy = 0 local yz = 0 local zz = 0

	for i, p in pairs(points) do
		local w = weights[i]
		local r = p - centroid
		xx = xx + r.x*r.x*w
		xy = xy + r.x*r.y*w
		xz = xz + r.x*r.z*w
		yy = yy + r.y*r.y*w
		yz = yz + r.y*r.z*w
		zz = zz + r.z*r.z*w
	end

	local det_x = yy*zz - yz*yz
	local det_y = xx*zz - xz*xz
	local det_z = xx*yy - xy*xy

	local det_max = math.max(det_x, det_y, det_z)
	assert(det_max > 0)

	-- Pick path with best conditioning:
    local dir
	if det_max == det_x then
		dir = Vector3.new(
			det_x,
			xz*yz - xy*zz,
			xy*yz - xz*yy
		)
	elseif det_max == det_y then
		dir = Vector3.new(
			xz*yz - xy*zz,
			det_y,
			xy*xz - yz*xx
		)
	else
		dir = Vector3.new(
			xy*yz - xz*yy,
			xy*xz - yz*xx,
			det_z
		)
	end

	-- quick fix for the plane normal sometimes being "upside down" from what we want
	if dir.y < 0 then
		dir = -dir
	end

    return centroid, dir.Unit
end

-- TODO: more appropriate cast distribution algorithm
-- https://stackoverflow.com/a/28572551/367100
local function radius(i, n, b)
	if i > n - b then
		return 1 -- put on the boundary
	else
		return math.sqrt((1 - 2*i)/(b - 2*n + 1))
	end
end

local function sunflower(n, alpha) --  example: n=500, alpha=2
	local b = math.ceil(alpha*math.sqrt(n)) -- number of boundary points
	local c = (3 - math.sqrt(5))*math.pi -- 2*pi/(phi*phi)
	local i = 1
	return function()
		if i <= n then
			i = i + 1
			local r = radius(i, n, b)
			local theta = c*i
			return i - 1, r*math.cos(theta), r*math.sin(theta)
		end
		return
	end
end

-- direction is direction + mag
local function castCylinder(options)
	local origin = assert(options.origin)
	local direction = assert(options.direction)
	local radius = assert(options.radius)
	local biasCenter = assert(options.biasCenter)
	local biasRadius = assert(options.biasRadius)
	local hipHeight = assert(options.hipHeight)
	local steepTan = assert(options.steepTan)
	local steepStartTan = assert(options.steepStartTan)
	local ignoreInstance = options.ignoreInstance

	-- clamp bias params
	biasRadius = math.max(biasRadius, 0.25)
	if biasCenter.Magnitude > radius*0.75 then
		biasCenter = biasCenter.Unit * radius*0.75
	end

	local onGround = false
	local totalWeight = 0
	local totalHeight = 0

	local weights = {}
	local points = {}
	for _, x, z in sunflower(CAST_COUNT, 2) do
		local offset = Vector3.new(x*radius, 0, z*radius)
		local offsetDist = offset.Magnitude

		local biasDist = (offset - biasCenter).Magnitude / biasRadius
		local weight = 1 - biasDist*biasDist
		-- weight = math.max(weight, 0.1)

		local start = origin + offset
		local ray = Ray.new(start, direction)

		local part, point = Workspace:FindPartOnRay(ray, ignoreInstance, false, true)
		local length = (point - start).Magnitude
		local legHit = length <= hipHeight + 0.25

		local lift = hipHeight - length
		-- is the angle way higher than the steepest angle?
		local steep = lift*0.95/offsetDist > steepTan

		if part then
			if steep then
				weight = 0.1*weight
			end
			if weight > 0 then
				onGround = onGround or legHit
				local groundWeight = weight
				-- add to weighted average for target ground height
				totalWeight = totalWeight + groundWeight
				totalHeight = totalHeight + point.y*groundWeight
			end

			local normalWeight = math.max(0.01, weight) -- alow 0 weight as last resort data
			points[#points + 1] = point
			weights[#weights + 1] = normalWeight
		end

		local pointColor
		if steep then
			pointColor = Color3.new(weight, 0, weight)
		elseif legHit then
			pointColor = Color3.new(0, weight, 0)
		elseif part then
			pointColor = Color3.new(0, weight, weight)
		else
			pointColor = Color3.new(1, 0, 0)
		end

		DebugVisualize.point(point, pointColor)
	end

	local centroid, normal = planeFromPoints(points, weights)

	local steepness = 0
	if centroid and normal then
		local y = normal.y
		local x = Vector2.new(normal.x, normal.z).Magnitude
		if math.abs(x) > 0 then
			steepness = math.min(1, math.max(0, x/y - steepStartTan) / (steepTan - steepStartTan))
		elseif y < 0 then
			-- straight down
			steepness = 1
		end
	end

	if centroid then
		DebugVisualize.vector(
			centroid + normal * 0.5,
			normal,
			Color3.new(1, 1 - steepness, 1)
		)
	end

	return onGround, totalHeight / totalWeight, steepness, centroid, normal
end

return castCylinder
