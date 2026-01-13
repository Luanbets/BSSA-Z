local module = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- =======================================================
-- 1. LOAD UTILITIES AN TOÀN (SAFE LOAD SYSTEM)
-- =======================================================
local Utils = nil

local function LoadUtilsSafely()
    print("🛠️ [ShopUtils] Đang tải Utilities.lua từ GitHub...")
    local url = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/Utilities.lua"
    
    -- Bước 1: Tải nội dung (Raw Content)
    local success, content = pcall(function() 
        return game:HttpGet(url) 
    end)
    
    if not success or not content then
        warn("❌ [ShopUtils] Lỗi tải HttpGet! " .. tostring(content))
        return nil
    end

    -- Bước 2: Biên dịch (Compile)
    local func, err = loadstring(content)
    if not func then
        warn("❌ [ShopUtils] Lỗi cú pháp (Syntax Error): " .. tostring(err))
        return nil
    end

    -- Bước 3: Chạy Module
    local runSuccess, loadedModule = pcall(func)
    if not runSuccess then
        warn("❌ [ShopUtils] Lỗi khi chạy Utilities: " .. tostring(loadedModule))
        return nil
    end

    print("✅ [ShopUtils] Đã tải Utilities thành công!")
    return loadedModule
end

-- Thực hiện tải
Utils = LoadUtilsSafely()

-- Fallback: Nếu tải lỗi, tạo hàm rỗng để script KHÔNG bị crash
if not Utils then
    warn("⚠️ [ShopUtils] Đang chạy chế độ Fallback (Không có Tween/Save)")
    Utils = {
        Tween = function(...) warn("⚠️ Tween chưa được tải!") end,
        SaveData = function(...) end
    }
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
-- 2. DỮ LIỆU CỨNG (SHOP DATA)
-- =======================================================
local ShopData = {
    ["Basic Egg"] = {}, 
    
    -- COLLECTORS
    ["Rake"] =     { Price = 800,   Type = "Collector", Category = "Collector" },
    ["Clippers"] = { Price = 2200,  Type = "Collector", Category = "Collector" },
    ["Magnet"] =   { Price = 5500,  Type = "Collector", Category = "Collector" },
    ["Vacuum"] =   { Price = 14000, Type = "Collector", Category = "Collector" },
    ["Super-Scooper"]  = { Price = 40000,    Type = "Collector", Category = "Collector" },
    ["Pulsar"]         = { Price = 125000,   Type = "Collector", Category = "Collector" },
    ["Electro-Magnet"] = { Price = 300000,   Type = "Collector", Category = "Collector" },
    ["Scissors"]       = { Price = 850000,   Type = "Collector", Category = "Collector" },
    ["Honey Dipper"]   = { Price = 1500000,  Type = "Collector", Category = "Collector" },

    -- CONTAINERS
    ["Jar"] =      { Price = 650,   Type = "Container", Category = "Accessory" },
    ["Backpack"] = { Price = 5500,  Type = "Container", Category = "Accessory" },
    ["Canister"] = { Price = 22000, Type = "Container", Category = "Accessory" },
    ["Mega-Jug"]    = { Price = 50000,    Type = "Container", Category = "Accessory" },
    ["Compressor"]  = { Price = 160000,   Type = "Container", Category = "Accessory" },
    ["Elite Barrel"]= { Price = 650000,   Type = "Container", Category = "Accessory" },
    ["Port-O-Hive"] = { Price = 1250000,  Type = "Container", Category = "Accessory" },

    -- ACCESSORIES
    ["Helmet"] = { Price = 30000, Type = "Accessory", Category = "Accessory", Ingredients = { ["Pineapple"] = 5, ["MoonCharm"] = 1 } },
    ["Belt Pocket"] = { Price = 14000, Type = "Accessory", Category = "Accessory", Ingredients = { ["SunflowerSeed"] = 10 } },
    ["Basic Boots"] = { Price = 4400, Type = "Accessory", Category = "Accessory", Ingredients = { ["SunflowerSeed"] = 3, ["Blueberry"] = 3 } },
    ["Propeller Hat"] = { Price = 2500000, Type = "Accessory", Category = "Accessory", Ingredients = { ["Gumdrops"] = 25, ["Pineapple"] = 100, ["MoonCharm"] = 5 } },
    ["Brave Guard"] = { Price = 300000, Type = "Accessory", Category = "Accessory", Ingredients = { ["Stinger"] = 3 } },
    ["Hasty Guard"] = { Price = 300000, Type = "Accessory", Category = "Accessory", Ingredients = { ["MoonCharm"] = 5 } },
    ["Bomber Guard"] = { Price = 300000, Type = "Accessory", Category = "Accessory", Ingredients = { ["SunflowerSeed"] = 25 } },
    ["Looker Guard"] = { Price = 300000, Type = "Accessory", Category = "Accessory", Ingredients = { ["SunflowerSeed"] = 25 } },
    ["Belt Bag"] = { Price = 440000, Type = "Accessory", Category = "Accessory", Ingredients = { ["Pineapple"] = 50, ["SunflowerSeed"] = 50, ["Stinger"] = 3 } },
    ["Hiking Boots"] = { Price = 2200000, Type = "Accessory", Category = "Accessory", Ingredients = { ["Blueberry"] = 50, ["Strawberry"] = 50 } }
}

