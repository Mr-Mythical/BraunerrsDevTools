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

local defaults = BDT.Config.defaults

local eventFrame = CreateFrame("Frame")

local function CopyDefaultValue(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for k, v in pairs(value) do
        copy[k] = CopyDefaultValue(v)
    end
    return copy
end

local function ApplyDefaults(db, defaultValues)
    for k, v in pairs(defaultValues) do
        if db[k] == nil then
            db[k] = CopyDefaultValue(v)
        end
    end
end

local function InitializeSettings()
    BraunerrsDevToolsDB = BraunerrsDevToolsDB or {}

    if BDT.Config and BDT.Config.MigrateDB then
        BDT.Config.MigrateDB(BraunerrsDevToolsDB)
    end

    ApplyDefaults(BraunerrsDevToolsDB, defaults)
    BDT.db = BraunerrsDevToolsDB
end

local function Initialize()
    InitializeSettings()

    BDT.DevMode:Initialize()
    BDT.KeybindManager:Initialize()
    BDT.Options:Initialize()

    -- Restore tool states if Dev Mode is active
    if BDT.db.devMode then
        if BDT.Utils.RestoreGrid then
            BDT.Utils.RestoreGrid()
        end
        if BDT.Utils.RestoreMouseCoords then
            BDT.Utils.RestoreMouseCoords()
        end
    end

    if not BDT.db.hasLoaded then
        print("BDT: Loaded! Use /bdt to toggle dev mode, /bdt help for commands.")
        BDT.db.hasLoaded = true
    end
    DevTools = DevTools or {}
    DevTools.DebugUI = BraunerrsDevTools_DebugUI
end

function BDTToggleDevMode()
    if BDT and BDT.Actions then
        BDT.Actions.ToggleDevMode()
    end
end

function BDTReloadUI()
    if BDT and BDT.Actions then
        BDT.Actions.ReloadUI()
    else
        ReloadUI()
    end
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
    BDT.Actions.ClearChat()
end

SLASH_BRAUNERRSDEVTOOLS1 = "/bdt"
SLASH_BRAUNERRSDEVTOOLS2 = "/braunerrsdev"

local function ShowHelp()
    print("BDT Commands:")
    print("  /bdt - Toggle dev mode")
    print("  /bdt quick - Toggle Quick Actions")
    print("  /bdt coords - Toggle mouse coordinates overlay")
    print("  /bdt grid [size|off] - Toggle/resize screen alignment grid (default 64, e.g. 32/64)")
    print("  /bdt profile - Toggle script profiling and reload")
    print("  /bdt profiler - Toggle Addon CPU Profiler UI")
    print("  /cc or /clearchat - Clear all chat windows")
    print("  /bdt debug - Open debug UI directly")
    print("  /bdt check <variable> - Inspect a global debug variable")
    print("  /bdt resetui - Reset BDT window positions")
    print("  /bdt help - Show this help")
end

SlashCmdList["BRAUNERRSDEVTOOLS"] = function(msg)
    local rawMsg = msg or ""
    local command, arg = rawMsg:match("^(%S*)%s*(.-)%s*$")
    command = (command or ""):lower()
    arg = arg or ""
    
    if command == "devmode" or command == "dev" or command == "" then
        BDT.Actions.ToggleDevMode()
    elseif command == "debug" or command == "ui" then
        BDT.Actions.OpenDebugUI()
    elseif command == "quick" then
        BDT.Actions.ToggleQuickActions()
    elseif command == "profile" then
        BDT.Actions.ToggleProfileAndReload()
    elseif command == "coords" then
        BDT.Actions.ToggleMouseCoords()
    elseif command == "grid" then
        BDT.Actions.ToggleGrid(arg ~= "" and arg or nil)
    elseif command == "profiler" or command == "profilerui" then
        BDT.Actions.ToggleProfilerUI()
    elseif command == "check" then
        if BDT.VariableManager then
            BDT.VariableManager:CheckVariableExistence(arg)
        end
    elseif command == "resetui" then
        BDT.Actions.ResetUIPositions()
    elseif command == "help" then
        ShowHelp()
    else
        print("BDT: Unknown command. Showing help...")
        ShowHelp()
    end
end
