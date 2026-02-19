--[[
    EraCompanies — Server Net API
    All net string registrations and handlers. Every action is validated server-side.
]]

-- ═══════════════════════════════════════
-- Net string registration
-- ═══════════════════════════════════════

local netStrings = {
    "EraC_State",
    "EraC_Notification",
    "EraC_ThreadMessages",
    "EraC_RequestState",
    "EraC_ToggleDuty",
    "EraC_CreateCompany",
    "EraC_Invite",
    "EraC_AcceptInvite",
    "EraC_DeclineInvite",
    "EraC_Apply",
    "EraC_CancelApplication",
    "EraC_AcceptApplication",
    "EraC_DenyApplication",
    "EraC_SetApplicationForm",
    "EraC_BankDeposit",
    "EraC_BankWithdraw",
    "EraC_Kick",
    "EraC_SetGrade",
    "EraC_Promote",
    "EraC_Demote",
    "EraC_CreateGrade",
    "EraC_EditGrade",
    "EraC_DeleteGrade",
    "EraC_RenameCompany",
    "EraC_TransferOwnership",
    "EraC_DeleteCompany",
    "EraC_LeaveCompany",
    "EraC_SendContact",
    "EraC_GetThread",
    "EraC_ReplyThread",
}

for _, name in ipairs(netStrings) do
    util.AddNetworkString(name)
end

-- ═══════════════════════════════════════
-- Helper: Send notification
-- ═══════════════════════════════════════

local function Notify(ply, msg, isError)
    net.Start("EraC_Notification")
    net.WriteString(msg)
    net.WriteBool(isError or false)
    net.Send(ply)
end

-- ═══════════════════════════════════════
-- Helper: Build & send state to a player
-- ═══════════════════════════════════════

