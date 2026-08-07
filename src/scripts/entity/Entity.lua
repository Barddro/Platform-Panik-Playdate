local gfx <const> = playdate.graphics

class("Entity").extends(gfx.sprite)

function Entity:init(x, y)
    Entity.super.init(self)
    self.behaviours = {}

    -- set default tag and z-index (should get overridden in concrete classes)
    self:setTag(Z_INDEXES.Default)
    self:setZIndex(Z_INDEXES.Default)

    self:setCenter(0, 0)
    self:moveTo(x, y)
    self:add()
end

function Entity:addBehaviour(behaviour)
    table.insert(self.behaviours, behaviour)
end

function Entity:onPlayerCollision(player, scene)
    for _, behavior in ipairs(self.behaviours) do
        if behavior.onPlayerCollision then
            behavior.onPlayerCollision(self, player, scene)
        end
    end
end