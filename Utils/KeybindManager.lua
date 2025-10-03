--[[
KeybindManager.lua - Manages keybinds for development tools

Purpose: Handles keybind registration, event processing, and state management for reload UI functionality
Dependencies: BDT.Config, BDT.DevMode, BDT.db
Author: braunerr
--]]

local _, BDT = ...
local KeybindManager = {}
BDT.KeybindManager = KeybindManager

local devBindings = BDT.Config.devBindings

local frame = nil

function KeybindManager:Initialize()
    self:CreateEventFrame()
    self:UpdateBindingsState()
end

function KeybindManager:CreateEventFrame()
    if frame then return end
    
    frame = CreateFrame("Frame", "BDTKeyBindFrame", UIParent)
    frame:SetScript("OnKeyDown", function(self, key)
        KeybindManager:HandleKeyPress(key)
    end)
    frame:EnableKeyboard(false)
    frame:SetPropagateKeyboardInput(true)
end

function KeybindManager:HandleKeyPress(key)
    if not BDT.DevMode:IsEnabled() then
        return false
    end
    
    if InCombatLockdown() then
        return false
    end
    
    if not BDT.DevMode:IsEnabled() then
        return false
    end
    
    if InCombatLockdown() then
        return false
    end
    
    local reloadBehavior = BDT.db.reloadKeybindBehavior or "disable_while_typing"
    local isTyping = GetCurrentKeyBoardFocus() ~= nil

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
        if frame then
            frame:SetPropagateKeyboardInput(false)
        end
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

    if enabled then
        frame:EnableKeyboard(true)
    else
        frame:EnableKeyboard(false)
    end
end
