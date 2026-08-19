class('EventBus').extends()

function EventBus:init()
    self.listeners = {}
    self._blockedEvents = {}
    self._blockAllEvents = false
end

function EventBus:on(event, fn)
    logger.info("registered event: " .. event)

    self.listeners[event] = self.listeners[event] or {}
    table.insert(self.listeners[event], fn)

    -- Return an unsubscribe function
    return function()
        local list = self.listeners[event]
        for i, func in ipairs(list) do
            if func == fn then
                table.remove(list, i)
                break
            end
        end
    end
end

function EventBus:withEventBlocked(event, callback)
    if not self.listeners[event] then
        logger.warning(event .. " is not a registered event")
    end
    self._blockedEvents[event] = true

    local function unblock()
        self._blockedEvents[event] = nil
    end

    callback(unblock)
end

 --probably also want a way to manage 'groups' of events (ie. add tags to events, then block all events with a specific tag)
 -- ie. tag 'player_event', then we can easily block all events that involve the player (winning, dying, taking damage, etc)
function EventBus:withEventsBlocked(events, fn)
    for _, event in ipairs(events) do
        if not self.listeners[event] then
            logger.warning(event .. " is not a registered event")
        end
        self._blockedEvents[event] = true
    end

    local function unblock()
        for _, event in ipairs(events) do
            self._blockedEvents[event] = nil
        end
    end

    Async.run(function()
        fn()
        unblock()
    end, function(err)
        unblock() -- still unblock on error ("finally" semantics)
        error(err, 0)
    end)
end

function EventBus:withAllEventsBlocked(fn)
    self._blockAllEvents = true

    Async.run(function()
        fn()
        self._blockAllEvents = false
    end, function(err)
        self._blockAllEvents = false
        error(err, 0)
    end)
end


function EventBus:emit(event, ...)
    logger.info("event emitted: " .. event)
    local list = self.listeners[event]

    if not list then logger.warning("event" .. event .. "not registered") end

    if not list or self._blockAllEvents or self._blockedEvents[event] then
        return
    end

    for _, callback in ipairs(list) do
        callback(...)
    end
end

-- clears all event triggers
function EventBus:reset()
    self.listeners = {}
end

return EventBus