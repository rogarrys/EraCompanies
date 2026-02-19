--[[
    EraCompanies — SQLite Database
    Creates tables, performs migrations, and provides query helpers.
]]

EraCompanies.DB = EraCompanies.DB or {}

-- ─── Initialise database ───
function EraCompanies.DB.Init()
    local queries = {
        [[CREATE TABLE IF NOT EXISTS era_companies (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            owner_steamid TEXT NOT NULL,
            sector TEXT,
            balance REAL DEFAULT 0,
            created_at INTEGER DEFAULT (strftime('%s','now'))
        )]],
        [[CREATE TABLE IF NOT EXISTS era_grades (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            company_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            weight INTEGER DEFAULT 0,
            permissions TEXT DEFAULT '[]',
            is_system INTEGER DEFAULT 0,
            salary REAL DEFAULT 0,
            FOREIGN KEY (company_id) REFERENCES era_companies(id)
        )]],
        [[CREATE TABLE IF NOT EXISTS era_members (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            company_id INTEGER NOT NULL,
            steamid TEXT NOT NULL,
            grade_id INTEGER NOT NULL,
            joined_at INTEGER DEFAULT (strftime('%s','now')),
            FOREIGN KEY (company_id) REFERENCES era_companies(id),
            FOREIGN KEY (grade_id) REFERENCES era_grades(id)
        )]],
        [[CREATE TABLE IF NOT EXISTS era_invites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            company_id INTEGER NOT NULL,
            target_steamid TEXT NOT NULL,
            inviter_steamid TEXT NOT NULL,
            created_at INTEGER DEFAULT (strftime('%s','now')),
            FOREIGN KEY (company_id) REFERENCES era_companies(id)
        )]],
        [[CREATE TABLE IF NOT EXISTS era_applications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            company_id INTEGER NOT NULL,
            steamid TEXT NOT NULL,
            payload TEXT DEFAULT '{}',
            status TEXT DEFAULT 'pending',
            created_at INTEGER DEFAULT (strftime('%s','now')),
            FOREIGN KEY (company_id) REFERENCES era_companies(id)
        )]],
        [[CREATE TABLE IF NOT EXISTS era_company_settings (
            company_id INTEGER PRIMARY KEY,
            form_json TEXT DEFAULT '[]',
            FOREIGN KEY (company_id) REFERENCES era_companies(id)
        )]],
        [[CREATE TABLE IF NOT EXISTS era_ledger (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            company_id INTEGER NOT NULL,
            steamid TEXT NOT NULL,
            action TEXT NOT NULL,
            amount REAL DEFAULT 0,
            note TEXT DEFAULT '',
            created_at INTEGER DEFAULT (strftime('%s','now')),
            FOREIGN KEY (company_id) REFERENCES era_companies(id)
        )]],
        [[CREATE TABLE IF NOT EXISTS era_mail_threads (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            company_id INTEGER NOT NULL,
            subject TEXT NOT NULL,
            author_steamid TEXT NOT NULL,
            created_at INTEGER DEFAULT (strftime('%s','now')),
            updated_at INTEGER DEFAULT (strftime('%s','now')),
            FOREIGN KEY (company_id) REFERENCES era_companies(id)
        )]],
        [[CREATE TABLE IF NOT EXISTS era_mail_messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            thread_id INTEGER NOT NULL,
            steamid TEXT NOT NULL,
            body TEXT NOT NULL,
            created_at INTEGER DEFAULT (strftime('%s','now')),
            FOREIGN KEY (thread_id) REFERENCES era_mail_threads(id)
        )]],
        [[CREATE TABLE IF NOT EXISTS era_service_tracking (
            company_id INTEGER NOT NULL,
            steamid TEXT NOT NULL,
            accumulated_seconds INTEGER DEFAULT 0,
            last_duty_start INTEGER,
            PRIMARY KEY (company_id, steamid),
            FOREIGN KEY (company_id) REFERENCES era_companies(id)
        )]],
    }

    for _, q in ipairs(queries) do
        sql.Query(q)
        if sql.LastError() and sql.LastError() ~= "" then
            ErrorNoHalt("[EraCompanies] SQL Error: " .. sql.LastError() .. "\n")
        end
    end

    -- Migration: add sector to companies
    local colsComp = sql.Query("PRAGMA table_info(era_companies)")
    local hasSector = false
    if colsComp then
        for _, c in ipairs(colsComp) do
            if c.name == "sector" then hasSector = true break end
        end
    end
    if not hasSector then
        sql.Query("ALTER TABLE era_companies ADD COLUMN sector TEXT")
    end

    print("[EraCompanies] Database initialised.")
