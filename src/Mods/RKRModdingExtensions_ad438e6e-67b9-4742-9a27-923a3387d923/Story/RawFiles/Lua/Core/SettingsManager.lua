---@class settings
---@field private _base_path string
---@field private _global dict<string, any>
---@field private _mods table<string, dict<string, any>>
---@field private _log logger
local settings = {}
settings.__index = settings

---@type dict<string, any>
local GLOBAL_DEFAULTS = Rkr.Dict({
    log_level = "WARN",
    log_verbose = false,
    run_tests = false
})
local base_path = "Rkr/Settings"
---Create the central settings manager.
---@return settings
function settings.new()
    local self = setmetatable({}, settings)
    self._log = RkrModdingExtensions.log:with_context("SettingsManager")
    self._log:info("Initialising SettingsManager")
    self._base_path = base_path
    self._mods = {}
    self._global = self:_load_mod("global", GLOBAL_DEFAULTS)

    self._log:info("SettingsManager ready")
    return self
end

---Get the global settings table.
---@return dict<string, any>
function settings:get_global()
    return self._global
end

---Get a mod's settings table (lazy-loaded).
---@param mod_name string?
---@return dict<string, any>
function settings:get_mod(mod_name)
    if mod_name then
        if not self._mods[mod_name] then
            self:_load_mod(mod_name)
        else
        end
        return self._mods[mod_name]
    end

    self._log:debug("Returning all loaded mods")
    return self._mods
end

---Persist a mod's settings to disk.
---@param mod_name string
function settings:save_mod(mod_name)
    local path = self._base_path .. "/" .. mod_name .. ".json"
    self._log:info("Saving settings for mod '%s' -> %s", mod_name, path)
    Ext.IO.SaveFile(path, Ext.Json.Stringify(self:get_mod(mod_name)))
end

---Load a JSON file for a mod.
---@private
---@return dict<string, any> | nil
function settings:_load_file(mod_name)
    local log = self._log:extend_context(mod_name)
    local path = self._base_path .. "/" .. mod_name .. ".json"
    log:debug("Loading mod settings file")

    local text = Ext.IO.LoadFile(path)
    if not text then
        log:warn("No settings file found at %s", path)
        return
    end

    local decoded = Ext.Json.Parse(text)
    if type(decoded) == "table" then
        local dict = Rkr.Dict(decoded)
        log:debug("Loaded %d entries", dict:size())
        return dict
    end

    self._log:error("Corrupt JSON in '%s'", path)
end

---Load or create a mod's settings.
---@private
---@param mod_name string
---@param defaults? dict<string, any> | nil
---@return dict<string, any>
function settings:_load_mod(mod_name, defaults)
    local log = self._log:extend_context(mod_name)
    if not self._mods[mod_name] then
        log:info("Loading mod settings '%s'", mod_name)

        local data = Rkr.Dict()
        if defaults then
            log:debug("Applying default mod settings")
            data = defaults
        end

        local saved_settings = self:_load_file(mod_name)
        if saved_settings then
            log:debug("Merging saved mod settings", mod_name)
            data:update(saved_settings)
        end

        self._mods[mod_name] = data

        if saved_settings ~= data and data:size() > 0 then
            log:info("Updating saved settings '%s'", mod_name)
            self:save_mod(mod_name)
        end
    else
        log:debug("Settings already loaded", mod_name)
    end

    return self._mods[mod_name]
end

---@class ModSettingsView
---@field private _manager settings
---@field private _mod_name string
---@field private _log logger
---@field log_level string
---@field log_verbose boolean
---@field run_tests boolean
---@field [string] any
local ModSettingsView = {}
ModSettingsView.__index = ModSettingsView

---Get a setting (mod → global → hard defaults).
---Get a setting (mod → global → hard defaults) with debug logs
---@param key string
---@param default any?
---@return any
function ModSettingsView:get(key, default)
    local m = self._manager:get_mod(self._mod_name)[key]
    if m ~= nil then
        self._log:debug("Retrieved setting '%s' from mod settings : %s", key, m)
        return m
    end
    local g = self._manager:get_global()[key]
    if g ~= nil then
        self._log:debug("Retrieved setting '%s' from global settings : %s", key, g)
        return g
    end
    local gd = GLOBAL_DEFAULTS[key]
    if gd ~= nil then
        self._log:debug("Retrieved setting '%s' from global defaults : %s", key, gd)
        return gd
    end
    if default ~= nil then
        self._log:debug("Setting '%s' not found, returning default : %s", key, default)
        return default
    end
