local Test
if Test == nil then Test = {} end

---@class TestRuntime
---@field logger logger
---@field current_suite string|nil
---@field suite_stack table
---@field total number
---@field failed number
---@field before_hooks table<string, fun()>
---@field after_hooks table<string, fun()>
---@field soft_failures table
local TestRuntime = {}
TestRuntime.__index = TestRuntime

function TestRuntime.new(logger)
    return setmetatable({
        logger = logger:with_context("Test"),
        current_suite = nil,
        suite_stack = {},
        total = 0,
        failed = 0,
        before_hooks = {},
        after_hooks = {},
        soft_failures = {},
    }, TestRuntime)
end

local active_runtime = nil

function Test.use_instance(runtime)
    active_runtime = runtime
end

function Test.current()
    if not active_runtime then
        error("Test framework not initialized. Call Test.initialize(logger)", 2)
    end
    return active_runtime
end

---@param mod_name string
function Test.initialise(mod_name)
    local logger = Rkr.Logger(mod_name, "INFO", true)
    local runtime = TestRuntime.new(logger)
    Test.use_instance(runtime)
end

local function extract_error_name(err)
    local s = tostring(err)
    return s:match(":%d+:%s*([%w_]+):")
        or s:match("([%w_]+):")
        or "UnknownError"
end

local function stringify(v)
    if type(v) == "table" then
        return "<table>"
    end
    return tostring(v)
end

local function deep_equal(a, b, visited)
    if a == b then return true end
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return false end

    visited = visited or {}
    if visited[a] and visited[a] == b then return true end
    visited[a] = b

    for k, v in pairs(a) do
        if not deep_equal(v, b[k], visited) then
            return false
        end
    end

    for k in pairs(b) do
        if a[k] == nil then return false end
    end

    return true
end

local function get_logger()
    local self = Test.current()
    return self.logger
end

function Test.print_failure(full_name, err)
    local s = tostring(err)

    local location, message = s:match("^(.+:%d+):%s*(.+)$")

    if location and message then
        local title, detail = message:match("^(.-)%s*::%s*(.+)$")

        if title and detail then
            get_logger():error("FAIL: %s :: %s", full_name, detail)
            get_logger():error("    %s: %s", location, title)
        else
            get_logger():error("FAIL: %s", full_name)
            get_logger():error("    %s: %s", location, message)
        end
    else
        get_logger():error("FAIL: %s", full_name)
        get_logger():error("    %s", s)
    end
end

function describe(name, fn)
    local self = Test.current()

    table.insert(self.suite_stack, name)

    local previous_suite = self.current_suite
    self.current_suite = table.concat(self.suite_stack, "::")

    fn()

    self.current_suite = previous_suite
    table.remove(self.suite_stack)
end

---@param suite_name string|nil
---@param hook_table table
local function resolve_hook(suite_name, hook_table)
    if not suite_name then return nil end

    local parts = {}
    for part in string.gmatch(suite_name, "[^:]+") do
        table.insert(parts, part)
    end

    while #parts > 0 do
        local path = table.concat(parts, "::")

        if hook_table[path] then
            return hook_table[path]
        end

        table.remove(parts)
    end

    return nil
end

function before_each(fn)
    local self = Test.current()

    if self.current_suite then
        self.before_hooks[self.current_suite] = fn
    end
end

function after_each(fn)
    local self = Test.current()

    if self.current_suite then
        self.after_hooks[self.current_suite] = fn
    end
end

function it(name, fn)
    local self = Test.current()

    self.total = self.total + 1

    local full_name = self.current_suite and
        (self.current_suite .. " :: " .. name) or name

    local before = resolve_hook(self.current_suite, self.before_hooks)
    local after = resolve_hook(self.current_suite, self.after_hooks)

    local ok, err = pcall(function()
        if before then before() end

        fn()

        if after then after() end

        if #self.soft_failures > 0 then
            local msg = table.concat(self.soft_failures, "\n")
            self.soft_failures = {}
            error("Soft assertion failures:\n" .. msg, 2)
        end
    end)

    if ok then
        get_logger():info("PASS: %s", full_name)
    else
        self.failed = self.failed + 1
        Test.print_failure(full_name, err)
    end
end

function Test.summary()
    local self = Test.current()

    if self.failed == 0 then
        get_logger():info("ALL TESTS PASSED (%d)", self.total)
    else
        get_logger():error("%d/%d TESTS FAILED", self.failed, self.total)
    end
end

