local module = {}
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Biến lưu dữ liệu
local FieldDataDB = nil
local TokenPriorityDB = nil

-- =========================================================
-- 1. HÀM TẢI DỮ LIỆU
-- =========================================================
local function LoadExternalModules(LogFunc)
    -- !!! LINK GITHUB CỦA BẠN !!!
    local repo = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/"
    
    local success1, content1 = pcall(function() return game:HttpGet(repo .. "FieldData.lua?t="..tick()) end)
    if success1 then 
        local func = loadstring(content1)
        if func then FieldDataDB = func() end
    end

    local success2, content2 = pcall(function() return game:HttpGet(repo .. "TokenData.lua?t="..tick()) end)
    if success2 then 
        local func = loadstring(content2)
        if func then 
            local mod = func()
            TokenPriorityDB = mod.Tokens
        end 
    end
end

-- =========================================================
-- 2. HÀM TÌM TỔ (ĐÃ SỬA THEO CODE CỦA BẠN + FIX LỖI ẢNH)
-- =========================================================
local function GetMyHivePos()
    local honeycombs = Workspace:FindFirstChild("Honeycombs") or Workspace:FindFirstChild("Hives")
    if not honeycombs then return nil end

    for _, hive in pairs(honeycombs:GetChildren()) do
        -- [LOGIC CỦA BẠN] Kiểm tra chủ sở hữu
        if hive:FindFirstChild("Owner") and hive.Owner.Value == LocalPlayer then
            
            -- [FIX LỖI] Kiểm tra kỹ loại SpawnPos để tránh lỗi "CFrame is not a valid member"
            local spawnPos = hive:FindFirstChild("SpawnPos")
            if spawnPos then
                if spawnPos:IsA("BasePart") then
                    return spawnPos.CFrame -- Nếu là Part thì lấy CFrame
                elseif spawnPos:IsA("CFrameValue") or spawnPos:IsA("ValueBase") then
                    return spawnPos.Value  -- Nếu là Value thì lấy .Value (Đây là chỗ bị lỗi trong ảnh)
                end
            end
        end
    end
    return nil
end

-- =========================================================
-- 3. CÁC HÀM HỖ TRỢ KHÁC
-- =========================================================
local function GetIDFromTexture(texture)
    return tostring(string.match(texture, "%d+$"))
end

local function IsBackpackFull()
    if LocalPlayer.CoreStats and LocalPlayer.CoreStats:FindFirstChild("Pollen") and LocalPlayer.CoreStats:FindFirstChild("Capacity") then
        return LocalPlayer.CoreStats.Pollen.Value >= LocalPlayer.CoreStats.Capacity.Value
    end
    return false
end

local function IsPointInField(point, fieldInfo)
    if not fieldInfo or not fieldInfo.Pos or not fieldInfo.Size then return false end
    local halfX = fieldInfo.Size.X / 2
    local halfZ = fieldInfo.Size.Z / 2
    local dx = math.abs(point.X - fieldInfo.Pos.X)
    local dz = math.abs(point.Z - fieldInfo.Pos.Z)
    return (dx <= halfX and dz <= halfZ)
end

-- Tìm Token (Logic Chạy Xuyên Qua)
local function FindBestToken(fieldInfo)
    if not TokenPriorityDB then return nil end
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
    if not FieldDataDB or not TokenPriorityDB then
        if LogFunc then LogFunc("Đang tải dữ liệu...", Color3.fromRGB(255, 255, 0)) end
        LoadExternalModules(LogFunc)
        task.wait(0.5)
    end

    local fieldInfo = FieldDataDB and FieldDataDB[fieldName]
    if not fieldInfo then
        if LogFunc then LogFunc("❌ Không tìm thấy Field: " .. tostring(fieldName), Color3.fromRGB(255, 0, 0)) end
        return
    end

    isFarming = true
    if LogFunc then LogFunc("🚜 Bắt đầu Farm: " .. fieldName, Color3.fromRGB(0, 255, 0)) end

    -- Auto Dig (Remote Server)
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

        -- 1. XỬ LÝ VỀ TỔ (FIX LỖI CFRAME/VALUE)
        if IsBackpackFull() then
            if LogFunc then LogFunc("🎒 Balo đầy! Đang tìm tổ...", Color3.fromRGB(255, 200, 0)) end
            
            local myHivePos = GetMyHivePos() -- Đã dùng logic mới

            if myHivePos then
                -- Về tổ: Đứng cao hơn và lùi ra 1 chút để dễ click
                Utils.Tween(myHivePos * CFrame.new(0, 4, 6), function() end)
                
                local convertTimeout = 0
                repeat
                    ReplicatedStorage.Events.PlayerHiveCommand:FireServer("ToggleHoneyMaking")
                    task.wait(2)
                    convertTimeout = convertTimeout + 1
                    if convertTimeout > 30 then break end 
                until not IsBackpackFull() or not isFarming
                
                if LogFunc then LogFunc("✅ Convert xong! Quay lại...", Color3.fromRGB(0, 255, 0)) end
                Utils.Tween(CFrame.new(fieldInfo.Pos + Vector3.new(0, 5, 0)), function() end)
            else
                if LogFunc then LogFunc("⚠️ Không tìm thấy tổ! (Kiểm tra lại code)", Color3.fromRGB(255, 0, 0)) end
                task.wait(2)
            end
        end

        -- 2. Nhặt Token (Lướt qua không dừng)
        local targetToken = FindBestToken(fieldInfo)
        
        if targetToken then
            Humanoid:MoveTo(targetToken.Position)
            local stuckCount = 0
            
            -- Lặp cho đến khi token biến mất (đã ăn được)
            while targetToken and targetToken.Parent and targetToken.Transparency == 0 do
                Humanoid:MoveTo(targetToken.Position) -- Spam lệnh đi để không dừng
                if not IsPointInField(RootPart.Position, fieldInfo) then break end
                
                stuckCount = stuckCount + 1
                if stuckCount > 60 then break end -- Kẹt quá 2s thì bỏ
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
