local module = {}

-- Nhận Utils từ Main truyền vào
function module.Run(LogFunc, WaitFunc, Utils)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local StarterGui = game:GetService("StarterGui")

    local function GetSpawnPosCFrame(spawnObj)
        if not spawnObj then return nil end
        if spawnObj:IsA("CFrameValue") then return spawnObj.Value
        elseif spawnObj:IsA("BasePart") then return spawnObj.CFrame
        else return nil end
    end

    local honeycombs = workspace:FindFirstChild("Honeycombs") or workspace:FindFirstChild("Hives")
    if not honeycombs then return false end

    for _, hive in pairs(honeycombs:GetChildren()) do
        WaitFunc()
        if hive:FindFirstChild("Owner") and (hive.Owner.Value == "" or hive.Owner.Value == nil) then
            local hiveID = hive.HiveID.Value
            local targetCF = GetSpawnPosCFrame(hive.SpawnPos)
            if targetCF then
                -- Log Gọn
                LogFunc("Claiming Hive " .. hiveID .. "...", Color3.fromRGB(255, 220, 0))
                
                -- Dùng Utils để bay (Chỉnh tốc độ tập trung ở file Utils)
                Utils.Tween(targetCF, WaitFunc)
                
                task.wait(1.5)
                WaitFunc()
                ReplicatedStorage.Events.ClaimHive:FireServer(hiveID)
                task.wait(1)
                
                LogFunc("Hive Claimed", Color3.fromRGB(0, 255, 0))
                StarterGui:SetCore("SendNotification", {Title="System", Text="Hive Claimed", Duration=3})
                return true
            end
        end
    end

    LogFunc("No Empty Hive", Color3.fromRGB(255, 80, 80))
    return false
end

return module
