local module = {}
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- =======================================================
-- DỮ LIỆU CỨNG (HARDCODED DATA) - KHÔNG CẦN TẢI TỪ WEB
-- =======================================================
local ShopData = {
    -- 1. GIÁ TRỨNG (BASIC EGG PRICES)
    ["Basic Egg"] = {
        [1] = 1000,    [2] = 2500,    [3] = 4250,    [4] = 6708,
        [5] = 10313,   [6] = 15669,   [7] = 23670,   [8] = 35648,
        [9] = 53596,   [10]= 80506,   [11]= 120858,  [12]= 181378,
        [13]= 272151,  [14]= 408304,  [15]= 612527
    },

    -- 2. CÔNG CỤ (TOOLS) - BASIC SHOP
    ["Rake"] =     { Price = 800,   Type = "Collector", Category = "Collector" },
    ["Clippers"] = { Price = 2200,  Type = "Collector", Category = "Collector" },
    ["Magnet"] =   { Price = 5500,  Type = "Collector", Category = "Collector" },
    ["Vacuum"] =   { Price = 14000, Type = "Collector", Category = "Collector" },

    -- 3. CÔNG CỤ (TOOLS) - PRO SHOP
    ["Super-Scooper"]  = { Price = 40000,    Type = "Collector", Category = "Collector" },
    ["Pulsar"]         = { Price = 125000,   Type = "Collector", Category = "Collector" },
    ["Electro-Magnet"] = { Price = 300000,   Type = "Collector", Category = "Collector" },
    ["Scissors"]       = { Price = 850000,   Type = "Collector", Category = "Collector" },
    ["Honey Dipper"]   = { Price = 1500000,  Type = "Collector", Category = "Collector" },

    -- 4. BALO (CONTAINERS) - BASIC SHOP
    ["Jar"] =      { Price = 650,   Type = "Container", Category = "Accessory" },
    ["Backpack"] = { Price = 5500,  Type = "Container", Category = "Accessory" },
    ["Canister"] = { Price = 22000, Type = "Container", Category = "Accessory" },

    -- 5. BALO (CONTAINERS) - PRO SHOP
    ["Mega-Jug"]    = { Price = 50000,    Type = "Container", Category = "Accessory" },
    ["Compressor"]  = { Price = 160000,   Type = "Container", Category = "Accessory" },
    ["Elite Barrel"]= { Price = 650000,   Type = "Container", Category = "Accessory" },
    ["Port-O-Hive"] = { Price = 1250000,  Type = "Container", Category = "Accessory" },

    -- 6. PHỤ KIỆN (ACCESSORIES) - BASIC SHOP
    ["Helmet"] = {
        Price = 30000, Type = "Accessory", Category = "Accessory",
        Ingredients = { ["Pineapple"] = 5, ["MoonCharm"] = 1 }
    },
    ["Belt Pocket"] = {
        Price = 14000, Type = "Accessory", Category = "Accessory",
        Ingredients = { ["SunflowerSeed"] = 10 }
    },
    ["Basic Boots"] = { 
        Price = 4400, Type = "Accessory", Category = "Accessory",
        Ingredients = { ["SunflowerSeed"] = 3, ["Blueberry"] = 3 }
    },

    -- 7. PHỤ KIỆN (ACCESSORIES) - PRO SHOP
    ["Propeller Hat"] = {
        Price = 2500000, Type = "Accessory", Category = "Accessory",
        Ingredients = { ["Gumdrops"] = 25, ["Pineapple"] = 100, ["MoonCharm"] = 5 }
    },
    ["Brave Guard"] = {
        Price = 300000, Type = "Accessory", Category = "Accessory",
        Ingredients = { ["Stinger"] = 3 }
    },
    ["Hasty Guard"] = { 
        Price = 300000, Type = "Accessory", Category = "Accessory",
        Ingredients = { ["MoonCharm"] = 5 }
    },
    ["Bomber Guard"] = {
        Price = 300000, Type = "Accessory", Category = "Accessory",
        Ingredients = { ["SunflowerSeed"] = 25 }
    },
    ["Looker Guard"] = {
        Price = 300000, Type = "Accessory", Category = "Accessory",
        Ingredients = { ["SunflowerSeed"] = 25 }
    },
    ["Belt Bag"] = {
        Price = 440000, Type = "Accessory", Category = "Accessory",
        Ingredients = { ["Pineapple"] = 50, ["SunflowerSeed"] = 50, ["Stinger"] = 3 }
    },
    ["Hiking Boots"] = {
        Price = 2200000, Type = "Accessory", Category = "Accessory",
        Ingredients = { ["Blueberry"] = 50, ["Strawberry"] = 50 }
    }
}

-- =======================================================
-- HÀM MUA (DÙNG DỮ LIỆU CỨNG)
-- =======================================================
function module.Buy(itemName, category)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    -- 1. Xử lý ngoại lệ: Basic Egg luôn nằm trong "Eggs"
    if itemName == "Basic Egg" then 
        category = "Eggs" 
    end
    
    -- 2. Nếu thiếu category, tự tìm trong ShopData
    if not category then
        if ShopData[itemName] then
            category = ShopData[itemName].Category
        end
    end

    -- 3. Gửi lệnh mua (Dùng pcall cho an toàn)
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
-- HÀM KIỂM TRA MUA (DÙNG DỮ LIỆU CỨNG)
-- =======================================================
function module.CheckRequirements(itemName, PlayerUtils, LogFunc)
    -- 1. XỬ LÝ BASIC EGG (MUA TRỨNG SLOT)
    if itemName == "Basic Egg" then
        local currentBees = PlayerUtils.GetBeeCount() 
        local eggIndex = math.max(1, currentBees) 
        
        local price = 1000 
        if ShopData["Basic Egg"] and ShopData["Basic Egg"][eggIndex] then
            price = ShopData["Basic Egg"][eggIndex]
        end

        local myHoney = PlayerUtils.GetHoney()
        if myHoney < price then
            return {CanBuy = false, MissingHoney = price - myHoney, MissingMats = {}, Price = price}
        else
            return {CanBuy = true, Price = price, MissingHoney = 0, MissingMats = {}}
        end
    end

    -- 2. XỬ LÝ ITEM THƯỜNG
    local data = ShopData[itemName]
    if not data then
        if LogFunc then LogFunc("❌ Không có dữ liệu: " .. itemName, Color3.fromRGB(255, 0, 0)) end
        return {CanBuy = false, Error = "NoData"}
    end

    local result = {
        CanBuy = true,
        Price = data.Price or 0,
        MissingHoney = 0,
        MissingMats = {}
    }

    -- Check Tiền
    local myHoney = PlayerUtils.GetHoney()
    if myHoney < result.Price then
        result.CanBuy = false
        result.MissingHoney = result.Price - myHoney
    end

    -- Check Nguyên Liệu
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
