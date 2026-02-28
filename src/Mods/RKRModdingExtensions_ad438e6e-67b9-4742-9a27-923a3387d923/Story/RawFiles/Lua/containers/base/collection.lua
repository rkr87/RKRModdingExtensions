--------------------------------------------------------------------------------
-- Collection<K, V>
--
-- Abstract base class for all container types.
--
-- Guarantees:
--   • Length protocol (__len)
--   • Iteration protocol (__pairs)
--   • Membership testing (__contains)
--   • Item iteration (__items)
--   • Value iteration (__values)
--
-- Concrete subclasses must implement __public and all required metamethods.
--------------------------------------------------------------------------------

---@type Object
local Object = Ext.Require("containers/base/object.lua")

---@class Collection<K, V>: Object
---@field __len fun(self: Collection<K, V>): integer
---@field __pairs fun(self: Collection<K, V>): fun(): K, V
---@field __contains fun(self: Collection<K, V>, value: K|V): boolean
---@field __items fun(self: Collection<K, V>): fun(): Sequence<K|V>
---@field __values fun(self: Collection<K, V>): fun(): V
---@field len fun(self: Collection<K, V>): integer
---@field contains fun(self: Collection<K, V>, value: K|V): boolean
---@field items fun(self: Collection<K, V>): fun(): Sequence<K|V>
---@field values fun(self: Collection<K, V>): fun(): V
local Collection = Object:derive("Collection", {
    abstract = true,
    requires = { "__len", "__pairs", "__contains", "__items", "__values" }
})

--------------------------------------------------------------------------------
-- Public API Wrappers
--
-- These delegate to required metamethod implementations.
--------------------------------------------------------------------------------

---Returns the number of elements in the collection.
function Collection:len() return self:__len() end

---Returns true if the value exists within the collection.
function Collection:contains(x) return self:__contains(x) end

---Returns an iterator over key/value pairs.
function Collection:items() return self:__items() end

---Returns an iterator over values.
function Collection:values() return self:__values() end

return Collection
