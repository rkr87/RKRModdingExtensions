---@class dict<K, V> : table
---@field private _size number
---@field private _order table<number, any>
---@field [K] V
local dict = {}

---@param key any
local function assert_hashable(key)
    if key == nil then
        error("TypeError: nil is not a valid dict key")
    end
    local t = type(key)
    if t == "string" or t == "number" or t == "boolean" then
        return
    end
    local mt = getmetatable(key)
    if mt and type(mt.__hash) == "function" then
        return
    end
    error("TypeError: unhashable type '" .. t .. "'")
end

function dict.__index(self, key)
    local method = rawget(dict, key)
    if method ~= nil then
        return method
    end

    assert_hashable(key)

    local value = rawget(self, key)
    if value ~= nil then
        return value
    end

    error("KeyError: " .. tostring(key))
end

function dict.__newindex(self, key, value)
    if key == "_size" or key == "_order" then
        rawset(self, key, value)
        return
    end

    assert_hashable(key)

    local old = rawget(self, key)
    if old == nil and value ~= nil then
        table.insert(self._order, key)
        self._size = self._size + 1
    elseif old ~= nil and value == nil then
        for i, k in ipairs(self._order) do
            if k == key then
                table.remove(self._order, i)
                break
            end
        end
        self._size = self._size - 1
    end

    rawset(self, key, value)
end

function dict:__len()
    return self._size
end

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

        if next_k == "_size" or next_k == "_order" then
            return iter(tbl, next_k)
        end

        return next_k, next_v
    end

    return iter, self, nil
end

function dict:__tostring()
    local parts = {}

    for k, v in pairs(self) do
        parts[#parts + 1] = tostring(k) .. ": " .. tostring(v)
    end

    return "{" .. table.concat(parts, ", ") .. "}"
end

---@generic K, V
---@param t table<K, V>|nil
---@return dict<K, V>
function dict.new(t)
    local self = setmetatable({}, dict)

    self._size = 0
    self._order = {}

    if t then
        for k, v in pairs(t) do
            assert_hashable(k)
            self[k] = v
        end
    end

    return self
end

---@generic K, V
function dict:set(key, value)
    assert_hashable(key)
    self[key] = value
end

dict.put = dict.set
dict.add = dict.set

---@generic K, V
---@param key K
---@param default? V
---@overload fun<K, V>(key:K): V|nil
---@overload fun<K, V>(key:K, default:V): V
function dict:get(key, default)
    assert_hashable(key)

    local value = rawget(self, key)

    if value ~= nil then
        return value
    end

    return default
end

---@generic K, V
---@param key K
---@param default V|nil
---@return V|nil
function dict:pop(key, default)
    assert_hashable(key)

    local value = rawget(self, key)

    if value == nil then
        if default ~= nil then
            return default
        end
        error("KeyError: " .. tostring(key))
    end

    self[key] = nil
    return value
end

---@generic K, V
---@return K, V
function dict:popitem()
    if self._size == 0 then
        error("KeyError: popitem called on empty dict")
    end

    local key
    repeat
        key = table.remove(self._order)
    until key == nil or rawget(self, key) ~= nil

    if key == nil then
        error("KeyError: popitem internal order corruption")
    end

    local value = rawget(self, key)
    self[key] = nil
    self._size = self._size - 1
    return key, value -- TODO replace with tuple
end

---@generic K
function dict:contains(key)
    assert_hashable(key)
    return rawget(self, key) ~= nil
end

function dict:len()
    return self._size
end

dict.size = dict.len

function dict:clear()
    for k in pairs(self) do
        if k ~= "_size" and k ~= "_order" then
            rawset(self, k, nil)
        end
    end

    self._size = 0
    self._order = {}
end

---@generic K, V
function dict:update(other)
    for k, v in pairs(other) do
        if k ~= "_size" and k ~= "_order" then
            assert_hashable(k)
            self[k] = v
        end
    end
end

---@generic K, V
function dict:setdefault(key, default)
    assert_hashable(key)

    local value = rawget(self, key)

    if value == nil then
        self[key] = default
        return default
    end

    return value
end

---@generic K
function dict:keys()
    local iter, tbl, key = pairs(self)

    return function()
        key = iter(tbl, key)
        return key
    end
end

---@generic K, V
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

function dict:__call()
    return self:keys()
end

---@generic K, V
---@return dict<K, V>
function dict:copy()
    local new = dict.new()

    for k, v in pairs(self) do
        if k ~= "_size" and k ~= "_order" then
            new[k] = v
        end
    end

    new._size = self._size
    new._order = { table.unpack(self._order) }

    return new
end

---@class Dict
local Dict = {}
Dict.__index = Dict

---@generic K, V
---@param iterable? K[]|fun(): K|nil
---@param value? V|nil
---@return dict<K, V>
function Dict.fromkeys(iterable, value)
    if iterable == nil then iterable = {} end

    local this = dict.new()

    if type(iterable) == "function" then
        for k in iterable do
            assert_hashable(k)
            this:set(k, value)
        end
    elseif type(iterable) == "table" then
        for _, k in ipairs(iterable) do
            assert_hashable(k)
            this:set(k, value)
        end
    end

    return this
end

Dict.new = dict.new
RkrModdingExtensions.make_callable(Dict, dict.new)

---@overload fun<K, V>(t: table<K, V>?): dict<K, V>
Rkr.Dict = Dict

return Dict
