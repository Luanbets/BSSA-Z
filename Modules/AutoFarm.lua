local module = {}
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- BIẾN TRẠNG THÁI (State)
local isFarming = false
local currentField = nil
local farmLoopConnection = nil

-- ====================================================
-- HÀM HỖ TRỢ: ĐẾM ONG THỰC TẾ
-- ====================================================
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

-- ====================================================
-- HÀM: TÌM FIELD TỐT NHẤT (Logic thuần túy)
-- Manage Script (Starter) sẽ gọi hàm này để hỏi, sau đó mới ra lệnh Farm
-- ====================================================
function module.FindBestField(criteriaType, value, FieldData)
    local myBees = module.GetRealBeeCount()
    local bestField = nil
    local highestReq = -1
    local candidateFields = {}

    local MaterialMap = {
        ["Blueberry"]  = {"Blue Flower Field", "Bamboo Field", "Pine Tree Forest", "Stump Field"},
        ["Strawberry"] = {"Strawberry Field", "Mushroom Field", "Rose Field", "Pepper Patch"},
        ["Sunflower"]  = {"Sunflower Field"},
        ["Pineapple"]  = {"Pineapple Patch"},
        ["Pumpkin"]    = {"Pumpkin Patch"},
        ["Cactus"]     = {"Cactus Field"},
        ["Honey"]      = {"Sunflower Field", "Dandelion Field", "Blue Flower Field", "Mushroom Field", "Clover Field", "Bamboo Field", "Spider Field", "Strawberry Field"}
    }

    if criteriaType == "Honey" then
        for name, _ in pairs(FieldData) do table.insert(candidateFields, name) end
    elseif criteriaType == "Material" then
        candidateFields = MaterialMap[value] or {}
    elseif criteriaType == "Color" then
        for name, data in pairs(FieldData) do
            if data.Color == value then table.insert(candidateFields, name) end
        end
    end

    for _, fieldName in pairs(candidateFields) do
        local data = FieldData[fieldName]
        if data and myBees >= (data.ReqBees or 0) then
            if (data.ReqBees or 0) > highestReq then
                highestReq = (data.ReqBees or 0)
                bestField = fieldName
            end
        end
    end
    
    return bestField or "Sunflower Field"
end

-- ====================================================
-- HÀM CHÍNH: BẮT ĐẦU FARM (Nghe lệnh từ Manager)
-- ====================================================
function module.StartFarm(fieldName, Utils, FieldData, TokenData)
    if isFarming and currentField == fieldName then return end -- Đang farm đúng chỗ thì thôi
    
    -- Reset trạng thái cũ
    module.Stop()
    
    isFarming = true
    currentField = fieldName
    
    -- 1. Lấy thông tin Field
    local fInfo = FieldData[fieldName]
    if not fInfo then
        warn("❌ [AutoFarm] Không tìm thấy data của field: " .. tostring(fieldName))
        isFarming = false
        return
    end

    print("🚜 AutoFarm: Bắt đầu cày tại " .. fieldName)

    -- 2. Di chuyển đến Field (Dùng Utils của Main)
    if Utils and Utils.Tween then
        -- Random nhẹ vị trí đứng để đỡ bị máy chủ nghi ngờ
        local offset = Vector3.new(math.random(-10,10), 5, math.random(-10,10))
        Utils.Tween(CFrame.new(fInfo.Pos + offset))
        task.wait(1)
    end

    -- 3. Vòng lặp Farm (Sử dụng Task để chạy ngầm)
    task.spawn(function()
        while isFarming do
            task.wait() -- Chạy nhanh nhất có thể
            
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then 
                task.wait(1)
                continue 
            end
            local hrp = char.HumanoidRootPart

            -- A. Tự động click chuột (Đào)
            local tool = char:FindFirstChildOfClass("Tool")
            if tool and tool:FindFirstChild("ClickEvent") then
                tool.ClickEvent:FireServer()
            end

            -- B. Logic nhặt Token (Dựa trên TokenData)
            local bestToken = nil
            local bestPriority = -1
            local closestDist = 9999

            local tokensFolder = Workspace:FindFirstChild("Collectibles")
            if tokensFolder then
                for _, token in pairs(tokensFolder:GetChildren()) do
                    -- Chỉ nhặt token gần field mình đang đứng
                    local dist = (token.Position - fInfo.Pos).Magnitude
                    if dist < (fInfo.Size.X / 1.2) then -- Trong phạm vi field
                        
                        -- Lấy ID hình ảnh để so sánh với TokenData
                        local textureId = token:FindFirstChild("Icon") and token.Icon.Texture
                        
                        -- Mặc định độ ưu tiên là 1
                        local priority = 1 
                        
                        if TokenData and TokenData.Tokens[textureId] then
                            priority = TokenData.Tokens[textureId].Priority
                        end
                        
                        -- Logic chọn: Ưu tiên cao nhất -> Gần nhất
                        if priority > bestPriority then
                            bestPriority = priority
                            bestToken = token
                            closestDist = (hrp.Position - token.Position).Magnitude
                        elseif priority == bestPriority then
                            local d = (hrp.Position - token.Position).Magnitude
                            if d < closestDist then
                                closestDist = d
                                bestToken = token
                            end
                        end
                    end
                end
            end

            -- C. Di chuyển
            if bestToken then
                -- Bay tới token
                hrp.CFrame = CFrame.new(bestToken.Position)
                -- Nếu là token xịn (Priority >= 100), đợi xíu cho chắc ăn
                if bestPriority >= 100 then task.wait(0.1) end
            else
                -- Không có token thì đi bộ ngẫu nhiên trong vùng farm
                local randomX = math.random(-fInfo.Size.X/3, fInfo.Size.X/3)
                local randomZ = math.random(-fInfo.Size.Z/3, fInfo.Size.Z/3)
                local targetMove = fInfo.Pos + Vector3.new(randomX, 0, randomZ)
                
                char.Humanoid:MoveTo(targetMove)
                task.wait(0.5)
            end
            
            -- D. Nếu đầy balo (Cơ bản)
            if LocalPlayer.CoreStats.Pollen.Value >= LocalPlayer.CoreStats.Capacity.Value then
                 -- Tạm thời chỉ convert tại chỗ (Honey Bee) hoặc đứng im
                 -- Logic về Hive convert sẽ nằm ở script Manager hoặc hàm Convert riêng
            end
        end
    end)
end

-- ====================================================
-- HÀM DỪNG FARM
-- ====================================================
function module.Stop()
    if isFarming then
        print("🛑 AutoFarm: Đã dừng lại.")
        isFarming = false
        currentField = nil
        -- Dừng nhân vật
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid:MoveTo(LocalPlayer.Character.HumanoidRootPart.Position)
        end
    end
end

return module
