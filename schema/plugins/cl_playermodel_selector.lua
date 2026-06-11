-- Cliente: selector inicial de playermodel con preview
if CLIENT then
    local function BuildModelList()
        local models = {}
        local allModels = player_manager.AllValidModels and player_manager.AllValidModels() or {}

        for name, model in pairs(allModels) do
            if isstring(model) and model ~= "" then
                models[#models + 1] = {
                    name = tostring(name),
                    model = model
                }
            end
        end

        table.SortByMember(models, "name", true)
        return models
    end

    local function StyleButton(button, baseColor)
        button:SetTextColor(Color(235, 230, 215))
        button:SetFont("DermaDefaultBold")
        button.Paint = function(self, w, h)
            local col = baseColor
            if self:IsHovered() then
                col = Color(math.min(baseColor.r + 20, 255), math.min(baseColor.g + 20, 255), math.min(baseColor.b + 20, 255))
            end
            if self:IsDown() then
                col = Color(math.max(baseColor.r - 18, 0), math.max(baseColor.g - 18, 0), math.max(baseColor.b - 18, 0))
            end

            draw.RoundedBox(4, 0, 0, w, h, col)
            surface.SetDrawColor(95, 84, 62)
            surface.DrawOutlinedRect(0, 0, w, h)
        end
    end

    local function OpenModelSelector()
        local models = BuildModelList()
        local selectedModel = models[1] and models[1].model or "models/player/kleiner.mdl"

        local frame = vgui.Create("DFrame")
        frame:SetTitle("")
        frame:SetSize(860, 620)
        frame:Center()
        frame:MakePopup()
        frame:SetDraggable(false)
        frame:ShowCloseButton(false)
        frame.Paint = function(self, w, h)
            draw.RoundedBox(8, 0, 0, w, h, Color(15, 17, 14))
            draw.RoundedBox(0, 0, 0, w, 92, Color(42, 39, 31))
            draw.SimpleText("THE LAST OF US", "DermaLarge", 24, 16, Color(226, 220, 205), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText("ELIGE TU APARIENCIA INICIAL", "DermaDefaultBold", 26, 54, Color(150, 86, 48), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            surface.SetDrawColor(150, 86, 48)
            surface.DrawLine(20, 92, w - 20, 92)
        end

        local list = vgui.Create("DListView", frame)
        list:SetPos(24, 116)
        list:SetSize(390, 420)
        list:AddColumn("Nombre")
        list:AddColumn("Modelo")

        for _, data in ipairs(models) do
            local line = list:AddLine(data.name, data.model)
            line.modelPath = data.model
        end

        local previewPanel = vgui.Create("DPanel", frame)
        previewPanel:SetPos(438, 116)
        previewPanel:SetSize(398, 420)
        previewPanel.Paint = function(self, w, h)
            draw.RoundedBox(6, 0, 0, w, h, Color(25, 28, 23))
            surface.SetDrawColor(92, 82, 62)
            surface.DrawOutlinedRect(0, 0, w, h)
        end

        local preview = vgui.Create("DModelPanel", previewPanel)
        preview:SetPos(0, 0)
        preview:SetSize(398, 420)
        preview:SetModel(selectedModel)
        preview:SetFOV(36)
        preview:SetCamPos(Vector(70, 0, 58))
        preview:SetLookAt(Vector(0, 0, 48))
        preview.LayoutEntity = function(self, ent)
            ent:SetAngles(Angle(0, RealTime() * 20 % 360, 0))
        end

        local selectedLabel = vgui.Create("DLabel", frame)
        selectedLabel:SetPos(24, 548)
        selectedLabel:SetSize(560, 22)
        selectedLabel:SetTextColor(Color(190, 184, 168))
        selectedLabel:SetText("Seleccionado: " .. selectedModel)

        list.OnRowSelected = function(_, _, row)
            selectedModel = row.modelPath or selectedModel
            preview:SetModel(selectedModel)
            selectedLabel:SetText("Seleccionado: " .. selectedModel)
        end

        local confirm = vgui.Create("DButton", frame)
        confirm:SetText("CONFIRMAR MODELO")
        confirm:SetPos(626, 550)
        confirm:SetSize(210, 42)
        StyleButton(confirm, Color(54, 72, 52))
        confirm.DoClick = function()
            net.Start("TLOUModelSelector_Select")
            net.WriteString(selectedModel)
            net.SendToServer()
            frame:Close()
        end
    end

    net.Receive("TLOUModelSelector_Open", function()
        OpenModelSelector()
    end)
end
