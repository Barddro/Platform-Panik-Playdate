local pd <const> = playdate
local gfx <const> = playdate.graphics

class('Player').extends(AnimatedSprite)

local instance = nil -- module-level singleton reference; not visible outside this file

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
	local playerImageTable = gfx.imagetable.new(GRAPHICS_PATH .. "entities/player-table-32-32")
	Player.super.init(self, playerImageTable)

	self:addState("idle", 1, 4, {tickStep = 4})
	self:addState("run", 5, 8, {tickStep = 5})
	self:addState("jump", 9, 9)
	self:addState("dive", 10, 10, {tickStep = 1})
	self:addState("diveFlip", 11, 15, {tickStep = 2, loop = false, nextAnimation = "jump"})
	self:addState("wallSlide", 16, 16)

	self:playAnimation()

	-- Sprite properties
	self:moveTo(x, y)
	self:setZIndex(Z_INDEXES.Player)
	self:setTag(TAGS.Player)
	self:setCollideRect(12, 13, 6, 19)

	-- Physics state
	self.xVelocity = 0
	self.yVelocity = 0

	-- Collision flags
	self.touchingGround = false
	self.touchingWall = false

    self.diveDirection = 0
	self.wallJumpAwayDirection = 0 -- +1/-1, direction a wall jump would push (set whenever touchingWall)

	-- Input-buffer / grace-period timers
	self.jumpBuffer = Countdown(PlayerData.jumpBufferWindow)
	self.wallCoyoteTimer = Countdown(PlayerData.wallCoyoteWindow)
	self.wallJumpLockTimer = Countdown(PlayerData.wallJumpLockWindow)

	self.dead = false

	self.fsm = StateMachine(self, PlayerStates, "idle")
end

function Player:collisionResponse(other)
	local tag = other:getTag()
	if tag == TAGS.Hazard then
		return gfx.sprite.kCollisionTypeOverlap
	end
	return gfx.sprite.kCollisionTypeSlide
end

function Player:update()
	if self.dead then
		return
	end

	if pd.buttonJustPressed(pd.kButtonA) then
		self.jumpBuffer:start()
	else
		self.jumpBuffer:tick()
	end
	self.wallJumpLockTimer:tick()

	self:updateAnimation()
	self.fsm:update()
	self:handleMovementAndCollisions()
end

function Player:handleMovementAndCollisions()
	local wasTouchingWall = self.touchingWall
	local wasTouchingGround = self.touchingGround

	local _, _, collisions, length = self:moveWithCollisions(self.x + self.xVelocity, self.y + self.yVelocity)

	self.touchingGround = false
	self.touchingWall = false

	for i = 1, length do
		local collision = collisions[i]
		local collisionObject = collision.other

		if collision.type == gfx.sprite.kCollisionTypeSlide then
			if collision.normal.y == -1 then
				self.touchingGround = true
			end
			if collision.normal.x ~= 0 then
				self.touchingWall = true
				self.wallJumpAwayDirection = collision.normal.x
			end
			if (collision.normal.x == 1 and self.xVelocity < 0) or
			   (collision.normal.x == -1 and self.xVelocity > 0) then
				self.xVelocity *= PlayerData.wallBumpDamping
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
		self.wallCoyoteTimer:start()
	else
		self.wallCoyoteTimer:tick()
	end

	-- Buffered jump: if the player pressed jump shortly before touching
	-- down, fire it now instead of waiting for next frame's grounded input.
	local justLanded = (not wasTouchingGround) and self.touchingGround
	if justLanded and self.jumpBuffer:isActive() then
		if self.fsm.current.diveFlipOnLand then
			self.fsm:transitionTo("diveFlip")
		else
			self.fsm:transitionTo("jump", PlayerData.jumpVelocity)
		end
		self.touchingGround = false
		self.jumpBuffer:consume()
	end

	self:updateFacing()
end

-- Facing ------------------------------------------------------------------
function Player:updateFacing()
	if self.fsm.current.lockFacing then
		return
	end
	if self.xVelocity < 0 then
		self.globalFlip = 1
	elseif self.xVelocity > 0 then
		self.globalFlip = 0
	end
end