end

-- ═══════════════════════════════════════
-- COMPANY queries
-- ═══════════════════════════════════════

function EraCompanies.DB.CreateCompany(name, ownerSteamID, sector)
    sql.Query(string.format(
        "INSERT INTO era_companies (name, owner_steamid, sector) VALUES (%s, %s, %s)",
        sql.SQLStr(name), sql.SQLStr(ownerSteamID), sql.SQLStr(sector or "Autre")
    ))
    if sql.LastError() and sql.LastError() ~= "" then return nil, sql.LastError() end

    local id = sql.QueryValue("SELECT last_insert_rowid()")
    id = tonumber(id)

    -- Create default system grades
    for _, g in ipairs(EraCompanies.DefaultGrades) do
        local perms = util.TableToJSON(g.permissions)
        local salary = g.salary and tonumber(g.salary) or 0
        sql.Query(string.format(
            "INSERT INTO era_grades (company_id, name, weight, permissions, is_system, salary) VALUES (%d, %s, %d, %s, %d, %s)",
            id, sql.SQLStr(g.name), g.weight, sql.SQLStr(perms), g.is_system and 1 or 0, salary
        ))
    end

    -- Create settings row
    sql.Query(string.format(
        "INSERT INTO era_company_settings (company_id) VALUES (%d)", id
    ))

    -- Get owner grade ID
    local ownerGrade = sql.QueryRow(string.format(
        "SELECT id FROM era_grades WHERE company_id = %d AND name = 'Patron'", id
    ))

    -- Add owner as member
    if ownerGrade then
        sql.Query(string.format(
            "INSERT INTO era_members (company_id, steamid, grade_id) VALUES (%d, %s, %d)",
            id, sql.SQLStr(ownerSteamID), tonumber(ownerGrade.id)
        ))
    end

    return id
end

function EraCompanies.DB.DeleteCompany(companyId)
    local id = tonumber(companyId)
    sql.Query("DELETE FROM era_service_tracking WHERE company_id = " .. id)
    sql.Query("DELETE FROM era_mail_messages WHERE thread_id IN (SELECT id FROM era_mail_threads WHERE company_id = " .. id .. ")")
    sql.Query("DELETE FROM era_mail_threads WHERE company_id = " .. id)
    sql.Query("DELETE FROM era_ledger WHERE company_id = " .. id)
    sql.Query("DELETE FROM era_applications WHERE company_id = " .. id)
    sql.Query("DELETE FROM era_invites WHERE company_id = " .. id)
    sql.Query("DELETE FROM era_members WHERE company_id = " .. id)
    sql.Query("DELETE FROM era_grades WHERE company_id = " .. id)
    sql.Query("DELETE FROM era_company_settings WHERE company_id = " .. id)
    sql.Query("DELETE FROM era_companies WHERE id = " .. id)
end

function EraCompanies.DB.GetCompany(companyId)
    return sql.QueryRow("SELECT * FROM era_companies WHERE id = " .. tonumber(companyId))
end

function EraCompanies.DB.GetCompanyByName(name)
    return sql.QueryRow("SELECT * FROM era_companies WHERE name = " .. sql.SQLStr(name))
end

function EraCompanies.DB.GetAllCompanies()
    return sql.Query("SELECT c.*, (SELECT COUNT(*) FROM era_members WHERE company_id = c.id) as member_count FROM era_companies c ORDER BY c.name ASC") or {}
end

function EraCompanies.DB.RenameCompany(companyId, newName)
    sql.Query(string.format("UPDATE era_companies SET name = %s WHERE id = %d", sql.SQLStr(newName), tonumber(companyId)))
    return not (sql.LastError() and sql.LastError() ~= "")
end

function EraCompanies.DB.SetOwner(companyId, steamid)
    sql.Query(string.format("UPDATE era_companies SET owner_steamid = %s WHERE id = %d", sql.SQLStr(steamid), tonumber(companyId)))
end

-- ═══════════════════════════════════════
-- MEMBER queries
-- ═══════════════════════════════════════

