local module = {}
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- 1. CẤU HÌNH TỐC ĐỘ (Chỉnh tất cả ở đây)
-- ==========================================
local CONFIG = {
    TweenSpeed = 100,   -- Tốc độ bay (Càng cao càng nhanh)
    WalkSpeed  = 150     -- Tốc độ chạy bộ (Mặc định 16, Hack là 80)
}

-- FILE SAVE SYSTEM
local FileName = "BSSA_Save_" .. LocalPlayer.Name .. ".json"

function module.LoadData()
    if isfile(FileName) then
        local success, result = pcall(function() 
            return HttpService:JSONDecode(readfile(FileName)) 
        end)
        if success then return result end
    end
    return {} 
end

function module.SaveData(key, value)
    local data = module.LoadData()
    data[key] = value
    writefile(FileName, HttpService:JSONEncode(data))
end

-- ==========================================
-- 2. HÀM BAY (TWEEN)
-- ==========================================
function module.Tween(targetCFrame, WaitFunc)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local root = LocalPlayer.Character.HumanoidRootPart
    local dist = (root.Position - targetCFrame.Position).Magnitude
    
    -- Lấy tốc độ từ CONFIG ở trên
    local speed = CONFIG.TweenSpeed 
    
    local info = TweenInfo.new(dist / speed, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(root, info, {CFrame = targetCFrame})
    
    tween:Play()
    tween.Completed:Wait()
    -- (Đã xóa dòng return lỗi)
end

-- ==========================================
-- 3. HÀM ĐỒNG BỘ TỐC ĐỘ CHẠY (Gọi bên AutoFarm)
-- ==========================================
function module.SyncWalkSpeed()
    local Char = LocalPlayer.Character
    if Char and Char:FindFirstChild("Humanoid") then
        -- Nếu tốc độ đang chậm hơn mức cài đặt thì tăng lên
        if Char.Humanoid.WalkSpeed < CONFIG.WalkSpeed then
            Char.Humanoid.WalkSpeed = CONFIG.WalkSpeed
        end
    end
end

return module
