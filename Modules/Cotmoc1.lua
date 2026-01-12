local module = {}
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Tọa độ Shop (Đã kiểm tra)
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
    
    -- LOAD DỮ LIỆU
    local Data = Utils.LoadData()
    local step = Data.Cotmoc1_Progress or 0 

    -- KIỂM TRA AN TOÀN (DEBUG)
    if not ShopUtils then LogFunc("❌ Error: ShopUtils is NIL", Color3.new(1,0,0)); return end
    if not PlayerUtils then LogFunc("❌ Error: PlayerUtils is NIL", Color3.new(1,0,0)); return end

    -- 1. ƯU TIÊN: NHẬP CODE
    if not Data.RedeemDone then
        LogFunc("🎫 Redeeming Codes...", Color3.fromRGB(255, 0, 255))
        RedeemCode.Run(LogFunc, WaitFunc, Utils)
        return
    end

    -- =================================================================
    -- [BƯỚC 1 & 2] MUA TRỨNG
    -- =================================================================
    if step < 2 then
        local currentEgg = step + 1
        LogFunc("🥚 Step " .. currentEgg .. "/2: Buying Basic Egg", Color3.fromRGB(255, 255, 0))
        
        if PlayerUtils.GetHoney() >= 1000 then
            LogFunc("💰 Buying Egg " .. currentEgg .. "...", Color3.fromRGB(0, 255, 0))
            if AutoFarm.StopFarm then AutoFarm.StopFarm() end 
            
            -- Chỉ bay nếu xa > 15m
            if (LocalPlayer.Character.HumanoidRootPart.Position - SHOPS.Egg.Position).Magnitude > 15 then
                Utils.Tween(SHOPS.Egg, WaitFunc)
                task.wait(1)
            end
            
            ReplicatedStorage.Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"]="Basic", ["Amount"]=1, ["Category"]="Eggs"})
            Utils.SaveData("Cotmoc1_Progress", currentEgg)
            task.wait(2)
        else
            -- FARM HONEY
            local bestField = AutoFarm.FindBestField("Honey", nil, Toolkit.FieldData)
            LogFunc("🌾 Need 1000 Honey. Farming at " .. bestField, Color3.fromRGB(255, 150, 0))
            if not AutoFarm.IsFarming() then
                AutoFarm.StartFarm(bestField, LogFunc, Utils, Toolkit.FieldData, Toolkit.TokenData)
            end
        end
        return
    end

    -- =================================================================
    -- [BƯỚC 3] MUA BACKPACK (ĐIỂM NÓNG BỊ LỖI)
    -- =================================================================
    if step == 2 then
        LogFunc("🎒 Step 3: Checking Backpack...", Color3.fromRGB(0, 255, 255))
        
        -- A. Kiểm tra xem có Backpack chưa? (Tránh kẹt)
        if PlayerUtils.GetItemAmount("Backpack") > 0 then
            LogFunc("✅ Đã có Backpack! Skip...", Color3.fromRGB(0, 255, 0))
            Utils.SaveData("Cotmoc1_Progress", 3)
            return -- Xong việc
        end

        -- B. Kiểm tra tiền (Dùng pcall để tránh crash nếu ShopUtils lỗi)
        local success, canBuy = pcall(function() 
            return ShopUtils.CheckBuy("Backpack", LogFunc) 
        end)

        if not success then
            LogFunc("⚠️ ShopUtils Error! Force Farming...", Color3.fromRGB(255, 0, 0))
            -- Nếu lỗi thì cứ đi farm cho chắc
            local bestField = AutoFarm.FindBestField("Honey", nil, Toolkit.FieldData)
            if not AutoFarm.IsFarming() then AutoFarm.StartFarm(bestField, LogFunc, Utils, Toolkit.FieldData, Toolkit.TokenData) end
            return
        end
        
        if canBuy then
            -- >> MUA
            LogFunc("🛒 Going to Shop (Backpack)...", Color3.fromRGB(0, 255, 0))
            if AutoFarm.StopFarm then AutoFarm.StopFarm() end
            
            local dist = (LocalPlayer.Character.HumanoidRootPart.Position - SHOPS.Tool.Position).Magnitude
            if dist > 15 then
                Utils.Tween(SHOPS.Tool, WaitFunc)
                task.wait(1)
            else
                -- Nếu đã ở shop thì nhích nhẹ 1 cái cho chắc
                LocalPlayer.Character.Humanoid:MoveTo(SHOPS.Tool.Position)
            end
            
            ReplicatedStorage.Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"]="Backpack", ["Category"]="Accessory"})
            task.wait(2)
            
            -- Check lại
            if PlayerUtils.GetItemAmount("Backpack") > 0 then
                Utils.SaveData("Cotmoc1_Progress", 3)
                LogFunc("✅ Mua thành công!", Color3.fromRGB(0, 255, 0))
            end
        else
            -- >> FARM
            local bestField = AutoFarm.FindBestField("Honey", nil, Toolkit.FieldData)
            LogFunc("🌾 Farming for Backpack...", Color3.fromRGB(255, 150, 0))
            if not AutoFarm.IsFarming() then
                AutoFarm.StartFarm(bestField, LogFunc, Utils, Toolkit.FieldData, Toolkit.TokenData)
            end
        end
        return
    end

    -- =================================================================
    -- [BƯỚC 4] MUA RAKE
    -- =================================================================
    if step == 3 then
        LogFunc("Step 4: Checking Rake...", Color3.fromRGB(0, 255, 255))
        
        if PlayerUtils.GetItemAmount("Rake") > 0 then
             Utils.SaveData("Cotmoc1_Progress", 4); Utils.SaveData("Cotmoc1Done", true)
             return
        end

        local canBuy = ShopUtils.CheckBuy("Rake", LogFunc) -- Không cần pcall nữa nếu bước trên OK
        
        if canBuy then
            LogFunc("🛒 Buying Rake...", Color3.fromRGB(0, 255, 0))
            if AutoFarm.StopFarm then AutoFarm.StopFarm() end
            
            if (LocalPlayer.Character.HumanoidRootPart.Position - SHOPS.Tool.Position).Magnitude > 15 then
                Utils.Tween(SHOPS.Tool, WaitFunc)
                task.wait(1)
            end
            
            ReplicatedStorage.Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"]="Rake", ["Category"]="Collector"})
            task.wait(2)
            
            if PlayerUtils.GetItemAmount("Rake") > 0 then
                Utils.SaveData("Cotmoc1_Progress", 4); Utils.SaveData("Cotmoc1Done", true)
                LogFunc("✅ DONE STARTER!", Color3.fromRGB(0, 255, 0))
            end
        else
            local bestField = AutoFarm.FindBestField("Honey", nil, Toolkit.FieldData)
            LogFunc("🌾 Farming for Rake...", Color3.fromRGB(255, 150, 0))
            if not AutoFarm.IsFarming() then
                AutoFarm.StartFarm(bestField, LogFunc, Utils, Toolkit.FieldData, Toolkit.TokenData)
            end
        end
        return
    end

    -- HOÀN THÀNH
    if step >= 4 then
        local currentBees = AutoFarm.GetRealBeeCount()
        LogFunc("🎉 Starter Done! Bees: " .. currentBees .. "/5", Color3.fromRGB(0, 255, 0))
        
        if not AutoFarm.IsFarming() then
            local bestField = AutoFarm.FindBestField("Honey", nil, Toolkit.FieldData)
            if bestField then AutoFarm.StartFarm(bestField, LogFunc, Utils, Toolkit.FieldData, Toolkit.TokenData) end
        end
    end
end

return module
