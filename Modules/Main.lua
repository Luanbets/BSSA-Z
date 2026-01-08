-- ====================================================
-- AUTO CLAIM HIVE V12 (MODULAR VERSION)
-- ====================================================
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

-- BIẾN ĐIỀU KHIỂN
local isPaused = false
local logHistory = {} 

-- ====================================================
-- PHẦN 1: GIAO DIỆN (UI) - GIỮ NGUYÊN CỦA BẠN
-- ====================================================
if CoreGui:FindFirstChild("AutoHiveV12") then CoreGui.AutoHiveV12:Destroy() end
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoHiveV12"
pcall(function() screenGui.Parent = CoreGui end)
if not screenGui.Parent then screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local mainFrame = Instance.new("Frame", screenGui); mainFrame.Size = UDim2.new(0, 350, 0, 160); mainFrame.Position = UDim2.new(0.5, -175, 0.5, -80); mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

local titleBar = Instance.new("TextLabel", mainFrame); titleBar.Size = UDim2.new(1, 0, 0, 30); titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35); titleBar.Text = "  BEE SWARM SIMULATOR SCRIPT"; titleBar.TextColor3 = Color3.fromRGB(0, 255, 255); titleBar.Font = Enum.Font.Code; titleBar.TextSize = 14; titleBar.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)
local filler = Instance.new("Frame", titleBar); filler.Size = UDim2.new(1, 0, 0, 10); filler.Position = UDim2.new(0, 0, 1, -10); filler.BackgroundColor3 = Color3.fromRGB(35, 35, 35); filler.BorderSizePixel = 0

local minBtn = Instance.new("TextButton", titleBar); minBtn.Size = UDim2.new(0, 30, 0, 30); minBtn.Position = UDim2.new(1, -30, 0, 0); minBtn.BackgroundTransparency = 1; minBtn.Text = "-"; minBtn.TextColor3 = Color3.fromRGB(255, 255, 255); minBtn.TextSize = 20; minBtn.Font = Enum.Font.Code

local logLabel = Instance.new("TextLabel", mainFrame); logLabel.Size = UDim2.new(1, -20, 1, -80); logLabel.Position = UDim2.new(0, 10, 0, 40); logLabel.BackgroundTransparency = 1; logLabel.TextColor3 = Color3.fromRGB(255, 255, 255); logLabel.RichText = true; logLabel.Font = Enum.Font.Code; logLabel.TextSize = 13; logLabel.TextWrapped = true; logLabel.TextXAlignment = Enum.TextXAlignment.Left; logLabel.TextYAlignment = Enum.TextYAlignment.Top; logLabel.Text = ""

local pauseBtn = Instance.new("TextButton", mainFrame); pauseBtn.Size = UDim2.new(1, -20, 0, 30); pauseBtn.Position = UDim2.new(0, 10, 1, -40); pauseBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60); pauseBtn.Text = "[ PAUSE ]"; pauseBtn.TextColor3 = Color3.fromRGB(255, 80, 80); pauseBtn.Font = Enum.Font.Code; pauseBtn.TextSize = 14; Instance.new("UICorner", pauseBtn).CornerRadius = UDim.new(0, 6)

local openBtn = Instance.new("TextButton", screenGui); openBtn.Size = UDim2.new(0, 50, 0, 50); openBtn.Position = UDim2.new(0, 20, 0.5, -25); openBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 255); openBtn.Text = "OPEN"; openBtn.Visible = false; Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 10)

-- CHỨC NĂNG UI
local dragging, dragInput, dragStart, startPos
titleBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; dragStart = input.Position; startPos = mainFrame.Position; input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end) end end)
titleBar.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then local delta = input.Position - dragStart; mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)

minBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false; openBtn.Visible = true end)
openBtn.MouseButton1Click:Connect(function() mainFrame.Visible = true; openBtn.Visible = false end)
pauseBtn.MouseButton1Click:Connect(function() isPaused = not isPaused; pauseBtn.Text = isPaused and "[ RESUME ]" or "[ PAUSE ]"; pauseBtn.TextColor3 = isPaused and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 80, 80) end)

-- ====================================================
-- HÀM LOG & HỖ TRỢ (GIỮ NGUYÊN ĐỂ TRUYỀN VÀO MODULE)
-- ====================================================
local function Log(text, color)
    local currentTime = os.date("%H:%M:%S")
    local baseText = string.format("[%s] %s", currentTime, text)
    local finalLine = baseText
    if color then
        local r, g, b = math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255)
        finalLine = string.format('<font color="rgb(%d,%d,%d)">%s</font>', r, g, b, baseText)
    else
        finalLine = string.format('<font color="rgb(200,200,200)">%s</font>', baseText)
    end
    print(baseText)
    table.insert(logHistory, finalLine)
    if #logHistory > 6 then table.remove(logHistory, 1) end
    logLabel.Text = table.concat(logHistory, "\n")
end

local function WaitIfPaused() while isPaused do task.wait(0.5) end end

-- ====================================================
-- ĐIỀU PHỐI MODULE (PHẦN QUAN TRỌNG NHẤT)
-- ====================================================
task.spawn(function()
    task.wait(1)
    Log("System: Initializing Modules...", Color3.fromRGB(255, 255, 255))

    -- 1. GỌI MODULE CLAIM HIVE
    local claimUrl = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/ClaimHive.lua"
    local success, claimFunc = pcall(function() return game:HttpGet(claimUrl) end)
    
    local isClaimed = false

    if success then
        -- Load và chạy Module, truyền hàm Log + Wait vào
        local ClaimModule = loadstring(claimFunc)()
        isClaimed = ClaimModule.Run(Log, WaitIfPaused)
    else
        Log("Error: Failed to load ClaimHive.lua", Color3.fromRGB(255, 0, 0))
    end

    -- 2. GỌI MODULE REDEEM CODE (NẾU CLAIM THÀNH CÔNG)
    if isClaimed then
        local redeemUrl = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/RedeemCode.lua"
        local success2, redeemFunc = pcall(function() return game:HttpGet(redeemUrl) end)
        
        if success2 then
            local RedeemModule = loadstring(redeemFunc)()
            RedeemModule.Run(Log, WaitIfPaused)
        else
            Log("Error: Failed to load RedeemCode.lua", Color3.fromRGB(255, 0, 0))
        end
    else
        if success then -- Nếu load được module nhưng trả về false (không tìm thấy tổ)
             -- Log đã được in bên trong module rồi, không cần in thêm
        end
    end
end)
