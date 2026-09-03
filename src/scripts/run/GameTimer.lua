local pd <const> = playdate
local gfx <const> = playdate.graphics

class('GameTimer').extends()

function GameTimer:init(dur)
    self.dur = dur
    self.timer = pd.timer.new(dur*1000, function ()
        Events:emit("timer_finish")
    end)
    self.timer.discardOnCompletion = false
    self.timer:pause()
end

function GameTimer:pause()
    self.timer:pause()
end

function GameTimer:start()
    self.timer:start()
end

function GameTimer:reset()
    self.timer:reset()
    self.timer:pause()
end

function GameTimer:resetTo(new_dur)
    self.dur = new_dur
    -- reset to new dur here
end






