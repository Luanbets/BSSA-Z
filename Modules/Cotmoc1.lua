local module = {}

-- Tọa độ Shop (Giữ nguyên như của bạn)
local SHOPS = {
    Egg  = CFrame.new(-140.41, 4.69, 243.97),
    Tool = CFrame.new(84.88, 4.51, 290.49)
}

function module.Run(Toolkit)
    -- 1. BUNG TOOLKIT (Lấy đồ nghề từ Main)
    local Utils = Toolkit.Utils
    local ShopUtils = Toolkit.ShopUtils
    local AutoFarm = Toolkit.AutoFarm
    local PlayerUtils = Toolkit.PlayerUtils
    local RedeemCode = Toolkit.RedeemCode -- Lấy worker nhập code
    
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    -- 2. HÀM HỖ TRỢ: MUA ITEM (Tự bay đến shop và mua)
    local function GoBuy(shopType, category, itemType, logText)
        -- Dừng Farm
        if AutoFarm.Stop then AutoFarm.Stop() end
        task.wait(0.5)

        -- Bay đến Shop
        local pos = (shopType == "Egg") and SHOPS.Egg or SHOPS.Tool
        Utils.Tween(pos)
        task.wait(1)

        -- Mua
        print("🛒 Đang mua: " .. logText)
        game:GetService("ReplicatedStorage").Events.ItemPackageEvent:InvokeServer("Purchase", {
            ["Type"] = itemType, 
            ["Category"] = category,
            ["Amount"] = 1
        })
        task.wait(1.5)
    end

    -- ==========================================================
    -- BƯỚC 0: NHẬP CODE (Ưu tiên số 1 - Chạy xong mới làm việc khác)
    -- ==========================================================
    local data = Utils.LoadData()
    if not data.RedeemDone then
        print("🎫 Bắt đầu nhập Code tân thủ...")
        if RedeemCode then 
            RedeemCode.Run(print, task.wait, Utils) -- Chạy worker nhập code
        end
        -- Sau khi nhập xong, return để Main refresh lại tiền nong
        return 
    end

    -- ==========================================================
    -- BƯỚC 1: MUA TRỨNG (Mục tiêu: Có 2 con ong)
    -- ==========================================================
    local currentBees = AutoFarm.GetRealBeeCount()
    if currentBees < 2 then
        print("🥚 Mục tiêu: Mua trứng (Hiện có: " .. currentBees .. "/2)")
        
        -- Check tiền (Giá trứng Basic là 1000 hoặc tùy server, mình check dư ra tí cho chắc)
        local price = 1000 
        local myHoney = PlayerUtils.GetHoney()

        if myHoney >= price then
            GoBuy("Egg", "Eggs", "Basic", "Basic Egg")
            return -- Mua xong return để Main check lại số ong
        else
            print("📉 Thiếu tiền mua trứng ("..myHoney.."/"..price.."). Đi cày...")
            -- Gọi AutoFarm
            Toolkit.AutoFarm.StartFarm("Sunflower Field", Utils, Toolkit.FieldData, Toolkit.TokenData)
            return
        end
    end

    -- ==========================================================
    -- BƯỚC 2: MUA DỤNG CỤ (Theo thứ tự: Backpack -> Rake)
    -- ==========================================================
    
    -- Danh sách việc cần làm tiếp theo (Đúng thứ tự bạn yêu cầu)
    local ItemsToBuy = {
        {Name = "Backpack", Category = "Accessory", Price = 5500}, -- Cần chỉnh lại giá nếu sai
        {Name = "Rake",     Category = "Collector", Price = 800}   -- Cần chỉnh lại giá nếu sai
    }

    for _, item in ipairs(ItemsToBuy) do
        -- Kiểm tra đã có món này chưa
        local hasItem = PlayerUtils.GetItemAmount(item.Name) > 0 or data["Has_"..item.Name]
        
        -- Nếu chưa có -> Đây là mục tiêu hiện tại
        if not hasItem then
            print("🎯 Mục tiêu hiện tại: " .. item.Name)
            
            -- Dùng ShopUtils để check tiền chuẩn xác (nó check cả nguyên liệu nếu cần)
            local canBuy = ShopUtils.CheckBuy(item.Name, print)
            
            if canBuy then
                -- ĐỦ TIỀN -> ĐI MUA
                GoBuy("Tool", item.Category, item.Name, item.Name)
                Utils.SaveData("Has_"..item.Name, true) -- Lưu lại là đã mua
                return
            else
                -- THIẾU TIỀN -> ĐI FARM
                print("🌾 Chưa đủ tiền mua " .. item.Name .. ". Đang Auto Farm...")
                
                -- Tìm bãi farm tốt nhất (Logic cũ: Sunflower cho dễ)
                Toolkit.AutoFarm.StartFarm("Sunflower Field", Utils, Toolkit.FieldData, Toolkit.TokenData)
                return
            end
        end
    end

    -- ==========================================================
    -- HOÀN THÀNH COTMOC1
    -- ==========================================================
    -- Nếu chạy xuống tới đây nghĩa là: Đã nhập code, đủ 2 ong, có Backpack, có Rake.
    print("🎉 Đã hoàn thành Cột Mốc 1 (Starter)!")
    Utils.SaveData("Cotmoc1Done", true)
    
    -- Lúc này Main.lua sẽ thấy bee >= 2 (hoặc điều kiện khác) để chuyển script
    -- Nhưng nếu Main yêu cầu 5 ong mới qua zone mới, bạn có thể thêm logic mua trứng tiếp ở đây.
end

return module
