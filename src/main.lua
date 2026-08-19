-- CoreLibs
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local pd <const> = playdate
local gfx <const> = playdate.graphics

ASSETS_PATH = "assets/"
GRAPHICS_PATH = ASSETS_PATH .. "graphics/"

-- TODO: pull this from build command/env variable
DEBUG = true

-- Libraries
import "scripts/lib/AnimatedSprite"
import "scripts/lib/LDtk"

-- Utils
import "scripts/utils/Logger"
import "scripts/utils/Async"
import "scripts/utils/Countdown"
import "scripts/utils/Statemachine"

-- Level
import "scripts/level/Level"

-- Entities
import "scripts/entity/Entity"
import "scripts/entity/Player/Player"
import "scripts/entity/Player/PlayerStates"
import "scripts/entity/Player/PlayerData"
import "scripts/entity/Flag"
import "scripts/entity/Spike"

-- Behaviours
import "scripts/behaviour/GoalBehaviour"
import "scripts/behaviour/KillBehaviour"

-- Run/Game
import "scripts/game/EventBus"
import "scripts/run/GameTimer"
import "scripts/run/RunManager"
import "scripts/game/GameManager"

-- UI
import "scripts/ui/LoseMenu"
import "scripts/ui/MainMenuUI"
import "scripts/ui/RunUI"
import "scripts/ui/GameTimerUI"
import "scripts/ui/Transitions"

-- Data
import "scripts/data/EntityData"
import "scripts/data/SpriteData"

logger = Logger()
GameManager()

function pd.update()
	pd.timer.updateTimers()
	gfx.sprite.update()
end