local module = {}
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- BIẾN TRẠNG THÁI
local isFarming = false
local currentField = nil

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
-- HÀM: TÌM FIELD TỐT NHẤT (Dựa trên FieldData)
-- ====================================================
function module.FindBestField(criteriaType, value, FieldData)
    local myBees = module.GetRealBeeCount()
    local bestField = nil
    local highestReq = -1
    local candidateFields = {}

    -- Logic map item sang field
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
    
    return bestField or "Sunflower Field" -- Mặc định nếu không tìm thấy
end

-- ====================================================
-- HÀM CHÍNH: BẮT ĐẦU FARM
-- fieldName: Tên cánh đồng (String)
-- Utils: Module Utilities (Để dùng hàm Tween, SaveData...)
-- FieldData: Module FieldData (Để lấy tọa độ)
-- TokenData: Module TokenData (Để biết ưu tiên nhặt cái gì)
-- ====================================================
function module.StartFarm(fieldName, Utils, FieldData, TokenData)
    if isFarming and currentField == fieldName then return end -- Đang farm đúng chỗ rồi thì thôi
    
    isFarming = true
    currentField = fieldName
    
    -- 1. Lấy thông tin Field
    local fInfo = FieldData[fieldName]
    if not fInfo then
        warn("❌ [AutoFarm] Không tìm thấy data của field: " .. tostring(fieldName))
        isFarming = false
        return
    end

    -- 2. Di chuyển đến Field
    if Utils and Utils.Tween then
        -- Tính toán vị trí đứng ngẫu nhiên trong field để tránh bị bot detect quá lộ
        local targetPos = CFrame.new(fInfo.Pos + Vector3.new(0, 5, 0)) 
        Utils.Tween(targetPos)
        task.wait(1)
    end

    -- 3. Vòng lặp Farm (Chạy ngầm)
    task.spawn(function()
        while isFarming do
            task.wait()
            
            -- A. Check nhân vật
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then task.wait(1); continue end
            local hrp = char.HumanoidRootPart

            -- B. Check đầy balo (Logic giả định, bạn cần code chuyển đổi mật ở đây hoặc trong Main)
            if LocalPlayer.CoreStats.Pollen.Value >= LocalPlayer.CoreStats.Capacity.Value then
                -- Nếu đầy, Main.lua sẽ lo việc gọi hàm Convert, ở đây ta chỉ pause hoặc tiếp tục farm
                -- Tạm thời cứ đứng đó
            end

            -- C. Tìm Token để nhặt (Dựa vào TokenData)
            local bestToken = nil
            local highestPriority = -1
            
            local tokensFolder = Workspace:FindFirstChild("Collectibles")
            if tokensFolder then
                for _, token in pairs(tokensFolder:GetChildren()) do
                    -- Check khoảng cách (chỉ nhặt trong field hoặc gần)
                    if (token.Position - fInfo.Pos).Magnitude < (fInfo.Size.X / 1.5) then
                        -- Check database
                        local textureId = token:FindFirstChild("Icon") and token.Icon.Texture
                        local tokenInfo = TokenData.Tokens[textureId]
                        
                        -- Mặc định priority là 1 nếu không có trong data
                        local priority = (tokenInfo and tokenInfo.Priority) or 1
                        
                        -- Token link hoặc rare item thì ưu tiên cực cao
                        if priority > highestPriority then
                            highestPriority = priority
                            bestToken = token
                        end
                    end
                end
            end

            -- D. Di chuyển tới Token hoặc đi loanh quanh
            if bestToken then
                hrp.CFrame = bestToken.CFrame
                task.wait(0.1) -- Delay nhỏ để server nhận
            else
                -- Auto Dig (Đào)
                if workspace:FindFirstChild(LocalPlayer.Name) then
                    local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                    if tool and tool:FindFirstChild("ClickEvent") then
                        tool.ClickEvent:FireServer()
                    end
                end
                
                -- Đi random trong field
                local randomX = math.random(-fInfo.Size.X/2, fInfo.Size.X/2)
                local randomZ = math.random(-fInfo.Size.Z/2, fInfo.Size.Z/2)
                local movePos = fInfo.Pos + Vector3.new(randomX, 0, randomZ)
                
                LocalPlayer.Character.Humanoid:MoveTo(movePos)
                task.wait(0.5)
            end
            
            -- Nếu bị lệnh Stop thì break
            if not isFarming then break end
        end
    end)
end

-- ====================================================
-- HÀM DỪNG FARM
-- ====================================================
function module.Stop()
    isFarming = false
    currentField = nil
    -- Dừng nhân vật lại
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:MoveTo(LocalPlayer.Character.HumanoidRootPart.Position)
    end
end

return module
