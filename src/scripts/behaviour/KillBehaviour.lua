KillBehaviour = {}

function KillBehaviour.onPlayerCollision()
    Events:emit("player_died")
    -- need to add debouncing to stop triggering events
end