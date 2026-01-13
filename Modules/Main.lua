-- ====================================================
-- AUTO BEE SWARM - ZERO TOUCH (MANAGER)
-- Created for: Luận
-- ====================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

-- 1. CẤU HÌNH REPO
local REPO_URL = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/"

-- Hàm tải module thông minh (Cache Busting)
local function LoadModule(scriptName)
    local url = REPO_URL .. scriptName .. "?t=" .. tostring(tick())
    local success, content = pcall(function() return game:HttpGet(url) end)
    if not success then
        warn("❌ Lỗi tải: " .. scriptName)
        return nil
    end
    local func = loadstring(content)
    return func()
end

-- UI LOG NHỎ GỌN
local function CreateLogUI()
    -- (Giữ nguyên UI của bạn hoặc rút gọn, ở đây mình làm hàm log đơn giản để in ra console/màn hình)
    local screen = Instance.new("ScreenGui", CoreGui)
    screen.Name = "BSSA_Log"
    local label = Instance.new("TextLabel", screen)
    label.Size = UDim2.new(1, 0, 0, 30)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 0.5
    label.BackgroundColor3 = Color3.new(0,0,0)
    label.TextColor3 = Color3.new(1,1,1)
    label.TextSize = 18
    return function(msg, color)
        label.Text = msg
        label.TextColor3 = color or Color3.new(1,1,1)
        print("[BSSA]: " .. msg)
    end
end
local Log = CreateLogUI()

-- ====================================================
-- 2. KHỞI TẠO CÁC WORKER (LOAD 1 LẦN DÙNG MÃI)
-- ====================================================
Log("Loading Modules...", Color3.fromRGB(255, 255, 0))

local Utilities   = LoadModule("Utilities.lua")
local PlayerUtils = LoadModule("PlayerUtils.lua")
local ShopUtils   = LoadModule("ShopUtils.lua")
local TokenData   = LoadModule("TokenData.lua")
local FieldData   = LoadModule("FieldData.lua")
local AutoFarm    = LoadModule("AutoFarm.lua")

-- Kiểm tra load thành công
if not (Utilities and PlayerUtils and ShopUtils and TokenData and FieldData and AutoFarm) then
    Log("❌ CRITICAL ERROR: Failed to load modules!", Color3.fromRGB(255, 0, 0))
    return
end

-- ====================================================
-- 3. LOGIC CHÍNH (TIẾN TRÌNH)
-- ====================================================
task.spawn(function()
    local SaveData = Utilities.LoadData() -- Load tiến trình đã lưu
    
    -- A. CLAIM HIVE (Nếu chưa có)
    if not SaveData.HiveClaimed then
        local ClaimHive = LoadModule("ClaimHive.lua")
        if ClaimHive and ClaimHive.Run(Log, task.wait, Utilities) then
            Utilities.SaveData("HiveClaimed", true)
        end
    end

    -- B. REDEEM CODE (Chạy 1 lần)
    if not SaveData.RedeemDone then
        local RedeemCode = LoadModule("RedeemCode.lua")
        if RedeemCode then 
            RedeemCode.Run(Log, task.wait, Utilities) 
        end
    end

    -- C. QUẢN LÝ TIẾN TRÌNH (STARTER -> 5 BEE -> ...)
    -- Truyền toàn bộ công cụ vào Cotmoc để nó tự xử lý
    local Tools = {
        Log = Log,
        Utils = Utilities,
        Player = PlayerUtils,
        Shop = ShopUtils,
        Farm = AutoFarm,
        Field = FieldData
    }

    -- Cột Mốc 1: Starter (Trứng + Dụng cụ cơ bản)
    if not SaveData.Cotmoc1Done then
        local Cotmoc1 = LoadModule("Cotmoc1.lua")
        if Cotmoc1 then
            Cotmoc1.Run(Tools) -- Chạy Cột mốc 1
        end
    end

    -- Cột Mốc 2: 5 Bee Zone (Ví dụ sau này bạn thêm)
    -- if not SaveData.Cotmoc2Done then ... end

    Log("✅ All Tasks Completed (For now)", Color3.fromRGB(0, 255, 0))
end)
