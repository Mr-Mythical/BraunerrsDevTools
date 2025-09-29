--[[
DevMode.lua - Development mode management

Purpose: Handles dev mode state, UI indicators, addon integrations, and combat safety
Dependencies: BDT.db, BDT.KeybindManager
Author: braunerr
--]]

local _, BDT = ...
local DevMode = {}
BDT.DevMode = DevMode

local DevMode = BDT.DevMode

function DevMode:Initialize()
    self.isEnabled = BDT.db.devMode
    self:CreateStatusIndicator()
    self:UpdateIndicator()
    self:RegisterCombatEvents()
    
    if self.isEnabled then
        self:UpdateAddonIntegrations()
    end
end

function DevMode:RegisterCombatEvents()
    if not self.combatFrame then
        self.combatFrame = CreateFrame("Frame")
        self.combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
        self.combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        self.combatFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        
        self.combatFrame:SetScript("OnEvent", function(self, event)
            if event == "PLAYER_REGEN_DISABLED" then
                DevMode:OnEnterCombat()
            elseif event == "PLAYER_REGEN_ENABLED" then
                DevMode:OnLeaveCombat()
            elseif event == "PLAYER_ENTERING_WORLD" then
                DevMode:OnPlayerEnteringWorld()
            end
        end)
    end
end

function DevMode:OnEnterCombat()
    if self.isEnabled then
        self.wasEnabledBeforeCombat = true
        
        if BDT.db.enableAutoAFK and UnitIsAFK("player") then
            -- Todo: this is depcrecated
            SendChatMessage("", "AFK")
        end
        
        self.isEnabled = false
        BDT.db.devMode = false
        
        self:UpdateAddonIntegrations()
        BDT.KeybindManager:UpdateBindingsState()
        self:UpdateIndicator()
        
        print("BDT: Dev mode disabled - entered combat")
    end
end

function DevMode:OnLeaveCombat()
    if self.wasEnabledBeforeCombat then
        self.wasEnabledBeforeCombat = false
    end
end

function DevMode:OnPlayerEnteringWorld()
    if self.isEnabled and self.settingsFrame and self.settingsFrame:IsShown() then
        C_Timer.After(0.5, function()
            if DevMode.settingsFrame and DevMode.settingsFrame:IsShown() then
                DevMode:UpdateVariablesUI()
            end
        end)
    end
end

--- Creates the status indicator frame
--- Shows dev mode status at the top of the screen
function DevMode:CreateStatusIndicator()
    local frame = CreateFrame("Frame", "BDTStatusFrame", UIParent)
    frame:SetSize(350, 30)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -10)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(100)
    
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(frame)
    bg:SetColorTexture(0, 0, 0, 0.7)
    
    local border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    border:SetAllPoints(frame)
    border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
    })
    border:SetBackdropBorderColor(1, 0.5, 0, 1)
    
        frame.statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        frame.statusText:SetPoint("CENTER", frame, "CENTER", 0, 0)
        frame.statusText:SetTextColor(1, 0.5, 0, 1)
        frame.statusText:SetText("DEV MODE ACTIVE")
    
    local icon = frame:CreateTexture(nil, "OVERLAY")
    icon:SetSize(20, 20)
    icon:SetPoint("LEFT", frame, "LEFT", 10, 0)
    icon:SetTexture("Interface\\AddOns\\BraunerrsDevTools\\LogoTransparent")
    
    frame:Hide()
    self.statusFrame = frame
end

