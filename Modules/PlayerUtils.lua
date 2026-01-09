local module = {}
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- =======================================================
-- HÀM LẤY SỐ LƯỢNG ITEM HIỆN CÓ
-- =======================================================
function module.GetItemAmount(itemName)
    -- Trong Bee Swarm, item thường nằm trong folder 'b' hoặc 'EggStats' của người chơi
    local inventory = LocalPlayer:FindFirstChild("b") -- Folder chứa items (Blueberry, Glue,...)
    local eggs = LocalPlayer:FindFirstChild("EggStats") -- Folder chứa trứng (Gold Egg, Silver Egg,...)
    
    -- 1. Tìm trong kho item thường
    if inventory then
        local item = inventory:FindFirstChild(itemName)
        if item then return item.Value end
    end

    -- 2. Tìm trong kho trứng (nếu item là trứng)
    if eggs then
        local egg = eggs:FindFirstChild(itemName)
        if egg then return egg.Value end
    end

    return 0 -- Không tìm thấy = 0
end

-- =======================================================
-- HÀM LẤY SỐ HONEY HIỆN CÓ
-- =======================================================
function module.GetHoney()
    if LocalPlayer:FindFirstChild("CoreStats") and LocalPlayer.CoreStats:FindFirstChild("Honey") then
        return LocalPlayer.CoreStats.Honey.Value
    end
    return 0
end

-- =======================================================
-- HÀM CHECK XEM ĐỦ TIỀN VÀ NGUYÊN LIỆU KHÔNG?
-- Input: 
--    price: Số Honey cần (Number)
--    ingredients: Danh sách nguyên liệu (Table dạng [["Glue", 5], ["Oil", 2]])
-- Output: 
--    true: Đủ hết
--    false: Thiếu gì đó (kèm thông báo)
-- =======================================================
function module.CanAfford(price, ingredients, LogFunc)
    -- 1. Check Tiền
    local myHoney = module.GetHoney()
    if price and myHoney < price then
        if LogFunc then LogFunc("Not enough Honey! Need: " .. price, Color3.fromRGB(255, 80, 80)) end
        return false
    end

    -- 2. Check Nguyên Liệu
    if ingredients then
        for _, req in pairs(ingredients) do
            local itemName = req[1]      -- Tên item (Ví dụ: "Glue")
            local amountNeed = req[2]    -- Số lượng cần (Ví dụ: 5)
            local amountHave = module.GetItemAmount(itemName)

            if amountHave < amountNeed then
                if LogFunc then 
                    LogFunc("Missing: " .. itemName .. " (" .. amountHave .. "/" .. amountNeed .. ")", Color3.fromRGB(255, 80, 80)) 
                end
                return false
            end
        end
    end

    return true
end

return module
