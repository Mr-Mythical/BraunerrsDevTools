--[[
Actions.lua - Shared actions used by slash commands and buttons

Purpose: Keeps command and Quick Actions behavior in one place
Dependencies: BDT.DevMode, BDT.Utils, BDT.ProfilerUI, BDT.UI, BDT.ControlCenter
Author: braunerr
--]]

local _, BDT = ...

BDT.Actions = BDT.Actions or {}

local Actions = BDT.Actions

function Actions.ToggleDevMode()
    if BDT.DevMode then
        BDT.DevMode:Toggle()
    end
end

function Actions.ReloadUI()
    ReloadUI()
end

function Actions.ToggleProfileAndReload()
    local currentState = GetCVarBool("scriptProfile")
    SetCVar("scriptProfile", currentState and "0" or "1")
    print("BDT: Script Profiling " .. (currentState and "disabled" or "enabled") .. ". Reloading UI...")
    ReloadUI()
end

function Actions.ToggleProfilerUI()
    if not BDT.ProfilerUI then
        print("BDT: Profiler UI not available")
        return
    end

    if BDT.ProfilerUI.frame and BDT.ProfilerUI.frame:IsShown() then
        BDT.ProfilerUI:Hide()
    else
        BDT.ProfilerUI:Show()
    end
end

function Actions.ToggleGrid(gridSize)
    if BDT.Utils and BDT.Utils.ToggleGrid then
        BDT.Utils.ToggleGrid(gridSize)
    end
end

function Actions.ToggleMouseCoords()
    if BDT.Utils and BDT.Utils.ToggleMouseCoords then
        BDT.Utils.ToggleMouseCoords()
    end
end

function Actions.ClearChat()
    for i = 1, (NUM_CHAT_WINDOWS or 10) do
        local frame = _G["ChatFrame" .. i]
        if frame then
            frame:Clear()
        end
    end
    print("BDT: Chat cleared.")
end

function Actions.OpenDebugUI()
    if DevTools and DevTools.DebugUI then
        DevTools.DebugUI:Show()
    elseif BraunerrsDevTools_DebugUI then
        BraunerrsDevTools_DebugUI:Show()
    else
        print("BDT: Debug UI not available")
    end
end

function Actions.ToggleQuickActions()
    if not BDT.QuickActions then
        print("BDT: Quick Actions not available")
        return
    end

    if BDT.QuickActions.frame and BDT.QuickActions.frame:IsShown() then
        BDT.QuickActions:Hide()
    else
        BDT.QuickActions:Show()
    end
end

function Actions.OpenControlCenter(tab)
    if not BDT.ControlCenter then
        print("BDT: Control Center not available")
        return
    end

    BDT.ControlCenter:Show(tab)
end

function Actions.ToggleControlCenter(tab)
    if not BDT.ControlCenter then
        print("BDT: Control Center not available")
        return
    end

    if BDT.ControlCenter:IsShown() then
        if tab and BDT.ControlCenter:GetSelectedTab() ~= tab then
            BDT.ControlCenter:Show(tab)
            return
        end
        BDT.ControlCenter:Hide()
    else
        BDT.ControlCenter:Show(tab)
    end
end

function Actions.ToggleFrameStack()
    if UIParentLoadAddOn then
        UIParentLoadAddOn("Blizzard_DebugTools")
    end

    if SlashCmdList.FRAMESTACK then
        SlashCmdList.FRAMESTACK("")
    elseif FrameStackTooltip_Toggle then
        FrameStackTooltip_Toggle()
    else
        print("BDT: Frame stack tool not available")
    end
end

function Actions.ToggleEventTrace()
    if UIParentLoadAddOn then
        UIParentLoadAddOn("Blizzard_DebugTools")
    end

    if SlashCmdList.EVENTTRACE then
        SlashCmdList.EVENTTRACE("")
    elseif EventTrace and EventTrace.ToggleVisibility then
        EventTrace:ToggleVisibility()
    else
        print("BDT: ETrace not available")
    end
end

function Actions.ResetUIPositions()
    if BDT.UI and BDT.UI.ResetManagedPositions then
        BDT.UI.ResetManagedPositions()
    end
end

-- Searchable action catalog for Control Center
Actions.catalog = {
    {
        id = "toggleDevMode",
        label = "Toggle Dev Mode",
        keywords = "dev mode development",
        run = function()
            Actions.ToggleDevMode()
        end,
    },
    {
        id = "openControlCenter",
        label = "Open Control Center",
        keywords = "panel open main",
        run = function()
            Actions.OpenControlCenter()
        end,
    },
    {
        id = "toggleQuickActions",
        label = "Toggle Quick Actions",
        keywords = "quick actions palette",
        run = function()
            Actions.ToggleQuickActions()
        end,
    },
    {
        id = "openDebugUI",
        label = "Open Debug Variables",
        keywords = "debug variables boolean register",
        run = function()
            Actions.OpenDebugUI()
        end,
    },
    {
        id = "toggleProfiler",
        label = "Toggle Profiler UI",
        keywords = "profiler cpu memory performance",
        run = function()
            Actions.ToggleProfilerUI()
        end,
    },
    {
        id = "toggleProfile",
        label = "Toggle Script Profiling & Reload",
        keywords = "scriptprofile profile cvar reload",
        run = function()
            Actions.ToggleProfileAndReload()
        end,
    },
    {
        id = "toggleGrid",
        label = "Toggle Grid",
        keywords = "grid layout alignment",
        run = function()
            Actions.ToggleGrid(nil)
        end,
    },
    {
        id = "grid32",
        label = "Grid 32",
        keywords = "grid layout 32",
        run = function()
            Actions.ToggleGrid(32)
        end,
    },
    {
        id = "grid64",
        label = "Grid 64",
        keywords = "grid layout 64",
        run = function()
            Actions.ToggleGrid(64)
        end,
    },
    {
        id = "toggleCoords",
        label = "Toggle Mouse Coordinates",
        keywords = "mouse coords coordinates cursor layout",
        run = function()
            Actions.ToggleMouseCoords()
        end,
    },
    {
        id = "clearChat",
        label = "Clear Chat",
        keywords = "chat clear cc",
        run = function()
            Actions.ClearChat()
        end,
    },
    {
        id = "frameStack",
        label = "Toggle Frame Stack (/fstack)",
        keywords = "fstack frame stack blizzard",
        run = function()
            Actions.ToggleFrameStack()
        end,
    },
    {
        id = "eventTrace",
        label = "Toggle Event Trace (/etrace)",
        keywords = "etrace event trace blizzard",
        run = function()
            Actions.ToggleEventTrace()
        end,
    },
    {
        id = "resetUI",
        label = "Reset Panel Positions",
        keywords = "resetui positions panels windows",
        run = function()
            Actions.ResetUIPositions()
        end,
    },
    {
        id = "reloadUI",
        label = "Reload UI",
        keywords = "reload ui /reload",
        run = function()
            Actions.ReloadUI()
        end,
    },
}

function Actions.Search(query)
    local results = {}
    local needle = (query or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")

    for _, action in ipairs(Actions.catalog) do
        if needle == "" then
            results[#results + 1] = action
        else
            local haystack = (action.label .. " " .. (action.keywords or "") .. " " .. action.id):lower()
            if haystack:find(needle, 1, true) then
                results[#results + 1] = action
            end
        end
    end

    return results
end

function Actions.RunById(actionId)
    for _, action in ipairs(Actions.catalog) do
        if action.id == actionId then
            action.run()
            return true
        end
    end

    return false
end
