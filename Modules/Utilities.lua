local module = {}

-- ============================
-- CẤU HÌNH TỐC ĐỘ (CHỈNH Ở ĐÂY)
-- ============================
module.Speed = 120 -- Tốc độ bay (Càng lớn càng nhanh)

-- ============================
-- HÀM TWEEN (DÙNG CHUNG)
-- ============================
function module.Tween(targetCFrame, WaitFunc)
    local TweenService = game:GetService("TweenService")
    local LocalPlayer = game:GetService("Players").LocalPlayer
    
    -- Kiểm tra nhân vật
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local root = char.HumanoidRootPart
    
    -- Nếu có hàm Wait (Tạm dừng), chạy nó trước
    if WaitFunc then WaitFunc() end
    
    -- Tính toán vị trí bay (Cao hơn đích 5 unit)
    local finalPos = targetCFrame.Position + Vector3.new(0, 5, 0)
    local dist = (finalPos - root.Position).Magnitude
    
    -- Công thức thời gian: Quãng đường / Tốc độ
    local time = dist / module.Speed 
    
    -- Tạo và chạy Tween
    local tweenInfo = TweenInfo.new(time, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(root, tweenInfo, {CFrame = CFrame.new(finalPos)})
    
    local bv = Instance.new("BodyVelocity", root)
    bv.Velocity = Vector3.zero
    bv.MaxForce = Vector3.one * math.huge
    
    tween:Play()
    tween.Completed:Wait()
    
    -- Dọn dẹp sau khi bay xong
    bv:Destroy()
    root.Velocity = Vector3.zero
end

return module
