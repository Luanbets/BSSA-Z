local module = {}

function module.Run(LogFunc, WaitFunc)
    local TweenService = game:GetService("TweenService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local StarterGui = game:GetService("StarterGui")

    local function GetSpawnPosCFrame(spawnObj)
        if not spawnObj then return nil end
        if spawnObj:IsA("CFrameValue") then return spawnObj.Value
        elseif spawnObj:IsA("BasePart") then return spawnObj.CFrame
        else return nil end
    end

    local function flyTo(targetCFrame)
        WaitFunc()
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local root = char.HumanoidRootPart
        local finalPos = targetCFrame.Position + Vector3.new(0, 5, 0)
        local tween = TweenService:Create(root, TweenInfo.new((finalPos - root.Position).Magnitude/100, Enum.EasingStyle.Linear), {CFrame = CFrame.new(finalPos)})
        local bv = Instance.new("BodyVelocity", root); bv.Velocity = Vector3.zero; bv.MaxForce = Vector3.one * math.huge
        tween:Play(); tween.Completed:Wait(); bv:Destroy(); root.Velocity = Vector3.zero
    end

    local honeycombs = workspace:FindFirstChild("Honeycombs") or workspace:FindFirstChild("Hives")
    if not honeycombs then return false end

    for _, hive in pairs(honeycombs:GetChildren()) do
        WaitFunc()
        if hive:FindFirstChild("Owner") and (hive.Owner.Value == "" or hive.Owner.Value == nil) then
            local hiveID = hive.HiveID.Value
            local targetCF = GetSpawnPosCFrame(hive.SpawnPos)
            if targetCF then
                -- LOG GỌN
                LogFunc("Claiming Hive " .. hiveID .. "...", Color3.fromRGB(255, 220, 0))
                
                flyTo(targetCF)
                WaitFunc()
                task.wait(1.5)
                
                WaitFunc()
                ReplicatedStorage.Events.ClaimHive:FireServer(hiveID)
                task.wait(1)
                
                LogFunc("Hive Claimed", Color3.fromRGB(0, 255, 0))
                StarterGui:SetCore("SendNotification", {Title="System", Text="Hive Claimed", Duration=3})
                return true
            end
        end
    end

    LogFunc("No Empty Hive", Color3.fromRGB(255, 80, 80))
    return false
end

return module
