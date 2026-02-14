local addonName = select(1, ...)
local addon = select(2, ...)

local Data = {}
addon.Data = Data

local Util = addon.Util
local LEM = addon.LibEditMode
local AceDB = LibStub('AceDB-3.0')

Data.defaultTrackedSpellsBySpec = {
    -- Death Knight: Blood
    [250] = {
        50842, -- Blood boil
        43265 -- Death and Decay
    },

    -- Death Knight: Frost
    [251] = {
        47568 -- Empower rune weapon
    },

    -- Death Knight: Unholy
    [252] = {},

    -- Demon Hunter: Havoc
    [577] = {},

    -- Demon Hunter: Vengeance
    [581] = {},

    -- Demon Hunter: Devourer
    [1480] = {},

    -- Druid: Balance
    [102] = {
        1233346, -- Solar Eclipse
        -- 1233272, -- Lunar Eclipse. Tracking 1 spell tracks both. I think?
    },

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
        366155, -- Reversion
        358267, -- Hover
    },

    -- Evoker: Augmentation
    [1473] = {
        358267, -- Hover
        409311, -- Prescience
    },

    -- Hunter: Beast Mastery
    [253] = {
        34026, -- Kill Command
        217200, -- Barbed Shot
    },

    -- Hunter: Marksmanship
    [254] = {
        19434, -- Aimed Shot
    },

    -- Hunter: Survival
    [255] = {
        259495, -- Wildfire Bomb
    },

    -- Mage: Arcane
    [62] = {
        153626, -- Arcane Orb
        212653, -- Shimmer
    },

    -- Mage: Fire
    [63] = {
        108853, -- Fire Blast
        212653, -- Shimmer
    },

    -- Mage: Frost
    [64] = {
        44614, -- Flurry
        212653, -- Shimmer
    },

    -- Monk: Brewmaster
    [268] = {
        119582, -- Purifying Brew
        322507, -- Celestial Brew
        121253, -- Keg Smash
        109132, -- Roll
    },

    -- Monk: Mistweaver
    [270] = {
        115151, -- Renewing Mists
        109132, -- Roll
    },

    -- Monk: Windwalker
    [269] = {
        109132, -- Roll
    },

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
    [267] = {
        17962, -- Conflaguration
    },

    -- Warrior: Arms
    [71] = {},

    -- Warrior: Fury
    [72] = {},

    -- Warrior: Protection
    [73] = {},
}

Data.defaultSpellColors = {
    -- Lava Burst
    [51505] = {255/255, 147/255, 85/255, 1},
    -- Riptide
    [61295] = {38/255, 220/255, 1, 1}
}

function Data:InitDB()
    ---@class AceDBObject-3.0
    self.db = AceDB:New(
        addonName.."DB"
    )
end

function Data:GetLayoutBarSettings(layoutName, spellId)
    local specId = Util:GetActiveSpecId()
    assert(self.db.global[layoutName][specId].specBars[spellId], string.format("SpellId %d not found in layout '%s' settings for specId %d!", spellId, layoutName, specId))

    return self.db.global[layoutName][specId].specBars[spellId]
end

function Data:GetActiveLayoutBarSettings(spellId)
    local layoutName = LEM:GetActiveLayoutName()
    return self:GetLayoutBarSettings(layoutName, spellId)
end
