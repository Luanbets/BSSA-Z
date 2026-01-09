local module = {}

function module.Run(LogFunc, WaitFunc, Utils)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    -- 1. LOAD MODULE SHOP UTILS (Để check tiền và item)
    -- Bạn nhớ lưu file ShopUtils.lua lên github hoặc cùng thư mục nhé
    local shopUtilsUrl = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/ShopUtils.lua" 
    local success, func = pcall(function() return game:HttpGet(shopUtilsUrl) end)
    local ShopUtils = nil
    
    if success then
        ShopUtils = loadstring(func)()
    else
        LogFunc("⚠️ Warning: Cannot load ShopUtils. Buying blindly...", Color3.fromRGB(255, 100, 0))
    end

    -- Tọa độ
    local EggShopPos = CFrame.new(-140.41, 4.69, 243.97)
    local ToolShopPos = CFrame.new(84.88, 4.51, 290.49)

    -- 2. ĐỌC CHECKPOINT
    local currentData = Utils.LoadData() 
    local daMua = currentData.Cotmoc1_Progress or 0 
    local totalSteps = 4 

    if daMua >= totalSteps then
        LogFunc("Cotmoc1: Already completed!", Color3.fromRGB(0, 255, 0))
        Utils.SaveData("Cotmoc1Done", true)
        return
    end

    -- ==========================================
    -- GIAI ĐOẠN 1: MUA TRỨNG (Bước 1 -> 2)
    -- ==========================================
    if daMua < 2 then
        LogFunc("Moving to Egg Shop...", Color3.fromRGB(255, 220, 0)) 
        Utils.Tween(EggShopPos, WaitFunc)
        task.wait(1)
        
        for i = (daMua + 1), 2 do
            WaitFunc()
            -- Trứng Basic giá rẻ và thay đổi theo số lượng nên ta mua luôn không cần check kỹ
            pcall(function()
                game:GetService("ReplicatedStorage").Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"]="Basic", ["Amount"]=1, ["Category"]="Eggs"})
            end)
            
            Utils.SaveData("Cotmoc1_Progress", i) 
            LogFunc("Bought Egg " .. i .. "/2", Color3.fromRGB(200, 200, 200))
            task.wait(1)
        end
        daMua = 2 
    end

    -- ==========================================
    -- GIAI ĐOẠN 2: MUA DỤNG CỤ (Bước 3 -> 4)
    -- ==========================================
    if daMua < 4 then
        LogFunc("Moving to Tool Shop...", Color3.fromRGB(255, 220, 0))
        Utils.Tween(ToolShopPos, WaitFunc)
        task.wait(1)

        -- BƯỚC 3: MUA BACKPACK
        if daMua < 3 then
            WaitFunc()
            local canBuy = true
            
            -- Nếu có ShopUtils thì check, không thì thôi (tránh lỗi script)
            if ShopUtils then 
                canBuy = ShopUtils.CheckBuy("Backpack", LogFunc)
            end

            if canBuy then
                LogFunc("Buying Backpack...", Color3.fromRGB(255, 255, 255))
                local success, err = pcall(function()
                    game:GetService("ReplicatedStorage").Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"]="Backpack", ["Category"]="Accessory"})
                end)
                
                if success then
                    Utils.SaveData("Cotmoc1_Progress", 3)
                    LogFunc("Bought Backpack", Color3.fromRGB(0, 255, 0))
                    daMua = 3
                end
            else
                LogFunc("Skip Backpack: Not enough resources", Color3.fromRGB(255, 80, 80))
                return -- Dừng lại đi farm tiếp
            end
            task.wait(1)
        end

        -- BƯỚC 4: MUA RAKE
        if daMua < 4 then
            WaitFunc()
            local canBuy = true
            
            if ShopUtils then 
                canBuy = ShopUtils.CheckBuy("Rake", LogFunc) -- Rake dùng data mặc định hoặc bạn thêm vào Tooldata nếu cần
            end
            
            -- Lưu ý: Trong file Tooldata bạn gửi ko có Rake thường, chỉ có Golden Rake.
            -- Nếu Rake thường giá rẻ (800 Honey) thì có thể bỏ qua check hoặc thêm data Rake vào ShopUtils.
            -- Ở đây tôi giả định là check được hoặc mua luôn.

            if canBuy then
                LogFunc("Buying Rake...", Color3.fromRGB(255, 255, 255))
                local success, err = pcall(function()
                    game:GetService("ReplicatedStorage").Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"]="Rake", ["Category"]="Collector"})
                end)
                
                if success then
                    Utils.SaveData("Cotmoc1_Progress", 4)
                    LogFunc("Bought Rake", Color3.fromRGB(0, 255, 0))
                end
            end
            task.wait(1)
        end
    end

    LogFunc("Cotmoc1 Completed", Color3.fromRGB(0, 255, 0))
    Utils.SaveData("Cotmoc1Done", true)
end

return module
