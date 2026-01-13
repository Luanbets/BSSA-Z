-- ====================================================
-- AUTO BEE SWARM - ZERO TOUCH (MANAGER V4 - MULTITASKING)
-- Created for: Luận
-- ====================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. CẤU HÌNH REPO (CHÍNH XÁC TUYỆT ĐỐI)
local REPO_URL = "https://raw.githubusercontent.com/Luanbets/BSSA-Z/main/Modules/"

-- 2. HỆ THỐNG LOG (UI ĐƠN GIẢN)
local uiName = "BSSA_Manager_UI"
if CoreGui:FindFirstChild(uiName) then CoreGui[uiName]:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = uiName
if pcall(function() screenGui.Parent = CoreGui end) then else screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local logLabel = Instance.new("TextLabel", screenGui)
logLabel.Size = UDim2.new(0.5, 0, 0, 40)
logLabel.Position = UDim2.new(0.25, 0, 0, 0)
logLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
logLabel.BackgroundTransparency = 0.5
logLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
logLabel.TextSize = 18
logLabel.Font = Enum.Font.GothamBold
logLabel.Text = "Initializing BSSA-Z..."

local function Log(text, color)
    logLabel.Text = text
    logLabel.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    print("[BSSA]: " .. text)
end

-- 3. HÀM TẢI MODULE AN TOÀN
local function LoadModule(scriptName)
    local url = REPO_URL .. scriptName .. "?t=" .. tostring(tick())
    local success, content = pcall(function() return game:HttpGet(url) end)
    if not success then
        Log("❌ HTTP Fail: " .. scriptName, Color3.fromRGB(255, 80, 80))
        return nil
    end

    local func, loadErr = loadstring(content)
    if not func then
        Log("❌ Syntax Error: " .. scriptName, Color3.fromRGB(255, 80, 80))
        warn("[BSSA Syntax]: " .. tostring(loadErr))
        return nil
    end

    local runSuccess, module = pcall(func)
    if not runSuccess then
        Log("❌ Runtime Error: " .. scriptName, Color3.fromRGB(255, 80, 80))
        warn("[BSSA Runtime]: " .. tostring(module))
        return nil
    end
    return module
end

