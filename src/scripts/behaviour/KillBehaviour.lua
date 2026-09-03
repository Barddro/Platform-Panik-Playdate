KillBehaviour = {}

function KillBehaviour.onPlayerCollision()
    Events:emit("player_died")
end