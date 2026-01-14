local module = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local isFarming = false

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

-- Hàm tìm Token (Né những cái đã lướt qua rồi - IgnoreList)
local function GetBestToken(FieldInfo, TokenData, Character, IgnoreList)
    local root = Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local Collectibles = workspace:FindFirstChild("Collectibles")
    if not Collectibles then return nil end

    local bestToken = nil
    local bestPriority = -1 
    local minDistance = 9999
    
    -- 1. LẤY PHẠM VI HÌNH HỘP
    local halfX = FieldInfo.Size.X / 2
    local halfZ = FieldInfo.Size.Z / 2
    local minX, maxX = FieldInfo.Pos.X - halfX, FieldInfo.Pos.X + halfX
    local minZ, maxZ = FieldInfo.Pos.Z - halfZ, FieldInfo.Pos.Z + halfZ

    for _, token in pairs(Collectibles:GetChildren()) do
        -- Chỉ lấy token chưa bị "Ignore" (chưa lướt qua)
        if token:FindFirstChild("FrontDecal") and token.Transparency < 0.9 and not IgnoreList[token] then
            local pos = token.Position
            
            -- Chỉ lấy trong phạm vi Field
            if pos.X >= minX and pos.X <= maxX and pos.Z >= minZ and pos.Z <= maxZ then
                
                local textureId = token.FrontDecal.Texture
                local priority = 0
                
                -- Lấy độ ưu tiên
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

    -- Danh sách đen (Chứa các token đã đụng vào)
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
                     IgnoreList = {} -- Reset danh sách khi về tổ
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
            -- LOGIC: CHẠY TỚI -> ĐỤNG -> LƯỚT QUA
            -- =========================================================
            local targetToken = GetBestToken(FieldInfo, TokenData, Character, IgnoreList)
            
            if targetToken then
                -- 1. Lao thẳng tới token
                Character.Humanoid:MoveTo(targetToken.Position)
                
                -- 2. Kiểm tra va chạm (6 studs là rất gần, coi như đã đụng)
                if root then
                    local dist = (root.Position - targetToken.Position).Magnitude
                    
                    if dist <= 6 then
                        -- Đã đụng! -> Cho vào danh sách đen ngay lập tức
                        IgnoreList[targetToken] = true
                        
                        -- Không cần lệnh dừng, vòng lặp sau tự động chạy tới cái khác
                    end
                end
            else
                -- Không có token thì chạy random
                local rx = math.random(-FieldInfo.Size.X/2 + 5, FieldInfo.Size.X/2 - 5)
                local rz = math.random(-FieldInfo.Size.Z/2 + 5, FieldInfo.Size.Z/2 - 5)
                Character.Humanoid:MoveTo(FieldInfo.Pos + Vector3.new(rx, 0, rz))
            end
            
            -- Xóa bớt danh sách nếu quá đầy để nhẹ máy
            if #IgnoreList > 100 then IgnoreList = {} end

            task.wait(0.1) -- Cập nhật liên tục để chuyển hướng mượt
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
