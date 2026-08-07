GoalBehaviour = {}

function GoalBehaviour.onPlayerCollision()
    Events:emit("level_complete")
end