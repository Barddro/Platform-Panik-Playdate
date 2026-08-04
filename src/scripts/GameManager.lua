STATES = {
    MAIN_MENU = 0,
    PAUSE = 1,
    RUN = 2,
}

class('GameManager').extends()

function GameManager:init()
    LDtk.load("assets/levels/world.ldtk", false)
    local runManager = RunManager()
    local runManagerUI = RunManagerUI(runManager)
    runManager:startRun()
end