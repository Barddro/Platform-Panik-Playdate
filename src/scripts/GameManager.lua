

STATE_TRANSITIONS = {
    RUN = (function ()
        LDtk.load("assets/levels/world.ldtk", false)
        Events = EventBus()
        local runManager = InfiniteRunManager(3)
        local runUI = RunUI(runManager)
        runManager:startRun()
    end)
}

class('GameManager').extends()

function GameManager:init()
    self.state = STATES.MAIN_MENU
end

function GameManager:goTo(state)
    -- instead of handling it like this, we could instantiate Events here instead of in RunManager, (or use a separate EventBus entirely for top-level game state events), then handle this by registering events like Events:on("run_lose", GameManager:goTo(GAME_STATES.LOSE))

end