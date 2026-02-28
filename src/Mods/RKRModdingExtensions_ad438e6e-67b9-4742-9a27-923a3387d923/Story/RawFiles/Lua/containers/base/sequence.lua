--------------------------------------------------------------------------------
-- Sequence<T>
--
-- Abstract ordered collection indexed by integers (0-based).
--
-- Extends Collection<integer, T>.
--
-- Guarantees:
--   • Integer indexing
--   • Length protocol
--   • Iteration protocol
--   • Membership testing
--   • Equality comparison
--   • Slicing support
--
-- Concrete subclasses must implement:
--   • __index_protocol(index)
--   • __len()
--   • __public constructor
--------------------------------------------------------------------------------

---@type Collection
local Collection = Ext.Require("containers/base/collection.lua")

---@class Sequence<T, S>: Collection<integer, T>, Object
---@field __index_protocol fun(self: Sequence<T>, index: integer): T
---@field __pairs fun(self: Sequence<T>): fun(): integer, T
---@field index fun(self: Sequence<T>, value: T, start?: integer, stop?: integer): integer|nil
---@field index_all fun(self: Sequence<T>, value: T): Sequence<integer>
---@field count fun(self: Sequence<T>, value: T): integer
---@field reversed fun(self: Sequence<T>): fun(): T
---@field slice fun(self: Sequence<T>, start?: table|integer|nil, stop?: integer|nil, step?: integer): S
---@field copy fun(self: S): S
---@field _validate_index fun(self: Sequence<T>, index: integer)
---@field _clamp_index fun(self: Sequence<T>, index: integer, size: integer, inclusive?: boolean): integer
---@field _normalise_index fun(self: Sequence<T>, index: integer, size: integer): integer
---@field _normalise_index_inclusive fun(self: Sequence<T>, index: integer, size: integer): integer
---@field _format_sequence fun(self: Sequence<T>, open?: string, close?: string): string
local Sequence = Collection:derive("Sequence",
    { abstract = true, requires = { "__index_protocol" } }
)

--------------------------------------------------------------------------------
-- Metamethods
--------------------------------------------------------------------------------

---Handles numeric indexing and method lookup.
function Sequence:__index(key)
    if type(key) == "number" then
        local index = Sequence:_normalise_index(key, self:__len())
        return self:__index_protocol(index)
    elseif type(key) == "table" then
        return self:slice(key)
    end
    local mt = getmetatable(self)
    if mt then
        local v = mt[key]
        if v ~= nil then
            return v
        end
    end
    Rkr.Error.Name("name '%s' is not defined", key)
end

---Default iteration over index/value pairs.
function Sequence:__pairs()
    local i = 0
    local n = self:__len()
    return function()
        if i < n then
            local k, v = i, self[i]
            i = i + 1
            return k, v
        end
    end
end

---Membership test.
function Sequence:__contains(value)
    for _, v in self:__pairs() do
        if v == value then return true end
    end
    return false
end

---Callable shorthand for values().
function Sequence:__call() return self:values() end

---Equality comparison.
function Sequence:__eq(other)
    if getmetatable(other) ~= getmetatable(self) then return false end
    if self:__len() ~= other:__len() then return false end
    for i, v in self:__pairs() do
        if other[i] ~= v then
            return false
        end
    end
    return true
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

---Returns first index of value within optional bounds.
function Sequence:index(value, start, stop)
    start = start or 0
    stop = stop or self:__len() - 1
    for i, v in self:__pairs() do
        if i >= start and i <= stop then
            if v == value then return i end
        end
    end
    Rkr.Error.Value("%s is not in list", value)
end

---Returns all indices where value appears.
function Sequence:index_all(value)
    local n = self:__len()
    local result = Rkr.List()
    for i = 0, n - 1 do
        if self[i] == value then
            result:append(i)
        end
    end
    if #result > 0 then return result end
    return Rkr.Error.Value("%s is not in sequence", value)
end

---Counts occurrences of a value.
function Sequence:count(value)
    local n = 0
    for _, v in self:__pairs() do
        if v == value then n = n + 1 end
    end
    return n
end

---Returns reverse iterator.
function Sequence:reversed()
    local current = self:__len()
    return function()
        current = current - 1
        if current >= 0 then
            return self:__index(current)
        end
    end
end

--------------------------------------------------------------------------------
-- Slicing / Copying
--------------------------------------------------------------------------------

