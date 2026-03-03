local Tuple = Rkr.Tuple
local List = Rkr.List

local t = { 10, 20, 20, 40, 25 }

---@type tuple<integer>
local tup

describe("Tuple", function()
    before_each(function()
        tup = Tuple(t)
    end)

    ------------------------------------------------------------------
    -- Construction
    ------------------------------------------------------------------

    describe("construct", function()
        it("creates empty tuple", function()
            expect(Tuple()).deep_equals(Tuple.new())
                .and_it.deep_equals(Tuple({}))
                .and_it.deep_equals(Tuple.new({}))
        end)

        it("creates tuple from table", function()
            expect(tup).deep_equals(Tuple.new(t))
                .and_it.deep_equals(Tuple(t))
        end)

        it("creates tuple from iterator", function()
            expect(tup).deep_equals(Tuple(tup()))
                .and_it.deep_equals(Tuple.new(tup()))
        end)

        it("creates tuple from list", function()
            expect(tup).deep_equals(Tuple(List(t)))
        end)

        it("creates tuple from unpacked args", function()
            expect(tup).deep_equals(Tuple(10, 20, 20, 40, 25))
            expect(tup).deep_equals(Tuple.new(10, 20, 20, 40, 25))
        end)
    end)

    ------------------------------------------------------------------
    -- Indexing
    ------------------------------------------------------------------

    describe("index access", function()
        it("returns value at index 0", function()
            expect(tup[0]).equals(10)
        end)

        it("supports negative indexing", function()
            expect(tup[-1]).equals(25)
        end)

        it("supports slice indexing", function()
            expect(tup[{ -1 }]).deep_equals(Tuple({ 25 }))
        end)

        it("throws IndexError when out of bounds", function()
            expect_index(tup, 99).errors("IndexError")
        end)

        it("throws error for invalid index type", function()
            expect_index(tup, "test").errors("NameError")
            expect_index(tup, 4.5).errors("TypeError")
        end)
    end)

    ------------------------------------------------------------------
    -- Length
    ------------------------------------------------------------------

    describe("length", function()
        it("returns correct length", function()
            expect(tup).has_length(5)
        end)

        it("empty tuple length is zero", function()
            expect(Tuple()).has_length(0)
        end)
    end)

    ------------------------------------------------------------------
    -- Immutability
    ------------------------------------------------------------------

    describe("immutability", function()
        it("cannot assign index", function()
            expect(function() tup[0] = 99 end).errors("TypeError")
        end)

        it("has no mutation methods", function()
            expect(function() tup:append(1) end).errors("TypeError")
            expect(function() tup:insert(0, 1) end).errors("TypeError")
            expect(function() tup:pop() end).errors("TypeError")
            expect(function() tup:remove(10) end).errors("TypeError")
            expect(function() tup:clear() end).errors("TypeError")
        end)
    end)

    ------------------------------------------------------------------
    -- Equality
    ------------------------------------------------------------------

    describe("equality", function()
        it("tuples with same values are equal", function()
            expect(Tuple(t)).deep_equals(Tuple(t))
                .and_it.equals(Tuple(t))
            expect(tup == Tuple(t)).equals(true)
        end)

        it("tuples with different values are not equal", function()
            expect(Tuple(1, 2)).to_not.deep_equals(Tuple(2, 1))
        end)

        it("tuple != list even with same values", function()
            expect(Tuple(t)).to_not.deep_equals(List(t))
        end)

        it("equality is symmetric", function()
            local a = Tuple(t)
            local b = Tuple(t)
            expect(a).deep_equals(b)
            expect(b).deep_equals(a)
        end)
    end)

    ------------------------------------------------------------------
    -- Hashing
    ------------------------------------------------------------------

    describe("hash", function()
        it("equal tuples have equal hash", function()
            local a = Tuple(t)
            local b = Tuple(t)
            expect(a:__hash()).equals(b:__hash())
        end)

        it("hash is cached", function()
            local h1 = tup:__hash()
            local h2 = tup:__hash()
            expect(h1).equals(h2)
        end)

        it("different tuples likely have different hash", function()
            local a = Tuple(1, 2, 3)
            local b = Tuple(3, 2, 1)
            expect(a:__hash()).to_not.equals(b:__hash())
        end)

        it("nested tuples hash structurally", function()
            local a = Tuple(Tuple(1, 2), 3)
            local b = Tuple(Tuple(1, 2), 3)
            expect(a:__hash()).equals(b:__hash())
        end)
    end)

    ------------------------------------------------------------------
    -- Slice
    ------------------------------------------------------------------

    describe("slice", function()
        it("returns tuple from slice", function()
            expect(tup:slice(1, 4)).deep_equals(Tuple({ 20, 20, 40 }))
            expect(tup[{ 1, 4 }]).deep_equals(Tuple({ 20, 20, 40 }))
        end)

        it("supports negative slicing", function()
            expect(tup:slice(-4, -1)).deep_equals(Tuple({ 20, 20, 40 }))
        end)

        it("supports step", function()
            expect(tup:slice(nil, nil, 2)).deep_equals(Tuple({ 10, 20, 25 }))
        end)

        it("reverse slice works", function()
            expect(tup:slice(nil, nil, -1))
                .deep_equals(Tuple({ 25, 40, 20, 20, 10 }))
        end)

        it("step zero throws", function()
            expect(function() tup:slice(nil, nil, 0) end).errors("ValueError")
        end)
    end)

    ------------------------------------------------------------------
    -- Iteration
    ------------------------------------------------------------------

    describe("iteration", function()
        it("enumerate works", function()
            local indices = List()
            local values  = List()

            for i, v in tup:enumerate() do
                indices:append(i)
                values:append(v)
            end

            expect(indices).deep_equals(List({ 0, 1, 2, 3, 4 }))
            expect(values).deep_equals(List(t))
        end)
        it("enumerate can unpack sequence values", function()
            local new_t = Tuple(Tuple(1, 2, 3), Tuple(3, 4, 5), Tuple(5, 6, 7))
            local i_l = List()
            local x_l = List()
            local y_l = List()
            local z_l = List()
            local x, y, z
            for i, v in new_t:enumerate() do
                x, y, z = v:unpack()
                i_l:append(i)
                x_l:append(x)
                y_l:append(y)
                z_l:append(z)
            end
            expect(i_l).deep_equals(List(0, 1, 2))
            expect(x_l).deep_equals(List(1, 3, 5))
            expect(y_l).deep_equals(List(2, 4, 6))
            expect(z_l).deep_equals(List(3, 5, 7))
        end)
        it("pairs works", function()
            local count = 0
            for _ in pairs(tup) do
                count = count + 1
            end
            expect(count).equals(#tup)
        end)

        it("callable tuple returns iterator", function()
            expect(Tuple(tup())).deep_equals(tup)
        end)
    end)

    ------------------------------------------------------------------
    -- Copy
    ------------------------------------------------------------------

    describe("copy", function()
        it("returns new independent tuple", function()
            local new = tup:copy()
            expect(new).deep_equals(tup)
            expect(rawequal(new, tup)).equals(false)
        end)
    end)

    ------------------------------------------------------------------
    -- Representation
    ------------------------------------------------------------------

    describe("tostring", function()
        it("formats multi-element tuple", function()
            expect(tostring(tup))
                .equals("(10, 20, 20, 40, 25)")
        end)

        it("formats single-element tuple correctly", function()
            expect(tostring(Tuple(1))).equals("(1,)")
        end)

        it("formats empty tuple", function()
            expect(tostring(Tuple())).equals("()")
        end)
    end)

    ------------------------------------------------------------------
    -- Algebraic / Structural Properties
    ------------------------------------------------------------------

    describe("structural invariants", function()
        it("slice of slice preserves semantics", function()
            local s1 = tup:slice(1, 4)
            local s2 = s1:slice(0, #s1)
            expect(s2).deep_equals(s1)
        end)

        it("reverse twice equals original", function()
            local r = tup:slice(nil, nil, -1)
            local rr = r:slice(nil, nil, -1)
            expect(rr).deep_equals(tup)
        end)
    end)

    ------------------------------------------------------------------
    -- Heterogeneous Tuples
    ------------------------------------------------------------------

    describe("heterogeneous tuples", function()
        it("supports mixed types", function()
            local mixed = Tuple(1, "a", true, { 1, 4 })
            expect(#mixed).equals(4)
        end)
    end)
end)
