--[[
ControlCenter.lua - Developer Control Center panel

Purpose: Single tabbed command center for BDT tools with search and panel controls
Dependencies: BDT.Actions, BDT.UI, BDT.db, BDT.Config
Author: braunerr
--]]

local _, BDT = ...

local ControlCenter = {}
BDT.ControlCenter = ControlCenter

local TAB_ORDER = {
    "quickActions",
    "debugVariables",
    "profiler",
    "layout",
    "events",
    "cvars",
    "diagnostics",
}

local TAB_LABELS = {
    quickActions = "Quick",
    debugVariables = "Vars",
    profiler = "Profiler",
    layout = "Layout",
    events = "Events",
    cvars = "CVars",
    diagnostics = "Diag",
}

local TAB_TOOLTIPS = {
    quickActions = "Quick Actions",
    debugVariables = "Debug Variables",
    profiler = "Profiler",
    layout = "Layout",
    events = "Events",
    cvars = "CVars",
    diagnostics = "Diagnostics",
}

local function GetUISettings()
    if not BDT.db then
        return nil
    end

    BDT.db.controlCenterUI = BDT.db.controlCenterUI or {}
    local ui = BDT.db.controlCenterUI
    if ui.locked == nil then
        ui.locked = false
    end
    if ui.opacity == nil then
        ui.opacity = 1
    end
    if ui.selectedTab == nil then
        ui.selectedTab = "quickActions"
    end
    return ui
end

local function CreateButton(parent, text, width, height, onClick)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(width or 160, height or 24)
    btn:SetText(text)
    btn:SetScript("OnClick", onClick)
    return btn
end

local function CreateLabel(parent, text, template)
    local label = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    label:SetText(text)
    return label
end

local function CreateSectionNote(parent, text)
    local note = CreateLabel(parent, text, "GameFontNormalSmall")
    note:SetTextColor(0.7, 0.7, 0.7, 1)
    note:SetJustifyH("LEFT")
    note:SetWordWrap(true)
    return note
end

function ControlCenter:EnsureDB()
    return GetUISettings()
end

function ControlCenter:IsShown()
    return self.frame and self.frame:IsShown()
end

function ControlCenter:GetSelectedTab()
    local ui = self:EnsureDB()
    return (ui and ui.selectedTab) or "quickActions"
end

