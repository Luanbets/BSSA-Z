-- ====================================================
-- BSSA-Z: MASTER CONTROLLER (INTEGRATED VERSION)
-- ====================================================
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- 1. SETUP UI STATUS
local uiName = "BSSA_Status"
if CoreGui:FindFirstChild(uiName) then CoreGui[uiName]:Destroy() end
local screen = Instance.new("ScreenGui", CoreGui); screen.Name = uiName
local lbl = Instance.new("TextLabel", screen)
lbl.Size = UDim2.new(0, 300, 0, 30); lbl.Position = UDim2.new(0.5, -150, 0.05, 0)
lbl.BackgroundColor3 = Color3.fromRGB(0,0,0); lbl.TextColor3 = Color3.fromRGB(0,255,0)
lbl.BackgroundTransparency = 0.5; lbl.Text = "BSSA-Z: Starting..."

local function Log(text) 
    lbl.Text = "STATUS: " .. text 
end

-- ==============================================================================
-- 2. TÍCH HỢP SHOPUTILS TRỰC TIẾP (KHÔNG CẦN TẢI TỪ GITHUB NỮA)
-- ==============================================================================
local ShopUtilsModule = (function()
    local module = {}
    -- Dữ liệu JSON rút gọn (Đã bao gồm Backpack, Rake, Guards, Masks...)
    local RawJson = [[
    {"Accessories":{"Belt Bag":{"Stats":[["Belt Bag",1]],"Name":"Belt Bag","Category":"Accessory/Bag","ID":"Belt Bag","Price":440000,"Ingredients":[["Pineapple",50],["SunflowerSeed",50],["Stinger",3]]},"Looker Guard":{"Stats":[["Looker Guard",1]],"Name":"Looker Guard","Category":"Accessory/Bag","ID":"Looker Guard","Price":300000,"Ingredients":[["SunflowerSeed",25]]},"Jar":{"Stats":[["Jar",1]],"Name":"Jar","Category":"Accessory/Bag","ID":"Jar","Price":650,"Ingredients":[]},"Pouch":{"Stats":[["Pouch",1]],"Name":"Pouch","Category":"Accessory/Bag","ID":"Pouch","Price":0,"Ingredients":[]},"Backpack":{"Stats":[["Backpack",1]],"Name":"Backpack","Category":"Accessory/Bag","ID":"Backpack","Price":5500,"Ingredients":[]},"Basic Boots":{"Stats":[["Basic Boots",1]],"Name":"Basic Boots","Category":"Accessory/Bag","ID":"Basic Boots","Price":4400,"Ingredients":[["SunflowerSeed",3],["Blueberry",3]]},"Rake":{"Stats":[],"Name":"Rake","Category":"Tool","ID":"Rake","Price":800,"Ingredients":[]}},"Collectors":{"Rake":{"Stats":[],"Name":"Rake","Category":"Tool","ID":"Rake","Price":800,"Ingredients":[]},"Pulsar":{"Stats":[],"Name":"Pulsar","Category":"Tool","ID":"Pulsar","Price":125000,"Ingredients":[]},"Scissors":{"Stats":[],"Name":"Scissors","Category":"Tool","ID":"Scissors","Price":850000,"Ingredients":[]},"Golden Rake":{"Stats":[],"Name":"Golden Rake","Category":"Tool","ID":"Golden Rake","Price":20000000,"Ingredients":[]},"Magnet":{"Stats":[],"Name":"Magnet","Category":"Tool","ID":"Magnet","Price":5500,"Ingredients":[]}}}
    ]]
    -- Lưu ý: Mình dùng bản JSON rút gọn các item quan trọng để code nhẹ hơn.
    -- Nếu bạn cần full JSON cũ, script vẫn hoạt động tốt với Backpack/Rake.

    local ToolDB = nil
    pcall(function() ToolDB = HttpService:JSONDecode(RawJson) end)

    function module.GetItemAmount(itemName)
        local inventory = LocalPlayer:FindFirstChild("b") 
        local eggs = LocalPlayer:FindFirstChild("EggStats") 
        if inventory and inventory:FindFirstChild(itemName) then return inventory[itemName].Value end
        if eggs and eggs:FindFirstChild(itemName) then return eggs[itemName].Value end
        return 0 
    end

    function module.GetHoney()
        if LocalPlayer:FindFirstChild("CoreStats") and LocalPlayer.CoreStats:FindFirstChild("Honey") then
            return LocalPlayer.CoreStats.Honey.Value
        end
        return 0
    end

    local function FindItemData(itemName)
        if not ToolDB then return nil end
        if ToolDB.Accessories[itemName] then return ToolDB.Accessories[itemName] end
        if ToolDB.Collectors[itemName] then return ToolDB.Collectors[itemName] end
        return nil
    end

    function module.CheckBuy(itemName, LogFunc)
        local data = FindItemData(itemName)
        if not data then
            if LogFunc then LogFunc("❌ Data Error: " .. itemName, Color3.fromRGB(255, 0, 0)) end
            return false
        end
        
        local price = data.Price or 0
        local ingredients = data.Ingredients or {}
        
        -- Check Tiền
        if module.GetHoney() < price then
            if LogFunc then LogFunc("❌ Thiếu Tiền: " .. itemName, Color3.fromRGB(255, 80, 80)) end
            return false
        end

        -- Check Nguyên Liệu
        for _, req in pairs(ingredients) do
            local matName = req[1]; local matNeed = req[2]
            if module.GetItemAmount(matName) < matNeed then
                if LogFunc then LogFunc("❌ Thiếu: " .. matName, Color3.fromRGB(255, 80, 80)) end
                return false
            end
        end
        return true
    end
    return module
end)()

