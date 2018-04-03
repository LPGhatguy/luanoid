local CollisionMask = {}

function CollisionMask.apply(root, mask)
	CollisionMask._applyInternal(root, mask, false)
end

function CollisionMask.revert(root, mask)
	CollisionMask._applyInternal(root, mask, true)
end

function CollisionMask._applyInternal(root, mask, invert)
	for name, collisionValue in pairs(mask) do
		if invert then
			collisionValue = not collisionValue
		end

		local part = root:FindFirstChild(name)

		if part then
			if part:IsA("BasePart") then
				part.CanCollide = collisionValue
			else
				warn(string.format("Instance named %q was not a BasePart! Skipping...", name))
			end
		else
			warn(string.format("Couldn't find part named %q in collision mask! Skipping...", name))
		end
	end
end

return CollisionMask