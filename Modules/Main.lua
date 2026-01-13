-- ... (Phần đầu giữ nguyên)

-- ====================================================
-- LOGIC ĐA NHIỆM (CHECK PENDING ITEMS)
-- ====================================================
local function StartBackgroundCheck(Tools)
    task.spawn(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        while true do
            task.wait(30) -- Check mỗi 30 giây
            
            local data = Tools.Utils.LoadData()
            local pending = data.PendingItems or {}
            
            if #pending > 0 then
                Tools.Log("🔍 Background Check: " .. #pending .. " Items...", Color3.fromRGB(150, 150, 150))
                
                local newPending = {}
                for _, itemData in ipairs(pending) do
                    -- Check Kho & Điều kiện (Không làm gián đoạn việc farm chính quá lâu)
                    local check = Tools.Shop.CheckRequirements(itemData.Item, Tools.Player)
                    
                    if check.CanBuy then
                        Tools.Log("✅ Background Buy: " .. itemData.Item, Color3.fromRGB(0, 255, 0))
                        
                        -- Tạm dừng Farm 1 chút để mua
                        Tools.Farm.StopFarm()
                        task.wait(0.5)
                        ReplicatedStorage.Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"]=itemData.Item, ["Category"]=itemData.Category})
                        task.wait(1)
                        -- Mua xong thì không thêm vào newPending nữa (Xóa nợ)
                    else
                        -- Vẫn chưa đủ -> Giữ lại trong danh sách nợ
                        table.insert(newPending, itemData)
                    end
                end
                
                -- Cập nhật lại danh sách nợ
                Tools.Utils.SaveData("PendingItems", newPending)
                
                -- Nếu danh sách nợ rỗng -> Thông báo
                if #newPending == 0 then
                    Tools.Log("🎉 All Pending Items Cleared!", Color3.fromRGB(0, 255, 0))
                else
                     -- Tiếp tục farm (Khôi phục trạng thái)
                     -- (Ở đây không cần gọi StartFarm lại vì vòng lặp của 5BeeZone vẫn đang chạy, chỉ cần biến isFarming=true là được)
                end
            end
        end
    end)
end

-- ====================================================
-- LOGIC CHÍNH
-- ====================================================
task.spawn(function()
    -- ... (Load Modules như cũ) ...

    -- 1. CHẠY STARTER (NẾU CHƯA XONG)
    if not SaveData.StarterDone then
        local Starter = LoadModule("Starter.lua")
        if Starter then Starter.Run(Tools) end
    end
    
    -- 2. KÍCH HOẠT CHẾ ĐỘ CHECK NGẦM (SAU KHI STARTER DONE)
    StartBackgroundCheck(Tools) -- <--- ĐÂY LÀ TÍNH NĂNG MỚI

    -- 3. CHUYỂN SANG ZONE 5 (HOẶC CÁC ZONE TIẾP THEO)
    Log("🚀 Starting 5 Bee Zone Logic...", Color3.fromRGB(0, 255, 255))
    
    -- Ví dụ load module 5BeeZone (Bạn sẽ viết file này sau)
    -- local Zone5 = LoadModule("5BeeZone.lua")
    -- if Zone5 then Zone5.Run(Tools) end
    
    -- Tạm thời Farm Loop (Giả lập Zone 5 đang chạy)
    while true do
        -- Logic của Zone 5 ở đây (ví dụ Farm Bamboo)
        Tools.Farm.StartFarm("Bamboo Field", Tools.Log, Tools.Utils)
        task.wait(10)
    end
end)
