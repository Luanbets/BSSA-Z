local module = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local isFarming = false

-- [MỚI] CẤU HÌNH KHOẢNG CÁCH NÉ
local SAFE_RADIUS = 25 

-- Hàm tìm tổ (Giữ nguyên)
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

-- [MỚI] HÀM QUÉT QUÁI VẬT ĐANG TẤN CÔNG
local function GetNearestThreat(character)
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    
    local monsters = workspace:FindFirstChild("Monsters")
    if not monsters then return nil end

    local closestMob = nil
    local closestDist = SAFE_RADIUS 

    for _, mob in pairs(monsters:GetChildren()) do
        if mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
            local mobPos = mob.HumanoidRootPart.Position
            local dist = (mobPos - root.Position).Magnitude
            
            if dist < closestDist then
                closestDist = dist
                closestMob = mobPos
            end
        end
    end
    return closestMob
end

-- Hàm tìm Token (Giữ nguyên)
local function GetBestToken(FieldInfo, TokenData, Character, IgnoreList)
    local root = Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local Collectibles = workspace:FindFirstChild("Collectibles")
    if not Collectibles then return nil end

    local bestToken = nil
    local bestPriority = -1 
    local minDistance = 9999
    
    local halfX = FieldInfo.Size.X / 2
    local halfZ = FieldInfo.Size.Z / 2
    local minX, maxX = FieldInfo.Pos.X - halfX, FieldInfo.Pos.X + halfX
    local minZ, maxZ = FieldInfo.Pos.Z - halfZ, FieldInfo.Pos.Z + halfZ

    for _, token in pairs(Collectibles:GetChildren()) do
        if token:FindFirstChild("FrontDecal") and token.Transparency < 0.9 and not IgnoreList[token] then
            local pos = token.Position
            if pos.X >= minX and pos.X <= maxX and pos.Z >= minZ and pos.Z <= maxZ then
                local textureId = token.FrontDecal.Texture
                local priority = 0
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

    -- [MỚI] TÍNH TOÁN GIỚI HẠN CÁNH ĐỒNG (ĐỂ NÉ KHÔNG BỊ CHẠY RA NGOÀI)
    local halfX = FieldInfo.Size.X / 2 - 2
    local halfZ = FieldInfo.Size.Z / 2 - 2
    local minX, maxX = FieldInfo.Pos.X - halfX, FieldInfo.Pos.X + halfX
    local minZ, maxZ = FieldInfo.Pos.Z - halfZ, FieldInfo.Pos.Z + halfZ

    local IgnoreList = {}

    task.spawn(function()
        while isFarming do
            pcall(function() ReplicatedStorage.Events.ToolCollect:FireServer() end)
            
            local Character = LocalPlayer.Character
            if not Character or not Character:FindFirstChild("Humanoid") then
                task.wait(1)
                continue
            end
            local root = Character:FindFirstChild("HumanoidRootPart")

            if Utils.SyncWalkSpeed then Utils.SyncWalkSpeed() end

            -- [GIỮ NGUYÊN] Check Balo đầy
            if LocalPlayer:FindFirstChild("CoreStats") then
                local currentPollen = LocalPlayer.CoreStats.Pollen.Value   
                local maxCapacity = LocalPlayer.CoreStats.Capacity.Value   
                if currentPollen >= (maxCapacity * 0.90) then
                     Log("🎒 Balo đầy. Về tổ...", Color3.fromRGB(255, 170, 0))
                     IgnoreList = {} 
                     local hivePos = GetMyHivePosition()
                     Utils.Tween(CFrame.new(hivePos + Vector3.new(0, 5, 0)))
                     task.wait(1) 
                     ReplicatedStorage.Events.PlayerHiveCommand:FireServer("ToggleHoneyMaking")
                     while LocalPlayer.CoreStats.Pollen.Value > 0 do
                        if not isFarming then break end 
                        task.wait(1) 
                     end
                     task.wait(2)
                     Utils.Tween(CFrame.new(FieldInfo.Pos + Vector3.new(0, 5, 0)))
                end
            end

            -- =========================================================
            -- [LOGIC MỚI] 1. ƯU TIÊN NÉ QUÁI TRƯỚC
            -- =========================================================
            local threatPos = GetNearestThreat(Character)

            if threatPos then
                -- Nếu có quái: Tính hướng chạy ngược lại
                local fleeDir = (root.Position - threatPos).Unit
                local targetPos = root.Position + (fleeDir * 15) -- Chạy ra xa 15 studs

                -- Kẹp tọa độ lại để không chạy ra khỏi cánh đồng
                local clampedX = math.clamp(targetPos.X, minX, maxX)
                local clampedZ = math.clamp(targetPos.Z, minZ, maxZ)
                
                Character.Humanoid:MoveTo(Vector3.new(clampedX, root.Position.Y, clampedZ))
                
                -- Nhảy để né tốt hơn
                if Character.Humanoid.FloorMaterial ~= Enum.Material.Air then
                    Character.Humanoid.Jump = true
                end

            else
                -- =========================================================
                -- [LOGIC CŨ] 2. NẾU AN TOÀN -> ĐI FARM TOKEN
                -- =========================================================
                local targetToken = GetBestToken(FieldInfo, TokenData, Character, IgnoreList)
                
                if targetToken then
                    Character.Humanoid:MoveTo(targetToken.Position)
                    
                    if root then
                        local dist = (root.Position - targetToken.Position).Magnitude
                        if dist <= 6 then
                            IgnoreList[targetToken] = true
                        end
                    end
                else
                    -- Không có token thì chạy random
                    local rx = math.random(-FieldInfo.Size.X/2 + 5, FieldInfo.Size.X/2 - 5)
                    local rz = math.random(-FieldInfo.Size.Z/2 + 5, FieldInfo.Size.Z/2 - 5)
                    Character.Humanoid:MoveTo(FieldInfo.Pos + Vector3.new(rx, 0, rz))
                end
            end
            
            if #IgnoreList > 100 then IgnoreList = {} end

            task.wait(0.1) 
        end
    end)
end

function module.FarmUntil(targetHoney, fieldName, Tools)
    local Player = Tools.Player
    local Log = Tools.Log
    module.StartFarm(fieldName, Tools)
    while Player.GetHoney() < targetHoney do task.wait(1) end
    module.StopFarm()
    task.wait(1) 
end

return module
