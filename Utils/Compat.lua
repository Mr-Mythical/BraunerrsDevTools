--[[
Compat.lua - Compatibility wrappers for WoW API differences and fragile calls

Purpose: Centralizes API variation across client flavors and protects calls that can error
Dependencies: None
Author: braunerr
--]]

local _, BDT = ...

BDT.Compat = BDT.Compat or {}

local Compat = BDT.Compat

local function SafeCall(func, ...)
    if type(func) ~= "function" then
        return false
    end

    return pcall(func, ...)
end

function Compat.GetNumAddOns()
    if C_AddOns and C_AddOns.GetNumAddOns then
        local success, count = SafeCall(C_AddOns.GetNumAddOns)
        if success and type(count) == "number" then
            return count
        end
    end

    local success, count = SafeCall(GetNumAddOns)
    if success and type(count) == "number" then
        return count
    end

    return 0
end

function Compat.GetAddOnInfo(index)
    if C_AddOns and C_AddOns.GetAddOnInfo then
        local success, name, title, notes, loadable, reason, security, newVersion = SafeCall(C_AddOns.GetAddOnInfo, index)
        if success then
            return name, title, notes, loadable, reason, security, newVersion
        end
    end

    local success, name, title, notes, loadable, reason, security, newVersion = SafeCall(GetAddOnInfo, index)
    if success then
        return name, title, notes, loadable, reason, security, newVersion
    end
end

function Compat.IsAddOnLoaded(addon)
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        local success, loaded = SafeCall(C_AddOns.IsAddOnLoaded, addon)
        if success then
            return loaded == true
        end
    end

    local success, loaded = SafeCall(IsAddOnLoaded, addon)
    if success then
        return loaded == true
    end

    return false
end

function Compat.UpdateAddOnCPUUsage()
    SafeCall(UpdateAddOnCPUUsage)
end

function Compat.UpdateAddOnMemoryUsage()
    SafeCall(UpdateAddOnMemoryUsage)
end

function Compat.GetAddOnCPUUsage(addon)
    local success, value = SafeCall(GetAddOnCPUUsage, addon)
    if success and type(value) == "number" then
        return value
    end

    return nil
end

function Compat.GetAddOnMemoryUsage(addon)
    local success, value = SafeCall(GetAddOnMemoryUsage, addon)
    if success and type(value) == "number" then
        return value
    end

    return nil
end
