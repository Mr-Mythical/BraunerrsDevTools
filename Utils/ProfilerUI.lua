--[[
ProfilerUI.lua - Addon CPU & Memory profiler window

Purpose: Displays per-addon CPU and memory usage with sortable columns
Dependencies: BDT, scriptProfile CVar
Author: braunerr
--]]

local _, BDT = ...
local ProfilerUI = {}
BDT.ProfilerUI = ProfilerUI

local SORT_CPU = "cpu"
local SORT_MEM = "mem"

local sortColumn = SORT_CPU
local sortAscending = false

local function FormatMemory(kb)
    if kb >= 1024 then
        return string.format("%.1f MB", kb / 1024)
    end
    return string.format("%.0f KB", kb)
end

local function CreateColumnHeader(parent, text, width, anchorPoint, anchorTo, anchorRel, offsetX, offsetY, columnKey)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width, 20)
    btn:SetPoint(anchorPoint, anchorTo, anchorRel, offsetX, offsetY)

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.15, 0.15, 0.15, 0.8)

    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.1)

    btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.label:SetPoint("CENTER")
    btn.label:SetText(text)

    btn.arrow = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.arrow:SetPoint("LEFT", btn.label, "RIGHT", 2, 0)
    btn.arrow:SetText("")

    btn:SetScript("OnClick", function()
        if sortColumn == columnKey then
            sortAscending = not sortAscending
        else
            sortColumn = columnKey
            sortAscending = false
        end
        ProfilerUI:UpdateHeaderArrows()
        ProfilerUI:UpdateData()
    end)

    btn.columnKey = columnKey
    return btn
end

function ProfilerUI:CreateUI()
    if self.frame then return end

    local frame = CreateFrame("Frame", "BDTProfilerFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(500, 500)
    frame:SetPoint("CENTER", UIParent, "CENTER", -200, 0)

    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(150)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    frame.title = frame:CreateFontString(nil, "OVERLAY")
    frame.title:SetFontObject("GameFontHighlight")
    frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0)
    frame.title:SetText("Addon Profiler")

    local infoText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -35)
    infoText:SetText("Updates automatically. Click column headers to sort.")
    infoText:SetTextColor(0.7, 0.7, 0.7)

    -- Column headers
    local headerY = -50
    local nameHeader = CreateColumnHeader(frame, "Addon", 240, "TOPLEFT", frame, "TOPLEFT", 25, headerY, nil)
    nameHeader:Disable()
    nameHeader.label:SetTextColor(0.8, 0.8, 0.2)

    self.cpuHeader = CreateColumnHeader(frame, "CPU", 80, "LEFT", nameHeader, "RIGHT", 0, 0, SORT_CPU)
    self.cpuHeader.label:SetTextColor(0.8, 0.8, 0.2)

    self.memHeader = CreateColumnHeader(frame, "MEM", 80, "LEFT", self.cpuHeader, "RIGHT", 0, 0, SORT_MEM)
    self.memHeader.label:SetTextColor(0.8, 0.8, 0.2)

    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, headerY - 22)
    scrollFrame:SetSize(450, 400)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(450, 400)
    scrollFrame:SetScrollChild(content)

    self.frame = frame
    self.content = content
    self.addonRows = {}

    self:UpdateHeaderArrows()

    local updateInterval = 1.0
    local timeSinceLastUpdate = 0
    frame:SetScript("OnUpdate", function(self, elapsed)
        timeSinceLastUpdate = timeSinceLastUpdate + elapsed
        if timeSinceLastUpdate >= updateInterval then
            timeSinceLastUpdate = 0
            if frame:IsShown() then
                ProfilerUI:UpdateData()
            end
        end
    end)
end

function ProfilerUI:UpdateHeaderArrows()
    local arrow = sortAscending and " ^" or " v"
    self.cpuHeader.arrow:SetText(sortColumn == SORT_CPU and arrow or "")
    self.memHeader.arrow:SetText(sortColumn == SORT_MEM and arrow or "")
end

