Async = {}

-- fn must be "node style": fn(callback, ...) where callback(...) signals completion
function Async.await(fn, ...)
    local co = coroutine.running()
    assert(co, "Async.await must be called from within an Async.run coroutine")

    local fired, results = false, nil

    fn(function(...)
        if fired then return end -- guard against double-invoke
        fired = true
        results = table.pack(...)
        if coroutine.status(co) == "suspended" then -- resume 'await', since we are calling back after the completion of whatever async function (eg. transition), so we have successfully 'awaited' its execution
            local ok, err = coroutine.resume(co) -- (((***)))
            if not ok then error(err, 0) end
        end
    end, ...)

    if fired then
        return table.unpack(results, 1, results.n) -- fn completed synchronously
    end

    coroutine.yield() -- 'co' coroutine (containing this await call) yields back to main game loop, then gets resumed at the line indicated with '(((***)))'
    return table.unpack(results, 1, results.n)
end

function Async.run(fn, onError)
    local co = coroutine.create(fn) -- Note that this coroutine contains await's execution, but whatever async function is being called by await (eg. startTransition) spawns its own coroutine which does not get paused by yield. So, we only pause await's execution, which gets resumed
    local ok, err = coroutine.resume(co) -- this actually starts the execution of co for the first itme
    if not ok then
        if onError then onError(err) else error(err, 0) end
    end
end