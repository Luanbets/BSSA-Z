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
-- 2. HÀM HỖ TRỢ & TÌM TỔ (FIXED)
-- =========================================================

-- Hàm Tìm Tổ Ong Của Mình (Siêu Cấp)
local function GetMyHivePos()
    -- Tìm folder chứa Hive (Có server tên Honeycombs, có server tên Hives)
    local honeycombs = Workspace:FindFirstChild("Honeycombs") or Workspace:FindFirstChild("Hives")
    if not honeycombs then return nil end
    
    for _, hive in pairs(honeycombs:GetChildren()) do
        -- Kiểm tra xem Hive có chủ chưa
        if hive:FindFirstChild("Owner") and hive:FindFirstChild("SpawnPos") then
            -- So sánh 1: Giá trị Owner là Tên (String)
            if tostring(hive.Owner.Value) == LocalPlayer.Name then
                return hive.SpawnPos.CFrame
            end
            -- So sánh 2: Giá trị Owner là Object (Instance)
            if hive.Owner.Value == LocalPlayer then
                return hive.SpawnPos.CFrame
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

local function IsPointInField(point, fieldInfo)
    if not fieldInfo or not fieldInfo.Pos or not fieldInfo.Size then return false end
    local halfX = fieldInfo.Size.X / 2
    local halfZ = fieldInfo.Size.Z / 2
    local dx = math.abs(point.X - fieldInfo.Pos.X)
    local dz = math.abs(point.Z - fieldInfo.Pos.Z)
    return (dx <= halfX and dz <= halfZ)
end

-- Tìm Token (Logic V2 - Ổn định)
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
-- 3. CHỨC NĂNG FARM CHÍNH
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

    -- Auto Dig (Remote)
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

        -- 1. XỬ LÝ ĐẦY BALO (LOGIC MỚI)
        if IsBackpackFull() then
            if LogFunc then LogFunc("🎒 Balo đầy! Đang tìm tổ...", Color3.fromRGB(255, 200, 0)) end
            
            local myHivePos = GetMyHivePos() -- Gọi hàm tìm tổ mới

            if myHivePos then
                -- Về tổ (Cộng thêm độ cao và lùi ra xíu để dễ đứng)
                Utils.Tween(myHivePos * CFrame.new(0, 2, 6), function() end)
                
                -- Thực hiện Convert
                local convertTimeout = 0
                repeat
                    ReplicatedStorage.Events.PlayerHiveCommand:FireServer("ToggleHoneyMaking")
                    task.wait(2)
                    convertTimeout = convertTimeout + 1
                    
                    -- Nếu kẹt quá 60s mà không xong thì quay lại farm (tránh treo)
                    if convertTimeout > 30 then break end 
                until not IsBackpackFull() or not isFarming
                
                if LogFunc then LogFunc("✅ Xong! Quay lại farm...", Color3.fromRGB(0, 255, 0)) end
                Utils.Tween(CFrame.new(fieldInfo.Pos + Vector3.new(0, 5, 0)), function() end)
            else
                if LogFunc then LogFunc("⚠️ Lỗi: Không tìm thấy tổ của bạn!", Color3.fromRGB(255, 0, 0)) end
                -- Nếu không tìm thấy tổ, reset nhân vật để về bệ spawn (giải pháp cuối cùng)
                -- LocalPlayer.Character:BreakJoints() 
                task.wait(5)
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
