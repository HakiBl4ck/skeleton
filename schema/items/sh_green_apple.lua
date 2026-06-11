ITEM.name = "Green Apple"
ITEM.model = Model("models/apple01.mdl")
ITEM.description = "A fresh green apple."
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
