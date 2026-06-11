-- Cliente: HUD TLOU
if CLIENT then
    local hiddenHUD = {
        CHudHealth = true,
        CHudBattery = true,
        CHudAmmo = false,
        CHudSecondaryAmmo = false
    }

    local colors = {
        bg = Color(12, 14, 12, 188),
        bgDark = Color(4, 5, 4, 210),
        panel = Color(28, 31, 24, 170),
        line = Color(97, 89, 64, 210),
        text = Color(226, 220, 205),
        muted = Color(172, 165, 145),
        health = Color(138, 42, 38),
        stamina = Color(204, 153, 47),
        armor = Color(82, 111, 91),
        moss = Color(76, 96, 67),
        rust = Color(153, 83, 47)
    }

    surface.CreateFont("TLOUHUD_Title", {
        font = "DermaLarge",
        size = 22,
        weight = 800,
        antialias = true
    })

    surface.CreateFont("TLOUHUD_Small", {
        font = "DermaDefault",
        size = 15,
        weight = 500,
        antialias = true
    })

    surface.CreateFont("TLOUHUD_Tiny", {
        font = "DermaDefaultBold",
        size = 13,
        weight = 700,
        antialias = true
    })

    local function PolyCircle(x, y, radius, segments)
        local poly = {}

        for i = 0, segments do
            local angle = math.rad((i / segments) * -360)
            poly[#poly + 1] = {
                x = x + math.sin(angle) * radius,
                y = y + math.cos(angle) * radius
            }
        end

        return poly
    end

    local function DrawCircleOutline(x, y, radius, color)
        surface.SetDrawColor(color)
        for i = 0, 2 do
            surface.DrawCircle(x, y, radius - i, color.r, color.g, color.b, color.a)
        end
    end

    local function DrawRoughLine(x1, y1, x2, y2, color)
        surface.SetDrawColor(color)
        surface.DrawLine(x1, y1, x2, y2)
        surface.DrawLine(x1 + 1, y1 + 1, x2 + 1, y2 + 1)
    end

    local function DrawBar(x, y, w, h, label, fraction, barColor)
        fraction = math.Clamp(fraction or 0, 0, 1)

        draw.RoundedBox(2, x, y, w, h, colors.bgDark)
        surface.SetDrawColor(colors.line)
        surface.DrawOutlinedRect(x, y, w, h)

        local fillW = math.floor((w - 6) * fraction)
        if fillW > 0 then
            draw.RoundedBox(1, x + 3, y + 3, fillW, h - 6, barColor)
        end

        surface.SetDrawColor(255, 255, 255, 18)
        for i = 0, 4 do
            surface.DrawLine(x + 8 + i * 72, y + 2, x + 22 + i * 72, y + h - 2)
        end

        draw.SimpleText(label, "TLOUHUD_Tiny", x + w / 2, y + h / 2 - 1, colors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local function GetFactionInfo(client)
        local factionName = "SIN FACCION"
        local factionColor = colors.moss

        if ix and ix.faction and client.GetCharacter then
            local character = client:GetCharacter()
            local faction = character and ix.faction.indices[character:GetFaction()]

            if faction then
                factionName = string.upper(faction.name or factionName)
                factionColor = faction.color or factionColor
            end
        elseif team.Valid(client:Team()) then
            factionName = string.upper(team.GetName(client:Team()) or factionName)
            factionColor = team.GetColor(client:Team()) or factionColor
        end

        return factionName, factionColor
    end

    local function GetMoney(client)
        if client.GetCharacter then
            local character = client:GetCharacter()
            if character then
                return tonumber(character:GetData("money")) or 0
            end
        end

        if client.GetPData then
            return tonumber(client:GetPData("tlou_money", "0")) or 0
        end

        return 0
    end

    local function GetStamina(client)
        local stamina = client.GetLocalVar and client:GetLocalVar("stm", client:GetNWFloat("stamina", 100)) or client:GetNWFloat("stamina", 100)
        local maxStamina = client.GetLocalVar and client:GetLocalVar("stmMax", 100) or 100

        if maxStamina <= 0 then
            maxStamina = 100
        end

        return math.Clamp((tonumber(stamina) or maxStamina) / maxStamina, 0, 1)
    end

    hook.Add("HUDShouldDraw", "TLOUHUD_HideDefault", function(name)
        if hiddenHUD[name] then return false end
    end)

    hook.Add("HUDPaint", "TLOUHUD_Draw", function()
        local client = LocalPlayer()
        if not IsValid(client) or not client:Alive() then return end

        local screenW, screenH = ScrW(), ScrH()
        local scale = math.Clamp(screenW / 1920, 0.78, 1)
        local baseX = 58 * scale
        local baseY = screenH - 220 * scale
        local logoRadius = 108 * scale
        local barX = baseX + logoRadius * 2 + 28 * scale
        local barW = 500 * scale
        local barH = 20 * scale

        local factionName, factionColor = GetFactionInfo(client)
        local health = math.Clamp(client:Health() / math.max(client:GetMaxHealth(), 1), 0, 1)
        local armor = math.Clamp(client:Armor() / 100, 0, 1)
        local stamina = GetStamina(client)
        local money = GetMoney(client)

        draw.NoTexture()
        surface.SetDrawColor(colors.bg)
        surface.DrawPoly(PolyCircle(baseX + logoRadius, baseY + logoRadius, logoRadius, 64))
        DrawCircleOutline(baseX + logoRadius, baseY + logoRadius, logoRadius, Color(0, 0, 0, 230))
        DrawCircleOutline(baseX + logoRadius, baseY + logoRadius, logoRadius - 8 * scale, Color(factionColor.r, factionColor.g, factionColor.b, 125))

        draw.SimpleText("ZONA", "TLOUHUD_Tiny", baseX + logoRadius, baseY + 70 * scale, colors.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(factionName, "TLOUHUD_Small", baseX + logoRadius, baseY + 97 * scale, colors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("SUPERVIVIENTE", "TLOUHUD_Tiny", baseX + logoRadius, baseY + 128 * scale, colors.rust, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        DrawRoughLine(barX - 16 * scale, baseY + 52 * scale, barX + barW + 18 * scale, baseY + 52 * scale, Color(0, 0, 0, 170))
        DrawBar(barX, baseY + 38 * scale, barW, barH, "", health, colors.health)
        DrawBar(barX, baseY + 86 * scale, barW * 0.94, barH, "", stamina, colors.stamina)

        if armor > 0 then
            DrawBar(barX, baseY + 132 * scale, barW * 0.84, barH, "", armor, colors.armor)
        else
            draw.RoundedBox(2, barX, baseY + 136 * scale, barW * 0.84, 26 * scale, Color(64, 66, 42, 90))
            draw.SimpleText("SIN PROTECCION  |  $" .. money, "TLOUHUD_Tiny", barX + 12 * scale, baseY + 148 * scale, colors.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        local serverX = screenW - 136 * scale
        local serverY = 28 * scale
        local serverR = 62 * scale

        surface.SetDrawColor(Color(8, 9, 8, 150))
        surface.DrawPoly(PolyCircle(serverX, serverY + serverR, serverR, 48))
        DrawCircleOutline(serverX, serverY + serverR, serverR, Color(0, 0, 0, 220))
        DrawCircleOutline(serverX, serverY + serverR, serverR - 7 * scale, Color(colors.rust.r, colors.rust.g, colors.rust.b, 110))

        draw.SimpleText("THE LAST", "TLOUHUD_Tiny", serverX, serverY + serverR - 12 * scale, colors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("OF US RP", "TLOUHUD_Tiny", serverX, serverY + serverR + 10 * scale, colors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end)
end
