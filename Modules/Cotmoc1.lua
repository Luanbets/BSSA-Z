local module = {}

function module.Run(LogFunc, WaitFunc, Utils)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    -- Tọa độ
    local EggShopPos = CFrame.new(-140.41, 4.69, 243.97)
    local ToolShopPos = CFrame.new(84.88, 4.51, 290.49) -- Tọa độ mới

    -- 1. ĐỌC CHECKPOINT
    local currentData = Utils.LoadData() 
    local daMua = currentData.Cotmoc1_Progress or 0 
    
    -- Tổng các bước cần làm: 2 Trứng + 1 Balo + 1 Cào = 4 Bước
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
        
        -- Chạy tiếp từ số trứng đã mua
        for i = (daMua + 1), 2 do
            WaitFunc()
            pcall(function()
                game:GetService("ReplicatedStorage").Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"]="Basic", ["Amount"]=1, ["Category"]="Eggs"})
            end)
            
            -- Lưu tiến độ (1 hoặc 2)
            Utils.SaveData("Cotmoc1_Progress", i) 
            LogFunc("Bought Egg " .. i .. "/2", Color3.fromRGB(200, 200, 200))
            task.wait(1)
        end
        -- Cập nhật lại biến daMua sau khi xong giai đoạn trứng
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
            LogFunc("Buying Backpack...", Color3.fromRGB(255, 255, 255))
            local success, err = pcall(function()
                game:GetService("ReplicatedStorage").Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"]="Backpack", ["Category"]="Accessory"})
            end)
            
            if success then
                Utils.SaveData("Cotmoc1_Progress", 3) -- Lưu bước 3
                LogFunc("Bought Backpack", Color3.fromRGB(0, 255, 0))
                daMua = 3
            end
            task.wait(1)
        end

        -- BƯỚC 4: MUA RAKE
        if daMua < 4 then
            WaitFunc()
            LogFunc("Buying Rake...", Color3.fromRGB(255, 255, 255))
            local success, err = pcall(function()
                game:GetService("ReplicatedStorage").Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"]="Rake", ["Category"]="Collector"})
            end)
            
            if success then
                Utils.SaveData("Cotmoc1_Progress", 4) -- Lưu bước 4
                LogFunc("Bought Rake", Color3.fromRGB(0, 255, 0))
            end
            task.wait(1)
        end
    end

    -- HOÀN TẤT
    LogFunc("Cotmoc1 Completed", Color3.fromRGB(0, 255, 0))
    Utils.SaveData("Cotmoc1Done", true)
end

return module
