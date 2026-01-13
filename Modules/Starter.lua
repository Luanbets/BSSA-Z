local module = {}

-- ============================================================
-- KỊCH BẢN TUYẾN TÍNH (LÀM XONG BƯỚC NÀY MỚI QUA BƯỚC KIA)
-- ============================================================
local ACTION_LIST = {
    -- 1. Ấp cái trứng Free đầu game (Game cho sẵn 1 cái)
    [1] = {Type = "HatchExisting", Desc = "Hatch Free Egg"}, 

    -- 2. Mua đúng 2 trứng -> Ấp luôn
    [2] = {Type = "BuyAndHatch", Amount = 2}, 

    -- 3. Mua đồ nghề cơ bản
    [3] = {Type = "BuyItem", Item = "Backpack", Category = "Accessory"},
    [4] = {Type = "BuyItem", Item = "Rake",     Category = "Collector"},

    -- 4. Mua thêm 3 trứng -> Ấp luôn (Tổng cộng sẽ có 1+2+3 = 6 ong)
    [5] = {Type = "BuyAndHatch", Amount = 3}, 

    -- 5. Mua các đồ xịn hơn (Canister, Vacuum...)
    [6] = {Type = "BuyItem", Item = "Canister",      Category = "Accessory"},
    [7] = {Type = "BuyItem", Item = "Vacuum",        Category = "Collector"},
    [8] = {Type = "BuyItem", Item = "Belt Pocket",   Category = "Accessory"},
    [9] = {Type = "BuyItem", Item = "Basic Boots",   Category = "Accessory"},
    [10]= {Type = "BuyItem", Item = "Propeller Hat", Category = "Accessory"},
}

-- Hàm tìm slot trống (Giữ nguyên)
local function GetEmptySlot(LocalPlayer)
    local honeycombs = workspace.Honeycombs:FindFirstChild(LocalPlayer.Name .. "'s Hive")
    if not honeycombs then return nil end
    
    for i = 1, 50 do
        local cell = honeycombs.Cells:FindFirstChild("C" .. i)
        if cell then
            local cType = cell:FindFirstChild("CellType")
            if cType and (cType.Value == "Empty" or cType.Value == 0) then return i end
        end
    end
    return nil
end