function EraCompanies.DB.GetMembers(companyId)
    return sql.Query(string.format(
        "SELECT m.*, g.name as grade_name, g.weight as grade_weight FROM era_members m LEFT JOIN era_grades g ON m.grade_id = g.id WHERE m.company_id = %d ORDER BY g.weight DESC",
        tonumber(companyId)
    )) or {}
end

function EraCompanies.DB.GetMemberBysteamid(steamid)
    return sql.QueryRow("SELECT * FROM era_members WHERE steamid = " .. sql.SQLStr(steamid))
end

function EraCompanies.DB.AddMember(companyId, steamid, gradeId)
    sql.Query(string.format(
        "INSERT INTO era_members (company_id, steamid, grade_id) VALUES (%d, %s, %d)",
        tonumber(companyId), sql.SQLStr(steamid), tonumber(gradeId)
    ))
end

function EraCompanies.DB.RemoveMember(steamid)
    sql.Query("DELETE FROM era_members WHERE steamid = " .. sql.SQLStr(steamid))
end

function EraCompanies.DB.SetMemberGrade(steamid, gradeId)
    sql.Query(string.format(
        "UPDATE era_members SET grade_id = %d WHERE steamid = %s",
        tonumber(gradeId), sql.SQLStr(steamid)
    ))
end

-- ═══════════════════════════════════════
-- GRADE queries
-- ═══════════════════════════════════════

function EraCompanies.DB.GetGrades(companyId)
    return sql.Query(string.format(
        "SELECT id, company_id, name, weight, permissions, is_system, COALESCE(salary, 0) as salary FROM era_grades WHERE company_id = %d ORDER BY weight DESC",
        tonumber(companyId)
    )) or {}
end

function EraCompanies.DB.GetGrade(gradeId)
    return sql.QueryRow("SELECT * FROM era_grades WHERE id = " .. tonumber(gradeId))
end

function EraCompanies.DB.GetDefaultGrade(companyId)
    return sql.QueryRow(string.format(
        "SELECT * FROM era_grades WHERE company_id = %d AND name = 'Membre' AND is_system = 1",
        tonumber(companyId)
    ))
end

function EraCompanies.DB.GetOwnerGrade(companyId)
    return sql.QueryRow(string.format(
        "SELECT * FROM era_grades WHERE company_id = %d AND name = 'Patron' AND is_system = 1",
        tonumber(companyId)
    ))
end

function EraCompanies.DB.CreateGrade(companyId, name, weight, permissions, salary)
    salary = salary and tonumber(salary) or 0
    sql.Query(string.format(
        "INSERT INTO era_grades (company_id, name, weight, permissions, is_system, salary) VALUES (%d, %s, %d, %s, 0, %s)",
        tonumber(companyId), sql.SQLStr(name), tonumber(weight), sql.SQLStr(util.TableToJSON(permissions)), salary
    ))
    if sql.LastError() and sql.LastError() ~= "" then return nil end
    return tonumber(sql.QueryValue("SELECT last_insert_rowid()"))
end

function EraCompanies.DB.UpdateGradeSalary(gradeId, salary)
    sql.Query(string.format(
        "UPDATE era_grades SET salary = %s WHERE id = %d",
        tonumber(salary) or 0, tonumber(gradeId)
    ))
end

function EraCompanies.DB.UpdateGradePermsAndSalary(gradeId, permissions, salary)
    sql.Query(string.format(
        "UPDATE era_grades SET permissions = %s, salary = %s WHERE id = %d",
        sql.SQLStr(util.TableToJSON(permissions)), tonumber(salary) or 0, tonumber(gradeId)
    ))
end

function EraCompanies.DB.EditGrade(gradeId, name, weight, permissions, salary)
    salary = salary and tonumber(salary) or 0
    sql.Query(string.format(
        "UPDATE era_grades SET name = %s, weight = %d, permissions = %s, salary = %s WHERE id = %d AND is_system = 0",
        sql.SQLStr(name), tonumber(weight), sql.SQLStr(util.TableToJSON(permissions)), salary, tonumber(gradeId)
    ))
end

function EraCompanies.DB.DeleteGrade(gradeId, companyId)
    -- Migrate members to default grade
    local def = EraCompanies.DB.GetDefaultGrade(companyId)
    if def then
        sql.Query(string.format(
            "UPDATE era_members SET grade_id = %d WHERE grade_id = %d",
            tonumber(def.id), tonumber(gradeId)
        ))
    end
    sql.Query("DELETE FROM era_grades WHERE id = " .. tonumber(gradeId) .. " AND is_system = 0")