function ProfilerUI:UpdateData()
    if not GetCVarBool("scriptProfile") then
        self.frame:Hide()
        print("BDT: Script Profiling is currently disabled. Profiler closed.")
        return
    end

    UpdateAddOnCPUUsage()
    UpdateAddOnMemoryUsage()

    local addonData = {}

    local numAddons = C_AddOns and C_AddOns.GetNumAddOns and C_AddOns.GetNumAddOns() or GetNumAddOns()

    for i = 1, numAddons do
        local name, title, notes, loadable, reason, security, newVersion
        if C_AddOns and C_AddOns.GetAddOnInfo then
            name, title, notes, loadable, reason, security, newVersion = C_AddOns.GetAddOnInfo(i)
        else
            name, title, notes, loadable, reason, security, newVersion = GetAddOnInfo(i)
        end

        local loaded = false
        if C_AddOns and C_AddOns.IsAddOnLoaded then
            loaded = C_AddOns.IsAddOnLoaded(i)
        else
            loaded = IsAddOnLoaded(i)
        end

        if loaded then
            local cpuUsage = GetAddOnCPUUsage(i)
            local memUsage = GetAddOnMemoryUsage(i)
            table.insert(addonData, {
                index = i,
                name = title or name,
                cpu = cpuUsage,
                mem = memUsage,
            })
        end
    end

    local col = sortColumn
    if sortAscending then
        table.sort(addonData, function(a, b) return a[col] < b[col] end)
    else
        table.sort(addonData, function(a, b) return a[col] > b[col] end)
    end

    self:RefreshUI(addonData)
end

function ProfilerUI:RefreshUI(data)
    for _, row in pairs(self.addonRows) do
        row:Hide()
    end

    local maxResults = #data
    local yOffset = -5
    local contentHeight = 0

    for i = 1, maxResults do
        local item = data[i]
        local row = self.addonRows[i]

        if not row then
            row = CreateFrame("Frame", nil, self.content)
            row:SetSize(430, 20)

            row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.nameText:SetPoint("LEFT", row, "LEFT", 5, 0)
            row.nameText:SetWidth(240)
            row.nameText:SetJustifyH("LEFT")
            row.nameText:SetWordWrap(false)

            row.cpuText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            row.cpuText:SetPoint("LEFT", row, "LEFT", 245, 0)
            row.cpuText:SetWidth(80)
            row.cpuText:SetJustifyH("RIGHT")

            row.memText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            row.memText:SetPoint("LEFT", row, "LEFT", 330, 0)
            row.memText:SetWidth(80)
            row.memText:SetJustifyH("RIGHT")

            local highlight = row:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetAllPoints(row)
            highlight:SetColorTexture(1, 1, 1, 0.1)

            self.addonRows[i] = row
        end

        row.nameText:SetText(item.name)
        row.nameText:SetTextColor(1, 1, 1)

        -- Color code the CPU value
        local cpuStr = string.format("%.2f ms", item.cpu)
        if item.cpu > 50 then
            row.cpuText:SetTextColor(1, 0.2, 0.2)
        elseif item.cpu > 10 then
            row.cpuText:SetTextColor(1, 0.8, 0.2)
        else
            row.cpuText:SetTextColor(0.2, 1, 0.2)
        end
        row.cpuText:SetText(cpuStr)

        -- Color code the MEM value
        local memStr = FormatMemory(item.mem)
        if item.mem > 10240 then
            row.memText:SetTextColor(1, 0.2, 0.2)
        elseif item.mem > 1024 then
            row.memText:SetTextColor(1, 0.8, 0.2)
        else
            row.memText:SetTextColor(0.2, 1, 0.2)
        end
        row.memText:SetText(memStr)

        row:SetPoint("TOPLEFT", self.content, "TOPLEFT", 10, yOffset)
        row:Show()

        yOffset = yOffset - 22
        contentHeight = contentHeight + 22
    end

    self.content:SetHeight(math.max(contentHeight, self.frame:GetHeight() - 80))
end


function ProfilerUI:Show()
    if not GetCVarBool("scriptProfile") then
        print("BDT: Script Profiling must be enabled to view CPU usage. Type /bdt profile to reload with it enabled.")
        return
    end

    if not self.frame then
        self:CreateUI()
    end

    self:UpdateData()
    self.frame:Show()
end

function ProfilerUI:Hide()
    if self.frame then
        self.frame:Hide()
    end
end
