-- Timer.lua

local log = RkrModdingExtensions.log:with_context("Timer")

---@class Timer
---@field on_wait_ticks fun(ticks:number, callback:fun()):nil
---@field create_throttle fun(seconds:number, name:string):fun():boolean
local Timer = {}
Timer.__index = Timer

---Call a function after a given number of ticks.
---If `ticks <= 0`, the callback is executed immediately.
---@param ticks number Number of ticks to wait.
---@param callback fun() Function to call after waiting.
---@return nil
function Timer.on_wait_ticks(ticks, callback)
    if ticks <= 0 then
        log:info("Executing %s immediately (ticks <= 0)", callback)
        callback()
        return
    end
    log:debug("Scheduled %s to execute in %d tick(s)", callback, ticks)
    local function tick_counter(remaining)
        if remaining <= 0 then
            log:info("Executing scheduled callback %s", callback)
            callback()
            return
        end
        Ext.OnNextTick(function()
            tick_counter(remaining - 1)
        end)
    end
    tick_counter(ticks)
end

---Creates a simple rate-limiting throttle timer.
---Returns a function that can be polled to check if the timer
---is still within the blocked period.
---
---@param seconds number Cooldown duration in seconds.
---@param name string Name of throttle
---@return fun():boolean
function Timer.create_throttle(seconds, name)
    local lastExecutionTime = 0
    local threshold = seconds * 1000

    log:info("Creating %s throttle timer: %.3fs", name, seconds)

    return function()
        local currentTime = Ext.Utils.MonotonicTime()
        if currentTime - lastExecutionTime < threshold then
            return true
        end
        lastExecutionTime = currentTime
        return false
    end
end

Rkr.Timer = Timer
