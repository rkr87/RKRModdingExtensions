-- Timer.lua
---@class Timer
local Timer = {}
Timer.__index = Timer

---Call a function after a given number of ticks.
---If ticks <= 0, the callback is executed immediately.
---@param ticks number Number of ticks to wait
---@param callback fun() Function to call after waiting
---@return nil
function Timer.OnWaitTicks(ticks, callback)
    if ticks <= 0 then
        callback()
        return
    end

    Ext.OnNextTick(function()
        Timer.OnWaitTicks(ticks - 1, callback)
    end)
end

Rkr.Timer = Timer
