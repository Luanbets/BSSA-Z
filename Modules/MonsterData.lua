local MonsterData = {}

-- ==============================================================================
-- 1. CẤU HÌNH THỜI GIAN HỒI SINH (Cooldowns)
-- ==============================================================================
local MobCooldowns = {
    ["Ladybug"]      = 300,    -- 5 Phút
    ["Rhino Beetle"] = 300,    -- 5 Phút
    ["Spider"]       = 1800,   -- 30 Phút
    ["Scorpion"]     = 1800,   -- 30 Phút
    ["Mantis"]       = 1800,   -- 30 Phút
    ["Werewolf"]     = 3600,   -- 1 Tiếng
    ["Default"]      = 300
}

-- ==============================================================================
-- 2. DANH SÁCH QUÁI VẬT (RAW LIST)
-- ==============================================================================
-- Chỉ cần khai báo tên và cánh đồng. 
-- Mọi thông tin tọa độ sẽ lấy từ FieldData để đảm bảo đồng nhất.
local RawMobList = {
    -- [ZONE 0]
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
-- 3. HÀM TÍNH TOÁN (LOGIC MỚI KHỚP VỚI FIELD DATA)
-- ==============================================================================

-- Hàm tính bán kính dựa trên Size của cánh đồng (FieldData mới dùng Vector3 Size)
local function CalculateRadiusFromSize(sizeVec)
    -- Lấy kích thước lớn nhất giữa chiều dài và chiều rộng chia đôi
    -- Ví dụ: Size (100, 1, 100) -> Radius ~ 50
    if not sizeVec then return 60 end -- Mặc định nếu lỗi
    return math.max(sizeVec.X, sizeVec.Z) / 2 + 5 -- Cộng thêm 5 studs dư ra cho chắc
end

-- Hàm GetActiveMobs: Tự động ghép nối MonsterData + FieldData
-- Tham số FieldModule: Là cái file FieldData mới của bạn
-- Tham số currentBees: Số ong hiện tại
function MonsterData.GetActiveMobs(FieldModule, currentBees)
    local activeList = {}
    
    -- Kiểm tra xem FieldModule có đúng chuẩn không
    if not FieldModule or not FieldModule.Fields then 
        warn("MonsterData: FieldModule không hợp lệ!")
        return {} 
    end

    for _, mob in ipairs(RawMobList) do
        -- Lấy data cánh đồng từ FieldModule mới (Dùng key tên cánh đồng)
        local fieldInfo = FieldModule.Fields[mob.Field]
        
        if fieldInfo then
            -- 1. Check số ong (ReqBees lấy từ FieldData mới)
            local req = fieldInfo.ReqBees or 0
            
            if currentBees >= req then
                -- 2. Tính toán vị trí & bán kính tự động
                local center = fieldInfo.Pos + Vector3.new(0, 5, 0) -- Pos là mặt đất, +5 để lơ lửng
                local radius = CalculateRadiusFromSize(fieldInfo.Size)
                local time = MobCooldowns[mob.Type] or MobCooldowns["Default"]
                
                -- 3. Đóng gói dữ liệu trả về cho Bot Farm
                table.insert(activeList, {
                    Name = mob.Name,      -- Tên quái
                    Type = mob.Type,      -- Loại
                    Field = mob.Field,    -- Cánh đồng
                    Time = time,          -- Thời gian hồi
                    
                    Center = center,      -- Vị trí đứng farm (Lấy từ Field.Pos)
                    Radius = radius,      -- Phạm vi loot (Tính từ Field.Size)
                    ReqBees = req         -- Số ong yêu cầu
                })
            end
        else
            -- warn("Không tìm thấy data cánh đồng: " .. tostring(mob.Field))
        end
    end
    
    return activeList
end

return MonsterData
