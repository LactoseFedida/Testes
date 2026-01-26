--// Safety Hook Library - Universal
--// No Key Version

local SL = {}
local OriginalFunctions = setmetatable({}, { __mode = "k" })

--// Registra função original
function SL:RegisterFunction(func)
    if typeof(func) ~= "function" then return false end
    if not OriginalFunctions[func] then
        OriginalFunctions[func] = func
    end
    return true
end

--// Verifica se foi hookada
function SL:VerifyFunctionIntegrity(func)
    if typeof(func) ~= "function" then return false end

    local original = OriginalFunctions[func]
    if not original then
        OriginalFunctions[func] = func
        return false
    end

    return original ~= func
end

--// Reverte hook
function SL:RevertHook(func)
    local original = OriginalFunctions[func]
    if original and hookfunction then
        pcall(function()
            hookfunction(func, original)
        end)
        return true
    end
    return false
end

--// Protege função automaticamente
function SL:Protect(func)
    if typeof(func) ~= "function" then return end

    SL:RegisterFunction(func)

    hookfunction(func, newcclosure(function(...)
        if SL:VerifyFunctionIntegrity(func) then
            SL:RevertHook(func)
            while true do end
        end
        return func(...)
    end))
end

return SL
