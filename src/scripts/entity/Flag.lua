local gfx <const> = playdate.graphics
local flagSprite <const> = gfx.image.new("assets/graphics/entities/flag.png")

--assert(flagSprite, "Flag image failed to load — check path/filename")


class("Flag").extends(Entity)

function Flag:init(x, y)

    Flag.super.init(self, x, y)

    self:setImage(flagSprite)

    self:setTag(TAGS.Flag)

    self:setCollideRect(3, 7, 10, 9)

    self:setZIndex(Z_INDEXES.Flag)

    self:addBehaviour(GoalBehaviour)
end

function Flag.fromEntity(entity, ...)
    --[[for key, val in pairs(entity.position) do
        print("key: ", key)
        print("value: ", val)
    end]]
    return Flag(entity.position.x, entity.position.y)
end