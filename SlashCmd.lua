local addonName = select(1, ...)
local addon = select(2, ...)

local SlashCmd = {}
addon.SlashCmd = SlashCmd

function SlashCmd:Handle(msg, editBox)
    local command, rest = msg:match("^(%S*)%s*(.-)$")
    self[command](self, rest)
end

function SlashCmd:add(args)
    local spellId, rest = args:match("^(%d*)%s*(.-)$")
    print('add', spellId, rest)
    EventRegistry:TriggerEvent(addonName..".AddBar", spellId)
end

function SlashCmd:remove(args)
    local spellId, rest = args:match("^(%d*)%s*(.-)$")
    print('remove', spellId, rest)
    EventRegistry:TriggerEvent(addonName..".RemoveBar", spellId)
end
