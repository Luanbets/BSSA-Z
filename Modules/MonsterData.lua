local MonsterData = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- ==============================================================================
-- CONFIGURATION
-- ==============================================================================
local MobCooldowns = {
    ["Ladybug"]      = 300,
    ["Rhino Beetle"] = 300,
    ["Spider"]       = 1800,
    ["Scorpion"]     = 1800,
    ["Mantis"]       = 1800,
    ["Werewolf"]     = 3600,
    ["Default"]      = 300
}

local RawMobList = {
    -- [ZONE 0]
    {Name = "MushroomBush",     Type = "Ladybug",      Field = "Mushroom Field"},
    {Name = "Rhino Cave 1",     Type = "Rhino Beetle", Field = "Blue Flower Field"},
    {Name = "Ladybug Bush",     Type = "Ladybug",      Field = "Clover Field"},
    {Name = "Rhino Bush",       Type = "Rhino Beetle", Field = "Clover Field"},
    -- [ZONE 5]
    {Name = "Ladybug Bush 2",   Type = "Ladybug",      Field = "Strawberry Field"},
    {Name = "Ladybug Bush 3",   Type = "Ladybug",      Field = "Strawberry Field"},
    {Name = "Rhino Cave 3",     Type = "Rhino Beetle", Field = "Bamboo Field"},
    {Name = "Rhino Cave 2",     Type = "Rhino Beetle", Field = "Bamboo Field"},
    {Name = "Spider Cave",      Type = "Spider",       Field = "Spider Field"},
    -- [ZONE 10]
    {Name = "PineappleBeetle",  Type = "Rhino Beetle", Field = "Pineapple Patch"},
    {Name = "PineappleMantis1", Type = "Mantis",       Field = "Pineapple Patch"},
    -- [ZONE 15]
    {Name = "ForestMantis1",    Type = "Mantis",       Field = "Pine Tree Forest"},
    {Name = "ForestMantis2",    Type = "Mantis",       Field = "Pine Tree Forest"},
    {Name = "RoseBush",         Type = "Scorpion",     Field = "Rose Field"},
    {Name = "RoseBush2",        Type = "Scorpion",     Field = "Rose Field"},
    {Name = "WerewolfCave",     Type = "Werewolf",     Field = "Cactus Field"}
}

-- ==============================================================================
-- INTERNAL HELPERS
-- ==============================================================================

local function IsMobAlive(name, cooldown)
    local s, stats = pcall(function() return ReplicatedStorage.Events.RetrievePlayerStats:InvokeServer() end)
    if s and stats then
        local lastKill = stats.MonsterTimes and stats.MonsterTimes[name]
        if not lastKill or (lastKill + cooldown < os.time()) then 
            return true 
        end
    end
    return false
end

local function CollectLoot(centerPos, radius)
    local endTime = os.time() + 4
    local char = LocalPlayer.Character
    while os.time() < endTime do
        local collectibles = Workspace:FindFirstChild("Collectibles")
        if collectibles and char and char:FindFirstChild("Humanoid") then
            for _, token in pairs(collectibles:GetChildren()) do
                if token:IsA("BasePart") and token.Transparency < 1 then
                    if (token.Position - centerPos).Magnitude <= radius then
                        char.Humanoid:MoveTo(token.Position)
                        task.wait(0.15)
                    end
                end
            end
        end
        task.wait(0.1)
    end
end

-- ==============================================================================
-- MAIN FUNCTIONS
-- ==============================================================================

-- 1. Get List of Killable Mobs (Based on Bees & Cooldown)
function MonsterData.GetActionableMobs(FieldModule, currentBees)
    local list = {}
    for _, mob in ipairs(RawMobList) do
        local fieldInfo = FieldModule.Fields[mob.Field]
        -- Check Zone Requirement
        if fieldInfo and currentBees >= fieldInfo.ReqBees then
            local time = MobCooldowns[mob.Type] or MobCooldowns["Default"]
            -- Check Cooldown Immediately to save time
            if IsMobAlive(mob.Name, time) then
                table.insert(list, {
                    Name = mob.Name,
                    Center = fieldInfo.Pos + Vector3.new(0, 5, 0),
                    Radius = (fieldInfo.Size.X + fieldInfo.Size.Z) / 4 + 10,
                    Time = time
                })
            end
        end
    end
    return list
end

-- 2. Execute Kill (Like ClaimHive: Run -> Done)
function MonsterData.KillMob(mobInfo, Utils, StatusFunc)
    -- Double check status just in case
    if not IsMobAlive(mobInfo.Name, mobInfo.Time) then return false end

    StatusFunc("Moving to " .. mobInfo.Name)
    if Utils.Tween then Utils.Tween(CFrame.new(mobInfo.Center)) end
    task.wait(0.5)

    StatusFunc("Fighting " .. mobInfo.Name)
    local startTime = os.time()
    
    while true do
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("Humanoid") then break end
        local hum = char.Humanoid
        local root = char.HumanoidRootPart

        -- Anti-Fling / Zone Check
        if (root.Position - mobInfo.Center).Magnitude > (mobInfo.Radius + 30) then
            StatusFunc("Re-aligning...")
            hum:MoveTo(mobInfo.Center)
            task.wait(1)
        end

        if hum.FloorMaterial ~= Enum.Material.Air then hum.Jump = true end
        
        if (root.Position - mobInfo.Center).Magnitude > 5 then
            hum:MoveTo(mobInfo.Center)
        end
        
        -- Success Condition
        if not IsMobAlive(mobInfo.Name, mobInfo.Time) then
            StatusFunc("Looting " .. mobInfo.Name)
            CollectLoot(mobInfo.Center, mobInfo.Radius)
            return true 
        end
        
        -- Timeout
        if os.time() - startTime > 45 then return false end
        task.wait()
    end
    return false
end

return MonsterData
