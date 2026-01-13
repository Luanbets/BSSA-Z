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

-- 2. HỆ THỐNG LOG (UI ĐƠN GIẢN)
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

-- 3. HÀM TẢI MODULE (ĐƯỢC ĐỊNH NGHĨA TRƯỚC KHI DÙNG)
local function LoadModule(scriptName)
    Log("📥 Downloading: " .. scriptName .. "...", Color3.fromRGB(255, 255, 0))
    
    local url = REPO_URL .. scriptName .. "?t=" .. tostring(tick())
    local success, content = pcall(function() return game:HttpGet(url) end)
    
    if not success then
        Log("❌ HTTP Fail: " .. scriptName, Color3.fromRGB(255, 80, 80))
        return nil
    end

    local func, loadErr = loadstring(content)
    if not func then
        Log("❌ Syntax Error in " .. scriptName, Color3.fromRGB(255, 80, 80))
        warn("[BSSA Syntax]: " .. tostring(loadErr))
        return nil
    end

    local runSuccess, module = pcall(func)
    if not runSuccess then
        Log("❌ Runtime Error in " .. scriptName, Color3.fromRGB(255, 80, 80))
        warn("[BSSA Runtime]: " .. tostring(module))
        return nil
    end
    
    Log("✅ Loaded: " .. scriptName, Color3.fromRGB(0, 255, 0))
    return module
end

-- ====================================================
-- 4. TÍNH NĂNG ĐA NHIỆM (CHECK BACKGROUND)
-- ====================================================
local function StartBackgroundCheck(Tools)
    task.spawn(function()
        Log("🕵️ Background Check Started (Every 30s)", Color3.fromRGB(150, 150, 150))
        
        while true do
            task.wait(30)
            -- Bọc trong pcall để tránh lỗi ngầm làm crash luồng
            pcall(function()
                local data = Tools.Utils.LoadData()
                local pending = data.PendingItems or {}
                
                if #pending > 0 then
                    local newPending = {}
                    local boughtSomething = false
                    
                    for _, itemData in ipairs(pending) do
                        local check = Tools.Shop.CheckRequirements(itemData.Item, Tools.Player)
                        
                        if check.CanBuy then
                            Tools.Log("⚡ Background Buy: " .. itemData.Item, Color3.fromRGB(0, 255, 0))
                            Tools.Farm.StopFarm()
                            task.wait(0.5)
                            
                            -- Mua bằng module ShopUtils mới (CheckAndBuy hoặc Buy)
                            -- Ở đây dùng invoke trực tiếp như logic cũ của bạn
                            ReplicatedStorage.Events.ItemPackageEvent:InvokeServer("Purchase", {
                                ["Type"] = itemData.Item, 
                                ["Category"] = itemData.Category
                            })
                            
                            task.wait(1)
                            boughtSomething = true
                        else
                            table.insert(newPending, itemData)
                        end
                    end
                    
                    if boughtSomething or #newPending ~= #pending then
                        Tools.Utils.SaveData("PendingItems", newPending)
                        if #newPending == 0 then
                            Tools.Log("🎉 All Skipped Items Cleared!", Color3.fromRGB(0, 255, 0))
                        end
                    end
                end
            end)
        end
    end)
end

-- ====================================================
-- 5. LOGIC CHÍNH (MAIN THREAD)
-- ====================================================
task.spawn(function()
    task.wait(1)
    Log("🚀 Starting Main Thread...", Color3.fromRGB(0, 255, 255))

    -- Tải Modules (Bao gồm cả PlaceEgg ở đây để đảm bảo LoadModule đã tồn tại)
    local Utilities   = LoadModule("Utilities.lua")
    local PlayerUtils = LoadModule("PlayerUtils.lua")
    local ShopUtils   = LoadModule("ShopUtils.lua")
    local TokenData   = LoadModule("TokenData.lua")
    local FieldData   = LoadModule("FieldData.lua")
    local AutoFarm    = LoadModule("AutoFarm.lua")
    local PlaceEgg    = LoadModule("PlaceEgg.lua") -- Đã di chuyển xuống đây

    -- Kiểm tra module chết
    if not (Utilities and PlayerUtils and ShopUtils and TokenData and FieldData and AutoFarm and PlaceEgg) then
        Log("❌ CRITICAL: One or more modules failed to load!", Color3.fromRGB(255, 0, 0))
        return
    end

    -- Đóng gói Tools
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

    -- A. Claim Hive
    if not SaveData.HiveClaimed then
        local ClaimHive = LoadModule("ClaimHive.lua")
        if ClaimHive and ClaimHive.Run(Log, task.wait, Utilities) then
            Utilities.SaveData("HiveClaimed", true)
        end
    end

    -- B. Redeem Code
    if not SaveData.RedeemDone then
        local RedeemCode = LoadModule("RedeemCode.lua")
        if RedeemCode then RedeemCode.Run(Log, task.wait, Utilities) end
    end

    -- C. Chạy Starter Quest
    if not SaveData.StarterDone then
        local Starter = LoadModule("Starter.lua")
        if Starter then
            Starter.Run(Tools)
        end
    else
        Log("✅ Starter Previously Completed.", Color3.fromRGB(0, 255, 0))
    end

    -- D. Chạy Check Ngầm
    StartBackgroundCheck(Tools)

    -- E. Farm Loop
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
