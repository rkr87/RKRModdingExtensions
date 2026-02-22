-- Dict.lua
---@class dict<K, V> : table
---@field private _size number
---@field [K] V
local dict = {}
dict.__index = dict

---@generic K, V
---@param t table<K, V>|nil
---@return dict<K, V>
function dict.new(t)
    local self = setmetatable({}, dict)
    self._size = 0

    if t then
        for k, v in pairs(t) do
            self[k] = v
            self._size = self._size + 1
        end
    end

    return self
end

---@generic K, V
---@param key K
---@param value V
function dict:set(key, value)
    if self[key] == nil then
        self._size = self._size + 1
    end
    self[key] = value
end

dict.put = dict.set
dict.add = dict.set

---@generic K, V
---@param key K
---@param default V|nil
---@return V|nil
function dict:get(key, default)
    local value = self[key]
    if value == nil then
        return default
    end
    return value
end

---@generic K, V
---@param key K
---@param default V|nil
---@return V|nil
function dict:pop(key, default)
    local value = self[key]

    if value == nil then
        if default ~= nil then
            return default
        end
        error("KeyError: " .. tostring(key))
    end

    self[key] = nil
    self._size = self._size - 1
    return value
end

---@generic K, V
---@return K|nil, V|nil
function dict:popitem()
    for k, v in pairs(self) do
        self[k] = nil
        self._size = self._size - 1
        return k, v
    end
end

---@generic K
---@param key K
---@return boolean
function dict:contains(key)
    return self[key] ~= nil
end

---@return number
function dict:len()
    return self._size
end

dict.size = dict.len

function dict:clear()
    for k in pairs(self) do
        self[k] = nil
    end
    self._size = 0
end

---@generic K, V
---@param other table<K, V>|dict<K, V>
function dict:update(other)
    for k, v in pairs(other) do
        if self[k] == nil then
            self._size = self._size + 1
        end
        self[k] = v
    end
end

---@generic K, V
---@param key K
---@param default V
---@return V
function dict:setdefault(key, default)
    if self[key] == nil then
        self[key] = default
        self._size = self._size + 1
    end
    return self[key]
end

---@generic K
---@return fun(): K
function dict:keys()
    local iter, tbl, key = pairs(self)
    return function()
        key = iter(tbl, key)
        return key
    end
end

---@generic K, V
---@return fun(): V
function dict:values()
    local iter, tbl, key = pairs(self)
    return function()
        key = iter(tbl, key)
        if key ~= nil then
            return tbl[key]
        end
    end
end

---@generic K, V
---@return fun(): K, V
function dict:items()
    local iter, tbl, key = pairs(self)
    return function()
        key = iter(tbl, key)
        if key ~= nil then
            return key, tbl[key]
        end
    end
end

---@generic K, V
---@return fun(): K, V
function dict:__call()
    return self:keys()
end

---@generic K, V
---@return dict<K, V>
function dict:copy()
    local new = dict.new()
    for k, v in pairs(self) do
        new[k] = v
    end
    new._size = self._size
    return new
end

---@return number
function dict:__len()
    return self._size
end

---@param other dict
---@return boolean
function dict:__eq(other)
    if self._size ~= other._size then
        return false
    end

    for k, v in pairs(self) do
        if other[k] ~= v then
            return false
        end
    end

    return true
end

function dict:__pairs()
    local function iter(tbl, k)
        local next_k, next_v = next(tbl, k)
        if next_k == "_size" then
            return iter(tbl, next_k)
        end
        return next_k, next_v
    end

    return iter, self, nil
end

---@return string
function dict:__tostring()
    local parts = {}

    for k, v in pairs(self) do
        parts[#parts + 1] =
            tostring(k) .. ": " .. tostring(v)
    end

    return "{" .. table.concat(parts, ", ") .. "}"
end

---@class Dict
local Dict = {}
Dict.__index = Dict

---@generic K, V
---@param iterable K[]|fun(): K
---@param value? V|nil
---@return dict<K, V>
function Dict.fromkeys(iterable, value)
    local this = dict.new()
    if type(iterable) == "function" then
        for k in iterable do
            this:set(k, value)
        end
    elseif type(iterable) == "table" then
        for _, k in ipairs(iterable) do
            this:set(k, value)
        end
    end
    return this
end

RkrModdingExtensions.make_callable(Dict, dict.new)
---@overload fun<K, V>(t: table<K, V>?): dict<K, V>
Rkr.Dict = Dict
