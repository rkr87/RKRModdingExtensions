local log = RkrModdingExtensions.log:with_context("Test")

Rkr.Test.assert_test = function(test_name, expected, fn, comparator)
    local ok, result = pcall(fn)
    comparator = comparator or function(a, b) return a == b end

    if not ok then
        log:error(
            "FAIL: %s -> ERROR: %s (%s)",
            test_name,
            result,
            test_name
        )
        return
    end

    if comparator(result, expected) then
        log:info("PASS: %s -> %s", test_name, result)
    else
        log:error("FAIL: %s", test_name)
        log:error("   expected: %s", expected)
        log:error("   got     : %s", result)
    end
end

Rkr.Test.assert_error = function(test_name, fn, expected_error)
    local ok, err = pcall(fn)

    if ok then
        log:error(
            "FAIL: %s -> expected error: %s",
            test_name,
            expected_error or "any"
        )
        return
    end

    local err_name = tostring(err):match(":%d+:%s*([%w_]+):") or "UnknownError"
    if expected_error and err_name ~= expected_error then
        log:error("FAIL: %s", test_name)
        log:error("   expected error: %s", expected_error)
        log:error("   got error     : %s", err_name)
        return
    end

    log:info(
        "PASS: %s -> %s",
        test_name,
        err_name
    )
end
