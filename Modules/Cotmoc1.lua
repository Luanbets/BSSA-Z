local module = {}

function module.Run(Tools)
    local Log = Tools.Log
    local Utils = Tools.Utils
    local Shop = Tools.Shop
    local Farm = Tools.Farm
    local FieldData = Tools.Field
    
    -- Load trạng thái hiện tại
    local data = Utils.LoadData()
    local progress = data.Cotmoc1_Progress or 0

    Log("🚀 Starting Cotmoc 1...", Color3.fromRGB(255, 255, 255))

    -- CÁNH ĐỒNG ĐỂ FARM KHI THIẾU TIỀN (Starter farm ở Sunflower)
    local FARM_FIELD = "Sunflower Field" 

    -- HÀM MUA THÔNG MINH (Chặn lại farm cho đến khi đủ tiền)
    local function SmartBuy(itemName, category, stepNum)
        if progress >= stepNum then return end -- Đã làm rồi

        Log("🛒 Aiming to buy: " .. itemName, Color3.fromRGB(255, 255, 0))
        
        while true do
            local check = Shop.CheckRequirements(itemName)
            
            if check.CanBuy then
                -- Đủ tiền -> Mua ngay
                Farm.StopFarm() -- Dừng farm nếu đang farm
                task.wait(1)
                Log("💰 Buying " .. itemName .. "...", Color3.fromRGB(0, 255, 0))
                
                -- Di chuyển đến shop (Bạn thêm toạ độ shop vào Utils hoặc hardcode ở đây)
                -- Utils.Tween(ShopPos...) 
                
                game:GetService("ReplicatedStorage").Events.ItemPackageEvent:InvokeServer("Purchase", {
                    ["Type"] = itemName, 
                    ["Category"] = category
                })
                
                Utils.SaveData("Cotmoc1_Progress", stepNum)
                progress = stepNum
                Log("✅ Bought " .. itemName, Color3.fromRGB(0, 255, 0))
                break -- Thoát vòng lặp while để sang món tiếp theo
            else
                -- Thiếu tiền -> Đi Farm
                Log("📉 Missing: " .. check.MissingHoney .. " Honey. Farming...", Color3.fromRGB(255, 100, 100))
                Farm.StartFarm(FARM_FIELD, Tools)
                task.wait(5) -- Check lại sau mỗi 5s
            end
        end
    end

    -- === BƯỚC 1: MUA TRỨNG (VD: Basic Egg) ===
    -- Trứng thường không tốn Honey mà tốn tiền thật hoặc có sẵn, giả sử mua bằng Honey
    -- SmartBuy("Basic Egg", "Eggs", 1) 

    -- === BƯỚC 2: MUA BACKPACK ===
    SmartBuy("Backpack", "Accessory", 3)

    -- === BƯỚC 3: MUA RAKE ===
    SmartBuy("Rake", "Collector", 4)

    -- HOÀN THÀNH
    Log("🎉 Cotmoc 1 Completed!", Color3.fromRGB(0, 255, 0))
    Utils.SaveData("Cotmoc1Done", true)
    Farm.StopFarm()
end

return module