-- =======================================================
-- 3. HÀM MUA (INTERNAL)
-- =======================================================
local function ExecuteBuy(itemName, category)
    local success, err = pcall(function()
        ReplicatedStorage.Events.ItemPackageEvent:InvokeServer("Purchase", {
            ["Type"] = itemName, 
            ["Category"] = category,
            ["Amount"] = 1
        })
    end)
    return success
end

-- =======================================================
-- 4. HÀM CHECK VÀ MUA
-- =======================================================
function module.CheckAndBuy(itemName, PlayerUtils, LogFunc)
    -- A. LOGIC ĐẶC BIỆT CHO BASIC EGG
    if itemName == "Basic Egg" then
        if LogFunc then LogFunc("🏃 Đang bay tới Shop Trứng để kiểm tra...", Color3.fromRGB(255, 255, 0)) end

        -- 1. Tween tới Shop
        Utils.Tween(CFrame.new(-137, 4, 244))
        task.wait(0.5)

        -- 2. Mở Shop
        ToggleShopUI()

        -- 3. Lấy giá
        local price = 1000 
        local startTime = tick()
        local uiFound = false
        
        while tick() - startTime < 8 do
            local screenGui = PlayerGui:FindFirstChild("ScreenGui")
            local shopFrame = screenGui and screenGui:FindFirstChild("Shop")
            local itemInfo = shopFrame and shopFrame:FindFirstChild("ItemInfo")
            local itemCostLabel = itemInfo and itemInfo:FindFirstChild("ItemCost")

            if shopFrame and shopFrame.Visible and itemCostLabel then
                price = ParsePrice(itemCostLabel.Text)
                uiFound = true
                break
            end
            task.wait(0.5)
        end

        -- 4. QUYẾT ĐỊNH
        local myHoney = PlayerUtils.GetHoney()
        local result = { Purchased = false, MissingHoney = 0 }

        if myHoney >= price then
            if LogFunc then LogFunc("💰 Giá: " .. price .. " -> Mua ngay!", Color3.fromRGB(0, 255, 0)) end
            local buySuccess = ExecuteBuy("Basic Egg", "Eggs")
            if buySuccess then
                result.Purchased = true
                if LogFunc then LogFunc("✅ Mua thành công!", Color3.fromRGB(0, 255, 0)) end
            else
                if LogFunc then LogFunc("❌ Server từ chối mua!", Color3.fromRGB(255, 0, 0)) end
            end
        else
            result.MissingHoney = price - myHoney
            Utils.SaveData("NextEggPrice", price)
            if LogFunc then LogFunc("📉 Thiếu " .. result.MissingHoney .. " Honey. Đang lưu giá...", Color3.fromRGB(255, 100, 100)) end
        end

        -- 5. Đóng Shop
        task.wait(0.5)
        ToggleShopUI()
        task.wait(1)

        return result
    end

    -- B. LOGIC CHO ITEM THƯỜNG
    local data = ShopData[itemName]
    if not data then 
        if LogFunc then LogFunc("❌ Không tìm thấy data item: " .. itemName, Color3.fromRGB(255, 0, 0)) end
        return { Purchased = false, Error = "NoData" } 
    end

    local myHoney = PlayerUtils.GetHoney()
    if myHoney < data.Price then
        return { Purchased = false, MissingHoney = data.Price - myHoney }
    end

    if data.Ingredients then
        for matName, matNeed in pairs(data.Ingredients) do
            local matHave = PlayerUtils.GetItemAmount(matName)
            if matHave < matNeed then
                return { Purchased = false, MissingMats = matName }
            end
        end
    end

    if LogFunc then LogFunc("🛒 Đang mua item: " .. itemName, Color3.fromRGB(0, 255, 0)) end
    local success = ExecuteBuy(itemName, data.Category)
    
    return { Purchased = success }
end

return module
