if Rkr == nil then Rkr = {} end

local function InitTable(name, target)
    target = target or Mods.RKRModdingExtensions
    if type(name) == "table" then
        for _, v in pairs(name) do
            target[v] = {}
        end
    elseif target[name] == nil then
        target[name] = {}
    end
end

InitTable({ "Rkr" })
Ext.Require("Shared/Builtins/_Init.lua")

Vars = {}

Importer = {
    SetupVarsMetaTable = function(targetModTable)
        local meta = {}
        if targetModTable.Vars ~= nil and getmetatable(targetModTable.Vars) then
            meta = getmetatable(targetModTable.Vars)
        end
        if meta.__index == nil then
            meta.__index = Vars
        else
            local lastIndexer = meta.__index
            local indexerType = type(lastIndexer)
            meta.__index = function(tbl, k)
                if Vars[k] ~= nil then
                    return Vars[k]
                end
                if indexerType == "function" then
                    return lastIndexer(tbl, k)
                else
                    return lastIndexer[k]
                end
            end
        end
        if targetModTable.Vars == nil then
            rawset(targetModTable, "Vars", {})
        end
        setmetatable(targetModTable.Vars, meta)
    end,
    PrivateKeys = {
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
    },
    GetIndexer = function(originalGetIndex, additionalTable)
        local getIndex = function(tbl, k)
            if k == "RKRModdingExtensions" then
                return Mods.RKRModdingExtensions
            end
            if not Importer.PrivateKeys[k] then
                if additionalTable and additionalTable[k] ~= nil then
                    return additionalTable[k]
                end
                if Mods.RKRModdingExtensions[k] ~= nil then
                    return Mods.RKRModdingExtensions[k]
                end
            end
            if originalGetIndex then
                return originalGetIndex(tbl, k)
            end
        end
        return getIndex
    end
}

---@param targetModTable table
---@param additionalTable? table
function Import(targetModTable, additionalTable)
    Importer.SetupVarsMetaTable(targetModTable)
    local targetMeta = getmetatable(targetModTable)
    if not targetMeta then
        setmetatable(targetModTable, {
            __index = Importer.GetIndexer(nil, additionalTable)
        })
    else
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
        end
        targetMeta.__index = Importer.GetIndexer(targetOriginalGetIndex, additionalTable)
    end
end
