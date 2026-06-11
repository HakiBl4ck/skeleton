local function IsTLOUAdmin(ply)
    if (not IsValid(ply)) then return false end

    if (ply:GetPData("tlou_is_admin", "0") == "1") then return true end
    if (FACTION_ADMINS and ply:Team() == FACTION_ADMINS) then return true end

    return false
end

hook.Add("PlayerButtonDown", "TLOUAdminNoclip_Toggle", function(ply, button)
    if (not IsValid(ply) or not ply:IsPlayer()) then return end
    if (button ~= KEY_PERIOD) then return end
    if (not IsTLOUAdmin(ply)) then return end

    RunConsoleCommand("tlou_adminnoclip_toggle")
end)
