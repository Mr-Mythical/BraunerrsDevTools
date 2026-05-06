--[[
Actions.lua - Shared actions used by slash commands and buttons

Purpose: Keeps command and Quick Actions behavior in one place
Dependencies: BDT.DevMode, BDT.Utils, BDT.ProfilerUI, BDT.UI
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
