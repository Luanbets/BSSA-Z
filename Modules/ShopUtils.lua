local module = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- [RAM ONLY] Biến này sẽ mất khi tắt script hoặc disconnect
-- Tuyệt đối không lưu vào file Save
local CachedEggPrice = nil 

-- ==============================================================================
-- 1. BẢNG GIÁ TRỨNG CỐ ĐỊNH (DATA CỨNG)
-- [Giá_Hiện_Tại] = {Giá_Tiếp_Theo, Số_Thứ_Tự_Trứng}
-- ==============================================================================
local EggData = {
    [1000]      = {Next = 2500,     Index = 1},
    [2500]      = {Next = 4250,     Index = 2},
    [4250]      = {Next = 6708,     Index = 3},
    [6708]      = {Next = 10313,    Index = 4},
    [10313]     = {Next = 15669,    Index = 5},
    [15669]     = {Next = 23670,    Index = 6},
    [23670]     = {Next = 35648,    Index = 7},
    [35648]     = {Next = 53596,    Index = 8},
    [53596]     = {Next = 80506,    Index = 9},
    [80506]     = {Next = 120858,   Index = 10},
    [120858]    = {Next = 181378,   Index = 11},
    [181378]    = {Next = 272151,   Index = 12},
    [272151]    = {Next = 408304,   Index = 13},
    [408304]    = {Next = 612527,   Index = 14},
    [612527]    = {Next = 918857,   Index = 15},
    [918857]    = {Next = 1378348,  Index = 16},
    [1378348]   = {Next = 2067580,  Index = 17},
    [2067580]   = {Next = 3101426,  Index = 18},
    [3101426]   = {Next = 4652191,  Index = 19},
    [4652191]   = {Next = 6978337,  Index = 20},
    [6978337]   = {Next = 10000000, Index = 21},
    [10000000]  = {Next = 10000000, Index = 22}
}

-- ==============================================================================
-- 2. BẢNG GIÁ ITEM (ĐÃ CẬP NHẬT ĐẦY ĐỦ)
-- ==============================================================================
local ShopData = {
    -- Collectors
    ["Rake"]           = { Price = 800,       Type = "Collector", Category = "Collector" },
    ["Clippers"]       = { Price = 2200,      Type = "Collector", Category = "Collector" },
    ["Magnet"]         = { Price = 5500,      Type = "Collector", Category = "Collector" },
    ["Vacuum"]         = { Price = 14000,     Type = "Collector", Category = "Collector" },
    ["Super-Scooper"]  = { Price = 40000,     Type = "Collector", Category = "Collector" },
    ["Pulsar"]         = { Price = 125000,    Type = "Collector", Category = "Collector" },
    ["Electro-Magnet"] = { Price = 300000,    Type = "Collector", Category = "Collector" },
    ["Scissors"]       = { Price = 850000,    Type = "Collector", Category = "Collector" },
    ["Honey Dipper"]   = { Price = 1500000,   Type = "Collector", Category = "Collector" },

    -- Containers
    ["Jar"]            = { Price = 650,       Type = "Container", Category = "Accessory" },
    ["Backpack"]       = { Price = 5500,      Type = "Container", Category = "Accessory" },
    ["Canister"]       = { Price = 22000,     Type = "Container", Category = "Accessory" },
    ["Mega-Jug"]       = { Price = 50000,     Type = "Container", Category = "Accessory" },
    ["Compressor"]     = { Price = 160000,    Type = "Container", Category = "Accessory" },
    ["Elite Barrel"]   = { Price = 650000,    Type = "Container", Category = "Accessory" },
    ["Port-O-Hive"]    = { Price = 1250000,   Type = "Container", Category = "Accessory" },

    -- Accessories
    ["Helmet"]         = { Price = 30000,     Type = "Accessory", Category = "Accessory", Ingredients = { ["Pineapple"] = 5, ["MoonCharm"] = 1 } },
    ["Belt Pocket"]    = { Price = 14000,     Type = "Accessory", Category = "Accessory", Ingredients = { ["SunflowerSeed"] = 10 } },
    ["Basic Boots"]    = { Price = 4400,      Type = "Accessory", Category = "Accessory", Ingredients = { ["SunflowerSeed"] = 3, ["Blueberry"] = 3 } },
    ["Propeller Hat"]  = { Price = 2500000,   Type = "Accessory", Category = "Accessory", Ingredients = { ["Gumdrops"] = 25, ["Pineapple"] = 100, ["MoonCharm"] = 5 } },
    ["Brave Guard"]    = { Price = 300000,    Type = "Accessory", Category = "Accessory", Ingredients = { ["Stinger"] = 3 } },
    ["Hasty Guard"]    = { Price = 300000,    Type = "Accessory", Category = "Accessory", Ingredients = { ["MoonCharm"] = 5 } },
    ["Bomber Guard"]   = { Price = 300000,    Type = "Accessory", Category = "Accessory", Ingredients = { ["SunflowerSeed"] = 25 } },
    ["Looker Guard"]   = { Price = 300000,    Type = "Accessory", Category = "Accessory", Ingredients = { ["SunflowerSeed"] = 25 } },
    ["Belt Bag"]       = { Price = 440000,    Type = "Accessory", Category = "Accessory", Ingredients = { ["Pineapple"] = 50, ["SunflowerSeed"] = 50, ["Stinger"] = 3 } },
    ["Hiking Boots"]   = { Price = 2200000,   Type = "Accessory", Category = "Accessory", Ingredients = { ["Blueberry"] = 50, ["Strawberry"] = 50 } }
}

