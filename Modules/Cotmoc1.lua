local module = {}

function module.Run(LogFunc, WaitFunc, Utils)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    -- 1. LOAD MODULE SHOP UTILS (LINK MỚI TỪ BẠN CUNG CẤP)
    -- Sử dụng đúng đường dẫn có 'refs/heads/main' để đảm bảo tải được
    local shopUtilsUrl = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/refs/heads/main/Modules/ShopUtils.lua" 
    
    LogFunc("Loading ShopUtils...", Color3.fromRGB(255, 255, 255))
    local success, content = pcall(function() return game:HttpGet(shopUtilsUrl) end)
    local ShopUtils = nil
    
    if success then
        -- Kiểm tra xem nội dung tải về có phải code Lua hợp lệ không
        local loadFunc = loadstring(content)
        if loadFunc then
            ShopUtils = loadFunc()
            LogFunc("ShopUtils Loaded OK", Color3.fromRGB(0, 255, 100))
        else
            -- Nếu link sai hoặc file rỗng, loadstring sẽ trả về nil -> Báo lỗi thay vì Crash
            LogFunc("⚠️ Lỗi ShopUtils: Nội dung tải về không phải Code!", Color3.fromRGB(255, 80, 80))
            warn("Content downloaded:", content) -- In ra F9 để kiểm tra
        end
    else
        LogFunc("⚠️ Không tải được ShopUtils (Lỗi Mạng/Link).", Color3.fromRGB(255, 150, 0))
    end

    -- Tọa độ Shop
    local EggShopPos = CFrame.new(-140.41, 4.69, 243.97)
    local ToolShopPos = CFrame.new(84.88, 4.51, 290.49)

    -- 2. ĐỌC CHECKPOINT (LƯU TRỮ TIẾN ĐỘ)
    local currentData = Utils.LoadData() 
    local daMua = currentData.Cotmoc1_Progress or 0 
    local totalSteps = 4 

    -- Nếu đã xong hết thì báo xong luôn
    if daMua >= totalSteps or currentData.Cotmoc1Done then
        LogFunc("Cotmoc1: Already completed!", Color3.fromRGB(0, 255, 0))
        if not currentData.Cotmoc1Done then Utils.SaveData("Cotmoc1Done", true) end
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
            pcall(function()
                game:GetService("ReplicatedStorage").Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"]="Basic", ["Amount"]=1, ["Category"]="Eggs"})
            end)
            
            -- Cập nhật tiến độ
            Utils.SaveData("Cotmoc1_Progress", i) 
            daMua = i 
            LogFunc("Bought Egg " .. i .. "/2", Color3.fromRGB(200, 200, 200))
            task.wait(1)
        end
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
            -- Dùng ShopUtils để check tiền nếu tải thành công
            if ShopUtils then canBuy = ShopUtils.CheckBuy("Backpack", LogFunc) end

            if canBuy then
                LogFunc("Buying Backpack...", Color3.fromRGB(255, 255, 255))
                local successBuy, err = pcall(function()
                    game:GetService("ReplicatedStorage").Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"]="Backpack", ["Category"]="Accessory"})
                end)
                
                if successBuy then
                    Utils.SaveData("Cotmoc1_Progress", 3)
                    daMua = 3
                    LogFunc("✅ Bought Backpack", Color3.fromRGB(0, 255, 0))
                else
                    LogFunc("❌ Buy Failed (Server Error)", Color3.fromRGB(255, 0, 0))
                end
            else
                LogFunc("⏸️ Skip Backpack (Not enough Honey)", Color3.fromRGB(255, 150, 0))
            end
            task.wait(1)
        end

        -- BƯỚC 4: MUA RAKE
        if daMua == 3 then
            WaitFunc()
            local canBuy = true
            if ShopUtils then canBuy = ShopUtils.CheckBuy("Rake", LogFunc) end

            if canBuy then
                LogFunc("Buying Rake...", Color3.fromRGB(255, 255, 255))
                local successBuy, err = pcall(function()
                    game:GetService("ReplicatedStorage").Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"]="Rake", ["Category"]="Collector"})
                end)
                
                if successBuy then
                    Utils.SaveData("Cotmoc1_Progress", 4)
                    daMua = 4
                    LogFunc("✅ Bought Rake", Color3.fromRGB(0, 255, 0))
                else
                    LogFunc("❌ Buy Failed (Server Error)", Color3.fromRGB(255, 0, 0))
                end
            else
                LogFunc("⏸️ Skip Rake (Not enough Honey)", Color3.fromRGB(255, 150, 0))
            end
            task.wait(1)
        end
    end

    -- ==========================================
    -- HOÀN TẤT
    -- ==========================================
    if daMua >= 4 then
        LogFunc("🎉 Cotmoc1 Completed Full!", Color3.fromRGB(0, 255, 0))
        Utils.SaveData("Cotmoc1Done", true)
    else
        LogFunc("⏳ Cotmoc1 Paused (Step " .. daMua .. "/4). Farming needed.", Color3.fromRGB(255, 200, 100))
    end
end

return module
