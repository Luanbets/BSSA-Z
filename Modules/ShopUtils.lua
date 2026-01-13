local module = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Biến lưu giá tạm thời (Cache) để không phải chạy ra shop liên tục
local CachedEggPrice = nil 

-- =======================================================
-- 1. LOAD UTILITIES AN TOÀN
-- =======================================================
local Utils = nil

local function LoadUtilsSafely()
    local url = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/Utilities.lua"
    local success, content = pcall(function() return game:HttpGet(url) end)
    if not success then return nil end
    local func, err = loadstring(content)
    if not func then return nil end
    local runSuccess, loadedModule = pcall(func)
    return loadedModule
end

Utils = LoadUtilsSafely()
if not Utils then
    Utils = { Tween = function() end, SaveData = function() end, LoadData = function() return {} end }
end

-- Thử đọc giá từ file save cũ nếu có (để vào game là có giá luôn khỏi check)
local savedData = Utils.LoadData()
if savedData.NextEggPrice then
    CachedEggPrice = savedData.NextEggPrice
end

local function ParsePrice(text)
    local cleanStr = text:gsub("%D", "") 
    return tonumber(cleanStr) or 0
end

local function ToggleShopUI()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

-- =======================================================
-- 2. DỮ LIỆU CỨNG
-- =======================================================
local ShopData = {
    ["Basic Egg"] = {}, 
    ["Rake"] = { Price = 800, Type = "Collector", Category = "Collector" },
    ["Clippers"] = { Price = 2200, Type = "Collector", Category = "Collector" },
    ["Magnet"] = { Price = 5500, Type = "Collector", Category = "Collector" },
    ["Vacuum"] = { Price = 14000, Type = "Collector", Category = "Collector" },
    ["Backpack"] = { Price = 5500, Type = "Container", Category = "Accessory" },
    ["Canister"] = { Price = 22000, Type = "Container", Category = "Accessory" },
    -- (Các item khác giữ nguyên như cũ, tôi rút gọn để tập trung vào logic trứng)
    ["Belt Pocket"] = { Price = 14000, Type = "Accessory", Category = "Accessory", Ingredients = { ["SunflowerSeed"] = 10 } },
    ["Basic Boots"] = { Price = 4400, Type = "Accessory", Category = "Accessory", Ingredients = { ["SunflowerSeed"] = 3, ["Blueberry"] = 3 } },
    ["Propeller Hat"] = { Price = 2500000, Type = "Accessory", Category = "Accessory", Ingredients = { ["Gumdrops"] = 25, ["Pineapple"] = 100, ["MoonCharm"] = 5 } },
}

-- =======================================================
-- 3. HÀM CẬP NHẬT GIÁ (CHẠY RA SHOP ĐỂ XEM GIÁ)
-- =======================================================
local function FetchEggPriceFromShop(LogFunc)
    if LogFunc then LogFunc("🏃 Chưa có dữ liệu giá. Bay ra Shop check 1 lần...", Color3.fromRGB(255, 255, 0)) end

    -- 1. Tween tới Shop
    Utils.Tween(CFrame.new(-137, 4, 244))
    task.wait(0.5)

    -- 2. Mở Shop
    ToggleShopUI()

    -- 3. Đọc giá
    local price = 0
    local startTime = tick()
    
    while tick() - startTime < 8 do
        local screenGui = PlayerGui:FindFirstChild("ScreenGui")
        local shopFrame = screenGui and screenGui:FindFirstChild("Shop")
        local itemInfo = shopFrame and shopFrame:FindFirstChild("ItemInfo")
        local itemCostLabel = itemInfo and itemInfo:FindFirstChild("ItemCost")

        if shopFrame and shopFrame.Visible and itemCostLabel then
            price = ParsePrice(itemCostLabel.Text)
            break
        end
        task.wait(0.5)
    end

    -- 4. Đóng Shop
    task.wait(0.5)
    ToggleShopUI()
    task.wait(0.5)

    if price > 0 then
        CachedEggPrice = price
        Utils.SaveData("NextEggPrice", price) -- Lưu vào file luôn
        if LogFunc then LogFunc("🏷️ Đã cập nhật giá trứng: " .. price, Color3.fromRGB(0, 255, 255)) end
        return price
    else
        return 1000000000 -- Trả về giá siêu cao để không mua bậy nếu lỗi
    end
end

