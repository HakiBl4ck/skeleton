ITEM.name = "Red Apple"
ITEM.model = Model("models/jmod/props/plants/japple.mdl")
ITEM.description = "A sweet red apple."
ITEM.category = "Consumables"
ITEM.width = 1
ITEM.height = 1
ITEM.noBusiness = true

ITEM.functions.Eat = {
    OnRun = function(item)
        local client = item.player
        client:SetHealth(math.min(client:Health() + 5, client:GetMaxHealth()))
        return true
    end
}
