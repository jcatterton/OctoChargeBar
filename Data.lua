local addonName = select(1, ...)
local addon = select(2, ...)

local Data = {}
addon.Data = Data

local AceDB = LibStub("AceDB-3.0")

---@type ChargeBarSettings
Data.defaultBarSettings = {
    spellId = 51505, -- Lava Burst
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

Data.defaultDB = {
    profile = {
        bars = {}
    },
}

function Data:InitDB()
    ---@class AceDBObject-3.0
    self.db = AceDB:New(
        addonName.."DB",
        self.defaultDB
    )
end
