local module = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

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
    Utils = { Tween = function() end, SaveData = function() end }
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
    ["Rake"] =     { Price = 800,   Type = "Collector", Category = "Collector" },
    ["Clippers"] = { Price = 2200,  Type = "Collector", Category = "Collector" },
    ["Magnet"] =   { Price = 5500,  Type = "Collector", Category = "Collector" },
    ["Vacuum"] =   { Price = 14000, Type = "Collector", Category = "Collector" },
    ["Super-Scooper"]  = { Price = 40000,    Type = "Collector", Category = "Collector" },
    ["Pulsar"]         = { Price = 125000,   Type = "Collector", Category = "Collector" },
    ["Electro-Magnet"] = { Price = 300000,   Type = "Collector", Category = "Collector" },
    ["Scissors"]       = { Price = 850000,   Type = "Collector", Category = "Collector" },
    ["Honey Dipper"]   = { Price = 1500000,  Type = "Collector", Category = "Collector" },
    ["Jar"] =      { Price = 650,   Type = "Container", Category = "Accessory" },
    ["Backpack"] = { Price = 5500,  Type = "Container", Category = "Accessory" },
    ["Canister"] = { Price = 22000, Type = "Container", Category = "Accessory" },
    ["Mega-Jug"]    = { Price = 50000,    Type = "Container", Category = "Accessory" },
    ["Compressor"]  = { Price = 160000,   Type = "Container", Category = "Accessory" },
    ["Elite Barrel"]= { Price = 650000,   Type = "Container", Category = "Accessory" },
    ["Port-O-Hive"] = { Price = 1250000,  Type = "Container", Category = "Accessory" },
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
-- 3. HÀM MUA CHÍNH XÁC (FIX TYPE & CHECK TIỀN)
-- =======================================================
local function TryPurchase(itemName, category, PlayerUtils)
    -- Lấy tiền cũ
    local oldHoney = PlayerUtils.GetHoney()
    
    -- Gửi lệnh mua
    local success, err = pcall(function()
        -- FIX: item "Basic" chứ không phải "Basic Egg"
        local typeToSend = itemName 
        if itemName == "Basic Egg" then typeToSend = "Basic" end

        ReplicatedStorage.Events.ItemPackageEvent:InvokeServer("Purchase", {
            ["Type"] = typeToSend, 
            ["Category"] = category,
            ["Amount"] = 1
        })
    end)

    -- Đợi server xử lý
    task.wait(1.5)

    -- Kiểm tra lại tiền
    local newHoney = PlayerUtils.GetHoney()

    -- Nếu tiền đã giảm -> Mua thành công thật
    if newHoney < oldHoney then
        return true
    else
        return false -- Tiền y nguyên -> Mua thất bại
    end
end

-- =======================================================
-- 4. HÀM CHECK VÀ MUA
-- =======================================================
function module.CheckAndBuy(itemName, PlayerUtils, LogFunc)
    -- A. LOGIC ĐẶC BIỆT CHO BASIC EGG
    if itemName == "Basic Egg" then
        if LogFunc then LogFunc("🏃 Đang bay tới Shop Trứng...", Color3.fromRGB(255, 255, 0)) end

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
            if LogFunc then LogFunc("💰 Giá: " .. price .. " -> Đang mua...", Color3.fromRGB(0, 255, 0)) end
            
            -- GỌI HÀM MUA (ĐÃ FIX TYPE "Basic")
            local realSuccess = TryPurchase("Basic Egg", "Eggs", PlayerUtils)
            
            if realSuccess then
                result.Purchased = true
                if LogFunc then LogFunc("✅ Mua thành công! (Tiền đã trừ)", Color3.fromRGB(0, 255, 0)) end
            else
                if LogFunc then LogFunc("❌ Mua thất bại! (Tiền không giảm)", Color3.fromRGB(255, 0, 0)) end
            end
        else
            result.MissingHoney = price - myHoney
            Utils.SaveData("NextEggPrice", price)
            if LogFunc then LogFunc("📉 Thiếu " .. result.MissingHoney .. " Honey. Đang đi farm...", Color3.fromRGB(255, 100, 100)) end
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
    
    -- Item thường không cần đổi tên, dùng trực tiếp itemName
    local success = TryPurchase(itemName, data.Category, PlayerUtils)
    
    return { Purchased = success }
end

return module
