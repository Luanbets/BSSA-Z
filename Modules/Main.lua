-- ====================================================
-- AUTO CLAIM HIVE V13.7 (TEST FARM ADDED)
-- Created for: Luận
-- ====================================================
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- BIẾN ĐIỀU KHIỂN
local isPaused = false

-- ====================================================
-- UI SETUP (GIỮ NGUYÊN)
-- ====================================================
local uiName = "AutoHiveV13_TestVer"
if CoreGui:FindFirstChild(uiName) then CoreGui[uiName]:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = uiName
pcall(function() screenGui.Parent = CoreGui end)
if not screenGui.Parent then screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 320, 0, 140)
mainFrame.Position = UDim2.new(0.5, -160, 0.4, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", mainFrame)
stroke.Color = Color3.fromRGB(0, 255, 255); stroke.Thickness = 1.5; stroke.Transparency = 0.5

-- Header & Controls
local topBar = Instance.new("Frame", mainFrame)
topBar.Size = UDim2.new(1, 0, 0, 30); topBar.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 12)
local titleLbl = Instance.new("TextLabel", topBar)
titleLbl.Size = UDim2.new(1, -40, 1, 0); titleLbl.Position = UDim2.new(0, 10, 0, 0); titleLbl.BackgroundTransparency = 1
titleLbl.Text = "BSSA-Z: TEST FARM MODE"; titleLbl.TextColor3 = Color3.fromRGB(255, 200, 0); titleLbl.Font = Enum.Font.GothamBold; titleLbl.TextSize = 14; titleLbl.TextXAlignment = Enum.TextXAlignment.Left

-- Log Area
local contentFrame = Instance.new("Frame", mainFrame)
contentFrame.Size = UDim2.new(1, -20, 1, -80); contentFrame.Position = UDim2.new(0, 10, 0, 35); contentFrame.BackgroundTransparency = 1
local lblAction = Instance.new("TextLabel", contentFrame)
lblAction.Size = UDim2.new(1, 0, 0.5, 0); lblAction.BackgroundTransparency = 1; lblAction.TextColor3 = Color3.fromRGB(255, 255, 255); lblAction.Font = Enum.Font.GothamBold; lblAction.TextSize = 15; lblAction.TextXAlignment = Enum.TextXAlignment.Left; lblAction.Text = "Starting..."
local lblStatus = Instance.new("TextLabel", contentFrame)
lblStatus.Size = UDim2.new(1, 0, 0.5, 0); lblStatus.Position = UDim2.new(0, 0, 0.5, 0); lblStatus.BackgroundTransparency = 1; lblStatus.TextColor3 = Color3.fromRGB(150, 150, 150); lblStatus.Font = Enum.Font.Gotham; lblStatus.TextSize = 13; lblStatus.TextXAlignment = Enum.TextXAlignment.Left; lblStatus.Text = "..."

-- Footer
local pauseBtn = Instance.new("TextButton", mainFrame)
pauseBtn.Size = UDim2.new(1, -20, 0, 30); pauseBtn.Position = UDim2.new(0, 10, 1, -40); pauseBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50); pauseBtn.Text = "RUNNING"; pauseBtn.TextColor3 = Color3.fromRGB(0, 255, 100); pauseBtn.Font = Enum.Font.GothamBold; pauseBtn.TextSize = 14
Instance.new("UICorner", pauseBtn).CornerRadius = UDim.new(0, 6)

local minBtn = Instance.new("TextButton", topBar); minBtn.Size = UDim2.new(0,30,0,30); minBtn.Position = UDim2.new(1,-30,0,0); minBtn.BackgroundTransparency=1; minBtn.Text="-"; minBtn.TextColor3=Color3.new(1,1,1); minBtn.TextSize=20; minBtn.Font=Enum.Font.GothamBold
local openBtn = Instance.new("TextButton", screenGui); openBtn.Size=UDim2.new(0,50,0,50); openBtn.Position=UDim2.new(0,20,0.5,-25); openBtn.BackgroundColor3=Color3.fromRGB(25,25,30); openBtn.Text="BSSA"; openBtn.TextColor3=Color3.fromRGB(0,255,255); openBtn.Font=Enum.Font.GothamBold; openBtn.Visible=false
Instance.new("UICorner", openBtn).CornerRadius=UDim.new(0,12); Instance.new("UIStroke", openBtn).Color=Color3.fromRGB(0,255,255)