-- ====================================================
-- 4. TÍNH NĂNG ĐA NHIỆM (CHECK BACKGROUND)
-- Tự động kiểm tra và mua các món đồ đã Skip
-- ====================================================
local function StartBackgroundCheck(Tools)
    task.spawn(function()
        Log("🕵️ Background Check Started (Every 30s)", Color3.fromRGB(150, 150, 150))
        
        while true do
            task.wait(30) -- Chu kỳ kiểm tra 30 giây
            
            local data = Tools.Utils.LoadData()
            local pending = data.PendingItems or {} -- Lấy danh sách nợ
            
            if #pending > 0 then
                -- Log("🔍 Checking " .. #pending .. " skipped items...", Color3.fromRGB(150, 150, 150))
                
                local newPending = {}
                local boughtSomething = false
                
                for _, itemData in ipairs(pending) do
                    -- Kiểm tra xem đủ điều kiện mua chưa (Tiền + Nguyên liệu)
                    -- Lưu ý: Hàm CheckRequirements trả về {CanBuy = true/false, ...}
                    local check = Tools.Shop.CheckRequirements(itemData.Item, Tools.Player)
                    
                    if check.CanBuy then
                        -- ĐỦ ĐIỀU KIỆN -> MUA NGAY
                        Tools.Log("⚡ Background Buy: " .. itemData.Item, Color3.fromRGB(0, 255, 0))
                        
                        -- Tạm dừng Farm 1 chút để mua cho an toàn
                        local wasFarming = true -- Giả định đang farm
                        Tools.Farm.StopFarm()
                        task.wait(0.5)
                        
                        -- Gửi lệnh mua
                        ReplicatedStorage.Events.ItemPackageEvent:InvokeServer("Purchase", {
                            ["Type"] = itemData.Item, 
                            ["Category"] = itemData.Category
                        })
                        
                        task.wait(1)
                        boughtSomething = true
                        -- Mua xong thì KHÔNG thêm vào newPending nữa (Đã trả nợ xong)
                    else
                        -- Vẫn chưa đủ -> Giữ lại trong danh sách nợ
                        table.insert(newPending, itemData)
                    end
                end
                
                -- Cập nhật lại danh sách nợ mới
                if boughtSomething or #newPending ~= #pending then
                    Tools.Utils.SaveData("PendingItems", newPending)
                    
                    -- Nếu đã trả hết nợ
                    if #newPending == 0 then
                        Tools.Log("🎉 All Skipped Items Cleared!", Color3.fromRGB(0, 255, 0))
                    end
                    
                    -- Tiếp tục farm (Nếu đang ở trong vòng lặp farm của Zone 5 thì nó tự chạy tiếp)
                    -- Ở đây ta chỉ cần đảm bảo không bị kẹt là được.
                end
            end
        end
    end)
end

-- ====================================================
-- 5. LOGIC CHÍNH (MAIN THREAD)
-- ====================================================
task.spawn(function()
    task.wait(1)
    Log("Loading Core Modules...", Color3.fromRGB(255, 255, 0))

    -- Tải Modules
    local Utilities   = LoadModule("Utilities.lua")
    local PlayerUtils = LoadModule("PlayerUtils.lua")
    local ShopUtils   = LoadModule("ShopUtils.lua")
    local TokenData   = LoadModule("TokenData.lua")
    local FieldData   = LoadModule("FieldData.lua")
    local AutoFarm    = LoadModule("AutoFarm.lua")

    if not (Utilities and PlayerUtils and ShopUtils and TokenData and FieldData and AutoFarm) then
        Log("❌ STOP: Failed to load core modules!", Color3.fromRGB(255, 0, 0))
        return
    end

    -- Đóng gói công cụ (Tools Box)
    local Tools = {
        Log = Log,
        Utils = Utilities,
        Player = PlayerUtils,
        Shop = ShopUtils,
        Farm = AutoFarm,
        Field = FieldData,
        Token = TokenData
    }

    local SaveData = Utilities.LoadData()
    Log("Welcome back, " .. LocalPlayer.Name, Color3.fromRGB(100, 255, 100))

    -- A. NHỮNG VIỆC CƠ BẢN (CHẠY 1 LẦN)
    if not SaveData.HiveClaimed then
        local ClaimHive = LoadModule("ClaimHive.lua")
        if ClaimHive and ClaimHive.Run(Log, task.wait, Utilities) then
            Utilities.SaveData("HiveClaimed", true)
        end
    end

    if not SaveData.RedeemDone then
        local RedeemCode = LoadModule("RedeemCode.lua")
        if RedeemCode then RedeemCode.Run(Log, task.wait, Utilities) end
    end

    -- B. CHẠY STARTER (NẾU CHƯA XONG)
    if not SaveData.StarterDone then
        local Starter = LoadModule("Starter.lua") -- Tải Starter V4 (Có Skip logic)
        if Starter then
            Starter.Run(Tools) -- Chạy xong Starter mới đi tiếp
        end
    else
        Log("✅ Starter Previously Completed.", Color3.fromRGB(0, 255, 0))
    end

    -- C. KÍCH HOẠT CHẾ ĐỘ CHECK NGẦM (MULTITASKING)
    -- Từ giờ trở đi, nó sẽ âm thầm check các món đồ bị skip mỗi 30s
    StartBackgroundCheck(Tools)

    -- D. CHUYỂN SANG ZONE TIẾP THEO (5 BEE ZONE / AUTO FARM LOOP)
    Log("🚀 Entering Main Farm Loop (Zone 5+)...", Color3.fromRGB(0, 255, 255))
    
    -- Ví dụ sau này bạn có file 5BeeZone.lua:
    -- local Zone5 = LoadModule("5BeeZone.lua")
    -- if Zone5 then Zone5.Run(Tools) end
    
    -- Hiện tại: Treo máy Farm vĩnh viễn (Giả lập Zone tiếp theo)
    -- Nó sẽ farm ở Bamboo Field (hoặc cánh đồng tốt nhất cho Blueberry nếu bạn muốn)
    while true do
        -- Kiểm tra xem có đủ ong vào Bamboo không (5 ong)
        if PlayerUtils.GetBeeCount() >= 5 then
            Tools.Farm.StartFarm("Bamboo Field", Tools.Log, Tools.Utils)
        else
            -- Chưa đủ 5 ong thì farm Sunflower tiếp
            Tools.Farm.StartFarm("Sunflower Field", Tools.Log, Tools.Utils)
        end
        
        -- Dừng một chút để check lại (thực ra AutoFarm đã có vòng lặp riêng, 
        -- nhưng đây là vòng lặp của Main để quản lý lại nếu AutoFarm bị crash hoặc dừng)
        task.wait(10)
    end
end)
