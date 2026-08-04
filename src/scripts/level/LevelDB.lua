local ldtk <const> = LDtk

-- we store all level metadata inside a json, and load that during startup
-- before a run begins, we randomly generate a sequence of levels, and then load all levels from sequence into memory

class('LevelDB').extends()


function LevelDB:init()
end

function LevelDB:load()

end