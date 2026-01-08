local module = {}

-- Nhận Utils từ Main truyền vào để dùng hàm Tween
function module.Run(LogFunc, WaitFunc, Utils)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    -- Tọa độ Shop Trứng
    local ShopPosition = CFrame.new(-140.41, 4.69, 243.97)

    -- 1. Báo bắt đầu
    LogFunc("Buying 2 Basic Eggs...", Color3.fromRGB(255, 220, 0)) 
    
    -- 2. Bay đến shop (Dùng hàm chung trong Utilities)
    Utils.Tween(ShopPosition, WaitFunc)
    
    task.wait(1) 
    
    -- 3. Mua trứng (Chạy ngầm, không in log chi tiết)
    for i = 1, 2 do
        WaitFunc()
        pcall(function()
            game:GetService("ReplicatedStorage").Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"]="Basic", ["Amount"]=1, ["Category"]="Eggs"})
        end)
        -- Đợi trứng nở
        task.wait(3.5) 
    end

    -- 4. Báo hoàn thành
    LogFunc("Eggs Purchased", Color3.fromRGB(0, 255, 0))
end

return module
