---@return nil
local function make_error(name)
    return function(msg, ...)
        if msg ~= nil then
            msg = (select('#', ...) > 0) and string.format(msg, ...) or tostring(msg)
            error(string.format("%s: %s", name, msg), 3)
        end
        error(name, 3)
    end
end

Rkr.Error.Type           = make_error("TypeError")
Rkr.Error.Index          = make_error("IndexError")
Rkr.Error.Name           = make_error("NameError")
Rkr.Error.Key            = make_error("KeyError")
Rkr.Error.Value          = make_error("ValueError")
Rkr.Error.Runtime        = make_error("RuntimeError")
Rkr.Error.NotImplemented = make_error("NotImplementedError")
