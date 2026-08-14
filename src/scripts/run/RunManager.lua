local pd <const> = playdate
local gfx <const> = playdate.graphics

import "RunTypes"

class('RunManager').extends()

function RunManager:init(lives)
    self.difficulty = Difficulty.EASY
    self.round = 1 -- lua table indexing conventionally starts at 1
    self.lives = lives
    self.roundOutcomes = {}
    self.runLevels = {}
    self.loadedLevels = {}
    self.gameTimer = GameTimer(5)

    -- probably want to register these when the first instance of an entity that emits these events gets instantiated, not in RunManager (single responsibility)
    Events:on("level_complete", function()
        Events:withAllEventsBlocked(function()
            print("Event emitted: level_complete")
            Async.await(startTransition)
            self:next(RoundOutcome.WIN)
        end)
    end)

    Events:on("player_died", function()
        Events:withAllEventsBlocked(function()
            print("Event emitted: player_died")
            Async.await(startTransition)
            self:next(RoundOutcome.LOSE)
        end)
    end)

    Events:on("timer_finish", function()
        Events:withAllEventsBlocked(function()
            print("Event emitted: timer_finish")
            Async.await(startTransition)
            self:next(RoundOutcome.LOSE)
        end)
    end)
end

function RunManager:generateLevelSequence()
    for i = 0, self.round - 1 do
        -- choose random level based on difficulty, and add its id into table
    end
end

function RunManager:addLevelToSequence(level_name)
end

function RunManager:setLevelSequence(levels)
    for _, level_name in ipairs(levels) do
        if self.loadedLevels[level_name] == nil then
            self.loadedLevels[level_name] = Level(level_name)
        end
        table.insert(self.runLevels, level_name)
    end
end

function RunManager:goWin()
end

function RunManager:goLose()
end

function RunManager:next(outcome)
    print("calling run manager next method")
    table.insert(self.roundOutcomes, outcome)
    if outcome == RoundOutcome.LOSE then self.lives -= 1 end
    self.loadedLevels[self.runLevels[self.round]]:cleanup()
    if self.lives <= 0 then self:goLose() end
    self.round += 1
end

function RunManager:startRun()
    
    --self:generateLevelSequence()
    -- FOR TESTING:
    self:setLevelSequence({"Level_0", "Level_1"})
    self.loadedLevels[self.runLevels[1]]:goTo()
    self.gameTimer:start()
end

class('FiniteRunManager').extends(RunManager)

function FiniteRunManager:init(lives, maxRound)
    FiniteRunManager.super.init(self, lives)
    self.maxRound = maxRound
end

function FiniteRunManager:next(outcome)
    FiniteRunManager.super.next(self, outcome)

    if self.round >= self.maxRound then
        self:goWin()
    else
        self.loadedLevels[self.runLevels[self.round]]:goTo()
        self.gameTimer:reset()
        self.gameTimer:start()
    end
end

class('InfiniteRunManager').extends(RunManager)

function InfiniteRunManager:init(lives)
    InfiniteRunManager.super.init(self, lives)
end

function InfiniteRunManager:next(outcome)
    InfiniteRunManager.super.next(self, outcome)

    self.loadedLevels[self.runLevels[self.round]]:goTo()
    self.gameTimer:reset()
    self.gameTimer:start()
end
