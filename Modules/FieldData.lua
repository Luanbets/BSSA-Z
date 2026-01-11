local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local lp = Players.LocalPlayer

-- =========================================================
-- 1. HÀM ĐẾM SỐ ONG (CHẠY NGẦM - KHÔNG PRINT)
-- =========================================================
local function getRealBeeCount()
    local honeycombs = Workspace:FindFirstChild("Honeycombs")
    if not honeycombs then return 0 end

    -- A. Tìm Hive của mình
    local myHive = nil
    for _, hive in pairs(honeycombs:GetChildren()) do
        if hive:FindFirstChild("Owner") and hive.Owner.Value == lp then
            myHive = hive
            break
        end
    end

    -- B. Đếm slot trong Cells
    if myHive then
        local cellsFolder = myHive:FindFirstChild("Cells")
        if cellsFolder then
            local beeCount = 0
            for _, cell in pairs(cellsFolder:GetChildren()) do
                if cell:IsA("Model") and string.sub(cell.Name, 1, 1) == "C" then
                    local cellType = cell:FindFirstChild("CellType")
                    if cellType then
                        if cellType.Value ~= "Empty" and cellType.Value ~= 0 then
                            beeCount = beeCount + 1
                        end
                    else
                        beeCount = beeCount + 1 -- Fallback
                    end
                end
            end
            return beeCount
        end
    end
    
    return 0
end

-- =========================================================
-- 2. DỮ LIỆU FIELD DATA (DATA CỐ ĐỊNH)
-- =========================================================
local FieldData = {
    -- [0 Bee Zone]
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
    ["Stump Field"]       = {ID = 12519, Pos = Vector3.new(110, 5, 113), Color = "Mixed", ReqBees = 10},
    ["Pineapple Patch"]   = {ID = 11906, Pos = Vector3.new(131, 5, 91),  Color = "White", ReqBees = 10},

    -- [15 Bee Zone]
    ["Rose Field"]        = {ID = 10198, Pos = Vector3.new(123, 5, 83),  Color = "Red",   ReqBees = 15},
    ["Pumpkin Patch"]     = {ID = 9289,  Pos = Vector3.new(135, 5, 69),  Color = "White", ReqBees = 15},
    ["Cactus Field"]      = {ID = 9289,  Pos = Vector3.new(135, 5, 69),  Color = "Mixed", ReqBees = 15},
    ["Pine Tree Forest"]  = {ID = 11010, Pos = Vector3.new(91, 5, 122),  Color = "Blue",  ReqBees = 15},

    -- [25 Bee Zone]
    ["Mountain Top Field"]= {ID = 10830, Pos = Vector3.new(98, 5, 111),  Color = "Mixed", ReqBees = 25},

    -- [35 Bee Zone]
    ["Coconut Field"]     = {ID = 10146, Pos = Vector3.new(120, 5, 84),  Color = "White", ReqBees = 35},
    ["Pepper Patch"]      = {ID = 9108,  Pos = Vector3.new(82, 5, 111),  Color = "Red",   ReqBees = 35},
}

-- =========================================================
-- 3. CẤU HÌNH MATERIAL MAP (LOGIC CHỌN)
-- =========================================================
local MaterialMap = {
    ["Sunflower Seed"] = {"Sunflower Field"},
    ["Pineapple"]      = {"Pineapple Patch"},
    ["Blueberry"]      = {"Blue Flower Field", "Bamboo Field", "Pine Tree Forest"},
    ["Strawberry"]     = {"Mushroom Field", "Strawberry Field"},
    ["Honey"]          = {"Sunflower Field", "Spider Field", "Pineapple Patch", "Cactus Field", "Pepper Patch"}
}

-- =========================================================
-- 4. HÀM TRẢ VỀ CÁNH ĐỒNG TỐT NHẤT (RETURN ONLY)
-- =========================================================
-- Cách dùng: local fieldName = GetBestFieldForMaterial("Honey")
-- Nếu không tìm thấy hoặc lỗi, nó sẽ trả về nil

function GetBestFieldForMaterial(targetName)
    local playerBees = getRealBeeCount() -- Tự động lấy số ong thật (Silent)
    local possibleFields = MaterialMap[targetName]
    
    if not possibleFields then return nil end

    local bestField = nil
    local highestReq = -1 

    for _, fieldName in pairs(possibleFields) do
        local data = FieldData[fieldName]
        
        -- So sánh: Nếu có data và đủ ong
        if data and playerBees >= data.ReqBees then
            if data.ReqBees > highestReq then
                highestReq = data.ReqBees
                bestField = fieldName
            end
        end
    end
    
    return bestField -- Trả về tên cánh đồng (String) để UI sử dụng
end
