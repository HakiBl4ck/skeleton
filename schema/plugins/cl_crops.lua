local function drawCropHint()
    local trace = LocalPlayer():GetEyeTraceNoCursor()
    if (not IsValid(trace.Entity) or not trace.Entity.ixCrop) then return end

    local crop = trace.Entity.ixCrop
    local text = crop.name or "Cultivo"
    local water = math.floor(crop.water or 0)
    local growth = math.floor(crop.growth or 0)
    local status = crop.ready and "Listo para cosechar" or "Creciendo"

    draw.SimpleTextOutlined(
        text .. " | " .. status .. " | Agua: " .. water .. "% | Crecimiento: " .. growth .. "%",
        "DermaDefaultBold",
        ScrW() / 2,
        ScrH() * 0.8,
        Color(230, 220, 200),
        TEXT_ALIGN_CENTER,
        TEXT_ALIGN_CENTER,
        1,
        Color(0, 0, 0, 220)
    )
end

hook.Add("HUDPaint", "ixCropsHUDHint", drawCropHint)
