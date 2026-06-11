local function getRecipientsInRange(origin, range)
    local recipients = {}
    local rangeSqr = range * range

    for _, player in ipairs(player.GetAll()) do
        if (IsValid(player) and player:GetPos():DistToSqr(origin) <= rangeSqr) then
            recipients[#recipients + 1] = player
        end
    end

    return recipients
end

local function addRoleplayChatCommand(name, chatType, range, description, aliases)
    ix.command.Add(name, {
        description = description,
        arguments = ix.type.text,
        alias = aliases,
        OnRun = function(self, client, text)
            ix.chat.Send(client, chatType, text, false, getRecipientsInRange(client:GetPos(), ix.config.Get("chatRange", range)))
        end
    })
end

addRoleplayChatCommand("Do", "do", 280, "Describe una situación o el entorno.", {"do"})
addRoleplayChatCommand("Me", "me", 280, "Describe una acción de tu personaje.", {"me"})
addRoleplayChatCommand("Entorno", "entorno", 500, "Lanza un mensaje de entorno local.", {"entorno"})
addRoleplayChatCommand("Susurrar", "whisper", 160, "Habla en voz baja cerca de ti.", {"susurrar", "whisper"})
addRoleplayChatCommand("Gritar", "yell", 900, "Grita para que te escuchen a distancia.", {"gritar", "yell"})

ix.command.Add("Intentar", {
    description = "Intenta realizar una acción (50% de probabilidad).",
    arguments = ix.type.text,
    alias = {"intentar"},
    OnRun = function(self, client, text)
        local success = math.random(1, 2) == 1
        local result = success and "ÉXITO" or "FALLO"
        ix.chat.Send(client, "me", text .. " | RESULTADO: " .. result, false, getRecipientsInRange(client:GetPos(), ix.config.Get("chatRange", 280)))
    end
})

ix.command.Add("Roll", {
    description = "Tira un dado de 100 caras.",
    arguments = ix.type.number,
    OnRun = function(self, client, max)
        local maximum = tonumber(max) or 100
        local roll = math.random(0, maximum)
        ix.util.Notify(string.format("%s ha sacado un %d de %d en los dados.", client:Name(), roll, maximum))
    end
})

if (SERVER) then
    util.AddNetworkString("ixAmeAction")
    ix.command.Add("Ame", {
        description = "Muestra una acción sobre la cabeza de tu personaje.",
        arguments = ix.type.text,
        OnRun = function(self, client, text)
            local character = client:GetCharacter()
            if (not character) then
                return
            end

            text = tostring(text or "")
            character:SetData("ame_text", text)
            net.Start("ixAmeAction")
                net.WriteEntity(client)
                net.WriteString(text)
            net.Broadcast()
        end
    })
end

hook.Add("InitializedChatClasses", "SkeletonAmeChat", function()
    ix.chat.Register("ame", {
        prefix = {"/ame", "/Ame"},
        description = "Muestra una acción personal sobre tu personaje.",
        indicator = "chatPerforming",
        bNoIndicator = true,
        CanSay = function(self, speaker, text)
            return true
        end,
        OnChatAdd = function() end
    })
end)

hook.Add("PlayerMessageSend", "SkeletonAmePersist", function(client, chatType, message)
    if (chatType ~= "ame") then return end

    local character = client:GetCharacter()
    if (not character) then return end

    message = tostring(message or "")
    character:SetData("ame_text", message)
    net.Start("ixAmeAction")
        net.WriteEntity(client)
        net.WriteString(message)
    net.Broadcast()

    return message
end)