local function SendState(ply)
    local sid = ply:SteamID64()
    local state = {}

    state.mySteamID = sid
    state.myName = ply:Nick()
    state.isDarkRP = EraCompanies.Perm.IsDarkRP()

    -- Company & membership
    local company, mem = EraCompanies.Perm.GetPlayerCompany(ply)
    if company then
        state.myCompany = {
            id = tonumber(company.id),
            name = company.name,
            sector = company.sector,
            owner_steamid = company.owner_steamid,
            balance = tonumber(company.balance) or 0,
        }
        state.myGradeId = tonumber(mem.grade_id)

        -- Grade data
        local grade = EraCompanies.DB.GetGrade(mem.grade_id)
        if grade then
            state.myGrade = {
                id = tonumber(grade.id),
                name = grade.name,
                weight = tonumber(grade.weight),
                permissions = util.JSONToTable(grade.permissions) or {},
            }
        end

        -- Members
        local members = EraCompanies.DB.GetMembers(company.id)
        state.members = {}
        for _, m in ipairs(members) do
            table.insert(state.members, {
                steamid = m.steamid,
                name = EraCompanies.Perm.GetPlayerName(m.steamid),
                grade_id = tonumber(m.grade_id),
                grade_name = m.grade_name,
                grade_weight = tonumber(m.grade_weight),
            })
        end

        -- Grades
        local grades = EraCompanies.DB.GetGrades(company.id)
        state.grades = {}
        for _, g in ipairs(grades) do
            table.insert(state.grades, {
                id = tonumber(g.id),
                name = g.name,
                weight = tonumber(g.weight),
                permissions = util.JSONToTable(g.permissions) or {},
                is_system = tonumber(g.is_system) == 1,
                salary = tonumber(g.salary) or 0,
            })
        end

        -- Service (on duty) state
        local svc = EraCompanies.DB.GetServiceTracking(company.id, sid)
        state.onDuty = svc and (tonumber(svc.last_duty_start) or 0) > 0
        state.serviceTimeAccumulated = svc and (tonumber(svc.accumulated_seconds) or 0) or 0

        -- Applications for this company
        state.applications = {}
        local apps = EraCompanies.DB.GetApplicationsForCompany(company.id)
        for _, a in ipairs(apps) do
            table.insert(state.applications, {
                id = tonumber(a.id),
                steamid = a.steamid,
                name = EraCompanies.Perm.GetPlayerName(a.steamid),
                payload = util.JSONToTable(a.payload) or {},
                created_at = tonumber(a.created_at),
            })
        end

        -- Mail threads
        state.threads = {}
        local threads = EraCompanies.DB.GetThreads(company.id)
        for _, t in ipairs(threads) do
            table.insert(state.threads, {
                id = tonumber(t.id),
                subject = t.subject,
                author_steamid = t.author_steamid,
                author_name = EraCompanies.Perm.GetPlayerName(t.author_steamid),
                msg_count = tonumber(t.msg_count),
                created_at = tonumber(t.created_at),
                updated_at = tonumber(t.updated_at),
            })
        end

        -- Ledger
        state.ledger = {}
        local ledger = EraCompanies.DB.GetLedger(company.id, 50)
        for _, l in ipairs(ledger) do
            table.insert(state.ledger, {
                steamid = l.steamid,
                name = EraCompanies.Perm.GetPlayerName(l.steamid),
                action = l.action,
                amount = tonumber(l.amount),
                note = l.note,
                created_at = tonumber(l.created_at),
            })
        end

        -- Settings
        local settings = EraCompanies.DB.GetSettings(company.id)
        state.settings = {
            form_json = settings and (util.JSONToTable(settings.form_json) or {}) or {},
        }
    end

    -- Invites for this player
    state.invites = {}
    local invites = EraCompanies.DB.GetInvitesForPlayer(sid)
    for _, inv in ipairs(invites) do
        table.insert(state.invites, {
            id = tonumber(inv.id),
            company_id = tonumber(inv.company_id),
            company_name = inv.company_name,
            inviter_steamid = inv.inviter_steamid,
            inviter_name = EraCompanies.Perm.GetPlayerName(inv.inviter_steamid),
        })
    end

    -- My applications
    state.myApplications = {}
    local myApps = EraCompanies.DB.GetApplicationsForPlayer(sid)
    for _, a in ipairs(myApps) do
        table.insert(state.myApplications, {
            id = tonumber(a.id),
            company_id = tonumber(a.company_id),
            company_name = a.company_name,
            created_at = tonumber(a.created_at),
        })
    end

    -- All companies (for list tab)
    state.companies = {}
    local allComps = EraCompanies.DB.GetAllCompanies()
    for _, c in ipairs(allComps) do
        -- Get form for this company
        local cSettings = EraCompanies.DB.GetSettings(c.id)
        local form = cSettings and (util.JSONToTable(cSettings.form_json) or {}) or {}

        table.insert(state.companies, {
            id = tonumber(c.id),
            name = c.name,
            sector = c.sector,
            owner_steamid = c.owner_steamid,
            owner_name = EraCompanies.Perm.GetPlayerName(c.owner_steamid),
            member_count = tonumber(c.member_count),
            form = form,
        })
    end

    -- Online players (for invite picker)
    state.onlinePlayers = {}
    for _, p in ipairs(player.GetAll()) do
        table.insert(state.onlinePlayers, {
            steamid = p:SteamID64(),
            name = p:Nick(),
        })
    end

    local json = util.TableToJSON(state)
    net.Start("EraC_State")
    net.WriteUInt(#json, 32)
    net.WriteData(json, #json)
    net.Send(ply)
end

-- ═══════════════════════════════════════
-- REQUEST STATE
-- ═══════════════════════════════════════

net.Receive("EraC_RequestState", function(len, ply)
    if not IsValid(ply) then return end
    if not EraCompanies.Perm.CheckCooldown(ply, "state") then return end
    SendState(ply)
end)

-- ═══════════════════════════════════════
-- TOGGLE DUTY (se mettre en service)
-- ═══════════════════════════════════════

net.Receive("EraC_ToggleDuty", function(len, ply)
    if not IsValid(ply) then return end
    if not EraCompanies.Perm.CheckCooldown(ply, "duty") then
        Notify(ply, "Veuillez patienter.", true)
        return
    end

    local company, mem = EraCompanies.Perm.GetPlayerCompany(ply)
    if not company or not mem then
        Notify(ply, "Vous devez être dans une entreprise.", true)
        return
    end

    local grade = EraCompanies.DB.GetGrade(mem.grade_id)
    local salary = grade and (tonumber(grade.salary) or 0) or 0

    local svc = EraCompanies.DB.GetServiceTracking(company.id, ply:SteamID64())
    local lastStart = svc and svc.last_duty_start and tonumber(svc.last_duty_start) or nil
    local acc = svc and tonumber(svc.accumulated_seconds) or 0

    if lastStart and lastStart > 0 then
        -- Going OFF duty: add elapsed time, process payments
        local now = os.time()
        acc = acc + (now - lastStart)
        
        -- Process salaries (can be multiple hours)
        local salaryVal = salary
        if salaryVal > 0 and EraCompanies.Perm.IsDarkRP() then
            while acc >= 3600 do
                local comp = EraCompanies.DB.GetCompany(company.id)
                if not comp or (tonumber(comp.balance) or 0) < salaryVal then break end
                
                EraCompanies.DB.UpdateBalance(company.id, -salaryVal)
                EraCompanies.DB.AddLedgerEntry(company.id, ply:SteamID64(), "salary", -salaryVal, "Salaire (60 min de service)")
                
                if ply.addMoney then
                    ply:addMoney(salaryVal)
                end
                
                Notify(ply, "Salaire de $" .. salaryVal .. " reçu (60 min de service) !")
                acc = acc - 3600
            end
        end
        
        EraCompanies.DB.UpsertServiceTracking(company.id, ply:SteamID64(), math.floor(acc), 0)
        Notify(ply, "Vous n'êtes plus en service. Temps accumulé : " .. math.floor(acc / 60) .. " min.")
    else
        -- Going ON duty
        EraCompanies.DB.UpsertServiceTracking(company.id, ply:SteamID64(), acc, os.time())
        Notify(ply, "Vous êtes maintenant en service. Salaire : $" .. salary .. "/h (toutes les 60 min).")
    end

    SendState(ply)
end)

-- ═══════════════════════════════════════
-- CREATE COMPANY
-- ═══════════════════════════════════════

net.Receive("EraC_CreateCompany", function(len, ply)
    if not IsValid(ply) then return end
    if not EraCompanies.Perm.CheckCooldown(ply, "create") then
        Notify(ply, "Veuillez patienter avant de réessayer.", true)
        return
    end

    local name = net.ReadString()
    local sector = net.ReadString()
    name = string.Trim(name)
    sector = string.Trim(sector)

    -- Validate sector
    if sector == "" or not table.HasValue(EraCompanies.Config.Sectors, sector) then
        sector = "Autre"
    end

    -- Validate name length
    if #name < EraCompanies.Config.NameMin or #name > EraCompanies.Config.NameMax then
        Notify(ply, "Le nom doit contenir entre " .. EraCompanies.Config.NameMin .. " et " .. EraCompanies.Config.NameMax .. " caractères.", true)
        return
    end

    -- Check not already in a company
    if EraCompanies.Perm.GetMembership(ply) then
        Notify(ply, "Vous êtes déjà dans une entreprise.", true)
        return
    end

    -- Check name uniqueness
    if EraCompanies.DB.GetCompanyByName(name) then
        Notify(ply, "Ce nom est déjà pris.", true)
        return
    end

    local id = EraCompanies.DB.CreateCompany(name, ply:SteamID64(), sector)
    if not id then
        Notify(ply, "Erreur lors de la création.", true)
        return
    end

    -- Clean up any invites/applications for this player
    EraCompanies.DB.DeleteInvitesForPlayer(ply:SteamID64())
    EraCompanies.DB.DeleteApplicationsByPlayer(ply:SteamID64())

    Notify(ply, "Entreprise \"" .. name .. "\" créée avec succès !")
    SendState(ply)
end)

-- ═══════════════════════════════════════
-- INVITE
-- ═══════════════════════════════════════

net.Receive("EraC_Invite", function(len, ply)
    if not IsValid(ply) then return end
    if not EraCompanies.Perm.CheckCooldown(ply, "invite") then return end
    if not EraCompanies.Perm.HasPermission(ply, "invite") then
        Notify(ply, "Permission refusée.", true)
        return
    end

    local targetSid = net.ReadString()
    local company = EraCompanies.Perm.GetPlayerCompany(ply)
    if not company then return end

    -- Check target is not already a member
    if EraCompanies.DB.GetMemberBysteamid(targetSid) then
        Notify(ply, "Ce joueur est déjà dans une entreprise.", true)
        return
    end

    -- Check no duplicate invite
    if EraCompanies.DB.HasPendingInvite(company.id, targetSid) then
        Notify(ply, "Une invitation est déjà en attente pour ce joueur.", true)
        return
    end

    EraCompanies.DB.CreateInvite(company.id, targetSid, ply:SteamID64())
    Notify(ply, "Invitation envoyée !")
    SendState(ply)

    -- Also notify the target if online
    for _, p in ipairs(player.GetAll()) do
        if p:SteamID64() == targetSid then
            Notify(p, "Vous avez reçu une invitation de " .. company.name .. " !")
            SendState(p)
            break
        end
    end
end)

-- ═══════════════════════════════════════
-- ACCEPT INVITE
-- ═══════════════════════════════════════

net.Receive("EraC_AcceptInvite", function(len, ply)
    if not IsValid(ply) then return end
    if not EraCompanies.Perm.CheckCooldown(ply, "invite_resp") then return end

    local inviteId = net.ReadUInt(32)
    local invite = EraCompanies.DB.GetInvite(inviteId)
    if not invite or invite.target_steamid ~= ply:SteamID64() then
        Notify(ply, "Invitation invalide.", true)
        return
    end

    -- Check not already in a company
    if EraCompanies.Perm.GetMembership(ply) then
        Notify(ply, "Vous êtes déjà dans une entreprise.", true)
        EraCompanies.DB.DeleteInvite(inviteId)
        SendState(ply)
        return
    end

    -- Get default grade
    local defGrade = EraCompanies.DB.GetDefaultGrade(invite.company_id)
    if not defGrade then
        Notify(ply, "Erreur interne (grade introuvable).", true)
        return
    end

    EraCompanies.DB.AddMember(invite.company_id, ply:SteamID64(), defGrade.id)
    EraCompanies.DB.DeleteInvitesForPlayer(ply:SteamID64())
    EraCompanies.DB.DeleteApplicationsByPlayer(ply:SteamID64())

    Notify(ply, "Vous avez rejoint l'entreprise !")
    SendState(ply)
end)

-- ═══════════════════════════════════════
-- DECLINE INVITE
-- ═══════════════════════════════════════

net.Receive("EraC_DeclineInvite", function(len, ply)
    if not IsValid(ply) then return end

    local inviteId = net.ReadUInt(32)
    local invite = EraCompanies.DB.GetInvite(inviteId)
    if not invite or invite.target_steamid ~= ply:SteamID64() then return end

    EraCompanies.DB.DeleteInvite(inviteId)
    Notify(ply, "Invitation refusée.")
    SendState(ply)
end)

-- ═══════════════════════════════════════
-- APPLY
-- ═══════════════════════════════════════

net.Receive("EraC_Apply", function(len, ply)
    if not IsValid(ply) then return end
    if not EraCompanies.Perm.CheckCooldown(ply, "apply") then return end

    local companyId = net.ReadUInt(32)
    local payloadJson = net.ReadString()
    local payload = util.JSONToTable(payloadJson) or {}

    -- Check not in a company
    if EraCompanies.Perm.GetMembership(ply) then
        Notify(ply, "Vous êtes déjà dans une entreprise.", true)
        return
    end

    -- Check company exists
    local company = EraCompanies.DB.GetCompany(companyId)
    if not company then
        Notify(ply, "Entreprise introuvable.", true)
        return
    end

    -- Check no duplicate application
    if EraCompanies.DB.HasPendingApplication(companyId, ply:SteamID64()) then
        Notify(ply, "Vous avez déjà postulé à cette entreprise.", true)
        return
    end

    EraCompanies.DB.CreateApplication(companyId, ply:SteamID64(), payload)
    Notify(ply, "Candidature envoyée à " .. company.name .. " !")
    SendState(ply)
end)

-- ═══════════════════════════════════════
-- CANCEL APPLICATION
-- ═══════════════════════════════════════

net.Receive("EraC_CancelApplication", function(len, ply)
    if not IsValid(ply) then return end

    local appId = net.ReadUInt(32)
    local app = EraCompanies.DB.GetApplication(appId)
    if not app or app.steamid ~= ply:SteamID64() then
        Notify(ply, "Candidature introuvable.", true)
        return
    end

    EraCompanies.DB.SetApplicationStatus(appId, "cancelled")
    Notify(ply, "Candidature annulée.")
    SendState(ply)
end)

-- ═══════════════════════════════════════
-- ACCEPT APPLICATION
-- ═══════════════════════════════════════

net.Receive("EraC_AcceptApplication", function(len, ply)
    if not IsValid(ply) then return end
    if not EraCompanies.Perm.HasPermission(ply, "review_apps") then
        Notify(ply, "Permission refusée.", true)
        return
    end

    local appId = net.ReadUInt(32)
    local app = EraCompanies.DB.GetApplication(appId)
    if not app or app.status ~= "pending" then
        Notify(ply, "Candidature introuvable ou déjà traitée.", true)
        return
    end

    local company = EraCompanies.Perm.GetPlayerCompany(ply)
    if not company or tonumber(app.company_id) ~= tonumber(company.id) then
        Notify(ply, "Accès refusé.", true)
        return
    end

    -- Check applicant is not already in a company
    if EraCompanies.DB.GetMemberBysteamid(app.steamid) then
        EraCompanies.DB.SetApplicationStatus(appId, "denied")
        Notify(ply, "Le candidat est déjà dans une entreprise.", true)
        SendState(ply)
        return
    end

    local defGrade = EraCompanies.DB.GetDefaultGrade(company.id)
    if not defGrade then return end

    EraCompanies.DB.AddMember(company.id, app.steamid, defGrade.id)
    EraCompanies.DB.SetApplicationStatus(appId, "accepted")
    -- Clean up other invites/apps for this player
    EraCompanies.DB.DeleteInvitesForPlayer(app.steamid)

    Notify(ply, "Candidature acceptée !")
    SendState(ply)

    -- Notify the applicant if online
    for _, p in ipairs(player.GetAll()) do
        if p:SteamID64() == app.steamid then
            Notify(p, "Votre candidature chez " .. company.name .. " a été acceptée !")
            SendState(p)
            break
        end
    end
end)

-- ═══════════════════════════════════════
-- DENY APPLICATION
-- ═══════════════════════════════════════

net.Receive("EraC_DenyApplication", function(len, ply)
    if not IsValid(ply) then return end
    if not EraCompanies.Perm.HasPermission(ply, "review_apps") then
        Notify(ply, "Permission refusée.", true)
        return
    end

    local appId = net.ReadUInt(32)
    local app = EraCompanies.DB.GetApplication(appId)
    if not app or app.status ~= "pending" then return end

    local company = EraCompanies.Perm.GetPlayerCompany(ply)
    if not company or tonumber(app.company_id) ~= tonumber(company.id) then return end

    EraCompanies.DB.SetApplicationStatus(appId, "denied")
    Notify(ply, "Candidature refusée.")
    SendState(ply)
end)

-- ═══════════════════════════════════════
-- SET APPLICATION FORM
-- ═══════════════════════════════════════

net.Receive("EraC_SetApplicationForm", function(len, ply)
    if not IsValid(ply) then return end

    local company = EraCompanies.Perm.GetPlayerCompany(ply)
    if not company then return end
    if not EraCompanies.Perm.IsOwner(ply, company.id) then
        Notify(ply, "Seul le patron peut modifier le formulaire.", true)
        return
    end

    local formJson = net.ReadString()
    local form = util.JSONToTable(formJson) or {}

    -- Validate form fields
    if #form > EraCompanies.Config.MaxFormFields then
        Notify(ply, "Maximum " .. EraCompanies.Config.MaxFormFields .. " champs.", true)
        return
    end

    EraCompanies.DB.SetApplicationForm(company.id, formJson)
    Notify(ply, "Formulaire de candidature mis à jour !")
    SendState(ply)
end)

-- ═══════════════════════════════════════
-- BANK DEPOSIT
-- ═══════════════════════════════════════

net.Receive("EraC_BankDeposit", function(len, ply)
    if not IsValid(ply) then return end
    if not EraCompanies.Perm.CheckCooldown(ply, "bank") then return end
    if not EraCompanies.Perm.HasPermission(ply, "bank_deposit") then
        Notify(ply, "Permission refusée.", true)
        return
    end

    local amount = net.ReadUInt(32)
    if amount <= 0 then
        Notify(ply, "Montant invalide.", true)
        return
    end

    local company = EraCompanies.Perm.GetPlayerCompany(ply)
    if not company then return end

    -- DarkRP money check
    if EraCompanies.Perm.IsDarkRP() then
        if not ply.getDarkRPVar or ply:getDarkRPVar("money") < amount then
            Notify(ply, "Fonds insuffisants.", true)
            return
        end
        ply:addMoney(-amount)
    end

    EraCompanies.DB.UpdateBalance(company.id, amount)
    EraCompanies.DB.AddLedgerEntry(company.id, ply:SteamID64(), "deposit", amount, "Dépôt")

    Notify(ply, "Dépôt de $" .. amount .. " effectué !")
    SendState(ply)
end)

-- ═══════════════════════════════════════
-- BANK WITHDRAW
-- ═══════════════════════════════════════

net.Receive("EraC_BankWithdraw", function(len, ply)
    if not IsValid(ply) then return end
    if not EraCompanies.Perm.CheckCooldown(ply, "bank") then return end
    if not EraCompanies.Perm.HasPermission(ply, "bank_withdraw") then
        Notify(ply, "Permission refusée.", true)
        return
    end

    local amount = net.ReadUInt(32)
    if amount <= 0 then
        Notify(ply, "Montant invalide.", true)
        return
    end

    local company = EraCompanies.Perm.GetPlayerCompany(ply)
    if not company then return end

    if (tonumber(company.balance) or 0) < amount then
        Notify(ply, "Solde entreprise insuffisant.", true)
        return
    end

    EraCompanies.DB.UpdateBalance(company.id, -amount)

    if EraCompanies.Perm.IsDarkRP() and ply.addMoney then
        ply:addMoney(amount)
    end

    EraCompanies.DB.AddLedgerEntry(company.id, ply:SteamID64(), "withdraw", -amount, "Retrait")

    Notify(ply, "Retrait de $" .. amount .. " effectué !")
    SendState(ply)
end)

-- ═══════════════════════════════════════
-- KICK
-- ═══════════════════════════════════════

net.Receive("EraC_Kick", function(len, ply)
    if not IsValid(ply) then return end
    if not EraCompanies.Perm.CheckCooldown(ply, "kick") then return end
    if not EraCompanies.Perm.HasPermission(ply, "kick") then
        Notify(ply, "Permission refusée.", true)
        return
    end

    local targetSid = net.ReadString()
    local company = EraCompanies.Perm.GetPlayerCompany(ply)
    if not company then return end

    -- Cannot kick owner
    if company.owner_steamid == targetSid then
        Notify(ply, "Impossible d'expulser le patron.", true)
        return
    end

    -- Hierarchy check
    if not EraCompanies.Perm.CanActOn(ply, targetSid) then
        Notify(ply, "Vous ne pouvez pas agir sur ce membre.", true)
        return
    end

    -- Check target is in same company
    local targetMem = EraCompanies.DB.GetMemberBysteamid(targetSid)
    if not targetMem or tonumber(targetMem.company_id) ~= tonumber(company.id) then
        Notify(ply, "Ce joueur n'est pas dans votre entreprise.", true)
        return
    end

    EraCompanies.DB.RemoveMember(targetSid)
    EraCompanies.DB.AddLedgerEntry(company.id, ply:SteamID64(), "kick", 0,
        "Expulsé: " .. EraCompanies.Perm.GetPlayerName(targetSid))

    Notify(ply, "Membre expulsé !")
    SendState(ply)

    -- Notify target if online
    for _, p in ipairs(player.GetAll()) do
        if p:SteamID64() == targetSid then
            Notify(p, "Vous avez été expulsé de " .. company.name .. ".")
            SendState(p)
            break
        end
    end
end)

-- ═══════════════════════════════════════
-- SET GRADE
-- ═══════════════════════════════════════

net.Receive("EraC_SetGrade", function(len, ply)
    if not IsValid(ply) then return end
    if not EraCompanies.Perm.HasPermission(ply, "set_grade") then
        Notify(ply, "Permission refusée.", true)
        return
    end

    local targetSid = net.ReadString()
    local gradeId = net.ReadUInt(32)

    local company = EraCompanies.Perm.GetPlayerCompany(ply)
    if not company then return end

    -- Cannot change owner's grade (unless you are owner)
    if company.owner_steamid == targetSid and company.owner_steamid ~= ply:SteamID64() then
        Notify(ply, "Impossible de modifier le grade du patron.", true)
        return
    end

    -- Hierarchy check
    if not EraCompanies.Perm.CanActOn(ply, targetSid) then
        Notify(ply, "Vous ne pouvez pas agir sur ce membre.", true)
        return
    end

    -- Check grade belongs to same company
    local grade = EraCompanies.DB.GetGrade(gradeId)
    if not grade or tonumber(grade.company_id) ~= tonumber(company.id) then
        Notify(ply, "Grade invalide.", true)
        return
    end

    -- Cannot assign a grade equal or higher than own (unless owner)
    local actorGrade = EraCompanies.Perm.GetPlayerGrade(ply)
    if actorGrade and not EraCompanies.Perm.IsOwner(ply, company.id) then
        if tonumber(grade.weight) >= tonumber(actorGrade.weight) then
            Notify(ply, "Vous ne pouvez pas assigner un grade égal ou supérieur au vôtre.", true)
            return
        end
    end

    -- Cannot assign Owner grade
    if tonumber(grade.is_system) == 1 and grade.name == "Patron" then
        Notify(ply, "Utilisez le transfert de propriété pour cela.", true)
        return
    end

    EraCompanies.DB.SetMemberGrade(targetSid, gradeId)
    Notify(ply, "Grade mis à jour !")
    SendState(ply)
end)

-- ═══════════════════════════════════════
-- PROMOTE
-- ═══════════════════════════════════════

net.Receive("EraC_Promote", function(len, ply)
    if not IsValid(ply) then return end
    if not EraCompanies.Perm.HasPermission(ply, "promote") then
        Notify(ply, "Permission refusée.", true)
        return
    end

    local targetSid = net.ReadString()
    local company = EraCompanies.Perm.GetPlayerCompany(ply)
    if not company then return end

    if not EraCompanies.Perm.CanActOn(ply, targetSid) then
        Notify(ply, "Vous ne pouvez pas agir sur ce membre.", true)
        return
    end

    -- Get target's current grade and find next higher grade
    local targetMem = EraCompanies.DB.GetMemberBysteamid(targetSid)
    if not targetMem then return end
    local currentGrade = EraCompanies.DB.GetGrade(targetMem.grade_id)
    if not currentGrade then return end

    local grades = EraCompanies.DB.GetGrades(company.id)
    local nextGrade = nil
    local currentWeight = tonumber(currentGrade.weight)
    local actorGrade = EraCompanies.Perm.GetPlayerGrade(ply)
    local actorWeight = actorGrade and tonumber(actorGrade.weight) or 0

    -- Find next grade above current weight but below actor weight (unless owner)
    for _, g in ipairs(grades) do
        local gw = tonumber(g.weight)
        if gw > currentWeight then
            -- Unless owner, cannot promote above own weight
            if EraCompanies.Perm.IsOwner(ply, company.id) or gw < actorWeight then
                if g.name ~= "Patron" then -- Cannot promote to owner
                    if not nextGrade or gw < tonumber(nextGrade.weight) then
                        nextGrade = g
                    end
                end
            end
        end
    end

    if not nextGrade then
        Notify(ply, "Aucun grade supérieur disponible.", true)
        return
    end

    EraCompanies.DB.SetMemberGrade(targetSid, nextGrade.id)
    Notify(ply, EraCompanies.Perm.GetPlayerName(targetSid) .. " promu(e) au grade " .. nextGrade.name .. " !")
    SendState(ply)
end)

-- ═══════════════════════════════════════
-- DEMOTE
-- ═══════════════════════════════════════

net.Receive("EraC_Demote", function(len, ply)
    if not IsValid(ply) then return end
    if not EraCompanies.Perm.HasPermission(ply, "demote") then
        Notify(ply, "Permission refusée.", true)
        return
    end

    local targetSid = net.ReadString()
    local company = EraCompanies.Perm.GetPlayerCompany(ply)
    if not company then return end

    if company.owner_steamid == targetSid then
        Notify(ply, "Impossible de rétrograder le patron.", true)
        return
    end

    if not EraCompanies.Perm.CanActOn(ply, targetSid) then
        Notify(ply, "Vous ne pouvez pas agir sur ce membre.", true)
        return
    end

    local targetMem = EraCompanies.DB.GetMemberBysteamid(targetSid)
    if not targetMem then return end
    local currentGrade = EraCompanies.DB.GetGrade(targetMem.grade_id)
    if not currentGrade then return end

    local grades = EraCompanies.DB.GetGrades(company.id)
    local prevGrade = nil
    local currentWeight = tonumber(currentGrade.weight)

    -- Find next grade below current weight
    for _, g in ipairs(grades) do
        local gw = tonumber(g.weight)
        if gw < currentWeight then
            if not prevGrade or gw > tonumber(prevGrade.weight) then
                prevGrade = g
            end
        end
    end

    if not prevGrade then
        Notify(ply, "Aucun grade inférieur disponible.", true)
        return
    end

    EraCompanies.DB.SetMemberGrade(targetSid, prevGrade.id)
    Notify(ply, EraCompanies.Perm.GetPlayerName(targetSid) .. " rétrogradé(e) au grade " .. prevGrade.name .. ".")
    SendState(ply)
end)

-- ═══════════════════════════════════════
-- CREATE GRADE
-- ═══════════════════════════════════════

net.Receive("EraC_CreateGrade", function(len, ply)
    if not IsValid(ply) then return end
    local company, mem = EraCompanies.Perm.GetPlayerCompany(ply)
    if not company then return end
    local isOwner = EraCompanies.Perm.IsOwner(ply, company.id)
    if not isOwner and not EraCompanies.Perm.HasPermission(ply, "edit_grades") then
        Notify(ply, "Permission refusée.", true)
        return
    end

    local name = string.Trim(net.ReadString())
    local weight = net.ReadUInt(16)
    local permsJson = net.ReadString()
    local salary = net.ReadUInt(32)
    local perms = util.JSONToTable(permsJson) or {}

    if #name < 1 or #name > 24 then
        Notify(ply, "Nom de grade invalide.", true)
        return
    end

    -- Weight check: must be < actor's weight (unless owner)
    local actorGrade = EraCompanies.Perm.GetPlayerGrade(ply)
    if actorGrade and not EraCompanies.Perm.IsOwner(ply, company.id) then
        if weight >= tonumber(actorGrade.weight) then
            Notify(ply, "Le poids doit être inférieur au vôtre.", true)
            return
        end
    end

    local id = EraCompanies.DB.CreateGrade(company.id, name, weight, perms, salary)
    if not id then
        Notify(ply, "Erreur lors de la création du grade.", true)
        return
    end

    Notify(ply, "Grade \"" .. name .. "\" créé !")
    SendState(ply)
end)

-- ═══════════════════════════════════════
-- EDIT GRADE
-- ═══════════════════════════════════════

net.Receive("EraC_EditGrade", function(len, ply)
    if not IsValid(ply) then return end
    local company, mem = EraCompanies.Perm.GetPlayerCompany(ply)
    if not company then return end
    local isOwner = EraCompanies.Perm.IsOwner(ply, company.id)
    if not isOwner and not EraCompanies.Perm.HasPermission(ply, "edit_grades") then
        Notify(ply, "Permission refusée.", true)
        return
    end

    local gradeId = net.ReadUInt(32)
    local name = string.Trim(net.ReadString())
    local weight = net.ReadUInt(16)
    local permsJson = net.ReadString()
    local salary = net.ReadUInt(32)
    local perms = util.JSONToTable(permsJson) or {}

    local grade = EraCompanies.DB.GetGrade(gradeId)
    if not grade or tonumber(grade.company_id) ~= tonumber(company.id) then
        Notify(ply, "Grade invalide.", true)
        return
    end

    -- System grades: Patron = owner only. Other system grades (Membre) = editable by those with edit_grades.
    if tonumber(grade.is_system) == 1 then
        if grade.name == "Patron" then
            if not isOwner then
                Notify(ply, "Seul le patron peut modifier le grade Patron.", true)
                return
            end
            -- For Patron, only allow salary update (always full perms)
            EraCompanies.DB.UpdateGradeSalary(gradeId, salary)
            Notify(ply, "Salaire du patron mis à jour !")
        else
            -- For other system grades (e.g. Membre), allow full edit if authorized
            -- (they already have edit_grades or are owner if they reached here)
            EraCompanies.DB.UpdateGradePermsAndSalary(gradeId, perms, salary)
            Notify(ply, "Grade système mis à jour !")
        end
        SendState(ply)
        return
    end

    -- Weight check
    local actorGrade = EraCompanies.Perm.GetPlayerGrade(ply)
    if actorGrade and not EraCompanies.Perm.IsOwner(ply, company.id) then
        if weight >= tonumber(actorGrade.weight) then
            Notify(ply, "Le poids doit être inférieur au vôtre.", true)
            return
        end
    end

    EraCompanies.DB.EditGrade(gradeId, name, weight, perms, salary)
    Notify(ply, "Grade mis à jour !")
    SendState(ply)
end)

-- ═══════════════════════════════════════
-- DELETE GRADE
-- ═══════════════════════════════════════

net.Receive("EraC_DeleteGrade", function(len, ply)
    if not IsValid(ply) then return end
    local gradeId = net.ReadUInt(32)
    local company, mem = EraCompanies.Perm.GetPlayerCompany(ply)
    if not company then return end
    local isOwner = EraCompanies.Perm.IsOwner(ply, company.id)
    if not isOwner and not EraCompanies.Perm.HasPermission(ply, "edit_grades") then
        Notify(ply, "Permission refusée.", true)
        return
    end

    local grade = EraCompanies.DB.GetGrade(gradeId)
    if not grade or tonumber(grade.company_id) ~= tonumber(company.id) then return end

    if tonumber(grade.is_system) == 1 then
        Notify(ply, "Impossible de supprimer un grade système.", true)
        return
    end

    EraCompanies.DB.DeleteGrade(gradeId, company.id)
    Notify(ply, "Grade supprimé. Les membres ont été migrés.")
    SendState(ply)
end)

-- ═══════════════════════════════════════
-- RENAME COMPANY
-- ═══════════════════════════════════════

net.Receive("EraC_RenameCompany", function(len, ply)
    if not IsValid(ply) then return end
    if not EraCompanies.Perm.HasPermission(ply, "rename_company") then
        Notify(ply, "Permission refusée.", true)
        return
    end

    local newName = string.Trim(net.ReadString())
    if #newName < EraCompanies.Config.NameMin or #newName > EraCompanies.Config.NameMax then
        Notify(ply, "Nom invalide.", true)
        return
    end

    if EraCompanies.DB.GetCompanyByName(newName) then
        Notify(ply, "Ce nom est déjà pris.", true)
        return
    end

    local company = EraCompanies.Perm.GetPlayerCompany(ply)
    if not company then return end

    EraCompanies.DB.RenameCompany(company.id, newName)
    Notify(ply, "Entreprise renommée en \"" .. newName .. "\" !")
    SendState(ply)
end)

-- ═══════════════════════════════════════
-- TRANSFER OWNERSHIP
-- ═══════════════════════════════════════

net.Receive("EraC_TransferOwnership", function(len, ply)
    if not IsValid(ply) then return end

    local targetSid = net.ReadString()
    local company = EraCompanies.Perm.GetPlayerCompany(ply)
    if not company then return end

    if not EraCompanies.Perm.IsOwner(ply, company.id) then
        Notify(ply, "Seul le patron peut transférer l'entreprise.", true)
        return
    end

    -- Check target is in same company
    local targetMem = EraCompanies.DB.GetMemberBysteamid(targetSid)
    if not targetMem or tonumber(targetMem.company_id) ~= tonumber(company.id) then
        Notify(ply, "Ce joueur n'est pas dans votre entreprise.", true)
        return
    end

    -- Swap grades: new owner gets Owner grade, old owner gets target's grade
    local ownerGrade = EraCompanies.DB.GetOwnerGrade(company.id)
    local defGrade = EraCompanies.DB.GetDefaultGrade(company.id)
    if not ownerGrade or not defGrade then return end

    -- Set new owner
    EraCompanies.DB.SetOwner(company.id, targetSid)
    EraCompanies.DB.SetMemberGrade(targetSid, ownerGrade.id)
    EraCompanies.DB.SetMemberGrade(ply:SteamID64(), defGrade.id)

    EraCompanies.DB.AddLedgerEntry(company.id, ply:SteamID64(), "transfer", 0,
        "Propriété transférée à " .. EraCompanies.Perm.GetPlayerName(targetSid))

    Notify(ply, "Propriété transférée !")
    SendState(ply)

    for _, p in ipairs(player.GetAll()) do
        if p:SteamID64() == targetSid then
            Notify(p, "Vous êtes maintenant le patron de " .. company.name .. " !")
            SendState(p)
            break
        end
    end
end)

-- ═══════════════════════════════════════
-- DELETE COMPANY
-- ═══════════════════════════════════════

net.Receive("EraC_DeleteCompany", function(len, ply)
    if not IsValid(ply) then return end

    local company = EraCompanies.Perm.GetPlayerCompany(ply)
    if not company then return end

    if not EraCompanies.Perm.IsOwner(ply, company.id) then
        Notify(ply, "Seul le patron peut supprimer l'entreprise.", true)
        return
    end

    local companyName = company.name

    -- Notify all online members before deletion
    local members = EraCompanies.DB.GetMembers(company.id)
    EraCompanies.DB.DeleteCompany(company.id)

    for _, m in ipairs(members) do
        for _, p in ipairs(player.GetAll()) do
            if p:SteamID64() == m.steamid then
                Notify(p, "L'entreprise \"" .. companyName .. "\" a été supprimée.")
                SendState(p)
            end
        end
    end
end)

-- ═══════════════════════════════════════
-- LEAVE COMPANY
-- ═══════════════════════════════════════

net.Receive("EraC_LeaveCompany", function(len, ply)
    if not IsValid(ply) then return end

    local company = EraCompanies.Perm.GetPlayerCompany(ply)
    if not company then return end

    if company.owner_steamid == ply:SteamID64() then
        Notify(ply, "Transférez la propriété ou supprimez l'entreprise avant de quitter.", true)
        return
    end

    EraCompanies.DB.RemoveMember(ply:SteamID64())
    Notify(ply, "Vous avez quitté " .. company.name .. ".")
    SendState(ply)
end)

-- ═══════════════════════════════════════
-- SEND CONTACT (creates mail thread)
-- ═══════════════════════════════════════

net.Receive("EraC_SendContact", function(len, ply)
    if not IsValid(ply) then return end
    if not EraCompanies.Perm.CheckCooldown(ply, "contact") then
        Notify(ply, "Veuillez patienter.", true)
        return
    end

    local companyId = net.ReadUInt(32)
    local subject = string.Trim(net.ReadString())
    local body = string.Trim(net.ReadString())

    if #subject < 1 or #subject > 64 then
        Notify(ply, "Sujet invalide.", true)
        return
    end
    if #body < 1 or #body > 1000 then
        Notify(ply, "Message invalide.", true)
        return
    end

    local company = EraCompanies.DB.GetCompany(companyId)
    if not company then
        Notify(ply, "Entreprise introuvable.", true)
        return
    end

    EraCompanies.DB.CreateThread(companyId, subject, ply:SteamID64(), body)
    Notify(ply, "Message envoyé à " .. company.name .. " !")
    SendState(ply)
end)

-- ═══════════════════════════════════════
-- GET THREAD MESSAGES
-- ═══════════════════════════════════════

net.Receive("EraC_GetThread", function(len, ply)
    if not IsValid(ply) then return end
    if not EraCompanies.Perm.HasPermission(ply, "msg_access") then return end

    local threadId = net.ReadUInt(32)
    local thread = EraCompanies.DB.GetThread(threadId)
    if not thread then return end

    local company = EraCompanies.Perm.GetPlayerCompany(ply)
    if not company or tonumber(thread.company_id) ~= tonumber(company.id) then return end

    local messages = EraCompanies.DB.GetThreadMessages(threadId)
    local result = {}
    for _, m in ipairs(messages) do
        table.insert(result, {
            steamid = m.steamid,
            name = EraCompanies.Perm.GetPlayerName(m.steamid),
            body = m.body,
            created_at = tonumber(m.created_at),
        })
    end

    local json = util.TableToJSON({
        threadId = threadId,
        subject = thread.subject,
        messages = result,
    })

    net.Start("EraC_ThreadMessages")
    net.WriteUInt(#json, 32)
    net.WriteData(json, #json)
    net.Send(ply)
end)

-- ═══════════════════════════════════════
-- REPLY THREAD
-- ═══════════════════════════════════════

net.Receive("EraC_ReplyThread", function(len, ply)
    if not IsValid(ply) then return end
    if not EraCompanies.Perm.HasPermission(ply, "msg_write") then
        Notify(ply, "Permission refusée.", true)
        return
    end
    if not EraCompanies.Perm.CheckCooldown(ply, "reply") then return end

    local threadId = net.ReadUInt(32)
    local body = string.Trim(net.ReadString())

    if #body < 1 or #body > 1000 then
        Notify(ply, "Message invalide.", true)
        return
    end

    local thread = EraCompanies.DB.GetThread(threadId)
    if not thread then return end

    local company = EraCompanies.Perm.GetPlayerCompany(ply)
    if not company or tonumber(thread.company_id) ~= tonumber(company.id) then return end

    EraCompanies.DB.AddMessage(threadId, ply:SteamID64(), body)
    Notify(ply, "Réponse envoyée !")

    -- Re-send thread messages
    local messages = EraCompanies.DB.GetThreadMessages(threadId)
    local result = {}
    for _, m in ipairs(messages) do
        table.insert(result, {
            steamid = m.steamid,
            name = EraCompanies.Perm.GetPlayerName(m.steamid),
            body = m.body,
            created_at = tonumber(m.created_at),
        })
    end

    local json = util.TableToJSON({
        threadId = threadId,
        subject = thread.subject,
        messages = result,
    })

    net.Start("EraC_ThreadMessages")
    net.WriteUInt(#json, 32)
    net.WriteData(json, #json)
    net.Send(ply)

    SendState(ply)
end)

-- ═══════════════════════════════════════
-- THINK: Process on-duty time & salary
-- ═══════════════════════════════════════

local nextDutyTick = 0
hook.Add("Think", "EraCompanies_DutyThink", function()
    if CurTime() < nextDutyTick then return end
    nextDutyTick = CurTime() + 5

    for _, ply in ipairs(player.GetAll()) do
        if not IsValid(ply) then continue end
        local company, mem = EraCompanies.Perm.GetPlayerCompany(ply)
        if not company or not mem then continue end

        local svc = EraCompanies.DB.GetServiceTracking(company.id, ply:SteamID64())
        if not svc or (tonumber(svc.last_duty_start) or 0) <= 0 then continue end

        local grade = EraCompanies.DB.GetGrade(mem.grade_id)
        local salary = grade and (tonumber(grade.salary) or 0) or 0
        local now = os.time()
        local acc = (tonumber(svc.accumulated_seconds) or 0) + (now - tonumber(svc.last_duty_start))

        while acc >= 3600 and salary > 0 do
            local comp = EraCompanies.DB.GetCompany(company.id)
            if not comp or (tonumber(comp.balance) or 0) < salary then break end
            EraCompanies.DB.UpdateBalance(company.id, -salary)
            EraCompanies.DB.AddLedgerEntry(company.id, ply:SteamID64(), "salary", -salary, "Salaire (60 min de service)")
            if EraCompanies.Perm.IsDarkRP() and ply.addMoney then
                ply:addMoney(salary)
            end
            Notify(ply, "Salaire de $" .. salary .. " reçu (60 min de service) !")
            acc = acc - 3600
        end

        EraCompanies.DB.UpsertServiceTracking(company.id, ply:SteamID64(), math.floor(acc), now)
    end
end)

-- ═══════════════════════════════════════
-- PLAYER DISCONNECT: Finalize duty time
-- ═══════════════════════════════════════

hook.Add("PlayerDisconnected", "EraCompanies_DutyDisconnect", function(ply)
    local sid = IsValid(ply) and ply:SteamID64() or nil
    if not sid then return end

    local mem = EraCompanies.DB.GetMemberBysteamid(sid)
    if not mem then return end
    local company = EraCompanies.DB.GetCompany(mem.company_id)
    if not company then return end

    local svc = EraCompanies.DB.GetServiceTracking(company.id, sid)
    if not svc or (tonumber(svc.last_duty_start) or 0) <= 0 then return end

    local grade = EraCompanies.DB.GetGrade(mem.grade_id)
    local salary = grade and (tonumber(grade.salary) or 0) or 0
    local now = os.time()
    local acc = (tonumber(svc.accumulated_seconds) or 0) + (now - tonumber(svc.last_duty_start))

    while acc >= 3600 and salary > 0 do
        local comp = EraCompanies.DB.GetCompany(company.id)
        if not comp or (tonumber(comp.balance) or 0) < salary then break end
        EraCompanies.DB.UpdateBalance(company.id, -salary)
        EraCompanies.DB.AddLedgerEntry(company.id, sid, "salary", -salary, "Salaire (60 min de service)")
        acc = acc - 3600
    end

    EraCompanies.DB.UpsertServiceTracking(company.id, sid, math.floor(acc), 0)
end)

print("[EraCompanies] Net API loaded (" .. #netStrings .. " endpoints).")
-- ═══════════════════════════════════════
-- AUTO-OFF DUTY ON DISCONNECT
-- ═══════════════════════════════════════

hook.Add("PlayerDisconnected", "EraC_OffDutyOnDisconnect", function(ply)
    local company, mem = EraCompanies.Perm.GetPlayerCompany(ply)
    if not company or not mem then return end

    local svc = EraCompanies.DB.GetServiceTracking(company.id, ply:SteamID64())
    local lastStart = svc and svc.last_duty_start and tonumber(svc.last_duty_start) or nil
    if lastStart and lastStart > 0 then
        local now = os.time()
        local acc = (svc and tonumber(svc.accumulated_seconds) or 0) + (now - lastStart)
        
        -- Save accumulated time, but don't process salary here (to avoid issues during disconnect)
        -- Salary will be processed next time they toggle duty or via the background timer if they were still "on duty"
        EraCompanies.DB.UpsertServiceTracking(company.id, ply:SteamID64(), math.floor(acc), 0)
    end
end)

-- ═══════════════════════════════════════
-- PERIODIC SALARY CHECK (Every 60 seconds)
-- ═══════════════════════════════════════

timer.Create("EraC_SalaryTimer", 60, 0, function()
    local now = os.time()
    for _, ply in ipairs(player.GetAll()) do
        if not IsValid(ply) then continue end
        
        local company, mem = EraCompanies.Perm.GetPlayerCompany(ply)
        if not company or not mem then continue end

        local svc = EraCompanies.DB.GetServiceTracking(company.id, ply:SteamID64())
        local lastStart = svc and svc.last_duty_start and tonumber(svc.last_duty_start) or nil
        if not lastStart or lastStart <= 0 then continue end

        local acc = (svc and tonumber(svc.accumulated_seconds) or 0) + (now - lastStart)
        
        -- If reached 1 hour of work
        if acc >= 3600 then
            local grade = EraCompanies.DB.GetGrade(mem.grade_id)
            local salaryVal = grade and (tonumber(grade.salary) or 0) or 0
            
            if salaryVal > 0 and EraCompanies.Perm.IsDarkRP() then
                local comp = EraCompanies.DB.GetCompany(company.id)
                if comp and (tonumber(comp.balance) or 0) >= salaryVal then
                    -- Process payment
                    EraCompanies.DB.UpdateBalance(company.id, -salaryVal)
                    EraCompanies.DB.AddLedgerEntry(company.id, ply:SteamID64(), "salary", -salaryVal, "Salaire (60 min de service - Automatique)")
                    
                    if ply.addMoney then
                        ply:addMoney(salaryVal)
                    end
                    
                    Notify(ply, "Salaire de $" .. salaryVal .. " reçu (60 min de service) !")
                    
                    -- Reset tracking for the NEXT hour
                    acc = acc - 3600
                    EraCompanies.DB.UpsertServiceTracking(company.id, ply:SteamID64(), math.floor(acc), now)
                    SendState(ply)
                end
            end
        end
    end
end)
