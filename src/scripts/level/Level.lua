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

-- move everything below into ldtk entity data
TAGS = {
	Player = 1,
	Hazard = 2,
	Flag = 3
}

Z_INDEXES = {
	Player = 100,
	UI = 90,
	Hazard = 50,
	Flag = 45,
	Timer = 40,
}

-- class GameScene
class('Level').extends()

function Level:init(level_name)
    self.levelName = level_name
	ldtk.load_level(level_name)
end

function Level:goTo()
	-- insert fade/animation to black here
	gfx.sprite.removeAll()

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
			layerSprite:add()
			
			-- Collision
			local emptyTiles = ldtk.get_empty_tileIDs(self.levelName, "Solid", layer_name)
			if emptyTiles then
				gfx.sprite.addWallSprites(tilemap, emptyTiles)
			end
		end

		-- handle entities
		-- probably will want to implement flyweight here for spikes or other entities that share metadata
		if layer.entities then
			for _, entity in ipairs(layer.entities) do
				print(entity.name)
				local data = ENTITY_DATA[entity.name]
				print(data)
				-- may want to move from name to other field
				if data.class then
					data.class.fromEntity(entity)
				else
					print("WARNING: Unknown entity: ", entity.name)
				end

			end
		end
	end

 

	-- insert fade/animation to level here
end