function ControlCenter:CreateUI()
    if self.frame then
        return
    end

    local frame = CreateFrame("Frame", "BDTControlCenterFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(640, 520)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(180)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(selfFrame)
        local ui = GetUISettings()
        if ui and not ui.locked then
            selfFrame:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(selfFrame)
        selfFrame:StopMovingOrSizing()
        ControlCenter:SavePosition()
    end)
    frame:Hide()

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 8, 0)
    frame.title:SetText("BDT Control Center")

    BDT.UI.RestoreFramePosition(frame, "controlCenterUI")

    -- Search box
    local searchLabel = CreateLabel(frame, "Action Search:", "GameFontNormalSmall")
    searchLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -32)

    local searchBox = CreateFrame("EditBox", "BDTControlCenterSearchBox", frame, "InputBoxTemplate")
    searchBox:SetSize(220, 22)
    searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 8, 0)
    searchBox:SetAutoFocus(false)
    searchBox:SetScript("OnTextChanged", function()
        ControlCenter:UpdateSearchResults()
    end)
    searchBox:SetScript("OnEnterPressed", function(selfBox)
        ControlCenter:RunFirstSearchResult()
        selfBox:ClearFocus()
    end)
    searchBox:SetScript("OnEscapePressed", function(selfBox)
        selfBox:SetText("")
        selfBox:ClearFocus()
        ControlCenter:UpdateSearchResults()
    end)
    self.searchBox = searchBox

    local searchResults = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    searchResults:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", -4, -2)
    searchResults:SetSize(280, 120)
    searchResults:SetFrameStrata("DIALOG")
    searchResults:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    searchResults:Hide()
    self.searchResults = searchResults
    self.searchResultButtons = {}

    -- Panel controls (lock / opacity / reset)
    local lockBtn = CreateButton(frame, "Lock", 60, 22, function()
        ControlCenter:ToggleLocked()
    end)
    lockBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -36, -30)
    self.lockBtn = lockBtn

    local resetPosBtn = CreateButton(frame, "Reset Pos", 80, 22, function()
        ControlCenter:ResetPosition()
    end)
    resetPosBtn:SetPoint("RIGHT", lockBtn, "LEFT", -4, 0)

    local opacityLabel = CreateLabel(frame, "Opacity", "GameFontNormalSmall")
    opacityLabel:SetPoint("TOPRIGHT", lockBtn, "BOTTOMRIGHT", 0, -8)

    local opacitySlider = CreateFrame("Slider", "BDTControlCenterOpacitySlider", frame, "OptionsSliderTemplate")
    opacitySlider:SetWidth(100)
    opacitySlider:SetHeight(16)
    opacitySlider:SetPoint("RIGHT", opacityLabel, "LEFT", -8, 0)
    opacitySlider:SetMinMaxValues(0.4, 1)
    opacitySlider:SetValueStep(0.05)
    if opacitySlider.SetObeyStepOnDrag then
        opacitySlider:SetObeyStepOnDrag(true)
    end
    if _G[opacitySlider:GetName() .. "Low"] then
        _G[opacitySlider:GetName() .. "Low"]:SetText("")
    end
    if _G[opacitySlider:GetName() .. "High"] then
        _G[opacitySlider:GetName() .. "High"]:SetText("")
    end
    if _G[opacitySlider:GetName() .. "Text"] then
        _G[opacitySlider:GetName() .. "Text"]:SetText("")
    end
    opacitySlider:SetScript("OnValueChanged", function(_, value)
        ControlCenter:SetOpacity(value)
    end)
    self.opacitySlider = opacitySlider

    -- Tab bar
    local tabBar = CreateFrame("Frame", nil, frame)
    tabBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -78)
    tabBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -78)
    tabBar:SetHeight(28)
    self.tabBar = tabBar
    self.tabButtons = {}

    local previous
    for _, tabId in ipairs(TAB_ORDER) do
        local tabBtn = CreateFrame("Button", nil, tabBar, "UIPanelButtonTemplate")
        tabBtn:SetSize(82, 24)
        tabBtn:SetText(TAB_LABELS[tabId])
        if previous then
            tabBtn:SetPoint("LEFT", previous, "RIGHT", 4, 0)
        else
            tabBtn:SetPoint("LEFT", tabBar, "LEFT", 0, 0)
        end
        tabBtn:SetScript("OnClick", function()
            ControlCenter:SelectTab(tabId)
        end)
        tabBtn:SetScript("OnEnter", function(selfBtn)
            GameTooltip:SetOwner(selfBtn, "ANCHOR_TOP")
            GameTooltip:SetText(TAB_TOOLTIPS[tabId] or TAB_LABELS[tabId], 1, 1, 1)
            GameTooltip:Show()
        end)
        tabBtn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        self.tabButtons[tabId] = tabBtn
        previous = tabBtn
    end

    -- Content host
    local contentHost = CreateFrame("Frame", nil, frame)
    contentHost:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -112)
    contentHost:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 14)
    self.contentHost = contentHost
    self.tabPanels = {}

    for _, tabId in ipairs(TAB_ORDER) do
        local panel = CreateFrame("Frame", nil, contentHost)
        panel:SetAllPoints(contentHost)
        panel:Hide()
        self.tabPanels[tabId] = panel
    end

    self:BuildQuickActionsTab()
    self:BuildDebugVariablesTab()
    self:BuildProfilerTab()
    self:BuildLayoutTab()
    self:BuildEventsTab()
    self:BuildCVarsTab()
    self:BuildDiagnosticsTab()

    self.frame = frame
    self:ApplyAppearance()
    self:UpdateLockButton()
end

