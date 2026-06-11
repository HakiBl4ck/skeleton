Instrucciones de uso - Plugins TLOU

Resumen:
- `tlou_crear_personaje`: Abre la interfaz de creación de personaje (Helix integrado).
- `tlou_admin_panel`: Abre el panel administrativo (solo facción `Admins`).
- `tlou_faction_manager`: Abre el gestor de facciones dinámico (solo `Admins`).
- `/tienda`: Abre la tienda. Los `Admins` pueden crear, editar y eliminar ofertas.
- `/dardinero <jugador> <cantidad>`: Da dinero a un jugador para comprar en la tienda (solo `Admins`).
- `/tlou_admin_model <modelo>`: Cambia tu playermodel como admin, usando una ruta tipo `models/player/kleiner.mdl`.
- `/radio <mensaje>`: Envía un mensaje solo a los miembros de tu facción.

Comandos (chat / comando ix):
- En el chat escribe `/tlou_crear_personaje` para abrir el creador de personaje.
- En el chat escribe `/tlou_admin_panel` para abrir el panel administrativo (debes ser `Admins`).
- En el chat escribe `/tlou_faction_manager` para abrir el gestor de facciones (debes ser `Admins`).
- En el chat escribe `/tienda` para comprar objetos o administrar ofertas si eres `Admins`.
- En el chat escribe `/dardinero <jugador> <cantidad>` para darle dinero a un jugador (debes ser `Admins`).
- En el chat escribe `/tlou_admin_model <modelo>` para cambiar tu playermodel como admin.
- En el chat escribe `/radio <mensaje>` para comunicarte solo con los miembros de tu facción.

Asignar la facción `Admins` a un jugador (consola del servidor):
```lua
-- Ejecutar en la consola del servidor (lua_run_sv)
for _,p in ipairs(player.GetAll()) do
    if p:Nick() == "NOMBRE_DEL_JUGADOR" then p:SetTeam(FACTION_ADMINS) end
end
```

Persistencia:
- Las facciones dinámicas se guardan en `data/tlou_factions.json` en el servidor.
- Las ofertas de la tienda se guardan en `data/tlou_shop_items.txt` en el servidor.
- El playermodel elegido por jugadores nuevos se guarda con `SetPData` y se reaplica al reconectar.
- Los datos del personaje (nombre, edad, bio) se guardan con `SetPData` por jugador.

Integración con Helix:
- Al guardar el nombre desde la interfaz de creación de personaje, el plugin intentará actualizar
  el nombre del character activo de Helix (`char:SetName(...)` o `char:SetData("name", ...)`) y llamar a `char:Save()` si está disponible.

Notas y recomendaciones:
- Asegúrate de que la facción `Admins` esté presente en `schema/factions/sh_admins.lua`.
- Los controles en pantalla están en español y buscan un estilo sobrio inspirado en The Last of Us.
- Si necesitas más utilidades (dar items, kick/ban desde panel, sonidos, radio con canales), indícalo y lo implemento.
