-- ====================================================
-- AUTO BEE SWARM - ZERO TOUCH (MANAGER V4 - FINAL)
-- Created for: Luận
-- ====================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
    if logLabel then
        logLabel.Text = text
        logLabel.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    end
    print("[BSSA]: " .. text)
end

-- 3. HÀM TẢI MODULE (DEBUG CHI TIẾT)
local function LoadModule(scriptName)
    Log("📥 Downloading: " .. scriptName .. "...", Color3.fromRGB(255, 255, 0))
    
    local url = REPO_URL .. scriptName .. "?t=" .. tostring(tick())
    local success, content = pcall(function() return game:HttpGet(url) end)
    
    if not success or type(content) ~= "string" then
        Log("❌ LỖI TẢI (HTTP Fail): " .. scriptName, Color3.fromRGB(255, 80, 80))
        warn("[BSSA DEBUG] URL: " .. url)
        return nil
    end

    local func, loadErr = loadstring(content)
    if not func then
        Log("❌ LỖI CÚ PHÁP (Syntax): " .. scriptName, Color3.fromRGB(255, 80, 80))
        warn("[BSSA DEBUG] Error: " .. tostring(loadErr))
        return nil
    end

    local runSuccess, module = pcall(func)
    if not runSuccess then
        Log("❌ LỖI CHẠY (Runtime): " .. scriptName, Color3.fromRGB(255, 80, 80))
        warn("[BSSA DEBUG] Error: " .. tostring(module))
        return nil
    end
    
    Log("✅ Loaded: " .. scriptName, Color3.fromRGB(0, 255, 0))
    return module
end

-- ====================================================
-- 4. BACKGROUND CHECK
-- ====================================================
local function StartBackgroundCheck(Tools)
    task.spawn(function()
        Log("🕵️ Background Check Active", Color3.fromRGB(150, 150, 150))
        while true do
            task.wait(30)
            pcall(function()
                local data = Tools.Utils.LoadData()
                local pending = data.PendingItems or {}
                if #pending > 0 then
                    local newPending = {}
                    local bought = false
                    for _, itemData in ipairs(pending) do
                        local check = Tools.Shop.CheckAndBuy(itemData.Item, Tools.Player, nil) -- Gọi CheckAndBuy mới
                        if check.Purchased then
                            Tools.Log("⚡ Background Buy: " .. itemData.Item, Color3.fromRGB(0, 255, 0))
                            bought = true
                        else
                            table.insert(newPending, itemData)
                        end
                    end
                    if bought or #newPending ~= #pending then
                        Tools.Utils.SaveData("PendingItems", newPending)
                    end
                end
            end)
        end
    end)
end

-- ====================================================
-- 5. MAIN THREAD
-- ====================================================
task.spawn(function()
    task.wait(1)
    Log("🚀 Starting Main Thread...", Color3.fromRGB(0, 255, 255))

    local Utilities   = LoadModule("Utilities.lua")
    local PlayerUtils = LoadModule("PlayerUtils.lua")
    local ShopUtils   = LoadModule("ShopUtils.lua")
    local TokenData   = LoadModule("TokenData.lua")
    local FieldData   = LoadModule("FieldData.lua")
    local AutoFarm    = LoadModule("AutoFarm.lua")
    local PlaceEgg    = LoadModule("PlaceEgg.lua")

    if not (Utilities and PlayerUtils and ShopUtils and TokenData and FieldData and AutoFarm and PlaceEgg) then
        Log("❌ CRITICAL: Thiếu Module quan trọng! Kiểm tra Console (F9).", Color3.fromRGB(255, 0, 0))
        return
    end

    local Tools = {
        Log = Log,
        Utils = Utilities,
        Player = PlayerUtils,
        Shop = ShopUtils,
        Farm = AutoFarm,
        Field = FieldData,
        Token = TokenData,
        Hatch = PlaceEgg
    }

    local SaveData = Utilities.LoadData()
    Log("Welcome back, " .. LocalPlayer.Name, Color3.fromRGB(100, 255, 100))

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

    if not SaveData.StarterDone then
        local Starter = LoadModule("Starter.lua")
        if Starter then Starter.Run(Tools) end
    else
        Log("✅ Starter Completed.", Color3.fromRGB(0, 255, 0))
    end

    StartBackgroundCheck(Tools)

    Log("🚜 Main Farm Loop Started", Color3.fromRGB(0, 255, 255))
    local targetMaterial = "Honey"
    local lastField = ""

    while true do
        local bestField, fieldInfo = Tools.Field.GetBestFieldForMaterial(targetMaterial)
        if bestField and fieldInfo then
            if lastField ~= bestField then
                Tools.Log("📍 Farming at: " .. bestField, Color3.fromRGB(255, 255, 0))
                lastField = bestField
            end
            Tools.Farm.StartFarm(bestField, Tools)
        else
            Tools.Log("⚠️ Finding best field...", Color3.fromRGB(255, 100, 100))
        end
        task.wait(5)
    end
end)
