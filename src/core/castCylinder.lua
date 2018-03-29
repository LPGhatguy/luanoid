local Workspace = game:GetService("Workspace")

local DebugHandle = require(script.Parent.DebugHandle)

local CAST_COUNT = 32

-- TODO: use normals to get a better plane with fewer points
-- http://www.ilikebigbits.com/blog/2015/3/2/plane-from-points
local function planeFromPoints(points, weights)
	local n = 0
	local sumX, sumY, sumZ = 0, 0, 0
	for i, p in pairs(points) do
		local w = weights[i]
		n = n + w
		sumX, sumY, sumZ = sumX + p.X*w, sumY + p.Y*w, sumZ + p.Z*w
	end
	local centroid = Vector3.new(sumX, sumY, sumZ) * (1.0/n)

	if n < 3 then
		-- at least three points required
		return centroid, Vector3.new(0, 1, 0)
	end

	-- Calc full 3x3 covariance matrix, excluding symmetries:
	local xx = 0.0 local xy = 0.0 local xz = 0.0
	local yy = 0.0 local yz = 0.0 local zz = 0.0

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
	if det_max <= 0 then
		return
	end

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

    return centroid, dir.Unit
end

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

	local weights = {}
	local points = {}
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

				points[#points + 1] = point
				weights[#weights + 1] = weight
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

	local centroid, normal = planeFromPoints(points, weights)
	if options.debugPlane then
		if centroid then
			options.debugPlane.Visible = true
			options.debugPlane.CFrame = CFrame.new(centroid + normal*0.5, centroid + normal)
		else
			options.debugPlane.Visible = false
		end
	end

	return onGround, totalHeight / totalWeight
end

return castCylinder