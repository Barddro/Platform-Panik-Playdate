-- CoreLibs
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local pd <const> = playdate
local gfx <const> = playdate.graphics

ASSETS_PATH = "assets/"
GRAPHICS_PATH = ASSETS_PATH .. "graphics/"

-- Libraries
import "scripts/lib/AnimatedSprite"
import "scripts/lib/LDtk"

-- Top-Level
import "scripts/EventBus"

-- Level
import "scripts/level/Level"

-- Entities
import "scripts/entity/Entity"
import "scripts/entity/Player"
import "scripts/entity/Flag"
import "scripts/entity/Spike"
import "scripts/entity/EntityData"

-- Behaviours
import "scripts/behaviour/GoalBehaviour"
import "scripts/behaviour/KillBehaviour"

-- Run
import "scripts/run/GameTimer"
import "scripts/run/RunManager"
import "scripts/GameManager"

-- UI
import "scripts/ui/GameTimerUI"
import "scripts/ui/Transitions"

GameManager()

function pd.update()
	pd.timer.updateTimers()
	gfx.sprite.update()
end