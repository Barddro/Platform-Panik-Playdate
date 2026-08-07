local pd <const> = playdate
local gfx <const> = playdate.graphics

class('GameTimerUI').extends(gfx.sprite)

function GameTimerUI:init(gameTimer, x, y)
    GameTimerUI.super.init(self)

    self.gameTimer = gameTimer
    self.shouldDraw = true

    self:setSize(100, 30)
    self:setCenter(0.5, 0.5)
    self:moveTo(x, y)
    self:setZIndex(Z_INDEXES.UI)
    self:add()
end

function GameTimerUI:formatRemainingTime()
    local remaining = self.gameTimer.timer.timeLeft
    if remaining <= 0 then return "00.000" end
    local sec = math.floor((remaining % 60000) / 1000)
    local remain_ms = remaining % 1000
    return string.format("%02d.%03d", sec, remain_ms)
end

function GameTimerUI:draw()
    local w, h = self:getSize()
    gfx.drawTextAligned(
        self:formatRemainingTime(),
        w / 2,
        h / 2,
        gfx.kTextAlignment.center
    )
end

function GameTimerUI:update()
    if self.shouldDraw then
        self:markDirty()
    end
end