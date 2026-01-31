local addonName = select(1, ...)
local addon = select(2, ...)

local Data = addon.Data
local ChargeBar = addon.ChargeBar
local SlashCmd = addon.SlashCmd

local Core = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceEvent-3.0")
addon.Core = Core

function Core:OnInitialize()
    Data:InitDB()
    Core.chargeBars = {}

    EventRegistry:RegisterCallback(addonName..".AddBar", Core.AddNewBar)
    EventRegistry:RegisterCallback(addonName..".RemoveBar", Core.RemoveBar)
end

function Core:OnEnable()
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("TRAIT_CONFIG_UPDATED")
    self:RegisterEvent("SPELL_UPDATE_CHARGES")

    for i, barSettings in pairs(Data.db.profile.bars) do
        local chargeBar = ChargeBar:Init(barSettings)
        table.insert(Core.chargeBars, chargeBar)
    end

    RegisterNewSlashCommand(function(msg, editBox)
        SlashCmd:Handle(msg, editBox)
    end, 'octochargebar', 'ocb')
end

function Core:OnDisable()
    self:UnregisterAllEvents()
    -- TODO: Disable all enabled charge bars.
end

function Core:SPELL_UPDATE_CHARGES(event)
    for i, chargeBar in pairs(Core.chargeBars) do
        chargeBar:HandleSpellUpdateCharges()
    end
end

function Core:PLAYER_ENTERING_WORLD(event, isLogin, isReload)
    if InCombatLockdown() then return end

    -- Possible that we can run this too early on initial login, so we delay a second in those cases.
    C_Timer.After(isLogin and 1 or 0, function()
        for i, chargeBar in pairs(Core.chargeBars) do
            chargeBar:Setup()
        end
    end)
end

function Core:TRAIT_CONFIG_UPDATED(event, configId)
    if InCombatLockdown() then return end

    for i, chargeBar in pairs(Core.chargeBars) do
        chargeBar:Setup()
        chargeBar:HandleSpellUpdateCharges()
    end
end

function Core:AddNewBar(spellId)
    print('AddNewBar', spellId)
end

function Core:RemoveBar(spellId)
    print('RemoveBar', spellId)
end
