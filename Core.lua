--[[
Core.lua - Main addon logic and initialization

Purpose: Handles addon initialization, settings management, and slash command routing
Dependencies: BDT.DevMode, BDT.KeybindManager, BDT.Options, BDT.ProfilerUI, BDT.Utils
Author: braunerr
--]]

local addonName, BDT = ...
_G["BraunerrsDevTools"] = BDT

BDT = BDT or {}
BDT.Utils = BDT.Utils or {}

BDT.Utils.IsDebugVariableEnabled = function(varName)
    return _G[varName] == true
end

local defaults = BDT.Options.defaults

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
        print("BDT: Loaded! Use /bdt to toggle dev mode, /bdt help for commands.")
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

-- Chat clear slash command
SLASH_BDT_CHATCLEAR1 = "/cc"
SLASH_BDT_CHATCLEAR2 = "/clearchat"
SlashCmdList["BDT_CHATCLEAR"] = function(msg)
    for i = 1, NUM_CHAT_WINDOWS or 10 do
        local frame = _G["ChatFrame" .. i]
        if frame then
            frame:Clear()
        end
    end
    print("BDT: Chat cleared.")
end

SLASH_BRAUNERRSDEVTOOLS1 = "/bdt"
SLASH_BRAUNERRSDEVTOOLS2 = "/braunerrsdev"

local function ShowHelp()
    print("BDT Commands:")
    print("  /bdt - Toggle dev mode")
    print("  /bdt coords - Toggle mouse coordinates overlay")
    print("  /bdt grid [size|off] - Toggle/resize screen alignment grid (default 64, e.g. 32/64)")
    print("  /bdt profile - Toggle script profiling and reload")
    print("  /bdt profiler - Toggle Addon CPU Profiler UI")
    print("  /cc or /clearchat - Clear all chat windows")
    print("  /bdt debug - Open debug UI directly")
    print("  /bdt help - Show this help")
end

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
    elseif msg == "profile" then
        local currentState = GetCVarBool("scriptProfile")
        SetCVar("scriptProfile", currentState and "0" or "1")
        print("BDT: Script Profiling " .. (currentState and "disabled" or "enabled") .. ". Reloading UI...")
        ReloadUI()
    elseif msg == "coords" then
        if BDT.Utils and BDT.Utils.ToggleMouseCoords then
            BDT.Utils.ToggleMouseCoords()
        end
    elseif msg:match("^grid") then
        local cmd, arg = msg:match("^(%S*)%s*(.*)$")
        arg = (arg ~= "") and arg or nil
        if BDT.Utils and BDT.Utils.ToggleGrid then
            BDT.Utils.ToggleGrid(arg)
        end
    elseif msg == "profiler" or msg == "profilerui" then
        if BDT.ProfilerUI then
            if BDT.ProfilerUI.frame and BDT.ProfilerUI.frame:IsShown() then
                BDT.ProfilerUI:Hide()
            else
                BDT.ProfilerUI:Show()
            end
        end
    elseif msg == "help" then
        ShowHelp()
    else
        print("BDT: Unknown command. Showing help...")
        ShowHelp()
    end
end
