local pd <const> = playdate
local gfx <const> = playdate.graphics

class('GameTimer').extends()

function GameTimer:init(dur, events)
    self.shouldDraw = true
    self.dur = dur
    self.timer = pd.timer.new(dur*1000, function ()
        events:emit("timer_finish")
    end
    )
    self.timer:pause()
end

function GameTimer:pause()
    self.timer.pause()
end

function GameTimer:start()
    self.timer:startTimer()
end

function GameTimer:reset()
    self.timer.reset()
    self.timer.pause()
end

function GameTimer:resetTo(new_dur)
    self.dur = new_dur
    -- reset to new dur here
end




