-- ========================================
-- SafetyLibrary v1.0
-- Sistema Avançado de Proteção contra Hooking
-- Criador: [Seu Nome]
-- ========================================

local SafetyLibrary = {}
SafetyLibrary.__index = SafetyLibrary

-- Variáveis internas
local registeredFunctions = {}
local functionSignatures = {}
local hookedFunctions = {}
local protectionActive = true

-- ========================================
-- INICIALIZAÇÃO
-- ========================================

function SafetyLibrary.new()
    local self = setmetatable({}, SafetyLibrary)
    self.protectedFuncs = {}
    self.originalFuncs = {}
    self.checksums = {}
    
    -- Auto-inicializar proteção
    self:_initializeProtection()
    
    return self
end

-- ========================================
-- CRIAR ASSINATURA/CHECKSUM DA FUNÇÃO
-- ========================================

function SafetyLibrary:_createSignature(func)
    if typeof(func) ~= "function" then
        return nil
    end
    
    local signature = {
        -- Informações básicas
        name = debug.getinfo(func).name or "anonymous",
        source = debug.getinfo(func).source or "unknown",
        linedefined = debug.getinfo(func).linedefined or 0,
        lastlinedefined = debug.getinfo(func).lastlinedefined or 0,
        nups = debug.getinfo(func).nups or 0, -- Número de upvalues
        
        -- Upvalues
        upvalues = {},
        
        -- Constantes (números, strings)
        constants = {},
        
        -- Checksum combinado
        checksum = 0
    }
    
    -- Extrair upvalues
    pcall(function()
        for i = 1, 256 do
            local name, value = debug.getupvalue(func, i)
            if not name then break end
            
            signature.upvalues[i] = {
                name = name,
                type = typeof(value),
                value = tostring(value)
            }
        end
    end)
    
    -- Calcular checksum simples (CRC32-like)
    local checksumString = signature.name .. signature.source .. tostring(signature.nups)
    for i, uv in ipairs(signature.upvalues) do
        checksumString = checksumString .. uv.name .. uv.type
    end
    
    signature.checksum = self:_calculateChecksum(checksumString)
    
    return signature
end

-- ========================================
-- CALCULAR CHECKSUM
-- ========================================

function SafetyLibrary:_calculateChecksum(str)
    local checksum = 0
    for i = 1, #str do
        checksum = (checksum * 31 + string.byte(str, i)) % 2147483647
    end
    return checksum
end

-- ========================================
-- VERIFICAR INTEGRIDADE DA FUNÇÃO
-- ========================================

function SafetyLibrary:VerifyFunctionIntegrity(func)
    if not protectionActive then
        return false
    end
    
    if not self.checksums[func] then
        -- Se não tem assinatura registrada, registrar agora
        self.checksums[func] = self:_createSignature(func)
        return false
    end
    
    local originalSignature = self.checksums[func]
    local currentSignature = self:_createSignature(func)
    
    -- Comparar assinaturas
    local isHooked = false
    
    -- Verificar mudanças básicas
    if currentSignature.checksum ~= originalSignature.checksum then
        isHooked = true
    end
    
    -- Verificar mudanças em upvalues
    if #currentSignature.upvalues ~= #originalSignature.upvalues then
        isHooked = true
    end
    
    -- Verificar cada upvalue
    for i, uv in ipairs(currentSignature.upvalues) do
        if not originalSignature.upvalues[i] then
            isHooked = true
            break
        end
        
        if uv.name ~= originalSignature.upvalues[i].name or
           uv.type ~= originalSignature.upvalues[i].type then
            isHooked = true
            break
        end
    end
    
    return isHooked
end

-- ========================================
-- REMOVER HOOK (REVERT)
-- ========================================

function SafetyLibrary:RevertHook(func)
    if not protectionActive then
        return
    end
    
    if self.originalFuncs[func] then
        -- Se temos a função original armazenada, restaurar
        local original = self.originalFuncs[func]
        
        -- Re-registrar a assinatura
        self.checksums[func] = self:_createSignature(original)
        
        return original
    end
    
    -- Se não temos original, tentar restaurar via debug
    pcall(function()
        local info = debug.getinfo(func)
        
        -- Resetar upvalues para valores originais
        if self.originalUpvalues and self.originalUpvalues[func] then
            for i, originalValue in ipairs(self.originalUpvalues[func]) do
                pcall(function()
                    debug.setupvalue(func, i, originalValue)
                end)
            end
        end
    end)
