STATES = {
    MAIN_MENU = 0,
    PAUSE = 1,
    RUN = 2,
}

class('GameManager').extends()

function GameManager:init()
    LDtk.load("assets/levels/world.ldtk", false)
    Events = EventBus()
    local runManager = RunManager(3)
    local runUI = RunUI(runManager)
    runManager:startRun()
end