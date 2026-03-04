---@type MutableSequence
local MutableSequence = Rkr.Require("containers/base/mutable_sequence.lua")

---@class list<T>: MutableSequence<T>, Object
---@field private _data table<integer, T>
---@field private _size integer
---@field slice fun(self: list<T>, start?: table|integer|nil, stop?: integer|nil, step?: integer): list<T>
---@field copy fun(self: ...): list<T>
local list = MutableSequence:derive("list")

---@class List<T>
---@field new fun(...: T)|fun(obj?: IterableSequence<T>): list<T>
---@overload fun(...: T): list<T>
---@overload fun(obj?: IterableSequence<T>): list<T>
local List = {}
list.__public = List

---@diagnostic disable-next-line: param-type-mismatch
setmetatable(List, { __call = function(_, ...) return List.new(...) end })

function List.new(...)
    ---@type list<T>
    local new = setmetatable({ _data = {}, _size = 0 }, list)
    local args = MutableSequence.parse_args(...)
    if args ~= nil then new:extend(args) end
    return new
end

function list:__index_protocol(index) return self._data[index] end

function list:__set_index_protocol(index, value) self._data[index] = value end

function list:__len() return self._size end

function list:append(value)
    self._data[self._size] = value
    self._size = self._size + 1
end

function list:insert(index, value)
    self:_validate_index(index)
    index = self:_normalise_index_inclusive(index, self._size)
    index = math.max(index, 0)
    index = math.min(index, self._size)
    for i = self._size, index, -1 do
        self._data[i] = self._data[i - 1]
    end
    self._data[index] = value
    self._size = self._size + 1
end

function list:pop(index)
    if self._size == 0 then Rkr.Error.Index("pop from empty list") end
    index = index or self._size - 1
    index = self:_normalise_index(index, self._size)
    local value = self._data[index]
    for i = index, self._size - 1 do
        self._data[i] = self._data[i + 1]
    end
    self._data[self._size] = nil
    self._size = self._size - 1
    return value
end

function list:remove(value)
    for i, v in self:enumerate() do
        if v == value then
            self:pop(i)
            return
        end
    end
    Rkr.Error.Value("%s is not in list", value)
end

function list:clear()
    self._data = {}
    self._size = 0
end

function list:__tostring() return self:_format_sequence() end

list:finalise()
Rkr.List = List
