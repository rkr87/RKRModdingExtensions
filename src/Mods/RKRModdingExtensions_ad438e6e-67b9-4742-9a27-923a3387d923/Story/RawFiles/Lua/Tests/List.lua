local List = Rkr.List

local function test_construction()
    Rkr.Test.assert_test(
        "List()",
        List(),
        function() return List() end
    )
end

local function test_indexing()
    local l = List({ 10, 20, 30, 40, 50 })

    Rkr.Test.assert_test(
        "List({10,20,30,40,50})[0]",
        10,
        function() return l[0] end
    )

    Rkr.Test.assert_test(
        "List({10,20,30,40,50})[-1]",
        50,
        function() return l[-1] end
    )

    Rkr.Test.assert_error(
        "List({10,20,30,40,50})[99]",
        function() return l[99] end,
        "IndexError"
    )
end

local function test_assignment()
    local l = List({ 1, 2, 3 })

    l[1] = 99

    Rkr.Test.assert_test(
        "List({1,2,3})[1]=99",
        List({ 1, 99, 3 }),
        function() return l end
    )

    Rkr.Test.assert_error(
        "List({1,2,3})[10]=5",
        function() l[10] = 5 end,
        "IndexError"
    )

    Rkr.Test.assert_error(
        "List({1,2,3})[10.72]=5",
        function() l[10.72] = 5 end,
        "TypeError"
    )

    Rkr.Test.assert_error(
        "List({1,2,3})['test']=5",
        function() l['test'] = 5 end,
        "NameError"
    )
end

local function test_append()
    local l = List({ 1, 2 })

    l:append(3)

    Rkr.Test.assert_test(
        "List({1,2}):append(3)",
        List({ 1, 2, 3 }),
        function() return l end
    )
end

local function test_insert()
    local l = List({ 1, 2, 3 })

    l:insert(1, 99)

    Rkr.Test.assert_test(
        "List({1,2,3}):insert(1,99)",
        List({ 1, 99, 2, 3 }),
        function() return l end
    )

    l = List({ 1, 2, 3 })

    l:insert(100, 5)

    Rkr.Test.assert_test(
        "List({1,2,3}):insert(100,5)",
        List({ 1, 2, 3, 5 }),
        function() return l end
    )
end

local function test_pop()
    local l = List({ 1, 2, 3 })

    Rkr.Test.assert_test(
        "List({1,2,3}):pop()",
        3,
        function() return l:pop() end
    )

    l = List({ 1, 2, 3 })

    Rkr.Test.assert_test(
        "List({1,2,3}):pop(0)",
        1,
        function() return l:pop(0) end
    )

    Rkr.Test.assert_error(
        "List({1,2,3}):pop(99)",
        function() l:pop(99) end,
        "IndexError"
    )

    l = List({})
    Rkr.Test.assert_error(
        "List({}):pop()",
        function() l:pop() end,
        "IndexError"
    )
end

local function test_len()
    local l = List({ 1, 2, 3 })

    Rkr.Test.assert_test(
        "#List({1,2,3})",
        3,
        function() return #l end
    )

    Rkr.Test.assert_test(
        "List({1,2,3}):len()",
        3,
        function() return l:len() end
    )
end

local function test_contains()
    local l = List({ 1, 2, 3 })

    Rkr.Test.assert_test(
        "List({1,2,3}):contains(2)",
        true,
        function() return l:contains(2) end
    )

    Rkr.Test.assert_test(
        "List({1,2,3}):contains(9)",
        false,
        function() return l:contains(9) end
    )
end

local function test_count()
    local l = List({ 1, 2, 2, 3 })

    Rkr.Test.assert_test(
        "List({1,2,2,3}):count(2)",
        2,
        function() return l:count(2) end
    )
end

local function test_index_method()
    local l = List({ 1, 2, 3 })

    Rkr.Test.assert_test(
        "List({1,2,3}):index(2)",
        1,
        function() return l:index(2) end
    )

    Rkr.Test.assert_error(
        "List({1,2,3}):index(9)",
        function() l:index(9) end,
        "ValueError"
    )
end

