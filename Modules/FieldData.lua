local module = {}

-- DANH SÁCH MUA SẮM (Theo thứ tự bạn muốn)
local SHOPPING_LIST = {
    {Item = "Backpack",     Category = "Accessory", Step = 3},
    {Item = "Rake",         Category = "Collector", Step = 4},
    {Item = "Canister",     Category = "Accessory", Step = 6},
    {Item = "Vacuum",       Category = "Collector", Step = 7},
    {Item = "Belt Pocket",  Category = "Accessory", Step = 8},
    {Item = "Basic Boots",  Category = "Accessory", Step = 9},
    -- Thêm món khó vào đây để test skip
    {Item = "Propeller Hat",Category = "Accessory", Step = 10}, 
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
    local FieldData = Tools.Field
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = game:GetService("Players").LocalPlayer
    
    local data = Utils.LoadData()
    if data.StarterDone then return end
    
    local FARM_DEFAULT = "Sunflower Field"
    local SkippedItems = {} -- Danh sách các món tạm bỏ qua

    -- ============================================================
    -- HÀM MUA TRỨNG (Để lên ong)
    -- ============================================================
    local function BuyAndHatch(targetBees)
        Log("🐝 Target Bees: " .. targetBees, Color3.fromRGB(200, 200, 255))
        while Player.GetBeeCount() < targetBees do
            local eggInBag = Player.GetItemAmount("Basic Egg")
            if eggInBag > 0 then
                Farm.StopFarm()
                local slot = GetEmptySlot(LocalPlayer)
                if slot then
                    ReplicatedStorage.Events.ConstructHiveCellFromEgg:InvokeServer(unpack({slot, 2, "Basic", 1, false}))
                    Log("🐣 Hatched Slot " .. slot, Color3.fromRGB(0, 255, 0)); task.wait(4)
                else
                    Log("⚠️ Hive Full!", Color3.fromRGB(255, 0, 0)); break
                end
            else
                local check = Shop.CheckRequirements("Basic Egg", Player, Log)
                if check.CanBuy then
                    Farm.StopFarm()
                    Log("💰 Buying Egg...", Color3.fromRGB(0, 255, 0))
                    ReplicatedStorage.Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"]="Basic",["Category"]="Eggs",["Amount"]=1})
                    task.wait(1)
                else
                    Log("📉 Farming for Egg...", Color3.fromRGB(255, 100, 100))
                    Farm.StartFarm(FARM_DEFAULT, Tools.Log, Tools.Utils)
                    task.wait(5)
                end
            end
        end
    end

    -- ============================================================
    -- HÀM XỬ LÝ MUA ITEM (CÓ SKIP)
    -- Trả về: true (Mua được), false (Chưa mua được - Skip)
    -- ============================================================
    local function TryBuyItem(itemData)
        local itemName = itemData.Item
        Log("🛒 Checking: " .. itemName, Color3.fromRGB(255, 255, 0))

        -- 1. Check Kho & Tiền (Luôn check kho trước!)
        local check = Shop.CheckRequirements(itemName, Player, Log)
        
        if check.CanBuy then
            Farm.StopFarm()
            task.wait(0.5)
            ReplicatedStorage.Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"]=itemName, ["Category"]=itemData.Category})
            Log("✅ Bought: " .. itemName, Color3.fromRGB(0, 255, 0))
            Utils.SaveData("StarterStep", itemData.Step)
            return true
        end

        -- 2. Nếu thiếu, phân tích nguyên nhân
        -- A. Thiếu Nguyên Liệu
        if check.MissingMats and #check.MissingMats > 0 then
            local missing = check.MissingMats[1]
            local bestField, _ = FieldData.GetBestField(missing.Name)

            if bestField then
                -- Vào được map -> Đi farm
                Log("🚜 Farming " .. missing.Name .. " at " .. bestField, Color3.fromRGB(0, 255, 255))
                Farm.StartFarm(bestField, Tools.Log, Tools.Utils)
                task.wait(5)
                return false -- Chưa mua được, nhưng đang farm -> Coi như Skip vòng này để check lại sau
            else
                -- KHÔNG VÀO ĐƯỢC MAP (Thiếu ong) -> SKIP
                Log("⏭️ SKIP " .. itemName .. " (Zone Locked: " .. missing.Name .. ")", Color3.fromRGB(255, 80, 80))
                return false -- Skip thực sự
            end
        end

        -- B. Chỉ thiếu Honey -> Đi farm Honey (Farm Basic Egg nếu cần thiết để mở map sau này)
        if check.MissingHoney > 0 then
            Log("📉 Farming Honey for " .. itemName, Color3.fromRGB(255, 200, 100))
            Farm.StartFarm(FARM_DEFAULT, Tools.Log, Tools.Utils)
            task.wait(5)
            return false
        end
        
        return false
    end

    -- ============================================================
    -- LOGIC CHÍNH: CHẠY LIST + SKIP
    -- ============================================================
    
    -- 1. Đảm bảo ong cơ bản trước (Để farm map thường)
    BuyAndHatch(3) 

    -- 2. Duyệt danh sách mua sắm
    for _, itemData in ipairs(SHOPPING_LIST) do
        local savedData = Utils.LoadData()
        local currentStep = savedData.StarterStep or 0
        
        if currentStep < itemData.Step then
            local success = TryBuyItem(itemData)
            
            if not success then
                -- Nếu không mua được (do đang farm hoặc bị lock map)
                -- Kiểm tra xem có phải Lock Map không?
                local check = Shop.CheckRequirements(itemData.Item, Player)
                local isLocked = false
                if check.MissingMats then
                    for _, m in pairs(check.MissingMats) do
                        if not FieldData.GetBestField(m.Name) then isLocked = true break end
                    end
                end

                if isLocked then
                    -- Nếu bị Lock Map -> Thêm vào danh sách Bỏ Qua
                    table.insert(SkippedItems, itemData)
                else
                    -- Nếu chỉ thiếu tiền -> Lặp lại việc farm cho đến khi đủ (Không skip đồ cơ bản)
                    -- Trừ khi bạn muốn skip luôn cả đồ thiếu tiền?
                    -- Theo logic bạn: "Tạm bỏ qua -> cái tiếp theo". OK, ta skip luôn nếu farm lâu.
                    -- Nhưng đồ cơ bản (Rake) mà skip thì không có đồ farm.
                    -- Nên tôi để logic: Đồ Collector cơ bản KHÔNG SKIP. Đồ Accessory (Mũ) MỚI SKIP.
                    if itemData.Category == "Collector" then
                        while not TryBuyItem(itemData) do task.wait(1) end
                    else
                        table.insert(SkippedItems, itemData)
                    end
                end
            end
        end
    end

    -- 3. QUAY LẠI CHECK ĐỒ BỎ QUA (RETRY)
    Log("🔄 Retrying Skipped Items...", Color3.fromRGB(255, 100, 255))
    local StillPending = {}
    
    for _, itemData in ipairs(SkippedItems) do
        -- Check lại kho (Biết đâu nãy giờ farm lụm được)
        if TryBuyItem(itemData) then
            Log("✅ Retry Success: " .. itemData.Item, Color3.fromRGB(0, 255, 0))
        else
            Log("⚠️ Still Failed: " .. itemData.Item .. " -> Move to Pending", Color3.fromRGB(255, 80, 80))
            table.insert(StillPending, itemData)
        end
    end

    -- 4. KẾT THÚC STARTER
    -- Lưu danh sách nợ vào SaveData để Main xử lý tiếp
    Utils.SaveData("PendingItems", StillPending)
    Utils.SaveData("StarterDone", true)
    
    Log("🎉 Starter Loop Finished. Handing over to Main.", Color3.fromRGB(0, 255, 0))
    Farm.StopFarm()
end

return module
