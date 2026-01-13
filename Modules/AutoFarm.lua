local module = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Nhận TokenData từ Main truyền vào hoặc tự load (ở đây Main sẽ truyền)
local TokenDataDB = nil 
local isFarming = false

-- Hàm hỗ trợ
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
-- Tools chứa: {Field, TokenData, Utils, Player, Log}
function module.StartFarm(fieldName, Tools)
    if isFarming then return end -- Đang farm thì thôi
    isFarming = true
    
    local FieldInfo = Tools.Field[fieldName]
    local Utils = Tools.Utils
    local Log = Tools.Log
    
    if not FieldInfo then 
        Log("❌ AutoFarm: Unknown Field " .. fieldName, Color3.fromRGB(255, 0, 0))
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
            
            -- 2. Auto Convert (Nếu đầy)
            if Tools.Player.GetHoney() >= (LocalPlayer.CoreStats.Capacity.Value * 0.95) then
                 Log("🎒 Backpack Full -> Converting...", Color3.fromRGB(255, 200, 0))
                 -- Code về tổ convert (giữ nguyên logic cũ của bạn hoặc gọi hàm convert riêng)
                 -- Ở đây tôi giả lập chờ convert:
                 task.wait(10) 
                 -- Quay lại field
                 Utils.Tween(CFrame.new(FieldInfo.Pos + Vector3.new(0,5,0)), task.wait)
            end

            -- 3. Tìm Token xịn nhất (Dựa trên TokenData)
            local Character = LocalPlayer.Character
            if Character and Character:FindFirstChild("Humanoid") then
                -- Logic tìm token dùng Tools.TokenData (bạn tự tích hợp phần tìm token cũ vào đây)
                -- ...
                
                -- Random Move nếu không có token
                local rx = math.random(-FieldInfo.Size.X/2 + 5, FieldInfo.Size.X/2 - 5)
                local rz = math.random(-FieldInfo.Size.Z/2 + 5, FieldInfo.Size.Z/2 - 5)
                Character.Humanoid:MoveTo(FieldInfo.Pos + Vector3.new(rx, 0, rz))
            end
            
            task.wait(0.1)
        end
    end)
end

return module
