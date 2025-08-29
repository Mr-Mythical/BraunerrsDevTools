local addonName, BDT = ...
_G["BraunerrsDevTools"] = BDT

BDT = BDT or {}

local defaults = {
    devMode = false,
    enableBugSackIntegration = true,
    enableReloadUIKeybind = true,
    enableAutoAFK = true,
    enableAddonDebugIntegration = true,
    hasLoaded = false,
    bugSackOriginalAutoPopup = nil,
    devModeToggleVariables = {},
}

local eventFrame = CreateFrame("Frame")

local function InitializeSettings()
    BraunerrsDevToolsDB = BraunerrsDevToolsDB or {}
    for k, v in pairs(defaults) do
        if BraunerrsDevToolsDB[k] == nil then
            BraunerrsDevToolsDB[k] = v
        end
    end
    BDT.db = BraunerrsDevToolsDB
end

local function Initialize()
    InitializeSettings()
    
    BDT.DevMode:Initialize()
    BDT.KeybindManager:Initialize()
    BDT.Options:Initialize()
    
    if not BDT.db.hasLoaded then
        print("BDT: Loaded! Use /bdt to toggle dev mode")
        BDT.db.hasLoaded = true
    end
end

function BDTToggleDevMode()
    if BDT and BDT.DevMode then
        BDT.DevMode:Toggle()
    end
end

function BDTReloadUI()
    ReloadUI()
end

eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        Initialize()
    end
end)

-- Debug command functions
local function ListDebugVariables()
    print("BDT: Debug Variables:")

    -- Show registered variables first
    local hasRegistered = false
    if BDT.DebugAddonManager and next(BDT.DebugAddonManager.registeredDebugVariables) ~= nil then
        print("  Registered:")
        for varName, info in pairs(BDT.DebugAddonManager.registeredDebugVariables) do
            local status = IsDebugVariableEnabled(varName) and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"
            local category = info.category and (" [" .. info.category .. "]") or ""
            print("    " .. varName .. category .. " - " .. status .. " - " .. (info.description or "No description"))
            hasRegistered = true
        end
    end

    -- Show dev mode toggle variables
    local hasDevModeToggle = false
    if BDT.db.devModeToggleVariables and next(BDT.db.devModeToggleVariables) ~= nil then
        if hasRegistered then print("") end
        print("  Dev Mode Auto-Toggle:")
        for varName, info in pairs(BDT.db.devModeToggleVariables) do
            local status = IsDebugVariableEnabled(varName) and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"
            local category = info.category and (" [" .. info.category .. "]") or ""
            print("    " .. varName .. category .. " - " .. status .. " - " .. (info.description or "No description"))
            hasDevModeToggle = true
        end
    end

    -- Show all global boolean variables that look like debug variables
    local debugVars = FindAllDebugVariables()
    if next(debugVars) ~= nil then
        if hasRegistered or hasDevModeToggle then print("") end
        print("  Available (any global boolean variable):")
        for varName, _ in pairs(debugVars) do
            if not (BDT.DebugAddonManager and BDT.DebugAddonManager.registeredDebugVariables[varName]) and not (BDT.db.devModeToggleVariables and BDT.db.devModeToggleVariables[varName]) then
                local status = IsDebugVariableEnabled(varName) and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"
                print("    " .. varName .. " - " .. status)
            end
        end
    end

    if not hasRegistered and not hasDevModeToggle and next(debugVars) == nil then
        print("  No debug variables found")
        print("  Any global boolean variable can be controlled with /bdt enable/disable <variable>")
    end
end

local function FindAllDebugVariables()
    local debugVars = {}

    -- Find all global boolean variables
    for varName, value in pairs(_G) do
        if type(value) == "boolean" then
            debugVars[varName] = true
        end
    end

    return debugVars
end

local function IsDebugVariableEnabled(varName)
    if _G[varName] == nil then
        return false
    end

    return _G[varName] == true
end

local function EnableDebugVariable(varName)
    if _G[varName] == nil then
        print("BDT: '" .. varName .. "' not found")
        return false
    end

    if type(_G[varName]) ~= "boolean" then
        print("BDT: '" .. varName .. "' is not a boolean")
        return false
    end

    _G[varName] = true
    print("BDT: '" .. varName .. "' enabled")
    return true
end

