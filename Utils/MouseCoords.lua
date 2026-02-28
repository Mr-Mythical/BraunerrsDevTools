local _, BDT = ...
BDT.Utils = BDT.Utils or {}

local coordsFrame = nil
local isEnabled = false

function BDT.Utils.ToggleMouseCoords()
    if not coordsFrame then
        coordsFrame = CreateFrame("Frame", "BDT_MouseCoordsOverlay", UIParent, "BackdropTemplate")
        coordsFrame:SetSize(120, 30)
        coordsFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 100)
        coordsFrame:SetMovable(true)
        coordsFrame:EnableMouse(true)
        coordsFrame:RegisterForDrag("LeftButton")
        coordsFrame:SetScript("OnDragStart", coordsFrame.StartMoving)
        coordsFrame:SetScript("OnDragStop", coordsFrame.StopMovingOrSizing)
        coordsFrame:SetFrameStrata("TOOLTIP")
        
        -- Try to use typical backdrop
        coordsFrame.bg = coordsFrame:CreateTexture(nil, "BACKGROUND")
        coordsFrame.bg:SetAllPoints()
        coordsFrame.bg:SetColorTexture(0, 0, 0, 0.7)
        
        coordsFrame.text = coordsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        coordsFrame.text:SetPoint("CENTER")
        
        coordsFrame:SetScript("OnUpdate", function(self, elapsed)
            local uiScale = UIParent:GetEffectiveScale()
            local mx, my = GetCursorPosition()
            local uiX, uiY = mx / uiScale, my / uiScale
            self.text:SetFormattedText("X: %d, Y: %d", uiX, uiY)
        end)
    end
    
    isEnabled = not isEnabled
    if isEnabled then
        coordsFrame:Show()
        print("BDT: Mouse Coordinates enabled. Drag the box to move it.")
    else
        coordsFrame:Hide()
        print("BDT: Mouse Coordinates disabled.")
    end
end
