local addonName, BDT = ...
_G["BraunerrDevTools"] = BDT

BDT = BDT or {}

local defaults = {
    devMode = false,
    enableBugSackIntegration = true,
    enableReloadUIKeybind = true,
    enableAutoAFK = true,
    hasLoaded = false,
    bugSackOriginalAutoPopup = nil,
}

local eventFrame = CreateFrame("Frame")

local function InitializeSettings()
    BraunerrDevToolsDB = BraunerrDevToolsDB or {}
    for k, v in pairs(defaults) do
        if BraunerrDevToolsDB[k] == nil then
            BraunerrDevToolsDB[k] = v
        end
    end
    BDT.db = BraunerrDevToolsDB
end

local function Initialize()
    InitializeSettings()
    
    BDT.DevMode:Initialize()
    BDT.KeybindManager:Initialize()
    BDT.Options:Initialize()
    
    if not BDT.db.hasLoaded then
        print("BDT: Loaded! Use /bdt to toggle dev mode")
        BDT.db.hasLoaded = true
    end
end

function BDTToggleDevMode()
    if BDT and BDT.DevMode then
        BDT.DevMode:Toggle()
    end
end

eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        Initialize()
    end
end)

SLASH_BRAUNERRDEVTOOLS1 = "/bdt"
SLASH_BRAUNERRDEVTOOLS2 = "/braunerrdev"
SlashCmdList["BRAUNERRDEVTOOLS"] = function(msg)
    msg = msg:lower()
    if msg == "devmode" or msg == "dev" or msg == "" then
        BDT.DevMode:Toggle()
    else
        print("BDT: Use /bdt to toggle dev mode")
    end
end
