local m_log = RkrModdingExtensions.log:with_context("Importer")
local SharedVars = {}

local PrivateKeys = {
    ModuleUUID = true,
    PersistentVars = true,
    LoadPersistentVars = true,
    Debug = true,
    Vars = true,
    Listeners = true,
    SkillListeners = true,
    ModListeners = true,
    Settings = true,
    Importer = true,
    ImportUnsafe = true,
    Import = true,
    CustomSkillProperties = true,
    _PV = true,
}

local Importer = {
    setup_shared_vars = function(targetMod)
        local meta = {}
        if targetMod.Vars ~= nil and getmetatable(targetMod.Vars) then
            meta = getmetatable(targetMod.Vars)
        end

        if meta.__index == nil then
            meta.__index = SharedVars
        else
            local lastIndexer = meta.__index
            local indexerType = type(lastIndexer)
            meta.__index = function(tbl, k)
                if SharedVars[k] ~= nil then return SharedVars[k] end
                if indexerType == "function" then
                    return lastIndexer(tbl, k)
                else
                    return lastIndexer[k]
                end
            end
        end

        if targetMod.Vars == nil then rawset(targetMod, "Vars", {}) end

        setmetatable(targetMod.Vars, meta)
    end,

    get_indexer = function(originalGetIndex)
        local get_index = function(tbl, k)
            if k == "RKRModdingExtensions" then
                return Mods.RKRModdingExtensions
            end
            if not PrivateKeys[k] then
                if Mods.RKRModdingExtensions[k] ~= nil then
                    return Mods.RKRModdingExtensions[k]
                end
            end
            if originalGetIndex then
                return originalGetIndex(tbl, k)
            end
        end
        return get_index
    end
}

---@param target_mod table
---@param mod_name string
function Import(target_mod, mod_name)
    local log = m_log:extend_context(mod_name)
    local mod_id = target_mod.ModuleUUID or "<unknown>"
    log:info("Importing mod table '%s' for '%s'", mod_id, mod_name)

    Importer.setup_shared_vars(target_mod)

    local targetMeta = getmetatable(target_mod)
    local targetOriginalGetIndex = nil
    if targetMeta.__index then
        if type(targetMeta.__index) == "function" then
            targetOriginalGetIndex = targetMeta.__index
        else
            local originalIndex = targetMeta.__index
            targetOriginalGetIndex = function(tbl, k)
                return originalIndex[k]
            end
        end
        log:debug("Wrapped existing __index function/table")
    end

    targetMeta.__index = Importer.get_indexer(targetOriginalGetIndex)
    log:debug("Applied new __index to existing metatable")

    log:info("Import complete for '%s'", mod_name)
end
