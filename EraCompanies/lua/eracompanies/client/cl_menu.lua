--[[
    EraCompanies — Client Menu
    Creates the DHTML panel, binds F3, and sets up the JS↔Lua bridge.
    Uses DHTML directly (no DPanel wrapper) for proper keyboard input.
]]

print("[EraCompanies] cl_menu.lua loaded!")

EraCompanies.Panel = EraCompanies.Panel or nil
EraCompanies.IsOpen = EraCompanies.IsOpen or false

local function GetHTMLPath()
    -- Return the hosted URL from config
    return EraCompanies.Config.WebURL or "http://localhost/index.html"
end

function EraCompanies.OpenMenu()
    print("[EraCompanies] OpenMenu called")

    -- If already exists, just show it
    if IsValid(EraCompanies.Panel) then
        EraCompanies.Panel:SetVisible(true)
        EraCompanies.Panel:SetKeyboardInputEnabled(true)
        EraCompanies.Panel:SetMouseInputEnabled(true)
        EraCompanies.Panel:MakePopup()
        EraCompanies.Panel:RequestFocus()
        EraCompanies.IsOpen = true
        EraCompanies.Net.RequestState()
        return
    end

    local w, h = ScrW(), ScrH()
    local pw = math.floor(w * 0.70)
    local ph = math.floor(h * 0.75)

    -- Create DHTML directly — no DPanel wrapper
    local html = vgui.Create("DHTML")
    html:SetSize(pw, ph)
    html:SetPos((w - pw) / 2, (h - ph) / 2)
    html:SetAllowLua(true)
    html:SetVisible(true)
    html:SetAlpha(255)
    html:MakePopup()
    html:SetKeyboardInputEnabled(true)
    html:SetMouseInputEnabled(true)
    html:RequestFocus()

    -- Closed menu helper
    html:AddFunction("lua", "closeMenu", function()
        EraCompanies.CloseMenu()
    end)

    -- ─── JS → Lua bridge ───
    -- Add a logging function to help debug
    html:AddFunction("lua", "log", function(msg)
        print("[EraCompanies JS] " .. tostring(msg))
    end)

    html:AddFunction("lua", "requestState", function()
        EraCompanies.Net.RequestState()
    end)

    html:AddFunction("lua", "createCompany", function(name, sector)
        EraCompanies.Net.CreateCompany(name or "", sector or "Autre")
    end)

    html:AddFunction("lua", "invite", function(targetSid)
        EraCompanies.Net.Invite(targetSid or "")
    end)

    html:AddFunction("lua", "acceptInvite", function(id)
        EraCompanies.Net.AcceptInvite(tonumber(id) or 0)
    end)

    html:AddFunction("lua", "declineInvite", function(id)
        EraCompanies.Net.DeclineInvite(tonumber(id) or 0)
    end)

    html:AddFunction("lua", "apply", function(companyId, payloadJson)
        EraCompanies.Net.Apply(tonumber(companyId) or 0, util.JSONToTable(payloadJson or "{}") or {})
    end)

    html:AddFunction("lua", "cancelApplication", function(id)
        EraCompanies.Net.CancelApplication(tonumber(id) or 0)
    end)

    html:AddFunction("lua", "acceptApplication", function(id)
        EraCompanies.Net.AcceptApplication(tonumber(id) or 0)
    end)

    html:AddFunction("lua", "denyApplication", function(id)
        EraCompanies.Net.DenyApplication(tonumber(id) or 0)
    end)

    html:AddFunction("lua", "setApplicationForm", function(formJson)
        EraCompanies.Net.SetApplicationForm(formJson or "[]")
    end)

    html:AddFunction("lua", "bankDeposit", function(amount)
        EraCompanies.Net.BankDeposit(tonumber(amount) or 0)
    end)

    html:AddFunction("lua", "bankWithdraw", function(amount)
        EraCompanies.Net.BankWithdraw(tonumber(amount) or 0)
    end)

    html:AddFunction("lua", "kick", function(sid)
        EraCompanies.Net.Kick(sid or "")
    end)

    html:AddFunction("lua", "setGrade", function(sid, gradeId)
        EraCompanies.Net.SetGrade(sid or "", tonumber(gradeId) or 0)
    end)

    html:AddFunction("lua", "promote", function(sid)
        EraCompanies.Net.Promote(sid or "")
    end)

    html:AddFunction("lua", "demote", function(sid)
        EraCompanies.Net.Demote(sid or "")
    end)

    html:AddFunction("lua", "createGrade", function(name, weight, permsJson, salary)
        EraCompanies.Net.CreateGrade(name or "", tonumber(weight) or 0, permsJson or "[]", salary or 0)
    end)

    html:AddFunction("lua", "editGrade", function(gradeId, name, weight, permsJson, salary)
        EraCompanies.Net.EditGrade(tonumber(gradeId) or 0, name or "", tonumber(weight) or 0, permsJson or "[]", salary or 0)
    end)

    html:AddFunction("lua", "deleteGrade", function(gradeId)
        EraCompanies.Net.DeleteGrade(tonumber(gradeId) or 0)
    end)

    html:AddFunction("lua", "renameCompany", function(name)
        EraCompanies.Net.RenameCompany(name or "")
    end)

    html:AddFunction("lua", "transferOwnership", function(sid)
        EraCompanies.Net.TransferOwnership(sid or "")
    end)

    html:AddFunction("lua", "deleteCompany", function()
        EraCompanies.Net.DeleteCompany()
    end)

    html:AddFunction("lua", "leaveCompany", function()
        EraCompanies.Net.LeaveCompany()
    end)

    html:AddFunction("lua", "sendContact", function(companyId, subject, body)
        EraCompanies.Net.SendContact(tonumber(companyId) or 0, subject or "", body or "")
    end)

    html:AddFunction("lua", "getThread", function(threadId)
        EraCompanies.Net.GetThread(tonumber(threadId) or 0)
    end)

    html:AddFunction("lua", "replyThread", function(threadId, body)
        EraCompanies.Net.ReplyThread(tonumber(threadId) or 0, body or "")
    end)

    html:AddFunction("lua", "closeMenu", function()
        EraCompanies.CloseMenu()
    end)

    html:AddFunction("lua", "toggleDuty", function()
        EraCompanies.Net.ToggleDuty()
    end)

    html:AddFunction("lua", "getClientSettings", function()
        local json = util.TableToJSON(EraCompanies.ClientSettings)
        html:RunJavascript('if(window.receiveClientSettings) window.receiveClientSettings(' .. json .. ');')
    end)

    html:AddFunction("lua", "saveClientSettings", function(settingsJson)
        local tbl = util.JSONToTable(settingsJson or "{}")
        if tbl then
            EraCompanies.ClientSettings = tbl
            EraCompanies.SaveClientSettings()
        end
    end)

    print("[EraCompanies] Loading URL: " .. GetHTMLPath())
    html:OpenURL(GetHTMLPath())

    -- Force visibility after a delay in case CEF is being slow
    timer.Simple(2, function()
        if IsValid(html) then
            print("[EraCompanies] Manual visibility check - Visible: " .. tostring(html:IsVisible()) .. " Alpha: " .. tostring(html:GetAlpha()))
        end
    end)

    -- Test local rendering if remote fails
    timer.Simple(5, function()
        if IsValid(html) and not html.LoadedSuccessfully then
            print("[EraCompanies] Remote load might have failed, testing local rendering...")
            -- html:SetHTML("<html><body style='background:red; color:white; font-size:50px;'>TEST RENDU LOCAL OK</body></html>")
        end
    end)

    EraCompanies.Panel = html
    EraCompanies.IsOpen = true

    -- Request initial state after a brief delay (let HTML load)
    timer.Simple(0.8, function()
        if IsValid(html) then
            print("[EraCompanies] Performing initial state request after load")
            EraCompanies.Net.RequestState()
        end
    end)
