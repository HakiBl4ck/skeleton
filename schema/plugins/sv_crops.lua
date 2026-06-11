if (SERVER) then
    util.AddNetworkString("ixCropNotify")

    local CROP_MODELS = {
        seedling = "models/props_junk/garbage_metalcan001a.mdl",
        growing = "models/props_junk/garbage_metalcan002a.mdl",
        mature = "models/props_junk/garbage_metalcan002a.mdl"
    }

    local CROP_TYPES = {
        tomato = {
            name = "Tomate",
            growthTime = 300,
            waterTime = 120,
            yieldMin = 2,
            yieldMax = 5
        },
        carrot = {
            name = "Zanahoria",
            growthTime = 240,
            waterTime = 90,
            yieldMin = 1,
            yieldMax = 4
        },
        potato = {
            name = "Papa",
            growthTime = 360,
            waterTime = 150,
            yieldMin = 2,
            yieldMax = 6
        },
        lettuce = {
            name = "Lechuga",
            growthTime = 180,
            waterTime = 80,
            yieldMin = 1,
            yieldMax = 3
        }
    }

    local function isFarmer(ply)
        return IsValid(ply) and ply:IsPlayer()
    end

    local function notify(ply, text)
        if (IsValid(ply)) then
            ply:ChatPrint(text)
        end
    end

    local function createCropEntity(ply, cropType, pos, ang)
        local cropData = CROP_TYPES[cropType]
        if (not cropData) then
            notify(ply, "Tipo de cultivo invalido.")
            return
        end

        local entity = ents.Create("prop_physics")
        if (not IsValid(entity)) then return end

        entity:SetModel(CROP_MODELS.seedling)
        entity:SetPos(pos)
        entity:SetAngles(ang or Angle(0, 0, 0))
        entity:Spawn()
        entity:Activate()
        entity:SetMoveType(MOVETYPE_NONE)
        entity:SetSolid(SOLID_VPHYSICS)

        local id = tostring(entity:EntIndex()) .. "_" .. tostring(CurTime())
        entity.ixCrop = {
            id = id,
            type = cropType,
            name = cropData.name,
            plantedBy = IsValid(ply) and ply:SteamID() or "unknown",
            plantedAt = CurTime(),
            lastWatered = CurTime(),
            growth = 0,
            stage = 1,
            water = 100,
            ready = false
        }

        entity:SetUseType(SIMPLE_USE)
        entity:CallOnRemove("ixCropCleanup", function(ent)
            if (ent.ixCropTimer) then
                timer.Remove(ent.ixCropTimer)
            end
        end)

        local timerName = "ixCropGrow_" .. id
        entity.ixCropTimer = timerName

        timer.Create(timerName, 5, 0, function()
            if (not IsValid(entity)) then
                timer.Remove(timerName)
                return
            end

            local crop = entity.ixCrop
            if (not crop) then return end

            crop.water = math.max(0, crop.water - 5)

            if (crop.water <= 0) then
                return
            end

            local elapsed = CurTime() - crop.plantedAt
            crop.growth = math.min(100, (elapsed / cropData.growthTime) * 100)

            if (crop.growth >= 100) then
                crop.ready = true
                entity:SetModel(CROP_MODELS.mature)
                return
            end

            crop.stage = crop.growth < 33 and 1 or (crop.growth < 66 and 2 or 3)
            entity:SetModel(crop.stage == 1 and CROP_MODELS.seedling or CROP_MODELS.growing)
        end)

        return entity
    end

    local function rayPlantPos(ply)
        local trace = ply:GetEyeTraceNoCursor()
        if (not trace.Hit) then return nil end
        return trace.HitPos + trace.HitNormal * 6, Angle(0, ply:EyeAngles().y, 0)
    end

    local function getCropFromTrace(ply)
        local trace = ply:GetEyeTraceNoCursor()
        if (not IsValid(trace.Entity) or not trace.Entity.ixCrop) then return nil end
        return trace.Entity
    end

    ix.command.Add("plantar", {
        description = "Planta una semilla de cultivo.",
        syntax = "<tomato|carrot|potato|lettuce>",
        OnRun = function(self, ply, args)
            local cropType = istable(args) and tostring(args[1] or "") or tostring(args or "")
            cropType = string.lower(cropType)
            local pos, ang = rayPlantPos(ply)

            if (not pos) then
                notify(ply, "Debes apuntar a un lugar valido para plantar.")
                return
            end

            if (not CROP_TYPES[cropType]) then
                notify(ply, "Cultivo invalido. Usa tomato, carrot, potato o lettuce.")
                return
            end

            createCropEntity(ply, cropType, pos, ang)
            notify(ply, "Has plantado " .. CROP_TYPES[cropType].name .. ".")
        end
    })

    ix.command.Add("regar", {
        description = "Riega el cultivo que tengas apuntado.",
        OnRun = function(self, ply)
            local crop = getCropFromTrace(ply)
            if (not IsValid(crop)) then
                notify(ply, "No tienes un cultivo apuntado.")
                return
            end

            crop.ixCrop.water = math.min(100, (crop.ixCrop.water or 0) + 40)
            crop.ixCrop.lastWatered = CurTime()
            notify(ply, "Has regado el cultivo.")
        end
    })

    ix.command.Add("cosechar", {
        description = "Cosecha un cultivo maduro.",
        OnRun = function(self, ply)
            local crop = getCropFromTrace(ply)
            if (not IsValid(crop) or not crop.ixCrop) then
                notify(ply, "No tienes un cultivo apuntado.")
                return
            end

            if (not crop.ixCrop.ready) then
                notify(ply, "El cultivo aun no esta listo.")
                return
            end

            local cropData = CROP_TYPES[crop.ixCrop.type]
            local amount = math.random(cropData.yieldMin, cropData.yieldMax)
            notify(ply, "Has cosechado " .. amount .. "x " .. cropData.name .. ".")
            crop:Remove()
        end
    })

    hook.Add("PlayerUse", "ixCropsPlayerUse", function(ply, entity)
        if (IsValid(entity) and entity.ixCrop and isFarmer(ply)) then
            local crop = entity.ixCrop
            if (crop.ready) then
                local cropData = CROP_TYPES[crop.type]
                local amount = math.random(cropData.yieldMin, cropData.yieldMax)
                notify(ply, "Has cosechado " .. amount .. "x " .. cropData.name .. ".")
                entity:Remove()
                return false
            end
        end
    end)
end