function ControlCenter:BuildQuickActionsTab()
    local panel = self.tabPanels.quickActions
    local title = CreateLabel(panel, "Common developer actions", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -4)
    title:SetTextColor(1, 0.5, 0, 1)

    local status = CreateLabel(panel, "", "GameFontNormal")
    status:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    self.quickActionsStatus = status

    local buttons = {
        { "Toggle Dev Mode", function() BDT.Actions.ToggleDevMode() end },
        { "Toggle Profiling & Reload", function() BDT.Actions.ToggleProfileAndReload() end },
        { "Open Profiler UI", function() BDT.Actions.ToggleProfilerUI() end },
        { "/fstack", function() BDT.Actions.ToggleFrameStack() end },
        { "/etrace", function() BDT.Actions.ToggleEventTrace() end },
        { "Toggle Grid", function()
            BDT.Actions.ToggleGrid(nil)
            ControlCenter:RefreshActiveTab()
        end },
        { "Grid 32", function()
            BDT.Actions.ToggleGrid(32)
            ControlCenter:RefreshActiveTab()
        end },
        { "Grid 64", function()
            BDT.Actions.ToggleGrid(64)
            ControlCenter:RefreshActiveTab()
        end },
        { "Toggle Mouse Coords", function() BDT.Actions.ToggleMouseCoords() end },
        { "Clear Chat", function() BDT.Actions.ClearChat() end },
        { "Floating Quick Actions", function() BDT.Actions.ToggleQuickActions() end },
        { "Reload UI", function() BDT.Actions.ReloadUI() end },
    }

    local x, y = 4, -50
    local col = 0
    for _, info in ipairs(buttons) do
        local btn = CreateButton(panel, info[1], 190, 26, info[2])
        btn:SetPoint("TOPLEFT", panel, "TOPLEFT", x + (col * 200), y)
        col = col + 1
        if col >= 3 then
            col = 0
            y = y - 32
        end
    end
end

function ControlCenter:BuildDebugVariablesTab()
    local panel = self.tabPanels.debugVariables
    local title = CreateLabel(panel, "Debug Variables", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -4)
    title:SetTextColor(1, 0.5, 0, 1)

    local note = CreateSectionNote(panel, "Browse and register global boolean debug flags for Dev Mode auto-toggle.")
    note:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    note:SetWidth(580)

    local openBtn = CreateButton(panel, "Open Debug Variable Browser", 220, 26, function()
        BDT.Actions.OpenDebugUI()
    end)
    openBtn:SetPoint("TOPLEFT", note, "BOTTOMLEFT", 0, -12)

    local listTitle = CreateLabel(panel, "Registered for Dev Mode:", "GameFontNormal")
    listTitle:SetPoint("TOPLEFT", openBtn, "BOTTOMLEFT", 0, -16)
    self.debugVarsListTitle = listTitle

    local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", listTitle, "BOTTOMLEFT", 0, -8)
    scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -28, 4)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(560, 280)
    scroll:SetScrollChild(content)
    self.debugVarsContent = content
    self.debugVarsLines = {}
end

function ControlCenter:BuildProfilerTab()
    local panel = self.tabPanels.profiler
    local title = CreateLabel(panel, "Addon Profiler", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -4)
    title:SetTextColor(1, 0.5, 0, 1)

    local status = CreateLabel(panel, "", "GameFontNormal")
    status:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    self.profilerStatus = status

    local note = CreateSectionNote(panel, "CPU profiling requires the scriptProfile CVar. Memory usage is always available.")
    note:SetPoint("TOPLEFT", status, "BOTTOMLEFT", 0, -8)
    note:SetWidth(580)

    local toggleBtn = CreateButton(panel, "Toggle Profiling & Reload", 200, 26, function()
        BDT.Actions.ToggleProfileAndReload()
    end)
    toggleBtn:SetPoint("TOPLEFT", note, "BOTTOMLEFT", 0, -16)

    local openBtn = CreateButton(panel, "Open Profiler UI", 160, 26, function()
        BDT.Actions.ToggleProfilerUI()
    end)
    openBtn:SetPoint("LEFT", toggleBtn, "RIGHT", 8, 0)
    self.profilerOpenBtn = openBtn
end

