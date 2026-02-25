---@generic T
---@param class table
---@param constructor fun(...): T
local function make_callable(class, constructor)
    class.__index = class
    setmetatable(class, {
        __call = function(_, ...)
            return constructor(...)
        end
    })
end

RkrModdingExtensions.make_callable = make_callable
