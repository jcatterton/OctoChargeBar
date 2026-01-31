local addonName = select(1, ...)
local addon = select(2, ...)

local LEM = LibStub('LibEditMode')
local Util = addon.Util
local Data = addon.Data

local ChargeBar = {}
addon.ChargeBar = ChargeBar

---@param settings ChargeBarSettings
function ChargeBar:Init(settings)
    DevTools_Dump(settings)
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
    self.frame:SetClipsChildren(true)

    self.innerContainer = self.innerContainer or CreateFrame("Frame", "innerContainer", self.frame)
    self.innerContainer:SetSize(settings.barWidth - (settings.borderWidth * 2), settings.barHeight - (settings.borderWidth * 2))
    self.innerContainer:SetPoint("CENTER", self.frame, "CENTER", 0, 0)

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

    LEM:RegisterCallback('enter', function()
        self:onEnterEditMode()
    end)
    LEM:RegisterCallback('exit', function()
        self:onExitEditMode()
    end)
    LEM:RegisterCallback('layout', function(layoutName)
        self:onEditModeLayout(layoutName)
    end)

    LEM:AddFrame(self.frame, function(frame, layoutName, point, x, y)
        self:onPositionChanged(layoutName, point, x, y)
    end, { point = 'CENTER', x = 0, y = 0, })

    return self
end

-- Sets up bars based on max charges.
-- Can't be called while Secret restrictions are active!
function ChargeBar:Setup()
    local spellName = C_Spell.GetSpellName(self.spellId)
    assert(spellName, string.format("No spell name found for %d.", self.spellId))
    local frameName = string.format("%s: %s", addonName, spellName)

    local chargeInfo = C_Spell.GetSpellCharges(self.spellId)
    if not chargeInfo then return end

    local maxCharges = chargeInfo.maxCharges
    local currentCharges = chargeInfo.currentCharges
    local chargeWidth = ceil(self.innerContainer:GetWidth() / maxCharges)
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
    print(self.frame:GetName(), 'enter')
end

function ChargeBar:onExitEditMode()
    print(self.frame:GetName(), 'exit')
end

--- Called every time the Edit Mode layout changes (including on login)
function ChargeBar:onEditModeLayout(layoutName)
    print(self.frame:GetName(), 'editModeLayout:', layoutName)
end
