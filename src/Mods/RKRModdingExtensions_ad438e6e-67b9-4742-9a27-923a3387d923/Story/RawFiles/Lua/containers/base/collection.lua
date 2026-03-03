---@type Object
local Object = Rkr.Require("containers/base/object.lua")

---@class Collection<K, V>: Object
---@field __len fun(self: Collection<K, V>): integer
---@field len fun(self: Collection<K, V>): integer
---@field __contains fun(self: Collection<K, V>, value: K|V): boolean
---@field contains fun(self: Collection<K, V>, value: K|V): boolean
---@field __pairs fun(self: Collection<K, V>): fun(): K, V
---@field __iter fun(self: Collection<K, V>): fun(): K|V
---@field enumerate fun(self: Collection<K, V>): fun(): integer, K|V
local Collection = Object:derive("Collection", {
    abstract = true, requires = { "__len", "__pairs", "__iter", "__contains" }
})

function Collection:__call() return self:__iter() end

function Collection:len() return self:__len() end

function Collection:contains(x) return self:__contains(x) end

function Collection:enumerate()
    local iter = self:__iter()
    local i = -1
    return function()
        local v = iter()
        if v ~= nil then
            i = i + 1
            return i, v
        end
    end
end

function Collection.get_iterable(object)
    local iter = nil
    local mt = getmetatable(object)
    if type(object) == "function" then
        iter = object
    elseif mt and mt.__iter then
        iter = object:__iter()
    elseif type(object) == "table" then
        local i = 0
        iter = function()
            i = i + 1
            return object[i]
        end
    end
    return iter
end

function Collection.parse_args(...)
    local argc = select("#", ...)
    if argc == 0 then return nil end
    if argc == 1 then
        local first = select(1, ...)
        local mt = getmetatable(first)
        local typ = type(first)
        if typ == "function" or typ == "table" or (mt and mt.__iter) then
            return first
        end
    end
    return { ... }
end

return Collection
