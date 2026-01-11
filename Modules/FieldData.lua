-- Cấu hình dữ liệu các cánh đồng
local FieldData = {
    -- [0 Bee Zone] - Starter
    ["Sunflower Field"]   = {ID = 10614, Pos = Vector3.new(81, 5, 132),  Color = "White", ReqBees = 0},
    ["Dandelion Field"]   = {ID = 10415, Pos = Vector3.new(144, 5, 72),  Color = "White", ReqBees = 0},
    ["Blue Flower Field"] = {ID = 11613, Pos = Vector3.new(172, 5, 68),  Color = "Blue",  ReqBees = 0},
    ["Mushroom Field"]    = {ID = 11758, Pos = Vector3.new(128, 5, 92),  Color = "Red",   ReqBees = 0},
    ["Clover Field"]      = {ID = 12646, Pos = Vector3.new(106, 5, 119), Color = "Mixed", ReqBees = 0},

    -- [5 Bee Zone]
    ["Bamboo Field"]      = {ID = 11702, Pos = Vector3.new(156, 5, 75),  Color = "Blue",  ReqBees = 5},
    ["Strawberry Field"]  = {ID = 9529,  Pos = Vector3.new(90, 5, 106),  Color = "Red",   ReqBees = 5},
    ["Spider Field"]      = {ID = 11907, Pos = Vector3.new(112, 5, 106), Color = "White", ReqBees = 5},

    -- [10 Bee Zone]
    ["Stump Field"]       = {ID = 12519, Pos = Vector3.new(110, 5, 113), Color = "Mixed",  ReqBees = 10},
    ["Pineapple Patch"]   = {ID = 11906, Pos = Vector3.new(131, 5, 91),  Color = "White", ReqBees = 10},

    -- [15 Bee Zone]
    ["Rose Field"]        = {ID = 10198, Pos = Vector3.new(123, 5, 83),  Color = "Red",   ReqBees = 15},
    ["Pumpkin Patch"]     = {ID = 9289,  Pos = Vector3.new(135, 5, 69),  Color = "White", ReqBees = 15},
    ["Cactus Field"]      = {ID = 9289,  Pos = Vector3.new(135, 5, 69),  Color = "Mixed", ReqBees = 15}, -- Cactus là Mixed (Xanh/Đỏ)
    ["Pine Tree Forest"]  = {ID = 11010, Pos = Vector3.new(91, 5, 122),  Color = "Blue",  ReqBees = 15},

    -- [25 Bee Zone]
    ["Mountain Top Field"]= {ID = 10830, Pos = Vector3.new(98, 5, 111),  Color = "Mixed", ReqBees = 25}, -- ĐÃ SỬA: Mixed

    -- [35 Bee Zone]
    ["Coconut Field"]     = {ID = 10146, Pos = Vector3.new(120, 5, 84),  Color = "White", ReqBees = 35},
    ["Pepper Patch"]      = {ID = 9108,  Pos = Vector3.new(82, 5, 111),  Color = "Red",   ReqBees = 35},
}

-- Hàm logic chọn Field
function GetBestFieldForQuest(questColor, playerBees)
    local bestField = nil
    local highestReq = -1 
    
    for name, data in pairs(FieldData) do
        -- Chỉ chọn đúng màu yêu cầu (Bỏ qua Mixed nếu đang cần màu cụ thể)
        if data.Color == questColor then
            if playerBees >= data.ReqBees then
                if data.ReqBees > highestReq then
                    highestReq = data.ReqBees
                    bestField = name
                end
            end
        end
    end
    
    return bestField
end
