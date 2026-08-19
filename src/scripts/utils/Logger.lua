class("Logger").extends()

LoggerLevels = {
    INFO = 0,
    WARNING = 1,
    ERROR = 2,
    FATAL = 3
}

local instance = nil -- singleton

local _LoggerNames = {
    [LoggerLevels.INFO] = "INFO",
    [LoggerLevels.WARNING] = "WARNING",
    [LoggerLevels.ERROR] = "ERROR",
    [LoggerLevels.FATAL] = "FATAL",
}

-- Override the creation mechanism
function Logger.new(defaultLevel)
    if instance then
        return instance
    end
    
    -- Otherwise, call the super constructor to allocate the table and call init()
    instance = Logger.super.new(defaultLevel)
    return instance
end

function Logger:init(...)
    local args = table.pack(...)
    if not args.defaultLevel or args.defaultLevel < LoggerLevels.Logger or args.defaultLevel > LoggerLevels.FATAL then
        self.defaultLevel = LoggerLevels.INFO
    else
        self.defaultLevel = args.defaultLevel
    end
end

function Logger:print(text)
   print(string.format("[%s]: %s", _LoggerNames[self.defaultLevel], text))
end

function Logger.info(...)
    print("[INFO]", ...)
end

function Logger.warning(...)
    print("[WARNING]", ...)
end

function Logger.error(...)
    print("[ERROR]", ...)
end

function Logger.fatal(...)
    print("[ERROR]", ...)
end

return Logger