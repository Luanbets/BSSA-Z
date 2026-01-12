local module = {}
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Biến lưu dữ liệu Field (Vẫn tải từ ngoài để dễ update toạ độ)
local FieldDataDB = nil

-- =========================================================
-- 1. DỮ LIỆU TOKEN (ĐÃ TÍCH HỢP TRỰC TIẾP VÀO ĐÂY)
-- =========================================================
local TokenPriorityDB = {
    -- === ITEMS (Priority: 100) - LỤM NGAY ===
    ["rbxassetid://1471850677"] = {Priority = 100, Name = "Diamond Egg"},
    ["rbxassetid://2319943273"] = {Priority = 100, Name = "Star Jelly"},
    ["rbxassetid://2584584968"] = {Priority = 100, Name = "Oil"},
    ["rbxassetid://1674871631"] = {Priority = 100, Name = "Ticket"},
    ["rbxassetid://1471882621"] = {Priority = 100, Name = "Royal Jelly"},
    ["rbxassetid://1952796032"] = {Priority = 100, Name = "Pineapple"},
    ["rbxassetid://2028453802"] = {Priority = 100, Name = "Blueberry"},
    ["rbxassetid://1952682401"] = {Priority = 100, Name = "Sunflower Seed"},
    ["rbxassetid://2542899798"] = {Priority = 100, Name = "Glitter"},
    ["rbxassetid://1952740625"] = {Priority = 100, Name = "Strawberry"},
    ["rbxassetid://1471849394"] = {Priority = 100, Name = "Gold Egg"},

    -- === TOKEN BUFF (Priority: 10) - LỤM SAU ===
    ["rbxassetid://1442859163"] = {Priority = 10, Name = "Red Boost"},
    ["rbxassetid://1442725244"] = {Priority = 10, Name = "Blue Boost"},
    ["rbxassetid://177997841"]  = {Priority = 10, Name = "Bomb Token"},
    ["rbxassetid://2499514197"] = {Priority = 10, Name = "Honey Mark"},
    ["rbxassetid://65867881"]   = {Priority = 10, Name = "Haste"},
    ["rbxassetid://253828517"]  = {Priority = 10, Name = "Melody"},
    ["rbxassetid://1472256444"] = {Priority = 10, Name = "Baby Love"},
    ["rbxassetid://1442863423"] = {Priority = 10, Name = "Blue Boost"},
    ["rbxassetid://1629547638"] = {Priority = 10, Name = "Token Link"},
    ["rbxassetid://2499540966"] = {Priority = 10, Name = "Pollen Mark"},
    ["rbxassetid://1442764904"] = {Priority = 10, Name = "Buzz Bomb+"},
    ["rbxassetid://2000457501"] = {Priority = 10, Name = "Star"},
    ["rbxassetid://1629649299"] = {Priority = 10, Name = "Focus"},
}

-- =========================================================
-- 2. HÀM TẢI DỮ LIỆU (CHỈ CÒN TẢI FIELD DATA)
-- =========================================================
local function LoadFieldData(LogFunc)
    -- !!! LINK GITHUB CỦA BẠN !!!
    local repo = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/"
    
    local success1, content1 = pcall(function() return game:HttpGet(repo .. "FieldData.lua?t="..tick()) end)
    if success1 then 
        local func = loadstring(content1)
        if func then FieldDataDB = func() end
    end
    -- TokenData đã có sẵn ở trên, không cần tải nữa!
end

-- =========================================================
-- 3. HÀM TÌM TỔ & HỖ TRỢ
-- =========================================================
local function GetMyHivePos()
    local honeycombs = Workspace:FindFirstChild("Honeycombs") or Workspace:FindFirstChild("Hives")
    if not honeycombs then return nil end

    for _, hive in pairs(honeycombs:GetChildren()) do
        if hive:FindFirstChild("Owner") and hive.Owner.Value == LocalPlayer then
            local spawnPos = hive:FindFirstChild("SpawnPos")
            if spawnPos then
                if spawnPos:IsA("BasePart") then
                    return spawnPos.CFrame 
                elseif spawnPos:IsA("CFrameValue") or spawnPos:IsA("ValueBase") then
                    return spawnPos.Value  
                end
            end
        end
    end
    return nil
end

local function GetIDFromTexture(texture)
    return tostring(string.match(texture, "%d+$"))
end

local function IsBackpackFull()
    if LocalPlayer.CoreStats and LocalPlayer.CoreStats:FindFirstChild("Pollen") and LocalPlayer.CoreStats:FindFirstChild("Capacity") then
        return LocalPlayer.CoreStats.Pollen.Value >= LocalPlayer.CoreStats.Capacity.Value
    end
    return false
end

local function GetCurrentPollen()
    if LocalPlayer.CoreStats and LocalPlayer.CoreStats:FindFirstChild("Pollen") then
        return LocalPlayer.CoreStats.Pollen.Value
    end
    return 0
end

local function IsPointInField(point, fieldInfo)
    if not fieldInfo or not fieldInfo.Pos or not fieldInfo.Size then return false end
    local halfX = fieldInfo.Size.X / 2
    local halfZ = fieldInfo.Size.Z / 2
    local dx = math.abs(point.X - fieldInfo.Pos.X)
    local dz = math.abs(point.Z - fieldInfo.Pos.Z)
    return (dx <= halfX and dz <= halfZ)
end

