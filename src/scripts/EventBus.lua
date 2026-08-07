class('EventBus').extends()

function EventBus:init()
    self.listeners = {}
end

function EventBus:on(event, callback)
    self.listeners[event] = self.listeners[event] or {}
    table.insert(self.listeners[event], callback)

    -- Return an unsubscribe function
    return function()
        local list = self.listeners[event]
        for i, cb in ipairs(list) do
            if cb == callback then
                table.remove(list, i)
                break
            end
        end
    end
end

function EventBus:emit(event, ...)
    local list = self.listeners[event]
    if not list then return end

    for _, callback in ipairs(list) do
        callback(...)
    end
end

-- clears all event triggers
function EventBus:reset()
    self.listeners = {}
end

return EventBus