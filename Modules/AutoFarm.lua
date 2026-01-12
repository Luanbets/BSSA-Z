local module = {}
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

-- Biến lưu dữ liệu
local FieldDataDB = nil
local TokenPriorityDB = nil

-- Hàm load dữ liệu từ GitHub
local function LoadExternalModules(LogFunc)
    -- !!! LINK GITHUB CỦA BẠN !!!
    local repo = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/"
    
    -- 1. Load FieldData
    local success1, content1 = pcall(function() return game:HttpGet(repo .. "FieldData.lua?t="..tick()) end)
    if success1 then 
        local func = loadstring(content1)
        if func then FieldDataDB = func() end
    else
        if LogFunc then LogFunc("❌ Lỗi tải FieldData!", Color3.fromRGB(255, 0, 0)) end
    end

    -- 2. Load TokenData
    local success2, content2 = pcall(function() return game:HttpGet(repo .. "TokenData.lua?t="..tick()) end)
    if success2 then 
        local func = loadstring(content2)
        if func then 
            local mod = func()
            TokenPriorityDB = mod.Tokens
        end 
    else
        if LogFunc then LogFunc("❌ Lỗi tải TokenData!", Color3.fromRGB(255, 0, 0)) end
    end
end

-- Hàm hỗ trợ: Lấy ID từ Texture
local function GetIDFromTexture(texture)
    return tostring(string.match(texture, "%d+$"))
end

-- Hàm hỗ trợ: Kiểm tra balo đầy
local function IsBackpackFull()
    if LocalPlayer.CoreStats and LocalPlayer.CoreStats:FindFirstChild("Pollen") and LocalPlayer.CoreStats:FindFirstChild("Capacity") then
        return LocalPlayer.CoreStats.Pollen.Value >= LocalPlayer.CoreStats.Capacity.Value
    end
    return false
end

-- Hàm hỗ trợ: Kiểm tra điểm trong Field
local function IsPointInField(point, fieldInfo)
    if not fieldInfo or not fieldInfo.Pos or not fieldInfo.Size then return false end
    local halfX = fieldInfo.Size.X / 2
    local halfZ = fieldInfo.Size.Z / 2
    local dx = math.abs(point.X - fieldInfo.Pos.X)
    local dz = math.abs(point.Z - fieldInfo.Pos.Z)
    return (dx <= halfX and dz <= halfZ)
end

-- Logic Tìm Token (Item > Token > Gần nhất)
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

-- CHỨC NĂNG FARM
local isFarming = false

function module.StartFarm(fieldName, LogFunc, Utils)
    -- Tải dữ liệu nếu chưa có
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

    -- Auto Dig
    task.spawn(function()
        while isFarming do
            VirtualUser:ClickButton1(Vector2.new())
            task.wait(0.2)
        end
    end)

    local Character = LocalPlayer.Character
    local Humanoid = Character:WaitForChild("Humanoid")
    local RootPart = Character:WaitForChild("HumanoidRootPart")

    -- Đến Field
    Utils.Tween(CFrame.new(fieldInfo.Pos + Vector3.new(0, 5, 0)), function() end)

    while isFarming do
        task.wait()
        
        -- Hồi sinh
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.CharacterAdded:Wait()
            Character = LocalPlayer.Character
            Humanoid = Character:WaitForChild("Humanoid")
            RootPart = Character:WaitForChild("HumanoidRootPart")
            Utils.Tween(CFrame.new(fieldInfo.Pos + Vector3.new(0, 5, 0)), function() end)
        end

        -- 1. Convert khi đầy
        if IsBackpackFull() then
            if LogFunc then LogFunc("🎒 Đầy Balo -> Về tổ...", Color3.fromRGB(255, 200, 0)) end
            
            local hives = Workspace:FindFirstChild("Honeycombs") or Workspace:FindFirstChild("Hives")
            local myHivePos = nil
            for _, hive in pairs(hives:GetChildren()) do
                if hive:FindFirstChild("Owner") and hive.Owner.Value == LocalPlayer then
                    if hive:FindFirstChild("SpawnPos") then
                        myHivePos = hive.SpawnPos.CFrame
                    end
                    break
                end
            end

            if myHivePos then
                Utils.Tween(myHivePos * CFrame.new(0, 0, 3), function() end)
                repeat
                    game:GetService("ReplicatedStorage").Events.PlayerHiveCommand:FireServer("ToggleHoneyMaking")
                    task.wait(2)
                until not IsBackpackFull() or not isFarming
                
                if LogFunc then LogFunc("✅ Convert xong -> Quay lại...", Color3.fromRGB(0, 255, 0)) end
                Utils.Tween(CFrame.new(fieldInfo.Pos + Vector3.new(0, 5, 0)), function() end)
            end
        end

        -- 2. Nhặt Token
        local targetToken = FindBestToken(fieldInfo)
        
        if targetToken then
            Humanoid:MoveTo(targetToken.Position)
            local timeout = 0
            while targetToken and targetToken.Parent and targetToken.Transparency == 0 and timeout < 20 do
                if (RootPart.Position - targetToken.Position).Magnitude < 4 then break end
                task.wait(0.1)
                timeout = timeout + 1
            end
        else
            -- 3. Farm ngẫu nhiên
            local rx = math.random(-fieldInfo.Size.X/2 + 5, fieldInfo.Size.X/2 - 5)
            local rz = math.random(-fieldInfo.Size.Z/2 + 5, fieldInfo.Size.Z/2 - 5)
            local dest = Vector3.new(fieldInfo.Pos.X + rx, fieldInfo.Pos.Y, fieldInfo.Pos.Z + rz)
            
            Humanoid:MoveTo(dest)
            local walkTime = 0
            while (RootPart.Position - dest).Magnitude > 4 and walkTime < 20 do
                task.wait(0.1)
                walkTime = walkTime + 1
                if FindBestToken(fieldInfo) then break end
            end
        end
    end
end

function module.StopFarm()
    isFarming = false
end

return module
