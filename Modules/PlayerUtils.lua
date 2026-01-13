local module = {}
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- =======================================================
-- 1. HÀM ĐẾM SỐ ONG THỰC TẾ (CỰC QUAN TRỌNG)
-- Giúp script biết đã đủ điều kiện qua cổng chưa
-- =======================================================
function module.GetBeeCount()
    local honeycombs = Workspace:FindFirstChild("Honeycombs") or Workspace:FindFirstChild("Hives")
    if not honeycombs then return 0 end

    -- A. Tìm Hive của mình
    local myHive = nil
    for _, hive in pairs(honeycombs:GetChildren()) do
        if hive:FindFirstChild("Owner") and hive.Owner.Value == LocalPlayer then
            myHive = hive
            break
        end
    end

    -- B. Đếm số slot ong đã nở
    if myHive then
        local cellsFolder = myHive:FindFirstChild("Cells")
        if cellsFolder then
            local count = 0
            for _, cell in pairs(cellsFolder:GetChildren()) do
                -- Cell phải là Model và không phải là Empty
                if cell:IsA("Model") then
                    local cellType = cell:FindFirstChild("CellType")
                    if cellType and cellType.Value ~= "Empty" and cellType.Value ~= 0 then
                        count = count + 1
                    end
                end
            end
            return count
        end
    end
    
    return 0 -- Không tìm thấy hive hoặc không có ong
end

-- =======================================================
-- 2. HÀM LẤY SỐ LƯỢNG ITEM (Sạch gọn)
-- =======================================================
function module.GetItemAmount(itemName)
    -- Ưu tiên 1: Kho đồ thường (b)
    local inventory = LocalPlayer:FindFirstChild("b")
    if inventory and inventory:FindFirstChild(itemName) then
        return inventory[itemName].Value
    end

    -- Ưu tiên 2: Kho trứng (EggStats)
    local eggs = LocalPlayer:FindFirstChild("EggStats")
    if eggs and eggs:FindFirstChild(itemName) then
        return eggs[itemName].Value
    end

    -- Ưu tiên 3: CoreStats (Đôi khi vé ticket nằm ở đây)
    local core = LocalPlayer:FindFirstChild("CoreStats")
    if core and core:FindFirstChild(itemName) then
        return core[itemName].Value
    end

    return 0 -- Không có trả về 0
end

-- =======================================================
-- 3. HÀM LẤY HONEY
-- =======================================================
function module.GetHoney()
    if LocalPlayer:FindFirstChild("CoreStats") and LocalPlayer.CoreStats:FindFirstChild("Honey") then
        return LocalPlayer.CoreStats.Honey.Value
    end
    return 0
end

return module
