local module = {}
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local isFarming = false

-- Helper: Lấy ID Texture
local function GetIDFromTexture(texture)
    return tostring(string.match(texture, "%d+$"))
end

-- Helper: Tìm Hive
local function GetMyHivePos()
    local honeycombs = Workspace:FindFirstChild("Honeycombs") or Workspace:FindFirstChild("Hives")
    if not honeycombs then return nil end
    for _, hive in pairs(honeycombs:GetChildren()) do
        if hive:FindFirstChild("Owner") and hive.Owner.Value == LocalPlayer then
            return hive:FindFirstChild("SpawnPos") and hive.SpawnPos.Value
        end
    end
    return nil
end

-- Helper: Tìm Token ngon nhất (Dùng TokenData được truyền vào)
local function FindBestToken(fieldInfo, TokenData)
    local Character = LocalPlayer.Character
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = Character.HumanoidRootPart.Position
    
    local bestToken = nil
    local bestPriority = -1
    local minDistance = 99999

    local collectibles = Workspace:FindFirstChild("Collectibles")
    if collectibles then
        for _, token in pairs(collectibles:GetChildren()) do
            if token.Transparency == 0 and token:FindFirstChild("FrontDecal") then
                local texID = "rbxassetid://" .. GetIDFromTexture(token.FrontDecal.Texture)
                
                -- LẤY DỮ LIỆU TỪ TOKENDATA BÊN NGOÀI
                local tokenInfo = TokenData.Tokens[texID]
                
                -- Logic kiểm tra vị trí
                local dx = math.abs(token.Position.X - fieldInfo.Pos.X)
                local dz = math.abs(token.Position.Z - fieldInfo.Pos.Z)
                local isInField = (dx <= fieldInfo.Size.X/2 and dz <= fieldInfo.Size.Z/2)

                if tokenInfo and isInField then
                    local priority = tokenInfo.Priority or 0
                    local dist = (token.Position - myPos).Magnitude
                    
                    if priority > bestPriority then
                        bestPriority = priority
                        minDistance = dist
                        bestToken = token
                    elseif priority == bestPriority then
                        if dist < minDistance then
                            minDistance = dist
                            bestToken = token
                        end
                    end
                end
            end
        end
    end
    return bestToken
end

-- MAIN FUNCTION: START FARM
-- Nhận toàn bộ data từ bên ngoài vào
function module.StartFarm(fieldName, LogFunc, Utils, FieldData, TokenData)
    local fieldInfo = FieldData[fieldName]
    if not fieldInfo then
        if LogFunc then LogFunc("❌ Không tìm thấy Field: " .. tostring(fieldName), Color3.fromRGB(255, 0, 0)) end
        return
    end

    isFarming = true
    if LogFunc then LogFunc("🚜 Farming: " .. fieldName, Color3.fromRGB(0, 255, 0)) end

    -- Auto Dig Loop
    task.spawn(function()
        while isFarming do
            pcall(function() ReplicatedStorage.Events.ToolCollect:FireServer() end)
            task.wait(0.2)
        end
    end)

    local Character = LocalPlayer.Character
    local Humanoid = Character:WaitForChild("Humanoid")
    
    Utils.Tween(CFrame.new(fieldInfo.Pos + Vector3.new(0, 5, 0)), function() end)

    while isFarming do
        RunService.Heartbeat:Wait()
        if not LocalPlayer.Character then LocalPlayer.CharacterAdded:Wait() end
        
        -- 1. Check Balo đầy -> Về tổ
        if LocalPlayer.CoreStats.Pollen.Value >= LocalPlayer.CoreStats.Capacity.Value then
            if LogFunc then LogFunc("🎒 Balo đầy -> Convert", Color3.fromRGB(255, 200, 0)) end
            local myHive = GetMyHivePos()
            if myHive then
                Utils.Tween(myHive * CFrame.new(0,4,6), function() end)
                task.wait(0.5)
                ReplicatedStorage.Events.PlayerHiveCommand:FireServer("ToggleHoneyMaking")
                task.wait(1)
                -- Đợi convert xong (đơn giản hóa)
                while LocalPlayer.CoreStats.Pollen.Value > 0 and isFarming do task.wait(1) end
                task.wait(2)
                if LogFunc then LogFunc("✅ Convert xong -> Quay lại", Color3.fromRGB(0, 255, 0)) end
                Utils.Tween(CFrame.new(fieldInfo.Pos + Vector3.new(0, 5, 0)), function() end)
            end
        end

        -- 2. Tìm và ăn Token (Dùng TokenData)
        local target = FindBestToken(fieldInfo, TokenData)
        if target then
            Humanoid:MoveTo(target.Position)
        else
            -- 3. Đi ngẫu nhiên nếu không có token xịn
            local rx = math.random(-fieldInfo.Size.X/2 + 5, fieldInfo.Size.X/2 - 5)
            local rz = math.random(-fieldInfo.Size.Z/2 + 5, fieldInfo.Size.Z/2 - 5)
            Humanoid:MoveTo(Vector3.new(fieldInfo.Pos.X + rx, fieldInfo.Pos.Y, fieldInfo.Pos.Z + rz))
            task.wait(0.5)
        end
    end
end

function module.StopFarm()
    isFarming = false
end

return module
