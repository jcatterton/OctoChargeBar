local addonName = select(1, ...)
local addon = select(2, ...)

local LEM = LibStub('LibEditMode')

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

---Deep copy a table
---@generic T
---@param tbl T[]
---@param cache table?
---@return T[]
function Util:TableCopy(tbl, cache)
    local t = {}
    cache = cache or {}
    cache[tbl] = t
    self:TableForEach(tbl, function(v, k)
    if type(v) == "table" then
        t[k] = cache[v] or self:TableCopy(v, cache)
    else
        t[k] = v
    end
    end)
    return t
end

---Run a callback on each table item
---@generic T
---@param tbl T[]
---@param callback fun(value: T, index: number)
---@return T[]
function Util:TableForEach(tbl, callback)
    assert(tbl, "Must be a table!")
    for ik, iv in pairs(tbl) do
        callback(iv, ik)
    end
    return tbl
end
