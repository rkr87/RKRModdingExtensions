---@class Object
---@field __name string
---@field __parent Object|nil
---@field __requires table<string, boolean>
---@field __ancestory table<string, boolean>
---@field __abstract boolean
---@field __public fun(...): Object
---@field new fun(self: Object, ...): Object    -
---@field derive fun(self: Object, name: string, opts?: table): Object
---@field finalise fun(self: Object)
---@field is fun(self: Object, other: string): boolean
---@field __tostring fun(self: Object): string
local Object = {}
Object.__index = Object
Object.__requires = {}
Object.__ancestory = { ["Object"] = true }
Object.__abstract = true

function Object:new(...)
    local obj = {}
    setmetatable(obj, self)
    return obj
end

local function propagate_metamethods(child, parent)
    local m = { "__tostring", "__add", "__sub", "__eq", "__len", "__pairs",
        "__call", "__index", "__newindex" }
    for _, meta in ipairs(m) do
        if child[meta] == nil and parent[meta] ~= nil then
            child[meta] = parent[meta]
        end
    end
end

function Object:derive(name, opts)
    opts = opts or {}
    local parent = self
    local class = {
        __name = name,
        __parent = parent,
        __abstract = opts.abstract or false,
        __requires = {},
        __ancestory = { [name] = true }
    }
    if opts.requires then
        for _, v in pairs(opts.requires) do class.__requires[v] = true end
    end
    if parent.__requires then
        for k, v in pairs(parent.__requires) do class.__requires[k] = v end
    end
    if parent.__ancestory then
        for k, v in pairs(parent.__ancestory) do class.__ancestory[k] = v end
    end
    propagate_metamethods(class, parent)
    setmetatable(class, { __index = parent })
    return class
end

local function is_class_table(t)
    return type(t) == "table" and rawget(t, "__parent") ~= nil
end

function Object:is(other)
    if other == nil then return false end
    local a = self
    if not is_class_table(a) then a = getmetatable(a) end
    if not a then return false end
    return a.__ancestory[other] == true
end

function Object:finalise()
    if self.__abstract then return end
    local missing = {}
    for method, _ in pairs(self.__requires or {}) do
        if self[method] == nil then table.insert(missing, method) end
    end
    if #missing > 0 then
        Rkr.Error.Type("Concrete class '%s' missing required methods: %s",
            self.__name, table.concat(missing, ", "))
    end
    if rawget(self, "__public") == nil then
        Rkr.Error.Type("Concrete class '%s' must define __public", self.__name)
    end
end

function Object:__tostring() return ("<%s object>"):format(self.__name) end

return Object
