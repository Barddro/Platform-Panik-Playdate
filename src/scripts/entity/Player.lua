local pd <const> = playdate
local gfx <const> = playdate.graphics

class('Player').extends(AnimatedSprite)

local instance = nil   -- module-level singleton reference; not visible outside this file

function Player.fromEntity(entity)
    if instance then
        instance:moveTo(entity.position.x, entity.position.y)
        instance:add()   -- Level:goTo() calls gfx.sprite.removeAll(), which wipes
                          -- the player off the display list too — re-add it here.
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
	local playerImageTable = gfx.imagetable.new(GRAPHICS_PATH .. "entities/player-table-16-32")
	Player.super.init(self, playerImageTable)
	
	self:addState("idle", 1, 4, {tickStep = 4})
	self:addState("run", 5, 8, {tickStep = 5})
	self:addState("jump", 9, 9)
	self:playAnimation()
	
	--Sprite Properties
	self:moveTo(x, y)
	self:setZIndex(Z_INDEXES.Player)
	self:setTag(TAGS.Player)
	self:setCollideRect(6, 14, 10, 17)
	
	--Physics 
	self.xVelocity = 0
	self.yVelocity = 0
	self.gravity = 1.0
	
	self.groundAcceleration = 0.5
	self.airAcceleration = 0.3
	self.maxSpeedGrounded = 5.0
	self.maxSpeedAir = 5.0
	self.jumpVelocity = -8
	
	-- Player State
	self.touchingGround = false
	self.dead = false
	self.scene = nil
end


function Player:setScene(scene)
	self.scene = scene
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
			self:changeToIdleState() -- make an Idle Air state where you don't deccelerate // NVM ALREADY HANDLED IN REGULAR IDLE
		end
		self:applyGravity()
		self:handleAirInput()
	end
end

function Player:handleMovementAndCollisions()

	_, _, collisions, length = self:moveWithCollisions(self.x + self.xVelocity, self.y + self.yVelocity)

	self.touchingGround = false
	local died = false

	for i=1,length do
		local collision = collisions[i]
		local collisionType = collision.type
		local collisionObject = collision.other
		local collisionTag = collisionObject:getTag()

		if collisionType == gfx.sprite.kCollisionTypeSlide then
			if collision.normal.y == -1 then
				self.touchingGround = true
			end
			if (collision.normal.x == 1 and self.xVelocity < 0) or
			(collision.normal.x == -1 and self.xVelocity > 0) then
				self.xVelocity *= 0.1   -- keeps a tiny bit of push
			end
		end

		if collisionObject.onPlayerCollision then
			collisionObject:onPlayerCollision(self, self.scene)
		end

		if died then
			self:die()
		end
	end

	if self.xVelocity < 0 then
		self.globalFlip = 1
	elseif self.xVelocity > 0 then
		self.globalFlip = 0
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
	if pd.buttonIsPressed(pd.kButtonLeft) then
		-- flip if moving decently fast to the left]
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
	--self.xVelocity = 0
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
		-- instead of setting velocity, accelerate smoothly by adding velocity until cap
		--self.xVelocity = -self.maxSpeedGrounded
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

-- Physics Helper Functions
function Player:applyGravity()
    if not self.touchingGround then
        self.yVelocity += self.gravity
    else
        self.yVelocity = 0
    end
end

function Player:die()
	self.dead = true
	self.xVelocity = 0
	self.yVelocity = 0
	self:setCollisionEnabled(false)
end