-- Shared movement helpers (used by more than one state) --------------------
function Player:accelerateGround(direction)
	if direction == "left" then
		if self.xVelocity > -PlayerData.maxSpeedGrounded then
			self.xVelocity -= PlayerData.groundAcceleration
		end
		if self.xVelocity < -PlayerData.maxSpeedGrounded then
			self.xVelocity = -PlayerData.maxSpeedGrounded
		end
	elseif direction == "right" then
		if self.xVelocity < PlayerData.maxSpeedGrounded then
			self.xVelocity += PlayerData.groundAcceleration
		end
		if self.xVelocity > PlayerData.maxSpeedGrounded then
			self.xVelocity = PlayerData.maxSpeedGrounded
		end
	end
end

--[[
function Player:handleAirInput()

	if pd.buttonJustPressed(pd.kButtonA) and self.wallCoyoteTimer:isActive() then
		self:performWallJump()
		return
	end

	if pd.buttonJustPressed(pd.kButtonB) then
		self.fsm:transitionTo("dive")
		return
	end

	if self.wallJumpLockTimer:isActive() then
		return
	end

	if pd.buttonIsPressed(pd.kButtonLeft) then
		self.xVelocity -= PlayerData.airAcceleration
		if self.xVelocity < -PlayerData.maxSpeedAir then
			self.xVelocity = -PlayerData.maxSpeedAir
		end
	elseif pd.buttonIsPressed(pd.kButtonRight) then
		self.xVelocity += PlayerData.airAcceleration
		if self.xVelocity > PlayerData.maxSpeedAir then
			self.xVelocity = PlayerData.maxSpeedAir
		end
	end
end
]]

function Player:handleAirInput(maxSpeedAir)

    if not maxSpeedAir then maxSpeedAir = PlayerData.maxSpeedAir end

	if pd.buttonJustPressed(pd.kButtonA) and self.wallCoyoteTimer:isActive() then
		self:performWallJump()
		return
	end

	if pd.buttonJustPressed(pd.kButtonB) then
		self.fsm:transitionTo("dive")
		return
	end

	if self.wallJumpLockTimer:isActive() then
		return
	end

	if pd.buttonIsPressed(pd.kButtonLeft) then
		self.xVelocity -= PlayerData.airAcceleration
		if self.xVelocity < -maxSpeedAir then
			self.xVelocity = -maxSpeedAir
		end
	elseif pd.buttonIsPressed(pd.kButtonRight) then
		self.xVelocity += PlayerData.airAcceleration
		if self.xVelocity > maxSpeedAir then
			self.xVelocity = maxSpeedAir
		end
	end
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

function Player:performWallJump()
	local direction = self.wallJumpAwayDirection
	self.xVelocity = direction * PlayerData.wallJumpVelocityX
	self.yVelocity = PlayerData.wallJumpVelocityY
	self.wallJumpLockTimer:start()
	self.wallCoyoteTimer:clear()
	self.touchingWall = false
	self.fsm:transitionTo("jump")
end

-- Physics helpers -----------------------------------------------------
function Player:applyGravity(multiplier)
	multiplier = multiplier or 1
	if not self.touchingGround then
		self.yVelocity += PlayerData.gravity * multiplier
	else
		self.yVelocity = 0
	end
end

function Player:applyWallSlideGravity()
	self.yVelocity += PlayerData.gravity
	if self.yVelocity > PlayerData.wallSlideMaxFallSpeed then
		self.yVelocity = PlayerData.wallSlideMaxFallSpeed
	end
	self.xVelocity = -self.wallJumpAwayDirection * PlayerData.wallStickSpeed
end

-- Kept as its own method (not routed through the fsm) since there's no
-- "die" animation state -- self.dead is checked at the top of update()
-- and short-circuits everything else, same as before. Name kept exactly
-- as-is in case something outside this file calls it directly (e.g. a
-- hazard's collision handler).
function Player:changeToDieState()
	self.dead = true
	self.xVelocity = 0
	self.yVelocity = 0
	self:setCollisionEnabled(false)
	-- If you want RunManager/UI to react (e.g. show a death screen),
	-- this is a natural spot for Events.publish("playerDied"), matching
	-- the EventBus pattern used elsewhere.
end