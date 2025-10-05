--[[
Core.lua - Main addon logic and initialization

Purpose: Handles addon initialization, settings management, and slash commands for debug variable control
Dependencies: BDT.Config, BDT.DevMode, BDT.KeybindManager, BDT.Options
Author: braunerr
--]]

local addonName, BDT = ...
_G["BraunerrsDevTools"] = BDT

BDT = BDT or {}
BDT.Utils = BDT.Utils or {}

BDT.Utils.IsDebugVariableEnabled = function(varName)
    if _G[varName] == nil then
        return false
    end

    return _G[varName] == true
end

local defaults = BDT.Config.defaults

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
        print("BDT: Loaded! Use /bdt to toggle dev mode, /bdt debug to open the debug UI")
        BDT.db.hasLoaded = true
    end
        DevTools = DevTools or {}
        DevTools.DebugUI = BraunerrsDevTools_DebugUI
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

SLASH_BRAUNERRSDEVTOOLS1 = "/bdt"
SLASH_BRAUNERRSDEVTOOLS2 = "/braunerrsdev"
SlashCmdList["BRAUNERRSDEVTOOLS"] = function(msg)
    msg = msg:lower():gsub("^%s+", ""):gsub("%s+$", "")
    
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
        print("BDT: Unknown command. Opening Debug UI...")
        if DevTools and DevTools.DebugUI then
            DevTools.DebugUI:Show()
        else
            print("BDT: Debug UI not available. Use /bdt help for commands.")
        end
    end
end
