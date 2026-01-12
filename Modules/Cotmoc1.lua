local module = {}
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

function module.Run(LogFunc, WaitFunc, Utils)
    -- Tìm folder chứa tổ ong (Hỗ trợ cả tên cũ và mới nếu game update)
    local honeycombs = Workspace:FindFirstChild("Honeycombs") or Workspace:FindFirstChild("Hives")
    
    if not honeycombs then 
        if LogFunc then LogFunc("❌ Không tìm thấy folder Honeycombs!", Color3.fromRGB(255, 0, 0)) end
        return false 
    end

    -- =======================================================================
    -- BƯỚC 1: KIỂM TRA XEM MÌNH ĐÃ CÓ TỔ CHƯA? (LOGIC GIỐNG AUTOFARM)
    -- =======================================================================
    for _, hive in pairs(honeycombs:GetChildren()) do
        -- Kiểm tra kỹ thuộc tính Owner
        if hive:FindFirstChild("Owner") and hive.Owner.Value == LocalPlayer then
            if LogFunc then 
                LogFunc("✅ Đã sở hữu Hive ID: " .. tostring(hive.HiveID.Value), Color3.fromRGB(0, 255, 0)) 
            end
            return true -- >> ĐÃ CÓ TỔ -> TRẢ VỀ TRUE NGAY
        end
    end

    -- =======================================================================
    -- BƯỚC 2: NẾU CHƯA CÓ -> ĐI TÌM TỔ TRỐNG ĐỂ CLAIM
    -- =======================================================================
    if LogFunc then LogFunc("🔍 Đang tìm tổ trống...", Color3.fromRGB(255, 255, 0)) end
    
    for _, hive in pairs(honeycombs:GetChildren()) do
        -- Tìm tổ chưa có chủ (Value là nil hoặc rỗng)
        if hive:FindFirstChild("Owner") and (hive.Owner.Value == nil or hive.Owner.Value == "") then
            local hiveID = hive:FindFirstChild("HiveID") and hive.HiveID.Value
            local spawnPos = hive:FindFirstChild("SpawnPos")
            
            if spawnPos then
                -- Lấy tọa độ chuẩn (Xử lý cả trường hợp là Part hoặc CFrameValue)
                local targetPos = nil
                if spawnPos:IsA("CFrameValue") then 
                    targetPos = spawnPos.Value
                elseif spawnPos:IsA("BasePart") then 
                    targetPos = spawnPos.CFrame 
                end
                
                if targetPos then
                    -- >> THỰC HIỆN CLAIM
                    if LogFunc then LogFunc("🏃 Đang nhận tổ số " .. tostring(hiveID) .. "...", Color3.fromRGB(255, 200, 0)) end
                    
                    if Utils and Utils.Tween then
                        Utils.Tween(targetPos, WaitFunc)
                    end
                    task.wait(1)
                    
                    -- Gửi lệnh nhận tổ
                    ReplicatedStorage.Events.ClaimHive:FireServer(hiveID)
                    task.wait(1)
                    
                    -- Check lại ngay lập tức xem đã nhận được chưa
                    if hive.Owner.Value == LocalPlayer then
                        if LogFunc then LogFunc("✅ Nhận tổ thành công!", Color3.fromRGB(0, 255, 0)) end
                        return true
                    end
                end
            end
        end
    end

    if LogFunc then LogFunc("❌ Không còn tổ trống nào!", Color3.fromRGB(255, 0, 0)) end
    return false
end

return module
