local PLUGIN = PLUGIN or {}

PLUGIN.name = "Saludar al jugador cuando spawnee"
PLUGIN.author = "Max"
PLUGIN.description = "Saluda al jugador cuando aparezca y le informa su dinero"

function PLUGIN:InitializedPlugins()
    print("[MIPLUGIN]Plugin cargado correctamente")
end

function PLUGIN:PlayerLoadedCharacter(client, character)
    local nombre = client:Nick()
    local dinero = character:GetMoney()
    local cur = ix.currency.Get(dinero)
    client:Notify("Buenos dias, " .. nombre .. " tienes " .. cur, client)
end