--[[
Config.lua - Configuration data and defaults

Purpose: Stores default settings, configuration options, and other addon data
Dependencies: None
Author: braunerr
--]]

local _, BDT = ...

BDT.Config = {
    devBindings = {
        ["CTRL-R"] = function() ReloadUI() end,
    }
}
