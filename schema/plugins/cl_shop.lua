-- Cliente: interfaz de tienda TLOU
if CLIENT then
    local function FormatExpiration(expiresAt)
        expiresAt = tonumber(expiresAt) or 0
        if expiresAt <= 0 then return "Nunca" end

        local remaining = expiresAt - os.time()
        if remaining <= 0 then return "Expirado" end

        local minutes = math.ceil(remaining / 60)
        if minutes < 60 then return minutes .. " min" end

        local hours = math.ceil(minutes / 60)
        if hours < 24 then return hours .. " h" end

        return math.ceil(hours / 24) .. " d"
    end

    local function DrawButton(button, color)
        button:SetTextColor(Color(240, 240, 240))
        button.Paint = function(self, w, h)
            local col = color
            if self:IsHovered() then
                col = Color(math.min(color.r + 25, 255), math.min(color.g + 25, 255), math.min(color.b + 25, 255))
            end
            if self:IsDown() then
                col = Color(math.max(color.r - 20, 0), math.max(color.g - 20, 0), math.max(color.b - 20, 0))
            end

            draw.RoundedBox(6, 0, 0, w, h, col)
            draw.SimpleText(self:GetText(), "DermaDefaultBold", w / 2, h / 2, Color(240, 240, 240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    local function AddTextEntry(parent, label, x, y, w, default)
        local lbl = vgui.Create("DLabel", parent)
        lbl:SetText(label)
        lbl:SetTextColor(Color(220, 210, 200))
        lbl:SetPos(x, y)
        lbl:SetSize(w, 18)

        local entry = vgui.Create("DTextEntry", parent)
        entry:SetPos(x, y + 20)
        entry:SetSize(w, 26)
        entry:SetText(tostring(default or ""))

        return entry
    end

    local function OpenShop(items, isAdmin, money)
        items = items or {}
        money = tonumber(money) or 0

        local frame = vgui.Create("DFrame")
        frame:SetTitle("")
        frame:SetSize(isAdmin and 1180 or 900, 690)
        frame:Center()
        frame:MakePopup()
        frame:SetDraggable(true)
        frame:ShowCloseButton(true)
        frame.Paint = function(self, w, h)
            draw.RoundedBox(12, 0, 0, w, h, Color(18, 16, 14))
            draw.RoundedBox(0, 0, 0, w, 100, Color(45, 30, 20))
            draw.SimpleText("THE LAST OF US", "DermaLarge", w / 2, 15, Color(200, 140, 80), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            draw.SimpleText("ARMERIA CLANDESTINA", "DermaDefaultBold", w / 2, 45, Color(180, 160, 140), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

            surface.SetDrawColor(100, 70, 40)
            surface.DrawLine(20, 95, w - 20, 95)

            draw.SimpleText("Dinero disponible: $" .. money, "DermaLarge", w - 30, 25, Color(100, 200, 100), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
            draw.RoundedBox(0, 0, h - 60, w, 60, Color(30, 25, 20))
        end

        local shopWidth = isAdmin and 760 or frame:GetWide() - 40
        local list = vgui.Create("DListView", frame)
        list:SetPos(20, 120)
        list:SetSize(shopWidth, 490)
        local colName = list:AddColumn("Nombre")
        local colClass = list:AddColumn("Clase")
        local colCategory = list:AddColumn("Categoria")
        local colPrice = list:AddColumn("Precio")
        local colStock = list:AddColumn("Stock")
        local colExpire = list:AddColumn("Expira")

        colName:SetFixedWidth(220)
        colClass:SetFixedWidth(170)
        colCategory:SetFixedWidth(110)
        colPrice:SetFixedWidth(80)
        colStock:SetFixedWidth(80)
        colExpire:SetFixedWidth(90)

        for _, item in ipairs(items) do
            local stock = tonumber(item.stock) or -1
            local line = list:AddLine(
                item.name or "Objeto",
                item.class or "",
                item.category or "General",
                "$" .. tostring(item.price or 0),
                stock < 0 and "Infinito" or tostring(stock),
                FormatExpiration(item.expiresAt)
            )
            line.shopItem = item
        end

        local btnBuy = vgui.Create("DButton", frame)
        btnBuy:SetText("COMPRAR")
        btnBuy:SetPos(20, 625)
        btnBuy:SetSize(240, 40)
        DrawButton(btnBuy, Color(60, 100, 50))
        btnBuy.DoClick = function()
            local selected = list:GetSelectedLine()
            local line = selected and list:GetLine(selected)
            if not line or not line.shopItem then
                chat.AddText(Color(255, 100, 100), "Selecciona un objeto primero.")
                return
            end

            net.Start("Shop_Buy")
            net.WriteUInt(line.shopItem.id or 0, 16)
            net.SendToServer()
            frame:Close()
        end

        local btnClose = vgui.Create("DButton", frame)
        btnClose:SetText("CERRAR")
        btnClose:SetPos(280, 625)
        btnClose:SetSize(240, 40)
        DrawButton(btnClose, Color(80, 50, 50))
        btnClose.DoClick = function()
            frame:Close()
        end

        if not isAdmin then return end

        local panel = vgui.Create("DPanel", frame)
        panel:SetPos(800, 120)
        panel:SetSize(360, 545)
        panel.Paint = function(self, w, h)
            draw.RoundedBox(8, 0, 0, w, h, Color(28, 24, 20))
            draw.SimpleText("GESTION ADMIN", "DermaDefaultBold", 15, 12, Color(220, 180, 120), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end

        local idEntry = AddTextEntry(panel, "ID (vacio para crear)", 15, 45, 150, "")
        local nameEntry = AddTextEntry(panel, "Nombre", 15, 95, 330, "")
        local classEntry = AddTextEntry(panel, "Clase weapon_/ammo_/ix item", 15, 145, 330, "")
        local categoryEntry = AddTextEntry(panel, "Categoria", 15, 195, 160, "General")
        local priceEntry = AddTextEntry(panel, "Precio", 185, 195, 160, "0")
        local stockEntry = AddTextEntry(panel, "Stock (-1 infinito)", 15, 245, 160, "-1")
        local expireEntry = AddTextEntry(panel, "Expira en minutos (0 nunca)", 185, 245, 160, "0")

        local function LoadSelectedIntoForm()
            local selected = list:GetSelectedLine()
            local line = selected and list:GetLine(selected)
            local item = line and line.shopItem
            if not item then return end

            idEntry:SetText(tostring(item.id or ""))
            nameEntry:SetText(tostring(item.name or ""))
            classEntry:SetText(tostring(item.class or ""))
            categoryEntry:SetText(tostring(item.category or "General"))
            priceEntry:SetText(tostring(item.price or 0))
            stockEntry:SetText(tostring(item.stock or -1))

            local expiresAt = tonumber(item.expiresAt) or 0
            local minutes = expiresAt > 0 and math.max(1, math.ceil((expiresAt - os.time()) / 60)) or 0
            expireEntry:SetText(tostring(minutes))
        end

        list.OnRowSelected = function()
            LoadSelectedIntoForm()
        end

        local btnNew = vgui.Create("DButton", panel)
        btnNew:SetText("NUEVO")
        btnNew:SetPos(15, 310)
        btnNew:SetSize(105, 34)
        DrawButton(btnNew, Color(75, 75, 75))
        btnNew.DoClick = function()
            idEntry:SetText("")
            nameEntry:SetText("")
            classEntry:SetText("")
            categoryEntry:SetText("General")
            priceEntry:SetText("0")
            stockEntry:SetText("-1")
            expireEntry:SetText("0")
        end

        local btnLoad = vgui.Create("DButton", panel)
        btnLoad:SetText("CARGAR")
        btnLoad:SetPos(128, 310)
        btnLoad:SetSize(105, 34)
        DrawButton(btnLoad, Color(70, 80, 110))
        btnLoad.DoClick = LoadSelectedIntoForm

        local btnDelete = vgui.Create("DButton", panel)
        btnDelete:SetText("ELIMINAR")
        btnDelete:SetPos(240, 310)
        btnDelete:SetSize(105, 34)
        DrawButton(btnDelete, Color(120, 55, 45))
        btnDelete.DoClick = function()
            local id = tonumber(idEntry:GetValue()) or 0
            if id <= 0 then
                chat.AddText(Color(255, 100, 100), "Selecciona un objeto guardado.")
                return
            end

            net.Start("Shop_AdminDelete")
            net.WriteUInt(id, 16)
            net.SendToServer()
            frame:Close()
        end

        local btnSave = vgui.Create("DButton", panel)
        btnSave:SetText("GUARDAR OFERTA")
        btnSave:SetPos(15, 360)
        btnSave:SetSize(330, 40)
        DrawButton(btnSave, Color(60, 100, 50))
        btnSave.DoClick = function()
            local expireMinutes = math.max(0, math.floor(tonumber(expireEntry:GetValue()) or 0))
            local expiresAt = expireMinutes > 0 and os.time() + (expireMinutes * 60) or 0

            net.Start("Shop_AdminSave")
            net.WriteTable({
                id = tonumber(idEntry:GetValue()) or 0,
                name = nameEntry:GetValue(),
                class = classEntry:GetValue(),
                category = categoryEntry:GetValue(),
                price = tonumber(priceEntry:GetValue()) or 0,
                stock = tonumber(stockEntry:GetValue()) or -1,
                expiresAt = expiresAt
            })
            net.SendToServer()
            frame:Close()
        end

        local help = vgui.Create("DLabel", panel)
        help:SetPos(15, 420)
        help:SetSize(330, 100)
        help:SetWrap(true)
        help:SetTextColor(Color(190, 180, 170))
        help:SetText("Clases comunes: weapon_pistol, weapon_shotgun, weapon_smg1, weapon_ar2, ammo_pistol, ammo_smg1, ammo_ar2, ammo_buckshot.")
    end

    net.Receive("Shop_Open", function()
        OpenShop(net.ReadTable(), net.ReadBool(), net.ReadUInt(32))
    end)
end
