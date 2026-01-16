-- ====================================================
-- AUTO BEE SWARM - ZERO TOUCH (MANAGER V7 - AUTO KILL ADDED)
-- Created for: Luận
-- ====================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. CẤU HÌNH REPO
local REPO_URL = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/"

-- 2. HỆ THỐNG LOG & UI
local uiName = "BSSA_Manager_UI"
if CoreGui:FindFirstChild(uiName) then CoreGui[uiName]:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = uiName
if pcall(function() screenGui.Parent = CoreGui end) then else screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0.5, 0, 0, 60) 
mainFrame.Position = UDim2.new(0.25, 0, 0, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mainFrame.BackgroundTransparency = 0.6
mainFrame.BorderSizePixel = 0

local statusLabel = Instance.new("TextLabel", mainFrame)
statusLabel.Size = UDim2.new(1, 0, 0.5, 0)
statusLabel.Position = UDim2.new(0, 0, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
statusLabel.TextSize = 16
statusLabel.Font = Enum.Font.GothamBold
statusLabel.Text = "Status: Idle"

local logLabel = Instance.new("TextLabel", mainFrame)
logLabel.Size = UDim2.new(1, 0, 0.5, 0)
logLabel.Position = UDim2.new(0, 0, 0.5, 0)
logLabel.BackgroundTransparency = 1
logLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
logLabel.TextSize = 14
logLabel.Font = Enum.Font.Gotham
logLabel.Text = "Initializing..."

local function Log(text, color)
    if string.find(text, "Farming at") or string.find(text, "Status:") or string.find(text, "Fighting") or string.find(text, "Moving to") then
        statusLabel.Text = text:gsub("🚜 ", ""):gsub("📍 ", ""):gsub("🏠 ", "")
    else
        logLabel.Text = text
        if color then logLabel.TextColor3 = color end
    end
    print("[BSSA]: " .. text)
end

-- 3. HÀM TẢI MODULE
local function LoadModule(scriptName)
    Log("📥 Downloading: " .. scriptName .. "...", Color3.fromRGB(255, 255, 0))
    local url = REPO_URL .. scriptName .. "?t=" .. tostring(tick())
    local success, content = pcall(function() return game:HttpGet(url) end)
    
    if not success or type(content) ~= "string" then return nil end
    local func, loadErr = loadstring(content)
    if not func then return nil end
    local runSuccess, module = pcall(func)
    if not runSuccess then return nil end
    
    Log("✅ Loaded: " .. scriptName, Color3.fromRGB(0, 255, 0))
    return module
end

-- ====================================================
-- 4. BACKGROUND CHECK (MUA ĐỒ NGẦM)
-- ====================================================
local function StartBackgroundCheck(Tools)
    task.spawn(function()
        while true do
            task.wait(30)
            pcall(function()
                local data = Tools.Utils.LoadData()
                local pending = data.PendingItems or {}
                if #pending > 0 then
                    local newPending = {}
                    local bought = false
                    for _, itemData in ipairs(pending) do
                        local check = Tools.Shop.CheckAndBuy(itemData.Item, Tools.Player, nil)
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

    -- [UPDATE] Load thêm MonsterData
    local Utilities   = LoadModule("Utilities.lua")
    local PlayerUtils = LoadModule("PlayerUtils.lua")
    local ShopUtils   = LoadModule("ShopUtils.lua")
    local TokenData   = LoadModule("TokenData.lua")
    local FieldData   = LoadModule("FieldData.lua")
    local AutoFarm    = LoadModule("AutoFarm.lua")
    local PlaceEgg    = LoadModule("PlaceEgg.lua")
    local MonsterData = LoadModule("MonsterData.lua")

    if not (Utilities and PlayerUtils and ShopUtils and TokenData and FieldData and AutoFarm and PlaceEgg and MonsterData) then
        Log("❌ CRITICAL: Thiếu Module!", Color3.fromRGB(255, 0, 0))
        return
    end

    local Tools = { 
        Log = Log, Utils = Utilities, Player = PlayerUtils, Shop = ShopUtils, 
        Farm = AutoFarm, Field = FieldData, Token = TokenData, Hatch = PlaceEgg,
        Monster = MonsterData -- [NEW] Thêm vào Tools
    }
    
    local SaveData = Utilities.LoadData()
    Log("Welcome back, " .. LocalPlayer.Name, Color3.fromRGB(100, 255, 100))

    -- A. CHECK & CLAIM HIVE
    local ClaimHive = LoadModule("ClaimHive.lua")
    if ClaimHive then
        Log("🏠 Verifying Hive Ownership...", Color3.fromRGB(255, 255, 0))
        local hasHive = false
        while not hasHive do
            if ClaimHive.Run(Log, task.wait, Utilities) then
                hasHive = true
                Log("✅ Hive Confirmed!", Color3.fromRGB(0, 255, 0))
            else
                Log("⚠️ No Empty Hive! Retrying in 5s...", Color3.fromRGB(255, 100, 100))
                task.wait(5)
            end
        end
    end

    -- B. REDEEM & STARTER
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

    -- ============================================================
    -- C. VÒNG LẶP FARM CHÍNH + AUTO KILL
    -- ============================================================
    Log("🚜 Main Farm Loop Started", Color3.fromRGB(0, 255, 255))
    local targetMaterial = "Honey"
    local lastField = ""

    while true do
        -- 1. ƯU TIÊN SĂN QUÁI (KILL MONSTERS)
        local bees = Tools.Player.GetBeeCount()
        local activeMobs = Tools.Monster.GetActionableMobs(Tools.Field, bees)

        if #activeMobs > 0 then
            Tools.Log("⚔️ Monster Detected: " .. #activeMobs, Color3.fromRGB(255, 100, 100))
            Tools.Farm.StopFarm() -- Dừng Farm ngay
            task.wait(1)

            for _, mob in ipairs(activeMobs) do
                -- Gọi hàm giết quái tự động (Check -> Giết -> Loot -> Xong)
                local success = Tools.Monster.KillMob(mob, Tools, Log)
                if success then
                    Tools.Log("💀 Eliminated: " .. mob.Name, Color3.fromRGB(255, 50, 50))
                    task.wait(0.5)
                end
            end
            
            Tools.Log("✅ Kill Cycle Done. Resume Farming...", Color3.fromRGB(0, 255, 0))
            lastField = "" -- Reset để log lại dòng Farming at
        end

        -- 2. AUTO FARM (MẶC ĐỊNH)
        local bestField, fieldInfo = Tools.Field.GetBestFieldForMaterial(targetMaterial)
        if bestField and fieldInfo then
            if lastField ~= bestField then
                Tools.Log("📍 Farming at " .. bestField, Color3.fromRGB(255, 255, 0))
                lastField = bestField
            end
            Tools.Farm.StartFarm(bestField, Tools)
        else
            Tools.Log("⚠️ Finding best field...", Color3.fromRGB(255, 100, 100))
        end
        
        task.wait(3) -- Quét lại sau 3 giây
    end
end)
