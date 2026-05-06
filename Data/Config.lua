--[[
Config.lua - Configuration data and defaults

Purpose: Provides the shared config namespace for addon modules
Dependencies: None
Author: braunerr
--]]

local _, BDT = ...

BDT.Config = BDT.Config or {}

local Config = BDT.Config

Config.schemaVersion = 1

Config.defaults = {
	schemaVersion = Config.schemaVersion,
	devMode = false,
	enableBugSackIntegration = true,
	enableReloadUIKeybind = true,
	enableAutoAFK = true,
	hasLoaded = false,
	bugSackOriginalAutoPopup = nil,
	devModeToggleVariables = {},
	reloadUIR = false,
	reloadUICTRL = true,
	reloadUISHIFT = false,
	reloadUIALT = false,
	reloadUIOnDevModeToggle = false,
	disableReloadWhileTyping = true,
	hideInterfaceVersionInDevMode = false,
	gridEnabled = false,
	gridSize = 64,
	mouseCoordsEnabled = false,
	quickActionsUI = {},
	variablesUI = {},
	mouseCoordsUI = {},
}

Config.defaultFramePositions = {
	quickActionsUI = { "CENTER", "UIParent", "CENTER", 350, 0 },
	variablesUI = { "CENTER", "UIParent", "CENTER", 0, 0 },
	mouseCoordsUI = { "BOTTOM", "UIParent", "BOTTOM", 0, 100 },
}

Config.managedFrames = {
	{ key = "quickActionsUI", frameName = "BDTQuickActionsFrame", defaultPoint = Config.defaultFramePositions.quickActionsUI },
	{ key = "variablesUI", frameName = "BDTSettingsFrame", defaultPoint = Config.defaultFramePositions.variablesUI },
	{ key = "mouseCoordsUI", frameName = "BDT_MouseCoordsOverlay", defaultPoint = Config.defaultFramePositions.mouseCoordsUI },
}

local function MigrateReloadTypingBehavior(db)
	if db.disableReloadWhileTyping ~= nil then
		return
	end

	if db.reloadKeybindBehavior == "allow_while_typing" then
		db.disableReloadWhileTyping = false
	elseif db.reloadKeybindBehavior ~= nil then
		db.disableReloadWhileTyping = true
	end
end
function Config.MigrateDB(db)
	if type(db) ~= "table" then
		return
	end

	local schemaVersion = tonumber(db.schemaVersion) or 0

	if schemaVersion < 1 then
		MigrateReloadTypingBehavior(db)
		db.schemaVersion = Config.schemaVersion
	end
end
