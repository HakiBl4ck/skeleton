-- Cliente: herramientas administrativas adicionales
print("[TLouAdmin] Cliente cargando cl_adminextras.lua")

local function IsTLOUAdmin(ply)
    if not IsValid(ply) then return false end
    -- Verificar el flag persistente primero (no depende de cargas de facción)
    if ply:GetPData("tlou_is_admin", "0") == "1" then return true end
    -- Luego verificar equipo (si FACTION_ADMINS está disponible)
    if FACTION_ADMINS and ply:Team() == FACTION_ADMINS then return true end
    return false
end

local function styleButton(btn, bg)
    btn:SetTextColor(Color(235,235,235))
    btn.Paint = function(self, w, h)
        local col = bg or Color(80, 80, 76)
        if self:IsDown() then col = Color(math.max(col.r - 10, 0), math.max(col.g - 10, 0), math.max(col.b - 10, 0)) end
        if self:IsHovered() then col = Color(math.min(col.r + 8, 255), math.min(col.g + 8, 255), math.min(col.b + 8, 255)) end
        draw.RoundedBox(6, 0, 0, w, h, col)
        draw.SimpleText(self:GetText(), "DermaDefaultBold", w/2, h/2, Color(240,240,240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

local function BuildPlayerModelChoices()
    local choices = {}
    local allModels = player_manager.AllValidModels and player_manager.AllValidModels() or {}

    for name, model in pairs(allModels) do
        if isstring(model) and model ~= "" then
            choices[#choices + 1] = {
                name = tostring(name),
                model = model
            }
        end
    end

    table.SortByMember(choices, "name", true)
    return choices
end

local function OpenPropSpawner()
    local ply = LocalPlayer()
    if not IsTLOUAdmin(ply) then return end

    local frame = vgui.Create("DFrame")
    frame:SetTitle("TLOU Admin - Colocar objeto")
    frame:SetSize(480, 200)
    frame:Center()
    frame:MakePopup()
    frame.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(28, 24, 20))
        draw.RoundedBox(0, 0, 0, w, 32, Color(36, 30, 26))
        draw.SimpleText("Colocar objeto", "DermaLarge", 16, 6, Color(230,220,200), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    local models = {
        "models/props_c17/oildrum001.mdl",
        "models/props_c17/chair02a.mdl",
        "models/props_c17/bench01a.mdl",
        "models/props_wasteland/laundry_dryer001.mdl"
    }

    local label = vgui.Create("DLabel", frame)
    label:SetText("Modelo:")
    label:SetPos(16, 48)
    label:SizeToContents()
    label:SetColor(Color(220,220,210))

    local combo = vgui.Create("DComboBox", frame)
    combo:SetPos(16, 68)
    combo:SetSize(frame:GetWide() - 32, 24)
    combo:SetValue(models[1])
    for _, mdl in ipairs(models) do
        combo:AddChoice(mdl)
    end

    local btnSpawn = vgui.Create("DButton", frame)
    btnSpawn:SetText("Colocar objeto")
    btnSpawn:SetPos(16, 110)
    btnSpawn:SetSize(frame:GetWide() - 32, 32)
    btnSpawn.DoClick = function()
        local model = combo:GetValue()
        if not model or model == "" then
            chat.AddText(Color(255,100,100), "Selecciona un modelo primero")
            return
        end
        chat.AddText(Color(150,200,255), "Spawneando objeto: " .. model)
        net.Start("TLouAdmin_SpawnProp")
        net.WriteString(model)
        net.SendToServer()
        frame:Close()
    end
    btnSpawn:SetTextColor(Color(235,235,235))
    btnSpawn.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(80, 80, 76))
        if self:IsHovered() then draw.RoundedBox(6, 0, 0, w, h, Color(95, 95, 90)) end
        draw.SimpleText(self:GetText(), "DermaDefaultBold", w/2, h/2, Color(240,240,240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

hook.Add("PopulateToolMenu", "TLouAdmin_PropSpawner", function()
    local ply = LocalPlayer()
    print("[TLouAdmin] PopulateToolMenu hook ejecutado, player: " .. (IsValid(ply) and ply:Nick() or "INVÁLIDO"))
    if not IsTLOUAdmin(ply) then 
        print("[TLouAdmin] Player no es admin, retornando")
        return 
    end
    print("[TLouAdmin] Player es admin, agregando opción al menú")
    spawnmenu.AddToolMenuOption("Utilities", "The Last of Us", "TLOUAdminTools", "TLOU Admin", "", "", function(panel)
        panel:ClearControls()
        panel:Help("Herramientas administrativas TLOU")
        panel:ControlHelp("Solo disponible para administradores.")
        panel:Button("Colocar objeto", "", function()
            print("[TLouAdmin] Botón de 'Colocar objeto' presionado")
            OpenPropSpawner()
        end)
    end)
end)

local adminContextMenu
hook.Add("OnContextMenuOpen", "TLouAdmin_ContextMenu", function()
    local ply = LocalPlayer()
    print("[TLouAdmin] OnContextMenuOpen hook ejecutado, player: " .. (IsValid(ply) and ply:Nick() or "INVÁLIDO"))
    if not IsTLOUAdmin(ply) then 
        print("[TLouAdmin] Player no es admin, retornando")
        return 
    end
    print("[TLouAdmin] Player es admin, abriendo context menu")
    if IsValid(adminContextMenu) then adminContextMenu:Remove() end

    adminContextMenu = vgui.Create("DFrame")
    adminContextMenu:SetTitle("TLOU Admin - Modelos")
    adminContextMenu:SetSize(520, 360)
    adminContextMenu:AlignRight(10)
    adminContextMenu:AlignBottom(10)
    adminContextMenu:MakePopup()
    adminContextMenu:SetKeyboardInputEnabled(false)
    adminContextMenu:SetMouseInputEnabled(true)
    adminContextMenu.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(24, 22, 20, 220))
        draw.RoundedBox(0, 0, 0, w, 32, Color(36, 30, 26, 220))
        draw.SimpleText("Cambiar playermodel", "DermaLarge", 14, 8, Color(235,225,205), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    local models = BuildPlayerModelChoices()
    local selectedModel = models[1] and models[1].model or "models/player/kleiner.mdl"

    local combo = vgui.Create("DComboBox", adminContextMenu)
    combo:SetPos(16, 50)
    combo:SetSize(300, 24)
    combo:SetValue(models[1] and models[1].name or selectedModel)
    for _, data in ipairs(models) do
        combo:AddChoice(data.name, data.model)
    end

    local preview = vgui.Create("DModelPanel", adminContextMenu)
    preview:SetPos(332, 48)
    preview:SetSize(170, 240)
    preview:SetModel(selectedModel)
    preview:SetFOV(36)
    preview:SetCamPos(Vector(70, 0, 58))
    preview:SetLookAt(Vector(0, 0, 48))
    preview.LayoutEntity = function(self, ent)
        ent:SetAngles(Angle(0, RealTime() * 20 % 360, 0))
    end

    combo.OnSelect = function(_, _, _, model)
        if model and model ~= "" then
            selectedModel = model
            preview:SetModel(model)
        end
    end

    local btnModel = vgui.Create("DButton", adminContextMenu)
    btnModel:SetText("Cambiar model")
    btnModel:SetPos(16, 90)
    btnModel:SetSize(300, 30)
    btnModel.DoClick = function()
        local selectedID = combo:GetSelectedID()
        if not selectedID then 
            chat.AddText(Color(255,100,100), "Selecciona un modelo primero")
            return
        end
        local selectedModel = combo:GetOptionData(selectedID)
        if not selectedModel or selectedModel == "" then 
            chat.AddText(Color(255,100,100), "Error: modelo inválido")
            return
        end
        chat.AddText(Color(150,200,255), "Cambiando modelo a: " .. combo:GetOptionText(selectedID))
        net.Start("TLouAdmin_SetPlayermodel")
        net.WriteString(selectedModel)
        net.SendToServer()
    end
    styleButton(btnModel, Color(70,90,70))

    local btnClose = vgui.Create("DButton", adminContextMenu)
    btnClose:SetText("Cerrar")
    btnClose:SetPos(16, 130)
    btnClose:SetSize(300, 30)
    btnClose.DoClick = function()
        adminContextMenu:Close()
    end
    styleButton(btnClose, Color(140,60,60))
end)

hook.Add("OnContextMenuClose", "TLouAdmin_ContextMenuClose", function()
    if IsValid(adminContextMenu) then
        adminContextMenu:Remove()
    end
end)
