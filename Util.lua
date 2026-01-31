local addonName = select(1, ...)
local addon = select(2, ...)

local Util = {}
addon.Util = Util

function Util:UnpackRGBA(rgba)
    return unpack({
        rgba.r,
        rgba.g,
        rgba.b,
        rgba.a or 1
    })
end
