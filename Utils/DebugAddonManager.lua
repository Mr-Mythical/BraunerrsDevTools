local _, BDT = ...
local DebugAddonManager = {}
BDT.DebugAddonManager = DebugAddonManager

function DebugAddonManager:Initialize()
    self:CreateDebugUI()
    self.registeredDebugVariables = self.registeredDebugVariables or {}
    -- devModeToggleVariables is now stored in saved variables (BDT.db.devModeToggleVariables)
end

function DebugAddonManager:CreateDebugUI()
    -- Debug UI creation logic (if any) can go here
    -- Slash command is now defined in Core.lua
end

function DebugAddonManager:ListDebugVariables()
    print("BDT: Debug Variables:")

    -- Show registered variables first
    local hasRegistered = false
    if next(self.registeredDebugVariables) ~= nil then
        print("  Registered:")
        for varName, info in pairs(self.registeredDebugVariables) do
            local status = self:IsDebugVariableEnabled(varName) and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"
            local category = info.category and (" [" .. info.category .. "]") or ""
            print("    " .. varName .. category .. " - " .. status .. " - " .. (info.description or "No description"))
            hasRegistered = true
        end
    end

    -- Show dev mode toggle variables
    local hasDevModeToggle = false
    if BDT.db and BDT.db.devModeToggleVariables and next(BDT.db.devModeToggleVariables) ~= nil then
        if hasRegistered then print("") end
        print("  Dev Mode Auto-Toggle:")
        for varName, info in pairs(BDT.db.devModeToggleVariables) do
            local status = self:IsDebugVariableEnabled(varName) and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"
            local category = info.category and (" [" .. info.category .. "]") or ""
            print("    " .. varName .. category .. " - " .. status .. " - " .. (info.description or "No description"))
            hasDevModeToggle = true
        end
    end

    -- Show all global boolean variables that look like debug variables
    local debugVars = self:FindAllDebugVariables()
    if next(debugVars) ~= nil then
        if hasRegistered or hasDevModeToggle then print("") end
        print("  Available (any global boolean variable):")
        for varName, _ in pairs(debugVars) do
            if not self.registeredDebugVariables[varName] and not (BDT.db and BDT.db.devModeToggleVariables and BDT.db.devModeToggleVariables[varName]) then
                local status = self:IsDebugVariableEnabled(varName) and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"
                print("    " .. varName .. " - " .. status)
            end
        end
    end

    if not hasRegistered and not hasDevModeToggle and next(debugVars) == nil then
        print("  No debug variables found")
        print("  Any global boolean variable can be controlled with /bdtdebug enable/disable <variable>")
    end
end

function DebugAddonManager:FindAllDebugVariables()
    local debugVars = {}

    -- Find all global boolean variables
    for varName, value in pairs(_G) do
        if type(value) == "boolean" then
            debugVars[varName] = true
        end
    end

    return debugVars
end

function DebugAddonManager:ShowHelp()
    print("BDT Debug Commands (use /bdt <command>):")
    print("  /bdt list - Show all debug variables (registered and available)")
    print("  /bdt enable - Enable all registered debug variables")
    print("  /bdt disable - Disable all registered debug variables")
    print("  /bdt clear - Clear all registered and dev mode toggle variables")
    print("  /bdt check <variable> - Check if a variable exists and its properties")
    print("  /bdt enable <variable> - Enable any global boolean variable")
    print("  /bdt disable <variable> - Disable any global boolean variable")
    print("  /bdt register <variable> - Register variable for dev mode auto-toggle")
    print("  /bdt unregister <variable> - Unregister from dev mode auto-toggle")
    print("")
    print("You can control ANY global boolean variable, not just registered ones!")
    print("Examples: /bdt enable BugSackDebug, /bdt register WeakAurasDebugLog")
end

function DebugAddonManager:EnableAllDebugModes()
    local count = 0

    -- Enable registered variables
    for varName, info in pairs(self.registeredDebugVariables) do
        if self:EnableDebugVariable(varName) then
            count = count + 1
        end
    end

    -- Enable dev mode toggle variables
    if BDT.db and BDT.db.devModeToggleVariables then
        for varName, info in pairs(BDT.db.devModeToggleVariables) do
            if self:EnableDebugVariable(varName) then
                count = count + 1
            end
        end
    end

    print("BDT: Enabled " .. count .. " debug variables")
end

function DebugAddonManager:DisableAllDebugModes()
    local count = 0

    -- Disable registered variables
    for varName, info in pairs(self.registeredDebugVariables) do
        if self:DisableDebugVariable(varName) then
            count = count + 1
        end
    end

    -- Disable dev mode toggle variables
    if BDT.db and BDT.db.devModeToggleVariables then
        for varName, info in pairs(BDT.db.devModeToggleVariables) do
            if self:DisableDebugVariable(varName) then
                count = count + 1
            end
        end
    end

    print("BDT: Disabled " .. count .. " debug variables")
