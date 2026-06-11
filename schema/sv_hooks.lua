
-- Here is where all of your serverside hooks should go.

-- Change death sounds of people in the police faction to the metropolice death sound.
function Schema:GetPlayerDeathSound(client)
	local character = client:GetCharacter()

	if (character and character:IsPolice()) then
		return "NPC_MetroPolice.Die"
	end
end

if (SERVER) then
    util.AddNetworkString("ixAmeRequest")
    util.AddNetworkString("ixAmeSync")

    net.Receive("ixAmeRequest", function(_, client)
        if (not IsValid(client)) then return end

        local ameEntries = {}
        local count = 0

        for _, player in ipairs(player.GetAll()) do
            local character = player:GetCharacter()
            local ameText = character and character:GetData("ame_text", "") or ""

            if (ameText ~= "") then
                count = count + 1
                ameEntries[count] = {player = player, text = ameText}
            end
        end

        net.Start("ixAmeSync")
            net.WriteUInt(count, 8)

            for i = 1, count do
                net.WriteEntity(ameEntries[i].player)
                net.WriteString(ameEntries[i].text)
            end
        net.Send(client)
    end)
end

function Schema:CharacterLoaded(character)
    local player = character:GetPlayer()
    local ameText = character:GetData("ame_text", "")

    if (IsValid(player) and ameText ~= "") then
        net.Start("ixAmeAction")
            net.WriteEntity(player)
            net.WriteString(ameText)
        net.Broadcast()
    end
end

function Schema:CanPlayerUseCharacter(client, character)
    if (not character) then
        return false, "@unknownError"
    end

    local name = character:GetName()
    local citizenFaction = isnumber(FACTION_CITIZEN) and FACTION_CITIZEN

    if (not citizenFaction and ix and ix.faction and ix.faction.GetIndex) then
        citizenFaction = ix.faction.GetIndex("citizen")
    end

    if (name and string.Trim(string.lower(name)) == "joel bill" and citizenFaction and character:GetFaction() ~= citizenFaction) then
        character:SetFaction(citizenFaction)

        if (character.Save) then
            character:Save()
        end
    end
end
