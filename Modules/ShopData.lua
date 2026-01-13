local ShopData = {
    -- ====================================================
    -- 1. GIÁ TRỨNG (BASIC EGG PRICES)
    -- ====================================================
    ["Basic Egg"] = {
        [1] = 1000,    [2] = 2500,    [3] = 4250,    [4] = 6708,
        [5] = 10313,   [6] = 15669,   [7] = 23670,   [8] = 35648,
        [9] = 53596,   [10]= 80506,   [11]= 120858,  [12]= 181378,
        [13]= 272151,  [14]= 408304,  [15]= 612527
    },

    -- ====================================================
    -- 2. CÔNG CỤ (TOOLS) - BASIC SHOP (CŨ)
    -- ====================================================
    ["Rake"] =     { Price = 800,   Type = "Collector", Category = "Collector" },
    ["Clippers"] = { Price = 2200,  Type = "Collector", Category = "Collector" },
    ["Magnet"] =   { Price = 5500,  Type = "Collector", Category = "Collector" },
    ["Vacuum"] =   { Price = 14000, Type = "Collector", Category = "Collector" },

    -- ====================================================
    -- 3. CÔNG CỤ (TOOLS) - PRO SHOP (MỚI THÊM)
    -- ====================================================
    ["Super-Scooper"]  = { Price = 40000,    Type = "Collector", Category = "Collector" },
    ["Pulsar"]         = { Price = 125000,   Type = "Collector", Category = "Collector" },
    ["Electro-Magnet"] = { Price = 300000,   Type = "Collector", Category = "Collector" },
    ["Scissors"]       = { Price = 850000,   Type = "Collector", Category = "Collector" },
    ["Honey Dipper"]   = { Price = 1500000,  Type = "Collector", Category = "Collector" },

    -- ====================================================
    -- 4. BALO (CONTAINERS) - BASIC SHOP (CŨ)
    -- ====================================================
    ["Jar"] =      { Price = 650,   Type = "Container", Category = "Accessory" },
    ["Backpack"] = { Price = 5500,  Type = "Container", Category = "Accessory" },
    ["Canister"] = { Price = 22000, Type = "Container", Category = "Accessory" },

    -- ====================================================
    -- 5. BALO (CONTAINERS) - PRO SHOP (MỚI THÊM)
    -- ====================================================
    ["Mega-Jug"]    = { Price = 50000,    Type = "Container", Category = "Accessory" },
    ["Compressor"]  = { Price = 160000,   Type = "Container", Category = "Accessory" },
    ["Elite Barrel"]= { Price = 650000,   Type = "Container", Category = "Accessory" },
    ["Port-O-Hive"] = { Price = 1250000,  Type = "Container", Category = "Accessory" },

    -- ====================================================
    -- 6. PHỤ KIỆN (ACCESSORIES) - BASIC SHOP (CŨ)
    -- ====================================================
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

    -- ====================================================
    -- 7. PHỤ KIỆN (ACCESSORIES) - PRO SHOP (MỚI THÊM)
    -- ====================================================
    ["Propeller Hat"] = {
        Price = 2500000, Type = "Accessory", Category = "Accessory",
        Ingredients = { 
            ["Gumdrops"] = 25, 
            ["Pineapple"] = 100, 
            ["MoonCharm"] = 5 
        }
    },
    ["Brave Guard"] = {
        Price = 300000, Type = "Accessory", Category = "Accessory",
        Ingredients = { ["Stinger"] = 3 }
    },
    ["Hasty Guard"] = { -- Bạn ghi là Brave Guard thứ 2, nhưng data này là Hasty Guard
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
        Ingredients = { 
            ["Pineapple"] = 50, 
            ["SunflowerSeed"] = 50, 
            ["Stinger"] = 3 
        }
    },
    ["Hiking Boots"] = {
        Price = 2200000, Type = "Accessory", Category = "Accessory",
        Ingredients = { 
            ["Blueberry"] = 50, 
            ["Strawberry"] = 50 
        }
    }
}

return ShopData
