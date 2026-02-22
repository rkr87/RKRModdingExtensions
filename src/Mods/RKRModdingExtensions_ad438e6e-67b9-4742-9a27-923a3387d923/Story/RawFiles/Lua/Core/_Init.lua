Ext.Require("Core/Constants.lua")
Ext.Require("Core/Logger.lua")
local SettingsManager = Ext.Require("Core/SettingsManager.lua")

local mod_globals = SettingsManager.get_mod(RkrModdingExtensions.ModName)

RkrModdingExtensions.log = Rkr.Logger(
    RkrModdingExtensions.ModName,
    mod_globals.log_level,
    mod_globals.log_verbose)

Ext.Require("Core/Importer.lua")

Rkr.Settings = SettingsManager()

RkrModdingExtensions.Settings = Rkr.Settings:bind_mod(RkrModdingExtensions.ModName)
