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
if Rkr.Test == nil then Rkr.Test = {} end
init_table({ "Constants", "Test" }, Rkr)


Ext.Require("Builtin/_Init.lua")
Ext.Require("Core/_Init.lua")
Ext.Require("Shared/_Init.lua")
Ext.Require("Tests/_Init.lua")
