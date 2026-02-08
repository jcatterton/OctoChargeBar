local addonName = select(1, ...)
local addon = select(2, ...)

local Data = addon.Data
local ChargeBar = addon.ChargeBar
local Util = addon.Util
local LEM = LibStub('LibEditMode')

local Core = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceEvent-3.0")
addon.Core = Core

function Core:OnInitialize()
    Data:InitDB()
    Core.chargeBars = {}
end

function Core:OnEnable()
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    self:RegisterEvent("TRAIT_CONFIG_UPDATED")
    self:RegisterEvent("SPELL_UPDATE_CHARGES")

    LEM:RegisterCallback('enter', function()
        self:onEnterEditMode()
    end)
    LEM:RegisterCallback('exit', function()
        self:onExitEditMode()
    end)
    LEM:RegisterCallback('layout', function(layoutName)
        self:SetupBars(layoutName)
    end)
end

function Core:OnDisable()
    self:UnregisterAllEvents()
end

function Core:SPELL_UPDATE_CHARGES(event)
    for spellId, chargeBar in pairs(Core.chargeBars) do
        chargeBar:HandleSpellUpdateCharges()
    end
end

function Core:PLAYER_ENTERING_WORLD(event, isLogin, isReload)
    if InCombatLockdown() then return end

    -- Possible that we can run this too early on initial login, so we delay a second in those cases.
    C_Timer.After(isLogin and 1 or 0, function()
        for spellId, chargeBar in pairs(Core.chargeBars) do
            chargeBar:SetupCharges()
        end
    end)
end

function Core:PLAYER_SPECIALIZATION_CHANGED(event)
    Core:SetupBars(LEM:GetActiveLayoutName())
end

function Core:TRAIT_CONFIG_UPDATED(event, configId)
    if InCombatLockdown() then return end

    for i, chargeBar in pairs(Core.chargeBars) do
        local settings = Data:GetActiveLayoutBarSettings(chargeBar.spellId)
        chargeBar:ApplySettings(settings)
        chargeBar:HandleSpellUpdateCharges()
    end
end

function Core:SetupBars(layoutName)
    -- If we're switching layouts, we need to hide bars from the old layout.
    for spellId, chargeBar in pairs(Core.chargeBars) do
        chargeBar:Hide()
    end

    local specId = Util:GetActiveSpecId()

    Data.db.global[layoutName] = Data.db.global[layoutName] or {}
    Data.db.global[layoutName][specId] = Data.db.global[layoutName][specId] or {specBars = {}}

    local specBarSettings = Data.db.global[layoutName][specId].specBars

    -- pull default spells and add to SV if missing for this spec.
    for _, spellId in pairs(Data.defaultTrackedSpellsBySpec[specId]) do
        if not specBarSettings[spellId] then
            local settings = Util:TableCopy(Data.defaultBarSettings)
            settings.spellId = spellId
            specBarSettings[spellId] = settings
        end
    end

    -- setup bars from SV
    for spellId, barSettings in pairs(specBarSettings) do
        if not Core.chargeBars[spellId] then
            Core.chargeBars[spellId] = ChargeBar:NewWithSettings(barSettings)
        else
            Core.chargeBars[spellId]:ApplySettings(barSettings)
            LEM:RefreshFrameSettings(Core.chargeBars[spellId].frame)
        end
    end
end

function Core:onEnterEditMode()
    -- show everything even if disabled
    for i, chargeBar in pairs(Core.chargeBars) do
        chargeBar:Show()
    end
end

function Core:onExitEditMode()
    for spellId, chargeBar in pairs(Core.chargeBars) do
        local settings = Data:GetActiveLayoutBarSettings(chargeBar.spellId)
        chargeBar:ApplySettings(settings)
    end
end
