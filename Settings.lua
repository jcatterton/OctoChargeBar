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
    },
    [Settings.keys.Height] = {
        name = 'Bar Height',
        kind = LEM.SettingType.Slider,
        default = 12,
    },
    [Settings.keys.Color] = {
        name = 'Charge Color',
        description = 'Color of active charges.',
        kind = LEM.SettingType.ColorPicker,
        default = {255/255, 147/255, 85/255, 1},
        hasOpacity = true,
    },
    [Settings.keys.BorderWidth] = {
        name = 'Border Width',
        kind = LEM.SettingType.Slider,
        default = 1,
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
    assert(Settings.defaultValues[key], string.format("GetLEMSettingsObject: Invalid settings key passed in! '%s'", key))

    return Settings.defaultValues[key]
end

function Settings:GetSliderSettingsForOption(key)
    if key == Settings.keys.Width or key == Settings.keys.Height then
        return {
            minValue = 5,
            maxValue = 500,
            valueStep = 1,
        }
    elseif key == Settings.keys.BorderWidth or key == Settings.keys.TickWidth then
        return {
            minValue = 0,
            maxValue = 10,
            valueStep = 1,
        }
    elseif key == Settings.keys.RechargeTextSize then
        return {
            minValue = 6,
            maxValue = 20,
            valueStep = 1
        }
    end
    error(
        string.format(
            "Slider Settings for key '%s' are either not implemented or you're calling this with the wrong key.",
            key
        )
    )
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
