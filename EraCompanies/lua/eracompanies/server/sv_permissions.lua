--[[
    EraCompanies — Server Permissions & Helpers
    Centralises permission checks, hierarchy validation, and DarkRP detection.
]]

EraCompanies.Perm = EraCompanies.Perm or {}

-- ─── DarkRP detection ───
function EraCompanies.Perm.IsDarkRP()
    return DarkRP ~= nil and istable(DarkRP)
end

-- ─── Get a player's membership row ───
function EraCompanies.Perm.GetMembership(ply)
    return EraCompanies.DB.GetMemberBysteamid(ply:SteamID64())
end

-- ─── Get a player's company data (or nil) ───
function EraCompanies.Perm.GetPlayerCompany(ply)
    local mem = EraCompanies.Perm.GetMembership(ply)
    if not mem then return nil end
    return EraCompanies.DB.GetCompany(mem.company_id), mem
end

-- ─── Get a player's grade data ───
function EraCompanies.Perm.GetPlayerGrade(ply)
    local mem = EraCompanies.Perm.GetMembership(ply)
    if not mem then return nil end
    return EraCompanies.DB.GetGrade(mem.grade_id)
end

-- ─── Check if player is owner of a specific company ───
function EraCompanies.Perm.IsOwner(ply, companyId)
    local comp = EraCompanies.DB.GetCompany(companyId)
    if not comp then return false end
    return comp.owner_steamid == ply:SteamID64()
end

-- ─── Check if player has a specific permission ───
function EraCompanies.Perm.HasPermission(ply, permKey)
    local company, mem = EraCompanies.Perm.GetPlayerCompany(ply)
    if not company or not mem then return false end

    -- Owner bypasses all permission checks
    if company.owner_steamid == ply:SteamID64() then return true end

    local grade = EraCompanies.DB.GetGrade(mem.grade_id)
    if not grade then return false end

    local perms = util.JSONToTable(grade.permissions) or {}
    for _, p in ipairs(perms) do
        if p == permKey then return true end
    end

    return false
end

-- ─── Hierarchy check: can actor act on target? ───
-- actor must have strictly higher grade weight than target
function EraCompanies.Perm.CanActOn(actorPly, targetSteamID64)
    local actorGrade = EraCompanies.Perm.GetPlayerGrade(actorPly)
    if not actorGrade then return false end

    local targetMem = EraCompanies.DB.GetMemberBysteamid(targetSteamID64)
    if not targetMem then return false end

    local targetGrade = EraCompanies.DB.GetGrade(targetMem.grade_id)
    if not targetGrade then return false end

    -- Owner can act on everyone
    local company = EraCompanies.Perm.GetPlayerCompany(actorPly)
    if company and company.owner_steamid == actorPly:SteamID64() then return true end

    return tonumber(actorGrade.weight) > tonumber(targetGrade.weight)
end

-- ─── Anti-spam cooldown ───
EraCompanies.Perm._cooldowns = EraCompanies.Perm._cooldowns or {}

function EraCompanies.Perm.CheckCooldown(ply, action)
    local key = ply:SteamID64() .. "_" .. action
    local last = EraCompanies.Perm._cooldowns[key] or 0
    if CurTime() - last < EraCompanies.Config.Cooldown then
        return false
    end
    EraCompanies.Perm._cooldowns[key] = CurTime()
    return true
end

-- ─── Get player name by SteamID64 (online or fallback) ───
function EraCompanies.Perm.GetPlayerName(steamid64)
    for _, p in ipairs(player.GetAll()) do
        if p:SteamID64() == steamid64 then
            return p:Nick()
        end
    end
    return steamid64
end
