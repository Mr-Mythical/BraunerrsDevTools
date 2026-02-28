local _, BDT = ...
local ProfilerUI = {}
BDT.ProfilerUI = ProfilerUI

function ProfilerUI:CreateUI()
    if self.frame then return end
    
    local frame = CreateFrame("Frame", "BDTProfilerFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(400, 500)
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
    frame.title:SetText("Addon CPU Profiler (ms)")
    
    -- BasicFrameTemplateWithInset already provides a CloseButton. We just need to make sure we don't create a second one.

    -- Info Text
    local infoText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -35)
    infoText:SetText("Updates automatically. Sorting by CPU usage (Descending)")
    infoText:SetTextColor(0.7, 0.7, 0.7)

    -- Scroll Frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -60)
    scrollFrame:SetSize(350, 420)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(350, 420)
    scrollFrame:SetScrollChild(content)

    self.frame = frame
    self.content = content
    self.addonRows = {}
    
    -- Update Loop
    local updateInterval = 1.0  -- Update every 1 second
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

function ProfilerUI:UpdateData()
    if not GetCVarBool("scriptProfile") then
        self.frame:Hide()
        print("BDT: Script Profiling is currently disabled. Profiler closed.")
        return
    end

    UpdateAddOnCPUUsage()

    local addonData = {}
    
    -- C_AddOns.GetNumAddOns() is the modern API
    local numAddons = C_AddOns and C_AddOns.GetNumAddOns and C_AddOns.GetNumAddOns() or GetNumAddOns()
    
    for i = 1, numAddons do
        -- C_AddOns.GetAddOnInfo is the modern API
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
            table.insert(addonData, {
                index = i,
                name = title or name,
                cpu = cpuUsage
            })
        end
    end
    
    table.sort(addonData, function(a, b)
        return a.cpu > b.cpu
    end)

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
            row:SetSize(330, 20)
            
            row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.nameText:SetPoint("LEFT", row, "LEFT", 5, 0)
            row.nameText:SetWidth(240)
            row.nameText:SetJustifyH("LEFT")
            row.nameText:SetWordWrap(false)
            
            row.cpuText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            row.cpuText:SetPoint("RIGHT", row, "RIGHT", -5, 0)
            row.cpuText:SetWidth(80)
            row.cpuText:SetJustifyH("RIGHT")
            
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
            row.cpuText:SetTextColor(1, 0.2, 0.2) -- Red for high CPU
        elseif item.cpu > 10 then
            row.cpuText:SetTextColor(1, 0.8, 0.2) -- Yellow for medium
        else
            row.cpuText:SetTextColor(0.2, 1, 0.2) -- Green for low
        end
        row.cpuText:SetText(cpuStr)
        
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
