local gfx <const> = playdate.graphics
local spikeSprite <const> = gfx.image.new("assets/graphics/entities/spike.png")

assert(spikeSprite, "Spike image failed to load — check path/filename")

class("Spike").extends(Entity)

function Spike:init(x, y)

    Spike.super.init(self, x, y)

    self:setImage(spikeSprite)
 
    self:setTag(TAGS.Hazard)

    self:setCollideRect(3, 7, 10, 9)

    self:setZIndex(Z_INDEXES.Hazard)

    self:addBehaviour(KillBehaviour)
end

function Spike.fromEntity(entity, ...)
    return Spike(entity.position.x, entity.position.y)
end