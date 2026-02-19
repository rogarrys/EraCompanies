--[[
    EraCompanies — Client Net
    Sends requests to the server and receives state/notifications.
]]

EraCompanies.Net = EraCompanies.Net or {}

-- ═══════════════════════════════════════
-- SENDERS
-- ═══════════════════════════════════════

function EraCompanies.Net.RequestState()
    net.Start("EraC_RequestState")
    net.SendToServer()
end

function EraCompanies.Net.ToggleDuty()
    net.Start("EraC_ToggleDuty")
    net.SendToServer()
end

function EraCompanies.Net.CreateCompany(name, sector)
    net.Start("EraC_CreateCompany")
    net.WriteString(name)
    net.WriteString(sector or "Autre")
    net.SendToServer()
end

function EraCompanies.Net.Invite(targetSteamID64)
    net.Start("EraC_Invite")
    net.WriteString(targetSteamID64)
    net.SendToServer()
end

function EraCompanies.Net.AcceptInvite(inviteId)
    net.Start("EraC_AcceptInvite")
    net.WriteUInt(inviteId, 32)
    net.SendToServer()
end

function EraCompanies.Net.DeclineInvite(inviteId)
    net.Start("EraC_DeclineInvite")
    net.WriteUInt(inviteId, 32)
    net.SendToServer()
end

function EraCompanies.Net.Apply(companyId, payload)
    net.Start("EraC_Apply")
    net.WriteUInt(companyId, 32)
    net.WriteString(util.TableToJSON(payload))
    net.SendToServer()
end

function EraCompanies.Net.CancelApplication(appId)
    net.Start("EraC_CancelApplication")
    net.WriteUInt(appId, 32)
    net.SendToServer()
end

function EraCompanies.Net.AcceptApplication(appId)
    net.Start("EraC_AcceptApplication")
    net.WriteUInt(appId, 32)
    net.SendToServer()
end

function EraCompanies.Net.DenyApplication(appId)
    net.Start("EraC_DenyApplication")
    net.WriteUInt(appId, 32)
    net.SendToServer()
end

function EraCompanies.Net.SetApplicationForm(formJson)
    net.Start("EraC_SetApplicationForm")
    net.WriteString(formJson)
    net.SendToServer()
end

function EraCompanies.Net.BankDeposit(amount)
    net.Start("EraC_BankDeposit")
    net.WriteUInt(amount, 32)
    net.SendToServer()
end

function EraCompanies.Net.BankWithdraw(amount)
    net.Start("EraC_BankWithdraw")
    net.WriteUInt(amount, 32)
    net.SendToServer()
end

function EraCompanies.Net.Kick(targetSteamID64)
    net.Start("EraC_Kick")
    net.WriteString(targetSteamID64)
    net.SendToServer()
end

function EraCompanies.Net.SetGrade(targetSteamID64, gradeId)
    net.Start("EraC_SetGrade")
    net.WriteString(targetSteamID64)
    net.WriteUInt(gradeId, 32)
    net.SendToServer()
end

function EraCompanies.Net.Promote(targetSteamID64)
    net.Start("EraC_Promote")
    net.WriteString(targetSteamID64)
    net.SendToServer()
end

function EraCompanies.Net.Demote(targetSteamID64)
    net.Start("EraC_Demote")
    net.WriteString(targetSteamID64)
    net.SendToServer()
end

function EraCompanies.Net.CreateGrade(name, weight, permsJson, salary)
    net.Start("EraC_CreateGrade")
    net.WriteString(name)
    net.WriteUInt(weight, 16)
    net.WriteString(permsJson)
    net.WriteUInt(math.floor(tonumber(salary) or 0), 32)
    net.SendToServer()
end

function EraCompanies.Net.EditGrade(gradeId, name, weight, permsJson, salary)
    net.Start("EraC_EditGrade")
    net.WriteUInt(gradeId, 32)
    net.WriteString(name)
    net.WriteUInt(weight, 16)
    net.WriteString(permsJson)
    net.WriteUInt(math.floor(tonumber(salary) or 0), 32)
    net.SendToServer()
end

function EraCompanies.Net.DeleteGrade(gradeId)
    net.Start("EraC_DeleteGrade")
    net.WriteUInt(gradeId, 32)
    net.SendToServer()
end

function EraCompanies.Net.RenameCompany(newName)
    net.Start("EraC_RenameCompany")
    net.WriteString(newName)
    net.SendToServer()
end

function EraCompanies.Net.TransferOwnership(targetSteamID64)
    net.Start("EraC_TransferOwnership")
    net.WriteString(targetSteamID64)
    net.SendToServer()
end

function EraCompanies.Net.DeleteCompany()
    net.Start("EraC_DeleteCompany")
    net.SendToServer()
end

function EraCompanies.Net.LeaveCompany()
    net.Start("EraC_LeaveCompany")
    net.SendToServer()
end

function EraCompanies.Net.SendContact(companyId, subject, body)
    net.Start("EraC_SendContact")
    net.WriteUInt(companyId, 32)
    net.WriteString(subject)
    net.WriteString(body)
    net.SendToServer()
end

function EraCompanies.Net.GetThread(threadId)
    net.Start("EraC_GetThread")
    net.WriteUInt(threadId, 32)
    net.SendToServer()
end

function EraCompanies.Net.ReplyThread(threadId, body)
    net.Start("EraC_ReplyThread")
    net.WriteUInt(threadId, 32)
    net.WriteString(body)
    net.SendToServer()
end

-- ═══════════════════════════════════════
-- RECEIVERS
-- ═══════════════════════════════════════

-- Receive full state
net.Receive("EraC_State", function()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    local tbl = util.JSONToTable(data)
    if tbl then
        EraCompanies.State = tbl
        -- Push to DHTML if panel exists
        if IsValid(EraCompanies.Panel) then
            local json = string.JavascriptSafe(data)
            EraCompanies.Panel:RunJavascript('if(window.receiveState) window.receiveState("' .. json .. '");')
        end
    end
end)

-- Receive notification
net.Receive("EraC_Notification", function()
    local msg = net.ReadString()
    local isError = net.ReadBool()

    if IsValid(EraCompanies.Panel) then
        local safeMsg = string.JavascriptSafe(msg)
        EraCompanies.Panel:RunJavascript('if(window.showToast) window.showToast("' .. safeMsg .. '", ' .. tostring(isError) .. ');')
    end

    -- Play sound if enabled
    if EraCompanies.ClientSettings.notifSound then
        if isError then
            surface.PlaySound("buttons/button10.wav")
        else
            surface.PlaySound("buttons/button14.wav")
        end
    end
end)

-- Receive thread messages
net.Receive("EraC_ThreadMessages", function()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)

    if IsValid(EraCompanies.Panel) then
        local json = string.JavascriptSafe(data)
        EraCompanies.Panel:RunJavascript('if(window.receiveThreadMessages) window.receiveThreadMessages("' .. json .. '");')
    end
end)
