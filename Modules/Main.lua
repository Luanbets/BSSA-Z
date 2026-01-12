-- ====================================================
-- MASTER CONTROLLER - CEO
-- ====================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- BIẾN HỆ THỐNG
local isRunning = true
local currentPhaseScript = nil -- Script tiến trình đang chạy

-- ====================================================
-- 1. LOAD WORKERS (CÔNG CỤ) - LOAD 1 LẦN DÙNG MÃI MÃI
-- ====================================================
local function LoadWorker(url)
    -- Thêm timestamp để tránh cache cũ
    local finalUrl = url .. "?t=" .. tostring(tick())
    local success, content = pcall(function() return game:HttpGet(finalUrl) end)
    if success then
        local func = loadstring(content)
        if func then return func() end
    end
    warn("❌ Failed to load worker: " .. url)
    return nil
end

print("🔄 Loading System Workers...")

-- Đóng gói tất cả Worker vào 1 cái hộp để đưa cho Script tiến trình dùng
local Toolkit = {
    Utils       = LoadWorker("https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/Utilities.lua"),
    ShopUtils   = LoadWorker("https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/ShopUtils.lua"),
    FieldData   = LoadWorker("https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/FieldData.lua"),
    TokenData   = LoadWorker("https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/TokenData.lua"),
    AutoFarm    = LoadWorker("https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/AutoFarm.lua"),
    PlayerUtils = LoadWorker("https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/PlayerUtils.lua"),
    -- Các worker phụ như ClaimHive, RedeemCode có thể để Script tiến trình tự gọi hoặc load ở đây luôn
    ClaimHive   = LoadWorker("https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/ClaimHive.lua"),
    RedeemCode  = LoadWorker("https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/RedeemCode.lua")
}

-- Kiểm tra xem load đủ chưa
if not Toolkit.AutoFarm or not Toolkit.ShopUtils then
    warn("⚠️ CRITICAL ERROR: Thiếu Worker quan trọng! Dừng hệ thống.")
    return
end

print("✅ Workers Loaded Successfully!")

-- ====================================================
-- 2. HÀM CHỌN TIẾN TRÌNH (PHASE SELECTOR)
-- ====================================================
local function GetCurrentPhaseScript(beeCount)
    -- LOGIC QUAN TRỌNG NHẤT Ở ĐÂY: CHIA GIAI ĐOẠN
    
    if beeCount < 5 then
        return "Starter.lua", "https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/Cotmoc1.lua" -- Tạm gọi Cotmoc1 là Starter
        
    elseif beeCount < 10 then
        return "5BeeZone.lua", "Link_To_5BeeZone_Script" -- Bạn sẽ điền link sau
        
    elseif beeCount < 15 then
        return "10BeeZone.lua", "Link_To_10BeeZone_Script"
        
    else
        return "EndGame", nil
    end
end

-- ====================================================
-- 3. VÒNG LẶP ĐIỀU HÀNH (MAIN LOOP)
-- ====================================================
task.spawn(function()
    while isRunning do
        task.wait(1) -- Check mỗi giây
        
        -- A. Lấy số lượng ong hiện tại để biết đang ở đâu
        -- (Sử dụng hàm từ AutoFarm hoặc PlayerUtils để đếm ong thật)
        local myBees = Toolkit.AutoFarm.GetRealBeeCount() 
        
        -- B. Xác định ai sẽ làm Quản lý (Phase nào)
        local phaseName, phaseLink = GetCurrentPhaseScript(myBees)
        
        if phaseLink then
            -- Load Script Tiến Trình
            local PhaseManager = LoadWorker(phaseLink)
            
            if PhaseManager and PhaseManager.Run then
                print("🔹 Executing Phase: " .. phaseName .. " | Bees: " .. myBees)
                
                -- C. GIAO QUYỀN CHO QUẢN LÝ
                -- Truyền bộ công cụ (Toolkit) cho quản lý dùng
                -- Hàm Run() này sẽ thực hiện 1 lượt logic rồi trả lại quyền cho Main
                local success, result = pcall(function()
                    PhaseManager.Run(Toolkit) 
                end)
                
                if not success then
                    warn("⚠️ Error in " .. phaseName .. ": " .. tostring(result))
                end
                
                -- Lưu ý: Script tiến trình (Starter.lua) không nên dùng vòng lặp while true wait() vĩnh viễn
                -- Nó nên chạy xong 1 logic (check mua đồ -> chưa đủ -> farm 1 tí) rồi return để Main còn check lại số ong.
            else
                print("⚠️ Không tải được script: " .. phaseName)
            end
        else
            print("🎉 Đã đạt cấp độ cao nhất hoặc chưa có script cho giai đoạn này!")
            -- Có thể chạy AutoFarm mặc định ở đây nếu muốn
        end
    end
end)
