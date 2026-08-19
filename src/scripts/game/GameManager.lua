local pd <const> = playdate
local gfx <const> = playdate.graphics

GameStateTransitions = {

}

class('GameManager').extends()

function GameManager:registerState(stateName, goToFunction, cleanupFunction)
    if self.GameStates[stateName] == nil then self.GameStates[stateName] = {} end
    self.GameStates[stateName].goTo = goToFunction
    self.GameStates[stateName].cleanup = cleanupFunction
end

function GameManager:cleanupCurrent()
    if not self.currentState or not self.GameStates[self.currentState] then
        logger.warning("current state not registered")
        return
    end
    self.GameStates[currentState].cleanup()
end

function GameManager:goTo(state, ...)
    if not state or not self.GameStates[state] then
        logger.error("state " .. state .. " is not registered")
        error("state " .. state .. " is not registered", 2)
    end
    self.GameStates[state].goTo(...)
end

function GameManager:init()
    Events = EventBus()
    self.currentState = "main_menu"
    self.GameStates = {}

    Events:on("run_lose", function()
        Events:withAllEventsBlocked(function()
            Async.await(
                function ()
                    startTransition()
                    self:cleanupCurrent()
                end
            )
            self:goTo("run_lose")
        end)
    end)

    Events:on("run_win", function()
        Events:withAllEventsBlocked(function()
            Async.await(
                function ()
                    startTransition()
                    self:cleanupCurrent()
                end
            )
            self:goTo("run_win")
        end)
    end)

    self:registerState("run",
        function (...)
            LDtk.load("assets/levels/world.ldtk", false)
            local runManager = InfiniteRunManager(3)
            local runUI = RunUI(runManager)
            runManager:startRun()
        end,
        function ()
            gfx.clear()
        end
    )

        self:registerState("run_lose",
        function (...)
            LoseMenu()
        end,
        function ()
            gfx.clear()
        end
    )

    self:goTo("run")
end