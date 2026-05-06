--[[
QuickActions.lua - Quick actions floating panel

Purpose: Provides one-click access to frequent development actions (profiling, frame tools, grid, and chat clear)
Dependencies: BDT.db, BDT.Utils, BDT.ProfilerUI
Author: braunerr
--]]

local _, BDT = ...
local QuickActions = {}
BDT.QuickActions = QuickActions

function QuickActions:CreateUI()
    if self.frame then return end
    
    local frame = CreateFrame("Frame", "BDTQuickActionsFrame", UIParent, "BackdropTemplate")
    frame:SetSize(220, 375)
    BDT.UI.RestoreFramePosition(frame, "quickActionsUI")
    
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(200)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        QuickActions:SaveUIPosition()
    end)
    
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        tile = true, tileSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -16)
    title:SetText("Quick Actions")
    title:SetTextColor(1, 0.5, 0, 1)
    
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    local profileText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    profileText:SetPoint("TOP", title, "BOTTOM", 0, -10)
    self.profileText = profileText
    
    local profileBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    profileBtn:SetSize(180, 25)
    profileBtn:SetPoint("TOP", profileText, "BOTTOM", 0, -5)
    profileBtn:SetText("Toggle Profiling & Reload")
    profileBtn:SetScript("OnClick", function()
        BDT.Actions.ToggleProfileAndReload()
    end)

    local profilerUIBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    profilerUIBtn:SetSize(180, 25)
    profilerUIBtn:SetPoint("TOP", profileBtn, "BOTTOM", 0, -5)
    profilerUIBtn:SetText("Open Profiler UI")
    profilerUIBtn:SetScript("OnClick", function()
        BDT.Actions.ToggleProfilerUI()
    end)
    self.profilerUIBtn = profilerUIBtn

    local fstackBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    fstackBtn:SetSize(180, 25)
    fstackBtn:SetPoint("TOP", profilerUIBtn, "BOTTOM", 0, -10)
    fstackBtn:SetText("/fstack")
    fstackBtn:SetScript("OnClick", function()
        BDT.Actions.ToggleFrameStack()
    end)
    
    local etraceBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    etraceBtn:SetSize(180, 25)
    etraceBtn:SetPoint("TOP", fstackBtn, "BOTTOM", 0, -5)
    etraceBtn:SetText("/etrace")
    etraceBtn:SetScript("OnClick", function()
        BDT.Actions.ToggleEventTrace()
    end)

    local gridBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    gridBtn:SetSize(180, 25)
    gridBtn:SetPoint("TOP", etraceBtn, "BOTTOM", 0, -10)
    gridBtn:SetText("Toggle Grid")
    gridBtn:SetScript("OnClick", function()
        BDT.Actions.ToggleGrid(nil)
        QuickActions:UpdateGridStatus()
    end)

    local gridInfo = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    gridInfo:SetPoint("TOP", gridBtn, "BOTTOM", 0, -4)
    gridInfo:SetText("Grid: Off")
    self.gridInfo = gridInfo

    local grid32Btn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    grid32Btn:SetSize(85, 20)
    grid32Btn:SetPoint("TOP", gridInfo, "BOTTOM", 0, -8)
    grid32Btn:SetText("Grid 32")
    grid32Btn:SetScript("OnClick", function()
        BDT.Actions.ToggleGrid(32)
        QuickActions:UpdateGridStatus()
    end)

    local grid64Btn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    grid64Btn:SetSize(85, 20)
    grid64Btn:SetPoint("TOP", grid32Btn, "BOTTOM", 0, -5)
    grid64Btn:SetText("Grid 64")
    grid64Btn:SetScript("OnClick", function()
        BDT.Actions.ToggleGrid(64)
        QuickActions:UpdateGridStatus()
    end)

    local ccBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    ccBtn:SetSize(180, 25)
    ccBtn:SetPoint("TOP", grid64Btn, "BOTTOM", 0, -10)
    ccBtn:SetText("Clear Chat")
    ccBtn:SetScript("OnClick", function()
        BDT.Actions.ClearChat()
    end)

    local mouseCoordsBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    mouseCoordsBtn:SetSize(180, 25)
    mouseCoordsBtn:SetPoint("TOP", ccBtn, "BOTTOM", 0, -5)
    mouseCoordsBtn:SetText("Toggle Mouse Coords")
    mouseCoordsBtn:SetScript("OnClick", function()
        BDT.Actions.ToggleMouseCoords()
    end)

    self.frame = frame
end

function QuickActions:SaveUIPosition()
    if not self.frame then return end

    BDT.UI.SaveFramePosition(self.frame, "quickActionsUI")
end

function QuickActions:UpdateProfileText()
    if self.profileText then
        local isOn = GetCVarBool("scriptProfile")
        self.profileText:SetText("Script Profiling: " .. (isOn and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"))
        
        if self.profilerUIBtn then
            if isOn then
                self.profilerUIBtn:Enable()
            else
                self.profilerUIBtn:Disable()
            end
        end
    end
end

function QuickActions:UpdateGridStatus()
    if not self.gridInfo or not BDT.Utils or not BDT.Utils.GetGridInfo then
        return
    end
    local isEnabled, size = BDT.Utils.GetGridInfo()
    if isEnabled then
        self.gridInfo:SetText("Grid: |cFF00FF00ON|r (" .. size .. "px)")
    else
        self.gridInfo:SetText("Grid: |cFFFF0000OFF|r")
    end
end

function QuickActions:Show()
    if not self.frame then
        self:CreateUI()
    end
    self:UpdateProfileText()
    self:UpdateGridStatus()
    self.frame:Show()
end

function QuickActions:Hide()
    if self.frame then
        self.frame:Hide()
    end
end
