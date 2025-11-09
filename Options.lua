--[[
Options.lua - Settings and configuration UI

Purpose: Manages the addon's settings panel and user preferences
Dependencies: BDT.Config, BDT.DevMode, BDT.KeybindManager, BDT.db
Author: braunerr
--]]

local _, BDT = ...
local BDTOptions = {}
BDT.Options = BDTOptions

-- Configuration data
local DEFAULTS = {
    devMode = false,
    enableBugSackIntegration = true,
    enableReloadUIKeybind = true,
    enableAutoAFK = true,
    hasLoaded = false,
    bugSackOriginalAutoPopup = nil,
    devModeToggleVariables = {},
    reloadUIR = false,
    reloadUICTRL = true,
    reloadUISHIFT = false,
    reloadUIALT = false,
    reloadUIOnDevModeToggle = false,
    disableReloadWhileTyping = true,
    hideInterfaceVersionInDevMode = false,
}

-- Keep backwards compatibility
BDTOptions.defaults = DEFAULTS

local TOOLTIPS = {
    reloadUIR = "Enable reloading the UI with R in dev mode.",
    reloadUICTRL = "Enable reloading the UI with Ctrl+R in dev mode.",
    reloadUISHIFT = "Enable reloading the UI with Shift+R in dev mode.",
    reloadUIALT = "Enable reloading the UI with Alt+R in dev mode.",
    enableBugSackIntegration = "Automatically enable BugSack error popups when development mode is active.",
    enableAutoAFK = "Automatically set AFK status when entering development mode.",
    reloadUIOnDevModeToggle = "Automatically reload the UI when development mode is toggled on or off.",
    disableReloadWhileTyping = "If enabled, all reload keybinds are ignored while typing in chat or edit boxes like in the WeakAuras addon.",
    hideInterfaceVersionInDevMode = "If enabled, the interface version will not be displayed in the dev mode status indicator."
}

--- Creates a setting with checkbox
--- @param category table The settings category
--- @param name string Display name for the setting
--- @param key string Database key for the setting
--- @param tooltip string Tooltip text
--- @return table Setting object with option and checkbox
local function createSetting(category, name, key, tooltip)
    local defaultValue = DEFAULTS[key]
    local option = Settings.RegisterAddOnSetting(category, name, key, BraunerrsDevToolsDB, "boolean", name, defaultValue)
    option:SetValueChangedCallback(function(_, value)
        BraunerrsDevToolsDB[key] = value
        if key:find("reloadUI") then
            BDTOptions.updateReloadUIOptions()
        else
            BDTOptions.updateDevMode()
        end
    end)
    local initializer = Settings.CreateCheckbox(category, option, tooltip)
    initializer:SetSetting(option)
    return { option = option, checkbox = initializer }
end

function BDTOptions.updateDevMode()
    BDT.DevMode.isEnabled = BraunerrsDevToolsDB.devMode
    BDT.DevMode:HandleAFKStatus()
    BDT.DevMode:UpdateAddonIntegrations()
    BDT.DevMode:UpdateIndicator()
    BDT.KeybindManager:UpdateBindingsState()
    BDTOptions.updateReloadUIOptions()
end

function BDTOptions.updateReloadUIOptions()
    BDT.KeybindManager:UpdateBindingsState()
end

function BDTOptions:Initialize()
    if not Settings or not Settings.RegisterVerticalLayoutCategory then
        print("BDT: Options API not found. Use /bdt commands instead.")
        return
    end
    
    local success, result = pcall(function()
        local category = Settings.RegisterVerticalLayoutCategory("Braunerr's Dev Tools")
        Settings.RegisterAddOnCategory(category)
        
        local headerData = {
            name = "Development Mode Options",
            tooltip = "Configure development tools and integrations"
        }
        local headerInitializer = Settings.CreateElementInitializer("SettingsListSectionHeaderTemplate", headerData)
        local layout = SettingsPanel:GetLayout(category)
        layout:AddInitializer(headerInitializer)
        
        -- Define all settings in a table-driven way
        local settingsConfig = {
            { name = "Enable Reload UI with R", key = "reloadUIR" },
            { name = "Enable Reload UI with Ctrl+R", key = "reloadUICTRL" },
            { name = "Enable Reload UI with Shift+R", key = "reloadUISHIFT" },
            { name = "Enable Reload UI with Alt+R", key = "reloadUIALT" },
            { name = "BugSack Integration", key = "enableBugSackIntegration" },
            { name = "Auto AFK in Dev Mode", key = "enableAutoAFK" },
            { name = "Reload UI on Dev Mode Toggle", key = "reloadUIOnDevModeToggle" },
            { name = "Disable reload keybinds while typing", key = "disableReloadWhileTyping" },
            { name = "Hide Interface Version in Dev Mode", key = "hideInterfaceVersionInDevMode" }
        }
        
        -- Create all settings
        for _, setting in ipairs(settingsConfig) do
            local tooltip = TOOLTIPS[setting.key] or ""
            createSetting(category, setting.name, setting.key, tooltip)
        end
        
        BDTOptions.updateReloadUIOptions()
    end)
    
    if not success then
        print("BDT: Options panel registration failed: " .. tostring(result))
    end
end
