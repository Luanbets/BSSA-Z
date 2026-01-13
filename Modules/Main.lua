-- ====================================================
-- AUTO BEE SWARM - ZERO TOUCH (MANAGER V2)
-- Created for: Luận
-- ====================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

-- 1. CẤU HÌNH REPO (CHÍNH XÁC TUYỆT ĐỐI)
local REPO_URL = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/"

-- 2. HỆ THỐNG LOG (UI ĐƠN GIẢN ĐỂ THEO DÕI)
local uiName = "BSSA_Manager_UI"
if CoreGui:FindFirstChild(uiName) then CoreGui[uiName]:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = uiName
if pcall(function() screenGui.Parent = CoreGui end) then else screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local logLabel = Instance.new("TextLabel", screenGui)
logLabel.Size = UDim2.new(0.5, 0, 0, 40)
logLabel.Position = UDim2.new(0.25, 0, 0, 0)
logLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
logLabel.BackgroundTransparency = 0.5
logLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
logLabel.TextSize = 18
logLabel.Font = Enum.Font.GothamBold
logLabel.Text = "Initializing BSSA-Z..."

local function Log(text, color)
    logLabel.Text = text
    logLabel.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    print("[BSSA]: " .. text) -- In ra F9 để dễ debug
end

-- 3. HÀM TẢI MODULE AN TOÀN (FIX LỖI NIL VALUE)
local function LoadModule(scriptName)
    local url = REPO_URL .. scriptName .. "?t=" .. tostring(tick())
    
    -- Tải text
    local success, content = pcall(function() return game:HttpGet(url) end)
    if not success then
        Log("❌ HTTP Fail: " .. scriptName, Color3.fromRGB(255, 80, 80))
        warn("[BSSA Error] Could not download: " .. url)
        return nil
    end

    -- Compile code
    local func, loadErr = loadstring(content)
    if not func then
        Log("❌ Syntax Error: " .. scriptName, Color3.fromRGB(255, 80, 80))
        warn("[BSSA Syntax Error] " .. tostring(loadErr))
        return nil
    end

    -- Run code
    local runSuccess, module = pcall(func)
    if not runSuccess then
        Log("❌ Runtime Error: " .. scriptName, Color3.fromRGB(255, 80, 80))
        warn("[BSSA Runtime Error] " .. tostring(module))
        return nil
    end

    return module
end

-- ====================================================
-- 4. LOGIC CHÍNH
-- ====================================================
task.spawn(function()
    task.wait(1)
    Log("Loading Core Modules...", Color3.fromRGB(255, 255, 0))

    -- Tải các Worker (Manager tải 1 lần dùng mãi mãi)
    local Utilities   = LoadModule("Utilities.lua")
    local PlayerUtils = LoadModule("PlayerUtils.lua")
    local ShopUtils   = LoadModule("ShopUtils.lua")
    local TokenData   = LoadModule("TokenData.lua")
    local FieldData   = LoadModule("FieldData.lua")
    local AutoFarm    = LoadModule("AutoFarm.lua")

    -- Kiểm tra nếu thiếu file nào quan trọng thì dừng ngay
    if not (Utilities and PlayerUtils and ShopUtils and TokenData and FieldData and AutoFarm) then
        Log("❌ STOP: Failed to load core modules!", Color3.fromRGB(255, 0, 0))
        return
    end

    -- Gom các công cụ lại thành 1 cái túi (Tools) để truyền đi khắp nơi
    local Tools = {
        Log = Log,
        Utils = Utilities,
        Player = PlayerUtils,
        Shop = ShopUtils,
        Farm = AutoFarm,
        Field = FieldData,
        Token = TokenData
    }

    local SaveData = Utilities.LoadData()
    Log("Welcome back, " .. LocalPlayer.Name, Color3.fromRGB(100, 255, 100))

    -- A. CLAIM HIVE (Chạy nếu chưa claim)
    if not SaveData.HiveClaimed then
        local ClaimHive = LoadModule("ClaimHive.lua")
        if ClaimHive then
            Log("Checking Hive...", Color3.fromRGB(255, 255, 0))
            if ClaimHive.Run(Log, task.wait, Utilities) then
                Utilities.SaveData("HiveClaimed", true)
            end
        end
    end

    -- B. REDEEM CODE (Chạy nếu chưa redeem)
    if not SaveData.RedeemDone then
        local RedeemCode = LoadModule("RedeemCode.lua")
        if RedeemCode then
            RedeemCode.Run(Log, task.wait, Utilities)
        end
    end

    -- C. QUẢN LÝ TIẾN TRÌNH (COT MOC)
    -- Dựa vào số ong hoặc tiến trình đã lưu để quyết định chạy cái nào
    
    local beeCount = PlayerUtils.GetBeeCount()
    
    if beeCount < 5 and not SaveData.Cotmoc1Done then
        -- === CỘT MỐC 1: STARTER -> 4 BEES ===
        local Cotmoc1 = LoadModule("Cotmoc1.lua")
        if Cotmoc1 then
            Cotmoc1.Run(Tools) -- Truyền bộ Tools vào để nó tự xử lý
        end
    elseif beeCount >= 5 then
        -- === CỘT MỐC 2: 5 BEE ZONE (Ví dụ) ===
        -- Sau này bạn làm Cotmoc2.lua thì bỏ vào đây
        Log("✅ You have 5+ Bees! Ready for next zone.", Color3.fromRGB(0, 255, 0))
        -- Tạm thời cho đi farm Sunflower chơi
        -- Tools.Farm.StartFarm("Sunflower Field", Tools)
    end

    Log("💤 All scripts loaded.", Color3.fromRGB(200, 200, 200))
end)
