local pd <const> = playdate
local gfx <const> = playdate.graphics

class('Component').extends(gfx.sprite)

COMPONENT_ALIGN = {
    left = 0,
    center = 1,
    right = 2,
}

function Component:init(...)
    local args = table.pack(...)

    -- handle alignment
    if not args.align then
        self.align = left
    else
        self.align = args.align
    end
end