local function test_slice()
    local l = List({ 1, 2, 3, 4, 5 })

    Rkr.Test.assert_test(
        "List({1,2,3,4,5}):slice(1,4)",
        List({ 2, 3, 4 }),
        function() return l:slice(1, 4) end
    )

    Rkr.Test.assert_test(
        "List({1,2,3,4,5}):slice(-4,-1)",
        List({ 2, 3, 4 }),
        function() return l:slice(-4, -1) end
    )

    Rkr.Test.assert_test(
        "List({1,2,3,4,5}):slice(nil,nil,2)",
        List({ 1, 3, 5 }),
        function() return l:slice(nil, nil, 2) end
    )

    Rkr.Test.assert_test(
        "List({1,2,3,4,5}):slice(nil,nil,-1)",
        List({ 5, 4, 3, 2, 1 }),
        function() return l:slice(nil, nil, -1) end
    )

    Rkr.Test.assert_test(
        "List({1,2,3,4,5}):slice(-999,999)",
        List({ 1, 2, 3, 4, 5 }),
        function() return l:slice(-999, 999) end
    )

    Rkr.Test.assert_error(
        "List({1,2,3,4,5}):slice(nil,nil,0)",
        function() l:slice(nil, nil, 0) end,
        "ValueError"
    )
end

local function test_reverse()
    local l = List({ 1, 2, 3 })
    l:reverse()
    Rkr.Test.assert_test(
        "List({1,2,3}):reverse()",
        List({ 3, 2, 1 }),
        function() return l end
    )
end

local function test_sort()
    local l = List({ 3, 1, 2 })
    l:sort()
    Rkr.Test.assert_test(
        "List({3,1,2}):sort()",
        List({ 1, 2, 3 }),
        function() return l end
    )
end

local function test_copy()
    local l1 = List({ 1, 2, 3 })
    local l2 = l1:copy()

    Rkr.Test.assert_test(
        "List({1,2,3}):copy() == List({1,2,3})",
        List({ 1, 2, 3 }),
        function() return l2 end
    )

    Rkr.Test.assert_test(
        "l=List({1,2,3}); rawequal(l, l:copy()) == false",
        false,
        function() return rawequal(l1, l2) end
    )
end

local function test_clear()
    local l = List({ 1, 2, 3 })

    l:clear()

    Rkr.Test.assert_test(
        "List({1,2,3}):clear()",
        List(),
        function() return l end
    )
end

local function test_iter()
    local l = List({ 10, 20, 30 })
    local collected = List()

    for i, v in l:iter() do
        collected:append(List({ i, v }))
    end

    Rkr.Test.assert_test(
        "List({10,20,30}):iter()",
        List({
            List({ 0, 10 }),
            List({ 1, 20 }),
            List({ 2, 30 })
        }),
        function() return collected end
    )
end

local function test_values()
    local l = List({ 5, 6, 7 })
    local collected = List()

    for v in l:values() do
        collected:append(v)
    end

    Rkr.Test.assert_test(
        "List({5,6,7}):values()",
        List({ 5, 6, 7 }),
        function() return collected end
    )
end

local function test_call()
    local l = List({ 1, 2, 3 })
    local collected = List()

    for v in l() do
        collected:append(v)
    end

    Rkr.Test.assert_test(
        "List({1,2,3})()",
        List({ 1, 2, 3 }),
        function() return collected end
    )
end

local function test_tostring()
    local l = List({ 1, 2, 3 })

    Rkr.Test.assert_test(
        "tostring(List({1,2,3}))",
        "[1, 2, 3]",
        function() return tostring(l) end
    )

    local empty = List()

    Rkr.Test.assert_test(
        "tostring(List())",
        "[]",
        function() return tostring(empty) end
    )
end

local function run_tests()
    test_construction()
    test_indexing()
    test_assignment()
    test_append()
    test_insert()
    test_pop()
    test_len()
    test_contains()
    test_count()
    test_index_method()
    test_slice()
    test_reverse()
    test_sort()
    test_copy()
    test_clear()
    test_iter()
    test_values()
    test_call()
    test_tostring()
end

run_tests()
