local factionData = {factions = {}, members = {}, ranks = {}}
local managerFrame

local function sendAction(action, ...)
    net.Start("FactionManager_Action")
        net.WriteString(action)
        for _, value in ipairs({...}) do
            if (isstring(value)) then
                net.WriteString(value)
            elseif (istable(value)) then
                net.WriteTable(value)
            else
                net.WriteString(tostring(value))
            end
        end
    net.SendToServer()
end

local function paintButton(button, color)
    button:SetTextColor(Color(235, 235, 230))
    button.Paint = function(self, width, height)
        local base = color or Color(60, 60, 56)
        if (self:IsHovered()) then
            base = Color(math.min(base.r + 12, 255), math.min(base.g + 12, 255), math.min(base.b + 12, 255))
        end

        draw.RoundedBox(6, 0, 0, width, height, base)
        draw.SimpleText(self:GetText(), "DermaDefaultBold", width / 2, height / 2, Color(240, 240, 240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

local function factionMembersCount(faction)
    local key = tostring(faction.index)
    return factionData.members[key] and #factionData.members[key] or 0
end

local function csvToTable(text)
    local result = {}
    text = string.Trim(text or "")
    if (text == "") then return result end

    for value in string.gmatch(text, "[^,]+") do
        value = string.Trim(value)
        if (value ~= "") then
            result[#result + 1] = value
        end
    end

    return result
end

local function tableToCSV(values)
    if (not istable(values) or #values == 0) then return "" end
    return table.concat(values, ", ")
end

local function openMemberWindow(faction)
    local frame = vgui.Create("DFrame")
    frame:SetTitle("Miembros: " .. faction.name)
    frame:SetSize(620, 420)
    frame:Center()
    frame:MakePopup()

    local list = vgui.Create("DListView", frame)
    list:SetPos(10, 40)
    list:SetSize(600, 250)
    list:AddColumn("SteamID")
    list:AddColumn("Rango")

    local function refreshMembers()
        list:Clear()
        local key = tostring(faction.index)
        local members = factionData.members[key] or {}
        local ranks = factionData.members[key .. "_ranks"] or {}

        for _, steamid in ipairs(members) do
            list:AddLine(steamid, ranks[steamid] or "(sin rango)")
        end
    end

    refreshMembers()

    local txtSteamID = vgui.Create("DTextEntry", frame)
    txtSteamID:SetPos(10, 305)
    txtSteamID:SetSize(220, 28)
    txtSteamID:SetPlaceholderText("STEAM_0:X:XXXXXXX")

    local txtRank = vgui.Create("DTextEntry", frame)
    txtRank:SetPos(240, 305)
    txtRank:SetSize(200, 28)
    txtRank:SetPlaceholderText("Rango")

    local btnAdd = vgui.Create("DButton", frame)
    btnAdd:SetText("Agregar / Cambiar")
    btnAdd:SetPos(450, 305)
    btnAdd:SetSize(160, 28)
    paintButton(btnAdd, Color(70, 100, 70))
    btnAdd.DoClick = function()
        local steamid = txtSteamID:GetValue()
        local rank = txtRank:GetValue()
        if (steamid == "") then return end
        sendAction("addmember", tostring(faction.index), steamid)
        if (rank ~= "") then
            sendAction("setrank", tostring(faction.index), steamid, rank)
        end
    end

    local btnRemove = vgui.Create("DButton", frame)
    btnRemove:SetText("Eliminar seleccionado")
    btnRemove:SetPos(10, 350)
    btnRemove:SetSize(180, 30)
    paintButton(btnRemove, Color(120, 70, 70))
    btnRemove.DoClick = function()
        local line = list:GetSelectedLine()
        if (not line) then return end
        local steamid = list:GetLine(line):GetValue(1)
        sendAction("removemember", tostring(faction.index), steamid)
    end

    local btnClose = vgui.Create("DButton", frame)
    btnClose:SetText("Cerrar")
    btnClose:SetPos(500, 350)
    btnClose:SetSize(110, 30)
    paintButton(btnClose, Color(80, 80, 76))
    btnClose.DoClick = function()
        frame:Close()
    end
end

local function openRankWindow(faction)
    local frame = vgui.Create("DFrame")
    frame:SetTitle("Rangos: " .. faction.name)
    frame:SetSize(500, 360)
    frame:Center()
    frame:MakePopup()

    local list = vgui.Create("DListView", frame)
    list:SetPos(10, 40)
    list:SetSize(480, 220)
    list:AddColumn("Rango")

    local function refreshRanks()
        list:Clear()
        local ranks = factionData.ranks[tostring(faction.index)] or {}
        for i, rankName in ipairs(ranks) do
            list:AddLine(rankName):SetValue(1, rankName)
        end
    end

    refreshRanks()

    local txtRank = vgui.Create("DTextEntry", frame)
    txtRank:SetPos(10, 275)
    txtRank:SetSize(330, 28)
    txtRank:SetPlaceholderText("Nuevo rango")

    local btnAdd = vgui.Create("DButton", frame)
    btnAdd:SetText("Agregar")
    btnAdd:SetPos(350, 275)
    btnAdd:SetSize(65, 28)
    paintButton(btnAdd, Color(70, 100, 70))
    btnAdd.DoClick = function()
        local rankName = txtRank:GetValue()
        if (rankName == "") then return end
        sendAction("addrank", tostring(faction.index), rankName)
    end

    local btnRemove = vgui.Create("DButton", frame)
    btnRemove:SetText("Eliminar")
    btnRemove:SetPos(425, 275)
    btnRemove:SetSize(65, 28)
    paintButton(btnRemove, Color(120, 70, 70))
    btnRemove.DoClick = function()
        local line = list:GetSelectedLine()
        if (not line) then return end
        sendAction("removerank", tostring(faction.index), tostring(line))
    end
end

local function openManager()
    if (IsValid(managerFrame)) then
        managerFrame:Remove()
    end

    managerFrame = vgui.Create("DFrame")
    managerFrame:SetSize(1320, 780)
    managerFrame:Center()
    managerFrame:MakePopup()
    managerFrame:SetTitle("Gestor de Facciones")

    local list = vgui.Create("DListView", managerFrame)
    list:SetPos(20, 50)
    list:SetSize(760, 640)
    list:AddColumn("ID")
    list:AddColumn("Nombre")
    list:AddColumn("Miembros")
    list:AddColumn("Tipo")

    for _, faction in ipairs(factionData.factions or {}) do
        list:AddLine(
            tostring(faction.index),
            faction.name or "",
            tostring(factionMembersCount(faction)),
            faction.isCustom and "Custom" or "Schema"
        )
    end

    local txtName = vgui.Create("DTextEntry", managerFrame)
    txtName:SetPos(820, 50)
    txtName:SetSize(460, 28)
    txtName:SetPlaceholderText("Nombre")

    local txtDescription = vgui.Create("DTextEntry", managerFrame)
    txtDescription:SetPos(820, 88)
    txtDescription:SetSize(460, 52)
    txtDescription:SetPlaceholderText("Descripción")

    local txtPay = vgui.Create("DTextEntry", managerFrame)
    txtPay:SetPos(820, 150)
    txtPay:SetSize(120, 28)
    txtPay:SetPlaceholderText("Pago")

    local txtModels = vgui.Create("DTextEntry", managerFrame)
    txtModels:SetPos(820, 188)
    txtModels:SetSize(460, 28)
    txtModels:SetPlaceholderText("Models separados por coma")

    local txtWeapons = vgui.Create("DTextEntry", managerFrame)
    txtWeapons:SetPos(820, 226)
    txtWeapons:SetSize(460, 28)
    txtWeapons:SetPlaceholderText("Weapons separados por coma")

    local chkRecognized = vgui.Create("DCheckBoxLabel", managerFrame)
    chkRecognized:SetPos(820, 262)
    chkRecognized:SetText("Reconocida globalmente")
    chkRecognized:SetValue(true)
    chkRecognized:SizeToContents()

    local chkDefault = vgui.Create("DCheckBoxLabel", managerFrame)
    chkDefault:SetPos(820, 286)
    chkDefault:SetText("Facción por defecto")
    chkDefault:SetValue(false)
    chkDefault:SizeToContents()

    local btnCreate = vgui.Create("DButton", managerFrame)
    btnCreate:SetText("Crear facción")
    btnCreate:SetPos(820, 340)
    btnCreate:SetSize(140, 32)
    paintButton(btnCreate, Color(70, 90, 70))
    btnCreate.DoClick = function()
        sendAction(
            "create",
            txtName:GetValue(),
            txtDescription:GetValue(),
            {r = 200, g = 200, b = 200},
            txtPay:GetValue(),
            csvToTable(txtModels:GetValue()),
            csvToTable(txtWeapons:GetValue()),
            chkRecognized:GetChecked() == true,
            chkDefault:GetChecked() == true
        )
    end

    local btnModify = vgui.Create("DButton", managerFrame)
    btnModify:SetText("Modificar")
    btnModify:SetPos(970, 340)
    btnModify:SetSize(140, 32)
    paintButton(btnModify, Color(70, 90, 120))
    btnModify.DoClick = function()
        local line = list:GetSelectedLine()
        if (not line) then return end
        local factionID = list:GetLine(line):GetValue(1)
        sendAction(
            "modify",
            factionID,
            txtName:GetValue(),
            txtDescription:GetValue(),
            {r = 200, g = 200, b = 200},
            txtPay:GetValue(),
            csvToTable(txtModels:GetValue()),
            csvToTable(txtWeapons:GetValue()),
            chkRecognized:GetChecked() == true,
            chkDefault:GetChecked() == true
        )
    end

    local btnDelete = vgui.Create("DButton", managerFrame)
    btnDelete:SetText("Borrar")
    btnDelete:SetPos(1120, 340)
    btnDelete:SetSize(140, 32)
    paintButton(btnDelete, Color(120, 70, 70))
    btnDelete.DoClick = function()
        local line = list:GetSelectedLine()
        if (not line) then return end
        local factionID = list:GetLine(line):GetValue(1)
        sendAction("delete", factionID)
    end

    local btnMembers = vgui.Create("DButton", managerFrame)
    btnMembers:SetText("Gestionar miembros")
    btnMembers:SetPos(820, 392)
    btnMembers:SetSize(440, 34)
    paintButton(btnMembers, Color(90, 90, 90))
    btnMembers.DoClick = function()
        local line = list:GetSelectedLine()
        if (not line) then return end
        local factionID = tonumber(list:GetLine(line):GetValue(1))
        for _, faction in ipairs(factionData.factions or {}) do
            if (faction.index == factionID) then
                openMemberWindow(faction)
                return
            end
        end
    end

    local btnRanks = vgui.Create("DButton", managerFrame)
    btnRanks:SetText("Gestionar rangos")
    btnRanks:SetPos(820, 436)
    btnRanks:SetSize(440, 34)
    paintButton(btnRanks, Color(90, 90, 90))
    btnRanks.DoClick = function()
        local line = list:GetSelectedLine()
        if (not line) then return end
        local factionID = tonumber(list:GetLine(line):GetValue(1))
        for _, faction in ipairs(factionData.factions or {}) do
            if (faction.index == factionID) then
                openRankWindow(faction)
                return
            end
        end
    end

    local btnRefresh = vgui.Create("DButton", managerFrame)
    btnRefresh:SetText("Refrescar")
    btnRefresh:SetPos(820, 480)
    btnRefresh:SetSize(440, 34)
    paintButton(btnRefresh, Color(80, 80, 76))
    btnRefresh.DoClick = function()
        sendAction("request")
    end

    local btnClose = vgui.Create("DButton", managerFrame)
    btnClose:SetText("Cerrar")
    btnClose:SetPos(820, 524)
    btnClose:SetSize(440, 34)
    paintButton(btnClose, Color(120, 70, 70))
    btnClose.DoClick = function()
        managerFrame:Close()
    end

    list.OnRowSelected = function(_, _, row)
        local factionID = tonumber(row:GetColumnText(1))
        local selectedFaction

        for _, faction in ipairs(factionData.factions or {}) do
            if (faction.index == factionID) then
                selectedFaction = faction
                break
            end
        end

        if (not selectedFaction) then return end

        txtName:SetText(selectedFaction.name or "")
        txtDescription:SetText(selectedFaction.description or "")
        txtPay:SetText(tostring(selectedFaction.pay or 0))
        txtModels:SetText(tableToCSV(selectedFaction.models))
        txtWeapons:SetText(tableToCSV(selectedFaction.weapons))
        chkRecognized:SetChecked(selectedFaction.isGloballyRecognized ~= false)
        chkDefault:SetChecked(selectedFaction.isDefault == true)
    end
end

net.Receive("FactionManager_Data", function()
    factionData = net.ReadTable() or factionData
    openManager()
end)
