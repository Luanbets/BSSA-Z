-- ====================================================
-- BSSA-Z: MASTER CONTROLLER (FIXED LOGIC)
-- ====================================================
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

-- 1. SETUP UI STATUS (Để xem script đang làm gì)
local uiName = "BSSA_Status"
if CoreGui:FindFirstChild(uiName) then CoreGui[uiName]:Destroy() end
local screen = Instance.new("ScreenGui", CoreGui); screen.Name = uiName
local lbl = Instance.new("TextLabel", screen)
lbl.Size = UDim2.new(0, 300, 0, 30); lbl.Position = UDim2.new(0.5, -150, 0.05, 0)
lbl.BackgroundColor3 = Color3.fromRGB(0,0,0); lbl.TextColor3 = Color3.fromRGB(0,255,0)
lbl.BackgroundTransparency = 0.5; lbl.Text = "Loading System..."

local function Log(text) lbl.Text = "STATUS: " .. text end

-- 2. HÀM LOAD MODULE
local function LoadWorker(name)
    -- Thay đổi đường dẫn này thành Github của bạn
    local url = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/" .. name .. ".lua?t="..tick()
    local success, content = pcall(function() return game:HttpGet(url) end)
    if success then
        local func = loadstring(content)
        if func then return func() end
    end
    return nil
end

Log("Loading Workers...")
local Toolkit = {
    Utils       = LoadWorker("Utilities"),
    FieldData   = LoadWorker("FieldData"),   -- Dữ liệu Map
    TokenData   = LoadWorker("TokenData"),   -- Dữ liệu Token
    ShopUtils   = LoadWorker("ShopUtils"),   -- Dữ liệu Shop
    PlayerUtils = LoadWorker("PlayerUtils"), -- Check Tiền/Item
    AutoFarm    = LoadWorker("AutoFarm"),    -- Logic Farm
    ClaimHive   = LoadWorker("ClaimHive"),   -- Logic Nhận Tổ
    RedeemCode  = LoadWorker("RedeemCode"),  -- Logic Code
}

if not Toolkit.AutoFarm or not Toolkit.ClaimHive then 
    Log("❌ Error: Missing Scripts")
    return 
end

-- ====================================================
-- BƯỚC 1: CLAIM HIVE (CHẠY 1 LẦN DUY NHẤT TẠI ĐÂY)
-- ====================================================
Log("Checking Hive Status...")
-- Hàm này sẽ trả về True nếu đã có tổ, False nếu thất bại
local hasHive = Toolkit.ClaimHive.Run(Log, task.wait, Toolkit.Utils)

if not hasHive then
    Log("❌ Failed to claim hive! Script Stopped.")
    return -- Dừng script luôn
end

Log("✅ Hive Ready! Starting Brain Loop...")

-- ====================================================
-- BƯỚC 2: VÒNG LẶP CHÍNH (QUẢN LÝ)
-- ====================================================
task.spawn(function()
    while true do
        task.wait(1)
        
        -- Lấy số ong hiện tại
        local beeCount = Toolkit.AutoFarm.GetRealBeeCount()
        local CurrentStrategy = nil
        
        -- CHỌN CHIẾN THUẬT DỰA TRÊN SỐ ONG
        if beeCount < 5 then
            -- Giai đoạn < 5 ong: Dùng script Starter (Cotmoc1)
            if not Toolkit.Starter then 
                Toolkit.Starter = LoadWorker("Cotmoc1") -- Load Cotmoc1
            end
            CurrentStrategy = Toolkit.Starter
            
        elseif beeCount < 10 then
            Log("Phase: 5 Bee Zone (Next Update)")
            -- Toolkit.Zone5 = LoadWorker("5BeeZone")
            -- CurrentStrategy = Toolkit.Zone5
        else
            Log("Phase: High Level")
        end

        -- THỰC THI CHIẾN THUẬT
        if CurrentStrategy and CurrentStrategy.Run then
            local s, e = pcall(function()
                -- Truyền Toolkit vào để Worker dùng
                CurrentStrategy.Run(Log, task.wait, Toolkit)
            end)
            if not s then warn("Strategy Error: " .. tostring(e)) end
        end
    end
end)
