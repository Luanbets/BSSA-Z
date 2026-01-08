local module = {}

function module.Run(LogFunc, WaitFunc, Utils)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ShopPosition = CFrame.new(-140.41, 4.69, 243.97)

    -- ĐỌC CHECKPOINT
    local currentData = Utils.LoadData() 
    local daMua = currentData.Cotmoc1_Progress or 0 
    local canMua = 2 

    if daMua >= canMua then
        LogFunc("Cotmoc1: Already completed!", Color3.fromRGB(0, 255, 0))
        Utils.SaveData("Cotmoc1Done", true)
        return
    end

    LogFunc("Buying Eggs (Progress: " .. daMua .. "/" .. canMua .. ")...", Color3.fromRGB(255, 220, 0)) 
    Utils.Tween(ShopPosition, WaitFunc)
    task.wait(1) 
    
    -- VÒNG LẶP CHECKPOINT
    for i = (daMua + 1), canMua do
        WaitFunc()
        
        local success, err = pcall(function()
            game:GetService("ReplicatedStorage").Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"]="Basic", ["Amount"]=1, ["Category"]="Eggs"})
        end)
        
        if success then
            Utils.SaveData("Cotmoc1_Progress", i) -- LƯU NGAY KHI MUA ĐƯỢC
            LogFunc("Bought Egg " .. i .. "/" .. canMua, Color3.fromRGB(200, 200, 200))
        end
        
        task.wait(1) -- ĐÃ SỬA: CHỜ 1 GIÂY
    end

    LogFunc("Cotmoc1 Completed", Color3.fromRGB(0, 255, 0))
    Utils.SaveData("Cotmoc1Done", true)
end

return module
