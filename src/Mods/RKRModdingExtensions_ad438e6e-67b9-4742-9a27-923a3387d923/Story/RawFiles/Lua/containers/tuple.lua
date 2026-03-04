---@type Sequence
local Sequence = Rkr.Require("containers/base/sequence.lua")

---@type Hash
local Hash = Rkr.Require("containers/base/hash.lua")

---@class tuple<T>: Sequence<T>, Object, Hashable
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
    local new = setmetatable({ _data = {}, _size = 0, _hash = -1 }, tuple)
    local args = Sequence.parse_args(...)
    if args == nil then return new end
    local iter = Sequence.get_iterable(args)
    if not iter then Rkr.Error.Type("Tuple() expects iterable") end
    for v in iter do
        new._data[new._size] = v
        new._size = new._size + 1
    end
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


function tuple:__hash()
    if self._hash ~= -1 then return self._hash end
    local h = Hash.FNV_OFFSET
    for v in self() do
        local element_hash = Hash.hash_value(v)
        h = Hash.combine_ordered(h, element_hash)
    end
    h = Hash.finalise(h, self._size)
    self._hash = h
    return h
end

function tuple:__tostring()
    local close = (self:__len() == 1 and ",)") or ")"
    return self:_format_sequence("(", close)
end

tuple:finalise()
Rkr.Tuple = Tuple
