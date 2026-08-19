PlayerData = {
	gravity = 1.0,

	groundAcceleration = 0.5,
	airAcceleration = 0.3,
	maxSpeedGrounded = 5.0,
	maxSpeedAir = 5.0,
	jumpVelocity = -8,
    backToMaxAirDeceleration = 0.5,

	-- Ground friction (deceleration while grounded with no direction held)
	groundFrictionFactor = 0.8,
	groundFrictionStopThreshold = 0.2,

	-- Dive
	diveBoostSpeed = 7.0, -- horizontal impulse when the dive starts
	diveUpwardBoost = 4,
	diveGravityMultiplier = 1.3,

	-- Jump buffer / landing boost
    diveFlipUpwardBoost = 1.5,
	jumpBufferWindow = 6,
	landingBoostSpeed = 2.0,
    landingBoostCapMultiplier = 1.6,

	-- Wall interaction
	wallSlideMaxFallSpeed = 2.0,
	wallStickSpeed = 0.2,    -- tiny nudge into the wall each frame
	wallJumpVelocityX = 4.5,
	wallJumpVelocityY = -7.5,
	wallJumpLockWindow = 8,
	wallCoyoteWindow = 6,

	-- Collision response
	wallBumpDamping = 0.1,   -- keeps a tiny bit of push when bonking into a wall
}