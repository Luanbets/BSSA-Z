-- ====================================================
-- BSSA-Z: MASTER CONTROLLER (ZERO TOUCH)
-- ====================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

-- 1. SETUP UI NHỎ GỌN (CHỈ ĐỂ HIỂN THỊ TRẠNG THÁI)
local uiName = "BSSA_Status"
if CoreGui:FindFirstChild(uiName) then CoreGui[uiName]:Destroy() end
local screen = Instance.new("ScreenGui", CoreGui); screen.Name = uiName
local lbl = Instance.new("TextLabel", screen)
lbl.Size = UDim2.new(0, 300, 0, 30); lbl.Position = UDim2.new(0.5, -150, 0.05, 0)
lbl.BackgroundColor3 = Color3.fromRGB(0,0,0); lbl.TextColor3 = Color3.fromRGB(0,255,0)
lbl.Text = "BSSA-Z: Initializing..."; lbl.BackgroundTransparency = 0.5

local function Log(text) lbl.Text = "STATUS: " .. text end

-- 2. HÀM LOAD MODULE (SỬ DỤNG LINK CỦA BẠN)
local function LoadWorker(name)
    local url = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/" .. name .. ".lua?t="..tick()
    local success, content = pcall(function() return game:HttpGet(url) end)
    if success then
        local func = loadstring(content)
        if func then return func() end
    end
    warn("❌ Failed to load: " .. name)
    return nil
end

-- 3. TẢI TOÀN BỘ WORKER (TOOLKIT) - CHỈ TẢI 1 LẦN
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
    -- Starter (Cotmoc1) tải sau để đảm bảo logic mới nhất
}

if not Toolkit.AutoFarm or not Toolkit.FieldData then 
    Log("❌ CRITICAL ERROR: Missing Modules")
    return 
end

-- 4. VÒNG LẶP CHÍNH (BRAIN LOOP)
task.spawn(function()
    while true do
        task.wait(1) -- Nhịp tim của hệ thống
        
        -- A. Kiểm tra số ong để chọn chiến thuật
        local beeCount = Toolkit.AutoFarm.GetRealBeeCount() -- Sử dụng hàm đếm ong trong AutoFarm
        
        local CurrentStrategy = nil
        
        if beeCount < 5 then
            Log("Phase: Starter (Bees: "..beeCount..")")
            -- Tải hoặc gọi Starter Script
            if not Toolkit.Starter then 
                Toolkit.Starter = LoadWorker("Cotmoc1") -- Đổi tên file Cotmoc1 thành Starter trên Github sau nhé
            end
            CurrentStrategy = Toolkit.Starter
            
        elseif beeCount < 10 then
            Log("Phase: 5 Bee Zone (Coming Soon)")
            -- Sau này bạn thêm: Toolkit.Zone5 = LoadWorker("5BeeZone")
            -- CurrentStrategy = Toolkit.Zone5
             
        else
            Log("Phase: High Level")
        end

        -- B. Thực thi chiến thuật
        if CurrentStrategy and CurrentStrategy.Run then
            -- Truyền toàn bộ Toolkit vào để Starter sử dụng
            local status, err = pcall(function()
                CurrentStrategy.Run(Log, task.wait, Toolkit)
            end)
            
            if not status then warn("Strategy Error: " .. tostring(err)) end
        end
    end
end)
