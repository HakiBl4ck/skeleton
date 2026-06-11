PLUGIN.name = "Comandos de Rol TLOU"
PLUGIN.author = "Gemini Code Assist"
PLUGIN.description = "Añade comandos esenciales para el roleplay: /do, /ame, /intentar, etc."

ix.util.Include("sh_commands.lua")

local function getSpeakerName(speaker)
    if (IsValid(speaker)) then
        local character = speaker:GetCharacter()
        if (character and character.GetName) then
            return character:GetName()
        end

        if (speaker.Name) then
            return speaker:Name()
        end
    end

    return "Desconocido"
end

local function getCharacterName(speaker)
    if (IsValid(speaker)) then
        local character = speaker:GetCharacter()
        if (character and character.GetName) then
            return character:GetName()
        end
    end

    return getSpeakerName(speaker)
end

hook.Add("InitializedChatClasses", "SkeletonChatOverrides", function()
    local ic = ix.chat.classes.ic
    if (ic) then
        ic.format = "%s dice: %s"
    end

    local me = ix.chat.classes.me
    if (me) then
        me.OnChatAdd = function(self, speaker, text)
            chat.AddText(self.color or Color(200, 180, 140), string.format("[ME] %s hace %s", getCharacterName(speaker), text))
        end
    end
end)

ix.chat.Register("do", {
    format = "[DO] %s dice: %s",
    color = Color(150, 150, 200),
    OnChatAdd = function(self, speaker, text)
        chat.AddText(self.color, string.format(self.format, getCharacterName(speaker), text))
    end,
    CanSay = function(self, speaker, text) return true end,
    deadCanChat = true
})

ix.chat.Register("me", {
    color = Color(200, 180, 140),
    CanSay = function(self, speaker, text) return true end,
    deadCanChat = true
})

ix.chat.Register("entorno", {
    format = "[ENTORNO] %s",
    color = Color(140, 160, 140),
    OnChatAdd = function(self, speaker, text)
        chat.AddText(self.color, string.format(self.format, text))
    end,
    CanSay = function(self, speaker, text) return true end
})

ix.chat.Register("whisper", {
    format = "[SUSURRA] %s dice: %s",
    color = Color(170, 170, 170),
    range = 160,
    OnChatAdd = function(self, speaker, text)
        chat.AddText(self.color, string.format(self.format, getCharacterName(speaker), text))
    end,
    CanSay = function(self, speaker, text) return true end
})

ix.chat.Register("yell", {
    format = "[GRITA] %s dice: %s",
    color = Color(230, 170, 120),
    range = 900,
    OnChatAdd = function(self, speaker, text)
        chat.AddText(self.color, string.format(self.format, getCharacterName(speaker), text))
    end,
    CanSay = function(self, speaker, text) return true end
})

if (CLIENT) then
    local ameActions = {}

    local function syncAme(entity, text)
        if (IsValid(entity) and text and text ~= "") then
            ameActions[entity] = {text = text, die = 0}
        else
            ameActions[entity] = nil
        end
    end

    net.Receive("ixAmeAction", function()
        local ent = net.ReadEntity()
        local text = net.ReadString()

        if (IsValid(ent)) then
            syncAme(ent, text)
        end
    end)

    net.Receive("ixAmeSync", function()
        ameActions = {}

        local count = net.ReadUInt(8)
        for _ = 1, count do
            local ent = net.ReadEntity()
            local text = net.ReadString()

            if (IsValid(ent) and text ~= "") then
                syncAme(ent, text)
            end
        end
    end)

    function PLUGIN:PostPlayerDraw(client)
        local ameData = ameActions[client]
        if (not ameData or not ameData.text or ameData.text == "") then return end

        local pos = client:GetPos() + Vector(0, 0, client:GetModelRadius() + 15)
        local ang = LocalPlayer():EyeAngles()

        ang:RotateAroundAxis(ang:Forward(), 90)
        ang:RotateAroundAxis(ang:Right(), 90)

        cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.05)
            draw.SimpleTextOutlined("> " .. ameData.text .. " <", "ixMediumFont", 0, 0, Color(200, 150, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
        cam.End3D2D()
    end

    hook.Add("InitPostEntity", "ixAmeRequestSync", function()
        net.Start("ixAmeRequest")
        net.SendToServer()
    end)
end
