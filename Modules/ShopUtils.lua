local module = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local CachedEggPrice = nil 

-- LOAD UTILITIES AN TOÀN
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
Utils = LoadUtilsSafely() or { Tween = function() end, SaveData = function() end, LoadData = function() return {} end }

-- Load giá cũ nếu có
local savedData = Utils.LoadData()
if savedData.NextEggPrice then CachedEggPrice = savedData.NextEggPrice end

local function ParsePrice(text)
    local cleanStr = text:gsub("%D", "") 
    return tonumber(cleanStr) or 0
end

local function ToggleShopUI()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

local ShopData = {
    ["Basic Egg"] = {}, 
    ["Rake"] = { Price = 800, Type = "Collector", Category = "Collector" },
    ["Clippers"] = { Price = 2200, Type = "Collector", Category = "Collector" },
    ["Magnet"] = { Price = 5500, Type = "Collector", Category = "Collector" },
    ["Vacuum"] = { Price = 14000, Type = "Collector", Category = "Collector" },
    ["Backpack"] = { Price = 5500, Type = "Container", Category = "Accessory" },
    ["Canister"] = { Price = 22000, Type = "Container", Category = "Accessory" },
    ["Belt Pocket"] = { Price = 14000, Type = "Accessory", Category = "Accessory", Ingredients = { ["SunflowerSeed"] = 10 } },
    ["Basic Boots"] = { Price = 4400, Type = "Accessory", Category = "Accessory", Ingredients = { ["SunflowerSeed"] = 3, ["Blueberry"] = 3 } },
    ["Propeller Hat"] = { Price = 2500000, Type = "Accessory", Category = "Accessory", Ingredients = { ["Gumdrops"] = 25, ["Pineapple"] = 100, ["MoonCharm"] = 5 } },
}

local function FetchEggPriceFromShop(LogFunc)
    if LogFunc then LogFunc("🏃 Check giá trứng lần đầu...", Color3.fromRGB(255, 255, 0)) end
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
            break
        end
        task.wait(0.5)
    end
    
    task.wait(0.5)
    ToggleShopUI()
    task.wait(0.5)

    if price > 0 then
        CachedEggPrice = price
        Utils.SaveData("NextEggPrice", price)
        return price
    else
        return 1000000000 
    end
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
    -- A. BASIC EGG
    if itemName == "Basic Egg" then
        if not CachedEggPrice then FetchEggPriceFromShop(LogFunc) end

        local myHoney = PlayerUtils.GetHoney()
        
        if myHoney < CachedEggPrice then
            -- [UPDATE] Trả về thêm field 'Price' để Starter hiển thị
            return { Purchased = false, MissingHoney = CachedEggPrice - myHoney, Price = CachedEggPrice }
        else
            if LogFunc then LogFunc("💰 Đủ tiền ("..myHoney.."/"..CachedEggPrice.."). Mua ngay!", Color3.fromRGB(0, 255, 0)) end
            Utils.Tween(CFrame.new(-137, 4, 244))
            task.wait(0.5)
            
            local success = TryPurchase("Basic Egg", "Eggs", PlayerUtils)
            if success then
                CachedEggPrice = nil 
                Utils.SaveData("NextEggPrice", nil)
                return { Purchased = true }
            else
                if LogFunc then LogFunc("❌ Lỗi mua trứng!", Color3.fromRGB(255, 0, 0)) end
                return { Purchased = false }
            end
        end
    end

    -- B. ITEM THƯỜNG
    local data = ShopData[itemName]
    if not data then return { Purchased = false, Error = "NoData" } end

    local myHoney = PlayerUtils.GetHoney()
    if myHoney < data.Price then
        -- [UPDATE] Trả về Price
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
