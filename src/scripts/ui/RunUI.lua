-- wraps RunManager, pulls game state for UI rendering directly from RunManager itself
local pd <const> = playdate
local gfx <const> = playdate.graphics

class('RunUI').extends()

function RunUI:init(RunManager)
    self.components = {}
    -- may want to store this as data in a data file, including self.components.GameTimer.x = ___,  self.components.GameTimer.y = ___, etc
    self.components.GameTimer = GameTimerUI(RunManager.gameTimer, 200, 25)
end