local function DisableDebugVariable(varName)
    if _G[varName] == nil then
        print("BDT: '" .. varName .. "' not found")
        return false
    end

    if type(_G[varName]) ~= "boolean" then
        print("BDT: '" .. varName .. "' is not a boolean")
        return false
    end

    _G[varName] = false
    print("BDT: '" .. varName .. "' disabled")
    return true
end

local function EnableAllDebugModes()
    local count = 0

    -- Enable registered variables
    if BDT.DebugAddonManager and BDT.DebugAddonManager.registeredDebugVariables then
        for varName, info in pairs(BDT.DebugAddonManager.registeredDebugVariables) do
            if EnableDebugVariable(varName) then
                count = count + 1
            end
        end
    end

    -- Enable dev mode toggle variables
    if BDT.db.devModeToggleVariables then
        for varName, info in pairs(BDT.db.devModeToggleVariables) do
            if EnableDebugVariable(varName) then
                count = count + 1
            end
        end
    end

    print("BDT: Enabled " .. count .. " variables")
end

local function DisableAllDebugModes()
    local count = 0

    -- Disable registered variables
    if BDT.DebugAddonManager and BDT.DebugAddonManager.registeredDebugVariables then
        for varName, info in pairs(BDT.DebugAddonManager.registeredDebugVariables) do
            if DisableDebugVariable(varName) then
                count = count + 1
            end
        end
    end

    -- Disable dev mode toggle variables
    if BDT.db.devModeToggleVariables then
        for varName, info in pairs(BDT.db.devModeToggleVariables) do
            if DisableDebugVariable(varName) then
                count = count + 1
            end
        end
    end

    print("BDT: Disabled " .. count .. " variables")
end

local function EnableDevModeVariables()
    local count = 0

    -- Only enable dev mode toggle variables (not all registered variables)
    if BDT.db.devModeToggleVariables then
        for varName, info in pairs(BDT.db.devModeToggleVariables) do
            if EnableDebugVariable(varName) then
                count = count + 1
            end
        end
    end

    print("BDT: Enabled " .. count .. " dev mode variables")
end

local function DisableDevModeVariables()
    local count = 0

    -- Only disable dev mode toggle variables (not all registered variables)
    if BDT.db.devModeToggleVariables then
        for varName, info in pairs(BDT.db.devModeToggleVariables) do
            if DisableDebugVariable(varName) then
                count = count + 1
            end
        end
    end

    print("BDT: Disabled " .. count .. " dev mode variables")
end

local function RegisterForDevModeToggle(varName, description, category)
    -- Clean the variable name
    varName = varName:gsub("^%s+", ""):gsub("%s+$", "")  -- Remove leading/trailing spaces

    -- Check if variable exists in global scope
    if _G[varName] == nil then
        print("BDT: '" .. varName .. "' not found")
        print("BDT: Use '/bdt check " .. varName .. "' to see more details")
        return false
    end

    -- Check if variable is a boolean
    if type(_G[varName]) ~= "boolean" then
        print("BDT: '" .. varName .. "' is not a boolean (type: " .. type(_G[varName]) .. ")")
        return false
    end

    -- Ensure devModeToggleVariables table exists in saved variables
    if not BDT.db.devModeToggleVariables then
        BDT.db.devModeToggleVariables = {}
    end

    BDT.db.devModeToggleVariables[varName] = {
        description = description or ("Dev mode toggle: " .. varName),
        category = category or "Dev Mode Toggle",
        registeredAt = time()
    }

    print("BDT: Registered '" .. varName .. "'")
    return true
end

local function UnregisterForDevModeToggle(varName)
    if BDT.db.devModeToggleVariables and BDT.db.devModeToggleVariables[varName] then
        BDT.db.devModeToggleVariables[varName] = nil
        print("BDT: Unregistered '" .. varName .. "'")
        return true
    end

    print("BDT: '" .. varName .. "' not found in toggle list")
    return false
end