--- Updates the status indicator visibility and animation
--- Shows/hides and animates based on dev mode state
function DevMode:UpdateIndicator()
    if not self.statusFrame then return end
    
    if self.isEnabled then
        self.statusFrame:Show()
        if not self.statusFrame.pulse then
            self.statusFrame.pulse = self.statusFrame:CreateAnimationGroup()
            local fade = self.statusFrame.pulse:CreateAnimation("Alpha")
            fade:SetFromAlpha(1)
            fade:SetToAlpha(0.3)
            fade:SetDuration(1.5)
            fade:SetSmoothing("IN_OUT")
            self.statusFrame.pulse:SetLooping("BOUNCE")
        end
        self.statusFrame.pulse:Play()
            -- Display interface version
            local _, _, _, interfaceVersion = GetBuildInfo()
            if self.statusFrame.statusText then
                self.statusFrame.statusText:SetText("DEV MODE ACTIVE | Interface: " .. tostring(interfaceVersion))
            end
        -- Auto-show variables UI when dev mode is enabled
        self:ShowVariablesUI()
    else
        self.statusFrame:Hide()
        if self.statusFrame.pulse then
            self.statusFrame.pulse:Stop()
        end
        -- Hide variables UI when dev mode is disabled
        if self.settingsFrame then
            self.settingsFrame:Hide()
        end
    end
end

--- Toggles development mode on/off
--- Updates all related systems and provides user feedback
function DevMode:Toggle()
    if InCombatLockdown() and not self.isEnabled then
        print("BDT: Cannot enable dev mode while in combat")
        return
    end
    
    self.isEnabled = not self.isEnabled
    BDT.db.devMode = self.isEnabled
    
    self:HandleAFKStatus()
    self:UpdateAddonIntegrations()
    BDT.KeybindManager:UpdateBindingsState()
    self:UpdateIndicator()
    
    -- Handle UI reload option
    if BDT.db.reloadUIOnDevModeToggle then
        local state = self.isEnabled and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"
        print("BDT: Development mode " .. state .. " - Reloading UI...")
        ReloadUI()
        return
    end
    
    local state = self.isEnabled and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"
    print("BDT: Development mode " .. state)
end

--- Updates all addon integrations
--- Handles BugSack and debug variable integrations
function DevMode:UpdateAddonIntegrations()
    self:HandleBugSackIntegration()
    self:HandleAddonDebugIntegration()
end

--- Handles AFK status based on dev mode
--- Sets or clears AFK to avoid interruptions during development
function DevMode:HandleAFKStatus()
    if not BDT.db.enableAutoAFK then
        return
    end
    
    if self.isEnabled then
        if not UnitIsAFK("player") then
            SendChatMessage("", "AFK")
        end
    else
        if UnitIsAFK("player") then
            SendChatMessage("", "AFK")
        end
    end
end

--- Handles BugSack integration
--- Automatically enables BugSack error popups when dev mode is active
function DevMode:HandleBugSackIntegration()
    if not BDT.db.enableBugSackIntegration then
        return
    end
    
    local isBugSackLoaded = false
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        isBugSackLoaded = C_AddOns.IsAddOnLoaded("BugSack")
    elseif IsAddOnLoaded then
        isBugSackLoaded = IsAddOnLoaded("BugSack")
    else
        isBugSackLoaded = (_G.BugSack ~= nil)
    end
    
    if not isBugSackLoaded then
        return
    end
    
    local bugSackDB = _G.BugSackDB
    if not bugSackDB then
        return
    end
    
    if self.isEnabled then
        if BDT.db.bugSackOriginalAutoPopup == nil then
            BDT.db.bugSackOriginalAutoPopup = bugSackDB.auto or false
        end
        bugSackDB.auto = true
    else
        if BDT.db.bugSackOriginalAutoPopup ~= nil then
            bugSackDB.auto = BDT.db.bugSackOriginalAutoPopup
            BDT.db.bugSackOriginalAutoPopup = nil
        end
    end
end

--- Handles addon debug integration
--- Enables/disables registered debug variables based on dev mode state
function DevMode:HandleAddonDebugIntegration()
    if not BDT.db.enableAddonDebugIntegration then
        return
    end
    
    if self.isEnabled then
        BDTEnableDevModeVariables()
    else
        BDTDisableDevModeVariables()
    end
end

--- Checks if dev mode is currently enabled
--- @return boolean Whether dev mode is active
function DevMode:IsEnabled()
    return self.isEnabled
end