end

-- ═══════════════════════════════════════
-- INVITE queries
-- ═══════════════════════════════════════

function EraCompanies.DB.CreateInvite(companyId, targetSteamID, inviterSteamID)
    sql.Query(string.format(
        "INSERT INTO era_invites (company_id, target_steamid, inviter_steamid) VALUES (%d, %s, %s)",
        tonumber(companyId), sql.SQLStr(targetSteamID), sql.SQLStr(inviterSteamID)
    ))
end

function EraCompanies.DB.GetInvitesForPlayer(steamid)
    return sql.Query(string.format(
        "SELECT i.*, c.name as company_name FROM era_invites i LEFT JOIN era_companies c ON i.company_id = c.id WHERE i.target_steamid = %s ORDER BY i.created_at DESC",
        sql.SQLStr(steamid)
    )) or {}
end

function EraCompanies.DB.GetInvite(inviteId)
    return sql.QueryRow("SELECT * FROM era_invites WHERE id = " .. tonumber(inviteId))
end

function EraCompanies.DB.DeleteInvite(inviteId)
    sql.Query("DELETE FROM era_invites WHERE id = " .. tonumber(inviteId))
end

function EraCompanies.DB.HasPendingInvite(companyId, steamid)
    local r = sql.QueryRow(string.format(
        "SELECT id FROM era_invites WHERE company_id = %d AND target_steamid = %s",
        tonumber(companyId), sql.SQLStr(steamid)
    ))
    return r ~= nil
end

function EraCompanies.DB.DeleteInvitesForPlayer(steamid)
    sql.Query("DELETE FROM era_invites WHERE target_steamid = " .. sql.SQLStr(steamid))
end

-- ═══════════════════════════════════════
-- APPLICATION queries
-- ═══════════════════════════════════════

function EraCompanies.DB.CreateApplication(companyId, steamid, payload)
    sql.Query(string.format(
        "INSERT INTO era_applications (company_id, steamid, payload) VALUES (%d, %s, %s)",
        tonumber(companyId), sql.SQLStr(steamid), sql.SQLStr(util.TableToJSON(payload))
    ))
end

function EraCompanies.DB.GetApplicationsForCompany(companyId)
    return sql.Query(string.format(
        "SELECT * FROM era_applications WHERE company_id = %d AND status = 'pending' ORDER BY created_at DESC",
        tonumber(companyId)
    )) or {}
end

function EraCompanies.DB.GetApplicationsForPlayer(steamid)
    return sql.Query(string.format(
        "SELECT a.*, c.name as company_name FROM era_applications a LEFT JOIN era_companies c ON a.company_id = c.id WHERE a.steamid = %s AND a.status = 'pending' ORDER BY a.created_at DESC",
        sql.SQLStr(steamid)
    )) or {}
end

function EraCompanies.DB.GetApplication(appId)
    return sql.QueryRow("SELECT * FROM era_applications WHERE id = " .. tonumber(appId))
end

function EraCompanies.DB.SetApplicationStatus(appId, status)
    sql.Query(string.format(
        "UPDATE era_applications SET status = %s WHERE id = %d",
        sql.SQLStr(status), tonumber(appId)
    ))
end

function EraCompanies.DB.HasPendingApplication(companyId, steamid)
    local r = sql.QueryRow(string.format(
        "SELECT id FROM era_applications WHERE company_id = %d AND steamid = %s AND status = 'pending'",
        tonumber(companyId), sql.SQLStr(steamid)
    ))
    return r ~= nil
end

function EraCompanies.DB.DeleteApplicationsByPlayer(steamid)
    sql.Query("DELETE FROM era_applications WHERE steamid = " .. sql.SQLStr(steamid))
end

-- ═══════════════════════════════════════
-- COMPANY SETTINGS queries
-- ═══════════════════════════════════════

function EraCompanies.DB.GetSettings(companyId)
    return sql.QueryRow("SELECT * FROM era_company_settings WHERE company_id = " .. tonumber(companyId))
end

