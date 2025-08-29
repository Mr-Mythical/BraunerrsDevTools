local _, BDT = ...
local DevMode = {}
BDT.DevMode = DevMode

function DevMode:Initialize()
    self.isEnabled = BDT.db.devMode
    self:CreateStatusIndicator()
    self:UpdateIndicator()
    self:RegisterCombatEvents()
    
    -- Restore dev mode state on addon load
    if self.isEnabled then
        self:UpdateAddonIntegrations()
    end
end

function DevMode:RegisterCombatEvents()
    if not self.combatFrame then
        self.combatFrame = CreateFrame("Frame")
        self.combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
        self.combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        
        self.combatFrame:SetScript("OnEvent", function(self, event)
            if event == "PLAYER_REGEN_DISABLED" then
                DevMode:OnEnterCombat()
            elseif event == "PLAYER_REGEN_ENABLED" then
                DevMode:OnLeaveCombat()
            end
        end)
    end
end

function DevMode:OnEnterCombat()
    if self.isEnabled then
        self.wasEnabledBeforeCombat = true
        
        if BDT.db.enableAutoAFK and UnitIsAFK("player") then
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
    else
        self.statusFrame:Hide()
        if self.statusFrame.pulse then
            self.statusFrame.pulse:Stop()
        end
    end
end

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
    
    local state = self.isEnabled and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"
    print("BDT: Development mode " .. state)
end

function DevMode:UpdateAddonIntegrations()
    self:HandleBugSackIntegration()
    self:HandleAddonDebugIntegration()
end

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
        end
    end
end

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

function DevMode:IsEnabled()
    return self.isEnabled
end
