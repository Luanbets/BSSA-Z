local module = {}

-- ============================================================
-- 1. HÀM TÌM SLOT TRỐNG (HACKER LOGIC)
-- Giúp không bao giờ đặt đè lên ong cũ
-- ============================================================
local function GetEmptySlot(LocalPlayer)
    local honeycombs = workspace.Honeycombs:FindFirstChild(LocalPlayer.Name .. "'s Hive")
    if not honeycombs then return nil end
    
    -- Duyệt từ Slot 1 đến 50
    for i = 1, 50 do
        local cellName = "C" .. i
        local cell = honeycombs.Cells:FindFirstChild(cellName)
        
        -- Nếu chưa có Cell này (Slot chưa mở) -> Bỏ qua (hoặc có thể mua slot sau này)
        -- Nếu có Cell, kiểm tra xem có ong không
        if cell then
            local cellType = cell:FindFirstChild("CellType")
            if cellType and (cellType.Value == "Empty" or cellType.Value == 0) then
                return i -- Tìm thấy slot trống số i (ví dụ: Slot 3)
            end
        end
    end
    return nil -- Không còn chỗ trống
end

-- ============================================================
-- 2. LOGIC CHÍNH
-- ============================================================
function module.Run(Tools)
    local Log = Tools.Log
    local Utils = Tools.Utils
    local Shop = Tools.Shop
    local Farm = Tools.Farm
    local Player = Tools.Player
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = game:GetService("Players").LocalPlayer
    
    -- Load tiến trình đã lưu
    local data = Utils.LoadData()
    if data.StarterDone then 
        Log("✅ Starter Sequence Completed.", Color3.fromRGB(0, 255, 0))
        return 
    end

    local currentStep = data.StarterStep or 0
    Log("🚀 Starter Script Running... (Step: " .. currentStep .. ")", Color3.fromRGB(0, 255, 255))
    
    local FARM_FIELD = "Sunflower Field" -- Farm ở đây cho an toàn

    -- ============================================================
    -- HÀM MUA ĐỒ (Tự đi farm nếu thiếu tiền)
    -- ============================================================
    local function BuyItem(itemName, stepNum)
        if currentStep >= stepNum then return end -- Đã làm xong bước này

        Log("🛒 Goal: Buy " .. itemName, Color3.fromRGB(255, 255, 0))
        
        while true do
            local check = Shop.CheckRequirements(itemName, Player, Log)
            
            if check.CanBuy then
                Farm.StopFarm()
                task.wait(0.5)
                
                -- Tạo lệnh mua
                local args = {
                    ["Type"] = itemName,
                    ["Category"] = Shop.CheckRequirements(itemName, Player).Category or "Accessory"
                }
                -- Fix category đặc biệt cho Tool
                if itemName == "Rake" or itemName == "Vacuum" or itemName == "Scissors" then 
                    args.Category = "Collector" 
                end

                ReplicatedStorage.Events.ItemPackageEvent:InvokeServer("Purchase", args)
                Log("✅ Bought: " .. itemName, Color3.fromRGB(0, 255, 0))
                
                -- Lưu lại là đã xong bước này
                Utils.SaveData("StarterStep", stepNum)
                currentStep = stepNum
                task.wait(1)
                break
            else
                Log("📉 Need " .. Utils.FormatNumber(check.MissingHoney) .. " Honey. Farming...", Color3.fromRGB(255, 100, 100))
                Farm.StartFarm(FARM_FIELD, Tools)
                task.wait(5)
            end
        end
    end

    -- ============================================================
    -- HÀM MUA VÀ ẤP TRỨNG (An toàn tuyệt đối)
    -- ============================================================
    local function BuyAndHatchEgg(targetTotalBees, stepNum)
        if currentStep >= stepNum then return end
        
        -- Logic: Mua và ấp cho đến khi tổng số ong = targetTotalBees
        while Player.GetBeeCount() < targetTotalBees do
            
            -- 1. Kiểm tra xem có trứng trong balo chưa (có thể do code tặng)
            local eggInBag = Player.GetItemAmount("Basic Egg")
            
            if eggInBag > 0 then
                -- CÓ TRỨNG -> ẤP LUÔN
                Farm.StopFarm()
                local emptySlot = GetEmptySlot(LocalPlayer)
                
                if emptySlot then
                    Log("🥚 Hatching Egg at Slot " .. emptySlot, Color3.fromRGB(200, 200, 255))
                    local args = {
                        [1] = emptySlot, -- Slot tự tìm được (An toàn)
                        [2] = 2,         -- ID Basic Egg
                        [3] = "Basic",   -- Tên
                        [4] = 1,         -- Số lượng
                        [5] = false      -- Gifted
                    }
                    ReplicatedStorage.Events.ConstructHiveCellFromEgg:InvokeServer(unpack(args))
                    task.wait(4) -- Đợi ấp nở
                else
                    Log("⚠️ Hive Full! Cannot Hatch!", Color3.fromRGB(255, 0, 0))
                    break -- Hết chỗ thì chịu
                end
            else
                -- KHÔNG CÓ TRỨNG -> ĐI MUA
                -- ShopUtils tự biết giá dựa trên số ong hiện tại
                local check = Shop.CheckRequirements("Basic Egg", Player, Log)
                
                if check.CanBuy then
                    Farm.StopFarm()
                    Log("💰 Buying Basic Egg...", Color3.fromRGB(0, 255, 0))
                    ReplicatedStorage.Events.ItemPackageEvent:InvokeServer("Purchase", {
                        ["Type"] = "Basic",
                        ["Category"] = "Eggs",
                        ["Amount"] = 1
                    })
                    task.wait(1)
                else
                    Log("📉 Egg Price: " .. check.Price .. ". Farming...", Color3.fromRGB(255, 100, 100))
                    Farm.StartFarm(FARM_FIELD, Tools)
                    task.wait(5)
                end
            end
        end
        
        -- Đủ số ong yêu cầu -> Lưu bước
        Utils.SaveData("StarterStep", stepNum)
        currentStep = stepNum
    end

    -- ============================================================
    -- KỊCH BẢN STARTER (THEO ĐÚNG YÊU CẦU CỦA BẠN)
    -- ============================================================
    
    -- Bước 0: Ấp quả trứng đầu tiên (Nếu game tặng sẵn)
    -- Mục tiêu: Ít nhất 1 ong
    BuyAndHatchEgg(1, 1)

    -- Bước 1: Mua thêm 2 Egg (Tổng mong muốn: 3 Ong)
    BuyAndHatchEgg(3, 2)

    -- Bước 2: Mua Backpack
    BuyItem("Backpack", 3)

    -- Bước 3: Mua Rake
    BuyItem("Rake", 4)

    -- Bước 4: Mua thêm 3 Basic Egg (Tổng mong muốn: 3 + 3 = 6 Ong)
    BuyAndHatchEgg(6, 5)

    -- Bước 5: Mua Canister
    BuyItem("Canister", 6)

    -- Bước 6: Mua Vacuum
    BuyItem("Vacuum", 7)

    -- Bước 7: Mua Belt Pocket
    BuyItem("Belt Pocket", 8)

    -- Bước 8: Mua Basic Boots
    BuyItem("Basic Boots", 9)

    -- HOÀN THÀNH
    Log("🎉 Starter Script Completed! Ready for next zone.", Color3.fromRGB(0, 255, 0))
    Utils.SaveData("StarterDone", true)
    Farm.StopFarm()
end

return module
