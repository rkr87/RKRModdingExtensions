---@class Hash
---@field FNV_OFFSET integer 32-bit FNV-1a offset basis (2166136261)
---@field FNV_PRIME  integer 32-bit FNV-1a prime (16777619)
---@field MOD32      integer 2^32 modulus for unsigned 32-bit wraparound
local Hash = {}

Hash.FNV_OFFSET = 2166136261
Hash.FNV_PRIME = 16777619
Hash.MOD32 = 2 ^ 32

---Interface for objects that implement structural hashing.
---@class Hashable
---@field __hash fun(self: Hashable): integer

---@alias HashableObject Hashable|number|boolean|string|nil

---Converts a number to unsigned 32-bit space.
---@param n number
---@return integer
local function u32(n)
    return n % Hash.MOD32
end

---Order-sensitive hash combination (for tuple-like containers).
---@param h integer
---@param element_hash integer
---@return integer
function Hash.combine_ordered(h, element_hash)
    h = (h ~ element_hash) * Hash.FNV_PRIME
    return u32(h)
end

---Order-insensitive hash combination (for set-like containers).
---@param h integer
---@param element_hash integer
---@return integer
function Hash.combine_unordered(h, element_hash)
    h = h + element_hash
    return u32(h)
end

---Finalises a container hash by mixing in its size.
---@param h integer
---@param size integer
---@return integer
function Hash.finalise(h, size)
    h = (h ~ size) * Hash.FNV_PRIME
    return u32(h)
end

---Computes a 32-bit hash value for any Lua value.
---@param v any
---@return integer
function Hash.hash_value(v)
    local t = type(v)
    if t == "nil" then return 0 end
    if t == "number" then return u32(v) end
    if t == "boolean" then return v and 1 or 0 end
    if t == "string" then
        local h = Hash.FNV_OFFSET
        for i = 1, #v do
            h = (h ~ string.byte(v, i)) * Hash.FNV_PRIME
            h = u32(h)
        end
        return h
    elseif t == "table" then
        local mt = getmetatable(v)
        if mt and mt.__hash then return u32(Hash.hash_value(v:__hash())) end
    end
    return Rkr.Error.Type("unhashable type '%s'", t)
end

---Returns whether a value is considered hashable.
---@param v any
---@return boolean
function Hash.is_hashable(v)
    local t = type(v)
    if t == "number" or t == "boolean" or t == "string" or t == "nil" then
        return true
    end
    if t == "table" then
        local mt = getmetatable(v)
        return mt and mt.__hash ~= nil
    end
    return false
end

---Validates that a value is hashable.
---Raises a type error if not.
---@param v any
function Hash.validate_hashable(v)
    if not Hash.is_hashable(v) then
        Rkr.Error.Type("unhashable type '%s'", type(v))
    end
end

return Hash
