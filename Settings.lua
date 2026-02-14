local addonName = select(1, ...)
local addon = select(2, ...)

local Settings = {}
addon.Settings = Settings
local Util = addon.Util
local Data = addon.Data
local LEM = addon.LibEditMode

Settings.keys = {
    SpellId = "SPELL_ID",
    Enabled = "ENABLED",
    Width = "WIDTH",
    Height = "HEIGHT",
    Color = "COLOR",
    BorderWidth = "BORDER_WIDTH",
    BorderColor = "BORDER_COLOR",
    RechargeColor = "RECHARGE_COLOR",
    RechargeTextShow = "RECHARGE_TEXT_SHOW",
    RechargeTextSize = "RECHARGE_TEXT_SIZE",
    RechargeTextFont = "RECHARGE_TEXT_FONT",
    TickWidth = "TICK_WIDTH",
    TickColor = "TICK_COLOR",
    Position = "POSITION",
}

function Settings.GetDefaultEditModeFramePosition()
    return {
        point = "CENTER",
        x = 0,
        y = 0,
    }
end

Settings.defaultValues = {
    [Settings.keys.Enabled] = {
        name = 'Enabled',
        kind = LEM.SettingType.Checkbox,
        default = true,
    },
    [Settings.keys.Width] = {
        name = 'Bar Width',
        kind = LEM.SettingType.Slider,
        default = 180,
        minValue = 50,
        maxValue = 500,
        valueStep = 1,
    },
    [Settings.keys.Height] = {
        name = 'Bar Height',
        kind = LEM.SettingType.Slider,
        default = 12,
        minValue = 5,
        maxValue = 100,
        valueStep = 1,
    },
    [Settings.keys.Color] = {
        name = 'Charge Color',
        kind = LEM.SettingType.ColorPicker,
        -- Default color can be overriden for specific spells in Data.defaultTrackedSpellsBySpec.
        -- This is the fallback if a color isn't defined there.
        default = {0, 1, 0, 1},
        hasOpacity = true,
    },
    [Settings.keys.BorderWidth] = {
        name = 'Border Width',
        kind = LEM.SettingType.Slider,
        default = 1,
        minValue = 0,
        maxValue = 10,
        valueStep = 1,
    },
    [Settings.keys.BorderColor] = {
        name = 'Border Color',
        kind = LEM.SettingType.ColorPicker,
        default = {0, 0, 0, 1},
        hasOpacity = true,
    },
    [Settings.keys.RechargeColor] = {
        name = 'Recharge Bar Color',
        kind = LEM.SettingType.ColorPicker,
        default = {.6, .6, .6, .6},
        hasOpacity = true,
    },
    [Settings.keys.RechargeTextShow] = {
        name = 'Show Recharge Cooldown Text',
        kind = LEM.SettingType.Checkbox,
        default = true,
    },
    [Settings.keys.RechargeTextSize] = {
        name = 'Cooldown Text Size',
        description = 'Recharge Cooldown Text Size',
        kind = LEM.SettingType.Slider,
        default = 11,
        minValue = 6,
        maxValue = 20,
        valueStep = 1
    },
    [Settings.keys.RechargeTextFont] = {
        name = 'Cooldown Text Font',
        kind = LEM.SettingType.Dropdown,
        default = "Fonts\\FRIZQT__.TTF",
        -- TODO: Hook this up to LibSharedMedia
        values = {
            {
                text = "FRIZQT",
                value = "Fonts\\FRIZQT__.TTF",
            }
        },
    },
    [Settings.keys.TickWidth] = {
        name = 'Tick Width',
        kind = LEM.SettingType.Slider,
        default = 1,
        minValue = 0,
        maxValue = 10,
        valueStep = 1,
    },
    [Settings.keys.TickColor] = {
        name = 'Tick Color',
        kind = LEM.SettingType.ColorPicker,
        default = {0, 0, 0, 1},
    },
    [Settings.keys.Position] = {
        name = 'Position',
        kind = 'Internal',
        default = Settings.GetDefaultEditModeFramePosition()
    }
}

function Settings.GetSettingsDisplayOrder()
    return {
        Settings.keys.Enabled,
        Settings.keys.Width,
        Settings.keys.Height,
        Settings.keys.Color,
        Settings.keys.BorderWidth,
        Settings.keys.BorderColor,
        Settings.keys.RechargeColor,
        Settings.keys.RechargeTextShow,
        -- Settings.keys.RechargeTextFont,
        Settings.keys.RechargeTextSize,
        Settings.keys.TickWidth,
        Settings.keys.TickColor
    }
end

function Settings.GetLEMSettingsObject(key)
    assert(Settings.defaultValues[key], string.format("GetLEMSettingsObject: No setting found for '%s'.", key))

    return Settings.defaultValues[key]
end

function Settings:Get(layoutName, spellId, key)
    local specId = Util:GetActiveSpecId()
    assert(Data.db.global[layoutName][specId].specBars[spellId], string.format("No %d settings found for spec %d in layout '%s'.", spellId, specId, layoutName))

    local value = Data.db.global[layoutName][specId].specBars[spellId][key]
    if Settings.GetLEMSettingsObject(key).kind == LEM.SettingType.ColorPicker then
        return CreateColor(unpack(value))
    end
    return value
end

function Settings:Set(layoutName, spellId, key, value)
    local specId = Util:GetActiveSpecId()
    assert(Data.db.global[layoutName][specId].specBars[spellId])

    if Settings.GetLEMSettingsObject(key).kind == LEM.SettingType.ColorPicker then
        value = {value:GetRGBA()}
    end

    Data.db.global[layoutName][specId].specBars[spellId][key] = value

    EventRegistry:TriggerEvent(addonName..".SettingChanged", layoutName, spellId, key)
end

function Settings:CreateBarSettingsObjectFromDefaults(spellId)
    local settings = {
        [Settings.keys.SpellId] = spellId,
    }
    for key, setting in pairs(addon.Settings.defaultValues) do
        settings[key] = setting.default
    end

    -- not every spell will have a default color override, but set it here when we have one.
    if Data.defaultSpellColors[spellId] then
        settings[Settings.keys.Color] = Data.defaultSpellColors[spellId]
    end

    return settings
end
