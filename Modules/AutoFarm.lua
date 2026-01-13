local module = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Nhận TokenData từ Main truyền vào hoặc tự load
local TokenDataDB = nil 
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
    return Vector3.new(0, 5, 0) -- Fallback
end

local function GetTokenPriority(texID, TokenDB)
    if not TokenDB then return 0 end
    local cleanID = "rbxassetid://" .. tostring(string.match(texID, "%d+$"))
    if TokenDB.Tokens[cleanID] then return TokenDB.Tokens[cleanID].Priority end
    return 0
end

function module.StopFarm()
    isFarming = false
end

-- Hàm Farm Chính
function module.StartFarm(fieldName, Tools)
    if isFarming then return end 
    isFarming = true
    
    -- === [ĐÃ SỬA: LẤY ĐÚNG FIELD DATA] ===
    local FieldInfo = nil
    if Tools.Field and Tools.Field.Fields then
        FieldInfo = Tools.Field.Fields[fieldName] 
    end
    -- ======================================

    local Utils = Tools.Utils
    local Log = Tools.Log
    
    if not FieldInfo then 
        Log("❌ AutoFarm: Unknown Field " .. tostring(fieldName), Color3.fromRGB(255, 0, 0))
        isFarming = false 
        return 
    end

    Log("🚜 Farming at " .. fieldName, Color3.fromRGB(0, 255, 255))
    
    -- Di chuyển đến Field
    Utils.Tween(CFrame.new(FieldInfo.Pos + Vector3.new(0,5,0)), task.wait)

    -- Loop Farm
    task.spawn(function()
        while isFarming do
            -- 1. Auto Dig
            pcall(function() ReplicatedStorage.Events.ToolCollect:FireServer() end)
            
            -- 2. Auto Convert (ĐÃ SỬA LOGIC)
            if LocalPlayer:FindFirstChild("CoreStats") then
                local currentPollen = LocalPlayer.CoreStats.Pollen.Value   -- Lấy Phấn Hoa
                local maxCapacity = LocalPlayer.CoreStats.Capacity.Value   -- Lấy Sức chứa
                
                -- Nếu đầy 95% thì về
                if currentPollen >= (maxCapacity * 0.95) then
                     Log("🎒 Balo đầy ("..math.floor(currentPollen).."/"..maxCapacity.."). Về tổ...", Color3.fromRGB(255, 170, 0))
                     
                     -- A. Bay về tổ
                     local hivePos = GetMyHivePosition()
                     Utils.Tween(CFrame.new(hivePos + Vector3.new(0, 5, 0)))
                     task.wait(0.5)

                     -- B. Gửi lệnh làm mật
                     ReplicatedStorage.Events.PlayerHiveCommand:FireServer("ToggleHoneyMaking")
                     
                     -- C. Chờ phấn hoa về 0
                     local waitCount = 0
                     while LocalPlayer.CoreStats.Pollen.Value > 0 and waitCount < 60 do
                        -- Nhảy nhẹ để server không kick AFK
                        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                            LocalPlayer.Character.Humanoid.Jump = true
                        end
                        waitCount = waitCount + 1
                        task.wait(1)
                     end
                     
                     Log("🔙 Đã làm mật xong! Quay lại farm...", Color3.fromRGB(0, 255, 255))

                     -- D. Quay lại Field
                     Utils.Tween(CFrame.new(FieldInfo.Pos + Vector3.new(0,5,0)), task.wait)
                end
            end

            -- 3. Tìm Token & Random Move
            local Character = LocalPlayer.Character
            if Character and Character:FindFirstChild("Humanoid") then
                -- Random Move
                local rx = math.random(-FieldInfo.Size.X/2 + 5, FieldInfo.Size.X/2 - 5)
                local rz = math.random(-FieldInfo.Size.Z/2 + 5, FieldInfo.Size.Z/2 - 5)
                Character.Humanoid:MoveTo(FieldInfo.Pos + Vector3.new(rx, 0, rz))
            end
            
            task.wait(0.1)
        end
    end)
end

return module
