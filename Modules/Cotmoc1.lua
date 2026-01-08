local module = {}

function module.Run(LogFunc, WaitFunc)
    -- Service cần thiết
    local TweenService = game:GetService("TweenService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = game:GetService("Players").LocalPlayer

    -- Tọa độ Shop Trứng (Bạn đã lấy)
    local ShopPosition = CFrame.new(-140.41, 4.69, 243.97)

    -- Hàm Bay (Để module tự chạy độc lập)
    local function flyTo(targetCFrame)
        WaitFunc()
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local root = char.HumanoidRootPart
        local finalPos = targetCFrame.Position + Vector3.new(0, 5, 0)
        
        -- Tính tốc độ bay (250 là vừa phải, không quá nhanh để bị kick)
        local dist = (finalPos - root.Position).Magnitude
        local time = dist / 250
        
        local tween = TweenService:Create(root, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = CFrame.new(finalPos)})
        local bv = Instance.new("BodyVelocity", root); bv.Velocity = Vector3.zero; bv.MaxForce = Vector3.one * math.huge
        
        tween:Play()
        tween.Completed:Wait()
        bv:Destroy()
        root.Velocity = Vector3.zero
    end

    -- === LOGIC CỘT MỐC 1: MUA TRỨNG ===
    LogFunc("Cotmoc1: Di chuyen den Shop Trung...", Color3.fromRGB(255, 220, 0))
    
    flyTo(ShopPosition)
    task.wait(1) -- Đứng nghỉ xíu cho load shop
    
    -- Mua 2 quả trứng
    for i = 1, 2 do
        WaitFunc()
        LogFunc("Action: Mua Basic Egg lan " .. i, Color3.fromRGB(150, 150, 150))
        
        local args = {
            [1] = "Purchase",
            [2] = {
                ["Type"] = "Basic",
                ["Amount"] = 1,
                ["Category"] = "Eggs"
            }
        }
        
        -- Dùng pcall để tránh lỗi vặt làm dừng script
        local success, err = pcall(function()
            game:GetService("ReplicatedStorage").Events.ItemPackageEvent:InvokeServer(unpack(args))
        end)

        if not success then
            LogFunc("Error: Mua that bai lan " .. i, Color3.fromRGB(255, 80, 80))
        end
        
        task.wait(3.5) -- Đợi trứng nở animation xong mới mua tiếp
    end

    LogFunc("Cotmoc1: Hoan thanh mua trung!", Color3.fromRGB(0, 255, 0))
end

return module
