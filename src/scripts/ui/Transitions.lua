local pd <const> = playdate
local gfx <const> = playdate.graphics

function createTransitionSprite()
    local filledRect = gfx.image.new(400, 240, gfx.kColorBlack)
    local transitionSprite = gfx.sprite.new(filledRect)
    transitionSprite:moveTo(200, 120)
    transitionSprite:setZIndex(10000)
    transitionSprite:setIgnoresDrawOffset(true)
    transitionSprite:add()
    return transitionSprite
end

function invertedCircleTransition(startValue, endValue, transitionTime)
    local transitionSprite = createTransitionSprite()
    local circleMask = gfx.fillCircleAtPoint(400, 240, startValue)
    transitionSprite:setMaskImage(circleMask)
    local transitionTimer = pd.timer.new(transitionTime, startValue, endValue, pd.easingFunctions.inOutCubic)
    transitionTimer.updateCallback = function ()
        circleMask = gfx.fillCircleAtPoint(400, 240, timer.value)
    end
    return transitionTimer
end

function startTransition(onTransitionEndCallback)
    local transitionTimer = invertedCircleTransition(450, 0)
    transitionTimer.timerEndedCallback = onTransitionEndCallback
end