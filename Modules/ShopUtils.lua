local module = {}
local HttpService = game:GetService("HttpService")

-- JSON DỮ LIỆU (Đã nén gọn, đảm bảo không lỗi)
local RawJson = [[
{"Accessories":{"Belt Bag":{"Price":440000,"Ingredients":[["Pineapple",50],["SunflowerSeed",50],["Stinger",3]]},"Looker Guard":{"Price":300000,"Ingredients":[["SunflowerSeed",25]]},"Jar":{"Price":650,"Ingredients":[]},"Demon Mask":{"Price":5000000000,"Ingredients":[["Stinger",500],["RedExtract",250],["Enzymes",150],["Glue",100],["InvigoratingVial",1]]},"Propeller Hat":{"Price":2500000,"Ingredients":[["Gumdrops",25],["Pineapple",100],["MoonCharm",5]]},"Pouch":{"Price":0,"Ingredients":[]},"Red Guard":{"Price":750000,"Ingredients":[["Strawberry",50],["RoyalJelly",1],["Stinger",1]]},"Bubble Mask":{"Price":100000000,"Ingredients":[["Blueberry",500],["BlueExtract",50],["Oil",25],["Glitter",15]]},"Elite Blue Guard":{"Price":5000000,"Ingredients":[["BlueExtract",3],["Blueberry",50],["RoyalJelly",5],["MoonCharm",15]]},"Elite Red Guard":{"Price":5000000,"Ingredients":[["RedExtract",3],["Strawberry",50],["RoyalJelly",5],["Stinger",5]]},"Brave Guard":{"Price":300000,"Ingredients":[["Stinger",3]]},"Elite Barrel":{"Price":650000,"Ingredients":[]},"Honeycomb Belt":{"Price":75000000,"Ingredients":[["Enzymes",50],["Glue",50],["Oil",25]]},"Port-O-Hive":{"Price":1250000,"Ingredients":[]},"Diamond Mask":{"Price":5000000000,"Ingredients":[["BlueExtract",250],["Oil",150],["Glitter",100],["Diamond",5],["ComfortingVial",1]]},"Hiking Boots":{"Price":2200000,"Ingredients":[["Blueberry",50],["Strawberry",50]]},"Beekeeper's Mask":{"Price":20000000,"Ingredients":[["Enzymes",5],["Glue",3],["Glitter",1]]},"Helmet":{"Price":30000,"Ingredients":[["Pineapple",5],["MoonCharm",1]]},"Coconut Clogs":{"Price":10000000000,"Ingredients":[["Coconut",150],["TropicalDrink",50],["Glue",100],["Oil",100],["RefreshingVial",1]]},"Petal Belt":{"Price":15000000000,"Ingredients":[["SpiritPetal",1],["StarJelly",25],["Glitter",50],["Glue",100]]},"Porcelain Port-O-Hive":{"Price":250000000,"Ingredients":[["Glitter",3],["SoftWax",3],["MoonCharm",10]]},"Honey Mask":{"Price":100000000,"Ingredients":[["Treat",9999],["Oil",50],["Enzymes",25],["Gold",5]]},"Belt Pocket":{"Price":14000,"Ingredients":[["SunflowerSeed",10]]},"Bomber Guard":{"Price":300000,"Ingredients":[["SunflowerSeed",25]]},"Red Port-O-Hive":{"Price":12500000,"Ingredients":[["RedExtract",2],["SoftWax",2]]},"Hasty Guard":{"Price":300000,"Ingredients":[["MoonCharm",5]]},"Backpack":{"Name":"Backpack","Category":"Accessory/Bag","ID":"Backpack","Price":5500,"Ingredients":[]},"Basic Boots":{"Price":4400,"Ingredients":[["SunflowerSeed",3],["Blueberry",3]]},"Gummy Mask":{"Price":5000000000,"Ingredients":[["Glue",250],["Enzymes",100],["Oil",100],["Glitter",100],["SatisfyingVial",1]]},"Cobalt Guard":{"Price":200000000,"Ingredients":[["BlueExtract",100],["Stinger",100],["Enzymes",50],["Glitter",25]]},"Bucko Guard":{"Price":30000000,"Ingredients":[["BlueExtract",10],["Blueberry",100],["Glue",5],["MoonCharm",75]]},"Canister":{"Price":22000,"Ingredients":[]},"Riley Guard":{"Price":30000000,"Ingredients":[["RedExtract",10],["Strawberry",100],["Glue",5],["Stinger",25]]},"Blue Port-O-Hive":{"Price":12500000,"Ingredients":[["BlueExtract",2],["SoftWax",2]]},"Mega-Jug":{"Price":50000,"Ingredients":[]},"Crimson Guard":{"Price":200000000,"Ingredients":[["RedExtract",100],["Stinger",100],["Oil",50],["Glitter",25]]},"Beekeeper's Boots":{"Price":15000000,"Ingredients":[["Oil",5],["BlueExtract",3],["RedExtract",3]]},"Gummy Boots":{"Price":100000000000,"Ingredients":[["Glue",500],["RedExtract",250],["BlueExtract",250],["Glitter",250],["SatisfyingVial",1],["MotivatingVial",1]]},"Mondo Belt Bag":{"Price":12400000,"Ingredients":[["SoftWax",1],["Pineapple",150],["SunflowerSeed",150],["Stinger",10]]},"Blue Guard":{"Price":1000000,"Ingredients":[["Blueberry",50],["RoyalJelly",1],["MoonCharm",3]]},"Compressor":{"Price":160000,"Ingredients":[]},"Fire Mask":{"Price":100000000,"Ingredients":[["Strawberry",500],["RedExtract",50],["Enzymes",25],["Glue",15]]}},"Collectors":{"Pulsar":{"Price":125000,"Ingredients":[]},"Scissors":{"Price":850000,"Ingredients":[]},"Golden Rake":{"Price":20000000,"Ingredients":[]},"Momentum Magnet":{"Price":35000000,"Ingredients":[]},"Sticker-Seeker":{"Price":7000000,"Ingredients":[["Glue",1],["Oil",1],["SoftWax",5],["Neonberry",5],["Micro-Converter",10]]},"Porcelain Dipper":{"Price":150000000,"Ingredients":[]},"Dark Scythe":{"Price":2500000000000,"Ingredients":[["RedExtract",1500],["Stinger",150],["HardWax",100],["CausticWax",50],["SuperSmoothie",50],["InvigoratingVial",3]]},"Tide Popper":{"Price":2500000000000,"Ingredients":[["BlueExtract",1500],["Stinger",150],["TropicalDrink",150],["SwirledWax",75],["SuperSmoothie",50],["ComfortingVial",3]]},"Scooper":{"Price":0,"Ingredients":[]},"Spark Staff":{"Price":60000000,"Ingredients":[]},"Super-Scooper":{"Price":40000,"Ingredients":[]},"Honey Dipper":{"Price":1500000,"Ingredients":[]},"Rake":{"Name":"Rake","Category":"Tool","ID":"Rake","Price":800,"Ingredients":[]},"Bubble Wand":{"Price":3500000,"Ingredients":[]},"Petal Wand":{"Price":1500000000,"Ingredients":[["SpiritPetal",1],["StarJelly",10],["Glitter",25],["Enzymes",75]]},"Clippers":{"Price":2200,"Ingredients":[]},"Scythe":{"Price":3500000,"Ingredients":[]},"Vacuum":{"Price":14000,"Ingredients":[]},"Electro-Magnet":{"Price":300000,"Ingredients":[]},"Gummyballer":{"Price":10000000000000,"Ingredients":[["Glue",1500],["Gumdrops",2000],["CausticWax",50],["SuperSmoothie",50],["Turpentine",5],["SatisfyingVial",3]]},"Bow Rake":{"Price":12000000,"Ingredients":[]},"Elite Scythe":{"Price":3500000,"Ingredients":[]},"Magnet":{"Price":5500,"Ingredients":[]}}}
]]

local ToolDB = HttpService:JSONDecode(RawJson)

local function FindItemData(itemName)
    return ToolDB.Accessories[itemName] or ToolDB.Collectors[itemName]
end

function module.CheckBuy(itemName, PlayerUtils, LogFunc)
    local data = FindItemData(itemName)
    if not data then return false end
    
    local price = data.Price or 0
    local ingredients = data.Ingredients or {}
    
    if PlayerUtils.GetHoney() < price then
        if LogFunc then LogFunc("Thiếu Honey mua " .. itemName, Color3.fromRGB(255, 80, 80)) end
        return false
    end

    for _, req in pairs(ingredients) do
        local matName = req[1]
        local matNeed = req[2]
        local matHave = PlayerUtils.GetItemAmount(matName)
        if matHave < matNeed then
            if LogFunc then LogFunc("Thiếu " .. matName .. " (" .. matHave .. "/" .. matNeed .. ")", Color3.fromRGB(255, 80, 80)) end
            return false
        end
    end
    
    return true
end

function module.GetItemInfo(itemName)
    return FindItemData(itemName)
end

return module
