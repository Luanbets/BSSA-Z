local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

-- Hàm tải module từ Github (Chống Cache)
local function LoadModule(url)
    local finalUrl = url .. "?t=" .. tostring(tick())
    local success, content = pcall(function() return game:HttpGet(finalUrl) end)
    if success then
        local func = loadstring(content)
        if func then return func() end
    end
    warn("Failed to load: " .. url)
    return nil
end

-- === BASE URL ===
local REPO = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/refs/heads/main/Modules/"

task.spawn(function()
    print("--- LOADING SYSTEM ---")

    -- 1. LOAD CÁC WORKER CƠ BẢN (DATA & UTILS)
    local Utils       = LoadModule(REPO .. "Utilities.lua")
    local FieldData   = LoadModule(REPO .. "FieldData.lua")
    local TokenData   = LoadModule(REPO .. "TokenData.lua")
    local PlayerUtils = LoadModule(REPO .. "PlayerUtils.lua")
    local ShopUtils   = LoadModule(REPO .. "ShopUtils.lua")
    local AutoFarm    = LoadModule(REPO .. "AutoFarm.lua")
    
    -- Kiểm tra tải thành công
    if not (Utils and FieldData and TokenData and PlayerUtils and ShopUtils and AutoFarm) then
        warn("Lỗi tải thư viện cơ bản!")
        return
    end

    -- Hàm Log & Wait (Truyền vào các cột mốc)
    local function Log(txt, clr) print(txt) end -- Bạn có thể thay bằng UI Log của bạn
    local function WaitFunc() task.wait() end

    -- 2. CLAIM HIVE & REDEEM CODE
    local ClaimHive = LoadModule(REPO .. "ClaimHive.lua")
    if ClaimHive then ClaimHive.Run(Log, WaitFunc, Utils) end

    local RedeemCode = LoadModule(REPO .. "RedeemCode.lua")
    if RedeemCode then RedeemCode.Run(Log, WaitFunc, Utils) end

    -- 3. CHẠY TIẾN TRÌNH (COT MOC)
    -- Nhìn kỹ: Main truyền TOÀN BỘ công cụ vào Cột Mốc
    local UserData = Utils.LoadData()

    if not UserData.Cotmoc1Done then
        local Cotmoc1 = LoadModule(REPO .. "Cotmoc1.lua")
        if Cotmoc1 then
            -- SYNC: Cotmoc1 nhận AutoFarm, ShopUtils, FieldData... từ Main
            Cotmoc1.Run(Log, WaitFunc, Utils, ShopUtils, PlayerUtils, AutoFarm, FieldData, TokenData)
        end
    end
    
    -- Sau này bạn thêm if not 5BeeZoneDone thì load 5BeeZone.lua và truyền y hệt...
    print("--- SYSTEM READY ---")
end)
