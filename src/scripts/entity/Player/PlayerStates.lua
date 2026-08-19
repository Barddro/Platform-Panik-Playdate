local pd <const> = playdate

-- Behavior definitions for Player's state machine (player.fsm). Each state
-- is responsible for:
--   - which animation to play on entry (via player:changeState, inherited
--     from AnimatedSprite -- NOT the same thing as player.fsm:transitionTo;
--     see the note at the top of Player.lua)
--   - its own per-frame physics flavor
--   - its own input handling and the transitions that fall out of it
--
-- Tuning numbers live in PlayerData.lua. Timers (jump buffer, wall
-- coyote, wall-jump lock) are Countdown instances owned by Player and
-- ticked centrally in Player:update() / Player:handleMovementAndCollisions().

PlayerStates = {}

-- idle ----------------------------------------------------------------
PlayerStates.idle = {
	enter = function(player)
		player:changeState("idle")
	end,
	update = function(player)
		player:applyGravity()

		-- ground friction while no direction is held
		if math.abs(player.xVelocity) < PlayerData.groundFrictionStopThreshold then
			player.xVelocity = 0
		else
			player.xVelocity *= PlayerData.groundFrictionFactor
		end

		if pd.buttonJustPressed(pd.kButtonA) then
			player.fsm:transitionTo("jump", PlayerData.jumpVelocity)
		elseif pd.buttonIsPressed(pd.kButtonLeft) then
			player.fsm:transitionTo("run", "left")
		elseif pd.buttonIsPressed(pd.kButtonRight) then
			player.fsm:transitionTo("run", "right")
		end
	end,
}

-- run -------------------------------------------------------------------
PlayerStates.run = {
	enter = function(player, direction)
		player:changeState("run")
		player:accelerateGround(direction)
	end,
	update = function(player)
		player:applyGravity()

		if pd.buttonJustPressed(pd.kButtonA) then
			player.fsm:transitionTo("jump", PlayerData.jumpVelocity)
		elseif pd.buttonIsPressed(pd.kButtonLeft) then
			player:accelerateGround("left")
		elseif pd.buttonIsPressed(pd.kButtonRight) then
			player:accelerateGround("right")
		else
			player.fsm:transitionTo("idle")
		end
	end,
}

-- jump / fall -------------------------------------------------------------
-- Shared "airborne, normal gravity" state. `launchVelocity` is optional:
-- pass it for an actual jump impulse (grounded jump, buffered jump);
-- omit it to just become airborne without a boost (falling off a wall,
-- or a wall jump that already set its own velocity beforehand).
PlayerStates.jump = {
	enter = function(player, launchVelocity)
		if launchVelocity then
			player.yVelocity = launchVelocity
		end
		player:changeState("jump")
	end,
	update = function(player)
		if player.touchingGround then
			player.fsm:transitionTo("idle")
			return
		end
		if player:canEnterWallSlide() then
			player.fsm:transitionTo("wallSlide")
			return
		end
		player:applyGravity()
		player:handleAirInput()
	end,
}

-- dive --------------------------------------------------------------------
-- Holds its pose and ignores input; only exits via landing or a buffered
-- jump (which routes through diveFlipOnLand below).

PlayerStates.dive = {
	diveFlipOnLand = true,
	enter = function(player)
		if pd.buttonIsPressed(pd.kButtonLeft) then
			player.globalFlip = 1
		elseif pd.buttonIsPressed(pd.kButtonRight) then
			player.globalFlip = 0
		end
		player.diveDirection = player.globalFlip == 1 and -1 or 1
		player.xVelocity =
			player.diveDirection * PlayerData.diveBoostSpeed
			+ 0.5 * player.xVelocity
		player.yVelocity =
			0.5 * player.yVelocity - PlayerData.diveUpwardBoost
		player:changeState("dive")
	end,
	update = function(player)
		if player.touchingGround then
			player.fsm:transitionTo("idle")
			return
		end
		player:applyGravity(PlayerData.diveGravityMultiplier)
	end,
}

-- diveFlip ------------------------------------------------------------
-- Entered only via a buffered jump landing mid-dive (see
-- Player:handleMovementAndCollisions). Its animation is configured with
-- nextAnimation = "jump" in Player:init, so the VISUAL flip auto-advances
-- to the jump pose once it finishes playing -- but that's animation-only.
-- This behavioral state (and its boosted fall gravity) stays active until
-- touchingGround actually becomes true, same as every other airborne state.
PlayerStates.diveFlip = {
	enter = function(player)
		player.yVelocity =
			PlayerData.jumpVelocity - PlayerData.diveFlipUpwardBoost
		player.xVelocity +=
			player.diveDirection * PlayerData.landingBoostSpeed
		local cap = PlayerData.maxSpeedAir * PlayerData.landingBoostCapMultiplier
		if player.xVelocity > cap then
			player.xVelocity = cap
		elseif player.xVelocity < -cap then
			player.xVelocity = -cap
		end
        logger.info("x velocity after: ", player.xVelocity)
		player:changeState("diveFlip")
	end,
	update = function(player)
        local maxSpeedAirBoosted = PlayerData.maxSpeedAir * PlayerData.landingBoostCapMultiplier
		if player.touchingGround then
			player.fsm:transitionTo("idle")
			return
		end
		player:applyGravity(PlayerData.diveGravityMultiplier)
		player:handleAirInput(maxSpeedAirBoosted)
	end,
}

-- wallSlide -----------------------------------------------------------
PlayerStates.wallSlide = {
	lockFacing = true, -- always faces away from the wall; skip the generic facing update
	enter = function(player)
		player.globalFlip = player.wallJumpAwayDirection == 1 and 0 or 1
		player:changeState("wallSlide")
	end,
	update = function(player)
		if player.touchingGround then
			player.fsm:transitionTo("idle")
			return
		end
		if not player:canEnterWallSlide() then
			-- let go, or slid off the wall's edge -- fall normally, no launch impulse
			player.fsm:transitionTo("jump")
			return
		end
		player:applyWallSlideGravity()
		if pd.buttonJustPressed(pd.kButtonA) then
			player:performWallJump()
		end
	end,
}