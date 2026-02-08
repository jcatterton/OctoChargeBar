local addonName = select(1, ...)
local addon = select(2, ...)

local Data = {}
addon.Data = Data

local Util = addon.Util
local AceDB = LibStub("AceDB-3.0")
local LEM = LibStub('LibEditMode')

---@type ChargeBarSettings
Data.defaultBarSettings = {
    enabled = true,
    spellId = nil,
    barWidth = 180,
    barHeight = 12,
    borderWidth = 1,
    borderColor = {r = 0, g = 0, b = 0, a = 1},
    chargeColor = {r = 255/255, g = 147/255, b = 85/255, a = 1},
    showRechargeText = true,
    rechargeTextFont = "Fonts\\FRIZQT__.TTF",
    rechargeTextFontSize = 11,
    rechargeColor = {r = .6, g = .6, b = .6, a = .6},
    showTicks = true,
    tickWidth = 1,
    tickColor = {r = 0, g = 0, b = 0, a = 1},
    position = {
        point = "CENTER",
        x = 0,
        y = 0
    }
}

Data.defaultTrackedSpellsBySpec = {
    -- Death Knight: Blood
    [250] = {},

    -- Death Knight: Frost
    [251] = {},

    -- Death Knight: Unholy
    [252] = {},

    -- Demon Hunter: Havoc
    [577] = {},

    -- Demon Hunter: Vengeance
    [581] = {},

    -- Demon Hunter: Devourer
    [1480] = {},

    -- Druid: Balance
    [102] = {},

    -- Druid: Feral
    [103] = {},

    -- Druid: Guardian
    [104] = {},

    -- Druid: Restoration
    [105] = {},

    -- Evoker: Devastation
    [1467] = {
        358267, -- Hover
    },

    -- Evoker: Preservation
    [1468] = {
        358267, -- Hover
    },

    -- Evoker: Augmentation
    [1473] = {
        358267, -- Hover
        409311, -- Prescience
    },

    -- Hunter: Beast Mastery
    [253] = {},

    -- Hunter: Marksmanship
    [254] = {},

    -- Hunter: Survival
    [255] = {},

    -- Mage: Arcane
    [62] = {},

    -- Mage: Fire
    [63] = {},

    -- Mage: Frost
    [64] = {},

    -- Monk: Brewmaster
    [268] = {},

    -- Monk: Mistweaver
    [270] = {},

    -- Monk: Windwalker
    [269] = {},

    -- Paladin: Holy
    [65] = {},

    -- Paladin: Protection
    [66] = {},

    -- Paladin: Retribution
    [70] = {},

    -- Priest: Discipline
    [256] = {},

    -- Priest: Holy
    [257] = {},

    -- Priest: Shadow
    [258] = {},

    -- Rogue: Assassination
    [259] = {},

    -- Rogue: Outlaw
    [260] = {},

    -- Rogue: Subtlety
    [261] = {},

    -- Shaman: Elemental
    [262] = {
        51505, -- Lava Burst
    },

    -- Shaman: Enhancement
    [263] = {},

    -- Shaman: Restoration
    [264] = {
        61295, -- Riptide
        51505, -- Lava Burst
    },

    -- Warlock: Affliction
    [265] = {},

    -- Warlock: Demonology
    [266] = {},

    -- Warlock: Destruction
    [267] = {},

    -- Warrior: Arms
    [71] = {},

    -- Warrior: Fury
    [72] = {},

    -- Warrior: Protection
    [73] = {},
}

function Data:InitDB()
    ---@class AceDBObject-3.0
    self.db = AceDB:New(
        addonName.."DB"
    )
end

function Data:GetActiveLayoutBarSettings(spellId)
    local layoutName = LEM:GetActiveLayoutName()
    local specId = Util:GetActiveSpecId()
    assert(self.db.global[layoutName][specId].specBars[spellId], string.format("SpellId %d not found in layout '%s' settings for specId %d!", spellId, layoutName, specId))

    return self.db.global[layoutName][specId].specBars[spellId]
end

function Data:GetBarSetting(layoutName, spellId, key)
    local specId = Util:GetActiveSpecId()
    assert(self.db.global[layoutName][specId].specBars[spellId])

    local value = self.db.global[layoutName][specId].specBars[spellId][key]
    return value
end

function Data:SetBarSetting(layoutName, spellId, key, value)
    local specId = Util:GetActiveSpecId()
    assert(self.db.global[layoutName][specId].specBars[spellId])

    self.db.global[layoutName][specId].specBars[spellId][key] = value
end
