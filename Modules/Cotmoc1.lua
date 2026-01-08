local module = {}

function module.Run(LogFunc, WaitFunc)
    local TweenService = game:GetService("TweenService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = game:GetService("Players").LocalPlayer

    local ShopPosition = CFrame.new(-140.41, 4.69, 243.97)

    local function flyTo(targetCFrame)
        WaitFunc()
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local root = char.HumanoidRootPart
        local finalPos = targetCFrame.Position + Vector3.new(0, 5, 0)
        local dist = (finalPos - root.Position).Magnitude
        local tween = TweenService:Create(root, TweenInfo.new(dist / 250, Enum.EasingStyle.Linear), {CFrame = CFrame.new(finalPos)})
        local bv = Instance.new("BodyVelocity", root); bv.Velocity = Vector3.zero; bv.MaxForce = Vector3.one * math.huge
        tween:Play(); tween.Completed:Wait(); bv:Destroy(); root.Velocity = Vector3.zero
    end

    -- LOG GỌN: BÁO BẮT ĐẦU
    LogFunc("Buying 2 Basic Eggs...", Color3.fromRGB(255, 220, 0)) 
    
    flyTo(ShopPosition)
    task.wait(1) 
    
    for i = 1, 2 do
        WaitFunc()
        -- KHÔNG LOG CHI TIẾT MUA TỪNG CÁI NỮA
        pcall(function()
            game:GetService("ReplicatedStorage").Events.ItemPackageEvent:InvokeServer("Purchase", {["Type"]="Basic", ["Amount"]=1, ["Category"]="Eggs"})
        end)
        task.wait(1) 
    end

    -- LOG GỌN: BÁO KẾT THÚC
    LogFunc("Eggs Purchased", Color3.fromRGB(0, 255, 0))
end

return module
