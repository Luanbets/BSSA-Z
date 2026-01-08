local module = {}

local promoCodes = {
    "Wax", "Nectar", "Roof", "Connoisseur", "Crawlers", 
    "38217", "Bopmaster", "GumdropsForScience", "ClubBean", "BeesBuzz123"
}

function module.Run(LogFunc, WaitFunc, Utils)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    task.wait(1)
    LogFunc("Redeeming Codes...", Color3.fromRGB(255, 220, 0))

    for _, code in ipairs(promoCodes) do
        WaitFunc()
        ReplicatedStorage.Events.PromoCodeEvent:FireServer(code)
        task.wait(1.2)
    end
    
    LogFunc("Redeem Completed", Color3.fromRGB(0, 255, 0))
    if Utils then Utils.SaveData("RedeemDone", true) end
end

return module
