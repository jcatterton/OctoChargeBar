local addonName = select(1, ...)
local addon = select(2, ...)

local Util = {}
addon.Util = Util

function Util:GetActiveSpecId()
    local specIndex = C_SpecializationInfo.GetSpecialization()
    local specId = C_SpecializationInfo.GetSpecializationInfo(specIndex)
    assert(specId, "No specID for specIndex", specIndex)

    return specId
end
