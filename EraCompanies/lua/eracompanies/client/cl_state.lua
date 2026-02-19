--[[
    EraCompanies — Client State
    Holds the latest server state for UI consumption.
]]

EraCompanies.State = EraCompanies.State or {}
EraCompanies.ClientSettings = EraCompanies.ClientSettings or {
    notifSound = true,
    reduceAnimations = false,
}

-- Load saved client settings from file
local function LoadClientSettings()
    if file.Exists("eracompanies_settings.json", "DATA") then
        local raw = file.Read("eracompanies_settings.json", "DATA")
        local tbl = util.JSONToTable(raw)
        if tbl then
            EraCompanies.ClientSettings = tbl
        end
    end
end

function EraCompanies.SaveClientSettings()
    file.Write("eracompanies_settings.json", util.TableToJSON(EraCompanies.ClientSettings))
end

LoadClientSettings()
