local MonsterData = {}

-- ==============================================================================
-- 1. CẤU HÌNH THỜI GIAN HỒI SINH (Cooldowns)
-- ==============================================================================
local MobCooldowns = {
    ["Ladybug"]      = 300,
    ["Rhino Beetle"] = 300,
    ["Spider"]       = 1800,
    ["Scorpion"]     = 1800,
    ["Mantis"]       = 1800,
    ["Werewolf"]     = 3600,
    ["Default"]      = 300
}

-- ==============================================================================
-- 2. DANH SÁCH QUÁI VẬT (RAW DATA)
-- ==============================================================================
-- Chỉ cần khai báo: Tên quái, Loại quái, và Cánh đồng nó thuộc về.
-- Script sẽ tự tra cứu FieldData để biết nó ở đâu và cần bao nhiêu ong.
local RawMobList = {
    -- [ZONE 0 - STARTER]
    {Name = "MushroomBush",     Type = "Ladybug",      Field = "Mushroom Field"},
    {Name = "Rhino Cave 1",     Type = "Rhino Beetle", Field = "Blue Flower Field"},
    {Name = "Ladybug Bush",     Type = "Ladybug",      Field = "Clover Field"},
    {Name = "Rhino Bush",       Type = "Rhino Beetle", Field = "Clover Field"},
    
    -- [ZONE 5]
    {Name = "Ladybug Bush 2",   Type = "Ladybug",      Field = "Strawberry Field"},
    {Name = "Ladybug Bush 3",   Type = "Ladybug",      Field = "Strawberry Field"},
    {Name = "Rhino Cave 3",     Type = "Rhino Beetle", Field = "Bamboo Field"},
    {Name = "Rhino Cave 2",     Type = "Rhino Beetle", Field = "Bamboo Field"},
    {Name = "Spider Cave",      Type = "Spider",       Field = "Spider Field"},

    -- [ZONE 10]
    {Name = "PineappleBeetle",  Type = "Rhino Beetle", Field = "Pineapple Patch"},
    {Name = "PineappleMantis1", Type = "Mantis",       Field = "Pineapple Patch"},
    
    -- [ZONE 15]
    {Name = "ForestMantis1",    Type = "Mantis",       Field = "Pine Tree Forest"},
    {Name = "ForestMantis2",    Type = "Mantis",       Field = "Pine Tree Forest"},
    {Name = "RoseBush",         Type = "Scorpion",     Field = "Rose Field"},
    {Name = "RoseBush2",        Type = "Scorpion",     Field = "Rose Field"},
    {Name = "WerewolfCave",     Type = "Werewolf",     Field = "Cactus Field"}
}

-- ==============================================================================
-- 3. HÀM XỬ LÝ THÔNG MINH (Dynamic Check)
-- ==============================================================================

-- Hàm tính bán kính ước lượng dựa trên kích thước cánh đồng (Để thay thế số thủ công)
local function CalculateRadius(sizeVector)
    -- Lấy cạnh nhỏ nhất chia 2 hoặc lấy trung bình, ở đây lấy trung bình X và Z cho rộng rãi
    return (sizeVector.X + sizeVector.Z) / 4 + 10 -- Cộng thêm chút dư để bao quát
end

-- Hàm lấy danh sách quái KHẢ DỤNG (Chỉ trả về quái ở khu vực vào được)
-- Tham số: 
--   1. FieldModule: Module FieldData đã load
--   2. currentBees: Số ong hiện tại của người chơi
function MonsterData.GetActiveMobs(FieldModule, currentBees)
    local activeList = {}
    
    for _, mob in ipairs(RawMobList) do
        local fieldInfo = FieldModule.Fields[mob.Field]
        
        -- Kiểm tra 1: Cánh đồng có tồn tại trong Data không?
        if fieldInfo then
            -- Kiểm tra 2: Số ong có đủ để vào khu vực này không?
            if currentBees >= fieldInfo.ReqBees then
                
                -- Tự động lấy thông tin từ FieldData đắp vào
                table.insert(activeList, {
                    Name = mob.Name,
                    Type = mob.Type,
                    Field = mob.Field,
                    
                    -- [TỰ ĐỘNG] Lấy vị trí từ FieldData
                    Center = fieldInfo.Pos + Vector3.new(0, 5, 0), -- Cộng Y để không chui xuống đất
                    
                    -- [TỰ ĐỘNG] Tính bán kính quét quái dựa trên Size cánh đồng
                    Radius = CalculateRadius(fieldInfo.Size),
                    
                    -- Thời gian hồi sinh
                    Time = MobCooldowns[mob.Type] or MobCooldowns["Default"],
                    
                    -- Đánh dấu Zone để dễ debug nếu cần
                    ReqBees = fieldInfo.ReqBees 
                })
            end
        end
    end
    
    return activeList
end

return MonsterData
