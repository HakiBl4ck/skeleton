if (CLIENT) then
    local PLUGIN = PLUGIN

    function PLUGIN:PlayerButtonDown(client, button)
        if (SERVER or !IsFirstTimePredicted()) then return end

        if (button == KEY_I) then
            self:OpenCustomInventory()
        elseif (button == KEY_K) then
            net.Start("ixCustomInvSaveItem")
            net.SendToServer()
        end
    end

function PLUGIN:OpenCustomInventory()
    if (SERVER) then return end
    
    local lp = LocalPlayer()
    if (!IsValid(lp)) then return end

    if (IsValid(self.invFrame)) then self.invFrame:Remove() end

    local char = lp:GetCharacter()
    if (!char) then return end
    local maxSlots = self.maxSlots or 24

    local items = char:GetData("custom_inv", {})
    local color_bg = Color(20, 20, 20, 240)
    local color_accent = Color(140, 150, 100)

    self.invFrame = vgui.Create("DFrame")
    self.invFrame:SetTitle("")
    self.invFrame:SetSize(450, 650)
    self.invFrame:Center()
    self.invFrame:MakePopup()
    self.invFrame.Paint = function(self, w, h)
        surface.SetDrawColor(color_bg)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(color_accent)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("MOCHILA DE SUPERVIVENCIA", "ixMediumFont", w/2, 15, color_accent, TEXT_ALIGN_CENTER)
    end

    local grid = self.invFrame:Add("DGrid")
    grid:Dock(FILL)
    grid:DockMargin(20, 40, 10, 10)
    grid:SetCols(4)
    grid:SetColWide(100)
    grid:SetRowHeight(100)

    for i = 1, maxSlots do
        local slot = vgui.Create("Panel")
        slot:SetSize(90, 90)
        slot.Paint = function(self, w, h)
            surface.SetDrawColor(40, 40, 40, 200)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(color_accent)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end

        local itemData = items[i]
        if (itemData) then
            local icon = slot:Add("SpawnIcon")
            icon:SetSize(80, 80)
            icon:Center()
            icon:SetModel(itemData.model or "models/items/healthkit.mdl")
            icon:SetTooltip(itemData.name)
            
            icon.DoClick = function()
                local menu = DermaMenu()
                menu:AddOption("Usar", function() print("Usando " .. itemData.name) end)
                menu:AddOption("Soltar", function() print("Soltando " .. itemData.name) end)
                menu:Open()
            end
        end

        grid:AddItem(slot)
    end

    local footer = self.invFrame:Add("DLabel")
    footer:Dock(BOTTOM)
    footer:SetTall(30)
    footer:SetText("ESPACIO: " .. #items .. " / " .. maxSlots)
    footer:SetContentAlignment(5)
    footer:SetFont("ixSmallFont")
    footer:SetTextColor(color_accent)
end
end