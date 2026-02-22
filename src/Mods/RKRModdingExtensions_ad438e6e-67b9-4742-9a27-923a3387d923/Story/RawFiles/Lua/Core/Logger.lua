---@enum LoggingLevel
local LOG_LEVEL = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4
}

local LEVEL_COLOURS = {
    DEBUG = Rkr.Constants.ANSI_COLOURS.GREY,
    INFO  = Rkr.Constants.ANSI_COLOURS.GREEN,
    WARN  = Rkr.Constants.ANSI_COLOURS.YELLOW,
    ERROR = Rkr.Constants.ANSI_COLOURS.RED,
}

---@class Logger
---@field name string The name of the application (e.g., "AETPatch")
---@field level number The current logging threshold
---@field verbose boolean Whether metadata should be shown
---@field context string? The specific file or module context
---@field Level table<string, number> Reference to the enum
---@field log Logger Reference to logger intance for internal logging
local Logger = {}
Logger.__index = Logger
Logger.Level = LOG_LEVEL

local fallback_name = "RkrModdingExtensions"

--- Constructor: Creates the main Logger instance
---@param app_name string? Defaults to "LuaApp"
---@param initial_level string?
---@param verbose boolean? Defaults to false
---@return Logger
function Logger.new(app_name, initial_level, verbose)
    local self = setmetatable({}, Logger)
    initial_level = initial_level or "INFO"
    self.name = app_name or fallback_name
    self.level = Logger.Level[initial_level]
    self.verbose = verbose or false
    self.context = nil
    self.log = self:with_context("Logger")
    self.log:info(
        "Logger created (level=%s, verbose=%s)",
        initial_level,
        tostring(self.verbose)
    )
    return self
end

-- Allow Logger("AppName", level, verbose) syntax for instantiation
setmetatable(Logger, {
    ---@param app_name string?
    ---@param initial_level string?
    ---@param verbose boolean?
    ---@return Logger
    __call = function(_, app_name, initial_level, verbose)
        return Logger.new(app_name, initial_level, verbose)
    end
})

--- Creates a lightweight proxy for a specific file/context.
---@param context string e.g. "StatusManager"
---@return Logger
function Logger:with_context(context)
    local proxy = setmetatable({
        context = context
    }, {
        __index = self,
        __call = function(p, fmt, ...)
            p:_write("INFO", fmt, ...)
        end
    })
    return proxy
end

--- Creates a new logger with extended context.
---@param extra string
---@return Logger
function Logger:extend_context(extra)
    local new_context

    if self.context then
        new_context = self.context .. "." .. extra
    else
        new_context = extra
    end
    return self:with_context(new_context)
end

--- Internal: Core logging logic
---@param level_name string
---@param fmt string
---@param ... any
---@private
function Logger:_write(level_name, fmt, ...)
    local priority = Logger.Level[level_name]

    if not priority then
        self.log:extend_context("_write")
            :error("Unknown log level: %s", level_name)
        return
    end

    if priority < self.level then
        return
    end

    local message = (select('#', ...) > 0)
        and string.format(fmt, ...)
        or tostring(fmt)

    local name_block = self.name
    if self.verbose and self.context then
        name_block = string.format("%s:%s", self.name, self.context)
    end

    local raw_level = string.format("%-5s", level_name)
    local colour = LEVEL_COLOURS[level_name] or ""
    local reset = Rkr.Constants.ANSI_COLOURS.RESET

    local prefix = string.format(
        "[%s] %s[%s]%s",
        name_block,
        colour,
        raw_level,
        reset
    )
    print(prefix .. " " .. message)
end

---@param fmt string
---@param ... any
function Logger:debug(fmt, ...) self:_write("DEBUG", fmt, ...) end

---@param fmt string
---@param ... any
function Logger:info(fmt, ...) self:_write("INFO", fmt, ...) end

---@param fmt string
---@param ... any
function Logger:warn(fmt, ...) self:_write("WARN", fmt, ...) end

---@param fmt string
---@param ... any
function Logger:error(fmt, ...) self:_write("ERROR", fmt, ...) end

--- Changes the logging threshold for the main instance and all proxies
---@param level_name string
function Logger:set_level(level_name)
    local val = Logger.Level[tostring(level_name):upper()]

    if val then
        self.log:extend_context("set_level")
            :info("Log level changed to %s", tostring(level_name))
        self.level = val
    else
        self.log:extend_context("set_level")
            :warn("Attempt to set invalid log level: %s", tostring(level_name))
    end
end

--- Toggles context metadata visibility
---@param state boolean
function Logger:set_verbose(state)
    self.verbose = state
    self.log:extend_context("set_verbose")
        :info("Verbose mode set to %s", tostring(state))
end

--- Static logging: write without creating a Logger instance
---@param set_level string
---@param level_name string
---@param context string? Optional module/file context
---@param fmt string
---@param ... any
function Logger.log_static(set_level, set_verbose, level_name, context, fmt, ...)
    local set_priority = Logger.Level[set_level]
    local priority = Logger.Level[level_name]

    local name_block = fallback_name
    if context and set_verbose then
        name_block = name_block .. ":" .. context
    end
    local raw_level = string.format("%-5s", level_name or "ERROR")
    local colour = LEVEL_COLOURS[level_name] or Rkr.Constants.ANSI_COLOURS.RED
    local prefix = string.format(
        "[%s] %s[%s]%s",
        name_block,
        colour,
        raw_level,
        Rkr.Constants.ANSI_COLOURS.RESET
    )
    if not set_priority or not priority then
        local message = string.format("Unknown log level: %s", tostring(level_name))
        print(prefix .. " " .. message)
        return
    end
    if priority < set_priority then
        return
    end
    local message = (select('#', ...) > 0) and string.format(fmt, ...) or tostring(fmt)
    print(prefix .. " " .. message)
end

Rkr.Logger = Logger
