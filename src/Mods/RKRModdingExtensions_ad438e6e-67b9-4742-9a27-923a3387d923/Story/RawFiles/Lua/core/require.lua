if Rkr.Require then return end

local __RKR_REQUIRE_CACHE = {}

local function normalise(path)
    path = path:gsub("\\", "/")
    path = path:gsub("^%./", "")
    return path
end

local function unwrap(module)
    if type(module) == "table" and module[1] ~= nil then return module[1] end
    return module
end

local function RkrRequire(path)
    path = normalise(path)
    if __RKR_REQUIRE_CACHE[path] then return __RKR_REQUIRE_CACHE[path] end
    local result = Ext.Require(path)
    result = unwrap(result)
    __RKR_REQUIRE_CACHE[path] = result
    return result
end

Rkr.Require = RkrRequire
