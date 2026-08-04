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
    self.events = EventBus()
    self.gameTimer = GameTimer(5, self.events)

    self.events:on("level_complete", function()
        print("Event emitted: level_complete")
        self:next(RoundOutcome.WIN)
    end)

    self.events:on("player_died", function()
        print("Event emitted: player_died")
        self:next(RoundOutcome.LOSE)
    end)

    self.events:on("timer_finish", function()
        print("Event emitted: timer_finish")
        self:next(RoundOutcome.LOSE)
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

function RunManager:goNewRound()
end

function RunManager:goWin()
end

function RunManager:goLose()
end

function RunManager:next(outcome)
    startTransition(
        function () 
            table.insert(self.roundOutcomes, outcome)
            if outcome == RoundOutcome.LOSE then self.lives -= 1 end
            if self.lives <= 0 then self:goLose() end
            self.round += 1
        end
    )
    
end

function RunManager:startRun()
    
    --self:generateLevelSequence()
    -- FOR TESTING:
    self:setLevelSequence({"Level_0", "Level_1"})
    self.loadedLevels[self.runLevels[1]]:goTo()
    Player.getInstance():setScene(self)
end

class('FiniteRunManager').extends(RunManager)

function FiniteRunManager:init(lives, maxRound)
    FiniteRunManager.super.init(lives)
    self.maxRound = maxRound
end

function FiniteRunManager:next(outcome)
    self.super.next(outcome)
    
    if self.round >= self.maxRound then
        self:goWin()
    else
        self.loadedLevels[self.runLevelIDs[self.round]]:goTo()
    end
end

class('InfiniteRunManager').extends(RunManager)
