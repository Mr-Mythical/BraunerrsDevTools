--[[
UI.lua - Shared UI helpers

Purpose: Saves, restores, and resets positions for BDT-created frames
Dependencies: BDT.Config, BDT.db
Author: braunerr
--]]

local _, BDT = ...

BDT.UI = BDT.UI or {}

local UI = BDT.UI

local function ResolveParent(parentName)
    if type(parentName) == "string" and _G[parentName] then
        return _G[parentName]
    end

    return UIParent
end

local function GetDefaultPoint(storageKey, defaultPoint)
    if defaultPoint then
        return defaultPoint
    end

    if BDT.Config and BDT.Config.defaultFramePositions then
        return BDT.Config.defaultFramePositions[storageKey]
    end
end

local function ApplyPoint(frame, pointData)
    if not frame or type(pointData) ~= "table" then
        return false
    end

    local point, parentName, relativePoint, xOfs, yOfs
    if #pointData == 5 then
        point, parentName, relativePoint, xOfs, yOfs = unpack(pointData)
    elseif #pointData == 4 then
        point, relativePoint, xOfs, yOfs = unpack(pointData)
        parentName = "UIParent"
    end

    if point and relativePoint and type(xOfs) == "number" and type(yOfs) == "number" then
        frame:SetPoint(point, ResolveParent(parentName), relativePoint, xOfs, yOfs)
        return true
    end

    return false
end

function UI.RestoreFramePosition(frame, storageKey, defaultPoint)
    if not frame then
        return
    end

    frame:ClearAllPoints()

    local savedPoint
    if BDT.db and BDT.db[storageKey] then
        savedPoint = BDT.db[storageKey].point
    end

    if not ApplyPoint(frame, savedPoint) then
        ApplyPoint(frame, GetDefaultPoint(storageKey, defaultPoint) or { "CENTER", "UIParent", "CENTER", 0, 0 })
    end
end

function UI.SaveFramePosition(frame, storageKey)
    if not frame or not BDT.db or not storageKey then
        return
    end

    BDT.db[storageKey] = BDT.db[storageKey] or {}

    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
    BDT.db[storageKey].point = { point, "UIParent", relativePoint, xOfs or 0, yOfs or 0 }
end

function UI.ResetManagedPositions()
    if not BDT.db then
        return
    end

    local managedFrames = BDT.Config and BDT.Config.managedFrames or {}
    for _, info in ipairs(managedFrames) do
        BDT.db[info.key] = nil

        local frame = _G[info.frameName]
        if frame then
            UI.RestoreFramePosition(frame, info.key, info.defaultPoint)
        end
    end

    print("BDT: Reset saved window positions.")
end
