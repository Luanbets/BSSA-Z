local module = {}

-- ============================
-- CẤU HÌNH TỐC ĐỘ (ĐÃ SỬA: 100)
-- ============================
module.Speed = 100 

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- === HÀM TẠO TÊN FILE RIÊNG THEO USERNAME ===
local function GetSaveFileName()
    return "BSSA_Save_" .. LocalPlayer.Name .. ".json"
end

-- === CHỨC NĂNG LƯU/ĐỌC GAME ===
function module.LoadData()
    local fileName = GetSaveFileName()
    if isfile(fileName) then
        local success, result = pcall(function()
            return HttpService:JSONDecode(readfile(fileName))
        end)
        if success then return result end
    end
    -- Dữ liệu mặc định
    return {
        RedeemDone = false,
        Cotmoc1Done = false,
        Cotmoc1_Progress = 0
    }
end

function module.SaveData(key, value)
    local fileName = GetSaveFileName()
    local data = module.LoadData()
    data[key] = value
    writefile(fileName, HttpService:JSONEncode(data))
end

-- === HÀM TWEEN ===
function module.Tween(targetCFrame, WaitFunc)
    local TweenService = game:GetService("TweenService")
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local root = char.HumanoidRootPart
    
    if WaitFunc then WaitFunc() end
    
    local finalPos = targetCFrame.Position + Vector3.new(0, 5, 0)
    local dist = (finalPos - root.Position).Magnitude
    local time = dist / module.Speed 
    
    local tween = TweenService:Create(root, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = CFrame.new(finalPos)})
    local bv = Instance.new("BodyVelocity", root); bv.Velocity = Vector3.zero; bv.MaxForce = Vector3.one * math.huge
    tween:Play(); tween.Completed:Wait(); bv:Destroy(); root.Velocity = Vector3.zero
end

return module
