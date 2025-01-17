local addonName, addon = ...

-- Add references to the affix tables from the addon namespace
local affixDescLookup = MythicAffixHelper.affixDescLookup
local affixBuffLookup = MythicAffixHelper.affixBuffLookup

-- Define the special values for the affix numbers
local specialAffixNumbers = { "2", "4", "7", "10", "12" }

-- Function to add a frame below the affix with an icon and text
local function AddAffixIconWithText(affix, index)
    if not affix or not affix.affixID then return end

    -- Only create the overlay frame if it doesn't already exist
    if not affix.iconOverlay then
        -- Create a frame for the icon
        affix.iconOverlay = CreateFrame("Frame", nil, affix, "BackdropTemplate")
        affix.iconOverlay:SetSize(30, 30) -- Set size of the icon
        affix.iconOverlay:SetPoint("BOTTOM", affix, "BOTTOM", 0, -13) -- Position below the affix

        -- Add the background texture
        local texture = affix.iconOverlay:CreateTexture(nil, "BACKGROUND")
        texture:SetTexture("Interface\\AddOns\\MythicAffixHelper\\media\\textures\\icons\\mplus")
        texture:SetAllPoints(affix.iconOverlay) -- Fill the frame
        affix.iconOverlay.texture = texture

        -- Add the text overlay
        local text = affix.iconOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        text:SetPoint("CENTER", affix.iconOverlay, "CENTER", 2, 0) -- Center the text
        text:SetTextColor(1, 1, 1, 1) -- White color
        affix.iconOverlay.text = text
    end

-- Update text size and content with bold text
local fontName, _, fontFlags = affix.iconOverlay.text:GetFont()
affix.iconOverlay.text:SetFont(fontName, 11, fontFlags .. " OUTLINE") -- Use "OUTLINE" for bold effect (or "BOLD")
affix.iconOverlay.text:SetText(specialAffixNumbers[index] or "") -- Set the appropriate text for the affix
affix.iconOverlay:Show()

end

-- Function to add the "!" icon overlay on affix icons with a smoother wobble animation
local function AddWarningOverlay(affix)
    if not affix or not affix.affixID then return end

    -- Check if the affix has a description in the lookup table
    if affixDescLookup[affix.affixID] then
        -- Only create the overlay if it doesn't exist yet
        if not affix.warningOverlay then
            -- Create a frame for the warning icon (instead of just a texture)
            affix.warningOverlay = CreateFrame("Frame", nil, affix, "BackdropTemplate")
            affix.warningOverlay:SetSize(24, 24)  -- Set the size of the icon
            affix.warningOverlay:SetPoint("TOPRIGHT", affix, "TOPRIGHT", 0, 5)

            -- Create the texture for the warning icon
            local texture = affix.warningOverlay:CreateTexture(nil, "OVERLAY")
            texture:SetTexture("Interface\\AddOns\\MythicAffixHelper\\media\\textures\\icons\\warning") -- Replace with your texture path
            texture:SetAllPoints(affix.warningOverlay)  -- Make the texture fill the frame

            -- Set the frame level to ensure the overlay appears above the affix icon
            affix.warningOverlay:SetFrameLevel(affix:GetFrameLevel() + 1)

            -- Set the color to yellow (RGB: 1, 1, 0)
            texture:SetVertexColor(1, 1, 0)  -- Yellow color

            -- Add the smoother wobble animation
            local moveAmount = 10  -- Smaller horizontal movement for smoother effect
            local rotateAmount = 5  -- Smaller rotation for smoother effect
            local wobbleSpeed = 0.2  -- Slower animation for smoother transitions

            -- Create the wobble animation function
            local function WobbleAnimation(self, elapsed)
                self.elapsedTime = (self.elapsedTime or 0) + elapsed
                local progress = (self.elapsedTime / wobbleSpeed) % 1  -- Update animation progress

                -- Calculate position and rotation for each frame
                local translateX = math.sin(progress * math.pi * 2) * moveAmount  -- Horizontal movement
                local rotate = math.sin(progress * math.pi * 2) * rotateAmount  -- Rotation

                -- Apply animation to the texture and frame
                texture:SetPoint("CENTER", affix.warningOverlay, "CENTER", translateX, 0)
                texture:SetRotation(math.rad(rotate))  -- Convert degrees to radians and apply to the texture

                -- Reset animation if it exceeds the speed limit
                if self.elapsedTime > wobbleSpeed then
                    self.elapsedTime = 0
                end
            end

            -- Start the wobble animation
            affix.warningOverlay:SetScript("OnUpdate", WobbleAnimation)
            affix.warningOverlay.elapsedTime = 0  -- Initialize the elapsed time
        end
        affix.warningOverlay:Show()
    elseif affix.warningOverlay then
        affix.warningOverlay:Hide()
    end
end

-- Function to add additional tooltip information
local function AddAffixTooltipInfo(self, index)
    if not self.affixID then return end

    local name, description = C_ChallengeMode.GetAffixInfo(self.affixID)
    if not name or not description then return end

    -- Use the special number for the affix
    local affixNumber = specialAffixNumbers[index] or "" -- Default to "" if index is greater than 5
    local affixName = format("+%s %s", affixNumber, name)

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(affixName, 1, 1, 1, 1, true)
    GameTooltip:AddLine(description, nil, nil, nil, true)

    local spellID = affixBuffLookup[self.affixID]
    local affixDesc = affixDescLookup[self.affixID]

    if spellID then
        local spellLink = C_Spell.GetSpellLink(spellID)
        local spellInfo = C_Spell.GetSpellInfo(spellID)
        local spellDescription = C_Spell.GetSpellDescription(spellID)

        local iconWidth, iconHeight = 16, 16
        local spellName = spellInfo.name or "Unknown Spell"
        local spellIcon = spellInfo.iconID 
        local spellIconMarkup = "|T" .. spellIcon .. ":" .. iconWidth .. ":" .. iconHeight .. ":0:0|t"

        if spellLink and spellDescription then
            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine("Info:", 1, 0.8, 0)
            GameTooltip:AddLine(affixDesc, 0.9, 0.9, 0.9, true)
            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine("Buff:", 1, 0.8, 0)
            if spellName and spellIcon then
                -- Додаємо до тултіпа
                GameTooltip:AddLine(spellIconMarkup .. " [" .. spellName .. "]", 1, 0.8, 0, true)

            end
            GameTooltip:AddLine(spellDescription, 0.9, 0.9, 0.9, true)
        end
    end

    GameTooltip:Show()
end


-- Hook the tooltip display
function addon.HookAffixOnEnter()
    local affixesContainer = ChallengesFrame.WeeklyInfo 
        and ChallengesFrame.WeeklyInfo.Child 
        and ChallengesFrame.WeeklyInfo.Child.AffixesContainer

    if affixesContainer and affixesContainer.Affixes then
        for index, affix in ipairs(affixesContainer.Affixes) do
            if affix and affix.OnEnter then
                -- Add icon with text below the affix
                AddAffixIconWithText(affix, index)

                -- Add overlay "!" to the affix icon
                AddWarningOverlay(affix)

                -- Hook the tooltip display
                affix:HookScript("OnEnter", function(self)
                    AddAffixTooltipInfo(self, index) -- Pass the index to display the affix number
                end)
            end
        end
    end
end
