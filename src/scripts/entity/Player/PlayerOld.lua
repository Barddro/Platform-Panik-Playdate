--[[
local pd <const> = playdate
local gfx <const> = playdate.graphics

class('Player').extends(AnimatedSprite)

local instance = nil   -- module-level singleton reference; not visible outside this file

function Player.fromEntity(entity)
    if instance then
        instance:moveTo(entity.position.x, entity.position.y)
    else
        instance = Player(entity.position.x, entity.position.y)
    end
    return instance
end

function Player.getInstance()
    return instance
end

function Player:init(x, y)
	-- State Machine
	local playerImageTable = gfx.imagetable.new(GRAPHICS_PATH .. "entities/player-table-32-32")
	Player.super.init(self, playerImageTable)

	self:addState("idle", 1, 4, {tickStep = 4})
	self:addState("run", 5, 8, {tickStep = 5})
	self:addState("jump", 9, 9)
	self:addState("dive", 10, 10, {tickStep = 1})
	self:addState("diveFlip", 11, 15, {tickStep = 2, loop = false, nextAnimation = "jump"})
	self:addState("wallSlide", 16, 16)

	self:playAnimation()

	--Sprite Properties
	self:moveTo(x, y)
	self:setZIndex(Z_INDEXES.Player)
	self:setTag(TAGS.Player)
	self:setCollideRect(14, 14, 10, 17)

	--Physics
	self.xVelocity = 0
	self.yVelocity = 0
	self.gravity = 1.0

	self.groundAcceleration = 0.5
	self.airAcceleration = 0.3
	self.maxSpeedGrounded = 5.0
	self.maxSpeedAir = 5.0
	self.jumpVelocity = -8

	-- Dive Tuning
	self.diveBoostSpeed = 7.0 -- horizontal impulse when the dive starts
	self.diveUpwardBoost = 4
	self.diveGravityMultiplier = 1.5 -- extra gravity while diving/flipping

	-- Jump Buffer / Landing Boost Tuning
	self.jumpBufferWindow = 6
	self.jumpBufferTimer = 0
	self.landingBoostSpeed = 3.0
	self.landingBoostCap = self.maxSpeedAir * 1.6

	-- Wall Interaction Tuning
	self.wallSlideMaxFallSpeed = 2.0
	self.wallStickSpeed = 0.2 -- tiny nudge into the wall each frame
	self.wallJumpVelocityX = 4.5
	self.wallJumpVelocityY = -7.5
	self.wallJumpLockWindow = 8
	self.wallCoyoteWindow = 6

	-- Wall state
	self.touchingWall = false
	self.wallJumpAwayDirection = 0 -- +1/-1, direction a wall jump would push (set whenever touchingWall)
	self.wallCoyoteTimer = 0
	self.wallJumpLockTimer = 0

	-- Player State
	self.touchingGround = false
	self.dead = false
end

function Player:collisionResponse(other)
	local tag = other:getTag()
	if tag == TAGS.Hazard then
		return gfx.sprite.kCollisionTypeOverlap
	end
	return gfx.sprite.kCollisionTypeSlide
end

function Player:update()
	print("global flip: ", self.globalFlip)
	if self.dead then
		return
	end

	-- Track jump-button presses in a short buffer so a press just before landing still registers (see performBufferedJump).
	if pd.buttonJustPressed(pd.kButtonA) then
		self.jumpBufferTimer = self.jumpBufferWindow
	elseif self.jumpBufferTimer > 0 then
		self.jumpBufferTimer -= 1
	end

	self:updateAnimation()
	self:handleState()
	self:handleMovementAndCollisions()
end

function Player:handleState()
	if self.currentState == "idle" then
		self:applyGravity()
		self:handleGroundInput()
	elseif self.currentState == "run" then
		self:applyGravity()
		self:handleGroundInput()
	elseif self.currentState == "jump" then
		if self.touchingGround then
			self:changeToIdleState()
		elseif self:canEnterWallSlide() then
			self:changeToWallSlideState()
		end
		self:applyGravity()
		self:handleAirInput()
	elseif self.currentState == "dive" then
		if self.touchingGround then
			self:changeToIdleState()
		else
			-- holds the pose indefinitely; only exits via landing or a
			-- buffered jump (both handled outside this branch)
			self:applyGravity(self.diveGravityMultiplier)
		end
	elseif self.currentState == "diveFlip" then
		if self.touchingGround then
			self:changeToIdleState()
		else
			self:applyGravity(self.diveGravityMultiplier)
			self:handleAirInput()
		end
	elseif self.currentState == "wallSlide" then
		if self.touchingGround then
        	self:changeToIdleState()
		elseif not self:canEnterWallSlide() then
			self:changeState("jump") -- let go, or slid off the wall's edge; fall normally
		else
			self:applyWallSlideGravity()
			self:handleWallSlideInput()
		end
	end
end

function Player:handleMovementAndCollisions()
	local wasTouchingWall = self.touchingWall
	local wasTouchingGround = self.touchingGround

	_, _, collisions, length = self:moveWithCollisions(self.x + self.xVelocity, self.y + self.yVelocity)

	self.touchingGround = false
	self.touchingWall = false

	for i=1,length do
		local collision = collisions[i]
		local collisionType = collision.type
		local collisionObject = collision.other
		local collisionTag = collisionObject:getTag()

		if collisionType == gfx.sprite.kCollisionTypeSlide then
			if collision.normal.y == -1 then
				self.touchingGround = true
			end
			if collision.normal.x ~= 0 then
				self.touchingWall = true
				self.wallJumpAwayDirection = collision.normal.x
			end
			if (collision.normal.x == 1 and self.xVelocity < 0) or
			(collision.normal.x == -1 and self.xVelocity > 0) then
				self.xVelocity *= 0.1   -- keeps a tiny bit of push
			end
		end

		if collisionObject.onPlayerCollision then
			collisionObject:onPlayerCollision()
		end

	end

	if self.touchingGround then
		self.touchingWall = false -- landing takes priority over a wall hug
	end

	if wasTouchingWall and not self.touchingWall then
		self.wallCoyoteTimer = self.wallCoyoteWindow
	elseif self.wallCoyoteTimer > 0 then
		self.wallCoyoteTimer -= 1
	end

	-- Buffered jump: if the player pressed jump shortly before touching down,
	-- fire the jump right now (with the flip flourish) instead of making them
	-- wait for the next ground-input poll. Must happen after the collision
	-- pass above — we need to know we actually just landed this frame.
	if (not wasTouchingGround) and self.touchingGround and self.jumpBufferTimer > 0 then
		-- self.currentState here still reflects whatever was active going
		-- into this frame's landing (handleState ran earlier this same
		-- frame using the still-false touchingGround, so it hasn't changed
		-- state on us). This is the reliable way to know "was mid-dive".
		local wasMidDive = (self.currentState == "dive")
		self:performBufferedJump(wasMidDive)
	end

	local doNotFlip = (self.currentState == "wallSlide")

	if not doNotFlip then
		if self.xVelocity < 0 then
			self.globalFlip = 1
		elseif self.xVelocity > 0 then
			self.globalFlip = 0
		end
	end

end

-- Input Helper Functions
function Player:handleGroundInput()
	if pd.buttonJustPressed(pd.kButtonA) then
		self:changeToJumpState()
	elseif pd.buttonIsPressed(pd.kButtonLeft) then
		self:changeToRunState("left")
	elseif pd.buttonIsPressed(pd.kButtonRight) then
		self:changeToRunState("right")
	else
		self:changeToIdleState()
	end
end

function Player:handleAirInput()
	if pd.buttonJustPressed(pd.kButtonA) and self.wallCoyoteTimer > 0 then
		self:performWallJump()
		return
	end

	if pd.buttonJustPressed(pd.kButtonB) then
		self:changeToDiveState()
		return
	end

	if self.wallJumpLockTimer > 0 then
		self.wallJumpLockTimer -= 1
		return
	end

	if pd.buttonIsPressed(pd.kButtonLeft) then
		self.xVelocity -= self.airAcceleration
		if self.xVelocity < -0.1 * self.maxSpeedAir then
			self.globalFlip = 1
		end
		if self.xVelocity < -self.maxSpeedAir then
			self.xVelocity = -self.maxSpeedAir
		end
	elseif pd.buttonIsPressed(pd.kButtonRight) then
		self.xVelocity += self.airAcceleration
		if self.xVelocity > 0.1 * self.maxSpeedAir then
			self.globalFlip = 0
		end
		if self.xVelocity > self.maxSpeedAir then
			self.xVelocity = self.maxSpeedAir
		end
	end
end

-- State transitions
function Player:changeToIdleState()
	if self.touchingGround then
		if math.abs(self.xVelocity) < 0.2 then
			self.xVelocity = 0
		else
			self.xVelocity *= 0.8
		end
	end
	self:changeState("idle")
end

function Player:changeToRunState(direction)
	if direction == "left" then
		self.globalFlip = 1
		if self.xVelocity > -self.maxSpeedGrounded then
			self.xVelocity -= self.groundAcceleration
		end
		if self.xVelocity < -self.maxSpeedGrounded then
			self.xVelocity = -self.maxSpeedGrounded
		end
	elseif direction == "right" then
		self.globalFlip = 0
		if self.xVelocity < self.maxSpeedGrounded then
			self.xVelocity += self.groundAcceleration
		end
		if self.xVelocity > self.maxSpeedGrounded then
			self.xVelocity = self.maxSpeedGrounded
		end
	end
	self:changeState("run")
end

function Player:changeToJumpState()
	self.yVelocity = self.jumpVelocity
	self:changeState("jump")
end

function Player:changeToDiveState()
	if pd.buttonIsPressed(pd.kButtonLeft) then
		self.globalFlip = 1
	elseif pd.buttonIsPressed(pd.kButtonRight) then
		self.globalFlip = 0
	end
	local direction = self.globalFlip == 1 and -1 or 1
	self.xVelocity = (direction * self.diveBoostSpeed) + (0.5 * self.xVelocity)
	self.yVelocity = 0.5*self.yVelocity - self.diveUpwardBoost
	self:changeState("dive")
end

function Player:changeToDiveFlipState()
	local direction = self.globalFlip == 1 and -1 or 1
	self.touchingGround = false
	self.yVelocity = self.jumpVelocity
	self.xVelocity += direction * self.landingBoostSpeed
	if self.xVelocity > self.landingBoostCap then
		self.xVelocity = self.landingBoostCap
	elseif self.xVelocity < -self.landingBoostCap then
		self.xVelocity = -self.landingBoostCap
	end
	self:changeState("diveFlip")
end

function Player:changeToDieState()
	self.dead = true
	self.xVelocity = 0
	self.yVelocity = 0
	self:setCollisionEnabled(false)
end

-- Fires when a buffered jump press lands right as the player touches ground.
-- Carries existing horizontal momentum (e.g. from a dive) plus a boost on
-- top. If the landing was mid-dive, plays the flip as a takeoff flourish
-- (diveFlip's own nextAnimation="jump" hands control back to a normal air
-- state once it's done) otherwise it's just a plain boosted jump.
function Player:performBufferedJump(wasMidDive)
	if wasMidDive then
		self:changeToDiveFlipState()
	else
		self:changeToJumpState()
	end

	self.jumpBufferTimer = 0
end

function Player:canEnterWallSlide()
	return self.touchingWall and self:isPressingTowardWall()
end

function Player:isPressingTowardWall()
	if self.wallJumpAwayDirection == 0 then return false end
	local towardWall = -self.wallJumpAwayDirection
	if towardWall < 0 then
		return pd.buttonIsPressed(pd.kButtonLeft)
	else
		return pd.buttonIsPressed(pd.kButtonRight)
	end
end

function Player:changeToWallSlideState()
	self.globalFlip = self.wallJumpAwayDirection == 1 and 0 or 1 -- face away from wall
	self:changeState("wallSlide")
end

function Player:applyWallSlideGravity()
	self.yVelocity += self.gravity
	if self.yVelocity > self.wallSlideMaxFallSpeed then
		self.yVelocity = self.wallSlideMaxFallSpeed
	end
	self.xVelocity = -self.wallJumpAwayDirection * self.wallStickSpeed -- nudge toward wall to continue registering touching wall
end

function Player:handleWallSlideInput()
	if pd.buttonJustPressed(pd.kButtonA) then
		self:performWallJump()
	end
end

function Player:performWallJump()
	local direction = self.wallJumpAwayDirection
	self.xVelocity = direction * self.wallJumpVelocityX
	self.yVelocity = self.wallJumpVelocityY
	self.globalFlip = direction == 1 and 0 or 1
	self.wallJumpLockTimer = self.wallJumpLockWindow
	self.wallCoyoteTimer = 0
	self.touchingWall = false
	self:changeState("jump")
end

-- Physics Helper Functions
function Player:applyGravity(multiplier)
	multiplier = multiplier or 1
    if not self.touchingGround then
        self.yVelocity += self.gravity * multiplier
    else
        self.yVelocity = 0
    end
end
]]