minBtn.MouseButton1Click:Connect(function() mainFrame.Visible=false; openBtn.Visible=true end)
openBtn.MouseButton1Click:Connect(function() mainFrame.Visible=true; openBtn.Visible=false end)
pauseBtn.MouseButton1Click:Connect(function() isPaused = not isPaused; pauseBtn.Text = isPaused and "PAUSED" or "RUNNING"; pauseBtn.TextColor3 = isPaused and Color3.fromRGB(255,80,80) or Color3.fromRGB(0,255,100) end)

-- HÀM LOG (ĐÃ TẮT PRINT F9 THEO YÊU CẦU)
local function Log(text, color)
    lblAction.Text = "> " .. text
    lblAction.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    -- print("[AutoHive] " .. text) -- Đã tắt
end

local function WaitIfPaused() while isPaused do task.wait(0.5) end end

-- ====================================================
-- LOGIC TẢI THÔNG MINH
-- ====================================================
local function LoadModule(url)
    local noCacheUrl = url .. "?t=" .. tostring(tick())
    local success, content = pcall(function() return game:HttpGet(noCacheUrl) end)
    if success then
        local func = loadstring(content)
        if func then return func() end
    end
    return nil
end

-- ====================================================
-- MAIN LOGIC
-- ====================================================
task.spawn(function()
    task.wait(1)
    Log("Initializing...", Color3.fromRGB(255, 255, 255))

    -- 1. Load Utilities
    local Utils = LoadModule("https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/Utilities.lua")
    if not Utils then Log("FAIL: Utilities.lua", Color3.fromRGB(255, 0, 0)); return end
    
    local SaveData = Utils.LoadData()
    Log("User: " .. LocalPlayer.Name, Color3.fromRGB(200, 200, 200))

    -- 2. Claim Hive
    local ClaimModule = LoadModule("https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/ClaimHive.lua")
    if ClaimModule then
        local claimed = ClaimModule.Run(Log, WaitIfPaused, Utils)
        if not claimed then Log("Stop: No Hive!", Color3.fromRGB(255, 80, 80)); return end
    end

    -- 3. Redeem Codes
    if not SaveData.RedeemDone then
        local RedeemModule = LoadModule("https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/RedeemCode.lua")
        if RedeemModule then RedeemModule.Run(Log, WaitIfPaused, Utils) end
    end

    -- 4. Cotmoc1
    if not SaveData.Cotmoc1Done then
        local CM1Module = LoadModule("https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/Cotmoc1.lua")
        if CM1Module then
            CM1Module.Run(Log, WaitIfPaused, Utils)
        end
    end
    
    -- =================================================================
    -- CHỨC NĂNG TEST FARM (MỚI THÊM)
    -- =================================================================
    local TEST_FIELD = "Sunflower Field" -- << Đổi tên cánh đồng bạn muốn test ở đây
    
    Log("Loading AutoFarm Module...", Color3.fromRGB(255, 255, 0))
    local AutoFarm = LoadModule("https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/AutoFarm.lua")
    
    if AutoFarm then
        task.wait(1)
        Log("🧪 TESTING: " .. TEST_FIELD, Color3.fromRGB(0, 255, 255))
        
        -- Gọi hàm Farm (Lưu ý: Hàm này sẽ chạy vòng lặp mãi mãi)
        AutoFarm.StartFarm(TEST_FIELD, Log, Utils)
    else
        Log("❌ Lỗi: Không tải được AutoFarm!", Color3.fromRGB(255, 0, 0))
    end
end)
