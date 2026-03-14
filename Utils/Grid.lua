--[[
Grid.lua - Screen alignment grid overlay

Purpose: Draws a center-aligned grid overlay for UI layout and positioning work
Dependencies: BDT.Utils
Author: braunerr
--]]

local _, BDT = ...
BDT.Utils = BDT.Utils or {}

local gridFrame = nil
local isGridEnabled = false

local function CreateGrid(gridSize)
    if gridFrame then 
        gridFrame:Hide() 
        gridFrame = nil
    end
    
    gridFrame = CreateFrame("Frame", "BDT_GridOverlay", UIParent)
    gridFrame:SetAllPoints()
    gridFrame:SetFrameStrata("BACKGROUND")
    gridFrame:SetFrameLevel(0)
    
    local width, height = UIParent:GetWidth(), UIParent:GetHeight()
    local centerX, centerY = width / 2, height / 2
    
    -- Draw center lines first
    local vCenter = gridFrame:CreateTexture(nil, "BACKGROUND")
    vCenter:SetColorTexture(1, 0, 0, 0.7)
    vCenter:SetWidth(1)
    vCenter:SetPoint("BOTTOM", gridFrame, "BOTTOMLEFT", centerX, 0)
    vCenter:SetPoint("TOP", gridFrame, "TOPLEFT", centerX, 0)
    
    local hCenter = gridFrame:CreateTexture(nil, "BACKGROUND")
    hCenter:SetColorTexture(1, 0, 0, 0.7)
    hCenter:SetHeight(1)
    hCenter:SetPoint("LEFT", gridFrame, "BOTTOMLEFT", 0, centerY)
    hCenter:SetPoint("RIGHT", gridFrame, "BOTTOMRIGHT", 0, centerY)
    
    -- Draw horizontal/vertical lines outwards from center
    local stepsX = math.ceil(centerX / gridSize)
    local stepsY = math.ceil(centerY / gridSize)
    
    for i = 1, math.max(stepsX, stepsY) do
        local offset = i * gridSize
        
        -- Right vertical
        if centerX + offset <= width then
            local t = gridFrame:CreateTexture(nil, "BACKGROUND")
            t:SetColorTexture(0, 0, 0, 1)
            t:SetWidth(1)
            t:SetPoint("BOTTOM", gridFrame, "BOTTOMLEFT", centerX + offset, 0)
            t:SetPoint("TOP", gridFrame, "TOPLEFT", centerX + offset, 0)
        end
        -- Left vertical
        if centerX - offset >= 0 then
            local t = gridFrame:CreateTexture(nil, "BACKGROUND")
            t:SetColorTexture(0, 0, 0, 1)
            t:SetWidth(1)
            t:SetPoint("BOTTOM", gridFrame, "BOTTOMLEFT", centerX - offset, 0)
            t:SetPoint("TOP", gridFrame, "TOPLEFT", centerX - offset, 0)
        end
        
        -- Top horizontal
        if centerY + offset <= height then
            local t = gridFrame:CreateTexture(nil, "BACKGROUND")
            t:SetColorTexture(0, 0, 0, 1)
            t:SetHeight(1)
            t:SetPoint("LEFT", gridFrame, "BOTTOMLEFT", 0, centerY + offset)
            t:SetPoint("RIGHT", gridFrame, "BOTTOMRIGHT", 0, centerY + offset)
        end
        -- Bottom horizontal
        if centerY - offset >= 0 then
            local t = gridFrame:CreateTexture(nil, "BACKGROUND")
            t:SetColorTexture(0, 0, 0, 1)
            t:SetHeight(1)
            t:SetPoint("LEFT", gridFrame, "BOTTOMLEFT", 0, centerY - offset)
            t:SetPoint("RIGHT", gridFrame, "BOTTOMRIGHT", 0, centerY - offset)
        end
    end
end

function BDT.Utils.ToggleGrid(gridSize)
    if type(gridSize) == "string" and gridSize ~= "" then
        gridSize = tonumber(gridSize)
    else
        gridSize = nil
    end
    gridSize = gridSize or 64
    
    isGridEnabled = not isGridEnabled
    if isGridEnabled then
        CreateGrid(gridSize)
        gridFrame:Show()
        print("BDT: Grid enabled (Size: " .. gridSize .. "px).")
    else
        if gridFrame then
            gridFrame:Hide()
        end
        print("BDT: Grid disabled.")
    end
end
