-- List.lua
---@class list<T>
---@field private _data T[]
---@field private _size number
local list = {}
list.__index = list

---@generic T
---@param t T[]|nil
---@return list<T>
function list.new(t)
    local self = setmetatable({
        _data = {},
        _size = 0
    }, list)

    if t then
        for _, v in ipairs(t) do
            self._data[self._size] = v
            self._size = self._size + 1
        end
    end

    return self
end

---@param index number
local function is_int(index)
    if type(index) ~= "number" then
        error("NameError: name '" .. index .. ' is not defined')
    elseif index ~= math.floor(index) then
        error("TypeError: list indices must be integers or slices, not float")
    end
end

---@param index number
---@param size number
---@return number
local function clamp_slice_index(index, size)
    if index < 0 then
        index = size + index
    end
    return index
end

---@param index number
---@param size number
local function index_bounds(index, size)
    if index < 0 or index >= size then
        error("IndexError: list index out of range")
    end
end

---@param index number
---@param size number
---@return number
local function normalise_write(index, size)
    is_int(index)
    return clamp_slice_index(index, size)
end

---@param index number
---@param size number
---@return number
local function normalise_read(index, size)
    index = normalise_write(index, size)
    index_bounds(index, size)
    return index
end

---@param key any
---@return any
function list:__index(key)
    if type(key) == "number" then
        key = normalise_read(key, self._size)
        return self._data[key]
    end
    return rawget(list, key)
end

---@param index number
---@param value T
function list:__newindex(index, value)
    index = normalise_write(index, self._size)

    if index == self._size then
        self._data[self._size] = value
        self._size = self._size + 1
        return
    end
    index_bounds(index, self._size)
    self._data[index] = value
end

---@return number
function list:__len()
    return self._size
end

---@param value T
function list:append(value)
    self._data[self._size] = value
    self._size = self._size + 1
end

list.add = list.append
list.push = list.append

---@param index number
---@param value T
function list:insert(index, value)
    is_int(index)
    index = clamp_slice_index(index, self._size)
    index = math.max(index, 0)
    index = math.min(index, self._size)

    for i = self._size, index, -1 do
        self._data[i] = self._data[i - 1]
    end

    self._data[index] = value
    self._size = self._size + 1
end

---@param other list<T>
function list:extend(other)
    for i = 0, other._size - 1 do
        self:append(other._data[i])
    end
end

---@param index number|nil
---@return T
function list:pop(index)
    if self._size == 0 then
        error("IndexError: pop from empty list")
    end

    index = index or self._size - 1
    index = normalise_read(index, self._size)

    local value = self._data[index]

    for i = index, self._size - 1 do
        self._data[i] = self._data[i + 1]
    end

    self._data[self._size] = nil
    self._size = self._size - 1

    return value
end

---@param value T
function list:remove(value)
    for i = 0, self._size - 1 do
        if self._data[i] == value then
            self:pop(i)
            return
        end
    end
    error("ValueError: " .. tostring(value) .. " is not in list")
end

function list:clear()
    for i = 0, self._size - 1 do
        self._data[i] = nil
    end
    self._size = 0
end

---@return number
function list:len()
    return self._size
end

list.size = list.len

---@generic T
---@return fun(): number, T
function list:iter()
    local i = -1
    local n = self._size
    return function()
        i = i + 1
        if i < n then
            return i, self._data[i]
        end
    end
end

---@generic T
---@return fun(): T
function list:values()
    local i = -1
    local n = self._size
    return function()
        i = i + 1
        if i < n then
            return self._data[i]
        end
    end
end

function list:__call()
    return self:values()
end

---@generic T
---@return list<T>
function list:copy()
    local t = {}
    for i = 0, self._size - 1 do
        t[i + 1] = self._data[i]
    end
    return list.new(t)
end

---@generic T
---@param start number|nil
---@param stop number|nil
---@param step number|nil
---@return list<T>
function list:slice(start, stop, step)
    local result = list.new()
    local n = self._size

    step = step or 1
    if step == 0 then
        error("ValueError: slice step cannot be zero")
    end

    if step > 0 then
        start = clamp_slice_index(start or 0, n)
        stop = clamp_slice_index(stop or n, n)
    else
        start = clamp_slice_index(start or n, n)
        if stop == nil then
            stop = -1
        else
            stop = clamp_slice_index(stop, n)
        end
    end

    local function _append_result(i)
        if i >= 0 and i < n then
            result:append(self._data[i])
        end
        return i + step
    end

    local i = start
    if step > 0 then
        while i < stop do
            i = _append_result(i)
        end
    else
        while i > stop do
            i = _append_result(i)
        end
    end
    return result
end