function ControlCenter:BuildLayoutTab()
    local panel = self.tabPanels.layout
    local title = CreateLabel(panel, "Layout Tools", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -4)
    title:SetTextColor(1, 0.5, 0, 1)

    local status = CreateLabel(panel, "", "GameFontNormal")
    status:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    self.layoutStatus = status

    local gridBtn = CreateButton(panel, "Toggle Grid", 140, 26, function()
        BDT.Actions.ToggleGrid(nil)
        ControlCenter:RefreshActiveTab()
    end)
    gridBtn:SetPoint("TOPLEFT", status, "BOTTOMLEFT", 0, -14)

    local grid32 = CreateButton(panel, "Grid 32", 90, 26, function()
        BDT.Actions.ToggleGrid(32)
        ControlCenter:RefreshActiveTab()
    end)
    grid32:SetPoint("LEFT", gridBtn, "RIGHT", 8, 0)

    local grid64 = CreateButton(panel, "Grid 64", 90, 26, function()
        BDT.Actions.ToggleGrid(64)
        ControlCenter:RefreshActiveTab()
    end)
    grid64:SetPoint("LEFT", grid32, "RIGHT", 8, 0)

    local coordsBtn = CreateButton(panel, "Toggle Mouse Coords", 180, 26, function()
        BDT.Actions.ToggleMouseCoords()
        ControlCenter:RefreshActiveTab()
    end)
    coordsBtn:SetPoint("TOPLEFT", gridBtn, "BOTTOMLEFT", 0, -10)

    local resetBtn = CreateButton(panel, "Reset All Panel Positions", 200, 26, function()
        BDT.Actions.ResetUIPositions()
    end)
    resetBtn:SetPoint("TOPLEFT", coordsBtn, "BOTTOMLEFT", 0, -10)

    local note = CreateSectionNote(panel, "Rulers, frame highlight, and grid presets arrive in Layout Toolkit 2.0.")
    note:SetPoint("TOPLEFT", resetBtn, "BOTTOMLEFT", 0, -16)
    note:SetWidth(580)
end

function ControlCenter:BuildEventsTab()
    local panel = self.tabPanels.events
    local title = CreateLabel(panel, "Events", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -4)
    title:SetTextColor(1, 0.5, 0, 1)

    local note = CreateSectionNote(panel, "Persistent Event Watch lands in a later milestone. Use Blizzard EventTrace for now.")
    note:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    note:SetWidth(580)

    local etraceBtn = CreateButton(panel, "Open /etrace", 140, 26, function()
        BDT.Actions.ToggleEventTrace()
    end)
    etraceBtn:SetPoint("TOPLEFT", note, "BOTTOMLEFT", 0, -14)

    local fstackBtn = CreateButton(panel, "Open /fstack", 140, 26, function()
        BDT.Actions.ToggleFrameStack()
    end)
    fstackBtn:SetPoint("LEFT", etraceBtn, "RIGHT", 8, 0)
end

function ControlCenter:BuildCVarsTab()
    local panel = self.tabPanels.cvars
    local title = CreateLabel(panel, "Developer CVars", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -4)
    title:SetTextColor(1, 0.5, 0, 1)

    local status = CreateLabel(panel, "", "GameFontNormal")
    status:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    self.cvarStatus = status

    local note = CreateSectionNote(panel, "Named CVar profiles and diff view arrive later. scriptProfile can be toggled here now.")
    note:SetPoint("TOPLEFT", status, "BOTTOMLEFT", 0, -8)
    note:SetWidth(580)

    local toggleBtn = CreateButton(panel, "Toggle scriptProfile & Reload", 220, 26, function()
        BDT.Actions.ToggleProfileAndReload()
    end)
    toggleBtn:SetPoint("TOPLEFT", note, "BOTTOMLEFT", 0, -14)
end

