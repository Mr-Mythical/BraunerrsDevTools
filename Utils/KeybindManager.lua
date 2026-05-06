--[[
KeybindManager.lua - Manages keybinds for development tools

Purpose: Handles keybind registration, event processing, and state management for reload UI functionality
Dependencies: BDT.DevMode, BDT.db
Author: braunerr
--]]

local _, BDT = ...
local KeybindManager = {}
BDT.KeybindManager = KeybindManager

local devBindings = {}

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

    if BDT.db.disableReloadWhileTyping and GetCurrentKeyBoardFocus() ~= nil then
        return false
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

    local function reloadAction()
        if BDT.Actions then
            BDT.Actions.ReloadUI()
        else
            ReloadUI()
        end
    end

    if allowR then devBindings["R"] = reloadAction end
    if allowCTRL then devBindings["CTRL-R"] = reloadAction end
    if allowSHIFT then devBindings["SHIFT-R"] = reloadAction end
    if allowALT then devBindings["ALT-R"] = reloadAction end

    if enabled then
        frame:EnableKeyboard(true)
    else
        frame:EnableKeyboard(false)
    end
end
