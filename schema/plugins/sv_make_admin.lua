if SERVER then
    -- Asigna automáticamente a un jugador con nickname específico a la facción Admins
    local TARGET_NICK = "MaxBlackwell"
    local TARGET_STEAMID = "STEAM_0:1:519185489" -- SteamID proporcionado por el usuario

    -- Asignación en jugadores ya conectados (al recargar archivos o al iniciar)
    timer.Simple(1, function()
        for _, ply in ipairs(player.GetAll()) do
            local nick = ply:Nick() or ""
            if (TARGET_STEAMID ~= "" and ply:SteamID() == TARGET_STEAMID) or string.find(string.lower(nick), string.lower(TARGET_NICK), 1, true) then
                if FACTION_ADMINS then
                    ply:SetTeam(FACTION_ADMINS)
                    ply:SetPData("tlou_is_admin", "1")
                    ply:ChatPrint("Has sido añadido a la facción Admins.")
                end
            end
        end
    end)

    -- Asignación cuando el jugador se conecte
    hook.Add("PlayerInitialSpawn", "TLOU_AutoAddAdmin", function(ply)
        local nick = ply:Nick() or ""
        if (TARGET_STEAMID ~= "" and ply:SteamID() == TARGET_STEAMID) or string.find(string.lower(nick), string.lower(TARGET_NICK), 1, true) then
            if FACTION_ADMINS then
                ply:SetTeam(FACTION_ADMINS)
                ply:SetPData("tlou_is_admin", "1")
                timer.Simple(1, function()
                    if IsValid(ply) then
                        ply:ChatPrint("Has sido añadido a la facción Admins.")
                    end
                end)
            end
        end
    end)

    -- Comando ix para que admins agreguen a otros jugadores a Admins
    if ix and ix.command then
        ix.command.Add("tlou_add_admin", {
            description = "Añadir jugador a la facción Admins por nickname o SteamID",
            syntax = "<nombre o steamid>",
            OnRun = function(self, ply, args)
                if ply:Team() ~= FACTION_ADMINS then
                    ply:ChatPrint("No tienes permiso para usar este comando.")
                    return
                end

                local targetStr = table.concat(args, " ")
                if not targetStr or targetStr == "" then
                    ply:ChatPrint("Uso: /tlou_add_admin <nombre o steamid>")
                    return
                end

                local target = nil
                for _, pl in ipairs(player.GetAll()) do
                    if pl:SteamID() == targetStr or pl:Nick() == targetStr then
                        target = pl
                        break
                    end
                end

                if not IsValid(target) then
                    ply:ChatPrint("Jugador no encontrado.")
                    return
                end

                if FACTION_ADMINS then
                    target:SetTeam(FACTION_ADMINS)
                    target:SetPData("tlou_is_admin", "1")
                    ply:ChatPrint("Jugador añadido a Admins: " .. target:Nick())
                    target:ChatPrint("Has sido añadido a la facción Admins por " .. ply:Nick())
                end
            end
        })
    end
end
