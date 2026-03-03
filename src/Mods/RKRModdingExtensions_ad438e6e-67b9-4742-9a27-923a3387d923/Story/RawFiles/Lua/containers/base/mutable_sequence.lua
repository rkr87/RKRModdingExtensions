--------------------------------------------------------------------------------
-- MutableSequence<T>
--
-- Abstract mutable variant of Sequence<T>.
--
-- Extends:
--   • Indexed access
--   • Iteration
--   • Equality
--
-- Adds:
--   • Indexed assignment
--   • Structural mutation
--   • In-place sorting and reversing
--
-- Concrete subclasses must implement:
--   • __public
--   • __set_index_protocol(index, value)
--   • append
--   • extend
--   • insert
--   • pop
--   • remove
--   • clear
--------------------------------------------------------------------------------
---@type Sequence
local Sequence = Rkr.Require("containers/base/sequence.lua")

---@class MutableSequence<T>: Sequence<T>, Object
---@field __set_index_protocol fun(self: MutableSequence<T>, index: integer, value: T)
---@field append fun(self: MutableSequence<T>, value: T)
---@field extend fun(self: MutableSequence<T>, values: Collection<T>)
---@field insert fun(self: MutableSequence<T>, index: integer, value: T)
---@field pop fun(self: MutableSequence<T>, index?: integer): T
---@field remove fun(self: MutableSequence<T>, value: T): boolean
---@field clear fun(self: MutableSequence<T>)
---@field sort fun(self: MutableSequence<T>, cmp?: fun(a: T, b: T): boolean)
---@field reverse fun(self: MutableSequence<T>): MutableSequence<T>
local MutableSequence = Sequence:derive("MutableSequence", {
    abstract = true,
    requires = { "__set_index_protocol", "append", "extend", "insert", "pop", "remove", "clear" }
})

--------------------------------------------------------------------------------
-- Metamethods
--------------------------------------------------------------------------------

---Handles indexed assignment.
---Supports:
---  • Setting existing indices
---  • Appending via index == length
function MutableSequence:__newindex(key, value)
    self:_validate_index(key)

    local n = self:__len()

    if key == n then
        return self:append(value)
    end

    self:_normalise_index(key, n)
    self:__set_index_protocol(key, value)
end

--------------------------------------------------------------------------------
-- Public Mutating Operations
--------------------------------------------------------------------------------

---Sorts the sequence in-place.
---Defaults to ascending comparison using <.
function MutableSequence:sort(comp)
    comp = comp or function(a, b) return a < b end
    if type(comp) ~= "function" then
        Rkr.Error.Type("comparator must be a function")
    end
    local tmp = {}
    for _, v in self:__pairs() do table.insert(tmp, v) end
    table.sort(tmp, comp)
    local n = self:__len()
    for i = 0, n - 1 do self[i] = tmp[i + 1] end
end

---Reverses the sequence in-place.
---Returns self for chaining.
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

return MutableSequence
