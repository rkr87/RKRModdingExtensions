-- initialise shared globals table(s)
if Rkr == nil then Rkr = {} end
if Rkr.Constants == nil then Rkr.Constants = {} end
if Rkr.Error == nil then Rkr.Error = {} end

-- need to instantiate this mod's table before actually running mod setup as a
--     lot of core functionility is dependent on it existing.
if RkrModdingExtensions == nil then RkrModdingExtensions = {} end

Ext.Require("core/require.lua")
Rkr.Require("core/errors.lua")
--TODO make this internal/local
Rkr.Require("core/make_callable.lua")
