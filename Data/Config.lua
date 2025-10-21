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
    },
    devBindings = {
        ["CTRL-R"] = function() ReloadUI() end,
    }
}
