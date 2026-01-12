local module = {}

function module.Run(LogFunc, WaitFunc, Utils)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local honeycombs = workspace:FindFirstChild("Honeycombs") or workspace:FindFirstChild("Hives")

    if not honeycombs then return false end

    -- 1. KIỂM TRA XEM ĐÃ CÓ TỔ CHƯA (QUAN TRỌNG)
    for _, hive in pairs(honeycombs:GetChildren()) do
        if hive:FindFirstChild("Owner") and hive.Owner.Value == LocalPlayer then
            -- Đã có tổ rồi!
            return true 
        end
    end

    -- 2. NẾU CHƯA CÓ -> ĐI TÌM TỔ TRỐNG
    LogFunc("Searching for empty hive...")
    
    for _, hive in pairs(honeycombs:GetChildren()) do
        if hive:FindFirstChild("Owner") and (hive.Owner.Value == nil or hive.Owner.Value == "") then
            local hiveID = hive.HiveID.Value
            local spawnPos = hive:FindFirstChild("SpawnPos")
            
            if spawnPos then
                local pos = spawnPos.Value -- CFrameValue
                
                -- Bay tới tổ
                LogFunc("Claiming Hive " .. hiveID .. "...")
                Utils.Tween(pos)
                task.wait(1)
                
                -- Gửi lệnh nhận
                ReplicatedStorage.Events.ClaimHive:FireServer(hiveID)
                task.wait(1)
                
                -- Check lại xem nhận được chưa
                if hive.Owner.Value == LocalPlayer then
                    LogFunc("✅ Hive Claimed!")
                    return true
                end
            end
        end
    end

    LogFunc("❌ No Hive Available!")
    return false
end

return module
