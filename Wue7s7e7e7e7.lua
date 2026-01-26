--// SafetyLibrary - Real Hook Detection

local EXPECTED_KEY = "Luscaa"

return function(key)
    if key ~= EXPECTED_KEY then
        while true do end
    end

    local SL = {}
    local Stored = setmetatable({}, { __mode = "k" })

    local function fingerprint(fn)
        local info = debug.getinfo(fn)
        return table.concat({
            tostring(info.what),
            tostring(info.source),
            tostring(info.linedefined),
            tostring(info.lastlinedefined),
            tostring(iscclosure(fn))
        }, "|")
    end

    -- registra função original
    function SL:RegisterFunction(fn)
        if typeof(fn) ~= "function" then return end
        if Stored[fn] then return end

        Stored[fn] = {
            ref = fn,
            fp = fingerprint(fn),
            up = debug.getupvalues(fn)
        }
    end

    -- verifica se houve hook
    function SL:VerifyFunctionIntegrity(fn)
        if typeof(fn) ~= "function" then return false end

        local data = Stored[fn]
        if not data then
            SL:RegisterFunction(fn)
            return false
        end

        -- fingerprint mudou
        if fingerprint(fn) ~= data.fp then
            return true
        end

        -- upvalues alterados (hook silencioso)
        local ups = debug.getupvalues(fn)
        if #ups ~= #data.up then
            return true
        end

        return false
    end

    -- tenta reverter hook
    function SL:RevertHook(fn)
        local data = Stored[fn]
        if not data then return false end
        if not hookfunction then return false end

        pcall(function()
            hookfunction(fn, data.ref)
        end)

        return true
    end

    return SL
end
