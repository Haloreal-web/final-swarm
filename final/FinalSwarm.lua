-- ============================================
-- SCRIPT FINAL SWARM (STRIPPED + GOD MODE)
-- ============================================
-- Fitur: Cuma Auto Serang Musuh Terdekat + God Mode
-- Tanpa Upgrade, Tanpa Portal (biar simpel & ga bug)
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- ============================================
-- [VARIABEL]
-- ============================================
local isFarming = false
local isGodMode = false
local lastAttackTime = 0

-- ============================================
-- [FUNGSI CARI MUSUH TERDEKAT]
-- ============================================
local function GetNearestMob()
    -- Cari folder monster (auto detect, cocok sama struktur game pada umumnya)
    local mobFolder = Workspace:FindFirstChild("Monsters") or Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("Mobs")
    if not mobFolder then return nil end
    
    local closestDist = math.huge
    local closestMob = nil
    
    for _, child in ipairs(mobFolder:GetChildren()) do
        if child:IsA("Model") and child:FindFirstChild("Humanoid") then
            local mobHumanoid = child.Humanoid
            if mobHumanoid.Health > 0 then
                local mobRoot = child:FindFirstChild("HumanoidRootPart")
                if mobRoot and rootPart then
                    local dist = (rootPart.Position - mobRoot.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestMob = mobRoot
                    end
                end
            end
        end
    end
    return closestMob, closestDist
end

-- ============================================
-- [FUNGSI SERANG]
-- ============================================
local function AttackMob(targetPart)
    if not targetPart then return end
    
    -- Coba kirim RemoteEvent (cara kerja umum script cheat)
    local attackRemote = ReplicatedStorage:FindFirstChild("AttackEvent") or ReplicatedStorage:FindFirstChild("Attack")
    if attackRemote then
        pcall(function()
            attackRemote:FireServer(targetPart.Parent)
        end)
    end
    
    -- Backup: simulasi klik mouse kalau remote gak ada
    pcall(function()
        local mouse = player:GetMouse()
        if mouse then
            mouse.Target = targetPart
        end
    end)
end

-- ============================================
-- [LOOP UTAMA]
-- ============================================
RunService.Heartbeat:Connect(function()
    -- GOD MODE: Lock health ke max
    if isGodMode and humanoid then
        humanoid.Health = humanoid.MaxHealth
    end

    -- AUTO FARM
    if not isFarming then return end
    if not character or not rootPart or not humanoid then return end
    if humanoid.Health <= 0 then return end

    local enemy, dist = GetNearestMob()
    if enemy then
        humanoid:MoveTo(enemy.Position)
        
        -- Jarak serang (15 studs)
        if dist <= 15 then
            local now = tick()
            if now - lastAttackTime >= 0.3 then -- Cooldown 0.3 detik
                AttackMob(enemy)
                lastAttackTime = now
            end
        end
    end
end)

-- ============================================
-- [RESPAWN HANDLER]
-- ============================================
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
end)

-- ============================================
-- [GUI 2 TOMBOL]
-- ============================================
local screenGui = Instance.new("ScreenGui")
local frame = Instance.new("Frame")
local btnFarm = Instance.new("TextButton")
local btnGod = Instance.new("TextButton")

screenGui.Parent = player:WaitForChild("PlayerGui")
frame.Parent = screenGui
frame.Size = UDim2.new(0, 180, 0, 100)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0

-- Tombol Farm
btnFarm.Parent = frame
btnFarm.Size = UDim2.new(1, -20, 0, 35)
btnFarm.Position = UDim2.new(0, 10, 0, 10)
btnFarm.Text = "▶ Start Farm"
btnFarm.TextColor3 = Color3.fromRGB(255,255,255)
btnFarm.BackgroundColor3 = Color3.fromRGB(60, 60, 120)

-- Tombol God Mode
btnGod.Parent = frame
btnGod.Size = UDim2.new(1, -20, 0, 35)
btnGod.Position = UDim2.new(0, 10, 0, 50)
btnGod.Text = "🛡️ God Mode: OFF"
btnGod.TextColor3 = Color3.fromRGB(255,255,255)
btnGod.BackgroundColor3 = Color3.fromRGB(120, 40, 40)

-- Fungsi Tombol Farm
btnFarm.MouseButton1Click:Connect(function()
    isFarming = not isFarming
    btnFarm.Text = isFarming and "⏹ Stop Farm" or "▶ Start Farm"
end)

-- Fungsi Tombol God Mode
btnGod.MouseButton1Click:Connect(function()
    isGodMode = not isGodMode
    if isGodMode then
        btnGod.Text = "🛡️ God Mode: ON"
        btnGod.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
        if humanoid then humanoid.Health = humanoid.MaxHealth end
    else
        btnGod.Text = "🛡️ God Mode: OFF"
        btnGod.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
    end
end)

print("✅ Script siap! Cuma Auto Farm + God Mode, ga ada fitur lain.")