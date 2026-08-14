local pd <const> = playdate
local gfx <const> = playdate.graphics

class('Document').extends()

function Document:init(screen_x, screen_y)
    self.screen_x = screen_x
    self.screen_y = screen_y

    self.components = {}
end

function Document:add(component)

end

function Document:draw()
    -- here we handle computing layout from component tree, including spacing offsets, etc
end