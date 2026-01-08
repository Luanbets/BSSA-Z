local module = {}

local promoCodes = {
    "Wax", "Nectar", "Roof", "Connoisseur", "Crawlers", 
    "38217", "Bopmaster", "GumdropsForScience", "ClubBean", "BeesBuzz123"
}

function module.Run(LogFunc, WaitFunc)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local PromoEvent = ReplicatedStorage.Events.PromoCodeEvent

    task.wait(2)
    LogFunc("Action: Redeeming codes...", Color3.fromRGB(255, 220, 0))

    for _, code in ipairs(promoCodes) do
        WaitFunc()
        PromoEvent:FireServer(code)
        -- Log màu xám nhạt để báo đang chạy
        LogFunc("Checking: " .. code, Color3.fromRGB(150, 150, 150))
        task.wait(1.2)
    end
    
    LogFunc("Result: All codes redeemed", Color3.fromRGB(0, 255, 0))
end

return module
