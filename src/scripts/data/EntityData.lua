ENTITY_DATA = {
    -- could try moving each of these into the respective classes' files
    -- one good reason for this is that it makes it independent of import order in main (why cant lua have regular imports)
        --> before, if data is imported before entity classes, classes will not be initialized, thus Spike = nil, Flag = nil, etc.
        -- if these are added after the classes are created by class('Spike') or class('Flag'), then order is independent
    Spike = {
        class = Spike
    },

    Flag = {
        class = Flag
    },

    PlayerSpawn = {
        class = Player
    }
}