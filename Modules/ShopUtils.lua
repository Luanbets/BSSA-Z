-- ====================================================
-- BSSA-Z: MASTER CONTROLLER (FIXED GITHUB LINK)
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
lbl.BackgroundTransparency = 0.5; lbl.Text = "BSSA-Z: Starting..."

local function Log(text) 
    lbl.Text = "STATUS: " .. text 
    print("[BSSA-LOG]: " .. text) -- In ra F9 để dễ kiểm tra
end

-- HÀM LOAD THÔNG MINH (THỬ 2 ĐƯỜNG LINK)
local function LoadWorker(name)
    -- Link 1: Chuẩn (như trong ảnh trình duyệt của bạn)
    local url1 = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/" .. name .. ".lua?t="..tick()
    -- Link 2: Dự phòng (như link bạn test thành công)
    local url2 = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/refs/heads/main/Modules/" .. name .. ".lua?t="..tick()
    
    -- Thử Link 1
    local success, content = pcall(function() return game:HttpGet(url1) end)
    if success and content ~= "404: Not Found" then
        local func = loadstring(content)
        if func then return func() end
    end
    
    -- Nếu Link 1 lỗi -> Thử Link 2
    local success2, content2 = pcall(function() return game:HttpGet(url2) end)
    if success2 and content2 ~= "404: Not Found" then
        local func = loadstring(content2)
        if func then return func() end
    end
    
    return nil
end

Log("Loading System Modules...")
local Toolkit = {
    Utils       = LoadWorker("Utilities"),
    FieldData   = LoadWorker("FieldData"),
    TokenData   = LoadWorker("TokenData"),
    ShopUtils   = LoadWorker("ShopUtils"),   -- << Script sẽ thử tải kỹ hơn
    PlayerUtils = LoadWorker("PlayerUtils"), 
    AutoFarm    = LoadWorker("AutoFarm"),
    ClaimHive   = LoadWorker("ClaimHive"),
    RedeemCode  = LoadWorker("RedeemCode"),
}

-- KIỂM TRA LẠI
local missing = ""
if not Toolkit.ShopUtils then missing = missing .. "ShopUtils " end
if not Toolkit.PlayerUtils then missing = missing .. "PlayerUtils " end
if not Toolkit.AutoFarm then missing = missing .. "AutoFarm " end

if missing ~= "" then
    Log("❌ CRITICAL: Missing " .. missing)
    return -- Dừng script nếu thiếu file
end

-- ====================================================
-- BƯỚC 1: CLAIM HIVE
-- ====================================================
Log("Checking Hive...")
local hasHive = Toolkit.ClaimHive.Run(Log, task.wait, Toolkit.Utils)
if not hasHive then Log("❌ No Hive! Script Stopped."); return end

Log("✅ Hive Ready! Running Logic...")

-- ====================================================
-- BƯỚC 2: MAIN LOOP
-- ====================================================
task.spawn(function()
    while true do
        task.wait(1)
        
        local beeCount = Toolkit.AutoFarm.GetRealBeeCount()
        
        if beeCount < 5 then
            if not Toolkit.Starter then 
                Toolkit.Starter = LoadWorker("Cotmoc1") 
            end
            
            if Toolkit.Starter then
                pcall(function() Toolkit.Starter.Run(Log, task.wait, Toolkit) end)
            end
            
        elseif beeCount < 10 then
            Log("Phase: 5 Bee Zone (Coming Soon)")
        else
            Log("Phase: High Level")
        end
    end
end)
