if RkrModdingExtensions == nil then RkrModdingExtensions = {} end

RkrModdingExtensions.ModName = "RkrModdingExtensions"

local function init_table(name, target)
    target = target or Mods.RKRModdingExtensions
    if type(name) == "table" then
        for _, v in pairs(name) do
            target[v] = {}
        end
    elseif target[name] == nil then
        target[name] = {}
    end
end

if Rkr == nil then Rkr = {} end
init_table({ "Rkr" })
if Rkr.Constants == nil then Rkr.Constants = {} end
init_table({ "Constants" }, Rkr)

---@generic T
---@param class table
---@param constructor fun(...): T
local function make_callable(class, constructor)
    class.__index = class
    setmetatable(class, {
        __call = function(_, ...)
            return constructor(...)
        end
    })
end

RkrModdingExtensions.make_callable = make_callable

Ext.Require("Builtin/_Init.lua")
Ext.Require("Core/_Init.lua")
Ext.Require("Shared/_Init.lua")

if not RkrModdingExtensions.Settings.run_tests then return end
Rkr.Test.initialise(RkrModdingExtensions.ModName)
Ext.Require("Tests/_Init.lua")
