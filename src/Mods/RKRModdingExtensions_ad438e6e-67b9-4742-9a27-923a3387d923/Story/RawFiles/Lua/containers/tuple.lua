---@type Sequence
local Sequence = Rkr.Require("containers/base/sequence.lua")

---@class tuple<T>: Sequence<T>, Object
---@field private _data table<integer, T>
---@field private _size integer
---@field private _hash integer
---@field __hash fun(self: tuple<T>): integer
---@field slice fun(self: list<T>, start?: table|integer|nil, stop?: integer|nil, step?: integer): tuple<T>
---@field copy fun(self: ...): tuple<T>
local tuple = Sequence:derive("tuple")

---@class Tuple<T>
---@field new fun(...: T)|fun<T>(obj?: IterableSequence<T>): tuple<T>
---@overload fun(...: T):tuple<T>
---@overload fun(obj?: IterableSequence<T>): tuple<T>
local Tuple = {}
tuple.__public = Tuple

---@diagnostic disable-next-line: param-type-mismatch
setmetatable(Tuple, { __call = function(_, ...) return Tuple.new(...) end })

function Tuple.new(...)
    ---@type tuple<T>
    local new = setmetatable({ _data = {}, _size = 0, _hash = 0 }, tuple)
    local args = Sequence.parse_args(...)
    if args == nil then return new end
    local iter = Sequence.get_iterable(args)
    if not iter then Rkr.Error.Type("Tuple() expects iterable") end
    for v in iter do
        new._data[new._size] = v
        new._size = new._size + 1
    end
    new._hash = new:__hash()
    return new
end

function tuple:__index_protocol(index) return self._data[index] end

function tuple:__len() return self._size end

local function immutable(...) Rkr.Error.Type("tuple is immutable") end
tuple.__newindex = immutable
tuple.append     = immutable
tuple.insert     = immutable
tuple.pop        = immutable
tuple.remove     = immutable
tuple.clear      = immutable

local FNV_OFFSET = 2166136261
local FNV_PRIME  = 16777619
local MOD32      = 2 ^ 32

local function hash_value(v)
    local t = type(v)
    if t == "number" then return v % MOD32 end
    if t == "boolean" then return v and 1 or 0 end
    if t == "string" then
        local h = FNV_OFFSET
        for i = 1, #v do
            h = (h ~ string.byte(v, i)) * FNV_PRIME % MOD32
        end
        return h
    end
    if t == "table" then
        local mt = getmetatable(v)
        if mt and mt.__hash then return v:__hash() end
        local s = tostring(v)
        local hex = s:match("0x[%da-fA-F]+")
        if hex then return tonumber(hex, 16) or 0 end
        return 0
    end
end

function tuple:__hash()
    if self._hash ~= 0 then return self._hash end
    local h = FNV_OFFSET
    for i = 0, self._size - 1 do
        local element_hash = hash_value(self._data[i])
        h = (h ~ element_hash) * FNV_PRIME % MOD32
    end
    h = (h ~ self._size) * FNV_PRIME % MOD32
    return h
end

function tuple:__tostring()
    local close = (self:__len() == 1 and ",)") or ")"
    return self:_format_sequence("(", close)
end

tuple:finalise()
Rkr.Tuple = Tuple
