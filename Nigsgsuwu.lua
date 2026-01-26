local SafetyHook = {}

function SafetyHook:Init(crash, funcs)
    for _, v in pairs(funcs) do
        pcall(function()
            if typeof(v) == "function" then
                local ok = pcall(function()
                    return islclosure(v) == false
                end)
                if ok then
                    task.spawn(crash, "Tentativa de hooking em uma funcao critica")
                    hookfunction(v, v)
                end
            end
        end)
    end

    hookfunction(hookfunction, newcclosure(function(...)
        task.spawn(function()
            crash("Tentativa de usar hookfunction")
        end)
        while true do end
    end))
end

return SafetyHook