end

function EraCompanies.CloseMenu()
    if IsValid(EraCompanies.Panel) then
        EraCompanies.Panel:SetVisible(false)
        EraCompanies.Panel:SetKeyboardInputEnabled(false)
        EraCompanies.Panel:SetMouseInputEnabled(false)
    end
    EraCompanies.IsOpen = false
    gui.EnableScreenClicker(false)
end

function EraCompanies.ToggleMenu()
    if EraCompanies.IsOpen and IsValid(EraCompanies.Panel) then
        EraCompanies.CloseMenu()
    else
        EraCompanies.OpenMenu()
    end
end

-- ─── Bind ShowSpare1 (F3 in Sandbox) ───
hook.Add("ShowSpare1", "EraCompanies_ShowSpare1", function()
    EraCompanies.ToggleMenu()
    return true
end)

-- ─── Fallback: KEY_F3 + Escape handling ───
hook.Add("PlayerButtonDown", "EraCompanies_ButtonDown", function(ply, btn)
    if ply ~= LocalPlayer() then return end

    if btn == KEY_F3 then
        EraCompanies.ToggleMenu()
    elseif btn == KEY_ESCAPE and EraCompanies.IsOpen then
        EraCompanies.CloseMenu()
    end
end)

-- ─── Console command (most reliable) ───
concommand.Add("eracompanies", function()
    EraCompanies.ToggleMenu()
end)

-- ─── Chat command ───
hook.Add("OnPlayerChat", "EraCompanies_ChatCmd", function(ply, text)
    if ply == LocalPlayer() and string.lower(text) == "!company" then
        EraCompanies.ToggleMenu()
    end
end)

print("[EraCompanies] cl_menu.lua initialization complete")