function ControlCenter:BuildDiagnosticsTab()
    local panel = self.tabPanels.diagnostics
    local title = CreateLabel(panel, "Diagnostics", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -4)
    title:SetTextColor(1, 0.5, 0, 1)

    local note = CreateSectionNote(panel, "Full copyable diagnostics reports arrive later. Snapshot of the current environment:")
    note:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    note:SetWidth(580)

    local report = CreateLabel(panel, "", "GameFontHighlightSmall")
    report:SetPoint("TOPLEFT", note, "BOTTOMLEFT", 0, -14)
    report:SetJustifyH("LEFT")
    report:SetWidth(580)
    self.diagnosticsReport = report

    local refreshBtn = CreateButton(panel, "Refresh Snapshot", 140, 26, function()
        ControlCenter:UpdateDiagnosticsTab()
    end)
    refreshBtn:SetPoint("TOPLEFT", report, "BOTTOMLEFT", 0, -16)

    local printBtn = CreateButton(panel, "Print to Chat", 120, 26, function()
        ControlCenter:PrintDiagnostics()
    end)
    printBtn:SetPoint("LEFT", refreshBtn, "RIGHT", 8, 0)
end

function ControlCenter:UpdateSearchResults()
    if not self.searchBox or not self.searchResults then
        return
    end

    local query = self.searchBox:GetText() or ""
    if query == "" then
        self.searchResults:Hide()
        return
    end

    local matches = BDT.Actions.Search(query)
    for _, btn in ipairs(self.searchResultButtons) do
        btn:Hide()
    end

    if #matches == 0 then
        local btn = self.searchResultButtons[1]
        if not btn then
            btn = CreateFrame("Button", nil, self.searchResults)
            btn:SetSize(260, 20)
            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            btn.text:SetPoint("LEFT", 8, 0)
            self.searchResultButtons[1] = btn
        end
        btn:SetPoint("TOPLEFT", self.searchResults, "TOPLEFT", 6, -6)
        btn.text:SetText("No matching actions")
        btn.text:SetTextColor(0.6, 0.6, 0.6, 1)
        btn:SetScript("OnClick", nil)
        btn:Show()
        self.searchResults:SetHeight(32)
        self.searchResults:Show()
        return
    end

    local maxShow = 6
    local y = -6
    for i = 1, math.min(#matches, maxShow) do
        local action = matches[i]
        local btn = self.searchResultButtons[i]
        if not btn then
            btn = CreateFrame("Button", nil, self.searchResults)
            btn:SetSize(260, 20)
            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            btn.text:SetPoint("LEFT", 8, 0)
            local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetAllPoints()
            highlight:SetColorTexture(1, 1, 1, 0.1)
            self.searchResultButtons[i] = btn
        end
        btn:SetPoint("TOPLEFT", self.searchResults, "TOPLEFT", 6, y)
        btn.text:SetText(action.label)
        btn.text:SetTextColor(1, 1, 1, 1)
        btn:SetScript("OnClick", function()
            action.run()
            self.searchBox:SetText("")
            self.searchBox:ClearFocus()
            self.searchResults:Hide()
            ControlCenter:RefreshActiveTab()
        end)
        btn:Show()
        y = y - 20
    end

    self.searchResults:SetHeight(math.abs(y) + 10)
    self.searchResults:Show()
end

function ControlCenter:RunFirstSearchResult()
    if not self.searchBox then
        return
    end

    local matches = BDT.Actions.Search(self.searchBox:GetText() or "")
    if matches[1] then
        matches[1].run()
        self.searchBox:SetText("")
        self.searchResults:Hide()
        self:RefreshActiveTab()
    end
end

function ControlCenter:SelectTab(tabId)
    if not self.tabPanels[tabId] then
        tabId = "quickActions"
    end

    local ui = self:EnsureDB()
    if ui then
        ui.selectedTab = tabId
    end

    for id, panel in pairs(self.tabPanels) do
        if id == tabId then
            panel:Show()
        else
            panel:Hide()
        end
    end

    for id, btn in pairs(self.tabButtons) do
        if id == tabId then
            btn:Disable()
        else
            btn:Enable()
        end
    end

    self:RefreshActiveTab()
end

function ControlCenter:RefreshActiveTab()
    local tabId = self:GetSelectedTab()
    if tabId == "quickActions" then
        self:UpdateQuickActionsTab()
    elseif tabId == "debugVariables" then
        self:UpdateDebugVariablesTab()
    elseif tabId == "profiler" then
        self:UpdateProfilerTab()
    elseif tabId == "layout" then
        self:UpdateLayoutTab()
    elseif tabId == "cvars" then
        self:UpdateCVarsTab()
    elseif tabId == "diagnostics" then
        self:UpdateDiagnosticsTab()
    end
end

function ControlCenter:UpdateQuickActionsTab()
    if not self.quickActionsStatus then
        return
    end

    local profiling = GetCVarBool("scriptProfile")
    local gridText = "Off"
    if BDT.Utils and BDT.Utils.GetGridInfo then
        local enabled, size = BDT.Utils.GetGridInfo()
        if enabled then
            gridText = "ON (" .. tostring(size) .. "px)"
        end
    end

    local coordsOn = BDT.db and BDT.db.mouseCoordsEnabled
    self.quickActionsStatus:SetText(string.format(
        "Dev Mode: %s  |  Profiling: %s  |  Grid: %s  |  Coords: %s",
        (BDT.db and BDT.db.devMode) and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r",
        profiling and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r",
        gridText,
        coordsOn and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"
    ))
end

function ControlCenter:UpdateDebugVariablesTab()
    if not self.debugVarsContent then
        return
    end

    for _, line in ipairs(self.debugVarsLines) do
        line:Hide()
    end

    local y = -2
    local index = 0
    local vars = BDT.db and BDT.db.devModeToggleVariables

    if not vars or not next(vars) then
        index = 1
        local line = self.debugVarsLines[1]
        if not line then
            line = self.debugVarsContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            self.debugVarsLines[1] = line
        end
        line:SetPoint("TOPLEFT", self.debugVarsContent, "TOPLEFT", 4, y)
        line:SetText("No registered variables. Open the browser to add some.")
        line:SetTextColor(0.6, 0.6, 0.6, 1)
        line:Show()
        self.debugVarsContent:SetHeight(40)
        return
    end

    for varName, info in pairs(vars) do
        index = index + 1
        local line = self.debugVarsLines[index]
        if not line then
            line = self.debugVarsContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            self.debugVarsLines[index] = line
        end
        line:SetPoint("TOPLEFT", self.debugVarsContent, "TOPLEFT", 4, y)
        local status = (BDT.Utils and BDT.Utils.IsDebugVariableEnabled(varName)) and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"
        local category = info.category and (" [" .. info.category .. "]") or ""
        line:SetText(varName .. category .. ": " .. status)
        line:SetTextColor(1, 1, 1, 1)
        line:Show()
        y = y - 18
    end

    self.debugVarsContent:SetHeight(math.max(40, math.abs(y) + 10))
end

function ControlCenter:UpdateProfilerTab()
    if not self.profilerStatus then
        return
    end

    local profiling = GetCVarBool("scriptProfile")
    self.profilerStatus:SetText("scriptProfile: " .. (profiling and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"))
    if self.profilerOpenBtn then
        if profiling then
            self.profilerOpenBtn:Enable()
        else
            self.profilerOpenBtn:Disable()
        end
    end
end

function ControlCenter:UpdateLayoutTab()
    if not self.layoutStatus then
        return
    end

    local gridText = "Off"
    if BDT.Utils and BDT.Utils.GetGridInfo then
        local enabled, size = BDT.Utils.GetGridInfo()
        if enabled then
            gridText = "ON (" .. tostring(size) .. "px)"
        end
    end
    local coordsOn = BDT.db and BDT.db.mouseCoordsEnabled
    self.layoutStatus:SetText(string.format(
        "Grid: %s  |  Mouse Coords: %s",
        gridText,
        coordsOn and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"
    ))
end

function ControlCenter:UpdateCVarsTab()
    if not self.cvarStatus then
        return
    end

    local profiling = GetCVarBool("scriptProfile")
    local scriptErrors = GetCVarBool("scriptErrors")
    self.cvarStatus:SetText(string.format(
        "scriptProfile: %s  |  scriptErrors: %s",
        profiling and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r",
        scriptErrors and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"
    ))
end

function ControlCenter:BuildDiagnosticsText()
    local version, build, buildDate, interfaceVersion = GetBuildInfo()
    local addonCount = (BDT.Compat and BDT.Compat.GetNumAddOns and BDT.Compat.GetNumAddOns()) or 0
    local lines = {
        "BraunerrsDevTools Diagnostics",
        "Client: " .. tostring(version) .. " (" .. tostring(build) .. ")",
        "Interface: " .. tostring(interfaceVersion),
        "Build date: " .. tostring(buildDate),
        "Loaded addons (slots): " .. tostring(addonCount),
        "Dev Mode: " .. ((BDT.db and BDT.db.devMode) and "ON" or "OFF"),
        "scriptProfile: " .. (GetCVarBool("scriptProfile") and "ON" or "OFF"),
        "Grid: " .. ((BDT.db and BDT.db.gridEnabled) and ("ON/" .. tostring(BDT.db.gridSize)) or "OFF"),
        "Mouse Coords: " .. ((BDT.db and BDT.db.mouseCoordsEnabled) and "ON" or "OFF"),
    }
    return table.concat(lines, "\n")
end

function ControlCenter:UpdateDiagnosticsTab()
    if not self.diagnosticsReport then
        return
    end
    self.diagnosticsReport:SetText(self:BuildDiagnosticsText())
end

function ControlCenter:PrintDiagnostics()
    for line in string.gmatch(self:BuildDiagnosticsText(), "[^\n]+") do
        print("BDT: " .. line)
    end
end

function ControlCenter:ToggleLocked()
    local ui = self:EnsureDB()
    if not ui then
        return
    end
    ui.locked = not ui.locked
    self:UpdateLockButton()
end

function ControlCenter:UpdateLockButton()
    if not self.lockBtn then
        return
    end
    local ui = self:EnsureDB()
    local locked = ui and ui.locked
    self.lockBtn:SetText(locked and "Unlock" or "Lock")
end

function ControlCenter:SetOpacity(value)
    local ui = self:EnsureDB()
    if not ui or not self.frame then
        return
    end
    value = math.max(0.4, math.min(1, tonumber(value) or 1))
    ui.opacity = value
    self.frame:SetAlpha(value)
end

function ControlCenter:ApplyAppearance()
    local ui = self:EnsureDB()
    if not ui or not self.frame then
        return
    end

    -- Clear any previously saved custom scale from earlier builds.
    self.frame:SetScale(1)
    ui.scale = nil
    self.frame:SetAlpha(ui.opacity or 1)

    if self.opacitySlider then
        self.opacitySlider:SetValue(ui.opacity or 1)
    end
end

function ControlCenter:SavePosition()
    if not self.frame then
        return
    end
    BDT.UI.SaveFramePosition(self.frame, "controlCenterUI")
end

function ControlCenter:ResetPosition()
    if not self.frame then
        return
    end

    local ui = self:EnsureDB()
    if ui then
        ui.point = nil
        ui.opacity = 1
        ui.locked = false
    end

    BDT.UI.RestoreFramePosition(self.frame, "controlCenterUI")
    self:ApplyAppearance()
    self:UpdateLockButton()
    print("BDT: Control Center position and appearance reset.")
end

function ControlCenter:Show(tab)
    self:CreateUI()

    local requested = tab
    if type(requested) == "string" then
        requested = requested:lower()
        local aliases = {
            quick = "quickActions",
            actions = "quickActions",
            vars = "debugVariables",
            variables = "debugVariables",
            debug = "debugVariables",
            profile = "profiler",
            grid = "layout",
            coords = "layout",
            event = "events",
            cvar = "cvars",
            diag = "diagnostics",
        }
        requested = aliases[requested] or requested
    end

    if not requested or not self.tabPanels[requested] then
        requested = self:GetSelectedTab()
    end

    self:ApplyAppearance()
    self:UpdateLockButton()
    self.frame:Show()
    self:SelectTab(requested)
end

function ControlCenter:Hide()
    if self.frame then
        if self.searchResults then
            self.searchResults:Hide()
        end
        self.frame:Hide()
    end
end
