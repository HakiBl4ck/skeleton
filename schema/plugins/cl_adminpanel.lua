local function isAdmin()
    local ply = LocalPlayer()
    return IsValid(ply) and (ply:GetPData("tlou_is_admin", "0") == "1" or (FACTION_ADMINS and ply:Team() == FACTION_ADMINS))
end

local function styleButton(button, color)
    button:SetTextColor(Color(235, 230, 220))
    button.Paint = function(self, width, height)
        local base = color or Color(58, 52, 46)
        if (self:IsHovered()) then
            base = Color(math.min(base.r + 12, 255), math.min(base.g + 12, 255), math.min(base.b + 12, 255))
        end
        draw.RoundedBox(6, 0, 0, width, height, base)
        draw.SimpleText(self:GetText(), "DermaDefaultBold", width / 2, height / 2, Color(240, 235, 225), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

local function openAdminPanel()
    if (not isAdmin()) then return end

    local frame = vgui.Create("DFrame")
    frame:SetSize(920, 640)
    frame:Center()
    frame:MakePopup()
    frame:SetTitle("")
    frame.Paint = function(self, width, height)
        draw.RoundedBox(10, 0, 0, width, height, Color(22, 18, 16))
        draw.RoundedBox(10, 0, 0, width, 64, Color(36, 28, 24))
        draw.SimpleText("TLOU Admin Panel", "DermaLarge", 22, 16, Color(232, 220, 205), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("Herramientas de control", "DermaDefault", 24, 40, Color(180, 160, 140), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    local playerList = vgui.Create("DListView", frame)
    playerList:SetPos(20, 84)
    playerList:SetSize(430, 520)
    playerList:AddColumn("Jugador")
    playerList:AddColumn("SteamID")

    local function refreshPlayers()
        playerList:Clear()
        for _, target in ipairs(player.GetAll()) do
            playerList:AddLine(target:Nick(), target:SteamID())
        end
    end

    refreshPlayers()

    local actionPanel = vgui.Create("DPanel", frame)
    actionPanel:SetPos(470, 84)
    actionPanel:SetSize(430, 520)
    actionPanel.Paint = function(self, width, height)
        draw.RoundedBox(8, 0, 0, width, height, Color(30, 24, 22))
        draw.SimpleText("Acciones", "DermaLarge", 18, 14, Color(230, 220, 205), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    local function selectedSteamID()
        local line = playerList:GetSelectedLine()
        if (not line) then return nil end
        return playerList:GetLine(line):GetValue(2)
    end

    local function sendAction(action, extra1, extra2)
        local steamid = selectedSteamID()
        if (not steamid) then return end

        net.Start("AdminPanel_Action")
            net.WriteString(action)
            net.WriteString(steamid)
            net.WriteString(extra1 or "")
            net.WriteString(extra2 or "")
        net.SendToServer()
    end

    local y = 52
    local buttons = {
        {"Teleportar", "teleport", Color(70, 90, 70)},
        {"Revivir", "revive", Color(70, 90, 120)},
        {"Curar", "heal", Color(75, 95, 75)},
        {"Freeze", "freeze", Color(100, 85, 55)},
        {"Kill", "kill", Color(120, 70, 70)}
    }

    for _, data in ipairs(buttons) do
        local button = vgui.Create("DButton", actionPanel)
        button:SetText(data[1])
        button:SetPos(18, y)
        button:SetSize(394, 34)
        styleButton(button, data[3])
        button.DoClick = function()
            sendAction(data[2])
        end
        y = y + 44
    end

    local txtReason = vgui.Create("DTextEntry", actionPanel)
    txtReason:SetPos(18, y + 8)
    txtReason:SetSize(394, 28)
    txtReason:SetPlaceholderText("Motivo para kick/ban")

    local txtMinutes = vgui.Create("DTextEntry", actionPanel)
    txtMinutes:SetPos(18, y + 46)
    txtMinutes:SetSize(120, 28)
    txtMinutes:SetPlaceholderText("Minutos ban")

    local btnKick = vgui.Create("DButton", actionPanel)
    btnKick:SetText("Kick")
    btnKick:SetPos(150, y + 44)
    btnKick:SetSize(130, 30)
    styleButton(btnKick, Color(120, 80, 60))
    btnKick.DoClick = function()
        sendAction("kick", txtReason:GetValue())
    end

    local btnBan = vgui.Create("DButton", actionPanel)
    btnBan:SetText("Ban")
    btnBan:SetPos(290, y + 44)
    btnBan:SetSize(122, 30)
    styleButton(btnBan, Color(130, 60, 60))
    btnBan.DoClick = function()
        sendAction("ban", txtMinutes:GetValue(), txtReason:GetValue())
    end

    local btnRefresh = vgui.Create("DButton", actionPanel)
    btnRefresh:SetText("Refrescar")
    btnRefresh:SetPos(18, 564)
    btnRefresh:SetSize(394, 30)
    styleButton(btnRefresh, Color(80, 72, 66))
    btnRefresh.DoClick = refreshPlayers
end

net.Receive("AdminPanel_Open", function()
    openAdminPanel()
end)