end

function DebugAddonManager:ClearRegisteredVariables()
    local registeredCount = 0
    local devModeCount = 0

    -- Clear registered variables
    if self.registeredDebugVariables then
        for varName, info in pairs(self.registeredDebugVariables) do
            registeredCount = registeredCount + 1
        end
        self.registeredDebugVariables = {}
    end

    -- Clear dev mode toggle variables from saved variables
    if BDT.db and BDT.db.devModeToggleVariables then
        for varName, info in pairs(BDT.db.devModeToggleVariables) do
            devModeCount = devModeCount + 1
        end
        BDT.db.devModeToggleVariables = {}
        print("BDT: Cleared saved dev mode toggle variables")
    end

    print("BDT: Cleared " .. registeredCount .. " registered variables and " .. devModeCount .. " dev mode toggle variables")
end

function DebugAddonManager:CheckVariableExistence(varName)
    if not varName or varName == "" then
        print("BDT: Error - No variable name provided")
        print("BDT: Usage: /bdtdebug check <variable>")
        return
    end

    -- Clean the variable name
    varName = varName:gsub("^%s+", ""):gsub("%s+$", "")  -- Remove leading/trailing spaces

    print("BDT: Checking variable '" .. varName .. "':")
    print("BDT: Debug - Variable name length: " .. #varName)
    print("BDT: Debug - Variable name bytes: " .. varName:gsub(".", function(c) return string.format("%02X ", string.byte(c)) end))

    -- Check using rawget to avoid metamethod interference
    local rawValue = rawget(_G, varName)
    print("BDT: Debug - rawget(_G, '" .. varName .. "') result: " .. tostring(rawValue) .. " (type: " .. type(rawValue) .. ")")

    -- Check using direct _G access
    local directValue = _G[varName]
    print("BDT: Debug - _G['" .. varName .. "'] result: " .. tostring(directValue) .. " (type: " .. type(directValue) .. ")")

    -- Check if they match
    if rawValue ~= directValue then
        print("BDT: Warning - rawget and direct access return different values!")
        print("BDT: This might indicate metamethod interference")
    end

    if _G[varName] ~= nil then
        local varType = type(_G[varName])
        local varValue = tostring(_G[varName])

        print("  ✓ Found in global scope")
        print("  Type: " .. varType)
        print("  Value: " .. varValue)

        if varType == "boolean" then
            print("  Status: " .. (_G[varName] and "true (enabled)" or "false (disabled)"))
            print("  Can be registered: Yes")
        else
            print("  Can be registered: No (not a boolean)")
        end
    else
        print("  ✗ Not found in global scope")

        -- Check for similar variable names
        print("  Looking for similar variables...")
        local foundSimilar = false
        for name, value in pairs(_G) do
            if type(value) == "boolean" and name:lower():find(varName:lower(), 1, true) then
                print("  Similar: '" .. name .. "' (type: " .. type(value) .. ", value: " .. tostring(value) .. ")")
                foundSimilar = true
            end
        end

        if not foundSimilar then
            print("  No similar boolean variables found")
        end

        print("  Suggestions:")
        print("  - Make sure the addon that creates this variable is loaded")
        print("  - Check the exact variable name (case-sensitive)")
        print("  - Try again after other addons have finished loading")
        print("  - Check for leading/trailing spaces in the variable name")
    end
end

function DebugAddonManager:EnableDebugVariable(varName)
    if _G[varName] == nil then
        print("BDT: Variable '" .. varName .. "' not found in global scope")
        return false
    end

    if type(_G[varName]) ~= "boolean" then
        print("BDT: Variable '" .. varName .. "' is not a boolean")
        return false
    end

    _G[varName] = true
    print("BDT: Enabled '" .. varName .. "'")
    return true
end

function DebugAddonManager:DisableDebugVariable(varName)
    if _G[varName] == nil then
        print("BDT: Variable '" .. varName .. "' not found in global scope")
        return false
    end

    if type(_G[varName]) ~= "boolean" then
        print("BDT: Variable '" .. varName .. "' is not a boolean")
        return false
    end

    _G[varName] = false
    print("BDT: Disabled '" .. varName .. "'")
    return true
end

function DebugAddonManager:IsDebugVariableEnabled(varName)
    if _G[varName] == nil then
        return false
    end

    return _G[varName] == true
end

function DebugAddonManager:RegisterForDevModeToggle(varName, description, category)
    -- This function has been moved to Core.lua
    -- Call the global function instead
    if RegisterForDevModeToggle then
        return RegisterForDevModeToggle(varName, description, category)
    end
    return false
end

function DebugAddonManager:UnregisterForDevModeToggle(varName)
    -- This function has been moved to Core.lua
    -- Call the global function instead
    if UnregisterForDevModeToggle then
        return UnregisterForDevModeToggle(varName)
    end
    return false
end