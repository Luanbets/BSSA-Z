local module = {}
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Check số lượng Item/Trứng đang có
function module.GetItemAmount(itemName)
    local inventory = LocalPlayer:FindFirstChild("b") -- Folder items
    local eggs = LocalPlayer:FindFirstChild("EggStats") -- Folder trứng
    
    if inventory and inventory:FindFirstChild(itemName) then
        return inventory[itemName].Value
    end
    if eggs and eggs:FindFirstChild(itemName) then
        return eggs[itemName].Value
    end
    return 0
end

-- Check số Honey đang có
function module.GetHoney()
    if LocalPlayer:FindFirstChild("CoreStats") and LocalPlayer.CoreStats:FindFirstChild("Honey") then
        return LocalPlayer.CoreStats.Honey.Value
    end
    return 0
end

return module
