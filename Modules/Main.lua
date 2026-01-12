-- ====================================================
-- BSSA-Z: MASTER CONTROLLER (SAFE LOAD MODE)
-- ====================================================
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

-- 1. SETUP UI STATUS
local uiName = "BSSA_Status"
if CoreGui:FindFirstChild(uiName) then CoreGui[uiName]:Destroy() end
local screen = Instance.new("ScreenGui", CoreGui); screen.Name = uiName
local lbl = Instance.new("TextLabel", screen)
lbl.Size = UDim2.new(0, 300, 0, 30); lbl.Position = UDim2.new(0.5, -150, 0.05, 0)
lbl.BackgroundColor3 = Color3.fromRGB(0,0,0); lbl.TextColor3 = Color3.fromRGB(0,255,0)
lbl.BackgroundTransparency = 0.5; lbl.Text = "Starting BSSA-Z..."

local function Log(text) lbl.Text = "STATUS: " .. text end

-- 2. HÀM LOAD MODULE (CÓ THỬ LẠI)
local function LoadWorker(name)
    local url = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/" .. name .. ".lua?t="..tick()
    -- Thử tải 3 lần nếu mạng lag
    for i = 1, 3 do
        local success, content = pcall(function() return game:HttpGet(url) end)
        if success then
            local func = loadstring(content)
            if func then return func() end
        end
        task.wait(0.5)
    end
    return nil
end

Log("Loading System...")
local Toolkit = {
    Utils       = LoadWorker("Utilities"),
    FieldData   = LoadWorker("FieldData"),
    TokenData   = LoadWorker("TokenData"),
    ShopUtils   = LoadWorker("ShopUtils"),   -- << QUAN TRỌNG
    PlayerUtils = LoadWorker("PlayerUtils"), -- << QUAN TRỌNG
    AutoFarm    = LoadWorker("AutoFarm"),
    ClaimHive   = LoadWorker("ClaimHive"),
    RedeemCode  = LoadWorker("RedeemCode"),
}

-- KIỂM TRA TẤT CẢ MODULE
local missing = ""
if not Toolkit.AutoFarm then missing = missing .. "AutoFarm " end
if not Toolkit.ShopUtils then missing = missing .. "ShopUtils " end
if not Toolkit.PlayerUtils then missing = missing .. "PlayerUtils " end
if not Toolkit.ClaimHive then missing = missing .. "ClaimHive " end

if missing ~= "" then
    Log("❌ CRITICAL: Missing " .. missing)
    warn("❌ Không tải được các file: " .. missing .. ". Kiểm tra lại Link Github!")
    return -- Dừng ngay, không chạy tiếp để tránh lỗi "Đứng im"
end

-- ====================================================
-- BƯỚC 1: CLAIM HIVE
-- ====================================================
Log("Checking Hive...")
local hasHive = Toolkit.ClaimHive.Run(Log, task.wait, Toolkit.Utils)
if not hasHive then Log("❌ No Hive! Script Stopped."); return end

Log("✅ Hive Ready! Starting Brain Loop...")

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
            
            -- Chạy Starter trong pcall để nếu lỗi thì hiện ra console
            if Toolkit.Starter then
                local s, err = pcall(function()
                    Toolkit.Starter.Run(Log, task.wait, Toolkit)
                end)
                if not s then 
                    Log("⚠️ Error in Starter: " .. tostring(err)) 
                    print("LỖI CHI TIẾT:", err)
                end
            end
            
        elseif beeCount < 10 then
            Log("Phase: 5 Bee Zone (Coming Soon)")
        else
            Log("Phase: High Level")
        end
    end
end)