---@class ExpectContext
---@field actual any
---@field negate boolean
---@field test_name string|nil
---@field api table
local function build_expect(context)
    local function fail(msg)
        error((context.test_name or "Expectation failed") .. " :: " .. msg, 3)
    end

    local function check(condition, msg)
        if context.negate then
            if condition then fail("not " .. msg) end
        else
            if not condition then fail(msg) end
        end
        return context.api
    end

    local function evaluate_context()
        local actual = context.actual
        if type(actual) == "function" then
            return actual()
        end
        return actual
    end

    local api = {}
    context.api = api

    function api.equals(expected)
        local actual = evaluate_context()
        context.test_name = context.test_name or
            ("expect_it(" .. stringify(actual) .. ") == " .. stringify(expected))

        return check(actual == expected,
            "Expected " .. stringify(expected) ..
            " but got " .. stringify(actual))
    end

    --TODO figure out why deep_equals isn't working with tables
    function api.deep_equals(expected)
        context.test_name = context.test_name or "deep equality"
        local actual = evaluate_context()

        local ok = false
        if getmetatable(actual)
            and actual.__eq then
            ok = (actual == expected)
        else
            ok = deep_equal(actual, expected)
        end

        return check(ok, string.format("expected: %s | got: %s", expected, actual))
    end

    function api.is_type(t)
        context.test_name = context.test_name or ("type == " .. t)
        local actual = evaluate_context()
        return check(type(actual) == t,
            "Expected type " .. t .. " but got " .. type(actual))
    end

    function api.has_length(len)
        context.test_name = context.test_name or ("length == " .. len)
        local actual = evaluate_context()
        return check(#actual == len,
            "Expected length " .. len .. " but got " .. tostring(#actual))
    end

    function api.contains(value)
        context.test_name = context.test_name or ("contains " .. stringify(value))
        local actual = evaluate_context()

        local found = false
        if getmetatable(actual)
            and actual.contains then
            found = actual:contains(value)
        elseif type(actual) == "table" then
            for _, v in pairs(actual) do
                if v == value then
                    found = true
                    break
                end
            end
        elseif type(actual) == "string" then
            found = actual:find(value, 1, true) ~= nil
        end

        return check(found,
            "Expected to contain " .. stringify(value))
    end

    function api.matches(pattern)
        context.test_name = context.test_name or ("match " .. pattern)
        local actual = evaluate_context()
        return check(type(actual) == "string" and actual:match(pattern),
            "Expected match " .. pattern)
    end

    function api.errors(expected)
        if type(context.actual) ~= "function" then
            fail("errors requires function")
        end

        local ok, err = pcall(context.actual)

        if ok then
            fail("Expected error but none occurred")
        end

        local name = extract_error_name(err)

        context.test_name = context.test_name or "errors"

        if expected then
            return check(name == expected,
                "Expected error " .. expected .. " but got " .. name)
        end

        return context.api
    end

    api.and_it = api

    api.to_not = setmetatable({}, {
        __index = function(_, key)
            local function proxy_call(...)
                local neg_expect = build_expect {
                    actual = context.actual,
                    negate = not context.negate,
                    test_name = context.test_name
                }

                local matcher = neg_expect[key]

                if type(matcher) == "function" then
                    return matcher(...)
                else
                    return matcher
                end
            end

            return proxy_call
        end,

        __call = function(_, ...)
            local neg_expect = build_expect {
                actual = context.actual,
                negate = not context.negate,
                test_name = context.test_name
            }

            if type(neg_expect) == "function" then
                return neg_expect(...)
            end

            return neg_expect
        end
    })

    return api
end

function expect_it(value)
    return build_expect {
        actual = value,
        negate = false,
        test_name = nil
    }
end

function expect_call(obj, method, ...)
    local args = { ... }

    return expect_it(function()
        return obj[method](obj, table.unpack(args))
    end)
end

function expect_index(obj, key)
    return expect_it(function()
        return obj[key]
    end)
end

function expect_assign(obj, key, value)
    return expect_it(function()
        obj[key] = value
        return obj --get mutated object for comparion
    end)
end

function Test.soft()
    local context = {
        failures = {}
    }

    local function record_failure(msg)
        table.insert(context.failures, msg)
    end

    local api = {}

    function api.expect(value)
        return setmetatable({
            value = value
        }, {
            __index = function(tbl, key)
                local matcher = expect_it(tbl.value)[key]

                if type(matcher) == "function" then
                    return function(...)
                        local ok, err = pcall(function(...)
                            matcher(...)
                        end)

                        if not ok then
                            record_failure(err)
                        end

                        return api
                    end
                end

                return matcher
            end
        })
    end

    function api.assert_all()
        if #context.failures > 0 then
            error(
                "Soft assertion failures:\n" ..
                table.concat(context.failures, "\n"),
                2
            )
        end
    end

    return api
end

Rkr.Test = Test
