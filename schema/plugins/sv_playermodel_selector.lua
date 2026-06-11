-- Servidor: selector persistente de playermodel inicial
if SERVER then
    util.AddNetworkString("TLOUModelSelector_Open")
    util.AddNetworkString("TLOUModelSelector_Select")

    local MODEL_PDATA_KEY = "tlou_selected_playermodel"

    local function ApplySavedPlayermodel(ply)
        if not IsValid(ply) or not ply:IsPlayer() then return end

        local model = ply:GetPData(MODEL_PDATA_KEY, "")
        if model == "" or not util.IsValidModel(model) then return end

        ply:SetModel(model)

        if ply.GetCharacter then
            local char = ply:GetCharacter()
            if char then
                char:SetModel(model)
            end
        end

        ply:SetupHands()
    end

    local function OpenSelectorIfNew(ply)
        if not IsValid(ply) or not ply:IsPlayer() then return end
        if ply:GetPData(MODEL_PDATA_KEY, "") ~= "" then return end

        net.Start("TLOUModelSelector_Open")
        net.Send(ply)
    end

    hook.Add("PlayerInitialSpawn", "TLOUModelSelector_OpenForNewPlayers", function(ply)
        timer.Simple(4, function()
            OpenSelectorIfNew(ply)
        end)
    end)

    hook.Add("PlayerSpawn", "TLOUModelSelector_ApplyOnSpawn", function(ply)
        timer.Simple(0, function()
            ApplySavedPlayermodel(ply)
        end)
    end)

    hook.Add("PlayerLoadedCharacter", "TLOUModelSelector_ApplyOnCharacter", function(ply)
        timer.Simple(0.25, function()
            ApplySavedPlayermodel(ply)
            OpenSelectorIfNew(ply)
        end)
    end)

    net.Receive("TLOUModelSelector_Select", function(len, ply)
        if not IsValid(ply) or not ply:IsPlayer() then return end

        if ply:GetPData(MODEL_PDATA_KEY, "") ~= "" then
            ply:ChatPrint("Ya elegiste tu playermodel inicial.")
            ApplySavedPlayermodel(ply)
            return
        end

        local model = net.ReadString()
        if model == "" or not util.IsValidModel(model) then
            ply:ChatPrint("Modelo no valido.")
            OpenSelectorIfNew(ply)
            return
        end

        ply:SetPData(MODEL_PDATA_KEY, model)
        ApplySavedPlayermodel(ply)
        ply:ChatPrint("Playermodel guardado. Se cargara automaticamente cuando vuelvas al servidor.")
    end)
end
