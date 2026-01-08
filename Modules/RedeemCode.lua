local module = {}

-- Danh sách Code
local promoCodes = {
    "Wax",
    "Nectar",
    "Roof",
    "Connoisseur",
    "Crawlers",
    "38217",
    "Bopmaster",
    "GumdropsForScience",
    "ClubBean",
    "BeesBuzz123"
}

-- Hàm chạy chính (Nhận hàm Log từ Main chuyển sang để in thông báo lên UI)
function module.Run(LogFunc, WaitFunc)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local PromoEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("PromoCodeEvent")

    if LogFunc then LogFunc("Action: Starting Redeem Code...", Color3.fromRGB(255, 220, 0)) end

    for _, code in ipairs(promoCodes) do
        if WaitFunc then WaitFunc() end -- Check pause
        
        -- Gửi code
        PromoEvent:FireServer(code)
        
        -- In log (nếu có hàm Log)
        if LogFunc then 
            LogFunc("Redeeming: " .. code, Color3.fromRGB(200, 200, 200)) 
        end
        
        task.wait(1.2) -- Delay tránh bị kick
    end

    if LogFunc then LogFunc("Result: All codes checked!", Color3.fromRGB(0, 255, 0)) end
end

return module