function DevMode:CreateVariablesUI()
    if self.settingsFrame then return end
    
    local frame = CreateFrame("Frame", "BDTSettingsFrame", UIParent, "BackdropTemplate")
    frame:SetSize(400, 200)
    
    if BDT.db and BDT.db.variablesUI and BDT.db.variablesUI.point then
        local saved = BDT.db.variablesUI.point
        local point, parent, relativePoint, xOfs, yOfs
        if #saved == 5 then
            point, parent, relativePoint, xOfs, yOfs = unpack(saved)
        elseif #saved == 4 then
            point, relativePoint, xOfs, yOfs = unpack(saved)
            parent = "UIParent"
        end
        if point and parent and relativePoint and type(xOfs) == "number" and type(yOfs) == "number" then
            local parentFrame = _G[parent] or UIParent
            frame:SetPoint(point, parentFrame, relativePoint, xOfs, yOfs)
        else
            frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(200)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        DevMode:SaveVariablesUIPosition()
    end)
    
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        tile = true, tileSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -16)
    title:SetText("Active Debug Variables")
    title:SetTextColor(1, 0.5, 0, 1)
    
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)
    
    local debugUIButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    debugUIButton:SetSize(100, 25)
    debugUIButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -15)
    debugUIButton:SetText("Debug UI")
    debugUIButton:SetScript("OnClick", function()
        if DevTools and DevTools.DebugUI then
            DevTools.DebugUI:Show()
        else
            print("BDT: Debug UI not available")
        end
    end)
    
    self.variablesTexts = {}
    
    frame:Hide()
    self.settingsFrame = frame
end

function DevMode:SaveVariablesUIPosition()
    if not self.settingsFrame then return end
    
    -- Ensure saved variables table exists
    if not BDT.db.variablesUI then
        BDT.db.variablesUI = {}
    end
    
    -- Save the current position
    local point, relativeTo, relativePoint, xOfs, yOfs = self.settingsFrame:GetPoint()
    local parentName = "UIParent"
    BDT.db.variablesUI.point = {point, parentName, relativePoint, xOfs, yOfs}
end

function DevMode:UpdateVariablesUI()
    if not self.settingsFrame then return end
    
    local frame = self.settingsFrame
    local yOffset = -70  -- Start below the title and button
    local totalHeight = 90  -- Base height for title, button and padding
    
    for _, text in ipairs(self.variablesTexts) do
        text:Hide()
    end
    self.variablesTexts = {}
    
    local hasVariables = false
    
    -- Dev mode toggle variables
    if BDT.db.devModeToggleVariables and next(BDT.db.devModeToggleVariables) then
        local devModeTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        devModeTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, yOffset)
        devModeTitle:SetText("Dev Mode Auto-Toggle:")
        devModeTitle:SetTextColor(0.8, 0.8, 1, 1)
        table.insert(self.variablesTexts, devModeTitle)
        yOffset = yOffset - 20
        totalHeight = totalHeight + 20
        
        for varName, info in pairs(BDT.db.devModeToggleVariables) do
            local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            text:SetPoint("TOPLEFT", frame, "TOPLEFT", 26, yOffset)
            local status = BDT.Utils.IsDebugVariableEnabled(varName) and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"
            local category = info.category and (" [" .. info.category .. "]") or ""
            text:SetText(varName .. category .. ": " .. status)
            text:SetTextColor(1, 1, 1, 1)
            table.insert(self.variablesTexts, text)
            yOffset = yOffset - 16
            totalHeight = totalHeight + 16
            hasVariables = true
        end
    end
    
    if not hasVariables then
        local noVarsText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noVarsText:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, yOffset)
        noVarsText:SetText("No registered variables")
        noVarsText:SetTextColor(0.5, 0.5, 0.5, 1)
        table.insert(self.variablesTexts, noVarsText)
        totalHeight = totalHeight + 16
    end
    
    totalHeight = totalHeight + 20
    totalHeight = math.max(totalHeight, 120)
    totalHeight = math.min(totalHeight, 600)
    
    frame:SetHeight(totalHeight)
end

function DevMode:ShowVariablesUI()
    if not self.settingsFrame then
        self:CreateVariablesUI()
    end
    
    self:UpdateVariablesUI()
    self.settingsFrame:Show()
end