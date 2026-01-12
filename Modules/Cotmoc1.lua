local module = {}

-- Tọa độ Shop (Giữ nguyên)
local SHOPS = {
    Egg  = CFrame.new(-140.41, 4.69, 243.97),
    Tool = CFrame.new(84.88, 4.51, 290.49)
}

function module.Run(LogFunc, WaitFunc, Toolkit)
    -- BUNG TOOLKIT RA
    local Utils = Toolkit.Utils
    local ShopUtils = Toolkit.ShopUtils
    local AutoFarm = Toolkit.AutoFarm
    local PlayerUtils = Toolkit.PlayerUtils
    local RedeemCode = Toolkit.RedeemCode
    
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Data = Utils.LoadData()

    -- ==========================================================
    -- 1. NHẬP CODE (Ưu tiên số 1)
    -- ==========================================================
    if not Data.RedeemDone then
        LogFunc("🎫 Redeeming Codes...", Color3.fromRGB(255, 0, 255))
        RedeemCode.Run(LogFunc, WaitFunc, Utils)
        return -- Return để Main refresh lại
    end

    -- ==========================================================
    -- 2. LOGIC MUA SẮM (Egg -> Backpack -> Rake)
    -- ==========================================================
    local currentBees = AutoFarm.GetRealBeeCount()
    
    -- A. MỤC TIÊU: 2 CON ONG
    if currentBees < 2 then
        LogFunc("🥚 Goal: Get 2 Bees ("..currentBees.."/2)", Color3.fromRGB(255, 255, 0))
        local eggPrice = 1000 
        
        -- Check tiền
        if PlayerUtils.GetHoney() >= eggPrice then
            -- >> MUA
            LogFunc("💰 Buying Egg...", Color3.fromRGB(0, 255, 0))
            if AutoFarm.StopFarm then AutoFarm.StopFarm() end -- Dừng farm để đi mua
            Utils.Tween(SHOPS.Egg, WaitFunc)
            task.wait(1)
            ReplicatedStorage.Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"]="Basic", ["Amount"]=1, ["Category"]="Eggs"})
            task.wait(3) -- Đợi server xử lý
        else
            -- >> FARM
            LogFunc("🌾 Farming Honey for Egg...", Color3.fromRGB(255, 150, 0))
            if not AutoFarm.IsFarming() then
                AutoFarm.StartFarm("Sunflower Field", LogFunc, Utils, Toolkit.FieldData, Toolkit.TokenData)
            end
        end
        return -- Xử lý xong 1 nhịp thì return
    end

    -- B. MỤC TIÊU: MUA DỤNG CỤ
    local toolsToBuy = {
        {Name = "Backpack", Price = 5500, Category = "Accessory"},
        {Name = "Rake",     Price = 800,  Category = "Collector"}
    }

    for _, tool in ipairs(toolsToBuy) do
        -- Nếu chưa có item này
        if PlayerUtils.GetItemAmount(tool.Name) == 0 and not Data["Has_"..tool.Name] then
            LogFunc("🎯 Goal: " .. tool.Name, Color3.fromRGB(0, 255, 255))
            
            -- Check tiền & nguyên liệu
            local canBuy = ShopUtils.CheckBuy(tool.Name, LogFunc)
            
            if canBuy then
                -- >> MUA
                LogFunc("🛒 Buying " .. tool.Name, Color3.fromRGB(0, 255, 0))
                if AutoFarm.StopFarm then AutoFarm.StopFarm() end
                Utils.Tween(SHOPS.Tool, WaitFunc)
                task.wait(1)
                ReplicatedStorage.Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"]=tool.Name, ["Category"]=tool.Category})
                Utils.SaveData("Has_"..tool.Name, true)
                task.wait(3)
            else
                -- >> FARM
                LogFunc("🌾 Farming for " .. tool.Name, Color3.fromRGB(255, 150, 0))
                if not AutoFarm.IsFarming() then
                    AutoFarm.StartFarm("Sunflower Field", LogFunc, Utils, Toolkit.FieldData, Toolkit.TokenData)
                end
            end
            return -- Tập trung làm 1 món
        end
    end

    -- ==========================================================
    -- 3. NẾU ĐÃ MUA HẾT MỌI THỨ -> AUTO FARM (CÀY CẤP)
    -- ==========================================================
    -- Nếu code chạy xuống tận đây, nghĩa là Code đã nhập, 2 ong đã có, Balo & Rake đã mua.
    LogFunc("✅ Starter Completed! Farming for Bees...", Color3.fromRGB(0, 255, 0))
    
    -- Kiểm tra nếu chưa đủ 5 ong để qua màn tiếp theo thì cứ farm tiếp
    if not AutoFarm.IsFarming() then
        -- Farm ở Mushroom Field cho đổi gió hoặc giữ Sunflower tuỳ bạn
        AutoFarm.StartFarm("Mushroom Field", LogFunc, Utils, Toolkit.FieldData, Toolkit.TokenData)
    end
end

return module
