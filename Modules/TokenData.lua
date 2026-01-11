local module = {}

-- =========================================================
-- DATA TOKEN & ITEMS
-- Cấu trúc: [TextureID] = {Name = "Tên", Priority = Mức_Ưu_Tiên}
-- Priority càng cao càng được ưu tiên nhặt trước.
-- =========================================================

module.Tokens = {
    -- =====================================================
    -- 1. ITEMS (ƯU TIÊN CAO - Priority 100)
    -- =====================================================
    ["rbxassetid://1471850677"] = {Name = "Diamond Egg",    Priority = 100},
    ["rbxassetid://2319943273"] = {Name = "Star Jelly",     Priority = 100},
    ["rbxassetid://2584584968"] = {Name = "Oil",            Priority = 100},
    ["rbxassetid://1674871631"] = {Name = "Ticket",         Priority = 100},
    ["rbxassetid://1471882621"] = {Name = "Royal Jelly",    Priority = 100},
    ["rbxassetid://1952796032"] = {Name = "Pineapple",      Priority = 100}, -- Đã sửa chính tả Pinapple -> Pineapple
    ["rbxassetid://2028453802"] = {Name = "Blueberry",      Priority = 100},
    ["rbxassetid://1952682401"] = {Name = "Sunflower Seed", Priority = 100},
    ["rbxassetid://2542899798"] = {Name = "Glitter",        Priority = 100},
    ["rbxassetid://1952740625"] = {Name = "Strawberry",     Priority = 100},
    ["rbxassetid://1471849394"] = {Name = "Gold Egg",       Priority = 100},

    -- =====================================================
    -- 2. BEE TOKENS (ƯU TIÊN PHỤ - Priority 10)
    -- =====================================================
    ["rbxassetid://1442859163"] = {Name = "Red Boost",      Priority = 10},
    ["rbxassetid://1442725244"] = {Name = "Buz",            Priority = 10},
    ["rbxassetid://177997841"]  = {Name = "Bomb Token",     Priority = 10},
    ["rbxassetid://2499514197"] = {Name = "Honey Mark",     Priority = 10},
    ["rbxassetid://65867881"]   = {Name = "Haste",          Priority = 10},
    ["rbxassetid://253828517"]  = {Name = "Melody",         Priority = 10},
    ["rbxassetid://1472256444"] = {Name = "Baby Love",      Priority = 10},
    ["rbxassetid://1442863423"] = {Name = "Blue Boost",     Priority = 10},
    ["rbxassetid://1629547638"] = {Name = "Token Link",     Priority = 10},
    ["rbxassetid://2499540966"] = {Name = "Pollen Mark",    Priority = 10},
    ["rbxassetid://1442764904"] = {Name = "Buzz Bomb+",     Priority = 10},
    ["rbxassetid://2000457501"] = {Name = "Star",           Priority = 10},
    ["rbxassetid://1629649299"] = {Name = "Focus",          Priority = 10},
}

-- Hàm hỗ trợ kiểm tra nhanh (Optional)
function module.GetTokenInfo(textureId)
    return module.Tokens[textureId]
end

return module
