-- Cliente: interfaz de creacion de personaje TLOU

local TLOU_COLORS = {
    bg = Color(15, 17, 14),
    panel = Color(25, 28, 23),
    panelSoft = Color(34, 36, 30),
    header = Color(42, 39, 31),
    moss = Color(87, 111, 80),
    mossDark = Color(54, 72, 52),
    rust = Color(150, 86, 48),
    text = Color(226, 220, 205),
    muted = Color(170, 164, 148),
    line = Color(92, 82, 62)
}

local function DrawTLOUButton(button, baseColor)
    button:SetTextColor(TLOU_COLORS.text)
    button:SetFont("DermaDefaultBold")
    button.Paint = function(self, w, h)
        local col = baseColor
        if self:IsHovered() then
            col = Color(math.min(baseColor.r + 22, 255), math.min(baseColor.g + 22, 255), math.min(baseColor.b + 22, 255))
        end
        if self:IsDown() then
            col = Color(math.max(baseColor.r - 18, 0), math.max(baseColor.g - 18, 0), math.max(baseColor.b - 18, 0))
        end

        draw.RoundedBox(4, 0, 0, w, h, col)
        surface.SetDrawColor(TLOU_COLORS.line)
        surface.DrawOutlinedRect(0, 0, w, h)
    end
end

local function StyleTextEntry(entry, multiline)
    entry:SetTextColor(TLOU_COLORS.text)
    entry:SetCursorColor(TLOU_COLORS.text)
    entry:SetDrawLanguageID(false)
    entry:SetMultiline(multiline == true)
    entry.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(14, 15, 13))
        surface.SetDrawColor(self:HasFocus() and TLOU_COLORS.moss or TLOU_COLORS.line)
        surface.DrawOutlinedRect(0, 0, w, h)
        self:DrawTextEntryText(TLOU_COLORS.text, TLOU_COLORS.rust, TLOU_COLORS.text)
    end
end

local function AddField(parent, label, x, y, w, h, value, multiline)
    local lbl = vgui.Create("DLabel", parent)
    lbl:SetPos(x, y)
    lbl:SetSize(w, 18)
    lbl:SetText(label)
    lbl:SetTextColor(TLOU_COLORS.muted)
    lbl:SetFont("DermaDefaultBold")

    local entry = vgui.Create("DTextEntry", parent)
    entry:SetPos(x, y + 22)
    entry:SetSize(w, h)
    entry:SetText(tostring(value or ""))
    StyleTextEntry(entry, multiline)

    return entry
end

local function OpenCharCreator(data)
    data = data or {}

    local frame = vgui.Create("DFrame")
    frame:SetTitle("")
    frame:SetSize(980, 680)
    frame:Center()
    frame:MakePopup()
    frame:SetDraggable(true)
    frame:ShowCloseButton(true)
    frame.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, TLOU_COLORS.bg)
        draw.RoundedBox(0, 0, 0, w, 112, TLOU_COLORS.header)

        surface.SetDrawColor(31, 37, 29, 160)
        for i = 0, 10 do
            surface.DrawLine(i * 96, 112, i * 96 + 160, h)
        end

        draw.SimpleText("THE LAST OF US", "DermaLarge", 28, 18, TLOU_COLORS.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("EXPEDIENTE DE SUPERVIVIENTE", "DermaDefaultBold", 30, 55, TLOU_COLORS.rust, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("Zona de cuarentena / Registro civil improvisado", "DermaDefault", 30, 77, TLOU_COLORS.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        draw.RoundedBox(0, 0, 108, w, 2, TLOU_COLORS.rust)
        draw.RoundedBox(0, 22, h - 74, w - 44, 1, TLOU_COLORS.line)
    end

    local dossier = vgui.Create("DPanel", frame)
    dossier:SetPos(24, 132)
    dossier:SetSize(310, 470)
    dossier.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, TLOU_COLORS.panel)
        draw.RoundedBox(0, 0, 0, w, 46, TLOU_COLORS.panelSoft)
        draw.SimpleText("IDENTIDAD", "DermaDefaultBold", 18, 15, TLOU_COLORS.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        surface.SetDrawColor(TLOU_COLORS.line)
        surface.DrawOutlinedRect(0, 0, w, h)

        draw.SimpleText("ESTADO", "DermaDefaultBold", 18, 330, TLOU_COLORS.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("No infectado", "DermaLarge", 18, 355, TLOU_COLORS.moss, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("Registro pendiente de verificacion", "DermaDefault", 18, 392, TLOU_COLORS.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    local txtName = AddField(dossier, "Nombre completo", 18, 65, 274, 30, data.name or "", false)
    local txtAge = AddField(dossier, "Edad", 18, 125, 92, 30, data.age or "", false)
    local txtVinc = AddField(dossier, "Vinculos personales", 18, 185, 274, 110, data.vinculos or "", true)

    local body = vgui.Create("DPanel", frame)
    body:SetPos(354, 132)
    body:SetSize(602, 470)
    body.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, TLOU_COLORS.panel)
        draw.RoundedBox(0, 0, 0, w, 46, TLOU_COLORS.panelSoft)
        draw.SimpleText("PERFIL", "DermaDefaultBold", 18, 15, TLOU_COLORS.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        surface.SetDrawColor(TLOU_COLORS.line)
        surface.DrawOutlinedRect(0, 0, w, h)
    end

    local txtPF = AddField(body, "Rasgos fisicos, heridas, marcas y equipo visible", 18, 65, 566, 76, data.personalidad_fisica or "", true)
    local txtPP = AddField(body, "Temperamento, miedos, impulsos y forma de sobrevivir", 18, 175, 566, 76, data.personalidad_psicologica or "", true)
    local txtTras = AddField(body, "Trasfondo", 18, 285, 566, 126, data.trasfondo or data.bio or "", true)

    local btnSave = vgui.Create("DButton", frame)
    btnSave:SetText("GUARDAR EXPEDIENTE")
    btnSave:SetPos(746, 622)
    btnSave:SetSize(210, 36)
    DrawTLOUButton(btnSave, TLOU_COLORS.mossDark)
    btnSave.DoClick = function()
        net.Start("CharCreator_Save")
        net.WriteTable({
            name = txtName:GetValue(),
            age = txtAge:GetValue(),
            bio = txtTras:GetValue(),
            personalidad_fisica = txtPF:GetValue(),
            personalidad_psicologica = txtPP:GetValue(),
            trasfondo = txtTras:GetValue(),
            vinculos = txtVinc:GetValue()
        })
        net.SendToServer()
        frame:Close()
    end

    local btnClose = vgui.Create("DButton", frame)
    btnClose:SetText("CANCELAR")
    btnClose:SetPos(610, 622)
    btnClose:SetSize(120, 36)
    DrawTLOUButton(btnClose, Color(80, 61, 48))
    btnClose.DoClick = function()
        frame:Close()
    end
end

net.Receive("CharCreator_SendData", function()
    OpenCharCreator(net.ReadTable() or {})
end)
