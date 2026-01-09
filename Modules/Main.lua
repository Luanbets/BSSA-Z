-- ====================================================
-- AUTO CLAIM HIVE V13 (MODERN UI & SMART LOG)
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
-- PHẦN UI MỚI (MODERN DESIGN)
-- ====================================================
local uiName = "AutoHiveV13_Modern"
if CoreGui:FindFirstChild(uiName) then CoreGui[uiName]:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = uiName
pcall(function() screenGui.Parent = CoreGui end)
if not screenGui.Parent then screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- 1. Main Container
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 320, 0, 130)
mainFrame.Position = UDim2.new(0.5, -160, 0.4, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
mainFrame.BorderSizePixel = 0
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

-- Stroke (Viền Neon)
local stroke = Instance.new("UIStroke", mainFrame)
stroke.Color = Color3.fromRGB(0, 255, 255)
stroke.Thickness = 1.5
stroke.Transparency = 0.5

-- 2. Header
local topBar = Instance.new("Frame", mainFrame)
topBar.Size = UDim2.new(1, 0, 0, 30)
topBar.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 12)

local titleLbl = Instance.new("TextLabel", topBar)
titleLbl.Size = UDim2.new(1, -40, 1, 0)
titleLbl.Position = UDim2.new(0, 10, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "BSSA-Z AUTOMATION"
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextColor3 = Color3.fromRGB(0, 255, 255)
titleLbl.TextSize = 14
titleLbl.TextXAlignment = Enum.TextXAlignment.Left

-- Nút ẩn/hiện
local minBtn = Instance.new("TextButton", topBar)
minBtn.Size = UDim2.new(0, 30, 0, 30)
minBtn.Position = UDim2.new(1, -30, 0, 0)
minBtn.BackgroundTransparency = 1
minBtn.Text = "-"
minBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
minBtn.TextSize = 20
minBtn.Font = Enum.Font.GothamBold

-- Che phần góc dưới của Header để nó liền với Body
local hideCorner = Instance.new("Frame", topBar)
hideCorner.Size = UDim2.new(1, 0, 0, 10)
hideCorner.Position = UDim2.new(0, 0, 1, -10)
hideCorner.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
hideCorner.BorderSizePixel = 0
hideCorner.ZIndex = 0

-- 3. Body (Phần hiển thị Log)
local contentFrame = Instance.new("Frame", mainFrame)
contentFrame.Size = UDim2.new(1, -20, 1, -80)
contentFrame.Position = UDim2.new(0, 10, 0, 35)
contentFrame.BackgroundTransparency = 1

-- Dòng 1: ĐANG LÀM GÌ (Action)
local lblAction = Instance.new("TextLabel", contentFrame)
lblAction.Size = UDim2.new(1, 0, 0.5, 0)
lblAction.BackgroundTransparency = 1
lblAction.Text = "Đang khởi động..."
lblAction.TextColor3 = Color3.fromRGB(255, 255, 255)
lblAction.Font = Enum.Font.GothamBold
lblAction.TextSize = 16
lblAction.TextXAlignment = Enum.TextXAlignment.Left

-- Dòng 2: KẾT QUẢ (Status)
local lblStatus = Instance.new("TextLabel", contentFrame)
lblStatus.Size = UDim2.new(1, 0, 0.5, 0)
lblStatus.Position = UDim2.new(0, 0, 0.5, 0)
lblStatus.BackgroundTransparency = 1
lblStatus.Text = "Waiting..."
lblStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
lblStatus.Font = Enum.Font.Gotham
lblStatus.TextSize = 14
lblStatus.TextXAlignment = Enum.TextXAlignment.Left

-- 4. Footer (Nút Pause)
local pauseBtn = Instance.new("TextButton", mainFrame)
pauseBtn.Size = UDim2.new(1, -20, 0, 32)
pauseBtn.Position = UDim2.new(0, 10, 1, -42)
pauseBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
pauseBtn.Text = "RUNNING"
pauseBtn.TextColor3 = Color3.fromRGB(0, 255, 100)
pauseBtn.Font = Enum.Font.GothamBold
pauseBtn.TextSize = 14
Instance.new("UICorner", pauseBtn).CornerRadius = UDim.new(0, 6)

-- Nút mở lại khi ẩn
local openBtn = Instance.new("TextButton", screenGui)
openBtn.Size = UDim2.new(0, 50, 0, 50)
openBtn.Position = UDim2.new(0, 20, 0.5, -25)
openBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
openBtn.Text = "BSSA"
openBtn.TextColor3 = Color3.fromRGB(0, 255, 255)
openBtn.Font = Enum.Font.GothamBold
openBtn.Visible = false
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", openBtn).Color = Color3.fromRGB(0, 255, 255)

-- ====================================================
-- LOGIC GIAO DIỆN & LOG THÔNG MINH
-- ====================================================

-- Chức năng kéo thả (Draggable)
local dragging, dragInput, dragStart, startPos
topBar.InputBegan:Connect(function(input) 
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
        dragging = true; dragStart = input.Position; startPos = mainFrame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end) 
    end 
end)
topBar.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
UserInputService.InputChanged:Connect(function(input) 
    if input == dragInput and dragging then 
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) 
    end 
