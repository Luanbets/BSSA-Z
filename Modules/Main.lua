local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

-- 1. CẤU HÌNH REPO
local REPO_URL = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/"

-- 2. HỆ THỐNG LOG
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
    print("[BSSA]: " .. text)
end

-- 3. HÀM TẢI MODULE AN TOÀN
local function LoadModule(scriptName)
    local url = REPO_URL .. scriptName .. "?t=" .. tostring(tick())
    local success, content = pcall(function() return game:HttpGet(url) end)
    if not success then
        Log("❌ HTTP Fail: " .. scriptName, Color3.fromRGB(255, 80, 80))
        return nil
    end

    local func, loadErr = loadstring(content)
    if not func then
        Log("❌ Syntax Error: " .. scriptName, Color3.fromRGB(255, 80, 80))
        warn("[BSSA Syntax]: " .. tostring(loadErr))
        return nil
    end

    local runSuccess, module = pcall(func)
    if not runSuccess then
        Log("❌ Runtime Error: " .. scriptName, Color3.fromRGB(255, 80, 80))
        warn("[BSSA Runtime]: " .. tostring(module))
        return nil
    end
    return module
end

-- ====================================================
-- 4. LOGIC CHÍNH (TUẦN TỰ)
-- ====================================================
task.spawn(function()
    task.wait(1)
    Log("Loading Core Modules...", Color3.fromRGB(255, 255, 0))

    local Utilities   = LoadModule("Utilities.lua")
    local PlayerUtils = LoadModule("PlayerUtils.lua")
    local ShopUtils   = LoadModule("ShopUtils.lua")
    local TokenData   = LoadModule("TokenData.lua")
    local FieldData   = LoadModule("FieldData.lua")
    local AutoFarm    = LoadModule("AutoFarm.lua")

    if not (Utilities and PlayerUtils and ShopUtils and TokenData and FieldData and AutoFarm) then
        Log("❌ STOP: Failed to load core modules!", Color3.fromRGB(255, 0, 0))
        return
    end

    -- Đóng gói công cụ
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

    -- A. NHỮNG VIỆC CƠ BẢN (CHẠY 1 LẦN)
    if not SaveData.HiveClaimed then
        local ClaimHive = LoadModule("ClaimHive.lua")
        if ClaimHive and ClaimHive.Run(Log, task.wait, Utilities) then
            Utilities.SaveData("HiveClaimed", true)
        end
    end

    if not SaveData.RedeemDone then
        local RedeemCode = LoadModule("RedeemCode.lua")
        if RedeemCode then RedeemCode.Run(Log, task.wait, Utilities) end
    end

    -- B. QUẢN LÝ TIẾN TRÌNH (TUẦN TỰ)
    -- Logic: Xong cái này mới làm cái kia.
    
    -- 1. STARTER (Mới chơi)
    if not SaveData.StarterDone then
        local Starter = LoadModule("Starter.lua") -- Tải file Starter.lua
        if Starter then
            Starter.Run(Tools) -- Giao quyền cho Starter
        end
        return -- Dừng Main lại, để Starter chạy
    end

    -- 2. 5 BEE ZONE (Sau khi xong Starter)
    -- if not SaveData.Zone5Done then ... end

    -- 3. NẾU ĐÃ XONG HẾT
    Log("✅ Starter Complete! Waiting for Zone 5 Script...", Color3.fromRGB(0, 255, 0))
    -- Trong lúc chờ đợi script mới, cứ đi farm Sunflower
    Tools.Farm.StartFarm("Sunflower Field", Tools.Log, Tools.Utils)
end)
