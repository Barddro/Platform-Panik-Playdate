local pd <const> = playdate
local gfx <const> = playdate.graphics

class("LoseMenu").extends()

function LoseMenu:init()
    self:setSize(100, 30)
    self:setCenter(0.5, 0.5)
    self:moveTo(x, y)
    self:setZIndex(Z_INDEXES.UI)
    self:add()
    
    local w, h = self:getSize()

    gfx.drawTextAligned(
        self:formatRemainingTime(),
        w / 2,
        h / 2,
        kTextAlignment.center
    )
end

