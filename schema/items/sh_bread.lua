ITEM.name = "Bread"
ITEM.model = Model("models/bread01.mdl")
ITEM.description = "A simple loaf of bread."
ITEM.category = "Consumables"
ITEM.width = 1
ITEM.height = 1
ITEM.noBusiness = true

ITEM.functions.Eat = {
    OnRun = function(item)
        local client = item.player
        client:SetHealth(math.min(client:Health() + 8, client:GetMaxHealth()))
        return true
    end
}
