local MonsterData = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- [CONFIG] Chỉ map Tên Quái -> Loại -> Cánh Đồng (Không có tọa độ!)
local Mobs = {
    {N="MushroomBush", T="Ladybug", F="Mushroom Field"},
    {N="Rhino Cave 1", T="Rhino Beetle", F="Blue Flower Field"},
    {N="Ladybug Bush", T="Ladybug", F="Clover Field"},
    {N="Rhino Bush",   T="Rhino Beetle", F="Clover Field"},
    {N="Ladybug Bush 2",T="Ladybug", F="Strawberry Field"},
    {N="Ladybug Bush 3",T="Ladybug", F="Strawberry Field"},
    {N="Rhino Cave 3", T="Rhino Beetle", F="Bamboo Field"},
    {N="Rhino Cave 2", T="Rhino Beetle", F="Bamboo Field"},
    {N="Spider Cave",  T="Spider", F="Spider Field"},
    {N="PineappleBeetle", T="Rhino Beetle", F="Pineapple Patch"},
    {N="PineappleMantis1",T="Mantis", F="Pineapple Patch"},
    {N="ForestMantis1",   T="Mantis", F="Pine Tree Forest"},
    {N="ForestMantis2",   T="Mantis", F="Pine Tree Forest"},
    {N="RoseBush",        T="Scorpion", F="Rose Field"},
    {N="RoseBush2",       T="Scorpion", F="Rose Field"},
    {N="WerewolfCave",    T="Werewolf", F="Cactus Field"}
}

local Cooldowns = { ["Ladybug"]=300, ["Rhino Beetle"]=300, ["Spider"]=1800, ["Scorpion"]=1800, ["Mantis"]=1800, ["Werewolf"]=3600, ["Default"]=300 }

-- [HELPER] Check Server Time
local function Alive(n, t)
    local s, r = pcall(function() return ReplicatedStorage.Events.RetrievePlayerStats:InvokeServer() end)
    local last = (s and r and r.MonsterTimes and r.MonsterTimes[n])
    return not last or (last + t < os.time())
end

-- [HELPER] Auto Loot (Gọi Utils để chạy nhanh)
local function Loot(pos, rad, Utils)
    local endT = os.time() + 4
    while os.time() < endT do
        if Utils.SyncWalkSpeed then Utils.SyncWalkSpeed() end -- [CALL UTILS]
        for _,v in pairs(Workspace.Collectibles:GetChildren()) do
            if v.Transparency < 1 and (v.Position - pos).Magnitude <= rad then
                LocalPlayer.Character.Humanoid:MoveTo(v.Position)
                task.wait(0.15)
            end
        end
        task.wait(0.1)
    end
end

-- [MAIN 1] Lấy danh sách quái (GỌI FieldData ĐỂ LẤY TỌA ĐỘ)
function MonsterData.GetTargets(FieldModule, bees)
    local res = {}
    for _, m in ipairs(Mobs) do
        -- [GỌI FieldData] Lấy thông tin cánh đồng từ file FieldData.lua
        local fInfo = FieldModule.Fields[m.F]
        
        -- Chỉ xử lý nếu có Data cánh đồng và Đủ Ong
        if fInfo and bees >= fInfo.ReqBees then
            local time = Cooldowns[m.T] or Cooldowns["Default"]
            if Alive(m.N, time) then
                table.insert(res, {
                    Name = m.N,
                    -- [KHÔNG HARDCODE] Tính toán động từ dữ liệu FieldData
                    Pos = fInfo.Pos + Vector3.new(0, 5, 0), 
                    Rad = (fInfo.Size.X + fInfo.Size.Z)/4 + 10,
                    Time = time
                })
            end
        end
    end
    return res
end

-- [MAIN 2] Xử lý giết (GỌI Utils ĐỂ DI CHUYỂN)
function MonsterData.Kill(mob, Tools, Log)
    local Utils = Tools.Utils
    if not Alive(mob.Name, mob.Time) then return false end

    if Log then Log("Moving: " .. mob.Name) end
    if Utils.Tween then Utils.Tween(CFrame.new(mob.Pos)) end -- [CALL UTILS]
    
    local start = os.time()
    if Log then Log("Kill: " .. mob.Name) end
    
    while Alive(mob.Name, mob.Time) do
        if os.time()-start > 45 then return false end
        
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("Humanoid") then break end
        
        -- [CALL UTILS] Luôn đồng bộ tốc độ
        if Utils.SyncWalkSpeed then Utils.SyncWalkSpeed() end 
        
        local hrp = char.HumanoidRootPart
        if (hrp.Position - mob.Pos).Magnitude > 5 then
            char.Humanoid:MoveTo(mob.Pos)
        end
        
        if char.Humanoid.FloorMaterial ~= Enum.Material.Air then char.Humanoid.Jump = true end
        task.wait()
    end
    
    if Log then Log("Loot: " .. mob.Name) end
    Loot(mob.Pos, mob.Rad, Utils)
    return true
end

return MonsterData