end)

-- Ẩn / Hiện
minBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false; openBtn.Visible = true end)
openBtn.MouseButton1Click:Connect(function() mainFrame.Visible = true; openBtn.Visible = false end)

-- Pause / Resume
pauseBtn.MouseButton1Click:Connect(function() 
    isPaused = not isPaused
    if isPaused then
        pauseBtn.Text = "PAUSED"
        pauseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    else
        pauseBtn.Text = "RUNNING"
        pauseBtn.TextColor3 = Color3.fromRGB(0, 255, 100)
    end
end)

-- HÀM LOG MỚI (Trọng tâm thay đổi)
local function Log(text, color)
    local r, g, b = 255, 255, 255
    if color then r, g, b = math.floor(color.R*255), math.floor(color.G*255), math.floor(color.B*255) end
    
    -- Logic phân loại:
    -- Màu Vàng (255, 220, 0) hoặc Trắng: Thường là hành động chuẩn bị làm (Moving, Checking...) -> Hiển thị dòng trên
    -- Màu Xanh lá, Đỏ, hoặc khác: Thường là kết quả (Bought, Claimed, Error) -> Hiển thị dòng dưới
    
    local isAction = (r == 255 and g == 220 and b == 0) or (r == 255 and g == 255 and b == 255) or (text:find("Moving")) or (text:find("Check"))
    
    if isAction then
        lblAction.Text = "⚡ " .. text
        lblAction.TextColor3 = color or Color3.fromRGB(255, 255, 255)
        -- Reset dòng status để người dùng biết đang chờ kết quả mới
        lblStatus.Text = "..." 
        lblStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
    else
        lblStatus.Text = text
        lblStatus.TextColor3 = color or Color3.fromRGB(200, 200, 200)
        
        -- Hiệu ứng nháy nhẹ dòng kết quả
        local tInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)
        TweenService:Create(lblStatus, tInfo, {TextTransparency = 0.5}):Play()
    end
    
    print("[AutoHive] " .. text) -- Vẫn in ra F9 để debug nếu cần
end

local function WaitIfPaused() while isPaused do task.wait(0.5) end end

-- ====================================================
-- ĐIỀU PHỐI MODULE (LOGIC GIỮ NGUYÊN)
-- ====================================================
task.spawn(function()
    task.wait(1)
    Log("System: Initializing...", Color3.fromRGB(255, 255, 255))

    -- 1. TẢI MODULE UTILITIES
    local utilsUrl = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/Utilities.lua"
    local successUtils, utilsFunc = pcall(function() return game:HttpGet(utilsUrl) end)
    local Utils = nil
    local SaveData = {} 

    if successUtils then
        Utils = loadstring(utilsFunc)()
        SaveData = Utils.LoadData()
        Log("Data loaded for " .. LocalPlayer.Name, Color3.fromRGB(255, 255, 255))
    else
        Log("Error: Failed to load Utilities.lua", Color3.fromRGB(255, 0, 0))
        return 
    end

    -- 2. GỌI CLAIM HIVE
    local claimUrl = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/ClaimHive.lua"
    local success, claimFunc = pcall(function() return game:HttpGet(claimUrl) end)
    local isClaimed = false

    if success then
        local ClaimModule = loadstring(claimFunc)()
        -- Module này sẽ gọi LogFunc, UI của chúng ta sẽ tự xử lý hiển thị
        isClaimed = ClaimModule.Run(Log, WaitIfPaused, Utils)
    end

    if not isClaimed then 
        Log("Please claim a hive manually!", Color3.fromRGB(255, 80, 80))
        return 
    end

    -- 3. CHẠY NHIỆM VỤ (Redeem -> Cotmoc1)
    
    -- A. REDEEM CODE
    if not SaveData.RedeemDone then
        local redeemUrl = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/RedeemCode.lua"
        local success2, redeemFunc = pcall(function() return game:HttpGet(redeemUrl) end)
        if success2 then
            local RedeemModule = loadstring(redeemFunc)()
            RedeemModule.Run(Log, WaitIfPaused, Utils)
        end
    else
        -- Dùng màu xám để đẩy xuống dòng Status (Kết quả: Đã làm rồi)
        Log("Redeem Codes: Already Done", Color3.fromRGB(100, 100, 100))
    end

    -- B. COTMOC1 (MUA TRỨNG & DỤNG CỤ)
    if not SaveData.Cotmoc1Done then
        task.wait(1)
        local cotmoc1Url = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/Cotmoc1.lua"
        local success3, cm1Func = pcall(function() return game:HttpGet(cotmoc1Url) end)
        if success3 then
            local CM1Module = loadstring(cm1Func)()
            CM1Module.Run(Log, WaitIfPaused, Utils)
        end
    else
        Log("Cotmoc1: Already Done", Color3.fromRGB(100, 100, 100))
    end
    
    Log("All tasks completed!", Color3.fromRGB(0, 255, 100))
    lblAction.Text = "System Idle"
end)
