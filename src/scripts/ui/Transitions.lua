local pd <const> = playdate
local gfx <const> = playdate.graphics

local SCREEN_W, SCREEN_H = 400, 240

function createTransitionSprite()
    local filledRect = gfx.image.new(SCREEN_W, SCREEN_H, gfx.kColorBlack)
    local transitionSprite = gfx.sprite.new(filledRect)
    transitionSprite:moveTo(200, 120)
    transitionSprite:setZIndex(10000)
    transitionSprite:setIgnoresDrawOffset(true)
    transitionSprite:add()
    return transitionSprite, filledRect
end

local function makeCircleMask(radius)
    local mask = gfx.image.new(SCREEN_W, SCREEN_H, gfx.kColorWhite) -- start opaque (fully masked out)
    gfx.pushContext(mask)
        gfx.setColor(gfx.kColorBlack) -- black = visible hole in the mask
        gfx.fillCircleAtPoint(200, 120, radius)
    gfx.popContext()
    return mask
end

function invertedCircleTransition(startValue, endValue, transitionTime)
    local transitionSprite, image = createTransitionSprite()

    image:setMaskImage(makeCircleMask(startValue))

    local transitionTimer = pd.timer.new(transitionTime, startValue, endValue, pd.easingFunctions.inOutCubic)
    transitionTimer.updateCallback = function(timer)
        image:setMaskImage(makeCircleMask(timer.value))
    end

    return transitionTimer, transitionSprite
end

function startTransition(onTransitionEndCallback)
    local transitionTimer, transitionSprite = invertedCircleTransition(450, 0, 500) -- 500ms, tweak as needed
    transitionTimer.timerEndedCallback = function()
        transitionSprite:remove()
        if onTransitionEndCallback then
            onTransitionEndCallback()
        end
    end
end