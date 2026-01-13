local module = {}

-- Helper: Định dạng số cho đẹp (VD: 1.5k, 2M)
local function FormatNum(n)
    if n >= 10^9 then return string.format("%.2fB", n / 10^9) end
    if n >= 10^6 then return string.format("%.2fM", n / 10^6) end
    if n >= 10^3 then return string.format("%.2fk", n / 10^3) end
    return tostring(n)
end

local ACTION_LIST = {
    [1] = {Type = "HatchExisting", Desc = "Hatch Free Egg"}, 
    [2] = {Type = "BuyAndHatch", Amount = 2}, 
    [3] = {Type = "BuyItem", Item = "Backpack", Category = "Accessory"},
    [4] = {Type = "BuyItem", Item = "Rake",     Category = "Collector"},
    [5] = {Type = "BuyAndHatch", Amount = 3}, 
    [6] = {Type = "BuyItem", Item = "Canister",      Category = "Accessory"},
    [7] = {Type = "BuyItem", Item = "Vacuum",        Category = "Collector"},
    [8] = {Type = "BuyItem", Item = "Belt Pocket",   Category = "Accessory"},
    [9] = {Type = "BuyItem", Item = "Basic Boots",   Category = "Accessory"},
    [10]= {Type = "BuyItem", Item = "Propeller Hat", Category = "Accessory"},
}

function module.Run(Tools)
    local Log = Tools.Log
    local Utils = Tools.Utils
    local Shop = Tools.Shop    
    local Farm = Tools.Farm
    local Hatch = Tools.Hatch  
    local Player = Tools.Player

    local savedData = Utils.LoadData()
    if savedData.StarterDone then 
        Log("✅ Starter Quest Completed.", Color3.fromRGB(0, 255, 0))
        return 
    end
    
    local currentStep = savedData.StarterStep or 1
    local SkippedItems = savedData.PendingItems or {}
    local FARM_DEFAULT = "Sunflower Field"

    local function Action_HatchExisting()
        Log("🐣 Quest: Hatch Existing Egg", Color3.fromRGB(255, 255, 0))
        Farm.StopFarm()
        task.wait(1)
        local success, msg = Hatch.Run("Basic", 1)
        if success then
            Log("✅ Hatching...", Color3.fromRGB(0, 255, 0))
            task.wait(10)
        else
            Log("⚠️ " .. msg, Color3.fromRGB(255, 100, 100))
        end
    end

    local function Action_BuyAndHatch(amount)
        Log("🐝 Quest: Buy & Hatch " .. amount .. " Eggs", Color3.fromRGB(0, 255, 255))
        
        for k = 1, amount do
            local bought = false
            while not bought do
                Farm.StopFarm()
                task.wait(0.5)
                
                -- Gọi check và lấy kết quả
                local result = Shop.CheckAndBuy("Basic Egg", Player, Log)
                
                if result.Purchased then
                    bought = true
                    Log("✅ Egg Purchased! Hatching...", Color3.fromRGB(0, 255, 0))
                    task.wait(2)
                    local hSuccess = Hatch.Run("Basic", 1)
                    if hSuccess then
                        task.wait(10)
                    else
                        bought = true 
                    end
                else
                    -- [HIỂN THỊ CHI TIẾT 0/PRICE]
                    local current = Player.GetHoney()
                    local target = result.Price or (current + (result.MissingHoney or 0))
                    
                    -- Dòng Log bạn yêu cầu:
                    Log("📉 Farm Honey: " .. FormatNum(current) .. " / " .. FormatNum(target), Color3.fromRGB(255, 170, 0))
                    
                    Farm.StartFarm(FARM_DEFAULT, Tools)
                    task.wait(15) -- Farm 15s rồi check lại
                end
            end
        end
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
                     -- Hiển thị chi tiết cho item luôn
                     local current = Player.GetHoney()
                     local target = result.Price or 0
                     Log("📉 " .. itemName .. ": " .. FormatNum(current) .. " / " .. FormatNum(target), Color3.fromRGB(255, 170, 0))
                     
                     Farm.StartFarm(FARM_DEFAULT, Tools)
                     task.wait(15)
                else
                     Log("⏭️ Skip " .. itemName, Color3.fromRGB(255, 80, 80))
                     table.insert(SkippedItems, action)
                     return false
                end
            end
        end
    end

    Log("🚀 Starting Quest Step " .. currentStep, Color3.fromRGB(0, 255, 0))

    for i = currentStep, #ACTION_LIST do
        local action = ACTION_LIST[i]
        
        if action.Type == "HatchExisting" then
            Action_HatchExisting()
        elseif action.Type == "BuyAndHatch" then
            Action_BuyAndHatch(action.Amount)
        elseif action.Type == "BuyItem" then
            Action_BuyItem(action)
        end
        
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
