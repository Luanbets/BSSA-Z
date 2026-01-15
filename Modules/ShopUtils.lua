local module = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- [NEW] Remote kiểm tra kho đồ từ Server
local RetrieveStatsRemote = ReplicatedStorage:WaitForChild("Events", 5) and ReplicatedStorage.Events:WaitForChild("RetrievePlayerStats", 5)

-- [RAM ONLY] Biến này sẽ mất khi tắt script hoặc disconnect
local CachedEggPrice = nil 

-- BẢNG GIÁ TRỨNG CỐ ĐỊNH (DATA CỨNG)
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

-- BẢNG GIÁ ITEM (ĐÃ CẬP NHẬT)
local ShopData = {
    ["Rake"]           = { Price = 800,       Type = "Collector", Category = "Collector" },
    ["Clippers"]       = { Price = 2200,      Type = "Collector", Category = "Collector" },
    ["Magnet"]         = { Price = 5500,      Type = "Collector", Category = "Collector" },
    ["Vacuum"]         = { Price = 14000,     Type = "Collector", Category = "Collector" },
    ["Super-Scooper"]  = { Price = 40000,     Type = "Collector", Category = "Collector" },
    ["Pulsar"]         = { Price = 125000,    Type = "Collector", Category = "Collector" },
    ["Electro-Magnet"] = { Price = 300000,    Type = "Collector", Category = "Collector" },
    ["Scissors"]       = { Price = 850000,    Type = "Collector", Category = "Collector" },
    ["Honey Dipper"]   = { Price = 1500000,   Type = "Collector", Category = "Collector" },
    ["Jar"]            = { Price = 650,       Type = "Container", Category = "Accessory" },
    ["Backpack"]       = { Price = 5500,      Type = "Container", Category = "Accessory" },
    ["Canister"]       = { Price = 22000,     Type = "Container", Category = "Accessory" },
    ["Mega-Jug"]       = { Price = 50000,     Type = "Container", Category = "Accessory" },
    ["Compressor"]     = { Price = 160000,    Type = "Container", Category = "Accessory" },
    ["Elite Barrel"]   = { Price = 650000,    Type = "Container", Category = "Accessory" },
    ["Port-O-Hive"]    = { Price = 1250000,   Type = "Container", Category = "Accessory" },
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

-- [HÀM ĐÃ SỬA] Kiểm tra sở hữu Item từ Server (Silent Mode)
local function HasItem(itemName)
    if not RetrieveStatsRemote then return false end

    -- Gọi server lấy data (Chạy ngầm, không báo lỗi nếu fail)
    local success, stats = pcall(function() 
        return RetrieveStatsRemote:InvokeServer() 
    end)

    if not success or not stats then return false end

    -- Chỉ quét 3 danh mục yêu cầu
    local searchTargets = {
        stats.Collectors,   -- Tool
        stats.Backpacks,    -- Balo
        stats.Accessories   -- Phụ kiện
    }

    for _, category in pairs(searchTargets) do
        if type(category) == "table" then
            -- Quét sạch (check cả Key lẫn Value để không sót)
            for key, val in pairs(category) do
                if tostring(key) == itemName or tostring(val) == itemName then
                    return true -- Đã có hàng
                end
            end
        end
    end

    return false -- Không tìm thấy
end

function module.GetCurrentEggIndex(LogFunc)
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
    if CachedEggPrice and EggData[CachedEggPrice] then
        return EggData[CachedEggPrice].Index
    end
    return 0 
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
    -- A. BASIC EGG
    -- ==========================================
    if itemName == "Basic Egg" then
        if not CachedEggPrice then module.GetCurrentEggIndex(LogFunc) end
        local myHoney = PlayerUtils.GetHoney()
        if myHoney < CachedEggPrice then
            return { Purchased = false, MissingHoney = CachedEggPrice - myHoney, Price = CachedEggPrice }
        else
            if LogFunc then LogFunc("💰 Mua trứng giá: " .. CachedEggPrice, Color3.fromRGB(0, 255, 0)) end
            Utils.Tween(CFrame.new(-137, 4, 244))
            task.wait(0.5)
            local success = TryPurchase("Basic Egg", "Eggs", PlayerUtils)
            if success then
                local data = EggData[CachedEggPrice]
                if data then
                    CachedEggPrice = data.Next
                    if LogFunc then LogFunc("🔮 Giá tiếp theo: " .. CachedEggPrice, Color3.fromRGB(0, 255, 255)) end
                else
                    CachedEggPrice = nil 
                end
                return { Purchased = true }
            else
                return { Purchased = false }
            end
        end
    end

    -- ==========================================
    -- B. ITEM THƯỜNG (Đã Fix Loop)
    -- ==========================================
    local data = ShopData[itemName]
    if not data then return { Purchased = false, Error = "NoData" } end

    -- [FIX LOOP] Kiểm tra xem có chưa TRƯỚC khi mua
    if HasItem(itemName) then
        if LogFunc then LogFunc("✅ Đã có item: " .. itemName .. ". Bỏ qua!", Color3.fromRGB(0, 255, 0)) end
        return { Purchased = true } -- Trả về True để Starter biết mà skip
    end

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
    
    -- [FAILSAFE] Nếu mua thất bại nhưng tiền vẫn còn nguyên (và > giá),
    -- rất có thể do đã sở hữu mà hàm HasItem không tìm thấy hoặc lag.
    -- Ta trả về True luôn để tránh kẹt loop vô tận.
    if not success and myHoney >= data.Price then
        if LogFunc then LogFunc("⚠️ Mua không trừ tiền (Có thể đã có). Skip luôn!", Color3.fromRGB(255, 170, 0)) end
        return { Purchased = true }
    end

    return { Purchased = success }
end

return module
