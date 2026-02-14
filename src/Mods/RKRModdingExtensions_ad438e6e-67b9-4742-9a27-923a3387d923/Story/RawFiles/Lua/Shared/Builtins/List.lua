-- List.lua
---@class list<T>
---@field [integer] T
local List = {}
List.__index = List

setmetatable(List, {
    __call = function(_, t)
        return List.new(t)
    end
})

---Create a new List.
---@generic T
---@param t T[]|nil
---@return list<T>
function List.new(t)
    return setmetatable(t or {}, List)
end

---Normalise negative indices to positive ones.
---@param index number The index to normalise
---@param len number Length of the list
---@return number Normalised index
local function normalise_index(index, len)
    if index < 0 then
        index = len + index + 1
    end
    return index
end

---Append a value to the end of the list.
---@param value T
function List:append(value)
    self[#self + 1] = value
end

-- Aliases for append
List.add = List.append
List.push = List.append

---Insert a value at a specific index.
---@param index number Index to insert at (supports negative)
---@param value T Value to insert
function List:insert(index, value)
    index = normalise_index(index, #self)
    table.insert(self, index, value)
end

---Remove and return the value at the given index (defaults to last element).
---@param index number|nil Index to pop (optional)
---@return T|nil
function List:pop(index)
    if #self == 0 then return nil end
    index = index or #self
    index = normalise_index(index, #self)
    local value = self[index]
    table.remove(self, index)
    return value
end

---Remove the first occurrence of a value.
---@param value T
---@return boolean True if removed
function List:remove(value)
    for i, v in ipairs(self) do
        if v == value then
            table.remove(self, i)
            return true
        end
    end
    return false
end

---Remove all occurrences of a value.
---@param value T
---@return boolean True if any were removed
function List:remove_all(value)
    local items_removed = false
    for i = #self, 1, -1 do
        if self[i] == value then
            table.remove(self, i)
            items_removed = true
        end
    end
    return items_removed
end

---Check if a value exists in the list.
---@param value T
---@return boolean True if exists
function List:contains(value)
    for _, v in ipairs(self) do
        if v == value then return true end
    end
    return false
end

---Count the number of occurrences of a value.
---@param value T
---@return number
function List:count(value)
    local n = 0
    for _, v in ipairs(self) do
        if v == value then n = n + 1 end
    end
    return n
end

---Return the first index of a value, or nil.
---@param value T
---@return number|nil
function List:index(value)
    for i, v in ipairs(self) do
        if v == value then return i end
    end
    return nil
end

---Return a list of all indices of a value.
---@param value T
---@return list<number>
function List:index_all(value)
    ---@type list<number>
    local list = List.new()
    for i, v in ipairs(self) do
        if v == value then list:append(i) end
    end
    return list
end

---Clear all elements from the list.
function List:clear()
    for i = #self, 1, -1 do
        self[i] = nil
    end
end

---Append all values from another table or list.
---@param other_list T[]|list<T>
function List:extend(other_list)
    for _, v in ipairs(other_list) do
        self:append(v)
    end
end

---Return the length of the list.
---@return number
function List:len()
    return #self
end

-- Alias for len
List.size = List.len

---Return a shallow copy of the list.
---@return list<T>
function List:copy()
    local t = {}
    for i, v in ipairs(self) do
        t[i] = v
    end
    return List.new(t)
end

---Return a slice of the list.
---Supports negative indices and step.
---@param start number|nil Start index (defaults to 1)
---@param stop number|nil Stop index (defaults to length)
---@param step number|nil Step between indices (defaults to 1)
---@return list<T>
function List:slice(start, stop, step)
    local result = List.new({})
    local len = #self

    start = start or 1
    stop = stop or len
    step = step or 1

    start = normalise_index(start, len)
    stop = normalise_index(stop, len)

    if step == 0 then return result end

    if step > 0 then
        for i = start, stop, step do
            if self[i] ~= nil then
                result:append(self[i])
            end
        end
    else
        for i = start, stop, step do
            if self[i] ~= nil then
                result:append(self[i])
            end
        end
    end

    return result
end

---Reverse the list in place.
function List:reverse()
    local i, j = 1, #self
    while i < j do
        self[i], self[j] = self[j], self[i]
        i = i + 1
        j = j - 1
    end
end

---Sort the list in place.
---@param cmp fun(a:T, b:T):boolean|nil Optional comparator
function List:sort(cmp)
    table.sort(self, cmp)
end

---Return an iterator over indices and values.
---@return fun():number, T
function List:iter()
    local i = 0
    return function()
        i = i + 1
        return i, self[i]
    end
end

---Return an iterator over values only.
---@return fun(): T
function List:values()
    local i = 0
    return function()
        i = i + 1
        return self[i]
    end
end

---Check equality with another List.
---@param other list<T>
---@return boolean
function List:__eq(other)
    if #self ~= #other then return false end
    for i = 1, #self do
        if self[i] ~= other[i] then return false end
    end
    return true
end

---Return a string representation of the list.
---@return string
function List:__tostring()
    local parts = {}
    for i, v in ipairs(self) do
        parts[i] = tostring(v)
    end
    return "[" .. table.concat(parts, ", ") .. "]"
end

---Python-style iterator: for v in list do
---@return fun(): T
function List:__call()
    return self:values()
end

Rkr.List = List
