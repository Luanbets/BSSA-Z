-- ====================================================
-- BSSA-Z: MASTER CONTROLLER (FIXED FLOW)
-- ====================================================
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

-- SETUP UI STATUS
local uiName = "BSSA_Status"
if CoreGui:FindFirstChild(uiName) then CoreGui[uiName]:Destroy() end
local screen = Instance.new("ScreenGui", CoreGui); screen.Name = uiName
local lbl = Instance.new("TextLabel", screen)
lbl.Size = UDim2.new(0, 300, 0, 30); lbl.Position = UDim2.new(0.5, -150, 0.05, 0)
lbl.BackgroundColor3 = Color3.fromRGB(0,0,0); lbl.TextColor3 = Color3.fromRGB(0,255,0)
lbl.BackgroundTransparency = 0.5; lbl.Text = "Loading..."

local function Log(text) lbl.Text = "STATUS: " .. text end

-- LOAD WORKER
local function LoadWorker(name)
    local url = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/" .. name .. ".lua?t="..tick()
    local success, content = pcall(function() return game:HttpGet(url) end)
    if success then
        local func = loadstring(content)
        if func then return func() end
    end
    return nil
end

Log("Loading Toolkit...")
local Toolkit = {
    Utils       = LoadWorker("Utilities"),
    FieldData   = LoadWorker("FieldData"),
    TokenData   = LoadWorker("TokenData"),
    ShopUtils   = LoadWorker("ShopUtils"),
    PlayerUtils = LoadWorker("PlayerUtils"),
    AutoFarm    = LoadWorker("AutoFarm"),
    ClaimHive   = LoadWorker("ClaimHive"),
    RedeemCode  = LoadWorker("RedeemCode"),
}

if not Toolkit.AutoFarm or not Toolkit.ClaimHive then return end

-- ====================================================
-- BƯỚC 1: XỬ LÝ CLAIM HIVE (CHẶN CỔNG)
-- Chạy 1 lần duy nhất ở đây. Chưa có tổ thì không cho đi tiếp.
-- ====================================================
Log("Checking Hive...")
local hasHive = Toolkit.ClaimHive.Run(Log, task.wait, Toolkit.Utils)

if not hasHive then
    Log("❌ Failed to claim hive. Script Stopped.")
    return -- Dừng script luôn nếu không nhận được tổ
end

Log("✅ Hive Owned! Starting Brain Loop...")

-- ====================================================
-- BƯỚC 2: VÒNG LẶP CHÍNH (BRAIN LOOP)
-- Lúc này đã chắc chắn có tổ, Starter không cần lo việc này nữa
-- ====================================================
task.spawn(function()
    while true do
        task.wait(1)
        
        local beeCount = Toolkit.AutoFarm.GetRealBeeCount()
        local CurrentStrategy = nil
        
        if beeCount < 5 then
            -- Gọi Starter (Cotmoc1)
            if not Toolkit.Starter then 
                Toolkit.Starter = LoadWorker("Cotmoc1") -- Nhớ đổi tên Cotmoc1 -> Starter trên Github sau
            end
            CurrentStrategy = Toolkit.Starter
            
        elseif beeCount < 10 then
            Log("Phase: 5 Bee Zone (Coming Soon)")
        else
            Log("Phase: High Level")
        end

        if CurrentStrategy and CurrentStrategy.Run then
            pcall(function()
                CurrentStrategy.Run(Log, task.wait, Toolkit)
            end)
        end
    end
end)