function module.Run(Tools)
    local Log = Tools.Log
    local Utils = Tools.Utils
    local Shop = Tools.Shop
    local Farm = Tools.Farm
    local Player = Tools.Player
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = game:GetService("Players").LocalPlayer

    -- Resume (Nếu bị disconnect thì làm tiếp bước đang dở)
    local savedData = Utils.LoadData()
    if savedData.StarterDone then return end
    
    local currentStep = savedData.StarterStep or 1
    local SkippedItems = savedData.PendingItems or {}
    local FARM_DEFAULT = "Sunflower Field"

    -- ============================================================
    -- LOGIC 1: ẤP TRỨNG CÓ SẴN (KHÔNG MUA)
    -- ============================================================
    local function Action_HatchExisting()
        Log("🐣 Attempting to hatch existing egg...", Color3.fromRGB(255, 255, 0))
        Farm.StopFarm()
        task.wait(1)
        
        local slot = GetEmptySlot(LocalPlayer)
        if slot then
            ReplicatedStorage.Events.ConstructHiveCellFromEgg:InvokeServer(slot, 2, "Basic", 1, false)
            Log("✅ Hatch Command Sent to Slot " .. slot, Color3.fromRGB(0, 255, 0))
            task.wait(6) -- Đợi animation xong
        else
            Log("⚠️ No slot found or Hive full", Color3.fromRGB(255, 0, 0))
        end
    end

    -- ============================================================
    -- LOGIC 2: MUA VÀ ẤP (LOOP THEO SỐ LƯỢNG)
    -- TUYỆT ĐỐI KHÔNG CHECK INVENTORY
    -- ============================================================
    local function Action_BuyAndHatch(amount)
        Log("🐝 Mission: Buy & Hatch " .. amount .. " Eggs", Color3.fromRGB(0, 255, 255))
        
        for k = 1, amount do
            Log("   > Processing Egg " .. k .. "/" .. amount, Color3.fromRGB(200, 200, 200))
            
            -- BƯỚC 1: Cày tiền (nếu thiếu)
            -- Mặc dù không check trứng, nhưng phải check tiền để mua được
            while true do
                local check = Shop.CheckRequirements("Basic Egg", Player)
                if check.CanBuy then break end -- Đủ tiền thì thoát vòng lặp để mua
                
                -- Chưa đủ tiền -> Đi Farm
                Log("📉 Not enough honey. Farming...", Color3.fromRGB(255, 100, 100))
                Farm.StartFarm(FARM_DEFAULT, Tools.Log, Tools.Utils)
                task.wait(5)
            end
            
            -- BƯỚC 2: MUA (Bắt buộc mua, không check inventory)
            Farm.StopFarm()
            task.wait(0.5)
            Log("💰 Buying Basic Egg...", Color3.fromRGB(0, 255, 0))
            ReplicatedStorage.Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"]="Basic",["Category"]="Eggs",["Amount"]=1})
            
            -- CHỜ SERVER XỬ LÝ (QUAN TRỌNG)
            task.wait(2) 
            
            -- BƯỚC 3: ẤP LUÔN
            local slot = GetEmptySlot(LocalPlayer)
            if slot then
                Log("🐣 Hatching at Slot " .. slot, Color3.fromRGB(0, 255, 0))
                ReplicatedStorage.Events.ConstructHiveCellFromEgg:InvokeServer(slot, 2, "Basic", 1, false)
                task.wait(6) -- Đợi animation
            else
                Log("⚠️ Hive Full! Cannot hatch.", Color3.fromRGB(255, 0, 0))
                break -- Hết chỗ thì dừng loop
            end
        end
    end

    -- ============================================================
    -- LOGIC 3: MUA ITEM (ĐÃ CÓ TỪ TRƯỚC)
    -- ============================================================
    local function Action_BuyItem(action)
        local itemName = action.Item
        Log("🛒 Buying Item: " .. itemName, Color3.fromRGB(255, 255, 0))
        
        while true do
            local check = Shop.CheckRequirements(itemName, Player)
            if check.CanBuy then
                Farm.StopFarm()
                task.wait(0.5)
                ReplicatedStorage.Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"]=itemName, ["Category"]=action.Category})
                Log("✅ Bought " .. itemName, Color3.fromRGB(0, 255, 0))
                task.wait(1)
                return true
            else
                -- Logic Skip hoặc Farm như cũ
                if action.Category == "Collector" then
                     Log("⛏️ Farming for " .. itemName, Color3.fromRGB(255, 200, 100))
                     Farm.StartFarm(FARM_DEFAULT, Tools.Log, Tools.Utils)
                     task.wait(5)
                else
                     Log("⏭️ Skip " .. itemName, Color3.fromRGB(255, 80, 80))
                     table.insert(SkippedItems, action)
                     return false
                end
            end
        end
    end

    -- ============================================================
    -- MAIN LOOP (CHẠY TỪNG BƯỚC 1 -> 10)
    -- ============================================================
    for i = currentStep, #ACTION_LIST do
        local action = ACTION_LIST[i]
        currentStep = i -- Cập nhật bước hiện tại để lưu
        
        if action.Type == "HatchExisting" then
            Action_HatchExisting()
            
        elseif action.Type == "BuyAndHatch" then
            Action_BuyAndHatch(action.Amount)
            
        elseif action.Type == "BuyItem" then
            Action_BuyItem(action)
        end
        
        -- Lưu lại ngay sau khi xong 1 bước.
        -- Ví dụ: Xong bước 2 (Mua 2 trứng), save Step = 3.
        -- Nếu disconnect, vào lại sẽ làm bước 3 (Mua Backpack).
        Utils.SaveData("StarterStep", currentStep + 1)
        Utils.SaveData("PendingItems", SkippedItems)
    end

    -- KẾT THÚC
    Log("🎉 Starter Finished!", Color3.fromRGB(0, 255, 0))
    Utils.SaveData("StarterDone", true)
    Farm.StopFarm()
end

return module
