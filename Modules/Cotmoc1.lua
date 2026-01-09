local module = {}

function module.Run(LogFunc, WaitFunc, Utils)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    -- LOAD SHOP UTILS (CÓ CHỐNG CACHE)
    local shopUtilsUrl = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/ShopUtils.lua?t=" .. tostring(tick())
    
    LogFunc("Loading ShopUtils...", Color3.fromRGB(255, 255, 255))
    local success, content = pcall(function() return game:HttpGet(shopUtilsUrl) end)
    local ShopUtils = nil
    
    if success then
        local loadFunc = loadstring(content)
        if loadFunc then
            ShopUtils = loadFunc()
        else
            LogFunc("⚠️ ShopUtils Error: Bad Code", Color3.fromRGB(255, 80, 80))
        end
    else
        LogFunc("⚠️ ShopUtils Error: Download Fail", Color3.fromRGB(255, 80, 80))
    end

    -- Tọa độ
    local EggShopPos = CFrame.new(-140.41, 4.69, 243.97)
    local ToolShopPos = CFrame.new(84.88, 4.51, 290.49)

    -- Data Check
    local currentData = Utils.LoadData() 
    local daMua = currentData.Cotmoc1_Progress or 0 
    
    if daMua >= 4 or currentData.Cotmoc1Done then
        LogFunc("Cotmoc1: Completed!", Color3.fromRGB(0, 255, 0))
        if not currentData.Cotmoc1Done then Utils.SaveData("Cotmoc1Done", true) end
        return
    end

    -- 1. TRỨNG
    if daMua < 2 then
        LogFunc("Moving to Egg Shop...", Color3.fromRGB(255, 220, 0)) 
        Utils.Tween(EggShopPos, WaitFunc)
        task.wait(1)
        for i = (daMua + 1), 2 do
            WaitFunc()
            game:GetService("ReplicatedStorage").Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"]="Basic", ["Amount"]=1, ["Category"]="Eggs"})
            Utils.SaveData("Cotmoc1_Progress", i); daMua = i 
            LogFunc("Bought Egg " .. i .. "/2", Color3.fromRGB(200, 200, 200))
            task.wait(1)
        end
    end

    -- 2. DỤNG CỤ
    if daMua < 4 then
        LogFunc("Moving to Tool Shop...", Color3.fromRGB(255, 220, 0))
        Utils.Tween(ToolShopPos, WaitFunc)
        task.wait(1)

        -- Backpack (Step 3)
        if daMua < 3 then
            WaitFunc()
            local canBuy = true
            if ShopUtils then canBuy = ShopUtils.CheckBuy("Backpack", LogFunc) end
            
            if canBuy then
                LogFunc("Buying Backpack...", Color3.fromRGB(255, 255, 255))
                game:GetService("ReplicatedStorage").Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"]="Backpack", ["Category"]="Accessory"})
                Utils.SaveData("Cotmoc1_Progress", 3); daMua = 3
                LogFunc("✅ Bought Backpack", Color3.fromRGB(0, 255, 0))
            else
                LogFunc("⏸️ Skip Backpack (Honey/Mat)", Color3.fromRGB(255, 150, 0))
            end
            task.wait(1)
        end

        -- Rake (Step 4)
        if daMua == 3 then
            WaitFunc()
            local canBuy = true
            if ShopUtils then canBuy = ShopUtils.CheckBuy("Rake", LogFunc) end
            
            if canBuy then
                LogFunc("Buying Rake...", Color3.fromRGB(255, 255, 255))
                game:GetService("ReplicatedStorage").Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"]="Rake", ["Category"]="Collector"})
                Utils.SaveData("Cotmoc1_Progress", 4); daMua = 4
                LogFunc("✅ Bought Rake", Color3.fromRGB(0, 255, 0))
            else
                LogFunc("⏸️ Skip Rake (Honey/Mat)", Color3.fromRGB(255, 150, 0))
            end
            task.wait(1)
        end
    end

    if daMua >= 4 then
        LogFunc("🎉 Cotmoc1 Full Done!", Color3.fromRGB(0, 255, 0))
        Utils.SaveData("Cotmoc1Done", true)
    else
        LogFunc("⏳ Cotmoc1 Paused at step " .. daMua, Color3.fromRGB(255, 200, 100))
    end
end

return module
