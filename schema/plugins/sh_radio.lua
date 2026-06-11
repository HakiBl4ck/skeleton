PLUGIN.name = "Radio escrita"
PLUGIN.author = "Codex"
PLUGIN.description = "Añade un chat de radio por frecuencia con comandos /radio y /sintonizar."

local RADIO_FREQUENCY_KEY = "radio_frequency"
local DEFAULT_FREQUENCY = 100
local MIN_FREQUENCY = 1
local MAX_FREQUENCY = 999

local function getCharacter(client)
	if (IsValid(client) and client.GetCharacter) then
		return client:GetCharacter()
	end
end

local function getCharacterName(client)
	local character = getCharacter(client)

	if (character and character.GetName) then
		return character:GetName()
	end

	if (IsValid(client) and client.Name) then
		return client:Name()
	end

	return "Desconocido"
end

local function getFrequency(client)
	local character = getCharacter(client)

	if (character and character.GetData) then
		return tonumber(character:GetData(RADIO_FREQUENCY_KEY, DEFAULT_FREQUENCY)) or DEFAULT_FREQUENCY
	end

	return DEFAULT_FREQUENCY
end

local function setFrequency(client, frequency)
	local character = getCharacter(client)

	if (not character or not character.SetData) then
		return false
	end

	character:SetData(RADIO_FREQUENCY_KEY, frequency)
	return true
end

local function normalizeFrequency(value)
	local frequency = math.floor(tonumber(value) or 0)

	if (frequency < MIN_FREQUENCY or frequency > MAX_FREQUENCY) then
		return nil
	end

	return frequency
end

hook.Add("InitializedChatClasses", "SkeletonRadioChatFormat", function()
	local ic = ix.chat.classes.ic

	if (ic) then
		ic.format = "%s dice: %s"
	end
end)

if (SERVER) then
	util.AddNetworkString("ixRadioMessage")

	local function sendRadioMessage(client, text)
		local frequency = getFrequency(client)
		local speakerName = getCharacterName(client)

		for _, target in ipairs(player.GetAll()) do
			if (IsValid(target) and getFrequency(target) == frequency) then
				net.Start("ixRadioMessage")
					net.WriteString(speakerName)
					net.WriteString(text)
					net.WriteUInt(frequency, 16)
				net.Send(target)
			end
		end
	end

	ix.command.Add("radio", {
		description = "Envía un mensaje por la frecuencia actual de radio.",
		arguments = {ix.type.text},
		OnRun = function(self, client, text)
			local message = string.Trim(tostring(text or ""))

			if (message == "") then
				client:ChatPrint("Debes escribir un mensaje para la radio.")
				return
			end

			sendRadioMessage(client, message)
		end
	})

	ix.command.Add("sintonizar", {
		description = "Cambia la frecuencia de radio.",
		arguments = {ix.type.number},
		OnRun = function(self, client, frequency)
			local tunedFrequency = normalizeFrequency(frequency)

			if (not tunedFrequency) then
				client:ChatPrint("Frecuencia inválida. Usa un número entre " .. MIN_FREQUENCY .. " y " .. MAX_FREQUENCY .. ".")
				return
			end

			if (not setFrequency(client, tunedFrequency)) then
				client:ChatPrint("No se pudo guardar tu frecuencia de radio.")
				return
			end

			client:ChatPrint("Ahora estás sintonizado en la frecuencia " .. tunedFrequency .. ".")
		end
	})

	hook.Add("PlayerLoadedCharacter", "SkeletonRadioDefaultFrequency", function(client, character)
		if (character and character.GetData and character:GetData(RADIO_FREQUENCY_KEY, nil) == nil) then
			character:SetData(RADIO_FREQUENCY_KEY, DEFAULT_FREQUENCY)
		end
	end)
end

if (CLIENT) then
	net.Receive("ixRadioMessage", function()
		local speakerName = net.ReadString()
		local message = net.ReadString()
		local frequency = net.ReadUInt(16)

		chat.AddText(Color(120, 200, 255), "[RADIO " .. frequency .. "] ", color_white, speakerName .. " dice: " .. message)
	end)
end
