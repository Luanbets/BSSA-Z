-- ====================================================
-- MAIN HUB - BSSA-Z (Author: Luanbets)
-- ====================================================

-- 1. LINK MODULE (Đã tự động điền theo Repo của bạn)
local Url_ClaimHive = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/ClaimHive.lua"
local Url_RedeemCode = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/RedeemCode.lua"

-- 2. HÀM TẢI MODULE AN TOÀN
local function LoadModule(url)
    local success, result = pcall(function() return loadstring(game:HttpGet(url))() end)
    if not success then warn("Lỗi tải module: " .. url); return nil end
    return result
end

local ClaimModule = LoadModule(Url_ClaimHive)
local CodeModule = LoadModule(Url_RedeemCode)

-- 3. DANH SÁCH CODE
local myCodes = {
    "Wax", "Nectar", "Roof", "Connoisseur", "Crawlers",
    "38217", "Bopmaster", "GumdropsForScience", "ClubBean", "BeesBuzz123"
}

-- 4. LOGIC CHẠY
task.spawn(function()
    if not ClaimModule or not CodeModule then return end

    print("--- HUB STARTED ---")
    local success = ClaimModule.Run()
    
    if success then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "LuanHub", Text = "Claim Hive Xong! Đang nhập code...", Duration = 5
        })
        CodeModule.Run(myCodes)
    else
        warn("Không tìm thấy tổ trống!")
    end
end)
