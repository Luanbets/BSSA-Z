local module = {}

-- Tham số truyền vào đầy đủ: Log, Wait, Utils, ShopUtils, PlayerUtils, AutoFarm, FieldData, TokenData
function module.Run(LogFunc, WaitFunc, Utils, ShopUtils, PlayerUtils, AutoFarm, FieldData, TokenData)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    -- Tọa độ Shop (Lấy cứng hoặc lưu vào FieldData cũng được, tạm để đây)
    local EggShopPos = CFrame.new(-140.41, 4.69, 243.97)
    local ToolShopPos = CFrame.new(84.88, 4.51, 290.49)

    local currentData = Utils.LoadData() 
    local daMua = currentData.Cotmoc1_Progress or 0 
    
    if daMua >= 4 then return end -- Xong rồi thì thôi

    LogFunc("Tiến hành Cột Mốc 1...", Color3.fromRGB(0, 255, 255))

    -- STEP 1: Mua 2 Trứng
    if daMua < 2 then
        Utils.Tween(EggShopPos, WaitFunc)
        task.wait(1)
        for i = (daMua + 1), 2 do
            -- Kiểm tra tiền
            if PlayerUtils.GetHoney() >= 1000 then -- Giả sử giá trứng là 1000 (Ví dụ)
                ReplicatedStorage.Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"]="Basic", ["Amount"]=1, ["Category"]="Eggs"})
                Utils.SaveData("Cotmoc1_Progress", i)
                daMua = i
                LogFunc("Đã mua trứng " .. i, Color3.fromRGB(0, 255, 0))
            else
                LogFunc("Không đủ tiền mua trứng, đi farm!", Color3.fromRGB(255, 100, 0))
                -- GỌI AUTOFARM: Farm ở Sunflower cho dễ
                task.spawn(function() AutoFarm.StartFarm("Sunflower Field", LogFunc, Utils, FieldData, TokenData) end)
                
                -- Đợi đủ tiền
                repeat task.wait(2) until PlayerUtils.GetHoney() >= 1000
                AutoFarm.StopFarm()
                Utils.Tween(EggShopPos, WaitFunc)
            end
            task.wait(1)
        end
    end

    -- STEP 2: Mua Backpack
    if daMua < 3 then
        Utils.Tween(ToolShopPos, WaitFunc)
        
        -- Dùng ShopUtils + PlayerUtils để check
        local canBuy = ShopUtils.CheckBuy("Backpack", PlayerUtils, LogFunc)
        
        if canBuy then
            local info = ShopUtils.GetItemInfo("Backpack")
            ReplicatedStorage.Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"]=info.ID, ["Category"]=info.Category})
            Utils.SaveData("Cotmoc1_Progress", 3); daMua = 3
            LogFunc("Đã mua Backpack", Color3.fromRGB(0, 255, 0))
        else
            LogFunc("Chưa đủ tiền mua Backpack -> Farm tiếp", Color3.fromRGB(255, 255, 0))
             -- Farm tiếp...
        end
    end

    if daMua >= 3 then
        Utils.SaveData("Cotmoc1Done", true)
        LogFunc("Hoàn thành Cột Mốc 1!", Color3.fromRGB(0, 255, 0))
    end
end

return module
