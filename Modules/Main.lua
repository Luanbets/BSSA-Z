-- ====================================================
-- MAIN.LUA: GIAO DIỆN & ĐIỀU PHỐI
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
-- PHẦN UI (GIỮ NGUYÊN NHƯ CŨ CỦA BẠN)
-- ====================================================
if CoreGui:FindFirstChild("BSS_AutoClaim") then CoreGui.BSS_AutoClaim:Destroy() end
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BSS_AutoClaim"
pcall(function() screenGui.Parent = CoreGui end)
if not screenGui.Parent then screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- ... (Giữ nguyên toàn bộ phần tạo Frame, Title, Button của bạn ở đây) ...
-- (Mình tóm tắt lại đoạn tạo UI để tiết kiệm chỗ, bạn cứ paste y nguyên code UI cũ vào đây)
local mainFrame = Instance.new("Frame", screenGui); mainFrame.Size = UDim2.new(0, 350, 0, 160); mainFrame.Position = UDim2.new(0.5, -175, 0.5, -80); mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
local logLabel = Instance.new("TextLabel", mainFrame); logLabel.Size = UDim2.new(1, -20, 1, -80); logLabel.Position = UDim2.new(0, 10, 0, 40); logLabel.RichText = true; logLabel.Text = ""
local pauseBtn = Instance.new("TextButton", mainFrame); pauseBtn.Size = UDim2.new(1, -20, 0, 30); pauseBtn.Position = UDim2.new(0, 10, 1, -40); pauseBtn.Text = "[ PAUSE ]"

-- LOGIC NÚT BẤM
pauseBtn.MouseButton1Click:Connect(function() 
    isPaused = not isPaused
    pauseBtn.Text = isPaused and "[ RESUME ]" or "[ PAUSE ]"
end)

-- HÀM LOG (Để truyền cho các Module dùng)
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

local function WaitIfPaused() 
    while isPaused do task.wait(0.5) end 
end

-- ====================================================
-- ĐIỀU PHỐI MODULE (PHẦN THAY ĐỔI)
-- ====================================================
task.spawn(function()
    task.wait(1)
    Log("System: Initialized...", Color3.fromRGB(255, 255, 255))

    -- BƯỚC 1: GỌI MODULE CLAIM HIVE
    local claimModuleUrl = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/ClaimHive.lua"
    local successClaim, claimFunc = pcall(function() return game:HttpGet(claimModuleUrl) end)
    
    local claimedSuccess = false

    if successClaim then
        -- Chạy module ClaimHive, truyền hàm Log và Wait vào để module sử dụng
        local ClaimModule = loadstring(claimFunc)()
        claimedSuccess = ClaimModule.Run(Log, WaitIfPaused)
    else
        Log("Error: Cannot load ClaimHive module!", Color3.fromRGB(255, 0, 0))
    end

    -- BƯỚC 2: NẾU CLAIM THÀNH CÔNG THÌ GỌI MODULE REDEEM CODE
    if claimedSuccess then
        local redeemModuleUrl = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/RedeemCode.lua"
        local successRedeem, redeemFunc = pcall(function() return game:HttpGet(redeemModuleUrl) end)
        
        if successRedeem then
            local RedeemModule = loadstring(redeemFunc)()
            RedeemModule.Run(Log, WaitIfPaused)
        else
            Log("Error: Cannot load RedeemCode module!", Color3.fromRGB(255, 0, 0))
        end
    else
        -- Nếu không claim được hoặc lỗi
        if not successClaim then return end
        Log("System: Skipping code redeem (Hive not claimed)", Color3.fromRGB(255, 100, 100))
    end
end)
