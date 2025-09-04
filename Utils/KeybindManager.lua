--[[
KeybindManager.lua - Manages keybinds for development tools

Purpose: Handles keybind registration, event processing, and state management for reload UI functionality
Dependencies: BDT.DevMode, BDT.db
Author: braunerr
--]]

local _, BDT = ...
local KeybindManager = {}
BDT.KeybindManager = KeybindManager

local devBindings = {
    ["CTRL-R"] = function() ReloadUI() end,
}

local originalBindings = {}
local frame = nil

--- Initializes the keybind manager
--- Sets up global binding names and creates the event frame
function KeybindManager:Initialize()
    self:CreateEventFrame()
    self:UpdateBindingsState()
end

--- Creates the event frame for handling key presses
--- Sets up keyboard event handling with proper propagation control
function KeybindManager:CreateEventFrame()
    if frame then return end
    
    frame = CreateFrame("Frame", "BDTKeyBindFrame", UIParent)
    frame:SetScript("OnKeyDown", function(self, key)
        KeybindManager:HandleKeyPress(key)
    end)
    frame:EnableKeyboard(false)
    frame:SetPropagateKeyboardInput(true)
end

--- Handles key press events for reload functionality
--- @param key string The key that was pressed
--- @return boolean Whether the key was handled (affects propagation)
function KeybindManager:HandleKeyPress(key)
    if not BDT.DevMode:IsEnabled() then
        return false
    end
    
    if InCombatLockdown() then
        return false
    end
    
    local reloadBehavior = BDT.db.reloadKeybindBehavior or "disable_while_typing"
    local isTyping = GetCurrentKeyBoardFocus() ~= nil

    -- Determine which keybinds are allowed based on the reload behavior setting
    if reloadBehavior == "disable_while_typing" and isTyping then
        return false
    end

    if reloadBehavior == "disable_r_shift_r_while_typing" and isTyping then
        local isCtrl = IsControlKeyDown()
        local isAlt = IsAltKeyDown()
        local isShift = IsShiftKeyDown()
        if key == "R" and not isCtrl and not isAlt then
            -- Only shift or no modifier
            if not isShift or (isShift and not isCtrl and not isAlt) then
                return false
            end
        end
    end
    
    if not BDT.db.enableReloadUIKeybind then
        return false
    end
    
    local modifiers = ""
    if IsControlKeyDown() then modifiers = modifiers .. "CTRL-" end
    if IsShiftKeyDown() then modifiers = modifiers .. "SHIFT-" end
    if IsAltKeyDown() then modifiers = modifiers .. "ALT-" end
    
    local fullKey = modifiers .. key
    local action = devBindings[fullKey] or devBindings[key]
    
    if action then
        frame:SetPropagateKeyboardInput(false)
        action()
        C_Timer.After(0.01, function()
            if frame then
                frame:SetPropagateKeyboardInput(true)
            end
        end)
        return true
    end
    
    return false
end

--- Updates the keybind state based on user settings
--- Rebuilds the devBindings table and enables/disables the frame accordingly
function KeybindManager:UpdateBindingsState()
    if not frame then return end
    local enabled = BDT.DevMode:IsEnabled()
    local allowR = BDT.db.reloadUIR
    local allowCTRL = BDT.db.reloadUICTRL
    local allowSHIFT = BDT.db.reloadUISHIFT
    local allowALT = BDT.db.reloadUIALT
    devBindings = {}

    if allowR then devBindings["R"] = function() ReloadUI() end end
    if allowCTRL then devBindings["CTRL-R"] = function() ReloadUI() end end
    if allowSHIFT then devBindings["SHIFT-R"] = function() ReloadUI() end end
    if allowALT then devBindings["ALT-R"] = function() ReloadUI() end end

    -- Enable/disable the frame based on at least one keybind being enabled
    if enabled then
        frame:EnableKeyboard(true)
    else
        frame:EnableKeyboard(false)
    end
end
