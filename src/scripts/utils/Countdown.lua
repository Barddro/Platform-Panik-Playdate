class('Countdown').extends()

function Countdown:init(durationFrames)
	self.duration = durationFrames
	self.remaining = 0
end

-- Restart the countdown at full duration.
function Countdown:start()
	self.remaining = self.duration
end

-- Immediately expire the countdown.
function Countdown:clear()
	self.remaining = 0
end

-- Advance one frame. Call once per update(), every frame.
function Countdown:tick()
	if self.remaining > 0 then
		self.remaining -= 1
	end
end

function Countdown:isActive()
	return self.remaining > 0
end

-- Reads AND clears in one step -- handy for "buffered input" checks where
-- reading it should also consume it so it can't fire twice.
function Countdown:consume()
	local active = self:isActive()
	self.remaining = 0
	return active
end