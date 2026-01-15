local module = {}

local ACTION_LIST = {
    -- [1] Hatch Free Egg -> Kết quả: Có 1 Bee
    [1] = {Type = "HatchExisting", Desc = "Hatch Free Egg"}, 
    
    -- [2] Mua 2 trứng -> Kết quả: Có 3 Bees
    [2] = {Type = "BuyAndHatch", Amount = 2}, 
    
    [3] = {Type = "BuyItem", Item = "Backpack", Category = "Accessory"},
    [4] = {Type = "BuyItem", Item = "Rake",     Category = "Collector"},
    
    -- [5] Mua 3 trứng -> Kết quả: Có 6 Bees
    [5] = {Type = "BuyAndHatch", Amount = 3}, 
    
    [6] = {Type = "BuyItem", Item = "Canister",      Category = "Accessory"},
    [7] = {Type = "BuyItem", Item = "Vacuum",        Category = "Collector"},
    [8] = {Type = "BuyItem", Item = "Belt Pocket",   Category = "Accessory"},
    [9] = {Type = "BuyItem", Item = "Basic Boots",   Category = "Accessory"},
    [10]= {Type = "BuyItem", Item = "Propeller Hat", Category = "Accessory"},
}

-- Hàm chọn bãi farm ngon nhất (Logic chọn map, không phải di chuyển)
local function GetSmartField(Tools)
    local bestField, _ = Tools.Field.GetBestFieldForMaterial("Honey")
    return bestField or "Sunflower Field"
end

-- Hàm lấy tọa độ Hive để bay về (Logic tìm tọa độ, không phải hàm di chuyển)
local function GetHiveCFrame(LocalPlayer)
    local honeycombs = workspace:FindFirstChild("Honeycombs") or workspace:FindFirstChild("Hives")
    if honeycombs then
        for _, hive in pairs(honeycombs:GetChildren()) do
            if hive:FindFirstChild("Owner") and hive.Owner.Value == LocalPlayer then
                if hive:FindFirstChild("SpawnPos") then
                    return CFrame.new(hive.SpawnPos.Value.Position + Vector3.new(0, 5, 0))
                end
            end
        end
    end
    return nil
end

function module.Run(Tools)
    local Log = Tools.Log
    local Utils = Tools.Utils -- [QUAN TRỌNG] Gọi module Utilities ở đây
    local Shop = Tools.Shop    
    local Farm = Tools.Farm
    local Hatch = Tools.Hatch  
    local Player = Tools.Player

    local savedData = Utils.LoadData()
    if savedData.StarterDone then return end
    
    local currentStep = savedData.StarterStep or 1
    local SkippedItems = savedData.PendingItems or {}
    
    -- Tính số ong dự kiến
    local expectedHiveSlots = 1 
    for j = 1, currentStep - 1 do
        if ACTION_LIST[j].Type == "BuyAndHatch" then
            expectedHiveSlots = expectedHiveSlots + ACTION_LIST[j].Amount
        end
    end

    local function Action_HatchExisting()
        Log("🐣 Quest: Hatch Existing Egg", Color3.fromRGB(255, 255, 0))
        Farm.StopFarm()
        
        -- [GỌI UTILS] Bay về tổ để ấp
        local hivePos = GetHiveCFrame(game.Players.LocalPlayer)
        if hivePos then Utils.Tween(hivePos) end
        
        task.wait(1)
        Hatch.Run("Basic", 1)
        task.wait(5)
        
        local realBees = Player.GetBeeCount()
        Log("✅ Số ong hiện tại: " .. realBees, Color3.fromRGB(0, 255, 0))
    end

    local function Action_BuyAndHatch(amount)
        local targetSlots = expectedHiveSlots + amount
        Log("🐝 Quest: Nhiệm vụ mua " .. amount .. " trứng...", Color3.fromRGB(0, 255, 255))
        
        while true do
            local currentEggIndex = Shop.GetCurrentEggIndex(Log)
            local currentOwned = currentEggIndex - 1
            local boughtCount = currentOwned - expectedHiveSlots
            if boughtCount < 0 then boughtCount = 0 end
            if boughtCount > amount then boughtCount = amount end
            
            Log("🥚 Đã mua " .. boughtCount .. "/" .. amount, Color3.fromRGB(255, 200, 0))

            if currentEggIndex > targetSlots then
                Log("⏩ Đã đủ trứng. Skip!", Color3.fromRGB(0, 255, 0))
                break
            end
            
            Farm.StopFarm()
            
            -- [GỌI UTILS] Bay về Shop Trứng (-137, 4, 244)
            Utils.Tween(CFrame.new(-137, 4, 244)) 
            task.wait(0.5)

            local result = Shop.CheckAndBuy("Basic Egg", Player, Log)
            
            if result.Purchased then
                Log("✅ Mua trứng thành công! Đang ấp...", Color3.fromRGB(0, 255, 0))
                
                -- [GỌI UTILS] Bay về tổ để ấp
                local hivePos = GetHiveCFrame(game.Players.LocalPlayer)
                if hivePos then Utils.Tween(hivePos) end
                
                task.wait(1)
                Hatch.Run("Basic", 1)
                task.wait(5)
                
                local realBees = Player.GetBeeCount()
                Log("✅ Số ong thực tế: " .. realBees, Color3.fromRGB(50, 255, 50))
            else
                -- Thiếu tiền -> Đi farm
                local current = Player.GetHoney()
                local target = result.Price or (current + (result.MissingHoney or 0))
                
                local bestMap = GetSmartField(Tools)
                Log("💰 Cày tiền ở: " .. bestMap, Color3.fromRGB(255, 170, 0))
                
                -- FarmUntil bên trong nó đã gọi Utils.Tween để ra bãi rồi
                Farm.FarmUntil(target, bestMap, Tools)
            end
        end
        expectedHiveSlots = targetSlots
    end

    local function Action_BuyItem(action)
        local itemName = action.Item
        Log("🛒 Quest: Mua " .. itemName, Color3.fromRGB(255, 255, 0))
        
        while true do
            Farm.StopFarm()
            
            -- [GỌI UTILS] Bay về Noob Shop (-137, 4, 244)
            Utils.Tween(CFrame.new(-137, 4, 244))
            task.wait(0.5)
            
            local result = Shop.CheckAndBuy(itemName, Player, Log)
            
            if result.Purchased then
                Log("✅ Đã mua: " .. itemName, Color3.fromRGB(0, 255, 0))
                task.wait(1)
                return true
            else
                if result.MissingHoney then
                    -- Thiếu tiền -> Đi farm
                    local price = result.Price or 0
                    local missing = result.MissingHoney
                    Log("📉 Thiếu " .. missing .. " mật. Đi cày thôi...", Color3.fromRGB(255, 170, 0))
                    
                    local bestMap = GetSmartField(Tools)
                    
                    -- FarmUntil sử dụng Utils.Tween để bay ra bãi
                    Farm.FarmUntil(price, bestMap, Tools)
                    
                elseif result.MissingMats then
                    -- Thiếu nguyên liệu -> Skip
                    Log("⚠️ Thiếu nguyên liệu. Skip " .. itemName, Color3.fromRGB(255, 80, 80))
                    table.insert(SkippedItems, action)
                    return false
                else
                    -- Lỗi khác -> Skip
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
