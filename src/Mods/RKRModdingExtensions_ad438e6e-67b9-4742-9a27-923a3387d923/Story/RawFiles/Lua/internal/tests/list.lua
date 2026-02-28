local List = Rkr.List

local t = { 10, 20, 20, 40, 25 }

---@type list<integer>
local l

describe("List", function()
    before_each(function() l = List(t) end)

    ------------------------------------------------------------------
    -- Construction
    ------------------------------------------------------------------

    describe("construct", function()
        it("creates empty list", function()
            expect(List()).deep_equals(List.new())
                .and_it.deep_equals(List({}))
                .and_it.deep_equals(List.new({}))
        end)

        it("creates list from table", function()
            expect(l).deep_equals(List.new(t))
                .and_it.deep_equals(List(t))
        end)

        it("creates list from iterator", function()
            expect(l).deep_equals(List(l()))
                .and_it.deep_equals(List.new(l()))
                .and_it.deep_equals(List(l:values()))
                .and_it.deep_equals(List.new(l:values()))
        end)
    end)

    ------------------------------------------------------------------
    -- Indexing & Assignment
    ------------------------------------------------------------------

    describe("index access", function()
        it("returns value at index 0", function()
            expect(l[0]).equals(10)
        end)

        it("supports negative indexing", function()
            expect(l[-1]).equals(25)
        end)

        it("supports slice indexing", function()
            expect(l[{ -1 }]).equals(List({ 25 }))
        end)

        it("l[i] equals internal sequence position", function()
            for i = 0, #l - 1 do
                expect(l[i]).equals(l:values()[i + 1])
            end
        end)

        it("throws IndexError when out of bounds", function()
            expect_index(l, 99).errors("IndexError")
        end)

        it("throws error for invalid index type", function()
            expect_index(l, "test").errors("NameError")
            expect_index(l, 4.5).errors("TypeError")
        end)

        it("throws error for invalid slice descriptor", function()
            expect_index(l, { "test" }).errors("NameError")
            expect_index(l, { nil, "test" }).errors("NameError")
            expect_index(l, { nil, nil, "test" }).errors("TypeError")
            expect_index(l, { 4.5 }).errors("TypeError")
            expect_index(l, { nil, 4.5 }).errors("TypeError")
            expect_index(l, { nil, nil, 4.5 }).errors("TypeError")
        end)
    end)

    describe("assign", function()
        before_each(function() l = List(t) end)

        it("assigns value at index", function()
            expect_assign(l, 1, 99).deep_equals(List({ 10, 99, 20, 40, 25 }))
        end)

        it("appends when assigning at length", function()
            expect_assign(l, 5, 99).deep_equals(List({ 10, 20, 20, 40, 25, 99 }))
        end)

        it("throws IndexError when out of bounds", function()
            expect_assign(l, 10, 5).errors("IndexError")
        end)

        it("throws error for invalid index type", function()
            expect_assign(l, 10.72, 5).errors("TypeError")
            expect_assign(l, "test", 5).errors("NameError")
        end)
    end)

    ------------------------------------------------------------------
    -- Length Queries
    ------------------------------------------------------------------

    describe("length", function()
        it("returns correct length using # operator", function()
            expect(l).has_length(5)
        end)

        it("returns correct length using len()", function()
            expect(l:len()).equals(5)
        end)

        it("empty list is zero", function()
            expect(List()).has_length(0)
        end)
    end)

    ------------------------------------------------------------------
    -- Mutation Operations
    ------------------------------------------------------------------

    describe("append", function()
        it("adds value to end of list", function()
            l:append(4)
            expect(l).deep_equals(List({ 10, 20, 20, 40, 25, 4 }))
        end)

        it("multiple appends preserve order", function()
            l:append(100)
            l:append(200)

            expect(l).deep_equals(List({ 10, 20, 20, 40, 25, 100, 200 }))
        end)
    end)

    describe("insert", function()
        before_each(function() l = List(t) end)

        it("inserts value at given index", function()
            l:insert(1, 4)
            expect(l).deep_equals(List({ 10, 4, 20, 20, 40, 25 }))
        end)

        it("appends when index is greater than length", function()
            l:insert(100, 4)
            expect(l).deep_equals(List({ 10, 20, 20, 40, 25, 4 }))
        end)
    end)

    describe("pop", function()
        before_each(function() l = List(t) end)

        it("removes and returns last element when no index given", function()
            expect(l:pop()).equals(25)
            expect(l).deep_equals(List({ 10, 20, 20, 40 }))
        end)

        it("removes and returns element at given index", function()
            expect(l:pop(0)).equals(10)
            expect(l).deep_equals(List({ 20, 20, 40, 25 }))
        end)

        it("throws IndexError when index out of bounds", function()
            expect(function() l:pop(99) end).errors("IndexError")
            expect(l).deep_equals(List(t))
        end)

        it("throws IndexError when list is empty", function()
            l = List()
            expect(function() l:pop() end).errors("IndexError")
            expect(l).deep_equals(List())
        end)
    end)

    describe("clear", function()
        it("removes all elements", function()
            l:clear()
            expect(l).deep_equals(List())
        end)
    end)

    describe("reverse", function()
        it("reverses list in place", function()
            l:reverse()
            expect(l).deep_equals(List({ 25, 40, 20, 20, 10 }))
        end)
    end)

    describe("sort", function()
        it("sorts list in ascending order by default", function()
            l:sort()
            expect(l).deep_equals(List({ 10, 20, 20, 25, 40 }))
        end)

        it("sorts using custom descending comparator", function()
            l:sort(function(a, b) return a > b end)
            expect(l).deep_equals(List({ 40, 25, 20, 20, 10 }))
        end)

        it("sorts using custom comparator with derived value", function()
            local nums = List({ -10, 5, -3, 2 })
            nums:sort(function(a, b) return math.abs(a) < math.abs(b) end)
            expect(nums).deep_equals(List({ 2, -3, 5, -10 }))
        end)

        it("sorts strings alphabetically", function()
            local strs = List({ "banana", "apple", "cherry" })
            strs:sort()
            expect(strs).deep_equals(List({ "apple", "banana", "cherry" }))
        end)

        it("does not error on empty list", function()
            local empty = List()
            empty:sort()
            expect(empty).deep_equals(List())
        end)

        it("throws error if comparator is not a function", function()
            ---@diagnostic disable-next-line: param-type-mismatch
            expect(function() l:sort(123) end).errors("TypeError")
        end)
    end)

    ------------------------------------------------------------------
    -- Query Operations
    ------------------------------------------------------------------

    describe("contains", function()
        it("returns true when value exists", function()
            expect(l).contains(20)
            expect(l:contains(20)).equals(true)
        end)

        it("returns false when value does not exist", function()
            expect(l).to_not.contains(7)
            expect(l:contains(7)).equals(false)
        end)

        it("returns false on empty list", function()
            expect(List()).to_not.contains(10)
            expect(List():contains(10)).equals(false)
        end)
    end)

    describe("count", function()
        it("returns 1 when value appears once", function()
            expect(l:count(10)).equals(1)
        end)

        it("returns 0 when value does not exist", function()
            expect(l:count(30)).equals(0)
        end)

        it("returns correct count for duplicate values", function()
            expect(l:count(20)).equals(2)
        end)
    end)

    describe("index search", function()
        it("returns index of existing value", function()
            expect(l:index(40)).equals(3)
        end)

        it("returns first index when duplicates exist", function()
            expect(l:index(20)).equals(1)
        end)

        it("throws ValueError when value not found", function()
            expect(function() l:index(9) end).errors("ValueError")
        end)
    end)

    ------------------------------------------------------------------
    -- Sequence Transformations
    ------------------------------------------------------------------

    describe("slice", function()
        it("returns sublist between indices", function()
            expect(l:slice(1, 4)).deep_equals(List({ 20, 20, 40 }))
            expect(l[{ 1, 4 }]).deep_equals(List({ 20, 20, 40 }))
        end)

        it("supports negative indices", function()
            expect(l:slice(-4, -1)).deep_equals(List({ 20, 20, 40 }))
            expect(l[{ -4, -1 }]).deep_equals(List({ 20, 20, 40 }))
        end)

        it("supports step parameter", function()
            expect(l:slice(nil, nil, 2)).deep_equals(List({ 10, 20, 25 }))
            expect(l[{ nil, nil, 2 }]).deep_equals(List({ 10, 20, 25 }))
        end)

        it("supports reverse slicing", function()
            expect(l:slice(nil, nil, -1)).deep_equals(List({ 25, 40, 20, 20, 10 }))
            expect(l[{ nil, nil, -1 }]).deep_equals(List({ 25, 40, 20, 20, 10 }))
        end)

        it("clamps out-of-bounds indices", function()
            expect(l:slice(-999, 999)).deep_equals(l)
            expect(l[{ -999, 999 }]).deep_equals(l)
        end)

        it("throws ValueError when step is zero", function()
            expect(function() l:slice(nil, nil, 0) end).errors("ValueError")
            expect(function() return l[{ nil, nil, 0 }] end).errors("ValueError")
        end)

        it("slice with extremely large bounds", function()
            expect(l:slice(-1e9, 1e9)).deep_equals(l)
            expect(l[{ -1e9, 1e9 }]).deep_equals(l)
        end)

        it("slice with nil parameters", function()
            expect(l:slice()).deep_equals(l)
            expect(l[{}]).deep_equals(l)
        end)
    end)

    describe("slice composability", function()
        it("slicing a slice preserves semantics", function()
            local s1 = l:slice(1, 4)
            local s2 = s1:slice(0, #s1)
            expect(s2).deep_equals(s1)
            s1 = l[{ 1, 4 }]
            s2 = s1[{ 0, #s1 }]
            expect(s2).deep_equals(s1)
        end)

        it("reverse slice of slice works", function()
            local s = l:slice(nil, nil, -1)
            local s2 = s:slice(nil, nil, -1)
            expect(s2).deep_equals(l)
            s = l[{ nil, nil, -1 }]
            s2 = s[{ nil, nil, -1 }]
            expect(s2).deep_equals(l)
        end)
    end)

    ------------------------------------------------------------------
    -- Iteration Behavior
    ------------------------------------------------------------------

    describe("iteration", function()
        it("iter returns index, value pairs", function()
            local i_l = List()
            local v_l = List()
            for i, v in pairs(l) do
                i_l:append(i)
                v_l:append(v)
            end
            expect(i_l).deep_equals(List({ 0, 1, 2, 3, 4 }))
            expect(v_l).deep_equals(List(t))
        end)

        it("items returns an iterator on tuple of index, value pairs", function()
            expect(List(l:items())).deep_equals(List({
                List({ 0, 10 }),
                List({ 1, 20 }),
                List({ 2, 20 }),
                List({ 3, 40 }),
                List({ 4, 25 })
            }))
        end)

        it("values returns all values", function()
            expect(List(l:values())).deep_equals(List(t))
        end)

        it("callable list returns values", function()
            expect(List(l())).deep_equals(List(t))
        end)

        it("iterator can be consumed fully", function()
            local values = {}
            for v in l:values() do table.insert(values, v) end
            expect(List(values)).deep_equals(List(t))
        end)
    end)

    describe("iterator exhaustion", function()
        it("values iterator exhausts cleanly", function()
            local iter = l:values()

            local collected = {}
            for v in iter do
                table.insert(collected, v)
            end

            expect(List(collected)).deep_equals(l)
        end)

        it("iterator can be partially consumed", function()
            local iter = l:values()

            local first = iter()
            local second = iter()

            expect(first).equals(10)
            expect(second).equals(20)
        end)
    end)

    ------------------------------------------------------------------
    -- Representation & Copying
    ------------------------------------------------------------------

    describe("copy", function()
        it("returns a new independent copy", function()
            local new = l:copy()
            expect(new).deep_equals(List(t))
            expect(rawequal(new, l)).equals(false)
        end)

        it("mutations do not affect original after copy", function()
            local new = l:copy()
            new:append(999)
            expect(l).to_not.contains(999)
            expect(new).contains(999)
        end)
    end)

    describe("tostring", function()
        it("returns formatted string representation", function()
            expect(tostring(l)).equals("[10, 20, 20, 40, 25]")
        end)

        it("returns [] for empty list", function()
            expect(tostring(List())).equals("[]")
        end)
    end)

    ------------------------------------------------------------------
    -- Algebraic / Structural Properties
    ------------------------------------------------------------------

    describe("equality symmetry", function()
        it("equality is symmetric", function()
            local a = List(t)
            local b = List(t)

            expect(a).deep_equals(b)
            expect(b).deep_equals(a)
        end)
    end)

    describe("sorting invariants", function()
        it("sorting preserves multiset membership", function()
            local before = l:copy()

            l:sort()

            for v in before:values() do
                expect(l:count(v)).equals(before:count(v))
            end
        end)
    end)

    ------------------------------------------------------------------
    -- Stress Mutation Path
    ------------------------------------------------------------------

    describe("stress mutation path", function()
        it("mixed mutation sequence is stable", function()
            local copy = l:copy()

            copy:append(1)
            copy:insert(0, 2)
            copy:pop()
            copy:reverse()
            copy:sort()
            expect(copy).has_length(#l + 1)
                .and_it.deep_equals(List({ 2, 10, 20, 20, 25, 40 }))
        end)
    end)

    ------------------------------------------------------------------
    -- Heterogeneous Lists
    ------------------------------------------------------------------

    describe("heterogeneous lists", function()
        it("supports mixed value types", function()
            local mixed = List({ 1, "a", true, 4, { 1, 4 } })
            expect(#mixed).equals(5)
        end)
    end)
end)
