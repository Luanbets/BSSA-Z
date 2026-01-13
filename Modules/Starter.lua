local module = {}

-- ============================================================
-- DANH SÁCH NHIỆM VỤ (TUYẾN TÍNH)
-- ============================================================
local ACTION_LIST = {
    -- 1. Ấp cái trứng Free đầu game (Game cho sẵn 1 cái)
    [1] = {Type = "HatchExisting", Desc = "Hatch Free Egg"}, 

    -- 2. Mua 2 trứng -> Ấp luôn
    [2] = {Type = "BuyAndHatch", Amount = 2}, 

    -- 3. Mua đồ nghề cơ bản (Rake, Backpack)
    [3] = {Type = "BuyItem", Item = "Backpack", Category = "Accessory"},
    [4] = {Type = "BuyItem", Item = "Rake",     Category = "Collector"},

    -- 4. Mua tiếp 3 trứng -> Ấp (Tổng 6 ong để mở cổng 5)
    [5] = {Type = "BuyAndHatch", Amount = 3}, 

    -- 5. Mua các trang bị xịn hơn
    [6] = {Type = "BuyItem", Item = "Canister",      Category = "Accessory"},
    [7] = {Type = "BuyItem", Item = "Vacuum",        Category = "Collector"},
    [8] = {Type = "BuyItem", Item = "Belt Pocket",   Category = "Accessory"},
    [9] = {Type = "BuyItem", Item = "Basic Boots",   Category = "Accessory"},
    [10]= {Type = "BuyItem", Item = "Propeller Hat", Category = "Accessory"},
}

