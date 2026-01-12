local module = {}

-- Cấu trúc: [TextureID] = {Name = "Tên", Priority = Mức_Ưu_Tiên}
module.Tokens = {
    -- === ITEMS (Priority: 100) - LỤM NGAY ===
    ["rbxassetid://1471850677"] = {Priority = 100, Name = "Diamond Egg"},
    ["rbxassetid://2319943273"] = {Priority = 100, Name = "Star Jelly"},
    ["rbxassetid://2584584968"] = {Priority = 100, Name = "Oil"},
    ["rbxassetid://1674871631"] = {Priority = 100, Name = "Ticket"},
    ["rbxassetid://1471882621"] = {Priority = 100, Name = "Royal Jelly"},
    ["rbxassetid://1952796032"] = {Priority = 100, Name = "Pineapple"},
    ["rbxassetid://2028453802"] = {Priority = 100, Name = "Blueberry"},
    ["rbxassetid://1952682401"] = {Priority = 100, Name = "Sunflower Seed"},
    ["rbxassetid://2542899798"] = {Priority = 100, Name = "Glitter"},
    ["rbxassetid://1952740625"] = {Priority = 100, Name = "Strawberry"},
    ["rbxassetid://1471849394"] = {Priority = 100, Name = "Gold Egg"},

    -- === TOKEN BUFF (Priority: 10) - LỤM SAU ===
    ["rbxassetid://1442859163"] = {Priority = 10, Name = "Red Boost"},
    ["rbxassetid://1442725244"] = {Priority = 10, Name = "Blue Boost"},
    ["rbxassetid://177997841"]  = {Priority = 10, Name = "Bomb Token"},
    ["rbxassetid://2499514197"] = {Priority = 10, Name = "Honey Mark"},
    ["rbxassetid://65867881"]   = {Priority = 10, Name = "Haste"},
    ["rbxassetid://253828517"]  = {Priority = 10, Name = "Melody"},
    ["rbxassetid://1472256444"] = {Priority = 10, Name = "Baby Love"},
    ["rbxassetid://1442863423"] = {Priority = 10, Name = "Blue Boost"},
    ["rbxassetid://1629547638"] = {Priority = 10, Name = "Token Link"},
    ["rbxassetid://2499540966"] = {Priority = 10, Name = "Pollen Mark"},
    ["rbxassetid://1442764904"] = {Priority = 10, Name = "Buzz Bomb+"},
    ["rbxassetid://2000457501"] = {Priority = 10, Name = "Star"},
    ["rbxassetid://1629649299"] = {Priority = 10, Name = "Focus"},
}

return module
