local module = {}
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local isFarming = false
local currentField = nil

-- =========================================================
-- HÀM HỖ TRỢ (PUBLIC CHO MAIN DÙNG)
-- =========================================================
function module.IsFarming() return isFarming end

function module.GetRealBeeCount()
    local honeycombs = Workspace:FindFirstChild("Honeycombs") or Workspace:FindFirstChild("Hives")
    if not honeycombs then return 0 end
    for _, hive in pairs(honeycombs:GetChildren()) do
        if hive:FindFirstChild("Owner") and hive.Owner.Value == LocalPlayer then
            local cells = hive:FindFirstChild("Cells")
            if cells then
                local count = 0
                for _, cell in pairs(cells:GetChildren()) do
                    if cell:IsA("Model") and string.sub(cell.Name, 1, 1) == "C" then
                        local typeVal = cell:FindFirstChild("CellType")
                        if typeVal and typeVal.Value ~= "Empty" and typeVal.Value ~= 0 then count = count + 1 end
                    end
                end
                return count
            end
        end
    end
    return 0
end

-- =========================================================
-- HÀM FARM CHÍNH (Đã đồng bộ)
-- =========================================================
function module.StartFarm(fieldName, LogFunc, Utils, FieldData, TokenData)
    -- Nếu đang farm đúng chỗ rồi thì thôi không reset lại
    if isFarming and currentField == fieldName then return end
    
    module.StopFarm() -- Reset trước khi chạy mới
    isFarming = true
    currentField = fieldName
    
    -- Lấy data từ biến truyền vào (KHÔNG TẢI LẠI)
    local fieldInfo = FieldData[fieldName]
    if not fieldInfo then
        if LogFunc then LogFunc("❌ AutoFarm: Invalid Field " .. tostring(fieldName)) end
        isFarming = false
        return
    end

    if LogFunc then LogFunc("🚜 AutoFarm: " .. fieldName) end

    -- Di chuyển đến bãi
    Utils.Tween(CFrame.new(fieldInfo.Pos + Vector3.new(0, 5, 0)), function() end)
    
    -- Vòng lặp Farm (Chạy trên luồng riêng để không chặn Main)
    task.spawn(function()
        while isFarming do
            RunService.Heartbeat:Wait()
            local Character = LocalPlayer.Character
            if not Character or not Character:FindFirstChild("HumanoidRootPart") then task.wait(1) continue end
            
            local Humanoid = Character:FindFirstChild("Humanoid")
            local RootPart = Character:FindFirstChild("HumanoidRootPart")

            -- 1. Auto Dig
            pcall(function() ReplicatedStorage.Events.ToolCollect:FireServer() end)

            -- 2. Logic Balo Đầy (Convert)
            if LocalPlayer.CoreStats.Pollen.Value >= LocalPlayer.CoreStats.Capacity.Value then
                -- Logic quay về tổ (như code cũ của bạn)
                -- ... Bạn có thể copy lại đoạn convert Hive ở đây ...
                -- Tạm thời tôi để nó đứng im convert mật tại chỗ (Dùng Honey Bee nếu có) hoặc chạy về
                 ReplicatedStorage.Events.PlayerHiveCommand:FireServer("ToggleHoneyMaking")
                 task.wait(10) -- Giả lập thời gian convert
            end

            -- 3. Tìm Token (Sử dụng TokenData được truyền vào)
            -- Code tìm token ở đây giữ nguyên logic của bạn nhưng dùng TokenData.Tokens
            -- Ví dụ:
            local bestToken = nil
            local bestPrio = 0
            
            local cols = Workspace:FindFirstChild("Collectibles")
            if cols then
                for _, v in pairs(cols:GetChildren()) do
                    if (v.Position - fieldInfo.Pos).Magnitude < (fieldInfo.Size.X/1.5) and v.Transparency == 0 then
                        local tex = v:FindFirstChild("FrontDecal") and v.FrontDecal.Texture
                        -- Chuẩn hóa ID texture
                        local id = string.match(tex or "", "%d+$")
                        local fullId = "rbxassetid://" .. (id or "")
                        
                        local info = TokenData.Tokens[fullId]
                        local prio = (info and info.Priority) or 1
                        
                        if prio > bestPrio then
                            bestPrio = prio
                            bestToken = v
                        end
                    end
                end
            end

            -- 4. Di chuyển
            if bestToken then
                Humanoid:MoveTo(bestToken.Position)
            else
                -- Đi random
                local rx = math.random(-20, 20)
                local rz = math.random(-20, 20)
                Humanoid:MoveTo(fieldInfo.Pos + Vector3.new(rx, 0, rz))
                task.wait(0.5)
            end
        end
    end)
end

function module.StopFarm()
    isFarming = false
    currentField = nil
end

return module
