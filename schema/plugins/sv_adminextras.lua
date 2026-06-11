-- Servidor: sistema de herramientas administrativas TLOU
if SERVER then
    util.AddNetworkString("TLouAdmin_SpawnProp")
    util.AddNetworkString("TLouAdmin_SetPlayermodel")

    local function IsTLOUAdmin(ply)
        if not IsValid(ply) or not ply:IsPlayer() then return false end
        -- Verificar flag persistente
        local isAdmin = ply:GetPData("tlou_is_admin", "0") == "1"
        if isAdmin then return true end
        -- Verificar equipo (si FACTION_ADMINS está disponible)
        if FACTION_ADMINS and ply:Team() == FACTION_ADMINS then return true end
        return false
    end

    local function SetAdminPlayermodel(ply, model)
        if not model or model == "" then
            ply:ChatPrint("Modelo invalido.")
            return false
        end

        if not util.IsValidModel(model) then
            ply:ChatPrint("Modelo no valido: " .. model)
            return false
        end

        ply:SetModel(model)
        ply:SetPData("tlou_admin_playermodel", model)

        if ply.GetCharacter then
            local char = ply:GetCharacter()
            if char then
                char:SetModel(model)
            end
        end

        ply:SetupHands()
        ply:ChatPrint("Playermodel cambiado a: " .. model)
        return true
    end

    local function AllowAdminSpawn(ply)
        if IsTLOUAdmin(ply) then return true end
    end

    hook.Add("PlayerSpawnProp", "TLOUAdmin_AllowSpawnProp", AllowAdminSpawn)
    hook.Add("PlayerSpawnEffect", "TLOUAdmin_AllowSpawnEffect", AllowAdminSpawn)
    hook.Add("PlayerSpawnNPC", "TLOUAdmin_AllowSpawnNPC", AllowAdminSpawn)
    hook.Add("PlayerSpawnRagdoll", "TLOUAdmin_AllowSpawnRagdoll", AllowAdminSpawn)
    hook.Add("PlayerSpawnSENT", "TLOUAdmin_AllowSpawnSENT", AllowAdminSpawn)
    hook.Add("PlayerSpawnSWEP", "TLOUAdmin_AllowSpawnSWEP", AllowAdminSpawn)
    hook.Add("PlayerSpawnVehicle", "TLOUAdmin_AllowSpawnVehicle", AllowAdminSpawn)

    hook.Add("CanTool", "TLOUAdmin_AllowTools", function(ply)
        if IsTLOUAdmin(ply) then return true end
    end)

    net.Receive("TLouAdmin_SpawnProp", function(len, ply)
        print("[TLouAdmin] SpawnProp request from " .. ply:Nick())
        if not IsTLOUAdmin(ply) then 
            print("[TLouAdmin] " .. ply:Nick() .. " no tiene permisos admin")
            ply:ChatPrint("No tienes permisos de admin.")
            return 
        end

        local model = net.ReadString()
        print("[TLouAdmin] Intentando spawnear modelo: " .. model)
        if not model or model == "" then 
            ply:ChatPrint("Modelo inválido.")
            return 
        end
        if not util.IsValidModel(model) then 
            print("[TLouAdmin] Modelo no válido")
            ply:ChatPrint("Modelo no válido: " .. model)
            return 
        end

        local trace = ply:GetEyeTraceNoCursor()
        if not trace.Hit then 
            ply:ChatPrint("Debes apuntar a una superficie.")
            return 
        end

        local ent = ents.Create("prop_physics")
        if not IsValid(ent) then 
            ply:ChatPrint("Error al crear el objeto.")
            return 
        end

        ent:SetModel(model)
        ent:SetPos(trace.HitPos + trace.HitNormal * 8)
        ent:SetAngles(Angle(0, ply:EyeAngles().y, 0))
        ent:Spawn()
        ent:Activate()

        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
        end

        print("[TLouAdmin] Objeto spawneado exitosamente")
        ply:ChatPrint("Objeto colocado: " .. model)
    end)

    net.Receive("TLouAdmin_SetPlayermodel", function(len, ply)
        print("[TLouAdmin] SetPlayermodel request from " .. ply:Nick())
        if not IsTLOUAdmin(ply) then 
            print("[TLouAdmin] " .. ply:Nick() .. " no tiene permisos admin")
            ply:ChatPrint("No tienes permisos de admin.")
            return 
        end

        local model = net.ReadString()
        print("[TLouAdmin] Intentando cambiar modelo a: " .. model)
        if not model or model == "" then 
            ply:ChatPrint("Modelo inválido.")
            return 
        end
        if not util.IsValidModel(model) then 
            print("[TLouAdmin] Modelo no válido")
            ply:ChatPrint("Modelo no válido: " .. model)
            return 
        end

        if SetAdminPlayermodel(ply, model) then
            print("[TLouAdmin] Modelo cambiado exitosamente")
        end
    end)

    local function RegisterAdminExtraCommands()
        if not ix or not ix.command then
            return false
        end

        if not ix.command.list or not ix.command.list["tlou_admin_model"] then
            ix.command.Add("tlou_admin_model", {
                description = "Cambiar tu playermodel de admin",
                syntax = "<ruta del modelo>",
                OnRun = function(self, ply, args)
                    if not IsTLOUAdmin(ply) then
                        ply:ChatPrint("No tienes permisos de admin.")
                        return
                    end

                    local model = istable(args) and table.concat(args, " ") or tostring(args or "")
                    if model == "" then
                        ply:ChatPrint("Uso: /tlou_admin_model models/player/kleiner.mdl")
                        return
                    end

                    SetAdminPlayermodel(ply, model)
                end
            })
        end

        return true
    end

    if not RegisterAdminExtraCommands() then
        hook.Add("InitializedSchema", "TLOUAdminExtras_RegisterCommands", function()
            if RegisterAdminExtraCommands() then
                hook.Remove("InitializedSchema", "TLOUAdminExtras_RegisterCommands")
            end
        end)

        timer.Create("TLOUAdminExtras_RegisterCommands", 1, 10, function()
            if RegisterAdminExtraCommands() then
                timer.Remove("TLOUAdminExtras_RegisterCommands")
            end
        end)
    end
end
