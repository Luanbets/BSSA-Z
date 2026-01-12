local module = {}

-- Tọa độ Shop (Giữ nguyên)
local SHOPS = {
    Egg  = CFrame.new(-140.41, 4.69, 243.97),
    Tool = CFrame.new(84.88, 4.51, 290.49)
}

function module.Run(LogFunc, WaitFunc, Toolkit)
    local Utils = Toolkit.Utils
    local ShopUtils = Toolkit.ShopUtils
    local AutoFarm = Toolkit.AutoFarm
    local PlayerUtils = Toolkit.PlayerUtils
    local RedeemCode = Toolkit.RedeemCode
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    -- LOAD DỮ LIỆU TIẾN TRÌNH
    local Data = Utils.LoadData()
    local step = Data.Cotmoc1_Progress or 0 
    -- Step 0: New | 1: 1 Egg | 2: 2 Egg | 3: Backpack | 4: Rake (Done)

    -- 1. ƯU TIÊN: NHẬP CODE
    if not Data.RedeemDone then
        LogFunc("🎫 Redeeming Codes...", Color3.fromRGB(255, 0, 255))
        RedeemCode.Run(LogFunc, WaitFunc, Utils)
        return
    end

    -- [BƯỚC 1 & 2] MUA TRỨNG (Mục tiêu: Mua đủ 2 quả Basic Egg)
    if step < 2 then
        local currentEgg = step + 1
        LogFunc("🥚 Step " .. currentEgg .. "/2: Buying Basic Egg", Color3.fromRGB(255, 255, 0))
        local eggPrice = 1000
        
        if PlayerUtils.GetHoney() >= eggPrice then
            LogFunc("💰 Buying Egg " .. currentEgg .. "...", Color3.fromRGB(0, 255, 0))
            if AutoFarm.StopFarm then AutoFarm.StopFarm() end 
            Utils.Tween(SHOPS.Egg, WaitFunc)
            task.wait(1)
            ReplicatedStorage.Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"]="Basic", ["Amount"]=1, ["Category"]="Eggs"})
            Utils.SaveData("Cotmoc1_Progress", currentEgg)
            LogFunc("✅ Saved Progress: " .. currentEgg, Color3.fromRGB(200, 200, 200))
            task.wait(2)
        else
            -- ĐI FARM THEO FIELD TỐT NHẤT (HONEY)
            local bestField = AutoFarm.FindBestField("Honey", nil, Toolkit.FieldData)
            LogFunc("🌾 Need Honey ("..PlayerUtils.GetHoney().."/"..eggPrice.."). Farm at: " .. bestField, Color3.fromRGB(255, 150, 0))
            if not AutoFarm.IsFarming() then
                AutoFarm.StartFarm(bestField, LogFunc, Utils, Toolkit.FieldData, Toolkit.TokenData)
            end
        end
        return
    end

    -- [BƯỚC 3] MUA BACKPACK
    if step == 2 then
        LogFunc("🎒 Step 3: Buying Backpack", Color3.fromRGB(0, 255, 255))
        local canBuy = ShopUtils.CheckBuy("Backpack", LogFunc)
        
        if canBuy then
            LogFunc("🛒 Buying Backpack...", Color3.fromRGB(0, 255, 0))
            if AutoFarm.StopFarm then AutoFarm.StopFarm() end
            Utils.Tween(SHOPS.Tool, WaitFunc)
            task.wait(1)
            ReplicatedStorage.Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"]="Backpack", ["Category"]="Accessory"})
            Utils.SaveData("Cotmoc1_Progress", 3)
            LogFunc("✅ Bought Backpack!", Color3.fromRGB(0, 255, 0))
            task.wait(2)
        else
            -- ĐI FARM THEO FIELD TỐT NHẤT
            local bestField = AutoFarm.FindBestField("Honey", nil, Toolkit.FieldData)
            LogFunc("🌾 Farming for Backpack at: " .. bestField, Color3.fromRGB(255, 150, 0))
            if not AutoFarm.IsFarming() then
                AutoFarm.StartFarm(bestField, LogFunc, Utils, Toolkit.FieldData, Toolkit.TokenData)
            end
        end
        return
    end

    -- [BƯỚC 4] MUA RAKE (CÀO)
    if step == 3 then
        LogFunc("rake Step 4: Buying Rake", Color3.fromRGB(0, 255, 255))
        local canBuy = ShopUtils.CheckBuy("Rake", LogFunc)
        
        if canBuy then
            LogFunc("🛒 Buying Rake...", Color3.fromRGB(0, 255, 0))
            if AutoFarm.StopFarm then AutoFarm.StopFarm() end
            Utils.Tween(SHOPS.Tool, WaitFunc)
            task.wait(1)
            ReplicatedStorage.Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"]="Rake", ["Category"]="Collector"})
            Utils.SaveData("Cotmoc1_Progress", 4)
            Utils.SaveData("Cotmoc1Done", true)
            LogFunc("✅ Bought Rake! Starter Phase Done.", Color3.fromRGB(0, 255, 0))
            task.wait(2)
        else
            -- ĐI FARM THEO FIELD TỐT NHẤT
            local bestField = AutoFarm.FindBestField("Honey", nil, Toolkit.FieldData)
            LogFunc("🌾 Farming for Rake at: " .. bestField, Color3.fromRGB(255, 150, 0))
            if not AutoFarm.IsFarming() then
                AutoFarm.StartFarm(bestField, LogFunc, Utils, Toolkit.FieldData, Toolkit.TokenData)
            end
        end
        return
    end

    -- =================================================================
    -- HOÀN THÀNH TẤT CẢ -> TỰ ĐỘNG TÌM BÃI FARM HONEY TỐT NHẤT
    -- =================================================================
    if step >= 4 then
        local currentBees = AutoFarm.GetRealBeeCount()
        LogFunc("🎉 Starter Done! Bees: " .. currentBees .. "/5", Color3.fromRGB(0, 255, 0))
        
        -- Kiểm tra nếu đang không farm thì mới bắt đầu farm
        if not AutoFarm.IsFarming() then
            -- 1. Tìm Field tốt nhất để cày Honey dựa trên FieldData
            local bestField = AutoFarm.FindBestField("Honey", nil, Toolkit.FieldData)
            
            if bestField then
                LogFunc("🍯 Auto Farming Honey at: " .. bestField, Color3.fromRGB(0, 255, 255))
                AutoFarm.StartFarm(bestField, LogFunc, Utils, Toolkit.FieldData, Toolkit.TokenData)
            else
                LogFunc("⚠️ No suitable field found!", Color3.fromRGB(255, 0, 0))
            end
        end
        
        -- Logic mở rộng: Nếu đủ tiền mua thêm trứng (Step phụ) thì có thể thêm vào đây
        -- Hoặc chờ Main.lua chuyển Phase
    end
end

return module