function module.Run(Tools)
    -- Lấy các công cụ từ Main
    local Log = Tools.Log
    local Utils = Tools.Utils
    local Shop = Tools.Shop    -- Đã tích hợp CheckAndBuy
    local Farm = Tools.Farm
    local Hatch = Tools.Hatch  -- Module ấp trứng
    local Player = Tools.Player

    -- 1. KHÔI PHỤC TIẾN ĐỘ (RESUME)
    local savedData = Utils.LoadData()
    if savedData.StarterDone then 
        Log("✅ Starter Quest Completed Already.", Color3.fromRGB(0, 255, 0))
        return 
    end
    
    local currentStep = savedData.StarterStep or 1
    local SkippedItems = savedData.PendingItems or {}
    local FARM_DEFAULT = "Sunflower Field" -- Chỗ farm mặc định khi thiếu tiền

    -- ============================================================
    -- HÀM 1: ẤP TRỨNG CÓ SẴN (Dùng cho trứng Free)
    -- ============================================================
    local function Action_HatchExisting()
        Log("🐣 Quest: Hatch Existing Egg", Color3.fromRGB(255, 255, 0))
        Farm.StopFarm()
        task.wait(1)
        
        -- Gọi module PlaceEgg
        local success, msg = Hatch.Run("Basic", 1)
        
        if success then
            Log("✅ Hatching Started...", Color3.fromRGB(0, 255, 0))
            task.wait(10) -- Đợi ong nở
        else
            Log("⚠️ " .. msg, Color3.fromRGB(255, 100, 100))
        end
    end

    -- ============================================================
    -- HÀM 2: MUA VÀ ẤP (Dùng ShopUtils mới)
    -- ============================================================
    local function Action_BuyAndHatch(amount)
        Log("🐝 Quest: Buy & Hatch " .. amount .. " Eggs", Color3.fromRGB(0, 255, 255))
        
        for k = 1, amount do
            Log("   > Processing Egg " .. k .. "/" .. amount, Color3.fromRGB(200, 200, 200))
            
            local bought = false
            
            -- Vòng lặp: Check -> Mua -> Nếu thiếu tiền thì Farm -> Check lại
            while not bought do
                Farm.StopFarm()
                task.wait(0.5)
                
                -- GỌI HÀM CHECK & BUY (Nó tự chạy ra shop, tự check giá, tự mua nếu đủ)
                local result = Shop.CheckAndBuy("Basic Egg", Player, Log)
                
                if result.Purchased then
                    bought = true
                    Log("✅ Egg Purchased! Preparing to hatch...", Color3.fromRGB(0, 255, 0))
                    task.wait(2) -- Đợi server xử lý item
                    
                    -- ẤP LUÔN
                    local hSuccess, hMsg = Hatch.Run("Basic", 1)
                    if hSuccess then
                        Log("🐣 Hatching...", Color3.fromRGB(0, 255, 0))
                        task.wait(10) -- Đợi nở
                    else
                        Log("⚠️ Hive Full? " .. hMsg, Color3.fromRGB(255, 0, 0))
                        -- Nếu full tổ thì thoát vòng lặp trứng này (tránh kẹt)
                        bought = true 
                    end
                else
                    -- NẾU THIẾU TIỀN -> ĐI FARM
                    local missing = result.MissingHoney or "Unknown"
                    Log("📉 Missing " .. missing .. " Honey. Farming...", Color3.fromRGB(255, 100, 100))
                    Farm.StartFarm(FARM_DEFAULT, Tools)
                    
                    -- Farm trong 20s rồi quay lại check tiếp
                    task.wait(20)
                end
            end
        end
    end

    -- ============================================================
    -- HÀM 3: MUA ITEM (Dùng ShopUtils mới)
    -- ============================================================
    local function Action_BuyItem(action)
        local itemName = action.Item
        Log("🛒 Quest: Buy Item " .. itemName, Color3.fromRGB(255, 255, 0))
        
        while true do
            Farm.StopFarm()
            task.wait(0.5)
            
            -- GỌI HÀM CHECK & BUY
            local result = Shop.CheckAndBuy(itemName, Player, Log)
            
            if result.Purchased then
                Log("✅ Automatically Bought: " .. itemName, Color3.fromRGB(0, 255, 0))
                task.wait(1)
                return true
            else
                -- NẾU KHÔNG MUA ĐƯỢC
                if action.Category == "Collector" then
                     -- Collector là đồ quan trọng để farm -> Bắt buộc farm để mua
                     Log("⛏️ Must have " .. itemName .. ". Farming...", Color3.fromRGB(255, 200, 100))
                     Farm.StartFarm(FARM_DEFAULT, Tools)
                     task.wait(15)
                else
                     -- Đồ khác (Giày, Mũ, Balo) -> Skip nếu thiếu tiền để chạy quest khác
                     Log("⏭️ Skipping " .. itemName .. " (Add to pending)", Color3.fromRGB(255, 80, 80))
                     table.insert(SkippedItems, action)
                     return false
                end
            end
        end
    end

    -- ============================================================
    -- VÒNG LẶP CHÍNH (MAIN LOOP)
    -- ============================================================
    Log("🚀 Starting Linear Questline from Step " .. currentStep, Color3.fromRGB(0, 255, 0))

    for i = currentStep, #ACTION_LIST do
        local action = ACTION_LIST[i]
        
        -- Thực hiện hành động
        if action.Type == "HatchExisting" then
            Action_HatchExisting()
            
        elseif action.Type == "BuyAndHatch" then
            Action_BuyAndHatch(action.Amount)
            
        elseif action.Type == "BuyItem" then
            Action_BuyItem(action)
        end
        
        -- Cập nhật tiến độ sau khi xong mỗi bước
        currentStep = i + 1
        Utils.SaveData("StarterStep", currentStep)
        Utils.SaveData("PendingItems", SkippedItems)
        task.wait(1)
    end

    -- ============================================================
    -- KẾT THÚC
    -- ============================================================
    Log("🎉 STARTER QUESTLINE FINISHED!", Color3.fromRGB(0, 255, 0))
    Utils.SaveData("StarterDone", true)
    Farm.StopFarm()
end

return module