end

---Set a mod-specific setting.
---@param key string
---@param value any
function ModSettingsView:set(key, value)
    self._log:debug("Setting '%s' = %s", key, value)
    self._manager:get_mod(self._mod_name)[key] = value
    self:_save()
end

---Remove a mod-specific setting.
---@param key string
function ModSettingsView:remove(key)
    self._log:debug("Removing setting '%s'", key)
    self._manager:get_mod(self._mod_name):pop(key, nil)
    self:_save()
end

---Persist this mod's settings.
function ModSettingsView:_save()
    self._log:info("Persisting settings '%s'", self._mod_name)
    self._manager:save_mod(self._mod_name)
end

---@param k string
---@return any
function ModSettingsView:__index(k)
    local class_value = rawget(ModSettingsView, k)
    if class_value ~= nil then
        return class_value
    end
    return self:get(k)
end

---@param k string
---@param v any
function ModSettingsView:__newindex(k, v)
    self._log:debug("Direct assign '%s.%s' = %s",
        self._mod_name, k, v)
    self._manager:get_mod(self._mod_name)[k] = v
    self:_save()
end

---@param mod_name string
---@param defaults? dict<string, any>|nil
---@return ModSettingsView
function settings:bind_mod(mod_name, defaults)
    local log = self._log:extend_context(mod_name)
    log:info("Binding mod '%s'", mod_name)
    self:_load_mod(mod_name, defaults)

    local proxy = setmetatable(
        { _manager = self, _mod_name = mod_name, _log = log }, ModSettingsView)

    return proxy
end

---@class SettingsManager
local SettingsManager = {}

---@param name string
---@return dict<string, any> | nil
---@private
local function _static_load_file(name)
    local path = base_path .. "/" .. name .. ".json"
    local text = Ext.IO.LoadFile(path)
    if not text then return nil end

    local decoded = Ext.Json.Parse(text)
    if type(decoded) ~= "table" then
        Rkr.Logger.log("ERROR", "ERROR", "SettingsManager",
            "Invalid JSON in %s", path
        )
        return nil
    end
    return Rkr.Dict(decoded)
end

---Static: Load effective global settings for a mod.
---Priority: mod.json → global.json → hard defaults
---@param mod_name string
---@return dict<string, any>
function SettingsManager.get_mod(mod_name)
    local mod = _static_load_file(mod_name)
    local global = _static_load_file("global")
    local log_level = (mod and mod.log_level) or (global and global.log_level) or GLOBAL_DEFAULTS.log_level
    local log_verbose = (mod and mod.log_verbose) or (global and global.log_verbose) or GLOBAL_DEFAULTS.log_verbose
    Rkr.Logger.log(log_level, log_verbose, "INFO", "SettingsManager",
        "Loading global settings for mod '%s'", mod_name)
    local result = GLOBAL_DEFAULTS:copy()

    Rkr.Logger.log(log_level, log_verbose, "DEBUG", "SettingsManager",
        "Applied %d hard default settings", result:size())

    if global then
        result:update(global)
        Rkr.Logger.log(log_level, log_verbose, "DEBUG", "SettingsManager",
            "Merged %d keys from global.json", global:size())
    end
    if mod then
        result:update(mod)
        Rkr.Logger.log(log_level, log_verbose, "DEBUG", "SettingsManager",
            "Merged %d keys from %s.json", mod:size(), mod_name)
    end

    Rkr.Logger.log(log_level, log_verbose, "INFO", "SettingsManager",
        "Resolved global settings for '%s'", mod_name)
    return result
end

RkrModdingExtensions.make_callable(SettingsManager, settings.new)
---@overload fun(): settings
RkrModdingExtensions.SettingsManager = SettingsManager
