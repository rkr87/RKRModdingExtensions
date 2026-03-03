RkrModdingExtensions.ModName = "RkrModdingExtensions"
-- Hacky way to set appropriate log levels before SettingsManager is loaded
local mod_globals = RkrModdingExtensions.SettingsManager.get_mod(RkrModdingExtensions.ModName)
RkrModdingExtensions.log = Rkr.Logger(
    RkrModdingExtensions.ModName,
    mod_globals.log_level,
    mod_globals.log_verbose)

Rkr.Settings = RkrModdingExtensions.SettingsManager()

RkrModdingExtensions.Settings = Rkr.Settings:bind_mod(RkrModdingExtensions.ModName)

if not RkrModdingExtensions.Settings.run_tests then return end
Rkr.Test.initialise(
    RkrModdingExtensions.ModName,
    RkrModdingExtensions.Settings.log_level
)
Rkr.Require("internal/tests/_init.lua")
