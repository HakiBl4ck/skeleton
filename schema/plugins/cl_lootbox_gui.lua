if (CLIENT) then
net.Receive("ixLootBox_OpenEditor", function()
    local entity = net.ReadEntity()
    if (!IsValid(entity)) then return end

    local color_bg = Color(20, 20, 20, 240)
    local color_accent = Color(140, 150, 100)
    local color_text = Color(200, 200, 180)

    local frame = vgui.Create("DFrame")
    frame:SetTitle("")
    frame:SetSize(400, 550)
    frame:Center()
    frame:MakePopup()
    frame.Paint = function(self, w, h)
        surface.SetDrawColor(color_bg)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(color_accent)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("EDITOR DE CAJA DE LOOT", "ixMediumFont", 10, 5, color_text)
    end

    local scroll = frame:Add("DScrollPanel")
    scroll:Dock(FILL)
    scroll:DockMargin(10, 30, 10, 10)

    local itemsList = scroll:Add("DListLayout")
    itemsList:Dock(TOP)
    itemsList:SetTall(300)
    itemsList:DockMargin(0, 0, 0, 10)

    local function RefreshItems(items)
        itemsList:Clear()
        for i, itemData in ipairs(items) do
            local itemRow = itemsList:Add("Panel")
            itemRow:Dock(TOP)
            itemRow:SetTall(30)
            itemRow:DockMargin(0, 0, 0, 2)
            itemRow.Paint = function(self, w, h) surface.SetDrawColor(40, 40, 40) surface.DrawRect(0, 0, w, h) end

            local nameLabel = itemRow:Add("DLabel")
            nameLabel:SetText(itemData.name)
            nameLabel:Dock(LEFT)
            nameLabel:DockMargin(10, 0, 0, 0)
            nameLabel:SetWide(200)
            nameLabel:SetTextColor(color_text)

            local removeBtn = itemRow:Add("DButton")
            removeBtn:SetText("X")
            removeBtn:Dock(RIGHT)
            removeBtn:SetWide(30)
            removeBtn:SetTextColor(Color(255, 100, 100))
            removeBtn.DoClick = function()
                net.Start("ixLootBox_Update")
                    net.WriteEntity(entity)
                    net.WriteString("remove")
                    net.WriteTable({index = i})
                net.SendToServer()
            end
        end
    end

    net.Receive("ixLootBox_RequestItems", function()
        local targetEntity = net.ReadEntity()
        local items = net.ReadTable()
        if (targetEntity == entity) then
            RefreshItems(items)
        end
    end)

    local itemEntry = scroll:Add("DTextEntry")
    itemEntry:Dock(TOP)
    itemEntry:SetPlaceholderText("UniqueID o Clase del Item (ej: weapon_pistol)")
    itemEntry:SetTall(30)
    itemEntry:DockMargin(0, 0, 0, 5)
    itemEntry:SetFont("ixSmallFont")

    local addBtn = scroll:Add("DButton")
    addBtn:SetText("+ AÑADIR ITEM")
    addBtn:Dock(TOP)
    addBtn:SetTall(30)
    addBtn:DockMargin(0, 0, 0, 10)
    addBtn:SetTextColor(color_text)
    addBtn.Paint = function(self, w, h)
        surface.SetDrawColor(self:IsHovered() and color_accent or Color(50, 50, 50))
        surface.DrawRect(0, 0, w, h)
    end
    addBtn.DoClick = function()
        local itemIdentifier = itemEntry:GetValue():Trim()
        if (itemIdentifier != "") then
            local itemTable = ix.item.list[itemIdentifier]
            if (!itemTable) then
                for k, v in pairs(ix.item.list) do
                    if (v.class == itemIdentifier) then
                        itemTable = v
                        break
                    end
                end
            end

            if (itemTable) then
                net.Start("ixLootBox_Update")
                    net.WriteEntity(entity)
                    net.WriteString("add")
                    net.WriteTable({uniqueID = itemTable.uniqueID, name = itemTable.name})
                net.SendToServer()
                itemEntry:SetText("")
            else
                LocalPlayer():Notify("Item no encontrado: " .. itemIdentifier)
            end
        end
    end

    local closeBtn = frame:Add("DButton")
    closeBtn:SetText("CERRAR EDITOR")
    closeBtn:Dock(BOTTOM)
    closeBtn:SetTall(40)
    closeBtn:SetTextColor(color_text)
    closeBtn.Paint = function(self, w, h)
        surface.SetDrawColor(color_accent)
        surface.DrawRect(0, 0, w, h)
    end
    closeBtn.DoClick = function() frame:Close() end

    net.Start("ixLootBox_RequestItems")
        net.WriteEntity(entity)
    net.SendToServer()
end)
end