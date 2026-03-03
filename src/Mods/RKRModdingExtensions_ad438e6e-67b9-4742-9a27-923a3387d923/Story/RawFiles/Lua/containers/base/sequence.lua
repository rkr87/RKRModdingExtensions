---@type Collection
local Collection = Rkr.Require("containers/base/collection.lua")

---@class Sequence<T>: Collection<integer, T>, Object
---@field __index_protocol fun(self: Sequence<T>, index: integer): T
---@field index fun(self: Sequence<T>, value: T, start?: integer, stop?: integer): integer|nil
---@field index_all fun(self: Sequence<T>, value: T): Sequence<integer>
---@field count fun(self: Sequence<T>, value: T): integer
---@field reversed fun(self: Sequence<T>): fun(): T
---@field slice fun(self: Sequence<T>, start?: table|integer|nil, stop?: integer|nil, step?: integer): Sequence<T>
---@field unpack fun(self: Sequence<T>, start?: integer|nil, stop?: integer|nil, step?: integer): T,...
---@field copy fun(self: ...): Sequence<T>
---@field _validate_index fun(self: Sequence<T>, index: integer)
---@field _clamp_index fun(self: Sequence<T>, index: integer, size: integer, inclusive?: boolean): integer
---@field _normalise_index fun(self: Sequence<T>, index: integer, size: integer): integer
---@field _normalise_index_inclusive fun(self: Sequence<T>, index: integer, size: integer): integer
---@field _format_sequence fun(self: Sequence<T>, open?: string, close?: string): string
---@field enumerate fun(self: Sequence<T>): fun(): integer, T
local Sequence = Collection:derive("Sequence",
    { abstract = true, requires = { "__index_protocol" } }
)

---@alias IterableSequence<T> T[]|Sequence<T>|fun():T|Collection<T,any>|Collection<any,T>

function Sequence:__index(key)
    if type(key) == "number" then
        local index = Sequence:_normalise_index(key, self:__len())
        return self:__index_protocol(index)
    end
    if type(key) == "table" then return self:slice(key) end
    local mt = getmetatable(self)
    if mt then
        local v = mt[key]
        if v ~= nil then return v end
    end
    Rkr.Error.Name("name '%s' is not defined", key)
end

function Sequence:__pairs() return self:enumerate() end

function Sequence:__contains(value)
    for v in self() do
        if v == value then return true end
    end
    return false
end

function Sequence:__eq(other)
    if getmetatable(other) ~= getmetatable(self) then return false end
    if self:__len() ~= other:__len() then return false end
    for i, v in self:enumerate() do
        if other[i] ~= v then return false end
    end
    return true
end

function Sequence:index(value, start, stop)
    start = start or 0
    stop = stop or self:__len() - 1
    for i, v in self:enumerate() do
        if i >= start and i <= stop then
            if v == value then return i end
        end
    end
    Rkr.Error.Value("%s is not in list", value)
end

function Sequence:index_all(value)
    local result = Rkr.List()
    for i, v in self:enumerate() do
        if v == value then result:append(i) end
    end
    if #result > 0 then return result end
    return Rkr.Error.Value("%s is not in sequence", value)
end

function Sequence:count(value)
    local n = 0
    for v in self() do
        if v == value then n = n + 1 end
    end
    return n
end

function Sequence:reversed()
    local current = self:__len()
    return function()
        current = current - 1
        if current >= 0 then return self:__index(current) end
    end
end

function Sequence:unpack(start, stop, step)
    start, stop, step = self:_resolve_slice_bounds(start, stop, step)
    local result = self:_materialise_slice(start, stop, step)
    return table.unpack(result)
end

---@overload fun(start:table)
---@overload fun(start?:integer|nil, stop?: integer|nil, step?:integer|nil)
function Sequence:slice(start, stop, step)
    if type(start) == "table" then
        start, stop, step = Sequence:_validate_slice_descriptor(start)
    end
    start, stop, step = self:_resolve_slice_bounds(start, stop, step)
    local temp = self:_materialise_slice(start, stop, step)
    return self.__public(temp)
end

function Sequence:copy()
    local n = self:__len()
    local t = {}
    for i = 1, n do t[i] = self[i - 1] end
    return self.__public(t)
end

function Sequence:__iter()
    local i = 0
    local cache = {}
    local n = self:__len()
    local function next_value(create_cache, override_seq)
        create_cache = create_cache or false
        override_seq = override_seq or self
        if i < n then
            local v = override_seq[i]
            i = i + 1
            if create_cache then table.insert(cache, v) end
            return v
        end
    end
    local iterator_object = self.__public()
    setmetatable(iterator_object, {
        __call = function() return next_value() end,
        __index = function(_, key)
            local typ = type(key)
            local slice = typ == "table" and self:slice(key)
            if slice or typ == "number" then
                while #cache < key do
                    local v = next_value(true, slice)
                    if v == nil then break end
                end
                return cache[key]
            end
            return nil
        end
    })
    return iterator_object
end

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
    if step ~= nil and (type(step) ~= "number" or math.floor(step) ~= step) then
        Rkr.Error.Type("slice step must be an integer")
    end
    if start ~= nil then Sequence:_validate_index(start) end
    if stop ~= nil then Sequence:_validate_index(stop) end
    return start, stop, step
end

function Sequence:_resolve_slice_bounds(start, stop, step)
    local n = self:__len()
    step = step or 1
    if step == 0 then Rkr.Error.Value("slice step cannot be zero") end
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
    return start, stop, step
end

function Sequence:_materialise_slice(start, stop, step)
    local n = self:__len()
    local temp = {}
    if step > 0 then
        while start < stop do
            if start >= 0 and start < n then temp[#temp + 1] = self[start] end
            start = start + step
        end
    else
        while start > stop do
            if start >= 0 and start < n then temp[#temp + 1] = self[start] end
            start = start + step
        end
    end
    return temp
end

function Sequence:_format_sequence(open, close)
    local parts = {}
    for v in self() do parts[#parts + 1] = tostring(v) end
    return (open or "[") .. table.concat(parts, ", ") .. (close or "]")
end

return Sequence
