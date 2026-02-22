local log = RkrModdingExtensions.log:with_context("ProbabilityPool")

---@enum Rarity
local Rarity = {
    COMMON = "COMMON",
    UNCOMMON = "UNCOMMON",
    RARE = "RARE",
    VERY_RARE = "VERY_RARE"
}

---@class ProbabilityPool<T>
---@field private _distribution table<string, number>
---@field private _tiers string[]
local ProbabilityPool = {}
ProbabilityPool.__index = ProbabilityPool
ProbabilityPool.Tier = Rarity

local DEFAULT_DISTRIBUTION = {
    [Rarity.COMMON] = 0.50,
    [Rarity.UNCOMMON] = 0.31,
    [Rarity.RARE] = 0.16,
    [Rarity.VERY_RARE] = 0.03
}

---@generic T
---@param item_map table<string, T[]> use ProbabilityPool.Tier
---@param custom_distribution table<string, number>?
---@return ProbabilityPool<T>
function ProbabilityPool.new(item_map, custom_distribution)
    log:info("Creating ProbabilityPool with %d tiers",
        (function()
            local c = 0; for _ in pairs(item_map or {}) do c = c + 1 end; return c
        end)())
    local self = setmetatable(item_map or {}, ProbabilityPool)
    self._distribution = custom_distribution or DEFAULT_DISTRIBUTION
    self:_balance()
    return self
end

-- Allow ProbabilityPool(item_map, weights) syntax
setmetatable(ProbabilityPool, {
    ---@generic T
    ---@param _ table
    ---@param item_map table<string, T[]>
    ---@param custom_distribution table<string, number>? use ProbabilityPool.Tier
    ---@return ProbabilityPool<T>
    __call = function(_, item_map, custom_distribution)
        return ProbabilityPool.new(item_map, custom_distribution)
    end
})

--- Internal: Synchronises the tiers and ensures weights sum to 1.0
---@private
function ProbabilityPool:_balance()
    self._tiers = {}
    local total = 0

    for tier, weight in pairs(self._distribution) do
        table.insert(self._tiers, tier)
        total = total + weight
    end

    if total <= 0 then
        log:warn("Total weight <= 0, defaulting COMMON to 1.0")
        self._distribution[Rarity.COMMON] = 1.0
        total = 1.0
    end

    for tier, weight in pairs(self._distribution) do
        self._distribution[tier] = weight / total
        log:debug("Tier '%s' normalised to %.3f", tier, self._distribution[tier])
    end

    table.sort(self._tiers, function(a, b)
        return self._distribution[a] > self._distribution[b]
    end)

    log:debug("Tiers sorted by weight: %s", table.concat(self._tiers, ", "))
end

--- Updates a specific weight and re-balances the pool
---@param tier string  use ProbabilityPool.Tier
---@param weight number
function ProbabilityPool:update_weight(tier, weight)
    if self._distribution[tier] then
        log:info("Updating weight for tier '%s' to %.3f", tier, weight)
        self._distribution[tier] = weight
        self:_balance()
    else
        log:warn("Attempted to update unknown tier '%s'", tier)
    end
end

--- Selects an item based on distribution weights
---@param filter_callback? fun(items: T[]): T[]
---@return T?
function ProbabilityPool:select(filter_callback)
    local roll = math.random()
    local cumulative = 0
    local selected_tier = self._tiers[1]

    for _, tier in ipairs(self._tiers) do
        cumulative = cumulative + self._distribution[tier]
        if roll <= cumulative then
            selected_tier = tier
            break
        end
    end

    local pool = self[selected_tier]
    if filter_callback then
        pool = filter_callback(pool)
    end

    log:debug("Selected tier '%s' for roll %.3f (pool size=%d)", selected_tier, roll, pool and #pool or 0)
    return ProbabilityPool.get_random(pool)
end

function ProbabilityPool:get_pool_tier(index)
    return self._tiers[index]
end

function ProbabilityPool:get_pool()
    return self._tiers
end

--- Static: Picks a random element from an array
---@generic T
---@param array T[]
---@return T?
function ProbabilityPool.get_random(array)
    if not array or #array == 0 then
        log:warn("Attempted to get random element from empty array")
        return nil
    end
    local result = array[math.random(#array)]
    log:debug("Randomly selected element: %s", result)
    return result
end

--- Static: Simple probability test (e.g., 0.15 for 15% success)
---@param chance number
---@return boolean
function ProbabilityPool.test(chance)
    local roll = math.random()
    local result = roll < chance
    log:debug("Probability test %.2f < %.2f => %s", roll, chance, result)
    return result
end

Rkr.ProbabilityPool = ProbabilityPool
