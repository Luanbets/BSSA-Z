local module = {}
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- LOAD DATA (Link tới file ShopData.lua bạn đã tạo)
local DATA_URL = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/ShopData.lua"
local ShopData = {}
local isLoaded = false

local function LoadDatabase(LogFunc)
    if isLoaded then return end
    local success, content = pcall(function() return game:HttpGet(DATA_URL .. "?t=" .. tostring(tick())) end)
    if success then
        local func = loadstring(content)
        if func then ShopData = func(); isLoaded = true end
    elseif LogFunc then
        LogFunc("❌ Lỗi tải ShopData!", Color3.fromRGB(255, 0, 0))
    end
end

-- =======================================================
-- HÀM KIỂM TRA MUA (Gọn gàng - Dùng nhờ PlayerUtils)
-- =======================================================
function module.CheckRequirements(itemName, PlayerUtils, LogFunc)
    if not isLoaded then LoadDatabase(LogFunc) end

    -- 1. XỬ LÝ BASIC EGG (MUA TRỨNG SLOT)
    if itemName == "Basic Egg" then
        -- Dùng PlayerUtils đếm số ong để biết cần mua quả thứ mấy
        local currentBees = PlayerUtils.GetBeeCount() 
        local eggIndex = math.max(1, currentBees) -- Ví dụ: 4 ong -> Mua trứng thứ 4
        
        local price = 1000 -- Giá mặc định
        if ShopData["Basic Egg"] and ShopData["Basic Egg"][eggIndex] then
            price = ShopData["Basic Egg"][eggIndex]
        end

        local myHoney = PlayerUtils.GetHoney() -- Gọi PlayerUtils
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

    -- Check Tiền (Dùng PlayerUtils)
    local myHoney = PlayerUtils.GetHoney()
    if myHoney < result.Price then
        result.CanBuy = false
        result.MissingHoney = result.Price - myHoney
    end

    -- Check Nguyên Liệu (Dùng PlayerUtils)
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
