local module = {}

-- Giữ nguyên toạ độ Shop của bạn
local SHOPS = {
    Egg  = CFrame.new(-140.41, 4.69, 243.97),
    Tool = CFrame.new(84.88, 4.51, 290.49)
}

function module.Run(LogFunc, WaitFunc, Toolkit)
    -- BUNG TOOLKIT RA DÙNG
    local Utils = Toolkit.Utils
    local ShopUtils = Toolkit.ShopUtils
    local AutoFarm = Toolkit.AutoFarm
    local PlayerUtils = Toolkit.PlayerUtils
    local RedeemCode = Toolkit.RedeemCode
    local ClaimHive = Toolkit.ClaimHive
    
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Data = Utils.LoadData()

    -- 1. ƯU TIÊN TUYỆT ĐỐI: NHẬN TỔ & CODE
    if not ClaimHive.Run(LogFunc, WaitFunc, Utils) then
        -- Nếu chưa có tổ thì chưa làm gì cả
        return 
    end

    if not Data.RedeemDone then
        LogFunc("🎫 Redeem Codes...")
        RedeemCode.Run(LogFunc, WaitFunc, Utils)
        return -- Xong việc thì return để Main lặp lại
    end

    -- 2. LIST MỤC TIÊU (GIỮ NGUYÊN THỨ TỰ CỦA BẠN)
    -- Logic: Mua 2 trứng -> Mua Backpack -> Mua Rake
    
    -- === MỤC TIÊU 1: 2 CON ONG ===
    local currentBees = AutoFarm.GetRealBeeCount()
    if currentBees < 2 then
        LogFunc("🥚 Goal: Get 2 Bees ("..currentBees.."/2)")
        
        local eggPrice = 1000 -- Basic Egg
        if PlayerUtils.GetHoney() >= eggPrice then
            -- MUA
            LogFunc("💰 Buying Egg...")
            if AutoFarm.StopFarm then AutoFarm.StopFarm() end -- Dừng farm
            Utils.Tween(SHOPS.Egg)
            task.wait(1)
            ReplicatedStorage.Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"]="Basic", ["Amount"]=1, ["Category"]="Eggs"})
            task.wait(2)
        else
            -- FARM
            LogFunc("🌾 Farming for Egg...")
            -- Gọi AutoFarm (Main sẽ loop lại nên farm vẫn chạy)
            if not AutoFarm.IsFarming() then
                AutoFarm.StartFarm("Sunflower Field", LogFunc, Utils, Toolkit.FieldData, Toolkit.TokenData)
            end
        end
        return -- Xử lý xong 1 nhịp, return để Main check lại
    end

    -- === MỤC TIÊU 2 & 3: BACKPACK VÀ RAKE ===
    local toolsToBuy = {
        {Name = "Backpack", Price = 5500, Category = "Accessory"},
        {Name = "Rake",     Price = 800,  Category = "Collector"}
    }

    for _, tool in ipairs(toolsToBuy) do
        -- Kiểm tra đã có chưa
        if PlayerUtils.GetItemAmount(tool.Name) == 0 and not Data["Has_"..tool.Name] then
            LogFunc("🎯 Goal: " .. tool.Name)
            
            -- Dùng ShopUtils check cho chuẩn (cả nguyên liệu)
            local canBuy = ShopUtils.CheckBuy(tool.Name, LogFunc)
            
            if canBuy then
                -- MUA
                LogFunc("🛒 Buying " .. tool.Name)
                if AutoFarm.StopFarm then AutoFarm.StopFarm() end
                Utils.Tween(SHOPS.Tool)
                task.wait(1)
                ReplicatedStorage.Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"]=tool.Name, ["Category"]=tool.Category})
                Utils.SaveData("Has_"..tool.Name, true)
                task.wait(2)
            else
                -- FARM
                LogFunc("🌾 Farming for " .. tool.Name)
                if not AutoFarm.IsFarming() then
                    AutoFarm.StartFarm("Sunflower Field", LogFunc, Utils, Toolkit.FieldData, Toolkit.TokenData)
                end
            end
            return -- Tập trung 1 món thôi
        end
    end

    -- Nếu chạy xuống đây tức là đã xong hết
    LogFunc("✅ Starter Completed! Need to level up bees...")
    -- Farm tự do để chờ đủ 5 ong qua zone mới
    if currentBees < 5 then
        if not AutoFarm.IsFarming() then
            AutoFarm.StartFarm("Mushroom Field", LogFunc, Utils, Toolkit.FieldData, Toolkit.TokenData) -- Đổi bãi farm cho đổi gió
        end
    end
end

return module
