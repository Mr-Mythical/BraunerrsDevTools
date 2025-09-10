--[[
Config.lua - Configuration data and defaults

Purpose: Stores default settings, configuration options, and other addon data
Dependencies: None
Author: braunerr
--]]

local _, BDT = ...

BDT.Config = {
    defaults = {
        devMode = false,
        enableBugSackIntegration = true,
        enableReloadUIKeybind = true,
        enableAutoAFK = true,
        enableAddonDebugIntegration = true,
        reloadUIOnDevModeToggle = false,
        hasLoaded = false,
        bugSackOriginalAutoPopup = nil,
        devModeToggleVariables = {},
        -- Reload UI keybinds
        reloadUIR = false,
        reloadUICTRL = true,
        reloadUISHIFT = false,
        reloadUIALT = false,
        -- Other options
        enableAddonDebugIntegration = true,
        reloadUIOnDevModeToggle = false,
        disableReloadWhileTyping = true,
    },
    devBindings = {
        ["CTRL-R"] = function() ReloadUI() end,
    }
}