local function CheckVariableExistence(varName)
    if not varName or varName == "" then
        print("BDT: Error - No variable name provided")
        print("BDT: Usage: /bdt check <variable>")
        return
    end

    -- Clean the variable name
    varName = varName:gsub("^%s+", ""):gsub("%s+$", "")  -- Remove leading/trailing spaces

    print("BDT: Checking variable '" .. varName .. "':")

    if _G[varName] ~= nil then
        local varType = type(_G[varName])
        local varValue = tostring(_G[varName])

        print("  ✓ Found - Type: " .. varType .. ", Value: " .. varValue)

        if varType == "boolean" then
            print("  Status: " .. (_G[varName] and "enabled" or "disabled") .. " (can be registered)")
        else
            print("  Cannot be registered (not a boolean)")
        end
    else
        print("  ✗ Not found in global scope")

        -- Check for similar variable names (limit to 5 results)
        local foundSimilar = {}
        local count = 0
        for name, value in pairs(_G) do
            if count >= 5 then break end
            if type(value) == "boolean" and name:lower():find(varName:lower(), 1, true) then
                table.insert(foundSimilar, name)
                count = count + 1
            end
        end

        if #foundSimilar > 0 then
            print("  Similar variables: " .. table.concat(foundSimilar, ", "))
        else
            print("  No similar boolean variables found")
        end

        print("  Tips: Check spelling, ensure addon is loaded, verify case sensitivity")
    end
end

local function ClearRegisteredVariables()
    local registeredCount = 0
    local devModeCount = 0

    -- Clear registered variables from DebugAddonManager
    if BDT.DebugAddonManager and BDT.DebugAddonManager.registeredDebugVariables then
        for varName, info in pairs(BDT.DebugAddonManager.registeredDebugVariables) do
            registeredCount = registeredCount + 1
        end
        BDT.DebugAddonManager.registeredDebugVariables = {}
    end

    -- Clear dev mode toggle variables from saved variables
    if BDT.db.devModeToggleVariables then
        for varName, info in pairs(BDT.db.devModeToggleVariables) do
            devModeCount = devModeCount + 1
        end
        BDT.db.devModeToggleVariables = {}
    end

    print("BDT: Cleared " .. (registeredCount + devModeCount) .. " variables")
end

local function ShowHelp()
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
end

function BDTEnableAllDebugModes()
    EnableAllDebugModes()
end

function BDTDisableAllDebugModes()
    DisableAllDebugModes()
end

-- Dev mode specific functions that only affect dev mode toggle variables
function BDTEnableDevModeVariables()
    EnableDevModeVariables()
end

function BDTDisableDevModeVariables()
    DisableDevModeVariables()
end

SLASH_BRAUNERRSDEVTOOLS1 = "/bdt"
SLASH_BRAUNERRSDEVTOOLS2 = "/braunerrsdev"
SlashCmdList["BRAUNERRSDEVTOOLS"] = function(msg)
    local originalMsg = msg  -- Preserve original case for variable names
    msg = msg:lower()
    
    -- Helper function to extract variable name while preserving case
    local function extractVarName(command)
        -- Find command position (case-insensitive) and extract variable name from original
        local startPos, endPos = originalMsg:lower():find("^%s*" .. command:lower() .. "%s+")
        if startPos then
            local varStart = endPos + 1
            local varName = originalMsg:sub(varStart):gsub("^%s+", ""):gsub("%s+$", "")
            return varName ~= "" and varName or nil
        end
        return nil
    end
    
    if msg == "devmode" or msg == "dev" or msg == "" then
        BDT.DevMode:Toggle()
    elseif msg == "list" then
        ListDebugVariables()
    elseif msg == "enable" then
        EnableAllDebugModes()
    elseif msg == "disable" then
        DisableAllDebugModes()
    elseif msg:find("^register ") then
        local varName = extractVarName("register")
        if varName then
            RegisterForDevModeToggle(varName, "Dev mode toggle: " .. varName)
        else
            print("BDT: Error - No variable name provided for register command")
        end
    elseif msg:find("^unregister ") then
        local varName = extractVarName("unregister")
        if varName then
            UnregisterForDevModeToggle(varName)
        else
            print("BDT: Error - No variable name provided for unregister command")
        end
    elseif msg:find("^enable ") then
        local varName = extractVarName("enable")
        if varName then
            EnableDebugVariable(varName)
        else
            print("BDT: Error - No variable name provided for enable command")
        end
    elseif msg:find("^disable ") then
        local varName = extractVarName("disable")
        if varName then
            DisableDebugVariable(varName)
        else
            print("BDT: Error - No variable name provided for disable command")
        end
    elseif msg:find("^check ") then
        local varName = extractVarName("check")
        if varName then
            CheckVariableExistence(varName)
        else
            print("BDT: Error - No variable name provided for check command")
        end
    elseif msg == "clear" then
        ClearRegisteredVariables()
    elseif msg == "help" then
        ShowHelp()
    else
        ShowHelp()
    end
end
