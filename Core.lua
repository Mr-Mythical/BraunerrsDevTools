--[[
Core.lua - Main addon logic and initialization

Purpose: Handles addon initialization, settings management, and slash commands for debug variable control
Dependencies: BDT.Config, BDT.DevMode, BDT.KeybindManager, BDT.Options
Author: braunerr
--]]

local addonName, BDT = ...
_G["BraunerrsDevTools"] = BDT

BDT = BDT or {}

local defaults = BDT.Config.defaults

local eventFrame = CreateFrame("Frame")

--- Initializes saved variables with default values
local function InitializeSettings()
    BraunerrsDevToolsDB = BraunerrsDevToolsDB or {}
    for k, v in pairs(defaults) do
        if BraunerrsDevToolsDB[k] == nil then
            BraunerrsDevToolsDB[k] = v
        end
    end
    BDT.db = BraunerrsDevToolsDB
end

--- Initializes the addon after PLAYER_LOGIN event
--- Sets up all modules and displays welcome message if first load
local function Initialize()
    InitializeSettings()
    
    BDT.DevMode:Initialize()
    BDT.KeybindManager:Initialize()
    BDT.Options:Initialize()
    
    if not BDT.db.hasLoaded then
        print("BDT: Loaded! Use /bdt to toggle dev mode, /bdt debug to open the debug UI")
        BDT.db.hasLoaded = true
    end
    
        -- Reference Debug UI (already loaded by .toc)
        DevTools = DevTools or {}
        DevTools.DebugUI = BraunerrsDevTools_DebugUI
end

--- Toggles development mode
--- Global function accessible via keybinds
function BDTToggleDevMode()
    if BDT and BDT.DevMode then
        BDT.DevMode:Toggle()
    end
end

--- Reloads the UI
--- Global function for keybind integration
function BDTReloadUI()
    ReloadUI()
end

eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        Initialize()
    end
end)

--- Finds all global boolean variables
--- @return table Table of variable names mapped to true
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

--- Checks if a debug variable is enabled
--- @param varName string The variable name to check
--- @return boolean Whether the variable exists and is true
local function IsDebugVariableEnabled(varName)
    if _G[varName] == nil then
        return false
    end

    return _G[varName] == true
end

--- Enables a debug variable
--- @param varName string The variable name to enable
--- @return boolean Whether the operation was successful
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

--- Disables a debug variable
--- @param varName string The variable name to disable
--- @return boolean Whether the operation was successful
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
    
    -- Update settings UI if it's open
    if BDT.DevMode and BDT.DevMode.settingsFrame and BDT.DevMode.settingsFrame:IsShown() then
        BDT.DevMode:UpdateSettingsUI()
    end
    
    return true
end

local function UnregisterForDevModeToggle(varName)
    if BDT.db.devModeToggleVariables and BDT.db.devModeToggleVariables[varName] then
        BDT.db.devModeToggleVariables[varName] = nil
        print("BDT: Unregistered '" .. varName .. "'")
        
        -- Update settings UI if it's open
        if BDT.DevMode and BDT.DevMode.settingsFrame and BDT.DevMode.settingsFrame:IsShown() then
            BDT.DevMode:UpdateSettingsUI()
        end
        
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

        print("  Found - Type: " .. varType .. ", Value: " .. varValue)

        if varType == "boolean" then
            print("  Status: " .. (_G[varName] and "enabled" or "disabled") .. " (can be registered)")
        else
            print("  Cannot be registered (not a boolean)")
        end
    else
        print("  Not found in global scope")

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

function BDTEnableAllDebugModes()
    if DevTools and DevTools.DebugUI then
        -- Delegate to DebugUI implementation
        for varName, info in pairs(BDT.DebugAddonManager.registeredDebugVariables or {}) do
            _G[varName] = true
        end
        print("BDT: All registered debug variables enabled")
    else
        EnableAllDebugModes()
    end
end

function BDTDisableAllDebugModes()
    if DevTools and DevTools.DebugUI then
        -- Delegate to DebugUI implementation
        for varName, info in pairs(BDT.DebugAddonManager.registeredDebugVariables or {}) do
            _G[varName] = false
        end
        print("BDT: All registered debug variables disabled")
    else
        DisableAllDebugModes()
    end
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
    msg = msg:lower():gsub("^%s+", ""):gsub("%s+$", "")  -- Trim whitespace
    
    if msg == "devmode" or msg == "dev" or msg == "" then
        BDT.DevMode:Toggle()
    elseif msg == "debug" or msg == "ui" then
        if DevTools and DevTools.DebugUI then
            DevTools.DebugUI:Show()
        else
            print("BDT: Debug UI not available")
        end
    elseif msg == "help" then
        print("BDT Commands:")
        print("  /bdt - Toggle dev mode")
        print("  /bdt debug - Open debug UI directly")
        print("  /bdt help - Show this help")
        print("")
        print("When dev mode is active:")
        print("  A window shows registered variables")
        print("  Click 'Debug UI' button to open full variable manager")
    else
        -- For any other command, open the debug UI
        print("BDT: Unknown command. Opening Debug UI...")
        if DevTools and DevTools.DebugUI then
            DevTools.DebugUI:Show()
        else
            print("BDT: Debug UI not available. Use /bdt help for commands.")
        end
    end
end