end

-- ========================================
-- PROTEGER FUNÇÃO ESPECÍFICA
-- ========================================

function SafetyLibrary:ProtectFunction(func, customName)
    if typeof(func) ~= "function" then
        return false
    end
    
    -- Armazenar função original
    self.originalFuncs[func] = func
    
    -- Armazenar upvalues originais
    pcall(function()
        local upvalues = {}
        for i = 1, 256 do
            local name, value = debug.getupvalue(func, i)
            if not name then break end
            upvalues[i] = value
        end
        if not self.originalUpvalues then
            self.originalUpvalues = {}
        end
        self.originalUpvalues[func] = upvalues
    end)
    
    -- Criar assinatura
    self.checksums[func] = self:_createSignature(func)
    
    -- Registrar
    table.insert(self.protectedFuncs, func)
    table.insert(registeredFunctions, {
        func = func,
        name = customName or debug.getinfo(func).name or "anonymous",
        protected = true,
        timestamp = tick()
    })
    
    return true
end

-- ========================================
-- PROTEGER MÚLTIPLAS FUNÇÕES
-- ========================================

function SafetyLibrary:ProtectMultiple(funcTable)
    local successCount = 0
    
    for i, func in ipairs(funcTable) do
        if self:ProtectFunction(func) then
            successCount = successCount + 1
        end
    end
    
    return successCount
end

-- ========================================
-- MONITORAR FUNÇÃO (LOOP CONTÍNUO)
-- ========================================

function SafetyLibrary:MonitorFunction(func, callback)
    if not self.checksums[func] then
        self:ProtectFunction(func)
    end
    
    task.spawn(function()
        while protectionActive do
            if self:VerifyFunctionIntegrity(func) then
                if callback then
                    callback(func)
                end
            end
            wait(0.1) -- Verificar a cada 0.1 segundos
        end
    end)
end

-- ========================================
-- PROTEGER HOOKFUNCTION GLOBAL
-- ========================================

function SafetyLibrary:ProtectHookFunction()
    local originalHookFunction = hookfunction
    
    hookfunction(hookfunction, newcclosure(function(target, replacement)
        -- Verificar se estão tentando hookar função protegida
        if self.protectedFuncs[target] then
            -- Crashear se tentarem hookar
            task.spawn(function()
                error("Tentativa de hooking em função protegida!", 2)
            end)
            
            -- Retornar revert automático
            return self:RevertHook(target)
        end
        
        -- Se não é protegida, permitir (ou bloquear conforme quiser)
        return originalHookFunction(target, replacement)
    end))
end

-- ========================================
-- INICIALIZAR PROTEÇÃO COMPLETA
-- ========================================

function SafetyLibrary:_initializeProtection()
    -- Proteger funções HTTP padrão
    local httpFuncs = {
        http_request,
        (http and http.request),
        request,
        (syn and syn.request),
        (fluxus and fluxus.request)
    }
    
    for _, func in ipairs(httpFuncs) do
        if func then
            pcall(function()
                self:ProtectFunction(func, "HTTP_REQUEST")
            end)
        end
    end
    
    -- Proteger funções de I/O
    local ioFuncs = {
        loadstring,
        (game and game.HttpGet),
        (game and game.HttpPost)
    }
    
    for _, func in ipairs(ioFuncs) do
        if func then
            pcall(function()
                self:ProtectFunction(func, "IO_FUNCTION")
            end)
        end
    end
end

-- ========================================
-- DESATIVAR PROTEÇÃO (EMERGÊNCIA)
-- ========================================

function SafetyLibrary:Disable()
    protectionActive = false
    print("[SafetyLibrary] Proteção desativada!")
end

-- ========================================
-- ATIVAR PROTEÇÃO
-- ========================================

function SafetyLibrary:Enable()
    protectionActive = true
    print("[SafetyLibrary] Proteção ativada!")
end

-- ========================================
-- OBTER STATUS
-- ========================================

function SafetyLibrary:GetStatus()
    return {
        active = protectionActive,
        protectedCount = #self.protectedFuncs,
        registeredCount = #registeredFunctions
    }
end

-- ========================================
-- EXPORTAR A BIBLIOTECA
-- ========================================

return function(key)
    return SafetyLibrary.new(key)
end
