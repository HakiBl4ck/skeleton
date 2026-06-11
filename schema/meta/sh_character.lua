
-- In some cases you'll want to extend the metatables of a few classes. The standard way of doing so is to place your
-- extensions/overrides in the meta/ folder where each file pertains to one class.

local CHAR = ix.meta.character

function CHAR:IsPolice()
	return self:GetFaction() == FACTION_POLICE
end

if (ix and ix.char and ix.char.vars and ix.char.vars.faction and ix.char.vars.faction.OnValidate) then
	local factionVar = ix.char.vars.faction
	local originalOnValidate = factionVar.OnValidate

	factionVar.OnValidate = function(self, index, data, client)
		local result = {originalOnValidate(self, index, data, client)}

		if (result[1] == false and result[2] == nil) then
			return false, "unknownError"
		end

		return unpack(result)
	end
end
