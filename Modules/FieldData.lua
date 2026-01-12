local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local lp = Players.LocalPlayer

local function getRealBeeCount()
    local honeycombs = Workspace:FindFirstChild("Honeycombs") or Workspace:FindFirstChild("Hives")
    if not honeycombs then return 0 end
    for _, hive in pairs(honeycombs:GetChildren()) do
        if hive:FindFirstChild("Owner") and hive.Owner.Value == lp then
            local cells = hive:FindFirstChild("Cells")
            if cells then
                local count = 0
                for _, cell in pairs(cells:GetChildren()) do
                    if cell:IsA("Model") and cell:FindFirstChild("CellType") and cell.CellType.Value ~= "Empty" then
                        count = count + 1
                    end
                end
                return count
            end
        end
    end
    return 0
end

local FieldData = {
    ["Sunflower Field"]   = {ID = 10614, Pos = Vector3.new(-208.95, 4, 176.58), Size = Vector3.new(80.71, 1, 131.51), ReqBees = 0},
    ["Dandelion Field"]   = {ID = 10415, Pos = Vector3.new(-29.70, 4, 221.57),  Size = Vector3.new(143.65, 1, 72.50), ReqBees = 0},
    ["Blue Flower Field"] = {ID = 11613, Pos = Vector3.new(146.87, 4, 99.31),   Size = Vector3.new(171.63, 2, 67.67), ReqBees = 0},
    ["Mushroom Field"]    = {ID = 11758, Pos = Vector3.new(-89.70, 4, 111.73),  Size = Vector3.new(128.50, 2, 91.50), ReqBees = 0},
    ["Clover Field"]      = {ID = 12646, Pos = Vector3.new(157.55, 34, 196.35), Size = Vector3.new(106.49, 2, 118.75), ReqBees = 0},
    ["Bamboo Field"]      = {ID = 11702, Pos = Vector3.new(132.96, 20, -25.60), Size = Vector3.new(156.45, 2, 74.80), ReqBees = 5},
    ["Strawberry Field"]  = {ID = 9529,  Pos = Vector3.new(-178.17, 20, -9.85), Size = Vector3.new(89.65, 2, 106.29), ReqBees = 5},
    ["Spider Field"]      = {ID = 11907, Pos = Vector3.new(-43.47, 20, -13.59), Size = Vector3.new(112.31, 2, 106.02), ReqBees = 5},
    ["Pineapple Patch"]   = {ID = 11906, Pos = Vector3.new(256.50, 68, -207.48),Size = Vector3.new(130.67, 2, 91.11), ReqBees = 10},
    ["Stump Field"]       = {ID = 12519, Pos = Vector3.new(424.48, 96, -174.81),Size = Vector3.new(110.48, 3, 113.31), ReqBees = 10},
    ["Rose Field"]        = {ID = 10198, Pos = Vector3.new(-327.46, 20, 129.50),Size = Vector3.new(123.07, 1, 82.86), ReqBees = 15},
    ["Pumpkin Patch"]     = {ID = 9289,  Pos = Vector3.new(-188.50, 68, -183.85),Size = Vector3.new(135.00, 1, 68.81), ReqBees = 15},
    ["Cactus Field"]      = {ID = 9289,  Pos = Vector3.new(-188.50, 68, -101.60),Size = Vector3.new(135.00, 1, 68.81), ReqBees = 15},
    ["Pine Tree Forest"]  = {ID = 11010, Pos = Vector3.new(-328.67, 68, -187.35),Size = Vector3.new(90.62, 1, 121.50), ReqBees = 15},
    ["Mountain Top Field"]= {ID = 10830, Pos = Vector3.new(77.68, 176, -165.43),Size = Vector3.new(97.73, 1, 110.82), ReqBees = 25},
    ["Coconut Field"]     = {ID = 10146, Pos = Vector3.new(-254.48, 71, 469.46),Size = Vector3.new(120.31, 1, 84.33), ReqBees = 35},
    ["Pepper Patch"]      = {ID = 9108,  Pos = Vector3.new(-488.76, 123, 535.68),Size = Vector3.new(82.39, 1, 110.55), ReqBees = 35},
}

local MaterialMap = {
    ["Sunflower Seed"] = {"Sunflower Field"},
    ["Pineapple"]      = {"Pineapple Patch"},
    ["Blueberry"]      = {"Blue Flower Field", "Bamboo Field", "Pine Tree Forest"},
    ["Strawberry"]     = {"Mushroom Field", "Strawberry Field"},
    ["Honey"]          = {"Sunflower Field", "Spider Field", "Pineapple Patch", "Pepper Patch"}
}

function FieldData.GetBestField(targetMaterial)
    local playerBees = getRealBeeCount()
    local possibleFields = MaterialMap[targetMaterial] or MaterialMap["Honey"]
    
    local bestField = nil
    local highestReq = -1 

    for _, fieldName in pairs(possibleFields) do
        local data = FieldData[fieldName]
        if data and playerBees >= data.ReqBees then
            if data.ReqBees > highestReq then
                highestReq = data.ReqBees
                bestField = fieldName
            end
        end
    end
    return bestField, (bestField and FieldData[bestField])
end

return FieldData
