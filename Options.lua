--[[
Options.lua - Settings and configuration UI

Purpose: Manages the addon's settings panel and user preferences
Dependencies: BDT.DevMode, BDT.KeybindManager, BDT.db
Author: braunerr
--]]

local _, BDT = ...
local BDTOptions = {}
BDT.Options = BDTOptions

--- Creates a setting checkbox in the options panel
--- @param category table The settings category
--- @param name string Display name for the setting
--- @param key string The database key
--- @param defaultValue boolean Default value
--- @param tooltip string Tooltip text
--- @return table The created option components
local function createSetting(category, name, key, defaultValue, tooltip)
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

--- Updates dev mode related settings
--- Refreshes all dev mode integrations and UI elements
function BDTOptions.updateDevMode()
    BDT.DevMode.isEnabled = BraunerrsDevToolsDB.devMode
    BDT.DevMode:HandleAFKStatus()
    BDT.DevMode:UpdateAddonIntegrations()
    BDT.DevMode:UpdateIndicator()
    BDT.KeybindManager:UpdateBindingsState()
    BDTOptions.updateReloadUIOptions()
end

--- Updates reload UI keybind options
--- Refreshes keybind state when reload options change
function BDTOptions.updateReloadUIOptions()
    BDT.KeybindManager:UpdateBindingsState()
end

--- Initializes the options panel
--- Registers the settings category and all available options
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
        createSetting(
            category,
            "Enable Reload UI with R",
            "reloadUIR",
            false,
            "Enable reloading the UI with R in dev mode."
        )
        createSetting(
            category,
            "Enable Reload UI with Ctrl+R",
            "reloadUICTRL",
            true,
            "Enable reloading the UI with Ctrl+R in dev mode."
        )
        createSetting(
            category,
            "Enable Reload UI with Shift+R",
            "reloadUISHIFT",
            false,
            "Enable reloading the UI with Shift+R in dev mode."
        )
        createSetting(
            category,
            "Enable Reload UI with Alt+R",
            "reloadUIALT",
            false,
            "Enable reloading the UI with Alt+R in dev mode."
        )
        createSetting(
            category,
            "BugSack Integration",
            "enableBugSackIntegration",
            true,
            "Automatically enable BugSack error popups when development mode is active."
        )
        createSetting(
            category,
            "Auto AFK in Dev Mode",
            "enableAutoAFK",
            true,
            "Automatically set AFK status when entering development mode."
        )
        createSetting(
            category,
            "Addon Debug Integration",
            "enableAddonDebugIntegration",
            true,
            "Automatically enable debug modes in registered addons (Using /bdt register) when development mode is active."
        )
        createSetting(
            category,
            "Disable reload keybinds while typing",
            "disableReloadWhileTyping",
            true,
            "If enabled, all reload keybinds are ignored while typing in chat or edit boxes like in the WeakAuras addon."
        )
        BDTOptions.updateReloadUIOptions()
    end)
    if not success then
        print("BDT: Options panel registration failed: " .. tostring(result))
        print("BDT: Use /bdt commands instead.")
    end
end
