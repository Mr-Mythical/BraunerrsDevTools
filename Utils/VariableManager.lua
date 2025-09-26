--[[
VariableManager.lua - Manages debug variable operations

Purpose: Handles enabling, disabling, registering, and checking debug variables
Dependencies: BDT.Utils, BDT.db
Author: braunerr
--]]

local _, BDT = ...

BDT.VariableManager = {}

local VariableManager = BDT.VariableManager

BDT.Utils.EnableDebugVariable = function(varName)
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

BDT.Utils.DisableDebugVariable = function(varName)
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

BDT.Utils.ProcessVariables = function(varTable, actionFunc)
    local count = 0
    for varName, info in pairs(varTable) do
        if actionFunc(varName) then
            count = count + 1
        end
    end
    return count
end

function VariableManager:EnableAllDebugModes()
    local count = 0

    if BDT.DebugAddonManager and BDT.DebugAddonManager.registeredDebugVariables then
        count = count + BDT.Utils.ProcessVariables(BDT.DebugAddonManager.registeredDebugVariables, BDT.Utils.EnableDebugVariable)
    end

    if BDT.db.devModeToggleVariables then
        count = count + BDT.Utils.ProcessVariables(BDT.db.devModeToggleVariables, BDT.Utils.EnableDebugVariable)
    end

    print("BDT: Enabled " .. count .. " variables")
end

function VariableManager:DisableAllDebugModes()
    local count = 0

    if BDT.DebugAddonManager and BDT.DebugAddonManager.registeredDebugVariables then
        count = count + BDT.Utils.ProcessVariables(BDT.DebugAddonManager.registeredDebugVariables, BDT.Utils.DisableDebugVariable)
    end

    if BDT.db.devModeToggleVariables then
        count = count + BDT.Utils.ProcessVariables(BDT.db.devModeToggleVariables, BDT.Utils.DisableDebugVariable)
    end

    print("BDT: Disabled " .. count .. " variables")
end

function VariableManager:EnableDevModeVariables()
    local count = 0

    if BDT.db.devModeToggleVariables then
        count = count + BDT.Utils.ProcessVariables(BDT.db.devModeToggleVariables, BDT.Utils.EnableDebugVariable)
    end

    print("BDT: Enabled " .. count .. " dev mode variables")
end

function VariableManager:DisableDevModeVariables()
    local count = 0

    -- Only disable dev mode toggle variables (not all registered variables)
    if BDT.db.devModeToggleVariables then
        count = count + BDT.Utils.ProcessVariables(BDT.db.devModeToggleVariables, BDT.Utils.DisableDebugVariable)
    end

    print("BDT: Disabled " .. count .. " dev mode variables")
end

function VariableManager:RegisterForDevModeToggle(varName, description, category)
    varName = varName:gsub("^%s+", ""):gsub("%s+$", "")

    if _G[varName] == nil then
        print("BDT: '" .. varName .. "' not found")
        print("BDT: Use '/bdt check " .. varName .. "' to see more details")
        return false
    end

    if type(_G[varName]) ~= "boolean" then
        print("BDT: '" .. varName .. "' is not a boolean (type: " .. type(_G[varName]) .. ")")
        return false
    end

    if not BDT.db.devModeToggleVariables then
        BDT.db.devModeToggleVariables = {}
    end

    BDT.db.devModeToggleVariables[varName] = {
        description = description or ("Dev mode toggle: " .. varName),
        category = category or "Dev Mode Toggle",
        registeredAt = time()
    }

    print("BDT: Registered '" .. varName .. "'")
    
    if BDT.DevMode and BDT.DevMode.settingsFrame and BDT.DevMode.settingsFrame:IsShown() then
        BDT.DevMode:UpdateVariablesUI()
    end
    
    return true
end

function VariableManager:UnregisterForDevModeToggle(varName)
    if BDT.db.devModeToggleVariables and BDT.db.devModeToggleVariables[varName] then
        BDT.db.devModeToggleVariables[varName] = nil
        print("BDT: Unregistered '" .. varName .. "'")
        
        if BDT.DevMode and BDT.DevMode.settingsFrame and BDT.DevMode.settingsFrame:IsShown() then
            BDT.DevMode:UpdateVariablesUI()
        end
        
        return true
    end

    print("BDT: '" .. varName .. "' not found in toggle list")
    return false
end

function VariableManager:CheckVariableExistence(varName)
    if not varName or varName == "" then
        print("BDT: Error - No variable name provided")
        print("BDT: Usage: /bdt check <variable>")
        return
    end

    varName = varName:gsub("^%s+", ""):gsub("%s+$", "")

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
        for varName, info in pairs(BDT.DebugAddonManager.registeredDebugVariables or {}) do
            _G[varName] = true
        end
        print("BDT: All registered debug variables enabled")
    else
        VariableManager:EnableAllDebugModes()
    end
end

function BDTDisableAllDebugModes()
    if DevTools and DevTools.DebugUI then
        for varName, info in pairs(BDT.DebugAddonManager.registeredDebugVariables or {}) do
            _G[varName] = false
        end
        print("BDT: All registered debug variables disabled")
    else
        VariableManager:DisableAllDebugModes()
    end
end

function BDTEnableDevModeVariables()
    VariableManager:EnableDevModeVariables()
end

function BDTDisableDevModeVariables()
    VariableManager:DisableDevModeVariables()
end