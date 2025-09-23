-- DebugUI.lua
-- UI for displaying and searching global variables

local DebugUI = {}

function DebugUI:Show()
    if not frame then
        self:CreateUI()
    end
    frame:Show()
    self:UpdateList()
end

function DebugUI:CreateUI()
    frame = CreateFrame("Frame", "BraunerrsDevToolsDebugUI", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(500, 600) -- Wider frame
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("HIGH") -- Make window appear on top
    frame:SetFrameLevel(100) -- High frame level
    frame:Hide()

    frame.title = frame:CreateFontString(nil, "OVERLAY")
    frame.title:SetFontObject("GameFontHighlight")
    frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0)
    frame.title:SetText("Debug Variables (Booleans Only)")

    -- Add instructions label
    local instructions = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    instructions:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -35)
    instructions:SetText("Click to register/unregister for dev mode toggle")
    instructions:SetTextColor(0.7, 0.7, 0.7) -- Light gray color

    searchBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    searchBox:SetSize(250, 30) -- Wider search box
    searchBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -55) -- Moved down to make room for instructions
    searchBox:SetAutoFocus(false)
    searchBox:SetScript("OnTextChanged", function()
        DebugUI:UpdateList()
    end)

    scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", 0, -10)
    scrollFrame:SetSize(460, 460) -- Slightly shorter to account for instructions

    content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(460, 460)
    scrollFrame:SetScrollChild(content)

    frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
end

function DebugUI:UpdateList()
    local filter = searchBox:GetText():lower()
    local y = -5
    for i, child in ipairs({content:GetChildren()}) do
        child:Hide()
    end
    local index = 1
    local maxResults = 100 -- Limit results to prevent stack overflow
    local resultCount = 0
    
    for k, v in pairs(_G) do
        if resultCount >= maxResults then
            break
        end
        -- Only show boolean variables (like Core.lua functions)
        if type(k) == "string" and type(v) == "boolean" and k:lower():find(filter) then
            -- Skip internal WoW globals that start with underscore or are known system variables
            if not k:find("^_") and not k:find("^SLASH_") and not k:find("^BINDING_") then
                local btn = content["var"..index]
                if not btn then
                    btn = CreateFrame("Button", nil, content)
                    btn:SetSize(440, 20) -- Wider buttons to match new content width
                    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    btn.text:SetPoint("LEFT")
                    
                    -- Set up highlight texture for hover effect
                    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
                    highlight:SetAllPoints(btn)
                    highlight:SetColorTexture(1, 1, 0, 0.1) -- Subtle yellow highlight
                    
                    content["var"..index] = btn
                end
                
                -- Enable left-click handling
                btn:RegisterForClicks("LeftButtonUp")
                
                -- Update click handlers for this specific variable
                btn:SetScript("OnClick", function(self, button)
                    if button == "LeftButton" then
                        DebugUI:OnVariableClick(k, v)
                    end
                end)
                
                -- Format the display text
                local status = v and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"
                local displayText = k .. " - " .. status
                local BDT = _G["BraunerrsDevTools"]
                if BDT and BDT.db and BDT.db.devModeToggleVariables and BDT.db.devModeToggleVariables[k] then
                    displayText = displayText .. " [REGISTERED]"
                end
                
                btn:SetPoint("TOPLEFT", 10, y)
                btn.text:SetText(displayText)
                btn.text:SetTextColor(1, 1, 1) -- Ensure default color is white
                btn:Show()
                y = y - 22
                index = index + 1
                resultCount = resultCount + 1
            end
        end
    end
    
    -- Show message if results were limited
    if resultCount >= maxResults then
        local btn = content["var"..index]
        if not btn then
            btn = CreateFrame("Button", nil, content)
            btn:SetSize(440, 20) -- Wider buttons to match new content width
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

function DebugUI:OnVariableClick(varName, varValue)
    -- Handle registration/unregistration on left-click
    if type(varValue) ~= "boolean" then return end
    
    -- Access BDT through global table
    local BDT = _G["BraunerrsDevTools"]
    if not BDT then
        print("BDT: Error - BraunerrsDevTools global not found")
        return
    end
    
    -- Ensure the database exists
    if not BDT.db then
        print("BDT: Error - BDT.db not found")
        return
    end
    
    -- Ensure the devModeToggleVariables table exists
    if not BDT.db.devModeToggleVariables then
        BDT.db.devModeToggleVariables = {}
    end
    
    if BDT.db.devModeToggleVariables[varName] then
        -- Unregister
        BDT.db.devModeToggleVariables[varName] = nil
        print("BDT: Unregistered '" .. varName .. "' from dev mode toggle")
        
        -- If dev mode is active, turn off the variable
        if BDT.DevMode and BDT.DevMode:IsEnabled() then
            _G[varName] = false
            print("BDT: Set '" .. varName .. "' to false (dev mode active)")
        end
    else
        -- Register
        BDT.db.devModeToggleVariables[varName] = {
            description = "Dev mode toggle: " .. varName,
            category = "Dev Mode Toggle",
            registeredAt = time()
        }
        print("BDT: Registered '" .. varName .. "' for dev mode toggle")
        
        -- If dev mode is already active, toggle the variable to true
        if BDT.DevMode and BDT.DevMode:IsEnabled() then
            _G[varName] = true
            print("BDT: Set '" .. varName .. "' to true (dev mode active)")
        end
    end
    
    -- Update the dev mode variables UI if it's open
    if BDT.DevMode and BDT.DevMode.UpdateVariablesUI then
        BDT.DevMode:UpdateVariablesUI()
    end
    
    self:UpdateList()
end

BraunerrsDevTools_DebugUI = DebugUI
