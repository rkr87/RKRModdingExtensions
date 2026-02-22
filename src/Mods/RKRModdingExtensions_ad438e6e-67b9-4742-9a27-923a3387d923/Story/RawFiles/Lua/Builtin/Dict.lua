-- Dict.lua
---@class dict<K, V> : table
---@field private _size number
---@field [K] V
local Dict = {}
Dict.__index = Dict

---@generic K, V
---@param t table<K, V>|nil
---@return dict<K, V>
function Dict.new(t)
    local self = setmetatable({}, Dict)
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
function Dict:set(key, value)
    if self[key] == nil then
        self._size = self._size + 1
    end
    self[key] = value
end

Dict.put = Dict.set
Dict.add = Dict.set

---@generic K, V
---@param key K
---@param default V|nil
---@return V|nil
function Dict:get(key, default)
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
function Dict:pop(key, default)
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
function Dict:popitem()
    for k, v in pairs(self) do
        self[k] = nil
        self._size = self._size - 1
        return k, v
    end
end

---@generic K
---@param key K
---@return boolean
function Dict:contains(key)
    return self[key] ~= nil
end

---@return number
function Dict:len()
    return self._size
end

Dict.size = Dict.len

function Dict:clear()
    for k in pairs(self) do
        self[k] = nil
    end
    self._size = 0
end

---@generic K, V
---@param other table<K, V>|dict<K, V>
function Dict:update(other)
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
function Dict:setdefault(key, default)
    if self[key] == nil then
        self[key] = default
        self._size = self._size + 1
    end
    return self[key]
end

---@generic K
---@return fun(): K
function Dict:keys()
    local iter, tbl, key = pairs(self)
    return function()
        key = iter(tbl, key)
        return key
    end
end

---@generic K, V
---@return fun(): V
function Dict:values()
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
function Dict:items()
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
function Dict:__call()
    return self:keys()
end

---@generic K, V
---@return dict<K, V>
function Dict:copy()
    local new = Dict.new()
    for k, v in pairs(self) do
        new[k] = v
    end
    new._size = self._size
    return new
end

---@return number
function Dict:__len()
    return self._size
end

---@param other dict
---@return boolean
function Dict:__eq(other)
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

function Dict:__pairs()
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
function Dict:__tostring()
    local parts = {}

    for k, v in pairs(self) do
        parts[#parts + 1] =
            tostring(k) .. ": " .. tostring(v)
    end

    return "{" .. table.concat(parts, ", ") .. "}"
end

---@generic K, V
---@param iterable table|fun(): V
---@param value? V|nil
---@return dict<K, V>
function Dict.fromkeys(iterable, value)
    local self = Dict.new()
    value = value

    if iterable == nil then
        return self
    end

    if type(iterable) == "function" then
        while true do
            local v = iterable()
            if v == nil then
                break
            end

            if self[v] == nil then
                self._size = self._size + 1
            end
            self[v] = value
        end
    elseif type(iterable) == "table" then
        for _, v in ipairs(iterable) do
            if self[v] == nil then
                self._size = self._size + 1
            end
            self[v] = value
        end
    end

    return self
end

setmetatable(Dict, {
    __call = function(_, ...)
        return Dict.new(...)
    end
})

Rkr.Dict = Dict