function list:reverse()
    local i, j = 0, self._size - 1
    while i < j do
        self._data[i], self._data[j] = self._data[j], self._data[i]
        i = i + 1
        j = j - 1
    end
end

---@param cmp? fun(a:T,b:T):boolean|nil
function list:sort(cmp)
    cmp = cmp or function(a, b)
        return a < b
    end

    local threshold = 16

    local function insertion_sort(left, right)
        for i = left + 1, right do
            local key = self._data[i]
            local j = i - 1

            while j >= left and cmp(key, self._data[j]) do
                self._data[j + 1] = self._data[j]
                j = j - 1
            end

            self._data[j + 1] = key
        end
    end

    local function heapify(n, i, offset)
        local largest = i
        local l = 2 * i + 1 - offset
        local r = l + 1

        if l <= n and cmp(self._data[largest], self._data[l]) then
            largest = l
        end

        if r <= n and cmp(self._data[largest], self._data[r]) then
            largest = r
        end

        if largest ~= i then
            self._data[i], self._data[largest] =
                self._data[largest], self._data[i]

            heapify(n, largest, offset)
        end
    end

    local function heap_sort(left, right)
        local n = right

        for i = math.floor(n / 2), left, -1 do
            heapify(right, i, left)
        end

        for i = right, left + 1, -1 do
            self._data[left], self._data[i] =
                self._data[i], self._data[left]

            heapify(i - 1, left, left)
        end
    end

    local function partition(left, right)
        local pivot = self._data[math.floor((left + right) / 2)]

        local i = left
        local j = right

        while i <= j do
            while cmp(self._data[i], pivot) do
                i = i + 1
            end

            while cmp(pivot, self._data[j]) do
                j = j - 1
            end

            if i <= j then
                self._data[i], self._data[j] =
                    self._data[j], self._data[i]

                i = i + 1
                j = j - 1
            end
        end

        return i, j
    end

    local function introsort(left, right, depth_limit)
        while right - left > threshold do
            if depth_limit == 0 then
                heap_sort(left, right)
                return
            end

            local i, j = partition(left, right)

            depth_limit = depth_limit - 1

            if j - left < right - i then
                if left < j then
                    introsort(left, j, depth_limit)
                end
                left = i
            else
                if i < right then
                    introsort(i, right, depth_limit)
                end
                right = j
            end
        end

        insertion_sort(left, right)
    end

    local n = self._size

    if n > 1 then
        local depth_limit = math.floor(2 * math.log(n + 1, 2))
        introsort(0, n - 1, depth_limit)
    end
end

---@param value T
---@return boolean
function list:contains(value)
    for i = 0, self._size - 1 do
        if self._data[i] == value then
            return true
        end
    end
    return false
end

---@param value T
---@return number
function list:count(value)
    local c = 0
    for i = 0, self._size - 1 do
        if self._data[i] == value then
            c = c + 1
        end
    end
    return c
end

---@param value T
---@return number|nil
function list:index(value)
    for i = 0, self._size - 1 do
        if self._data[i] == value then
            return i
        end
    end
    error("ValueError: " .. tostring(value) .. " is not in list")
end

---@param value T
---@return list<number>
function list:index_all(value)
    local result = list.new()
    for i = 0, self._size - 1 do
        if self._data[i] == value then
            result:append(i)
        end
    end
    if result:len() == 0 then
        error("ValueError: " .. tostring(value) .. " is not in list")
    end
    return result
end

---@param other list<T>
function list:__eq(other)
    if getmetatable(other) ~= list then
        return false
    end

    if self._size ~= other._size then
        return false
    end

    for i = 0, self._size - 1 do
        if self._data[i] ~= other._data[i] then
            return false
        end
    end

    return true
end

---@return string
function list:__tostring()
    local parts = {}
    for i = 0, self._size - 1 do
        parts[i + 1] = tostring(self._data[i])
    end
    return "[" .. table.concat(parts, ", ") .. "]"
end

---@class List
local List = {}

---@generic T
---@param obj? list<T> | nil | table | fun(): T
---@return list<T>
function List.list(obj)
    if obj == nil then
        return list.new()
    end

    if getmetatable(obj) == list then
        return obj:copy()
    end

    local t = {}

    if type(obj) == "table" then
        local i = 1
        for _, v in ipairs(obj) do
            t[i] = v
            i = i + 1
        end
    elseif type(obj) == "function" then
        local i = 1
        for v in obj do
            t[i] = v
            i = i + 1
        end
    else
        error("TypeError: Rkr.list() expects table, iterable, or List")
    end

    return list.new(t)
end

RkrModdingExtensions.make_callable(List, list.new)
---@overload fun<T>(t: T[]?): list<T>
Rkr.List = List
Rkr.list = List.list
