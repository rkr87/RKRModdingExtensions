-- Core setups need to be initialised before anything else - includes methods/utils
--    used throughout internal/external/shared implementations
Ext.Require("core/_init.lua")

-- implement python container apis eg List/Dict/Set/Tuple
--    technically shared functionality but big enough implementation to warrant
--    its own implementation and needs to be initiated before any shared functionality
--    will work
Rkr.Require("containers/_init.lua")

-- shared functionality - ie used by this mod and any downstream mod
--     including but not limited to, SettingsManager, Testing, Logging, Import
Rkr.Require("shared/_init.lua")

-- internal mod functionality - ie functionality only used by this mod
Rkr.Require("internal/_init.lua")

-- external functionality - ie used only by downstream mods
--     helper functionality, eg timers, probabilitypools etc
Rkr.Require("external/_init.lua")
