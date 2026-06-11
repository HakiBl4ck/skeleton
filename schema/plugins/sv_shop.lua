-- Servidor: sistema de tienda TLOU
if SERVER then
    util.AddNetworkString("Shop_Open")
    util.AddNetworkString("Shop_Buy")
    util.AddNetworkString("Shop_AdminSave")
    util.AddNetworkString("Shop_AdminDelete")

    local SHOP_DATA_FILE = "tlou_shop_items.txt"

    local DEFAULT_SHOP_ITEMS = {
        {id = 1, name = "Pistola 9mm", class = "weapon_pistol", price = 500, stock = -1, expiresAt = 0, category = "Armas"},
        {id = 2, name = "Escopeta", class = "weapon_shotgun", price = 1200, stock = -1, expiresAt = 0, category = "Armas"},
        {id = 3, name = "SMG", class = "weapon_smg1", price = 800, stock = -1, expiresAt = 0, category = "Armas"},
        {id = 4, name = "Rifle", class = "weapon_ar2", price = 1500, stock = -1, expiresAt = 0, category = "Armas"},
        {id = 5, name = "Municion 9mm", class = "ammo_pistol", price = 50, stock = -1, expiresAt = 0, category = "Municion"},
        {id = 6, name = "Municion escopeta", class = "ammo_buckshot", price = 100, stock = -1, expiresAt = 0, category = "Municion"},
        {id = 7, name = "Municion SMG", class = "ammo_smg1", price = 75, stock = -1, expiresAt = 0, category = "Municion"},
        {id = 8, name = "Municion rifle", class = "ammo_ar2", price = 150, stock = -1, expiresAt = 0, category = "Municion"},
    }

    local SHOP_ITEMS = {}
    local nextShopItemID = 1

    local function IsShopAdmin(ply)
        if not IsValid(ply) or not ply:IsPlayer() then return false end
        return (FACTION_ADMINS and ply:Team() == FACTION_ADMINS) or ply:GetPData("tlou_is_admin", "0") == "1"
    end

    local function NormalizeShopItem(item)
        item.id = math.floor(tonumber(item.id) or 0)
        item.name = string.Trim(tostring(item.name or "Objeto"))
        item.class = string.Trim(tostring(item.class or ""))
        item.category = string.Trim(tostring(item.category or "General"))
        item.price = math.max(0, math.floor(tonumber(item.price) or 0))
        item.stock = math.floor(tonumber(item.stock) or -1)
        item.expiresAt = math.max(0, math.floor(tonumber(item.expiresAt) or 0))

        if item.name == "" then item.name = "Objeto" end
        if item.category == "" then item.category = "General" end

        return item
    end

    local function SaveShopItems()
        file.Write(SHOP_DATA_FILE, util.TableToJSON(SHOP_ITEMS, true))
    end

    local function LoadShopItems()
        if file.Exists(SHOP_DATA_FILE, "DATA") then
            local decoded = util.JSONToTable(file.Read(SHOP_DATA_FILE, "DATA") or "")
            if istable(decoded) then
                SHOP_ITEMS = decoded
            end
        end

        if #SHOP_ITEMS == 0 then
            SHOP_ITEMS = table.Copy(DEFAULT_SHOP_ITEMS)
        end

        nextShopItemID = 1
        for _, item in ipairs(SHOP_ITEMS) do
            NormalizeShopItem(item)
            nextShopItemID = math.max(nextShopItemID, item.id + 1)
        end

        SaveShopItems()
    end

    local function GetPlayerMoney(ply)
        if ply.GetCharacter then
            local char = ply:GetCharacter()
            if char then
                return tonumber(char:GetData("money")) or 0
            end
        end

        if ply.GetMoney then
            return tonumber(ply:GetMoney()) or 0
        end

        return tonumber(ply:GetPData("tlou_money", "0")) or 0
    end

    local function SetPlayerMoney(ply, amount)
        amount = math.max(0, math.floor(tonumber(amount) or 0))

        if ply.GetCharacter then
            local char = ply:GetCharacter()
            if char then
                char:SetData("money", amount)
                return
            end
        end

        ply:SetPData("tlou_money", tostring(amount))
    end

    local function IsExpired(item)
        return item.expiresAt > 0 and item.expiresAt <= os.time()
    end

    local function GetVisibleShopItems()
        local items = {}

        for _, item in ipairs(SHOP_ITEMS) do
            if not IsExpired(item) then
                items[#items + 1] = table.Copy(item)
            end
        end

        return items
    end

    local function FindShopItem(id)
        id = tonumber(id)

        for index, item in ipairs(SHOP_ITEMS) do
            if item.id == id then
                return item, index
            end
        end
    end

    local function SendShop(ply)
        if not IsValid(ply) then return end

        net.Start("Shop_Open")
        net.WriteTable(GetVisibleShopItems())
        net.WriteBool(IsShopAdmin(ply))
        net.WriteUInt(math.Clamp(GetPlayerMoney(ply), 0, 4294967295), 32)
        net.Send(ply)
    end

    local function GiveShopItem(ply, item)
        if item.class:find("^weapon_") then
            ply:Give(item.class)
            return true
        end

        if item.class:find("^ammo_") then
            local ammoType = item.class:gsub("^ammo_", "")
            if ammoType == "buckshot" then ammoType = "Buckshot" end
            ply:GiveAmmo(30, ammoType)
            return true
        end

        if ix and ix.item and ix.item.list and ix.item.list[item.class] and ply.GetCharacter then
            local char = ply:GetCharacter()
            local inv = char and char:GetInventory()
            if inv then
                inv:Add(item.class, 1)
                return true
            end
        end

        return false
    end

    LoadShopItems()

    net.Receive("Shop_Buy", function(len, ply)
        if not IsValid(ply) or not ply:IsPlayer() then return end

        local item = FindShopItem(net.ReadUInt(16))
        if not item or IsExpired(item) then
            ply:ChatPrint("Ese objeto ya no esta disponible.")
            SendShop(ply)
            return
        end

        if item.stock == 0 then
            ply:ChatPrint("Ese objeto no tiene stock.")
            SendShop(ply)
            return
        end

        local money = GetPlayerMoney(ply)
        if money < item.price then
            ply:ChatPrint("No tienes suficiente dinero. Necesitas $" .. item.price .. ", tienes $" .. money)
            return
        end

        if not GiveShopItem(ply, item) then
            ply:ChatPrint("No se pudo entregar ese objeto. Revisa la clase del item.")
            return
        end

        SetPlayerMoney(ply, money - item.price)

        if item.stock > 0 then
            item.stock = item.stock - 1
            SaveShopItems()
        end

        ply:ChatPrint("Compraste: " .. item.name .. " por $" .. item.price)
        SendShop(ply)
    end)

    net.Receive("Shop_AdminSave", function(len, ply)
        if not IsShopAdmin(ply) then return end

        local item = NormalizeShopItem(net.ReadTable() or {})
        if item.class == "" then
            ply:ChatPrint("La clase del objeto no puede estar vacia.")
            return
        end

        local existing = item.id > 0 and FindShopItem(item.id)
        if existing then
            existing.name = item.name
            existing.class = item.class
            existing.category = item.category
            existing.price = item.price
            existing.stock = item.stock
            existing.expiresAt = item.expiresAt
        else
            item.id = nextShopItemID
            nextShopItemID = nextShopItemID + 1
            SHOP_ITEMS[#SHOP_ITEMS + 1] = item
        end

        SaveShopItems()
        ply:ChatPrint("Objeto de tienda guardado: " .. item.name)
        SendShop(ply)
    end)

    net.Receive("Shop_AdminDelete", function(len, ply)
        if not IsShopAdmin(ply) then return end

        local item, index = FindShopItem(net.ReadUInt(16))
        if not item then return end

        table.remove(SHOP_ITEMS, index)
        SaveShopItems()
        ply:ChatPrint("Objeto eliminado de la tienda: " .. item.name)
        SendShop(ply)
    end)

    local function RegisterShopCommands()
        if not ix or not ix.command then
            return false
        end

        if not ix.command.list or not ix.command.list["tienda"] then
            ix.command.Add("tienda", {
                description = "Abrir la tienda de armas y municion",
                OnRun = function(self, ply)
                    SendShop(ply)
                end
            })
        end

        if not ix.command.list or not ix.command.list["dardinero"] then
            ix.command.Add("dardinero", {
                description = "Dar dinero a un jugador para usar en la tienda",
                syntax = "<jugador> <cantidad>",
                OnRun = function(self, ply, args)
                    if not IsShopAdmin(ply) then
                        ply:ChatPrint("No tienes permisos para usar este comando.")
                        return
                    end

                    local targetName
                    local amount

                    if istable(args) then
                        amount = tonumber(args[#args])
                        targetName = table.concat(args, " ", 1, math.max(#args - 1, 1))
                    else
                        local parts = string.Explode(" ", tostring(args or ""))
                        amount = tonumber(parts[#parts])
                        table.remove(parts, #parts)
                        targetName = table.concat(parts, " ")
                    end

                    if not targetName or targetName == "" or not amount or amount <= 0 then
                        ply:ChatPrint("Uso: /dardinero <jugador> <cantidad>")
                        return
                    end

                    local target = ix.util.FindPlayer(targetName)
                    if not IsValid(target) then
                        ply:ChatPrint("Jugador no encontrado.")
                        return
                    end

                    amount = math.floor(amount)
                    SetPlayerMoney(target, GetPlayerMoney(target) + amount)
                    ply:ChatPrint("Diste $" .. amount .. " a " .. target:Nick() .. ".")
                    target:ChatPrint("Recibiste $" .. amount .. " de " .. ply:Nick() .. ".")
                end
            })
        end

        if not ix.command.list or not ix.command.list["setmoney"] then
            ix.command.Add("setmoney", {
                description = "Establecer dinero de un jugador (Solo admins)",
                syntax = "<jugador> <cantidad>",
                OnRun = function(self, ply, args)
                    if not IsShopAdmin(ply) then
                        ply:ChatPrint("No tienes permisos para usar este comando.")
                        return
                    end

                    local targetName
                    local amount

                    if istable(args) then
                        amount = tonumber(args[#args])
                        targetName = table.concat(args, " ", 1, math.max(#args - 1, 1))
                    else
                        local parts = string.Explode(" ", tostring(args or ""))
                        amount = tonumber(parts[#parts])
                        table.remove(parts, #parts)
                        targetName = table.concat(parts, " ")
                    end

                    if not targetName or targetName == "" or not amount or amount < 0 then
                        ply:ChatPrint("Uso: /setmoney <jugador> <cantidad>")
                        return
                    end

                    local target = ix.util.FindPlayer(targetName)
                    if not IsValid(target) then
                        ply:ChatPrint("Jugador no encontrado.")
                        return
                    end

                    SetPlayerMoney(target, amount)
                    target:ChatPrint("Tu dinero ha sido establecido a: $" .. math.floor(amount))
                    ply:ChatPrint("Dinero de " .. target:Nick() .. " establecido a: $" .. math.floor(amount))
                end
            })
        end

        return true
    end

    if not RegisterShopCommands() then
        hook.Add("InitializedSchema", "TLOUShop_RegisterCommands", function()
            if RegisterShopCommands() then
                hook.Remove("InitializedSchema", "TLOUShop_RegisterCommands")
            end
        end)

        timer.Create("TLOUShop_RegisterCommands", 1, 10, function()
            if RegisterShopCommands() then
                timer.Remove("TLOUShop_RegisterCommands")
            end
        end)
    end
end
