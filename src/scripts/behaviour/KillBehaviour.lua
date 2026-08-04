local KillBehaviour = {}

function KillBehaviour.onPlayerCollision(entity, player, scene)
    scene.events:emit("player_died")
end

return KillBehaviour