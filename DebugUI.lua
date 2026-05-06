--[[
DebugUI.lua - Debug variable browser and registration UI

Purpose: Displays global boolean variables and lets users register/unregister them for dev mode auto-toggle
Dependencies: BDT.db, BDT.DevMode
Author: braunerr
--]]

local _, BDT = ...

local DebugUI = {}
local frame, searchBox, scrollFrame, content

function DebugUI:Show()
    if not frame then
        self:CreateUI()
    end
    frame:Show()
    self:UpdateList()
end

function DebugUI:CreateUI()
    frame = CreateFrame("Frame", "BraunerrsDevToolsDebugUI", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(500, 600)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(100)
    frame:Hide()

    frame.title = frame:CreateFontString(nil, "OVERLAY")
    frame.title:SetFontObject("GameFontHighlight")
    frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0)
    frame.title:SetText("Debug Variables (Booleans Only)")

    local instructions = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    instructions:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -35)
    instructions:SetText("Click to register/unregister for dev mode toggle")
    instructions:SetTextColor(0.7, 0.7, 0.7)

    searchBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    searchBox:SetSize(250, 30)
    searchBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -55)
    searchBox:SetAutoFocus(false)
    searchBox:SetScript("OnTextChanged", function()
        DebugUI:UpdateList()
    end)

    scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", 0, -10)
    scrollFrame:SetSize(460, 460)

    content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(460, 460)
    scrollFrame:SetScrollChild(content)

    frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
end

function DebugUI:UpdateList()
    local filter = searchBox:GetText():lower()
    local y = -5
    for _, child in ipairs({content:GetChildren()}) do
        child:Hide()
    end
    local index = 1
    local maxResults = 100
    local resultCount = 0
    
    for k, v in pairs(_G) do
        if resultCount >= maxResults then
            break
        end
        if type(k) == "string" and type(v) == "boolean" and k:lower():find(filter) then
            if not k:find("^_") and not k:find("^SLASH_") and not k:find("^BINDING_") then
                local btn = content["var"..index]
                if not btn then
                    btn = CreateFrame("Button", nil, content)
                    btn:SetSize(440, 20)
                    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    btn.text:SetPoint("LEFT")
                    
                    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
                    highlight:SetAllPoints(btn)
                    highlight:SetColorTexture(1, 1, 0, 0.1)
                    
                    content["var"..index] = btn
                end
                
                btn:RegisterForClicks("LeftButtonUp")
                
                btn:SetScript("OnClick", function(self, button)
                    if button == "LeftButton" then
                        DebugUI:OnVariableClick(k)
                    end
                end)
                
                local status = v and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"
                local displayText = k .. " - " .. status
                if BDT.VariableManager and BDT.VariableManager:IsRegisteredForDevModeToggle(k) then
                    displayText = displayText .. " [REGISTERED]"
                end
                
                btn:SetPoint("TOPLEFT", 10, y)
                btn.text:SetText(displayText)
                btn.text:SetTextColor(1, 1, 1)
                btn:Show()
                y = y - 22
                index = index + 1
                resultCount = resultCount + 1
            end
        end
    end
    
    if resultCount >= maxResults then
        local btn = content["var"..index]
        if not btn then
            btn = CreateFrame("Button", nil, content)
            btn:SetSize(440, 20)
            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            btn.text:SetPoint("LEFT")
            content["var"..index] = btn
        end
        btn:SetPoint("TOPLEFT", 10, y)
        btn.text:SetText("... (showing first " .. maxResults .. " results)")
        btn:Show()
        y = y - 22
    end
    
    content:SetHeight(math.abs(y))
end

function DebugUI:OnVariableClick(varName)
    if type(_G[varName]) ~= "boolean" then return end

    if not BDT.VariableManager then
        print("BDT: Variable manager not available")
        return
    end

    BDT.VariableManager:ToggleDevModeVariableRegistration(varName)
    
    self:UpdateList()
end

BraunerrsDevTools_DebugUI = DebugUI