---Returns a sliced copy of the sequence.
---@overload fun(start:table)
---@overload fun(start?:integer|nil, stop?: integer|nil, step?:integer|nil)
function Sequence:slice(start, stop, step)
    if type(start) == "table" then
        start, stop, step = Sequence:_validate_slice_descriptor(start)
    end

    local n = self:__len()
    step = step or 1
    if step == 0 then
        Rkr.Error.Value("slice step cannot be zero")
    end
    if step > 0 then
        start = Sequence:_clamp_index(start or 0, n, true)
        stop = Sequence:_clamp_index(stop or n, n, true)
    else
        start = Sequence:_clamp_index(start or n, n, true)
        if stop == nil then
            stop = -1
        else
            stop = Sequence:_clamp_index(stop, n, true)
        end
    end
    local temp = {}
    local i = start
    if step > 0 then
        while i < stop do
            if i >= 0 and i < n then temp[#temp + 1] = self[i] end
            i = i + step
        end
    else
        while i > stop do
            if i >= 0 and i < n then temp[#temp + 1] = self[i] end
            i = i + step
        end
    end

    return self.__public(temp)
end

---Returns a shallow copy of the sequence.
function Sequence:copy()
    ---@type Sequence<T>
    self = self
    local n = self:__len()
    local t = {}
    for i = 0, n - 1 do
        t[i + 1] = self[i]
    end
    return self.__public(t)
end

--------------------------------------------------------------------------------
-- Iteration Protocol
--------------------------------------------------------------------------------

---Returns iterator yielding {index, value} tuple.
function Sequence:__items()
    local iter = self:__pairs()
    return function()
        local k, v = iter()
        if k ~= nil then
            -- TODO: replace this with tuple
            return Rkr.List.new({ k, v })
        end
    end
end

---Returns iterator over values.
function Sequence:__values()
    local i = 0
    local cache = {}
    local n = self:__len()

    local function next_value()
        if i < n then
            local v = self[i]
            i = i + 1
            table.insert(cache, v)
            return v
        end
    end

    local iterator_object = self.__public()

    setmetatable(iterator_object, {
        __call = function()
            return next_value()
        end,
        __index = function(_, key)
            if type(key) == "number" then
                while #cache < key do
                    local v = next_value()
                    if v == nil then break end
                end
                return cache[key]
            end
            return nil
        end
    })

    return iterator_object
end

--------------------------------------------------------------------------------
-- Internal Helpers
--------------------------------------------------------------------------------

function Sequence:_validate_index(index)
    if type(index) ~= "number" then
        Rkr.Error.Name("name '%s' is not defined", index)
    elseif index ~= math.floor(index) then
        Rkr.Error.Type("list indices must be integers, not float")
    end
end

function Sequence:_clamp_index(index, size, inclusive)
    Sequence:_validate_index(index)
    inclusive = inclusive or false
    size = size or 0
    if index < 0 then index = size + index end
    if not inclusive then size = size - 1 end
    return math.max(math.min(size, index), 0)
end

function Sequence:_normalise_index_inclusive(index, size)
    return Sequence:_clamp_index(index, size, true)
end

function Sequence:_normalise_index(index, size)
    index = Sequence:_normalise_index_inclusive(index, size)
    if index < 0 or index >= size then
        Rkr.Error.Index("list index out of range")
    end
    return index
end

function Sequence:_validate_slice_descriptor(slice)
    if type(slice) ~= "table" then
        Rkr.Error.Type("slice descriptor must be a table")
    end
    local start = slice.start or slice[1]
    local stop  = slice.stop or slice[2]
    local step  = slice.step or slice[3]
    if step ~= nil then
        if type(step) ~= "number" or math.floor(step) ~= step then
            Rkr.Error.Type("slice step must be an integer")
        end
    end
    if start ~= nil then Sequence:_validate_index(start) end
    if stop ~= nil then Sequence:_validate_index(stop) end
    return start, stop, step
end

--------------------------------------------------------------------------------
-- Formatting
--------------------------------------------------------------------------------

function Sequence:_format_sequence(open, close)
    local parts = {}
    for i = 0, self:__len() - 1 do
        parts[#parts + 1] = tostring(self[i])
    end
    return (open or "(") .. table.concat(parts, ", ") .. (close or ")")
end

return Sequence
