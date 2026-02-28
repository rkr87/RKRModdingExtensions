--------------------------------------------------------------------------------
-- Object
--
-- Root base class for the container type system.
-- Provides:
--   • Class derivation
--   • Abstract enforcement
--   • Required method contracts
--   • Metamethod propagation
--------------------------------------------------------------------------------

---@class Object
---@field __name string
---@field __parent Object|nil
---@field __requires table<string, boolean>
---@field __abstract boolean
---@field __public fun(...): Object
---@field new fun(self: Object, ...): Object    -
---@field derive fun(self: Object, name: string, opts?: table): Object
---@field finalise fun(self: Object)
---@field __tostring fun(self: Object): string
local Object = {}
Object.__index = Object
Object.__requires = {}
Object.__abstract = true

--------------------------------------------------------------------------------
-- Instance Construction
--------------------------------------------------------------------------------

---Creates a new instance of the class.
---The class itself acts as the metatable.
function Object:new(...)
    local obj = {}
    setmetatable(obj, self)
    return obj
end

--------------------------------------------------------------------------------
-- Metamethod Propagation (Internal)
--------------------------------------------------------------------------------

---Propagates selected metamethods from parent to child class
---if not explicitly overridden.
local function propagate_metamethods(child, parent)
    local m = { "__tostring", "__add", "__sub", "__eq", "__len", "__pairs",
        "__call", "__index", "__newindex" }
    for _, meta in ipairs(m) do
        if child[meta] == nil and parent[meta] ~= nil then
            child[meta] = parent[meta]
        end
    end
end

--------------------------------------------------------------------------------
-- Class Derivation
--------------------------------------------------------------------------------

---Derives a new class from the current class.
---Supports abstract classes and required method contracts.
function Object:derive(name, opts)
    opts = opts or {}
    local parent = self
    local class = {
        __name = name,
        __parent = parent,
        __abstract = opts.abstract or false,
        __requires = {}
    }
    -- Inherit required contracts
    if parent.__requires then
        for k, v in pairs(parent.__requires) do
            class.__requires[k] = v
        end
    end
    propagate_metamethods(class, parent)
    setmetatable(class, { __index = parent })
    return class
end

--------------------------------------------------------------------------------
-- Class Finalisation / Contract Enforcement
--------------------------------------------------------------------------------

---Validates that a concrete class:
---  • Implements all required methods
---  • Defines a public constructor (__public)
function Object:finalise()
    if self.__abstract then
        return
    end
    local missing = {}
    for method, _ in pairs(self.__requires or {}) do
        if self[method] == nil then
            table.insert(missing, method)
        end
    end
    if #missing > 0 then
        Rkr.Error.Type("Concrete class '%s' missing required methods: %s",
            self.__name, table.concat(missing, ", "))
    end
    if rawget(self, "__public") == nil then
        Rkr.Error.Type("Concrete class '%s' must define __public", self.__name)
    end
end

--------------------------------------------------------------------------------
-- Metamethods
--------------------------------------------------------------------------------

---Default string representation for objects.
function Object:__tostring()
    return ("<%s object>"):format(self.__name)
end

return Object