-- Tìm Token
local function FindBestToken(fieldInfo)
    -- TokenPriorityDB ĐÃ CÓ SẴN, KHÔNG LO BỊ NIL
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
                local tokenData = TokenPriorityDB[texID]
                
                if tokenData and IsPointInField(token.Position, fieldInfo) then
                    local priority = tokenData.Priority or 0
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

-- =========================================================
-- 4. CHỨC NĂNG FARM CHÍNH
-- =========================================================
local isFarming = false

function module.StartFarm(fieldName, LogFunc, Utils)
    if not FieldDataDB then
        if LogFunc then LogFunc("Đang tải dữ liệu Field...", Color3.fromRGB(255, 255, 0)) end
        LoadFieldData(LogFunc)
        task.wait(0.5)
    end

    local fieldInfo = FieldDataDB and FieldDataDB[fieldName]
    if not fieldInfo then
        if LogFunc then LogFunc("❌ Không tìm thấy Field: " .. tostring(fieldName), Color3.fromRGB(255, 0, 0)) end
        return
    end

    isFarming = true
    if LogFunc then LogFunc("🚜 Bắt đầu Farm: " .. fieldName, Color3.fromRGB(0, 255, 0)) end

    -- Auto Dig
    task.spawn(function()
        while isFarming do
            pcall(function() ReplicatedStorage.Events.ToolCollect:FireServer() end)
            task.wait(0.2)
        end
    end)

    local Character = LocalPlayer.Character
    local Humanoid = Character:WaitForChild("Humanoid")
    local RootPart = Character:WaitForChild("HumanoidRootPart")

    Utils.Tween(CFrame.new(fieldInfo.Pos + Vector3.new(0, 5, 0)), function() end)

    while isFarming do
        RunService.Heartbeat:Wait()
        
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.CharacterAdded:Wait()
            Character = LocalPlayer.Character
            Humanoid = Character:WaitForChild("Humanoid")
            RootPart = Character:WaitForChild("HumanoidRootPart")
            Utils.Tween(CFrame.new(fieldInfo.Pos + Vector3.new(0, 5, 0)), function() end)
        end

        -- 1. XỬ LÝ VỀ TỔ (CONVERT 100% & CHỜ 6S)
        if IsBackpackFull() then
            if LogFunc then LogFunc("🎒 Balo đầy! Về tổ...", Color3.fromRGB(255, 200, 0)) end
            
            local myHivePos = GetMyHivePos()

            if myHivePos then
                Utils.Tween(myHivePos * CFrame.new(0, 4, 6), function() end)
                task.wait(0.5)

                -- Bấm nút convert lần đầu
                ReplicatedStorage.Events.PlayerHiveCommand:FireServer("ToggleHoneyMaking")
                task.wait(1)

                local prevPollen = GetCurrentPollen()
                local stuckTime = 0
                local timeout = 0
                
                while GetCurrentPollen() > 10 and isFarming do
                    task.wait(1)
                    timeout = timeout + 1
                    if timeout > 300 then break end
                    
                    local currPollen = GetCurrentPollen()
                    
                    if currPollen >= prevPollen then
                        stuckTime = stuckTime + 1
                        if stuckTime >= 5 then
                            if LogFunc then LogFunc("⚠️ Kẹt convert -> Thử bật lại...", Color3.fromRGB(255, 150, 0)) end
                            ReplicatedStorage.Events.PlayerHiveCommand:FireServer("ToggleHoneyMaking")
                            stuckTime = 0 
                        end
                    else
                        stuckTime = 0
                    end
                    prevPollen = currPollen
                end
                
                if LogFunc then LogFunc("⏳ Đợi thêm 6s cho chắc...", Color3.fromRGB(255, 255, 255)) end
                task.wait(6)
                
                if LogFunc then LogFunc("✅ Sạch balo! Đi farm...", Color3.fromRGB(0, 255, 0)) end
                Utils.Tween(CFrame.new(fieldInfo.Pos + Vector3.new(0, 5, 0)), function() end)
            else
                if LogFunc then LogFunc("⚠️ Lỗi tìm tổ!", Color3.fromRGB(255, 0, 0)) end
                task.wait(2)
            end
        end

        -- 2. Nhặt Token
        local targetToken = FindBestToken(fieldInfo)
        
        if targetToken then
            Humanoid:MoveTo(targetToken.Position)
            local stuckCount = 0
            while targetToken and targetToken.Parent and targetToken.Transparency == 0 do
                Humanoid:MoveTo(targetToken.Position)
                if not IsPointInField(RootPart.Position, fieldInfo) then break end
                stuckCount = stuckCount + 1
                if stuckCount > 60 then break end
                RunService.Heartbeat:Wait()
            end
        else
            -- 3. Farm ngẫu nhiên
            local rx = math.random(-fieldInfo.Size.X/2 + 5, fieldInfo.Size.X/2 - 5)
            local rz = math.random(-fieldInfo.Size.Z/2 + 5, fieldInfo.Size.Z/2 - 5)
            local dest = Vector3.new(fieldInfo.Pos.X + rx, fieldInfo.Pos.Y, fieldInfo.Pos.Z + rz)
            
            Humanoid:MoveTo(dest)
            local walkTime = 0
            while (RootPart.Position - dest).Magnitude > 4 and walkTime < 30 do
                if FindBestToken(fieldInfo) then break end
                walkTime = walkTime + 1
                RunService.Heartbeat:Wait()
            end
        end
    end
end

function module.StopFarm()
    isFarming = false
end

return module
