local module = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- HÀM TÌM TỌA ĐỘ (ĐÃ FIX CHUẨN)
-- Đưa nó vào trong này để tái sử dụng nội bộ
local function GetEmptySlotCoords()
    local honeycombs = workspace:FindFirstChild("Honeycombs") or workspace:FindFirstChild("Hives")
    local myHive = nil
    
    -- 1. Tìm Hive
    if honeycombs then
        for _, hive in pairs(honeycombs:GetChildren()) do
            if hive:FindFirstChild("Owner") and hive.Owner.Value == LocalPlayer then
                myHive = hive
                break
            end
        end
    end
    
    if not myHive then return nil, nil end 
    
    -- 2. Quét tọa độ C{x},{y}
    for y = 1, 7 do -- Quét từ hàng 1 lên 7
        for x = 1, 5 do -- Quét từ cột 1 sang 5
            local slotName = "C" .. x .. "," .. y
            local cell = myHive.Cells:FindFirstChild(slotName)
            
            if cell then
                -- Check trống
                local cType = cell:FindFirstChild("CellType")
                if not cType or (cType.Value == "Empty" or cType.Value == 0) then
                    return x, y -- Trả về tọa độ ngay khi thấy
                end
            end
        end
    end
    
    return nil, nil -- Full tổ
end

-- HÀM CHẠY CHÍNH
-- Tham số: eggName (mặc định "Basic"), amount (mặc định 1)
function module.Run(eggName, amount)
    eggName = eggName or "Basic"
    amount = amount or 1
    
    local x, y = GetEmptySlotCoords()
    
    if x and y then
        -- Gửi remote chuẩn tọa độ
        -- Arg 4: Amount (số lượng), Arg 5: IsGifted (false)
        ReplicatedStorage.Events.ConstructHiveCellFromEgg:InvokeServer(x, y, eggName, amount, false)
        return true, "Success at (" .. x .. "," .. y .. ")"
    else
        return false, "Hive Full"
    end
end

return module
