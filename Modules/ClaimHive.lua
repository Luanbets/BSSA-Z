local module = {}

function module.Run()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local honeycombs = workspace:FindFirstChild("Honeycombs") or workspace:FindFirstChild("Hives")
    local TweenService = game:GetService("TweenService")

    print("Module ClaimHive: Đang tìm tổ...")

    local function flyTo(targetCFrame)
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local root = char.HumanoidRootPart
        local finalPos = targetCFrame.Position + Vector3.new(0, 5, 0)
        
        local tweenInfo = TweenInfo.new((finalPos - root.Position).Magnitude/60, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(root, tweenInfo, {CFrame = CFrame.new(finalPos)})
        
        local bv = Instance.new("BodyVelocity", root)
        bv.Velocity = Vector3.zero
        bv.MaxForce = Vector3.one * math.huge
        
        tween:Play()
        tween.Completed:Wait()
        bv:Destroy()
        root.Velocity = Vector3.zero
    end
    
    for _, hive in pairs(honeycombs:GetChildren()) do
        if hive:FindFirstChild("Owner") and (hive.Owner.Value == "" or hive.Owner.Value == nil) then
            local hiveID = hive.HiveID.Value
            
            if hive:FindFirstChild("SpawnPos") then
                print("Module: Bay đến tổ " .. hiveID)
                flyTo(hive.SpawnPos.Value)
                task.wait(0.5)
            end
            
            ReplicatedStorage.Events.ClaimHive:FireServer(hiveID)
            task.wait(1)
            
            if hive.Owner.Value == LocalPlayer.Name then
                print("Module ClaimHive: Thành công!")
                return true
            end
        end
    end
    
    print("Module ClaimHive: Thất bại (Hết tổ)")
    return false
end

return module
