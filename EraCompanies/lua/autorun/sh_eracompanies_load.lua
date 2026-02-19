--[[
    EraCompanies — Shared Loader
    Loads all shared files and includes server/client files.
]]

print("[EraCompanies] Autorun loading...")

-- Shared
AddCSLuaFile("eracompanies/sh_config.lua")
include("eracompanies/sh_config.lua")

if SERVER then
    print("[EraCompanies] SERVER: Loading server files...")

    -- Server files
    include("eracompanies/server/sv_database.lua")
    include("eracompanies/server/sv_permissions.lua")
    include("eracompanies/server/sv_net.lua")

    -- Client files to send
    AddCSLuaFile("eracompanies/client/cl_state.lua")
    AddCSLuaFile("eracompanies/client/cl_net.lua")
    AddCSLuaFile("eracompanies/client/cl_menu.lua")

    print("[EraCompanies] SERVER: All files loaded.")
end

if CLIENT then
    print("[EraCompanies] CLIENT: Loading client files...")

    include("eracompanies/client/cl_state.lua")
    include("eracompanies/client/cl_net.lua")
    include("eracompanies/client/cl_menu.lua")

    print("[EraCompanies] CLIENT: All files loaded.")
end
