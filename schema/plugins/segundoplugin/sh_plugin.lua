local PLUGIN = PLUGIN or {}

PLUGIN.name = "Un comando para agregar un item al inventario"
PLUGIN.author = "Max"
PLUGIN.description = "Agrega un comando nuevo, hecho por mi, para agregar un item especifico al inventario del jugador"

function PLUGIN:InitializedPlugins()
    print("[SEGUNDO PLUGIN] Plugin cargado correctamente :p")
end

function PLUGIN:PlayerLoadedCharacter(client, character)
    local inv = client:GetCharacter():GetInventory()
    inv:Add("gmod_camera", 1)
    client:Notify("Se te ha regalado una camara", client)
end

ix.command.Add("do", {
    description = "Comando para rolear tu entorno",
    adminOnly = false,
    arguments = {
        ix.type.text
    },
    OnRun = function(self, client, text)
        local nombre = client:Nick()
        local msg = "[DO - " .. nombre .. "]: ".. text
        ix.chat.Send(client, "it", msg)
    end
})