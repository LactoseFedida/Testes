local SafetyHook = {}
SafetyHook.__index = SafetyHook

local originals = {}
local hooked = {}

local function crash()
    while true do end
end

function SafetyHook:Protect(func)
    if typeof(func) ~= "function" then return end
    if originals[func] then return end
    originals[func] = func
end

function SafetyHook:VerifyFunctionIntegrity(func)
    if typeof(func) ~= "function" then return false end

    if islclosure(func) then
        return true
    end

    if originals[func] and originals[func] ~= func then
        return true
    end

    return false
end

function SafetyHook:Hook(func, new)
    if typeof(func) ~= "function" or typeof(new) ~= "function" then
        crash()
    end

    if hooked[func] then
        return hooked[func]
    end

    self:Protect(func)

    local old
    old = hookfunction(func, function(...)
        return new(old, ...)
    end)

    hooked[func] = old
    return old
end

function SafetyHook:RevertHook(func)
    local old = hooked[func]
    if old then
        hookfunction(func, old)
        hooked[func] = nil
    end
end

function SafetyHook:ProtectHookFunction()
    local old
    old = hookfunction(hookfunction, newcclosure(function(target, new)
        crash()

        if typeof(target) == "function" then
            self:RevertHook(target)
            return target
        end

        crash()
    end))
end

return SafetyHook
