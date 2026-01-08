local module = {}

local promoCodes = {
    "Wax", "Nectar", "Roof", "Connoisseur", "Crawlers", 
    "38217", "Bopmaster", "GumdropsForScience", "ClubBean", "BeesBuzz123"
}

function module.Run(LogFunc, WaitFunc)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local PromoEvent = ReplicatedStorage.Events.PromoCodeEvent

    task.wait(2)
    -- Chỉ thông báo 1 lần là đang bắt đầu nhập
    LogFunc("Action: Redeeming codes...", Color3.fromRGB(255, 220, 0))

    for _, code in ipairs(promoCodes) do
        WaitFunc()
        PromoEvent:FireServer(code)
        
        -- Đã xóa dòng Log("Checking: " .. code) ở đây cho đỡ rối
        
        task.wait(1.2) -- Vẫn giữ delay để không bị kick
    end
    
    -- Thông báo 1 lần khi xong hết
    LogFunc("Result: All codes checked", Color3.fromRGB(0, 255, 0))
end

return module
