local module = {}
local TweenService = game:GetService("TweenService")
local LocalPlayer = game:GetService("Players").LocalPlayer

-- FILE SAVE SYSTEM
local FileName = "BSSA_Save_" .. LocalPlayer.Name .. ".json"
local HttpService = game:GetService("HttpService")

function module.LoadData()
    if isfile(FileName) then
        local success, result = pcall(function() return HttpService:JSONDecode(readfile(FileName)) end)
        if success then return result end
    end
    return {} -- Trả về bảng rỗng nếu chưa có dữ liệu
end

function module.SaveData(key, value)
    local data = module.LoadData()
    data[key] = value
    writefile(FileName, HttpService:JSONEncode(data))
end

-- TWEEN MOVE
function module.Tween(targetCFrame, WaitFunc)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local root = LocalPlayer.Character.HumanoidRootPart
    local dist = (root.Position - targetCFrame.Position).Magnitude
    local speed = 100 -- Tốc độ bay
    
    local info = TweenInfo.new(dist / speed, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(root, info, {CFrame = targetCFrame})
    tween:Play()
    tween.Completed:Wait()
end

return module
