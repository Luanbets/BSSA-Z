local module = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Biến lưu giá trứng tạm thời (RAM)
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

-- [CHECK 1] Load giá cũ từ file Save ngay khi chạy script
-- Nếu đã từng check trước đó rồi thì dùng luôn, KHÔNG cần mở UI check lại
local savedData = Utils.LoadData()
if savedData.NextEggPrice and savedData.NextEggPrice > 0 then 
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

-- [HÀM SOI GIÁ] Chỉ chạy khi chưa có giá
local function FetchEggPriceFromShop(LogFunc)
    if LogFunc then LogFunc("🏃 Đang check giá trứng lần đầu (UI)...", Color3.fromRGB(255, 255, 0)) end
    
    -- 1. Bay đến shop
    Utils.Tween(CFrame.new(-137, 4, 244))
    task.wait(0.5)
    
    -- 2. Mở UI
    ToggleShopUI()
    
    local price = 0
    local startTime = tick()
    
    -- 3. Đợi UI hiện ra và đọc số
    while tick() - startTime < 8 do
        local screenGui = PlayerGui:FindFirstChild("ScreenGui")
        local itemCostLabel = screenGui and screenGui:FindFirstChild("Shop") and screenGui.Shop:FindFirstChild("ItemInfo") and screenGui.Shop.ItemInfo:FindFirstChild("ItemCost")
        
        if itemCostLabel and screenGui.Shop.Visible then
            price = ParsePrice(itemCostLabel.Text)
            if price > 0 then break end
        end
        task.wait(0.5)
    end
    
    -- 4. Đóng UI
    task.wait(0.5)
    ToggleShopUI()
    task.wait(0.5)

    if price > 0 then
        CachedEggPrice = price
        -- Lưu ngay vào file để lỡ crash game vào lại vẫn nhớ giá
        Utils.SaveData("NextEggPrice", price)
        if LogFunc then LogFunc("✅ Đã cập nhật giá trứng: " .. price, Color3.fromRGB(0, 255, 0)) end
        return price
    else
        return 1000000000 -- Giá ảo nếu lỗi
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
    -- ==========================================
    -- A. BASIC EGG (Xử lý thông minh)
    -- ==========================================
    if itemName == "Basic Egg" then
        -- 1. Nếu chưa có giá (Cache = nil) -> Đi soi giá bằng UI (Lần đầu)
        if not CachedEggPrice then 
            FetchEggPriceFromShop(LogFunc) 
        end

        local myHoney = PlayerUtils.GetHoney()
        
        -- 2. So sánh tiền với giá đã lưu
        if myHoney < CachedEggPrice then
            -- Chưa đủ tiền -> Trả về thông tin để đi farm tiếp
            return { Purchased = false, MissingHoney = CachedEggPrice - myHoney, Price = CachedEggPrice }
        else
            -- Đủ tiền -> Đi mua (Dùng Remote, không cần UI)
            if LogFunc then LogFunc("💰 Đủ tiền ("..myHoney.."/"..CachedEggPrice.."). Mua ngay!", Color3.fromRGB(0, 255, 0)) end
            
            -- Bay ra shop cho chắc ăn (tránh bị lỗi vị trí)
            Utils.Tween(CFrame.new(-137, 4, 244))
            task.wait(0.5)
            
            local success = TryPurchase("Basic Egg", "Eggs", PlayerUtils)
            
            if success then
                -- [QUAN TRỌNG] Mua xong -> Giá thay đổi -> Xóa giá cũ đi
                CachedEggPrice = nil 
                Utils.SaveData("NextEggPrice", nil)
                return { Purchased = true }
            else
                if LogFunc then LogFunc("❌ Lỗi mua trứng!", Color3.fromRGB(255, 0, 0)) end
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
