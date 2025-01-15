local addonName, addon = ...

-- Event handling function
local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddonName = ...
        if loadedAddonName == addonName then
            hooksecurefunc("PVEFrame_ShowFrame", function()
                if PVEFrame and PVEFrame.activeTabIndex == 3 then
                    addon.HookAffixOnEnter()
                end
            end)
        end
    end
end

-- Create a frame to register events
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", OnEvent)