function EraCompanies.DB.SetApplicationForm(companyId, formJson)
    sql.Query(string.format(
        "UPDATE era_company_settings SET form_json = %s WHERE company_id = %d",
        sql.SQLStr(formJson), tonumber(companyId)
    ))
end

-- ═══════════════════════════════════════
-- LEDGER queries
-- ═══════════════════════════════════════

function EraCompanies.DB.AddLedgerEntry(companyId, steamid, action, amount, note)
    sql.Query(string.format(
        "INSERT INTO era_ledger (company_id, steamid, action, amount, note) VALUES (%d, %s, %s, %s, %s)",
        tonumber(companyId), sql.SQLStr(steamid), sql.SQLStr(action), tonumber(amount) or 0, sql.SQLStr(note or "")
    ))
end

function EraCompanies.DB.GetLedger(companyId, limit)
    limit = limit or 50
    return sql.Query(string.format(
        "SELECT * FROM era_ledger WHERE company_id = %d ORDER BY created_at DESC LIMIT %d",
        tonumber(companyId), limit
    )) or {}
end

function EraCompanies.DB.UpdateBalance(companyId, amount)
    sql.Query(string.format(
        "UPDATE era_companies SET balance = balance + %s WHERE id = %d",
        tonumber(amount), tonumber(companyId)
    ))
end

-- ═══════════════════════════════════════
-- MAIL queries
-- ═══════════════════════════════════════

function EraCompanies.DB.GetThreads(companyId)
    return sql.Query(string.format(
        "SELECT t.*, (SELECT COUNT(*) FROM era_mail_messages WHERE thread_id = t.id) as msg_count FROM era_mail_threads t WHERE t.company_id = %d ORDER BY t.updated_at DESC",
        tonumber(companyId)
    )) or {}
end

function EraCompanies.DB.GetThread(threadId)
    return sql.QueryRow("SELECT * FROM era_mail_threads WHERE id = " .. tonumber(threadId))
end

function EraCompanies.DB.GetThreadMessages(threadId)
    return sql.Query(string.format(
        "SELECT * FROM era_mail_messages WHERE thread_id = %d ORDER BY created_at ASC",
        tonumber(threadId)
    )) or {}
end

function EraCompanies.DB.CreateThread(companyId, subject, authorSteamID, body)
    sql.Query(string.format(
        "INSERT INTO era_mail_threads (company_id, subject, author_steamid) VALUES (%d, %s, %s)",
        tonumber(companyId), sql.SQLStr(subject), sql.SQLStr(authorSteamID)
    ))
    local threadId = tonumber(sql.QueryValue("SELECT last_insert_rowid()"))

    if threadId and body then
        sql.Query(string.format(
            "INSERT INTO era_mail_messages (thread_id, steamid, body) VALUES (%d, %s, %s)",
            threadId, sql.SQLStr(authorSteamID), sql.SQLStr(body)
        ))
    end

    return threadId
end

-- ═══════════════════════════════════════
-- SERVICE TRACKING (on duty / salary)
-- ═══════════════════════════════════════

function EraCompanies.DB.GetServiceTracking(companyId, steamid)
    return sql.QueryRow(string.format(
        "SELECT * FROM era_service_tracking WHERE company_id = %d AND steamid = %s",
        tonumber(companyId), sql.SQLStr(steamid)
    ))
end

function EraCompanies.DB.UpsertServiceTracking(companyId, steamid, accumulatedSeconds, lastDutyStart)
    local lastStr = (lastDutyStart and lastDutyStart > 0) and tostring(tonumber(lastDutyStart)) or "NULL"
    sql.Query(string.format(
        "REPLACE INTO era_service_tracking (company_id, steamid, accumulated_seconds, last_duty_start) VALUES (%d, %s, %d, %s)",
        tonumber(companyId), sql.SQLStr(steamid), tonumber(accumulatedSeconds), lastStr
    ))
end

function EraCompanies.DB.AddMessage(threadId, steamid, body)
    sql.Query(string.format(
        "INSERT INTO era_mail_messages (thread_id, steamid, body) VALUES (%d, %s, %s)",
        tonumber(threadId), sql.SQLStr(steamid), sql.SQLStr(body)
    ))
    sql.Query(string.format(
        "UPDATE era_mail_threads SET updated_at = strftime('%%s','now') WHERE id = %d",
        tonumber(threadId)
    ))
end

-- ─── Initialise on load ───
EraCompanies.DB.Init()
