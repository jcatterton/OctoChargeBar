local addonName = select(1, ...)
local addon = select(2, ...)

local LEM = addon.LibEditMode
local Data = addon.Data
local Settings = addon.Settings
local LPP = LibStub("LibPixelPerfect-1.0")

local ChargeBar = {}
addon.ChargeBar = ChargeBar

function ChargeBar:New()
    local newInstance = {}
    setmetatable(newInstance, {__index = self})
    return newInstance
end

function ChargeBar:NewWithSettings(spellId, settings)
    settings[Settings.keys.SpellId] = spellId
    local bar = ChargeBar:New()
    bar:ApplySettings(settings)

    return bar
end

function ChargeBar:ApplySettings(settings)
    local spellName = C_Spell.GetSpellName(settings[Settings.keys.SpellId])
    assert(spellName, string.format("No spell name found for %d.", settings[Settings.keys.SpellId]))

    local frameName = string.format("%s: %s", addonName, spellName)
    self.spellId = settings[Settings.keys.SpellId]
    self.tickWidth = settings[Settings.keys.TickWidth]
    self.showTicks = self.tickWidth > 0
    self.tickColor = settings[Settings.keys.TickColor]
    self.enabled = settings[Settings.keys.Enabled]

    local initialSetup = false

    if not self.frame then
        self.frame = CreateFrame("Frame", frameName, UIParent, "BackdropTemplate")
        initialSetup = true
        EventRegistry:RegisterCallback(addonName..".SettingChanged", function(ownerID, ...)
            local layoutName, spellId, key, value = ...
            if spellId == self.spellId then
                self:onSettingChanged(layoutName, key, value)
            end
        end)
    end

    LPP.PSize(self.frame, settings[Settings.keys.Width], settings[Settings.keys.Height])
    self.frame:SetPoint("CENTER", UIParent, settings[Settings.keys.Position].point, settings[Settings.keys.Position].x, settings[Settings.keys.Position].y)

    local borderWidth = settings[Settings.keys.BorderWidth]
    if borderWidth > 0 then
        self.frame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = borderWidth,
            insets = {left = 0, right = 0, top = 0, bottom = 0}
        })
        self.frame:SetBackdropColor(0,0,0,0)
        self.frame:SetBackdropBorderColor(unpack(settings[Settings.keys.BorderColor]))
    else
        self.frame:SetBackdrop({})
    end
    self.frame:SetShown(settings[Settings.keys.Enabled])

    self.innerContainer = self.innerContainer or CreateFrame("Frame", "innerContainer", self.frame)
    LPP.PWidth(self.innerContainer, self.frame:GetWidth() - (borderWidth * 2))
    LPP.PHeight(self.innerContainer, self.frame:GetHeight() - (borderWidth * 2))
    self.innerContainer:SetPoint("CENTER", self.frame, "CENTER")
    self.innerContainer:SetClipsChildren(true)

    self.chargeFrame = self.chargeFrame or CreateFrame("StatusBar", "ChargesBar", self.innerContainer)
    LPP.PWidth(self.chargeFrame, self.innerContainer:GetWidth())
    LPP.PHeight(self.chargeFrame, self.innerContainer:GetHeight())
    self.chargeFrame:SetAllPoints(self.innerContainer)
    self.chargeFrame:SetColorFill(unpack(settings[Settings.keys.Color]))

    self.refreshCharge = self.refreshCharge or CreateFrame("StatusBar", "RefreshCharge", self.innerContainer)
    self.refreshCharge:SetPoint("LEFT",self.chargeFrame:GetStatusBarTexture(), "RIGHT")
    self.refreshCharge:SetColorFill(unpack(settings[Settings.keys.RechargeColor]))

    self.refreshCharge.text = self.refreshCharge.text or self.refreshCharge:CreateFontString("RechargeTime", "OVERLAY")
    if settings[Settings.keys.RechargeTextShow] then
        self.refreshCharge.text:SetAllPoints(self.refreshCharge)
        self.refreshCharge.text:SetFont(
            settings[Settings.keys.RechargeTextFont],
            settings[Settings.keys.RechargeTextSize],
            "OUTLINE"
        )
        self.refreshCharge:SetScript("OnUpdate", function()
            if self.refreshCharge:GetTimerDuration() then
                local rechargeDuration = self.refreshCharge:GetTimerDuration():GetRemainingDuration()
                self.refreshCharge.text:SetFormattedText("%.1f", rechargeDuration)
            else
                self.refreshCharge.text:SetText("")
            end
        end)
    else
        self.refreshCharge.text:SetToDefaults()
    end

    self.ticksContainer = self.ticksContainer or CreateFrame("Frame", "TicksContainer", self.innerContainer)
    LPP.PHeight(self.ticksContainer, self.innerContainer:GetWidth())
    LPP.PHeight(self.ticksContainer, self.innerContainer:GetHeight())
    self.ticksContainer:SetAllPoints(self.innerContainer)
    self.ticksContainer:Raise()
    self.ticksContainer.ticks = self.ticksContainer.ticks or {}

    if initialSetup then
        self:LEMSetup()
    end

    -- Disable the bar if we don't know the spell it tracks
    if not C_SpellBook.IsSpellKnown(self.spellId) then
        self:Hide()
        return self
    end

    self:SetupCharges()

    return self
