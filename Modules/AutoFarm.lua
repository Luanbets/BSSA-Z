local module = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local isFarming = false

-- Hàm hỗ trợ tìm tổ của mình
local function GetMyHivePosition()
    local honeycombs = workspace:FindFirstChild("Honeycombs") or workspace:FindFirstChild("Hives")
    if honeycombs then
        for _, hive in pairs(honeycombs:GetChildren()) do
            if hive:FindFirstChild("Owner") and hive.Owner.Value == LocalPlayer then
                if hive:FindFirstChild("SpawnPos") then
                    return hive.SpawnPos.Value.Position
                end
            end
        end
    end
    -- Nếu không thấy tổ thì bay về Spawn để an toàn
    return Vector3.new(0, 5, 0)
end

function module.StopFarm()
    isFarming = false
end

function module.StartFarm(fieldName, Tools)
    if isFarming then return end 
    isFarming = true
    
    -- Lấy thông tin Field
    local FieldInfo = nil
    if Tools.Field and Tools.Field.Fields then
        FieldInfo = Tools.Field.Fields[fieldName] 
    end

    local Utils = Tools.Utils
    local Log = Tools.Log
    
    if not FieldInfo then 
        Log("❌ AutoFarm: Unknown Field " .. tostring(fieldName), Color3.fromRGB(255, 0, 0))
        isFarming = false 
        return 
    end

    Log("🚜 Farming at " .. fieldName, Color3.fromRGB(0, 255, 255))
    Utils.Tween(CFrame.new(FieldInfo.Pos + Vector3.new(0, 5, 0)))

    task.spawn(function()
        while isFarming do
            pcall(function() ReplicatedStorage.Events.ToolCollect:FireServer() end)
            
            -- CHECK BALO & CONVERT
            if LocalPlayer:FindFirstChild("CoreStats") then
                local currentPollen = LocalPlayer.CoreStats.Pollen.Value   
                local maxCapacity = LocalPlayer.CoreStats.Capacity.Value   
                
                -- Nếu đầy 90%
                if currentPollen >= (maxCapacity * 0.90) then
                     Log("🎒 Balo đầy ("..math.floor(currentPollen).."). Về tổ...", Color3.fromRGB(255, 170, 0))
                     
                     -- 1. Bay về tổ
                     local hivePos = GetMyHivePosition()
                     Utils.Tween(CFrame.new(hivePos + Vector3.new(0, 5, 0)))
                     task.wait(1) 

                     -- 2. Gửi lệnh làm mật
                     ReplicatedStorage.Events.PlayerHiveCommand:FireServer("ToggleHoneyMaking")
                     
                     -- 3. CHỜ PHẤN HOA VỀ 0 (TUYỆT ĐỐI KHÔNG NHẢY)
                     Log("⏳ Đang convert... (Đứng yên chờ về 0)", Color3.fromRGB(255, 255, 0))
                     
                     while LocalPlayer.CoreStats.Pollen.Value > 0 do
                        -- Code này chặn đứng tại đây, nhân vật sẽ đứng yên cho đến khi sạch balo
                        if not isFarming then break end -- [FIX] Thoát nếu bị tắt farm giữa chừng
                        task.wait(1) 
                     end
                     
                     -- 4. CHỜ THÊM 5 GIÂY (THEO YÊU CẦU)
                     Log("✅ Đã sạch balo. Đợi thêm 5s...", Color3.fromRGB(0, 255, 0))
                     task.wait(5)

                     Log("🔙 Quay lại farm...", Color3.fromRGB(0, 255, 255))
                     
                     -- 5. Quay lại Field
                     Utils.Tween(CFrame.new(FieldInfo.Pos + Vector3.new(0, 5, 0)))
                end
            end

            -- Random Move (Chỉ chạy khi KHÔNG convert)
            local Character = LocalPlayer.Character
            if Character and Character:FindFirstChild("Humanoid") then
                local rx = math.random(-FieldInfo.Size.X/2 + 5, FieldInfo.Size.X/2 - 5)
                local rz = math.random(-FieldInfo.Size.Z/2 + 5, FieldInfo.Size.Z/2 - 5)
                Character.Humanoid:MoveTo(FieldInfo.Pos + Vector3.new(rx, 0, rz))
            end
            
            task.wait(0.2)
        end
    end)
end

-- [MỚI] Hàm Farm cho đến khi đủ tiền (Chặn Starter lại)
function module.FarmUntil(targetHoney, fieldName, Tools)
    local Player = Tools.Player
    local Log = Tools.Log
    
    -- Gọi farm bình thường
    module.StartFarm(fieldName, Tools)
    
    Log("⏳ AutoFarm: Cày đến " .. tostring(targetHoney) .. " Honey...", Color3.fromRGB(255, 255, 0))

    -- Vòng lặp chặn: Starter sẽ kẹt ở đây cho đến khi đủ tiền
    -- Trong lúc kẹt, AutoFarm vẫn chạy vòng lặp convert của riêng nó thoải mái
    while Player.GetHoney() < targetHoney do
        task.wait(1) 
    end
    
    -- Đủ tiền rồi -> Dừng farm -> Trả quyền cho Starter đi mua đồ
    module.StopFarm()
    Log("✅ AutoFarm: Đã đủ tiền! Dừng để đi mua.", Color3.fromRGB(0, 255, 0))
    task.wait(1) 
end

return module