-- LOAD UTILITIES
local Utils = nil
local function LoadUtilsSafely()
    local url = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/Utilities.lua"
    local success, content = pcall(function() return game:HttpGet(url) end)
    if success then 
        local func = loadstring(content)
        if func then 
            local _, m = pcall(func)
            return m
        end
    end
    return nil
end
Utils = LoadUtilsSafely() or { Tween = function() end, SaveData = function() end, LoadData = function() return {} end }

local function ParsePrice(text)
    local cleanStr = text:gsub("%D", "") 
    return tonumber(cleanStr) or 0
end

local function ToggleShopUI()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

-- ==============================================================================
-- 3. HÀM CHECK INDEX TRỨNG (Dùng cho Starter để Skip nhiệm vụ)
-- ==============================================================================
function module.GetCurrentEggIndex(LogFunc)
    -- Nếu RAM chưa có giá (Mới chạy lại script) -> Đi soi UI 1 lần duy nhất
    if not CachedEggPrice then
        if LogFunc then LogFunc("🔍 Chưa có giá (Reset RAM). Đang soi UI...", Color3.fromRGB(255, 255, 0)) end
        
        Utils.Tween(CFrame.new(-137, 4, 244))
        task.wait(0.5)
        ToggleShopUI()
        
        local price = 0
        local startTime = tick()
        while tick() - startTime < 8 do
            local screenGui = PlayerGui:FindFirstChild("ScreenGui")
            local itemCostLabel = screenGui and screenGui:FindFirstChild("Shop") and screenGui.Shop:FindFirstChild("ItemInfo") and screenGui.Shop.ItemInfo:FindFirstChild("ItemCost")
            if itemCostLabel and screenGui.Shop.Visible then
                price = ParsePrice(itemCostLabel.Text)
                if price > 0 then break end
            end
            task.wait(0.5)
        end
        task.wait(0.5)
        ToggleShopUI()
        
        if price > 0 then
            CachedEggPrice = price
            if LogFunc then LogFunc("✅ Đã lấy giá gốc vào RAM: " .. price, Color3.fromRGB(0, 255, 0)) end
        end
    end

    -- Tra bảng cứng để xem đang ở trứng số mấy
    if CachedEggPrice and EggData[CachedEggPrice] then
        return EggData[CachedEggPrice].Index
    end
    
    return 0 -- Không xác định
end

local function TryPurchase(itemName, category, PlayerUtils)
    local oldHoney = PlayerUtils.GetHoney()
    pcall(function()
        local typeToSend = itemName == "Basic Egg" and "Basic" or itemName
        ReplicatedStorage.Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"] = typeToSend, ["Category"] = category, ["Amount"] = 1})
    end)
    task.wait(1.5)
    return PlayerUtils.GetHoney() < oldHoney
end

function module.CheckAndBuy(itemName, PlayerUtils, LogFunc)
    -- ==========================================
    -- A. BASIC EGG (LOGIC RAM & DỰ ĐOÁN)
    -- ==========================================
    if itemName == "Basic Egg" then
        if not CachedEggPrice then 
            module.GetCurrentEggIndex(LogFunc) -- Tự động đi soi nếu chưa có
        end

        local myHoney = PlayerUtils.GetHoney()
        
        if myHoney < CachedEggPrice then
            return { Purchased = false, MissingHoney = CachedEggPrice - myHoney, Price = CachedEggPrice }
        else
            if LogFunc then LogFunc("💰 Mua trứng giá: " .. CachedEggPrice, Color3.fromRGB(0, 255, 0)) end
            
            Utils.Tween(CFrame.new(-137, 4, 244))
            task.wait(0.5)
            
            local success = TryPurchase("Basic Egg", "Eggs", PlayerUtils)
            
            if success then
                -- [LOGIC CHÍNH] Mua xong -> Tra bảng -> Cập nhật RAM (Không lưu file)
                local data = EggData[CachedEggPrice]
                if data then
                    CachedEggPrice = data.Next
                    if LogFunc then LogFunc("🔮 Giá tiếp theo (Dự đoán): " .. CachedEggPrice, Color3.fromRGB(0, 255, 255)) end
                else
                    CachedEggPrice = nil -- Lỗi lạ -> Reset để lần sau check lại
                end
                return { Purchased = true }
            else
                return { Purchased = false }
            end
        end
    end

    -- ==========================================
    -- B. ITEM THƯỜNG
    -- ==========================================
    local data = ShopData[itemName]
    if not data then return { Purchased = false, Error = "NoData" } end

    local myHoney = PlayerUtils.GetHoney()
    if myHoney < data.Price then
        return { Purchased = false, MissingHoney = data.Price - myHoney, Price = data.Price }
    end

    if data.Ingredients then
        for matName, matNeed in pairs(data.Ingredients) do
            local matHave = PlayerUtils.GetItemAmount(matName)
            if matHave < matNeed then return { Purchased = false, MissingMats = matName } end
        end
    end

    if LogFunc then LogFunc("🛒 Mua vật phẩm: " .. itemName, Color3.fromRGB(0, 255, 0)) end
    local success = TryPurchase(itemName, data.Category, PlayerUtils)
    return { Purchased = success }
end

return module
