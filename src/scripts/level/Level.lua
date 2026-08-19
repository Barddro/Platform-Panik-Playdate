local gfx <const> = playdate.graphics
local ldtk <const> = LDtk

-- for now, we just use LDtk. However, later down the road need an internal format for storing levels (both in memory and on disk) to allow support for level creator

--[[ 
    for internal format:
    each layer is a 'bytemap' table of size screen_x / tilesize, screen_y / tilesize where each entry represents the entity/'thing' at that tile in the grid
    we maintain several of these:

    1. background
    2. ground --> for this we will either need to implement auto-tiling rules into runtime, or bake the tiles before
    3. entities

]]

-- class GameScene
class('Level').extends()

function Level:init(level_name)
    self.levelName = level_name
	self.sprites = {}
	ldtk.load_level(level_name)
end

function Level:addSprite(sprite)
    sprite:add()
    table.insert(self.sprites, sprite)
    return sprite
end

function Level:goTo()

	local filledRect = gfx.image.new(400, 240, gfx.kColorBlack)
    local bgRect = gfx.sprite.new(filledRect)
	bgRect:moveTo(200, 120)
	bgRect:setZIndex(0)
	self:addSprite(bgRect)

	-- refactor below to use actual layer names for tiles
	for layer_name, layer in pairs(ldtk.get_layers(self.levelName)) do
		-- handle tiles
		if layer.tiles then
			local tilemap = ldtk.create_tilemap(self.levelName, layer_name)
			
			local layerSprite = gfx.sprite.new()
			layerSprite:setTilemap(tilemap)
			layerSprite:setCenter(0, 0)
			layerSprite:moveTo(0, 0)
			layerSprite:setZIndex(layer.zIndex)
			self:addSprite(layerSprite)
			-- for now, we will add to sprites at each 'part' (tilemap, entity, etc.) but may want to refactor later to generalize more, will avoid weird bugs
			
			-- Collision
			local emptyTiles = ldtk.get_empty_tileIDs(self.levelName, "Solid", layer_name)
			if emptyTiles then
				wallTiles = gfx.sprite.addWallSprites(tilemap, emptyTiles)
				for _, tile in ipairs(wallTiles) do
					self:addSprite(tile)
				end
			end
		end

		-- handle entities
		-- probably will want to implement flyweight here for spikes or other entities that share metadata
		if layer.entities then
			for _, entity in ipairs(layer.entities) do
				local data = ENTITY_DATA[entity.name]
				-- may want to move from name to other field
				if data.class then
					concreteEntity = data.class.fromEntity(entity)
					self:addSprite(concreteEntity)
				else
					logger.waring("Unknown entity:", entity.name)
				end

			end
		end
	end
	-- insert fade/animation to level here?
end

function Level:cleanup()
    for _, sprite in ipairs(self.sprites) do
        sprite:remove()
    end

    self.sprites = {}
end