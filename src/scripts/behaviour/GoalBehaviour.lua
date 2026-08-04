local GoalBehavior = {}

function GoalBehavior.onPlayerCollision(entity, player, scene)
    scene.events:emit("level_complete")
end

return GoalBehavior