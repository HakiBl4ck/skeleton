-- Servidor: acciones administrativas (solo para FACTION_ADMINS)
util.AddNetworkString("AdminPanel_Action")
util.AddNetworkString("AdminPanel_Request")
util.AddNetworkString("AdminPanel_Open")

-- Comando Helix para abrir el panel desde chat: /tlou_admin_panel
if ix and ix.command then
    ix.command.Add("tlou_admin_panel", {
        description = "Abrir panel administrativo TLOU (Admins)",
        OnRun = function(self, ply)
            local isAdminFlag = ply:GetPData("tlou_is_admin", "0") == "1"
            if ply:Team() ~= FACTION_ADMINS and not isAdminFlag then
                ply:ChatPrint("No tienes permiso para abrir el panel administrativo.")
                return
            end
            net.Start("AdminPanel_Open")
            net.Send(ply)
        end
    })
end

net.Receive("AdminPanel_Action", function(len, ply)
    if ply:Team() ~= FACTION_ADMINS then
        ply:ChatPrint("No tienes permiso para usar el panel administrativo.")
        return
    end
    local action = net.ReadString()
    local steamid = net.ReadString()
    local target = nil
    for _, pl in ipairs(player.GetAll()) do
        if pl:SteamID() == steamid then target = pl break end
    end
    if not IsValid(target) or not target:IsPlayer() then
        ply:ChatPrint("Objetivo inválido.")
        return
    end
    if action == "teleport" then
        target:SetPos(ply:GetPos() + Vector(0,0,50))
        ply:ChatPrint("Jugador teletransportado.")
    elseif action == "revive" then
        target:Spawn()
        ply:ChatPrint("Jugador revivido.")
    elseif action == "heal" then
        if target.SetHealth then target:SetHealth(100) end
        ply:ChatPrint("Jugador curado.")
    elseif action == "freeze" then
        target:Freeze(not target:IsFrozen())
        ply:ChatPrint("Estado de congelado alternado.")
    elseif action == "kill" then
        target:Kill()
        ply:ChatPrint("Jugador eliminado.")
    elseif action == "kick" then
        local reason = net.ReadString()
        target:Kick(reason ~= "" and reason or "Kicked by admin panel")
    elseif action == "ban" then
        local minutes = tonumber(net.ReadString()) or 60
        local reason = net.ReadString()
        target:Ban(minutes, true)
        if (reason ~= "") then
            ply:ChatPrint("Ban aplicado: " .. reason)
        end
    else
        ply:ChatPrint("Acción desconocida: " .. tostring(action))
    end
end)
