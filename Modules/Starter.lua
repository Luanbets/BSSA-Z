local module = {}

local ACTION_LIST = {
    -- [1] Hatch Free Egg -> Kết quả: Có 1 Bee (Chuẩn bị mua trứng thứ 2)
    [1] = {Type = "HatchExisting", Desc = "Hatch Free Egg"}, 
    
    -- [2] Mua 2 trứng -> Kết quả: Có 3 Bees (Chuẩn bị mua trứng thứ 4)
    [2] = {Type = "BuyAndHatch", Amount = 2}, 
    
    [3] = {Type = "BuyItem", Item = "Backpack", Category = "Accessory"},
    [4] = {Type = "BuyItem", Item = "Rake",     Category = "Collector"},
    
    -- [5] Mua 3 trứng -> Kết quả: Có 6 Bees (Chuẩn bị mua trứng thứ 7)
    [5] = {Type = "BuyAndHatch", Amount = 3}, 
    
    [6] = {Type = "BuyItem", Item = "Canister",      Category = "Accessory"},
    [7] = {Type = "BuyItem", Item = "Vacuum",        Category = "Collector"},
    [8] = {Type = "BuyItem", Item = "Belt Pocket",   Category = "Accessory"},
    [9] = {Type = "BuyItem", Item = "Basic Boots",   Category = "Accessory"},
    [10]= {Type = "BuyItem", Item = "Propeller Hat", Category = "Accessory"},
}

-- [HÀM MỚI] Tự động chọn cánh đồng ngon nhất dựa trên số ong hiện có
local function GetSmartField(Tools)
    -- Hỏi FieldData xem map nào ngon nhất cho Honey
    local bestField, _ = Tools.Field.GetBestFieldForMaterial("Honey")
    return bestField or "Sunflower Field" -- Nếu lỗi thì về Sunflower
end

function module.Run(Tools)
    local Log = Tools.Log
    local Utils = Tools.Utils
    local Shop = Tools.Shop    
    local Farm = Tools.Farm
    local Hatch = Tools.Hatch  
    local Player = Tools.Player

    local savedData = Utils.LoadData()
    if savedData.StarterDone then return end
    
    local currentStep = savedData.StarterStep or 1
    local SkippedItems = savedData.PendingItems or {}
    
    -- Tính toán số slot ong dự kiến dựa trên các bước trước đó
    local expectedHiveSlots = 1 -- Mặc định có 1 con (Free Egg)
    for j = 1, currentStep - 1 do
        if ACTION_LIST[j].Type == "BuyAndHatch" then
            expectedHiveSlots = expectedHiveSlots + ACTION_LIST[j].Amount
        end
    end

    local function Action_HatchExisting()
        Log("🐣 Quest: Hatch Existing Egg", Color3.fromRGB(255, 255, 0))
        Farm.StopFarm()
        task.wait(1)
        Hatch.Run("Basic", 1)
        task.wait(5) -- Đợi ong nở animation
        
        -- [CHECK NGAY] In ra số ong hiện tại sau khi nở
        local realBees = Player.GetBeeCount()
        Log("✅ Số ong hiện tại: " .. realBees, Color3.fromRGB(0, 255, 0))
    end

    -- [LOGIC QUAN TRỌNG] Mua trứng thông minh
    local function Action_BuyAndHatch(amount)
        local targetSlots = expectedHiveSlots + amount
        Log("🐝 Quest: Nhiệm vụ mua " .. amount .. " trứng...", Color3.fromRGB(0, 255, 255))
        
        while true do
            -- 1. Lấy Index trứng hiện tại
            local currentEggIndex = Shop.GetCurrentEggIndex(Log)
            local currentOwned = currentEggIndex - 1
            local boughtCount = currentOwned - expectedHiveSlots
            
            if boughtCount < 0 then boughtCount = 0 end
            if boughtCount > amount then boughtCount = amount end
            
            Log("🥚 Đã mua " .. boughtCount .. "/" .. amount, Color3.fromRGB(255, 200, 0))

            -- 2. SO SÁNH VỚI MỤC TIÊU
            if currentEggIndex > targetSlots then
                Log("⏩ Đã đủ trứng. Skip!", Color3.fromRGB(0, 255, 0))
                break
            end
            
            -- 3. Chưa đủ -> Mua tiếp
            Farm.StopFarm()
            local result = Shop.CheckAndBuy("Basic Egg", Player, Log)
            
            if result.Purchased then
                Log("✅ Mua thành công! Hatching...", Color3.fromRGB(0, 255, 0))
                task.wait(2)
                Hatch.Run("Basic", 1)
                task.wait(5)
                
                -- [CHECK NGAY] Cập nhật lại số ong sau khi nở
                local realBees = Player.GetBeeCount()
                Log("✅ Số ong thực tế: " .. realBees, Color3.fromRGB(50, 255, 50))
            else
                local current = Player.GetHoney()
                local target = result.Price or (current + (result.MissingHoney or 0))
                
                -- [SỬA LỖI] Dùng GetSmartField thay vì FARM_DEFAULT
                local bestMap = GetSmartField(Tools)
                Log("💰 Cày tiền ở: " .. bestMap .. " (Mục tiêu: " .. target .. ")", Color3.fromRGB(255, 170, 0))
                Farm.FarmUntil(target, bestMap, Tools)
            end
        end
        
        expectedHiveSlots = targetSlots
    end

    local function Action_BuyItem(action)
        local itemName = action.Item
        Log("🛒 Quest: Buy Item " .. itemName, Color3.fromRGB(255, 255, 0))
        
        while true do
            Farm.StopFarm()
            task.wait(0.5)
            
            local result = Shop.CheckAndBuy(itemName, Player, Log)
            
            if result.Purchased then
                Log("✅ Bought: " .. itemName, Color3.fromRGB(0, 255, 0))
                task.wait(1)
                return true
            else
                if action.Category == "Collector" then
                     local current = Player.GetHoney()
                     local target = result.Price or 0
                     
                     -- [SỬA LỖI] Dùng GetSmartField thay vì FARM_DEFAULT
                     local bestMap = GetSmartField(Tools)
                     Log("💰 Cày tiền ở: " .. bestMap .. " để mua " .. itemName, Color3.fromRGB(255, 170, 0))
                     Farm.FarmUntil(target, bestMap, Tools)
                else
                     Log("⏭️ Skip " .. itemName, Color3.fromRGB(255, 80, 80))
                     table.insert(SkippedItems, action)
                     return false
                end
            end
        end
    end

    for i = currentStep, #ACTION_LIST do
        local action = ACTION_LIST[i]
        
        if action.Type == "HatchExisting" then Action_HatchExisting()
        elseif action.Type == "BuyAndHatch" then Action_BuyAndHatch(action.Amount)
        elseif action.Type == "BuyItem" then Action_BuyItem(action) end
        
        currentStep = i + 1
        Utils.SaveData("StarterStep", currentStep)
        Utils.SaveData("PendingItems", SkippedItems)
        task.wait(1)
    end

    Log("🎉 STARTER FINISHED!", Color3.fromRGB(0, 255, 0))
    Utils.SaveData("StarterDone", true)
    Farm.StopFarm()
end

return module
