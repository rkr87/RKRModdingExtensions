---@type Sequence
local Sequence = Rkr.Require("containers/base/sequence.lua")

---@class MutableSequence<T>: Sequence<T>, Object
---@field __set_index_protocol fun(self: MutableSequence<T>, index: integer, value: T)
---@field append fun(self: MutableSequence<T>, value: T)
---@field __add fun(self: MutableSequence<T>, other:  IterableSequence<T>): MutableSequence<T>
---@field extend fun(self: MutableSequence<T>, other:  IterableSequence<T>)
---@field insert fun(self: MutableSequence<T>, index: integer, value: T)
---@field pop fun(self: MutableSequence<T>, index?: integer): T
---@field remove fun(self: MutableSequence<T>, value: T): boolean
---@field clear fun(self: MutableSequence<T>)
---@field sort fun(self: MutableSequence<T>, cmp?: fun(a: T, b: T): boolean)
---@field reverse fun(self: MutableSequence<T>): MutableSequence<T>
---@field slice fun(self: MutableSequence<T>, start?: table|integer|nil, stop?: integer|nil, step?: integer): MutableSequence<T>
---@field copy fun(self: ...): MutableSequence<T>
local MutableSequence = Sequence:derive("MutableSequence", {
    abstract = true,
    requires = { "__set_index_protocol", "append", "extend", "insert", "pop",
        "remove", "clear" }
})

function MutableSequence:__newindex(key, value)
    self:_validate_index(key)
    local n = self:__len()
    if key == n then return self:append(value) end
    self:_normalise_index(key, n)
    self:__set_index_protocol(key, value)
end

function MutableSequence:sort(comp)
    comp = comp or function(a, b) return a < b end
    if type(comp) ~= "function" then
        Rkr.Error.Type("comparator must be a function")
    end
    local tmp = {}
    for v in self() do table.insert(tmp, v) end
    table.sort(tmp, comp)
    local n = self:__len()
    for i = 1, n do self[i - 1] = tmp[i] end
end

function MutableSequence:reverse()
    local n = self:__len()
    local i, j = 0, n - 1
    while i < j do
        local a, b = self[i], self[j]
        self[i] = b
        self[j] = a
        i, j = i + 1, j - 1
    end
    return self
end

function MutableSequence:extend(other)
    if other == nil then return end
    local iter = Sequence.get_iterable(other)
    if not iter then
        Rkr.Error.Type("MutableSequence:extend() expects iterable")
    end
    for v in iter do self:append(v) end
end

function MutableSequence:__add(other)
    ---@type MutableSequence
    local result = self:copy()
    result:extend(other)
    return result
end

return MutableSequence
