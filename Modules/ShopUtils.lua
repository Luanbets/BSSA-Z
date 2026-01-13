local module = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- =======================================================
-- LOAD UTILITIES TỪ URL CÓ SẴN (ĐỂ DÙNG TWEEN VÀ SAVE)
-- =======================================================
local Utils = nil
local success, result = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Luanbets/BSSA-Z/refs/heads/main/Modules/Utilities.lua"))()
end)

if success and result then
    Utils = result
else
    warn("❌ ShopUtils: Không thể tải Utilities.lua! Các tính năng Tween/Save sẽ lỗi.")
    -- Tạo bảng rỗng để tránh crash script nếu load lỗi
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
-- DỮ LIỆU CỨNG (SHOP DATA)
-- =======================================================
local ShopData = {
    -- Basic Egg: Logic mới sẽ check giá trực tiếp, data này chỉ để dự phòng
    ["Basic Egg"] = {},

    -- CÁC ITEM KHÁC (GIỮ NGUYÊN)
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
-- HÀM MUA (GIỮ NGUYÊN)
-- =======================================================
function module.Buy(itemName, category)
    if itemName == "Basic Egg" then category = "Eggs" end
    if not category and ShopData[itemName] then category = ShopData[itemName].Category end

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
-- HÀM CHECK REQUIREMENT (UPDATE LOGIC MỚI)
-- =======================================================
function module.CheckRequirements(itemName, PlayerUtils, LogFunc)
    -- A. XỬ LÝ BASIC EGG (MOVE -> OPEN UI -> CHECK -> SAVE -> CLOSE)
    if itemName == "Basic Egg" then
        if LogFunc then LogFunc("🏃 Moving to Egg Shop to check price...", Color3.fromRGB(255, 255, 0)) end

        -- 1. Tween tới Shop (Dùng hàm Tween của Utilities.lua)
        Utils.Tween(CFrame.new(-137, 4, 244))
        task.wait(0.5)

        -- 2. Mở Shop (Nhấn E)
        ToggleShopUI()

        -- 3. Lấy giá từ UI
        local price = 1000 -- Giá mặc định
        local startTime = tick()
        local uiFound = false
        
        while tick() - startTime < 8 do -- Timeout 8s
            local screenGui = PlayerGui:FindFirstChild("ScreenGui")
            local shopFrame = screenGui and screenGui:FindFirstChild("Shop")
            local itemInfo = shopFrame and shopFrame:FindFirstChild("ItemInfo")
            local itemCostLabel = itemInfo and itemInfo:FindFirstChild("ItemCost")

            if shopFrame and shopFrame.Visible and itemCostLabel then
                price = ParsePrice(itemCostLabel.Text)
                uiFound = true
                if LogFunc then LogFunc("🏷️ Current Egg Price: " .. price, Color3.fromRGB(0, 255, 255)) end
                break
            end
            task.wait(0.5)
        end

        -- 4. Đóng Shop (Nhấn E lần nữa) - Luôn đóng dù mua hay không
        task.wait(0.5)
        ToggleShopUI()
        task.wait(1) -- Chờ UI đóng hẳn

        -- 5. Kiểm tra tiền & Lưu data (Dùng hàm SaveData của Utilities.lua)
        local myHoney = PlayerUtils.GetHoney()
        
        if myHoney < price then
            if LogFunc then LogFunc("📉 Not enough honey ("..myHoney.."/"..price.."). Saving state...", Color3.fromRGB(255, 100, 100)) end
            
            -- LƯU DATA VÀO FILE CÓ SẴN
            Utils.SaveData("NextEggPrice", price)
            
            return {CanBuy = false, MissingHoney = price - myHoney, MissingMats = {}, Price = price}
        else
            if LogFunc then LogFunc("✅ Enough honey! Ready to buy.", Color3.fromRGB(0, 255, 0)) end
            return {CanBuy = true, Price = price, MissingHoney = 0, MissingMats = {}}
        end
    end

    -- B. XỬ LÝ ITEM THƯỜNG (GIỮ NGUYÊN LOGIC CŨ)
    local data = ShopData[itemName]
    if not data then return {CanBuy = false, Error = "NoData"} end

    local result = { CanBuy = true, Price = data.Price or 0, MissingHoney = 0, MissingMats = {} }
    
    local myHoney = PlayerUtils.GetHoney()
    if myHoney < result.Price then
        result.CanBuy = false
        result.MissingHoney = result.Price - myHoney
    end

    if data.Ingredients then
        for matName, matNeed in pairs(data.Ingredients) do
            local matHave = PlayerUtils.GetItemAmount(matName)
            if matHave < matNeed then
                result.CanBuy = false
                table.insert(result.MissingMats, {Name = matName, Amount = matNeed - matHave})
            end
        end
    end

    return result
end

return module
