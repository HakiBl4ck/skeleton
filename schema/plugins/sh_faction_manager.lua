PLUGIN = PLUGIN or {}
PLUGIN.name = "Faction Manager"
PLUGIN.author = "Gemini Code Assist"
PLUGIN.description = "Gestiona facciones, miembros y rangos."

local DATA_FILE = "tlou_faction_manager.json"

FactionManager = FactionManager or {}

function FactionManager.NormalizeColor(colorTable)
    if (istable(colorTable)) then
        return Color(
            tonumber(colorTable.r) or 255,
            tonumber(colorTable.g) or 255,
            tonumber(colorTable.b) or 255,
            tonumber(colorTable.a) or 255
        )
    end

    return Color(255, 255, 255)
end

function FactionManager.GetDefaultData()
    return {
        overrides = {},
        members = {},
        ranks = {},
        custom = {}
    }
end

function FactionManager.GetFactionID(faction)
    if (isnumber(faction)) then
        return faction
    end

    if (istable(faction) and faction.index) then
        return faction.index
    end

    return nil
end

function FactionManager.GetStoredData()
    return ix.data and ix.data.Get("tlouFactionManager", FactionManager.GetDefaultData()) or FactionManager.GetDefaultData()
end
