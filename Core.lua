local addonName = select(1, ...)
local addon = select(2, ...)

local Data = addon.Data
local ChargeBar = addon.ChargeBar
local Util = addon.Util
local Settings = addon.Settings
local LEM = addon.LibEditMode

local Core = LibStub('AceAddon-3.0'):NewAddon(addonName, 'AceEvent-3.0')
addon.Core = Core

function Core:OnInitialize()
    Data:InitDB()
    Core.chargeBars = {}
end

function Core:OnEnable()
    self:RegisterEvent('TRAIT_CONFIG_UPDATED')
    self:RegisterEvent('SPELL_UPDATE_CHARGES')

    LEM:RegisterCallback('enter', function()
        self:onEnterEditMode()
    end)
    LEM:RegisterCallback('exit', function()
        self:onExitEditMode()
    end)
    LEM:RegisterCallback('layout', function(layoutName)
        -- Need to wait a frame for min/max charges to update from talent changes.
        C_Timer.After(0, function()
            self:SetupBars(layoutName)
        end)
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

function Core:TRAIT_CONFIG_UPDATED(event, configId)
    if InCombatLockdown() then return end

    -- Need to wait a frame for min/max charges to update from talent changes.
    C_Timer.After(0, function()
        Core:SetupBars(LEM:GetActiveLayoutName())
    end)
end

function Core:SetupBars(layoutName)
    -- If we're switching layouts, we need to hide bars from the old layout.
    -- TODO: Better to just delete everything and start fresh instead of reuisng bars? Would be a lot simpler.
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
            local settingsObj = Settings:CreateBarSettingsObjectFromDefaults(spellId)
            specBarSettings[spellId] = settingsObj
        end
    end

    -- setup bars from SV
    for spellId, barSettings in pairs(specBarSettings) do
        if not Core.chargeBars[spellId] then
            Core.chargeBars[spellId] = ChargeBar:NewWithSettings(spellId, barSettings)
        else
            Core.chargeBars[spellId]:ApplySettings(barSettings)
            LEM:RefreshFrameSettings(Core.chargeBars[spellId].frame)
        end
    end
end

function Core:onEnterEditMode()
    -- show everything even if disabled
    for spellId, chargeBar in pairs(Core.chargeBars) do
        if C_SpellBook.IsSpellKnown(spellId) then
            chargeBar:Show()
        end
    end
end

function Core:onExitEditMode()
    for spellId, chargeBar in pairs(Core.chargeBars) do
        if C_SpellBook.IsSpellKnown(spellId) then
            local settings = Data:GetActiveLayoutBarSettings(chargeBar.spellId)
            chargeBar:ApplySettings(settings)
        end
    end
end
