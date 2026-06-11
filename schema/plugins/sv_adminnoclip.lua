if (SERVER) then
    local function IsTLOUAdmin(ply)
        if (not IsValid(ply)) then return false end

        if (ply:GetPData("tlou_is_admin", "0") == "1") then return true end
        if (FACTION_ADMINS and ply:Team() == FACTION_ADMINS) then return true end

        return false
    end

    local function LandPlayer(ply)
        local startPos = ply:GetPos() + Vector(0, 0, 8)
        local trace = util.TraceHull({
            start = startPos,
            endpos = startPos - Vector(0, 0, 4096),
            filter = ply,
            mins = ply:OBBMins(),
            maxs = ply:OBBMaxs(),
            mask = MASK_PLAYERSOLID
        })

        local targetPos = trace.Hit and trace.HitPos or ply:GetPos()
        ply:SetMoveType(MOVETYPE_WALK)
        ply:SetNoDraw(false)
        ply:SetNotSolid(false)
        ply:SetPos(targetPos + Vector(0, 0, 4))
        ply:SetLocalVelocity(vector_origin)
        ply:Freeze(false)
    end

    local function ToggleNoclip(ply)
        if (not IsTLOUAdmin(ply)) then return end

        local enabled = ply:GetNWBool("TLOUAdminNoclip", false)

        if (enabled) then
            ply:SetNWBool("TLOUAdminNoclip", false)
            LandPlayer(ply)
        else
            ply:SetNWBool("TLOUAdminNoclip", true)
            ply:SetMoveType(MOVETYPE_NOCLIP)
            ply:Freeze(false)
        end
    end

    concommand.Add("tlou_adminnoclip_toggle", function(ply)
        if (IsValid(ply)) then
            ToggleNoclip(ply)
        end
    end)

    hook.Add("PlayerNoClip", "TLOUAdminNoclip_PlayerNoClip", function(ply, desiredState)
        if (not IsTLOUAdmin(ply)) then return end

        if (desiredState) then
            ToggleNoclip(ply)
            return false
        end

        if (ply:GetNWBool("TLOUAdminNoclip", false)) then
            ToggleNoclip(ply)
            return false
        end
    end)
end
