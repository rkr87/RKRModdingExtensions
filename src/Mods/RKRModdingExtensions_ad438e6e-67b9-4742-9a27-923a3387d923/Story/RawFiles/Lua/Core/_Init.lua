Ext.Require("Core/Constants.lua")
Ext.Require("Core/Logger.lua")
local SettingsManager = Ext.Require("Core/SettingsManager.lua")

local mod_globals = SettingsManager.static_get_mod(RkrModdingExtensions.ModName)

RkrModdingExtensions.log = Rkr.Logger(
    RkrModdingExtensions.ModName,
    mod_globals.log_level,
    mod_globals.log_verbose)

Rkr.Settings = SettingsManager.new()

RkrModdingExtensions.Settings = Rkr.Settings:bind_mod(RkrModdingExtensions.ModName)

Ext.Require("Core/Importer.lua")
