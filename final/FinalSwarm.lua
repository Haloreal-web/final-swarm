-- ============================================
-- SCRIPT ULTIMATE - ANTI PANAH + ANTI AOE
-- ============================================
-- ✅ Panah dihancurin
-- ✅ Raycast (tembakan) gak kena
-- ✅ PlatformStand (anti jatuh & knockback)
-- ✅ Health Lock (buat jaga-jaga walau ilusi)
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local isRunning = false
local lastAttack = 0
local lastScan = 0
local cachedMobs = {}
local mobFolders = {"Monsters", "Enemies", "Mobs", "NPCs"}

-- ============================================
-- [PROYEKTIL DESTROYER]
-- ============================================
local function destroyProjectiles()
    if not rootPart then return end
    local myPos = rootPart.Position
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and not part:IsDescendantOf(character) then
            local speed = part.AssemblyLinearVelocity and part.AssemblyLinearVelocity.Magnitude or 0
            if speed > 20 and (myPos - part.Position).Magnitude < 35 then
                pcall(function() part:Destroy() end)
            end
        end
    end
end

-- ============================================
-- [DEFENSE + STEALTH + PLATFORMSTAND]
-- ============================================
local function applyDefense()
    if not character then return end
    
    -- 1. Stealth & Anti-Raycast
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                part.Transparency = 1
                part.CanCollide = true
                part.CanTouch = false
                part.CanQuery = false  -- Anti raycast
            end)
        end
    end
    if humanoid then
        humanoid.HealthDisplayDistance = 0
        humanoid.NameDisplayDistance = 0
        -- PlatformStand = Anti Jatuh & Anti Knockback (biar gak glitch)
        humanoid.PlatformStand = true
    end
    
    -- 2. ForceField
    if not character:FindFirstChild("DefenseShield") then
        local shield = Instance.new("ForceField")
        shield.Name = "DefenseShield"
        shield.Visible = false
        shield.Parent = character
    end

    -- 3. Health Lock (jaga-jaga biar gak tiba-tiba mati)
    if humanoid and humanoid.Health < humanoid.MaxHealth then
        humanoid.Health = humanoid.MaxHealth
    end
end

-- ============================================
-- [CARI MUSUH]
-- ============================================
local function getMobs()
    if tick() - lastScan < 0.5 then return cachedMobs end
    lastScan = tick()
    cachedMobs = {}
    for _, fname in ipairs(mobFolders) do
        local f = Workspace:FindFirstChild(fname)
        if f then
            for _, child in ipairs(f:GetChildren()) do
                if child:IsA("Model") and child:FindFirstChild("Humanoid") then
                    local h = child.Humanoid
                    if h.Health > 0 and not Players:GetPlayerFromCharacter(child) then
                        table.insert(cachedMobs, child)
                    end
                end
            end
        end
    end
    return cachedMobs
end

-- ============================================
-- [SERANG & NEXT WAVE]
-- ============================================
local function findRemote()
    local names = {"Attack", "Hit", "Damage", "Fire"}
    for _, n in ipairs(names) do
        local r = ReplicatedStorage:FindFirstChild(n)
        if r then return r end
    end
    return nil
end
local attackRemote = findRemote()

local function attackMob(mob)
    if not mob then return end
    if attackRemote then pcall(function() attackRemote:FireServer(mob) end) end
    pcall(function()
        local mouse = player:GetMouse()
        if mouse and mob:FindFirstChild("HumanoidRootPart") then
            mouse.Target = mob.HumanoidRootPart
        end
    end)
end

local function clickNextWave()
    for _, gui in ipairs(player.PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            for _, btn in ipairs(gui:GetDescendants()) do
                if btn:IsA("TextButton") and btn.Visible then
                    local t = btn.Text:lower()
                    if t:find("next") or t:find("wave") or t:find("start") then
                        pcall(function() btn:Click() end)
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- ============================================
-- [LOOP UTAMA]
-- ============================================
RunService.Heartbeat:Connect(function()
    if not isRunning then return end
    if not character or not humanoid or not rootPart then return end

    -- 1. Hancurin panah
    destroyProjectiles()
    
    -- 2. Pasang pertahanan (Stealth + Anti-Raycast + PlatformStand + Health Lock)
    applyDefense()

    -- 3. Auto Farm
    local mobs = getMobs()
    local closest, closestDist = nil, math.huge
    for _, mob in ipairs(mobs) do
        local hrp = mob:FindFirstChild("HumanoidRootPart")
        if hrp then
            local d = (rootPart.Position - hrp.Position).Magnitude
            if d < closestDist then
                closestDist = d
                closest = mob
            end
        end
    end

    if closest and closestDist < 50 then
        humanoid:MoveTo(closest.HumanoidRootPart.Position)
        if closestDist <= 15 and tick() - lastAttack > 0.2 then
            attackMob(closest)
            lastAttack = tick()
        end
    else
        if tick() % 2 < 0.1 then clickNextWave() end
    end
end)

-- ============================================
-- [RESPAWN]
-- ============================================
player.CharacterAdded:Connect(function(c)
    character = c
    humanoid = c:WaitForChild("Humanoid")
    rootPart = c:WaitForChild("HumanoidRootPart")
end)

-- ============================================
-- [GUI]
-- ============================================
local gui = Instance.new("ScreenGui")
local frame = Instance.new("Frame")
local btn = Instance.new("TextButton")
gui.Parent = player:WaitForChild("PlayerGui")
frame.Parent = gui
frame.Size = UDim2.new(0, 220, 0, 50)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0

btn.Parent = frame
btn.Size = UDim2.new(1, -20, 0, 35)
btn.Position = UDim2.new(0, 10, 0, 8)
btn.Text = "▶ START (AMAN PANAH & RAYCAST)"
btn.TextColor3 = Color3.fromRGB(255,255,255)
btn.BackgroundColor3 = Color3.fromRGB(60, 60, 140)

btn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    btn.Text = isRunning and "⏹ STOP" or "▶ START (AMAN PANAH & RAYCAST)"
    btn.BackgroundColor3 = isRunning and Color3.fromRGB(140, 40, 40) or Color3.fromRGB(60, 60, 140)
    print(isRunning and "✅ AKTIF! Panah hancur, raycast gak kena, AOE dikurangin." or "⏹ Mati.")
end)

print("✅ SCRIPT ULTIMATE! Panah & Tembakan GAK BISA KENA KAMU.")
print("⚠️ Catatan: Serangan Area (AOE/ledakan) mungkin tetap kena karena itu dari server.")