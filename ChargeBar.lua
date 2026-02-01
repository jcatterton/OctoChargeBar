local addonName = select(1, ...)
local addon = select(2, ...)

local LEM = LibStub('LibEditMode')
local Util = addon.Util
local Data = addon.Data

local ChargeBar = {}
addon.ChargeBar = ChargeBar

---@param settings ChargeBarSettings
function ChargeBar:Init(settings)
    if not C_SpellBook.IsSpellKnown(settings.spellId) then print(settings.spellId, 'not known!') return end
    local spellName = C_Spell.GetSpellName(settings.spellId)
    assert(spellName, string.format("No spell name found for %d.", settings.spellId))

    local frameName = string.format("%s: %s", addonName, spellName)
    print(frameName, 'Init()')
    self.spellId = settings.spellId
    self.showTicks = settings.showTicks
    self.tickColor = settings.tickColor
    self.tickWidth = settings.tickWidth

    self.frame = self.frame or CreateFrame("Frame", frameName, UIParent, "BackdropTemplate")
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
    self.ticksContainer:SetPoint("LEFT", self.borderWidth)
    -- ensure ticks render on top of the bar
    self.ticksContainer:Raise()
    self.ticksContainer.ticks = {}

    self:LEMSetup()

    return self
end

-- Sets up bars based on max charges.
-- Can't be called while Secret restrictions are active!
function ChargeBar:Setup()
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
        print('starting with', #self.ticksContainer.ticks, 'ticks')
        -- reuse existing ticks when possible
        for i = 1, #self.ticksContainer.ticks do
            local tick = self.ticksContainer.ticks[i]
            -- can be reused
            if i <= maxCharges - 1 then
                print('reusing tick', i, 'at', chargeWidth * i)
                tick:SetTexture("Interface\\Buttons\\WHITE8X8")
                tick:SetVertexColor(Util:UnpackRGBA(self.tickColor))
                tick:SetSize(self.tickWidth, self.innerContainer:GetHeight())
                tick:SetPoint("CENTER", self.ticksContainer, "LEFT", chargeWidth * i, 0)
            -- hide all ticks we don't need
            else
                print('Resetting tick', i)
                tick:SetToDefaults()
            end
        end

        local newTicksNeeded = (maxCharges - 1) - #self.ticksContainer.ticks
        print('need', newTicksNeeded, 'new ticks.')
        for i = #self.ticksContainer.ticks + 1, newTicksNeeded do
            print('creating tick', i, 'at', chargeWidth * i)
            local tick = self.ticksContainer:CreateTexture("Tick_"..i-1, "OVERLAY")
            tick:SetTexture("Interface\\Buttons\\WHITE8X8")
            tick:SetVertexColor(Util:UnpackRGBA(self.tickColor))
            tick:SetSize(self.tickWidth, self.innerContainer:GetHeight())
            tick:SetPoint("CENTER", self.innerContainer, "LEFT", chargeWidth * i, 0)
            table.insert(self.ticksContainer.ticks, tick)
        end
    end
end

function ChargeBar:Disable()
    self.frame:SetShown(false)
end

function ChargeBar:LEMSetup()
    LEM:RegisterCallback('enter', function()
        self:onEnterEditMode()
    end)
    LEM:RegisterCallback('exit', function()
        self:onExitEditMode()
    end)
    LEM:RegisterCallback('layout', function(layoutName)
        self:onEditModeLayout(layoutName)
    end)

    -- TODO: Figure out what the default position values should be.
    LEM:AddFrame(self.frame, function(frame, layoutName, point, x, y)
        self:onPositionChanged(layoutName, point, x, y)
    end, {point = 'CENTER', x = 0, y = 0})

    LEM:AddFrameSettings(self.frame, {
        {
            name = 'Bar Width',
            kind = LEM.SettingType.Slider,
            default = Data.defaultBarSettings.barWidth,
            get = function(layoutName)
                return Data.db.profile.bars[1].barWidth
            end,
            set = function(layoutName, value)
                Data.db.profile.bars[1].barWidth = value
                self.reinitRequired = self.frame:GetWidth() ~= value
            end,
            minValue = 50,
            maxValue = 1000,
            valueStep = 1,
        },
        {
            name = 'Bar Height',
            kind = LEM.SettingType.Slider,
            default = Data.defaultBarSettings.barHeight,
            get = function(layoutName)
                return Data.db.profile.bars[1].barHeight
            end,
            set = function(layoutName, value)
                Data.db.profile.bars[1].barHeight = value
                self.reinitRequired = self.frame:GetHeight() ~= value
            end,
            minValue = 50,
            maxValue = 1000,
            valueStep = 1,
        },
        {
            name = 'Bar Color',
            description = 'Color of active charges.',
            kind = LEM.SettingType.ColorPicker,
            default = CreateColor(Util:UnpackRGBA(Data.defaultBarSettings.chargeColor)),
            hasOpacity = true,
            get = function(layoutName)
                return CreateColor(Util:UnpackRGBA(Data.db.profile.bars[1].chargeColor))
            end,
            set = function(layoutName, value)
                Data.db.profile.bars[1].chargeColor = {
                    r = value.r,
                    g = value.g,
                    b = value.b,
                    a = value.a
                }
                self.chargeFrame:SetColorFill(value:GetRGBA())
            end,
        },
        {
            name = 'Border Width',
            kind = LEM.SettingType.Slider,
            default = Data.defaultBarSettings.borderWidth,
            get = function(layoutName)
                return Data.db.profile.bars[1].borderWidth
            end,
            set = function(layoutName, value)
                Data.db.profile.bars[1].borderWidth = value
                self.reinitRequired = self.frame:GetBackdrop().edgeSize ~= value
            end,
            minValue = 0,
            maxValue = 5,
        },
        {
            name = 'Border Color',
            kind = LEM.SettingType.ColorPicker,
            default = CreateColor(Util:UnpackRGBA(Data.defaultBarSettings.borderColor)),
            hasOpacity = true,
            get = function(layoutName)
                return CreateColor(Util:UnpackRGBA(Data.db.profile.bars[1].borderColor))
            end,
            set = function(layoutName, value)
                Data.db.profile.bars[1].borderColor = {
                    r = value.r,
                    g = value.g,
                    b = value.b,
                    a = value.a
                }
                self.frame:SetBackdropBorderColor(value:GetRGBA())
            end,
        },
        {
            -- TODO: Hook this up.
            name = 'Enable Recharge Bar',
            description = 'Displays a partial fill on the currently recharching charge',
            kind = LEM.SettingType.Checkbox,
            default = true, -- Data.defaultBarSettings.enableRechargeBar,
            get = function(layoutName)
                return true -- Data.db.profile.bars[1].enableRechargeBar
            end,
            set = function(layoutName, value)
                -- Data.db.profile.bars[1].enableRechargeBar = value
            end,
        },
        {
            name = 'Recharge Bar Color',
            kind = LEM.SettingType.ColorPicker,
            default = CreateColor(Util:UnpackRGBA(Data.defaultBarSettings.rechargeColor)),
            hasOpacity = true,
            get = function(layoutName)
                return CreateColor(Util:UnpackRGBA(Data.db.profile.bars[1].rechargeColor))
            end,
            set = function(layoutName, value)
                Data.db.profile.bars[1].rechargeColor = {
                    r = value.r,
                    g = value.g,
                    b = value.b,
                    a = value.a
                }
                self.refreshCharge:SetVertexColor(value:GetRGBA())
            end,
        },
        {
            name = 'Show Recharge Cooldown Text',
            kind = LEM.SettingType.Checkbox,
            default = Data.defaultBarSettings.showRechargeText,
            get = function(layoutName)
                return Data.db.profile.bars[1].showRechargeText
            end,
            set = function(layoutName, value)
                Data.db.profile.bars[1].showRechargeText = value
                self.reinitRequired = true
            end,
        },
        {
            name = 'Recharge Cooldown Text Size',
            kind = LEM.SettingType.Slider,
            default = Data.defaultBarSettings.rechargeTextFontSize,
            hidden = function()
                return not Data.db.profile.bars[1].rechargeTextFontSize
            end,
            get = function(layoutName)
                return Data.db.profile.bars[1].rechargeTextFontSize
            end,
            set = function(layoutName, value)
                Data.db.profile.bars[1].rechargeTextFontSize = value
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
            get = function(layoutName)
                return Data.db.profile.bars[1].tickWidth
            end,
            set = function(layoutName, value)
                Data.db.profile.bars[1].tickWidth = value
                self.reinitRequired = self.tickWidth ~= value
                self.tickWidth = value
            end,
            minValue = 0,
            maxValue = 5,
        },
        {
            name = 'Tick Color',
            kind = LEM.SettingType.ColorPicker,
            default = CreateColor(Util:UnpackRGBA(Data.defaultBarSettings.tickColor)),
            hasOpacity = true,
            get = function(layoutName)
                return CreateColor(Util:UnpackRGBA(Data.db.profile.bars[1].tickColor))
            end,
            set = function(layoutName, value)
                Data.db.profile.bars[1].tickColor = {
                    r = value.r,
                    g = value.g,
                    b = value.b,
                    a = value.a
                }
                self.tickColor = Data.db.profile.bars[1].tickColor
                self.reinitRequired = true
            end,
        },
    })
end

function ChargeBar:HandleSpellUpdateCharges()
    self.chargeFrame:SetValue(C_Spell.GetSpellCharges(self.spellId).currentCharges)
    self.refreshCharge:SetTimerDuration(
        C_Spell.GetSpellChargeDuration(self.spellId),
        Enum.StatusBarInterpolation.Immediate,
        Enum.StatusBarTimerDirection.ElapsedTime
    )
end

function ChargeBar:onPositionChanged(layoutName, point, x, y)
    print(self.frame:GetName(), layoutName, 'onPositionChanged', x, y, point)
    Data.db.profile.bars[1].position = {
        point = point,
        x = x,
        y = y
    }
end

function ChargeBar:onEnterEditMode()
end

function ChargeBar:onExitEditMode()
    if self.reinitRequired then
        self:Init(Data.db.profile.bars[1])
        self:Setup()
        self.reinitRequired = false
    end
end

--- Called every time the Edit Mode layout changes (including on login)
function ChargeBar:onEditModeLayout(layoutName)
end
