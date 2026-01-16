local MonsterData = {}

-- ==============================================================================
-- 1. CẤU HÌNH THỜI GIAN HỒI SINH (Cooldowns)
-- ==============================================================================
-- Đơn vị: Giây
local MobCooldowns = {
    ["Ladybug"]      = 300,
    ["Rhino Beetle"] = 300,
    ["Spider"]       = 1800,
    ["Scorpion"]     = 1800,
    ["Mantis"]       = 1800,
    ["Werewolf"]     = 3600,
    
    ["Default"]      = 300    -- Mặc định
}

-- ==============================================================================
-- 2. DỮ LIỆU CÁNH ĐỒNG (VỊ TRÍ ĐỨNG FARM)
-- ==============================================================================
-- Center: Vị trí nhân vật sẽ đứng (Giữa cánh đồng)
-- Radius: Bán kính quét đồ (Token) tính từ Center
MonsterData.FieldSettings = {
    -- Khu vực lv 0 - 5
    ["Mushroom Field"]    = {Center = Vector3.new(-94, 0, 114),   Radius = 60},
    ["Blue Flower Field"] = {Center = Vector3.new(115, 4, 100),   Radius = 60},
    ["Clover Field"]      = {Center = Vector3.new(174, 34, 189),  Radius = 75}, 
    ["Strawberry Field"]  = {Center = Vector3.new(-180, 20, -15), Radius = 70},
    ["Spider Field"]      = {Center = Vector3.new(-40, 20, -10),  Radius = 55},
    ["Bamboo Field"]      = {Center = Vector3.new(150, 20, -25),  Radius = 70},
    
    -- Khu vực lv 10+
    ["Pineapple Patch"]   = {Center = Vector3.new(262, 68, -201), Radius = 60},
    ["Pine Tree Forest"]  = {Center = Vector3.new(-318, 68, -150),Radius = 60},
    ["Rose Field"]        = {Center = Vector3.new(-322, 20, 124), Radius = 60},
    ["Cactus Field"]      = {Center = Vector3.new(-194, 68, -107),Radius = 60},
    ["Pumpkin Patch"]     = {Center = Vector3.new(-194, 68, -182),Radius = 60}
}

-- ==============================================================================
-- 3. DANH SÁCH QUÁI VẬT (MAPPING)
-- ==============================================================================
-- Name: Tên định danh trong game (Folder Monsters)
-- Type: Loại quái (để lấy thời gian hồi sinh)
-- Field: Tên cánh đồng (để lấy vị trí đứng)
local RawMobList = {
    -- [LEVEL 1-3]
    {Name = "MushroomBush",     Type = "Ladybug",      Field = "Mushroom Field"},
    {Name = "Rhino Cave 1",     Type = "Rhino Beetle", Field = "Blue Flower Field"},
    {Name = "Ladybug Bush",     Type = "Ladybug",      Field = "Clover Field"},
    {Name = "Rhino Bush",       Type = "Rhino Beetle", Field = "Clover Field"},
    {Name = "Ladybug Bush 2",   Type = "Ladybug",      Field = "Strawberry Field"},
    {Name = "Ladybug Bush 3",   Type = "Ladybug",      Field = "Strawberry Field"},
    {Name = "Rhino Cave 3",     Type = "Rhino Beetle", Field = "Bamboo Field"},
    {Name = "Rhino Cave 2",     Type = "Rhino Beetle", Field = "Bamboo Field"},
    {Name = "Spider Cave",      Type = "Spider",       Field = "Spider Field"},

    -- [LEVEL 4+]
    {Name = "PineappleBeetle",  Type = "Rhino Beetle", Field = "Pineapple Patch"},
    {Name = "PineappleMantis1", Type = "Mantis",       Field = "Pineapple Patch"},
    {Name = "ForestMantis1",    Type = "Mantis",       Field = "Pine Tree Forest"},
    {Name = "ForestMantis2",    Type = "Mantis",       Field = "Pine Tree Forest"},
    {Name = "RoseBush",         Type = "Scorpion",     Field = "Rose Field"},
    {Name = "RoseBush2",        Type = "Scorpion",     Field = "Rose Field"},
    {Name = "WerewolfCave",     Type = "Werewolf",     Field = "Cactus Field"}
}

-- ==============================================================================
-- 4. HÀM XỬ LÝ (Get Data)
-- ==============================================================================
-- Hàm này sẽ được script chính gọi để lấy danh sách đầy đủ
function MonsterData.GetMobList()
    local processedList = {}
    
    for _, mob in pairs(RawMobList) do
        -- Tự động lấy thời gian từ bảng Cooldowns, nếu sai tên thì lấy Default
        local time = MobCooldowns[mob.Type] or MobCooldowns["Default"]
        
        table.insert(processedList, {
            Name = mob.Name,
            Type = mob.Type,
            Field = mob.Field,
            Time = time
        })
    end
    
    return processedList
end

return MonsterData
