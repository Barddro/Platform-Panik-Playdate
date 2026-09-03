local gfx <const> = playdate.graphics

class('Camera').extends()

local instance = nil

-- don't call publicly
function Camera:init()
    
    if instance then return end

    self.getX = function () return 0 end
    self.getY = function () return 0 end
    self._enabled = false
    self._applyingMovement = false
    self._applyingMovementStep = 1
    self._offsetSeriesX = {}
    self._offsetSeriesY = {}
    self._offsetModifiers = {}
end

function Camera.getInstance()
    if not instance then
        instance = Camera()
    end
    return instance
end

function Camera:update()
    if self._enabled then
        baseX = self:getX()
        baseY = self:getY()

        if self._applyingMovement then
            if self._applyingMovementStep <= math.min(#self._offsetSeriesX, #self._offsetSeriesY) then
                baseX += self._offsetSeriesX[self._applyingMovementStep]
                baseY += self._offsetSeriesY[self._applyingMovementStep]
                self._applyingMovementStep += 1
            else
                self._applyingMovement = false
            end
        end

        for _, currentOffsetModifier in pairs(self._offsetModifiers) do
            xOffsetModifier, yOffsetModifier = table.unpack(currentOffsetModifier)
            baseX += xOffsetModifier()
            baseY += yOffsetModifier()
        end

        gfx.setDrawOffset(baseX, baseY)

    end
end

function Camera:disable()
    self._enabled = false
    gfx.setDrawOffset(0, 0)
end

function Camera:enable()
    self._enabled = true
end

function Camera:setPositionGetters(getX, getY)
    self.getX = getX
    self.getY = getY
end

--- Steps through offsetSeriesX and offsetSeriesY and applies this offset on top of other modifiers
--- @param offsetSeriesX table<integer>
--- @param offsetSeriesY table<integer> 
function Camera:applyMovement(offsetSeriesX, offsetSeriesY)
    self._applyingMovement = true
    self._applyingMovementStep = 1
    self._offsetSeriesX = offsetSeriesX
    self._offsetSeriesY = offsetSeriesY
end

function Camera:addOffsetModifier(offsetModifierName, xOffsetModifier, yOffsetModifier)
    self._offsetModifiers[offsetModifierName] = {xOffsetModifier, yOffsetModifier}
end

function Camera:removeOffsetModifier(name)
    if not self._offsetModifiers[name] then
        logger.warning("offset modifier" .. name .. "does not exist")
    else
        self._offsetModifiers[name] = nil
    end
end

function Camera:screenshake(strength)
    -- generate two series of random integers in range [-strength, strength] (one for x offsets and one for y offset), and pass off to 
end