-- =======================================================
-- 4. HÀM MUA (Remote Buy)
-- =======================================================
local function TryPurchase(itemName, category, PlayerUtils)
    local oldHoney = PlayerUtils.GetHoney()
    
    local success, err = pcall(function()
        local typeToSend = itemName 
        if itemName == "Basic Egg" then typeToSend = "Basic" end -- Fix tên cho Server

        ReplicatedStorage.Events.ItemPackageEvent:InvokeServer("Purchase", {
            ["Type"] = typeToSend, 
            ["Category"] = category,
            ["Amount"] = 1
        })
    end)

    task.wait(1.5)
    local newHoney = PlayerUtils.GetHoney()
    return newHoney < oldHoney
end

-- =======================================================
-- 5. HÀM CHECK VÀ MUA (LOGIC MỚI: CHECK NGẦM)
-- =======================================================
function module.CheckAndBuy(itemName, PlayerUtils, LogFunc)
    -- A. LOGIC ĐẶC BIỆT CHO BASIC EGG
    if itemName == "Basic Egg" then
        
        -- BƯỚC 1: KIỂM TRA XEM ĐÃ CÓ GIÁ CHƯA
        if not CachedEggPrice then
            -- Nếu chưa có giá -> Bắt buộc chạy ra shop check 1 lần
            FetchEggPriceFromShop(LogFunc)
        end

        -- BƯỚC 2: CHECK NGẦM (SILENT CHECK)
        local myHoney = PlayerUtils.GetHoney()
        
        if myHoney < CachedEggPrice then
            -- ==> THIẾU TIỀN: Return luôn, KHÔNG DI CHUYỂN
            -- Hàm Starter sẽ thấy return false -> tiếp tục đi farm
            return { Purchased = false, MissingHoney = CachedEggPrice - myHoney }
        else
            -- ==> ĐỦ TIỀN: Bây giờ mới bay ra shop để mua
            if LogFunc then LogFunc("💰 Đủ tiền ("..myHoney.."/"..CachedEggPrice.."). Bay ra Shop mua ngay!", Color3.fromRGB(0, 255, 0)) end
            
            -- Bay ra shop (Cần đứng gần mới mua được)
            Utils.Tween(CFrame.new(-137, 4, 244))
            task.wait(0.5)
            
            local success = TryPurchase("Basic Egg", "Eggs", PlayerUtils)
            
            if success then
                if LogFunc then LogFunc("✅ Mua thành công!", Color3.fromRGB(0, 255, 0)) end
                -- Mua xong thì giá sẽ tăng -> Reset cache để lần sau script tự check lại giá mới
                CachedEggPrice = nil 
                Utils.SaveData("NextEggPrice", nil)
                return { Purchased = true }
            else
                if LogFunc then LogFunc("❌ Mua thất bại (Lỗi Server/Lag)", Color3.fromRGB(255, 0, 0)) end
                return { Purchased = false }
            end
        end
    end

    -- B. LOGIC CHO ITEM THƯỜNG (Check nhanh qua data cứng)
    local data = ShopData[itemName]
    if not data then return { Purchased = false, Error = "NoData" } end

    local myHoney = PlayerUtils.GetHoney()
    if myHoney < data.Price then
        return { Purchased = false, MissingHoney = data.Price - myHoney }
    end

    -- Check nguyên liệu
    if data.Ingredients then
        for matName, matNeed in pairs(data.Ingredients) do
            local matHave = PlayerUtils.GetItemAmount(matName)
            if matHave < matNeed then
                return { Purchased = false, MissingMats = matName }
            end
        end
    end

    -- Đủ điều kiện -> Bay ra shop mua (nếu cần thiết, hoặc gọi remote)
    -- Với item thường, ta vẫn nên bay ra shop cho chắc ăn, hoặc dùng remote trực tiếp nếu game cho phép
    if LogFunc then LogFunc("🛒 Mua vật phẩm: " .. itemName, Color3.fromRGB(0, 255, 0)) end
    
    -- Tự động bay đến shop tương ứng (Logic đơn giản hóa: bay đại đến shop trứng vì các shop gần nhau hoặc dùng remote xa)
    -- Game này thường yêu cầu đứng gần shop cụ thể. 
    -- Ở đây ta dùng remote luôn, nếu thất bại do xa quá thì lần sau update thêm tọa độ từng shop.
    local success = TryPurchase(itemName, data.Category, PlayerUtils)
    
    return { Purchased = success }
end

return module
