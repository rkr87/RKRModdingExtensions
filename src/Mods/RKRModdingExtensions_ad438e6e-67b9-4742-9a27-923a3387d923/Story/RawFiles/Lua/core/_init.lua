-- initialise shared globals table(s)
if Rkr == nil then Rkr = {} end
if Rkr.Constants == nil then Rkr.Constants = {} end
if Rkr.Error == nil then Rkr.Error = {} end

-- need to instantiate this mod's table before actually running mod setup as alot
--   of core functionility is dependent on it existing.
if RkrModdingExtensions == nil then RkrModdingExtensions = {} end

Ext.Require("core/make_callable.lua")
