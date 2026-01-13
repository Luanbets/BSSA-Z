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
    return Vector3.new(0, 5, 0)
end

-- Hàm tìm Token ngon nhất
local function GetBestToken(FieldInfo, TokenData, Character)
    local root = Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local Collectibles = workspace:FindFirstChild("Collectibles")
    if not Collectibles then return nil end

    local bestToken = nil
    local bestPriority = 0
    local minDistance = 9999
    
    local maxFieldRadius = math.max(FieldInfo.Size.X, FieldInfo.Size.Z) / 1.5

    for _, token in pairs(Collectibles:GetChildren()) do
        if token:FindFirstChild("FrontDecal") and token.Transparency < 0.9 then
            local pos = token.Position
            local distToField = (pos - FieldInfo.Pos).Magnitude
            
            if distToField <= maxFieldRadius then
                local textureId = token.FrontDecal.Texture
                local priority = 1 
                
                if TokenData and TokenData.Tokens and TokenData.Tokens[textureId] then
                    priority = TokenData.Tokens[textureId].Priority
                end
                
                local distToPlayer = (pos - root.Position).Magnitude

                if priority > bestPriority then
                    bestPriority = priority
                    bestToken = token
                    minDistance = distToPlayer
                elseif priority == bestPriority then
                    if distToPlayer < minDistance then
                        bestToken = token
                        minDistance = distToPlayer
                    end
                end
            end
        end
    end

    return bestToken
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
    local TokenData = Tools.Token 
    
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
            
            local Character = LocalPlayer.Character
            if not Character or not Character:FindFirstChild("Humanoid") then
                task.wait(1)
                continue
            end

            -- [ĐỒNG BỘ HÓA] Gọi hàm từ Utilities để set tốc độ chạy
            -- Không cần chỉnh số ở đây nữa!
            if Utils.SyncWalkSpeed then
                Utils.SyncWalkSpeed()
            end

            -- A. CHECK BALO & CONVERT
            if LocalPlayer:FindFirstChild("CoreStats") then
                local currentPollen = LocalPlayer.CoreStats.Pollen.Value   
                local maxCapacity = LocalPlayer.CoreStats.Capacity.Value   
                
                if currentPollen >= (maxCapacity * 0.90) then
                     Log("🎒 Balo đầy ("..math.floor(currentPollen).."). Về tổ...", Color3.fromRGB(255, 170, 0))
                     
                     local hivePos = GetMyHivePosition()
                     Utils.Tween(CFrame.new(hivePos + Vector3.new(0, 5, 0)))
                     task.wait(1) 

                     ReplicatedStorage.Events.PlayerHiveCommand:FireServer("ToggleHoneyMaking")
                     
                     Log("⏳ Đang convert... (Đứng yên chờ về 0)", Color3.fromRGB(255, 255, 0))
                     while LocalPlayer.CoreStats.Pollen.Value > 0 do
                        if not isFarming then break end 
                        task.wait(1) 
                     end
                     
                     Log("✅ Đã sạch balo. Đợi thêm 5s...", Color3.fromRGB(0, 255, 0))
                     task.wait(5)

                     Log("🔙 Quay lại farm...", Color3.fromRGB(0, 255, 255))
                     Utils.Tween(CFrame.new(FieldInfo.Pos + Vector3.new(0, 5, 0)))
                end
            end

            -- B. DI CHUYỂN (TOKEN HOẶC RANDOM)
            local targetToken = GetBestToken(FieldInfo, TokenData, Character)
            
            if targetToken then
                Character.Humanoid:MoveTo(targetToken.Position)
            else
                local rx = math.random(-FieldInfo.Size.X/2 + 5, FieldInfo.Size.X/2 - 5)
                local rz = math.random(-FieldInfo.Size.Z/2 + 5, FieldInfo.Size.Z/2 - 5)
                Character.Humanoid:MoveTo(FieldInfo.Pos + Vector3.new(rx, 0, rz))
            end
            
            task.wait(0.1) 
        end
    end)
end

function module.FarmUntil(targetHoney, fieldName, Tools)
    local Player = Tools.Player
    local Log = Tools.Log
    
    module.StartFarm(fieldName, Tools)
    
    Log("⏳ AutoFarm: Cày đến " .. tostring(targetHoney) .. " Honey...", Color3.fromRGB(255, 255, 0))

    while Player.GetHoney() < targetHoney do
        task.wait(1) 
    end
    
    module.StopFarm()
    Log("✅ AutoFarm: Đã đủ tiền! Dừng để đi mua.", Color3.fromRGB(0, 255, 0))
    task.wait(1) 
end

return module
