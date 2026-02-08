local addonName = select(1, ...)
local addon = select(2, ...)

local LEM = LibStub('LibEditMode')
local Util = addon.Util
local Data = addon.Data

local ChargeBar = {}
addon.ChargeBar = ChargeBar

function ChargeBar:New()
    local newInstance = Util:TableCopy(Data.defaultBarSettings)
    setmetatable(newInstance, {__index = self})
    return newInstance
end

---@param settings ChargeBarSettings
function ChargeBar:NewWithSettings(settings)
    local bar = ChargeBar:New()
    bar:ApplySettings(settings)

    return bar
end

---@param settings ChargeBarSettings
function ChargeBar:ApplySettings(settings)
    assert(C_SpellBook.IsSpellKnown(settings.spellId), settings.spellId .. " not known!")

    local spellName = C_Spell.GetSpellName(settings.spellId)
    assert(spellName, string.format("No spell name found for %d.", settings.spellId))

    local frameName = string.format("%s: %s", addonName, spellName)
    self.spellId = settings.spellId
    self.showTicks = settings.showTicks
    self.tickColor = settings.tickColor
    self.tickWidth = settings.tickWidth
    self.enabled = settings.enabled

    local initialSetup = false

    if not self.frame then
        self.frame = CreateFrame("Frame", frameName, UIParent, "BackdropTemplate")
        initialSetup = true
    end
    self.frame:SetSize(settings.barWidth, settings.barHeight)
    self.frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = settings.borderWidth,
        insets = {left = 0, right = 0, top = 0, bottom = 0}
    })
    self.frame:SetBackdropColor(0,0,0,0)
    self.frame:SetBackdropBorderColor(Util:UnpackRGBA(settings.borderColor))
    self.frame:SetSize(settings.barWidth, settings.barHeight)
    self.frame:SetPoint(settings.position.point, settings.position.x, settings.position.y)
    self.frame:SetShown(settings.enabled)

    self.innerContainer = self.innerContainer or CreateFrame("Frame", "innerContainer", self.frame)
    self.innerContainer:SetSize(settings.barWidth - (settings.borderWidth * 2), settings.barHeight - (settings.borderWidth * 2))
    self.innerContainer:SetPoint("CENTER", self.frame, "CENTER", 0, 0)
    self.innerContainer:SetClipsChildren(true)

    self.chargeFrame = self.chargeFrame or CreateFrame("StatusBar", "ChargesBar", self.innerContainer)
    self.chargeFrame:SetPoint("CENTER", self.innerContainer, "CENTER", 0, 0)
    self.chargeFrame:SetSize(self.innerContainer:GetWidth(), self.innerContainer:GetHeight())
    self.chargeFrame:SetColorFill(Util:UnpackRGBA(settings.chargeColor))

    self.refreshCharge = self.refreshCharge or CreateFrame("StatusBar", "RefreshCharge", self.innerContainer)
    self.refreshCharge:SetPoint("LEFT",self.chargeFrame:GetStatusBarTexture(), "RIGHT", 0, 0)
    self.refreshCharge:SetColorFill(Util:UnpackRGBA(settings.rechargeColor))

    self.refreshCharge.text = self.refreshCharge.text or self.refreshCharge:CreateFontString("RechargeTime", "OVERLAY")
    if settings.showRechargeText then
        self.refreshCharge.text:SetPoint("CENTER")
        self.refreshCharge.text:SetFont(settings.rechargeTextFont, settings.rechargeTextFontSize, "OUTLINE")
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
    self.ticksContainer:SetPoint("CENTER")
    self.ticksContainer:SetSize(self.innerContainer:GetWidth(), self.innerContainer:GetHeight())
    self.ticksContainer.ticks = self.ticksContainer.ticks or {}

    if initialSetup then
        self:LEMSetup()
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

    local maxCharges = chargeInfo.maxCharges
    local currentCharges = chargeInfo.currentCharges
    local chargeWidth = self.innerContainer:GetWidth() / maxCharges
    self.chargeFrame:SetMinMaxValues(0, maxCharges)
    self.chargeFrame:SetValue(currentCharges)

    self.refreshCharge:SetSize(chargeWidth, self.innerContainer:GetHeight())
    if self.showTicks then
        -- reuse existing ticks when possible
        for i, tick in ipairs(self.ticksContainer.ticks) do
            -- can be reused
            if i <= maxCharges - 1 then
                tick:SetColorTexture(Util:UnpackRGBA(self.tickColor))
                tick:SetSize(self.tickWidth, self.ticksContainer:GetHeight())
                tick:SetPoint("CENTER", self.ticksContainer, "LEFT", chargeWidth * i, 0)
                tick:SetShown(true)
            -- hide all ticks we don't need
            else
                tick:SetToDefaults()
                tick:SetShown(false)
            end
        end

        local newTicksNeeded = (maxCharges - 1) - #self.ticksContainer.ticks
        for i = #self.ticksContainer.ticks + 1, newTicksNeeded do
            local tick = self.ticksContainer:CreateTexture(nil, "OVERLAY")
            tick:SetColorTexture(Util:UnpackRGBA(self.tickColor))
            tick:SetSize(self.tickWidth, self.ticksContainer:GetHeight())
            tick:SetPoint("CENTER", self.ticksContainer, "LEFT", chargeWidth * i, 0)
            table.insert(self.ticksContainer.ticks, tick)
        end
    end