end

-- Sets up bars based on max charges.
-- Can't be called while Secret restrictions are active!
function ChargeBar:SetupCharges()
    if not self.enabled then
        print('ChargeBar:SetupCharges:', self.spellId, 'not enabled.')
        return
    end

    local spellName = C_Spell.GetSpellName(self.spellId)
    assert(spellName, string.format("No spell name found for %d.", self.spellId))

    local chargeInfo = C_Spell.GetSpellCharges(self.spellId)
    if not chargeInfo then return end
    local currentCharges = chargeInfo.currentCharges
    local maxCharges = chargeInfo.maxCharges

    self.chargeFrame:SetMinMaxValues(0, maxCharges)
    self.chargeFrame:SetValue(currentCharges)

    -- disable all existing ticks
    for i, tick in ipairs(self.ticksContainer.ticks) do
        tick:SetToDefaults()
        tick:SetShown(false)
    end
    self.ticksContainer.ticks = {}

    if not issecretvalue(maxCharges) then
        local chargeWidth = self.innerContainer:GetWidth() / maxCharges

        LPP.PWidth(self.refreshCharge, chargeWidth)
        LPP.PHeight(self.refreshCharge, self.innerContainer:GetHeight())

        if self.showTicks then
            for i = 1, maxCharges - 1 do
                local tick = self.ticksContainer:CreateTexture(nil, "OVERLAY")
                tick:SetColorTexture(unpack(self.tickColor))
                LPP.PWidth(tick, self.tickWidth)
                LPP.PHeight(tick, self.ticksContainer:GetHeight())
                tick:SetPoint("CENTER", self.ticksContainer, "LEFT", chargeWidth * i, 0)
                tick:SetTexelSnappingBias(0)
                tick:SetSnapToPixelGrid(false)
                table.insert(self.ticksContainer.ticks, tick)
            end
        end
    end

    self:HandleSpellUpdateCharges()
end

function ChargeBar:Hide()
    self.frame:Hide()
    self.enabled = false
end

function ChargeBar:Show()
    self.frame:Show()
end

function ChargeBar:LEMSetup()
    LEM:AddFrame(self.frame, function(frame, layoutName, point, x, y)
        self:onPositionChanged(layoutName, point, x, y)
    end, Settings.GetDefaultEditModeFramePosition())

    local lemSettings = {}
    for _, key in ipairs(Settings.GetSettingsDisplayOrder()) do
        local settingObj = Settings.GetLEMSettingsObject(key)
        settingObj.get = function(layoutName)
            return Settings.Get(layoutName, self.spellId, key)
        end
        settingObj.set = function(layoutName, value)
            Settings.Set(layoutName, self.spellId, key, value)
        end
        settingObj.disabled = function(layoutName)
            -- The Enable setting is only disabled (and should already be unchecked) for spells we don't know.
            if key == Settings.keys.Enabled then
                return not C_SpellBook.IsSpellKnown(self.spellId)
            end
            return not self.enabled
        end

        table.insert(lemSettings, settingObj)
    end

    LEM:AddFrameSettings(self.frame, lemSettings)
end

function ChargeBar:HandleSpellUpdateCharges()
    if not self.enabled then
        return
    end
    self.chargeFrame:SetValue(C_Spell.GetSpellCharges(self.spellId).currentCharges)
    self.refreshCharge:SetTimerDuration(
        C_Spell.GetSpellChargeDuration(self.spellId),
        Enum.StatusBarInterpolation.Immediate,
        Enum.StatusBarTimerDirection.ElapsedTime
    )
end

function ChargeBar:onPositionChanged(layoutName, point, x, y)
    Settings.Set(layoutName, self.spellId, Settings.keys.Position, {
        point = point,
        x = x,
        y = y
    })
end

function ChargeBar:onSettingChanged(layoutName, key, value)
    local settings = Data:GetLayoutBarSettings(layoutName, self.spellId)
    self:ApplySettings(settings)
end
