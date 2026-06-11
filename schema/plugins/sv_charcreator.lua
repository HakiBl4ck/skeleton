-- Servidor: persistencia de creación de personaje
util.AddNetworkString("CharCreator_Save")
util.AddNetworkString("CharCreator_Request")
util.AddNetworkString("CharCreator_SendData")
util.AddNetworkString("CharCreator_Open")

local function getCitizenFactionIndex()
    if (isnumber(FACTION_CITIZEN)) then
        return FACTION_CITIZEN
    end

    if (ix and ix.faction and ix.faction.GetIndex) then
        return ix.faction.GetIndex("citizen") or ix.faction.GetIndex("Citizen")
    end

    return nil
end

net.Receive("CharCreator_Save", function(len, ply)
    local data = net.ReadTable()
    if not data then return end
    ply:SetPData("tlou_name", tostring(data.name or ""))
    ply:SetPData("tlou_age", tostring(data.age or ""))
    ply:SetPData("tlou_bio", tostring(data.bio or ""))
    ply:SetPData("tlou_personalidad_fisica", tostring(data.personalidad_fisica or ""))
    ply:SetPData("tlou_personalidad_psicologica", tostring(data.personalidad_psicologica or ""))
    ply:SetPData("tlou_trasfondo", tostring(data.trasfondo or ""))
    ply:SetPData("tlou_vinculos", tostring(data.vinculos or ""))

    -- Integración con Helix: si el jugador tiene un character activo, actualizamos su nombre
    if ply.GetCharacter then
        local char = ply:GetCharacter()
        if char and data.name and data.name ~= "" then
            if char.SetName then
                char:SetName(tostring(data.name))
            elseif char.SetData then
                char:SetData("name", tostring(data.name))
            end

            local citizenFaction = getCitizenFactionIndex()
            if (string.Trim(string.lower(tostring(data.name))) == "joel bill" and citizenFaction) then
                if char.SetFaction then
                    char:SetFaction(citizenFaction)
                elseif char.SetData then
                    char:SetData("faction", citizenFaction)
                end
            end

            if char.Save then
                pcall(function() char:Save() end)
            end
        end
    end

    ply:ChatPrint("Personaje guardado.")
end)

net.Receive("CharCreator_Request", function(len, ply)
    local tbl = {
        name = ply:GetPData("tlou_name", ""),
        age = ply:GetPData("tlou_age", ""),
        bio = ply:GetPData("tlou_bio", ""),
        personalidad_fisica = ply:GetPData("tlou_personalidad_fisica", ""),
        personalidad_psicologica = ply:GetPData("tlou_personalidad_psicologica", ""),
        trasfondo = ply:GetPData("tlou_trasfondo", ""),
        vinculos = ply:GetPData("tlou_vinculos", "")
    }
    net.Start("CharCreator_SendData")
    net.WriteTable(tbl)
    net.Send(ply)
end)

hook.Add("PlayerInitialSpawn", "CharCreator_SendOnSpawn", function(ply)
    timer.Simple(2, function()
        if not IsValid(ply) then return end
        local tbl = {
            name = ply:GetPData("tlou_name", ""),
            age = ply:GetPData("tlou_age", ""),
            bio = ply:GetPData("tlou_bio", ""),
            personalidad_fisica = ply:GetPData("tlou_personalidad_fisica", ""),
            personalidad_psicologica = ply:GetPData("tlou_personalidad_psicologica", ""),
            trasfondo = ply:GetPData("tlou_trasfondo", ""),
            vinculos = ply:GetPData("tlou_vinculos", "")
        }
        net.Start("CharCreator_SendData")
        net.WriteTable(tbl)
        net.Send(ply)
    end)
end)

-- Comando Helix para abrir el creador desde el chat: /tlou_crear_personaje
if ix and ix.command then
    ix.command.Add("tlou_crear_personaje", {
        description = "Abrir interfaz de creación de personaje The Last of Us",
        OnRun = function(self, ply)
            net.Start("CharCreator_SendData")
            net.WriteTable({
                name = ply:GetPData("tlou_name", ""),
                age = ply:GetPData("tlou_age", ""),
                bio = ply:GetPData("tlou_bio", "")
            })
            net.Send(ply)
        end
    })
end