end

function ChargeBar:Hide()
    self.frame:Hide()
    self.enabled = false
end

function ChargeBar:Show()
    self.frame:Show()
end

function ChargeBar:LEMSetup()
    -- TODO: Figure out what the default position values should be.
    LEM:AddFrame(self.frame, function(frame, layoutName, point, x, y)
        print(frame:GetName(), layoutName, point, x, y)
        self:onPositionChanged(layoutName, point, x, y)
    end, {point = 'CENTER', x = 0, y = 0})

    LEM:AddFrameSettings(self.frame, {
        {
            name = 'Enabled',
            kind = LEM.SettingType.Checkbox,
            default = Data.defaultBarSettings.enabled,
            get = function(layoutName)
                return Data:GetBarSetting(layoutName, self.spellId, 'enabled')
            end,
            set = function(layoutName, value)
                Data:SetBarSetting(layoutName, self.spellId, 'enabled', value)
                self.enabled = value
            end,
        },
        {
            name = 'Bar Width',
            kind = LEM.SettingType.Slider,
            default = Data.defaultBarSettings.barWidth,
            disabled = function(layoutName)
                return not self.enabled
            end,
            get = function(layoutName)
                return Data:GetBarSetting(layoutName, self.spellId, 'barWidth')
            end,
            set = function(layoutName, value)
                Data:SetBarSetting(layoutName, self.spellId, 'barWidth', value)
                self.frame:SetWidth(value)
            end,
            minValue = 50,
            maxValue = 500,
            valueStep = 1,
        },
        {
            name = 'Bar Height',
            kind = LEM.SettingType.Slider,
            default = Data.defaultBarSettings.barHeight,
            disabled = function(layoutName)
                return not self.enabled
            end,
            get = function(layoutName)
                return Data:GetBarSetting(layoutName, self.spellId, 'barHeight')
            end,
            set = function(layoutName, value)
                Data:SetBarSetting(layoutName, self.spellId, 'barHeight', value)
                self.frame:SetHeight(value)
            end,
            minValue = 8,
            maxValue = 100,
            valueStep = 1,
        },
        {
            name = 'Charge Color',
            description = 'Color of active charges.',
            kind = LEM.SettingType.ColorPicker,
            default = CreateColor(Util:UnpackRGBA(Data.defaultBarSettings.chargeColor)),
            disabled = function(layoutName)
                return not self.enabled
            end,
            hasOpacity = true,
            get = function(layoutName)
                return CreateColor(Util:UnpackRGBA(Data:GetBarSetting(layoutName, self.spellId, 'chargeColor')))
            end,
            set = function(layoutName, value)
                Data:SetBarSetting(layoutName, self.spellId, 'chargeColor', {
                    r = value.r,
                    g = value.g,
                    b = value.b,
                    a = value.a
                })
                self.chargeFrame:SetColorFill(value:GetRGBA())
            end,
        },
        {
            name = 'Border Width',
            kind = LEM.SettingType.Slider,
            default = Data.defaultBarSettings.borderWidth,
            disabled = function(layoutName)
                return not self.enabled
            end,
            get = function(layoutName)
                return Data:GetBarSetting(layoutName, self.spellId, 'borderWidth')
            end,
            set = function(layoutName, value)
                Data:SetBarSetting(layoutName, self.spellId, 'borderWidth', value)
            end,
            minValue = 0,
            maxValue = 5,
        },
        {
            name = 'Border Color',
            kind = LEM.SettingType.ColorPicker,
            default = CreateColor(Util:UnpackRGBA(Data.defaultBarSettings.borderColor)),
            disabled = function(layoutName)
                return not self.enabled
            end,
            hasOpacity = true,
            get = function(layoutName)
                return CreateColor(Util:UnpackRGBA(Data:GetBarSetting(layoutName, self.spellId, 'borderColor')))
            end,
            set = function(layoutName, value)
                Data:SetBarSetting(layoutName, self.spellId, 'borderColor', {
                    r = value.r,
                    g = value.g,
                    b = value.b,
                    a = value.a
                })
                self.frame:SetBackdropBorderColor(value:GetRGBA())
            end,
        },
        {
            name = 'Recharge Bar Color',
            kind = LEM.SettingType.ColorPicker,
            default = CreateColor(Util:UnpackRGBA(Data.defaultBarSettings.rechargeColor)),
            disabled = function(layoutName)
                return not self.enabled
            end,
            hasOpacity = true,
            get = function(layoutName)
                return CreateColor(Util:UnpackRGBA(Data:GetBarSetting(layoutName, self.spellId, 'rechargeColor')))
            end,
            set = function(layoutName, value)
                Data:SetBarSetting(layoutName, self.spellId, 'rechargeColor', {
                    r = value.r,
                    g = value.g,
                    b = value.b,
                    a = value.a
                })
                self.refreshCharge:SetColorFill(value:GetRGBA())
            end,
        },
        {
            name = 'Show Recharge Cooldown Text',
            kind = LEM.SettingType.Checkbox,
            default = Data.defaultBarSettings.showRechargeText,
            disabled = function(layoutName)
                return not self.enabled
            end,
            get = function(layoutName)
                return Data:GetBarSetting(layoutName, self.spellId, 'showRechargeText')
            end,
            set = function(layoutName, value)
                Data:SetBarSetting(layoutName, self.spellId, 'showRechargeText', value)
                self.refreshCharge.text:SetShown(false)
            end,
        },
        {
            name = 'Recharge Cooldown Text Size',
            kind = LEM.SettingType.Slider,
            default = Data.defaultBarSettings.rechargeTextFontSize,
            disabled = function(layoutName)
                return not self.enabled
            end,
            hidden = function(layoutName)
                return Data:GetBarSetting(layoutName, self.spellId, 'rechargeTextFontSize') < 1
            end,
            get = function(layoutName)
                return Data:GetBarSetting(layoutName, self.spellId, 'rechargeTextFontSize')
            end,
            set = function(layoutName, value)
                Data:SetBarSetting(layoutName, self.spellId, 'rechargeTextFontSize', value)
                self.refreshCharge.text:SetFontHeight(value)
            end,
            -- TODO: make these related to the bar size somehow
            minValue = 6,
            maxValue = 20,
            valueStep = 1,
        },
        {
            name = 'Tick Width',
            kind = LEM.SettingType.Slider,
            default = Data.defaultBarSettings.tickWidth,
            disabled = function(layoutName)
                return not self.enabled
            end,
            get = function(layoutName)
                return Data:GetBarSetting(layoutName, self.spellId, 'tickWidth')
            end,
            set = function(layoutName, value)
                Data:SetBarSetting(layoutName, self.spellId, 'tickWidth', value)
                self.tickWidth = value
            end,
            minValue = 0,
            maxValue = 5,
        },
        {
            name = 'Tick Color',
            kind = LEM.SettingType.ColorPicker,
            default = CreateColor(Util:UnpackRGBA(Data.defaultBarSettings.tickColor)),
            disabled = function(layoutName)
                return not self.enabled
            end,
            hasOpacity = true,
            get = function(layoutName)
                return CreateColor(Util:UnpackRGBA(Data:GetBarSetting(layoutName, self.spellId, 'tickColor')))
            end,
            set = function(layoutName, value)
                local color = {
                    r = value.r,
                    g = value.g,
                    b = value.b,
                    a = value.a
                }
                Data:SetBarSetting(layoutName, self.spellId, 'tickColor', color)
                self.tickColor = color
            end,
        },
    })
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
    -- print(string.format("onPositionChanged('%s', %d): %s (%d, %y)", layoutName, self.spellId, point, x, y))
    Data:SetBarSetting(layoutName, self.spellId, 'position', {
        point = point,
        x = floor(x),
        y = floor(y)
    })
end
