local module = {}

function module.Run(listCode)
    print("Module RedeemCode: Bắt đầu nhập code...")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    for _, code in ipairs(listCode) do
        -- Check logic cơ bản để tránh spam nếu cần
        game:GetService("ReplicatedStorage").Events.PromoCodeEvent:FireServer(code)
        task.wait(1.2) -- Delay an toàn
    end
    
    print("Module RedeemCode: Xong!")
end

return module
