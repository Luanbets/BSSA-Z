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
-- 2. DỮ LIỆU FIELD DATA (ĐÃ CẬP NHẬT CHÍNH XÁC + SIZE)
-- =========================================================
-- Lưu ý: Position đã được nâng nhẹ trục Y để nhân vật đứng trên mặt đất
local FieldData = {
    -- [0 Bee Zone]
    ["Sunflower Field"]   = {ID = 10614, Pos = Vector3.new(-208.95, 4, 176.58), Size = Vector3.new(80.71, 1, 131.51), Color = "White", ReqBees = 0},
    ["Dandelion Field"]   = {ID = 10415, Pos = Vector3.new(-29.70, 4, 221.57),  Size = Vector3.new(143.65, 1, 72.50), Color = "White", ReqBees = 0},
    ["Blue Flower Field"] = {ID = 11613, Pos = Vector3.new(146.87, 4, 99.31),   Size = Vector3.new(171.63, 2, 67.67), Color = "Blue",  ReqBees = 0},
    ["Mushroom Field"]    = {ID = 11758, Pos = Vector3.new(-89.70, 4, 111.73),  Size = Vector3.new(128.50, 2, 91.50), Color = "Red",   ReqBees = 0},
    ["Clover Field"]      = {ID = 12646, Pos = Vector3.new(157.55, 34, 196.35), Size = Vector3.new(106.49, 2, 118.75),Color = "Mixed", ReqBees = 0},

    -- [5 Bee Zone]
    ["Bamboo Field"]      = {ID = 11702, Pos = Vector3.new(132.96, 20, -25.60), Size = Vector3.new(156.45, 2, 74.80), Color = "Blue",  ReqBees = 5},
    ["Strawberry Field"]  = {ID = 9529,  Pos = Vector3.new(-178.17, 20, -9.85), Size = Vector3.new(89.65, 2, 106.29), Color = "Red",   ReqBees = 5},
    ["Spider Field"]      = {ID = 11907, Pos = Vector3.new(-43.47, 20, -13.59), Size = Vector3.new(112.31, 2, 106.02),Color = "White", ReqBees = 5},

    -- [10 Bee Zone]
    ["Stump Field"]       = {ID = 12519, Pos = Vector3.new(424.48, 96, -174.81),Size = Vector3.new(110.48, 3, 113.31),Color = "Mixed", ReqBees = 10},
    ["Pineapple Patch"]   = {ID = 11906, Pos = Vector3.new(256.50, 68, -207.48),Size = Vector3.new(130.67, 2, 91.11), Color = "White", ReqBees = 10},

    -- [15 Bee Zone]
    ["Rose Field"]        = {ID = 10198, Pos = Vector3.new(-327.46, 20, 129.50),Size = Vector3.new(123.07, 1, 82.86), Color = "Red",   ReqBees = 15},
    ["Pumpkin Patch"]     = {ID = 9289,  Pos = Vector3.new(-188.50, 68, -183.85),Size = Vector3.new(135.00, 1, 68.81), Color = "White", ReqBees = 15},
    ["Cactus Field"]      = {ID = 9289,  Pos = Vector3.new(-188.50, 68, -101.60),Size = Vector3.new(135.00, 1, 68.81), Color = "Mixed", ReqBees = 15},
    ["Pine Tree Forest"]  = {ID = 11010, Pos = Vector3.new(-328.67, 68, -187.35),Size = Vector3.new(90.62, 1, 121.50), Color = "Blue",  ReqBees = 15},

    -- [25 Bee Zone]
    ["Mountain Top Field"]= {ID = 10830, Pos = Vector3.new(77.68, 176, -165.43),Size = Vector3.new(97.73, 1, 110.82), Color = "Mixed", ReqBees = 25},

    -- [35 Bee Zone]
    ["Coconut Field"]     = {ID = 10146, Pos = Vector3.new(-254.48, 71, 469.46),Size = Vector3.new(120.31, 1, 84.33), Color = "White", ReqBees = 35},
    ["Pepper Patch"]      = {ID = 9108,  Pos = Vector3.new(-488.76, 123, 535.68),Size = Vector3.new(82.39, 1, 110.55),Color = "Red",   ReqBees = 35},
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
-- 4. HÀM TÌM CÁNH ĐỒNG TỐT NHẤT (RETURN INFO)
-- =========================================================
function GetBestFieldForMaterial(targetName)
    local playerBees = getRealBeeCount() -- Tự động lấy số ong thật
    local possibleFields = MaterialMap[targetName]
    
    if not possibleFields then 
        warn("Không tìm thấy dữ liệu cho vật phẩm: " .. tostring(targetName))
        return nil 
    end

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
    
    -- Trả về cả Tên và Data (Pos, Size) để dùng luôn
    if bestField then
        return bestField, FieldData[bestField]
    else
        return nil
    end
end

-- =========================================================
-- VÍ DỤ CÁCH DÙNG (TEST)
-- =========================================================

-- Giả sử bạn muốn farm Honey
local targetMaterial = "Honey"
local fieldName, fieldInfo = GetBestFieldForMaterial(targetMaterial)

if fieldName and fieldInfo then
    print("-------------------------------------------------")
    print("Đang đi tới cánh đồng tốt nhất cho: " .. targetMaterial)
    print("Tên đồng: " .. fieldName)
    print("Toạ độ tâm (Position): " .. tostring(fieldInfo.Pos))
    print("Kích thước vùng (Size): " .. tostring(fieldInfo.Size))
    print("-------------------------------------------------")
    
    -- Code Teleport đơn giản (Minh hoạ)
    -- lp.Character.HumanoidRootPart.CFrame = CFrame.new(fieldInfo.Pos)
else
    print("Bạn chưa đủ ong để farm vật phẩm này hoặc tên sai!")
end
