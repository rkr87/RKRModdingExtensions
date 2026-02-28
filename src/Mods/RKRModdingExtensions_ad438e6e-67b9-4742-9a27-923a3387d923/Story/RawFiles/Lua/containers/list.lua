--------------------------------------------------------------------------------
-- list<T>
--
-- Concrete mutable 0-based sequence implementation.
--
-- Backed by:
--   • _data  (sparse 0-based array)
--   • _size  (explicit length tracking)
--
-- Public constructor exposed via List(...)
--------------------------------------------------------------------------------

---@type MutableSequence
local MutableSequence = Ext.Require("containers/base/mutable_sequence.lua")

---@class list<T>: MutableSequence<T>, Object
---@field private _data table<integer, T>
---@field private _size integer
---@field private __public List
---@field append fun(self: list<T>, value: T)
---@field extend fun(self: list<T>, other: list<T>)
---@field insert fun(self: list<T>, index: integer, value: T)
---@field pop fun(self: list<T>, index?: integer): T
---@field remove fun(self: list<T>, value: T)
---@field clear fun(self: list<T>)
---@field __len fun(self: list<T>): integer
---@field __index_protocol fun(self: list<T>, index: integer): T
---@field __set_index_protocol fun(self: list<T>, index: integer, value: T)
---@field __tostring fun(self: list<T>): string
local list = MutableSequence:derive("list")

--------------------------------------------------------------------------------
-- Public Constructor Wrapper
--------------------------------------------------------------------------------

---@class List<T>
---@field new fun(t?: T[]|list<T>|fun():T|table): list<T>
---@field list fun(obj?: list<T>|table|fun():T): list<T>
local List = {}
list.__public = List
setmetatable(List, { __call = function(_, ...) return List.new(...) end })

--------------------------------------------------------------------------------
-- Construction
--------------------------------------------------------------------------------

function List.new(t)
    local data = {}
    local size = 0
    if t == nil then return setmetatable({ _data = data, _size = size }, list) end

    if getmetatable(t) == list then return t:copy() end
    local typ = type(t)
    if typ == "table" then
        for _, v in ipairs(t) do
            data[size] = v
            size = size + 1
        end
    elseif typ == "function" then
        for v in t do
            data[size] = v
            size = size + 1
        end
    else
        return Rkr.Error.Type("List.new() expects table, list, iterator or nil")
    end

    return setmetatable({ _data = data, _size = size }, list)
end

-- TODO: Get rid of this
List.list = List.new

--------------------------------------------------------------------------------
-- Required Protocol Implementations
--------------------------------------------------------------------------------

function list:__index_protocol(index) return self._data[index] end

function list:__set_index_protocol(index, value) self._data[index] = value end

function list:__len() return self._size end

--------------------------------------------------------------------------------
-- Mutating Operations
--------------------------------------------------------------------------------

function list:append(value)
    self._data[self._size] = value
    self._size = self._size + 1
end

function list:extend(other)
    for i = 0, other._size - 1 do self:append(other._data[i]) end
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
    for i = 0, self._size - 1 do
        if self._data[i] == value then
            self:pop(i)
            return
        end
    end
    Rkr.Error.Value("%s is not in list", value)
end

function list:clear()
    for i = 0, self._size - 1 do self._data[i] = nil end
    self._size = 0
end

--------------------------------------------------------------------------------
-- Metamethods
--------------------------------------------------------------------------------

function list:__tostring() return self:_format_sequence("[", "]") end

--------------------------------------------------------------------------------
-- Finalisation
--------------------------------------------------------------------------------

list:finalise()
Rkr.List = List
