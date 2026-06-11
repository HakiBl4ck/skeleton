if (SERVER) then
    util.AddNetworkString("FactionManager_Data")
    util.AddNetworkString("FactionManager_Action")

    local DATA_FILE = "tlou_faction_manager.json"
    local factionManagerData = {
        overrides = {},
        members = {},
        ranks = {},
        custom = {}
    }
    local customFactionSeq = 0

    local function saveData()
        file.Write(DATA_FILE, util.TableToJSON(factionManagerData, true))
    end

    local function loadData()
        if (not file.Exists(DATA_FILE, "DATA")) then
            saveData()
            return
        end

        local raw = file.Read(DATA_FILE, "DATA") or "{}"
        factionManagerData = util.JSONToTable(raw) or factionManagerData
        factionManagerData.overrides = factionManagerData.overrides or {}
        factionManagerData.members = factionManagerData.members or {}
        factionManagerData.ranks = factionManagerData.ranks or {}
        factionManagerData.custom = factionManagerData.custom or {}
    end

    local function isAdmin(ply)
        return IsValid(ply) and (ply:Team() == FACTION_ADMINS or ply:GetPData("tlou_is_admin", "0") == "1")
    end

    local function getFactionEntries()
        local entries = {}

        for index, faction in pairs(ix.faction.indices or {}) do
            entries[#entries + 1] = {
                index = index,
                name = faction.name or ("Faction " .. tostring(index)),
                description = faction.description or "",
                color = faction.color or Color(255, 255, 255),
                isDefault = faction.isDefault or false,
                isCustom = false,
                pay = faction.pay or 0,
                weapons = faction.weapons or {},
                models = faction.models or {},
                isGloballyRecognized = faction.isGloballyRecognized or false
            }
        end

        table.SortByMember(entries, "name", true)
        return entries
    end

    local function applyOverrides()
        for index, override in pairs(factionManagerData.overrides) do
            local faction = ix.faction.indices[tonumber(index)]
            if (faction) then
                for key, value in pairs(override) do
                    faction[key] = value
                end

                if (faction.uniqueID == "citizen") then
                    faction.isDefault = true
                end
            end
        end
    end

    local function registerCustomFaction(data)
        customFactionSeq = customFactionSeq + 1
        local uniqueID = data.uniqueID or ("custom_" .. tostring(customFactionSeq))
        local index = #ix.faction.indices + 1

        local faction = {
            index = index,
            uniqueID = uniqueID,
            name = data.name or "Custom",
            description = data.description or "",
            color = FactionManager.NormalizeColor(data.color),
            pay = tonumber(data.pay) or 0,
            isDefault = data.isDefault == true,
            isGloballyRecognized = data.isGloballyRecognized ~= false,
            models = data.models or {
                "models/humans/group01/male_01.mdl",
                "models/humans/group01/female_01.mdl"
            },
            weapons = data.weapons or {}
        }

        function faction:GetModels()
            return self.models
        end

        ix.faction.indices[index] = faction
        ix.faction.teams[uniqueID] = faction
        team.SetUp(index, faction.name, faction.color)

        return faction
    end

    loadData()
    applyOverrides()

    local function sendData(ply)
        net.Start("FactionManager_Data")
            net.WriteTable({
                factions = getFactionEntries(),
                members = factionManagerData.members,
                ranks = factionManagerData.ranks
            })
        net.Send(ply)
    end

    local function getFactionStorageKey(factionID)
        return tostring(factionID)
    end

    local function ensureStorage(factionID)
        local key = getFactionStorageKey(factionID)
        factionManagerData.members[key] = factionManagerData.members[key] or {}
        factionManagerData.ranks[key] = factionManagerData.ranks[key] or {}
        factionManagerData.overrides[key] = factionManagerData.overrides[key] or {}
        return key
    end

    net.Receive("FactionManager_Action", function(_, ply)
        if (not isAdmin(ply)) then return end

        local action = net.ReadString()

        if (action == "request") then
            sendData(ply)
            return
        end

        if (action == "create") then
            local name = net.ReadString()
            local description = net.ReadString()
            local color = net.ReadTable()
            local pay = tonumber(net.ReadString()) or 0
            local models = net.ReadTable() or {}
            local weapons = net.ReadTable() or {}
            local isGloballyRecognized = net.ReadBool()
            local isDefault = net.ReadBool()

            local faction = registerCustomFaction({
                name = name,
                description = description,
                color = color,
                pay = pay,
                models = models,
                weapons = weapons,
                isGloballyRecognized = isGloballyRecognized,
                isDefault = isDefault,
                uniqueID = "custom_" .. string.gsub(string.lower(name), "%W+", "_") .. "_" .. tostring(SysTime())
            })

            factionManagerData.custom[#factionManagerData.custom + 1] = {
                index = faction.index,
                uniqueID = faction.uniqueID,
                name = faction.name,
                description = faction.description,
                color = faction.color,
                pay = faction.pay,
                models = faction.models,
                weapons = faction.weapons,
                isGloballyRecognized = faction.isGloballyRecognized,
                isDefault = faction.isDefault,
                isCustom = true
            }

            saveData()
            sendData(ply)
            return
        end

        if (action == "delete") then
            local factionID = tonumber(net.ReadString())
            if (not factionID) then return end

            factionManagerData.members[getFactionStorageKey(factionID)] = nil
            factionManagerData.ranks[getFactionStorageKey(factionID)] = nil
            factionManagerData.overrides[getFactionStorageKey(factionID)] = nil
            saveData()
            sendData(ply)
            return
        end

        if (action == "modify") then
            local factionID = tonumber(net.ReadString())
            local name = net.ReadString()
            local description = net.ReadString()
            local color = net.ReadTable()
            local pay = tonumber(net.ReadString()) or 0
            local models = net.ReadTable() or {}
            local weapons = net.ReadTable() or {}
            local isGloballyRecognized = net.ReadBool()
            local isDefault = net.ReadBool()

            if (not factionID) then return end

            local key = ensureStorage(factionID)
            local faction = ix.faction.indices[factionID]
            if (faction) then
                faction.name = name
                faction.description = description
                faction.color = FactionManager.NormalizeColor(color)
                faction.pay = pay
                faction.models = models
                faction.weapons = weapons
                faction.isGloballyRecognized = isGloballyRecognized
                faction.isDefault = isDefault
                factionManagerData.overrides[key] = {
                    name = faction.name,
                    description = faction.description,
                    color = faction.color,
                    pay = faction.pay,
                    models = faction.models,
                    weapons = faction.weapons,
                    isGloballyRecognized = faction.isGloballyRecognized,
                    isDefault = faction.isDefault
                }
                saveData()
            end

            sendData(ply)
            return
        end

        if (action == "addmember") then
            local factionID = tonumber(net.ReadString())
            local steamid = net.ReadString()
            if (factionID and steamid ~= "") then
                local key = ensureStorage(factionID)
                if (not table.HasValue(factionManagerData.members[key], steamid)) then
                    factionManagerData.members[key][#factionManagerData.members[key] + 1] = steamid
                end
                saveData()
            end
            sendData(ply)
            return
        end

        if (action == "removemember") then
            local factionID = tonumber(net.ReadString())
            local steamid = net.ReadString()
            local key = getFactionStorageKey(factionID)
            if (factionManagerData.members[key]) then
                for i, storedSteamID in ipairs(factionManagerData.members[key]) do
                    if (storedSteamID == steamid) then
                        table.remove(factionManagerData.members[key], i)
                        break
                    end
                end
                saveData()
            end
            sendData(ply)
            return
        end

        if (action == "addrank") then
            local factionID = tonumber(net.ReadString())
            local rankName = net.ReadString()
            local key = ensureStorage(factionID)
            factionManagerData.ranks[key][#factionManagerData.ranks[key] + 1] = rankName
            saveData()
            sendData(ply)
            return
        end

        if (action == "removerank") then
            local factionID = tonumber(net.ReadString())
            local rankIndex = tonumber(net.ReadString())
            local key = getFactionStorageKey(factionID)
            if (factionManagerData.ranks[key] and rankIndex and factionManagerData.ranks[key][rankIndex]) then
                table.remove(factionManagerData.ranks[key], rankIndex)
                saveData()
            end
            sendData(ply)
            return
        end

        if (action == "setrank") then
            local factionID = tonumber(net.ReadString())
            local steamid = net.ReadString()
            local rankName = net.ReadString()
            local key = ensureStorage(factionID)
            factionManagerData.members[key] = factionManagerData.members[key] or {}
            factionManagerData.members[key .. "_ranks"] = factionManagerData.members[key .. "_ranks"] or {}
            factionManagerData.members[key .. "_ranks"][steamid] = rankName
            saveData()
            sendData(ply)
            return
        end
    end)

    ix.command.Add("tlou_faction_manager", {
        description = "Abrir gestor de facciones.",
        OnRun = function(self, ply)
            if (not isAdmin(ply)) then
                ply:ChatPrint("No tienes permiso para abrir el gestor de facciones.")
                return
            end

            sendData(ply)
        end
    })
end