-- ==============================================================================
-- 3. HÀM LOAD CÁC MODULE KHÁC (AUTOFARM, STARTER...)
-- ==============================================================================
local function LoadWorker(name)
    -- Thử tải bằng link chính
    local url = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/" .. name .. ".lua?t="..tick()
    local success, content = pcall(function() return game:HttpGet(url) end)
    
    if success and content ~= "404: Not Found" then
        local func = loadstring(content)
        if func then return func() end
    end
    
    -- Thử tải bằng link dự phòng (refs/heads)
    local url2 = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/refs/heads/main/Modules/" .. name .. ".lua?t="..tick()
    local success2, content2 = pcall(function() return game:HttpGet(url2) end)
    
    if success2 and content2 ~= "404: Not Found" then
        local func = loadstring(content2)
        if func then return func() end
    end

    return nil
end

Log("Loading Modules...")

-- TẠO BỘ CÔNG CỤ (DÙNG SHOPUTILS ĐÃ NHÚNG)
local Toolkit = {
    Utils       = LoadWorker("Utilities"),
    FieldData   = LoadWorker("FieldData"),
    TokenData   = LoadWorker("TokenData"),
    ShopUtils   = ShopUtilsModule,       -- << DÙNG BẢN TÍCH HỢP (KHÔNG CẦN TẢI)
    PlayerUtils = LoadWorker("PlayerUtils"), 
    AutoFarm    = LoadWorker("AutoFarm"),
    ClaimHive   = LoadWorker("ClaimHive"),
    RedeemCode  = LoadWorker("RedeemCode"),
}

-- KIỂM TRA LẠI
if not Toolkit.AutoFarm or not Toolkit.PlayerUtils then
    Log("❌ Error: Failed to load AutoFarm/PlayerUtils")
    return
end

-- ====================================================
-- 4. LOGIC CHÍNH
-- ====================================================

-- A. Claim Hive
Log("Checking Hive...")
if Toolkit.ClaimHive then
    local hasHive = Toolkit.ClaimHive.Run(Log, task.wait, Toolkit.Utils)
    if not hasHive then Log("❌ No Hive! Stopped."); return end
end

Log("✅ Ready! Starting Loop...")

-- B. Vòng lặp quản lý
task.spawn(function()
    while true do
        task.wait(1)
        
        local beeCount = Toolkit.AutoFarm.GetRealBeeCount()
        
        if beeCount < 5 then
            if not Toolkit.Starter then 
                Toolkit.Starter = LoadWorker("Cotmoc1") 
            end
            
            if Toolkit.Starter then
                pcall(function() Toolkit.Starter.Run(Log, task.wait, Toolkit) end)
            end
            
        elseif beeCount < 10 then
            Log("Phase: 5 Bee Zone")
        else
            Log("Phase: High Level")
        end
    end
end)
