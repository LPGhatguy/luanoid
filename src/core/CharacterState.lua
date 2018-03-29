local CharacterState = {}

CharacterState.Default = {
	orientationEnabled = true,
	controlEnabled = true,
	setCollisionForParts = {},
}

CharacterState.Stable = {
	setCollisionForParts = {
		LeftFoot = false,
		LowerLeftLeg = false,
		UpperLeftLeg = false,
		RightFoot = false,
		LowerRightLeg = false,
		UpperRightLeg = false,
	},
}

CharacterState.Ragdoll = {
	orientationEnabled = false,
	controlEnabled = false,
}

return CharacterState