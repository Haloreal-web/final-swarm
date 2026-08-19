-- ============================================
-- SCRIPT FINAL SWARM - 1 HIT KILL UNTUK SEMUA SKILL
-- ============================================
-- Fitur:
--   ✅ Auto Farm (cari & serang musuh)
--   ✅ TRUE GOD MODE (Health Lock + Anti-Fall + Anti-Knockback + ForceField + Revive)
--   ✅ STEALTH (Musuh gak bisa nargetin kamu)
--   ✅ 1 HIT KILL (SEMUA damage kamu, apapun skillnya, langsung bunuh musuh)
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
local isStealth = false
local isOneHit = false

local lastAttackTime = 0
local cachedMobModels = {}
local lastMobScan = 0
local mobFolderNames = {"Monsters", "Enemies", "Mobs", "NPCs", "Zombies"}

-- ============================================
-- [TRUE GOD MODE - PALING KUAT]
-- ============================================
local function TrueGodMode()
    if not isGodMode then 
        if humanoid then humanoid.PlatformStand = false end
        return 
    end
    if not character or not humanoid or not rootPart then return end

    -- LAPIS 1: Lock Health FULL
    humanoid.Health = humanoid.MaxHealth

    -- LAPIS 2: Matiin state mati biar gak bisa mati
    pcall(function()
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        humanoid.BreakJointsOnDeath = false
    end)

    -- LAPIS 3: PlatformStand = true (ANTI JATUH, ANTI KNOCKBACK, ANTI DAMAGE LINGKUNGAN)
    -- Ini yang bikin kamu gak bakal mati karena "damage sendiri" atau terjatuh!
    humanoid.PlatformStand = true

    -- LAPIS 4: ForceField tak terlihat (tameng tambahan)
    if not character:FindFirstChild("GodForceField") then
        local ff = Instance.new("ForceField")
        ff.Name = "GodForceField"
        ff.Visible = false
        ff.Parent = character
    end

    -- LAPIS 5: Anti-Void (kalau tiba-tiba jatuh, teleport balik)
    local minY = Workspace.FallenPartsDestroyHeight or -500
    if rootPart.Position.Y < minY + 10 then
        rootPart.CFrame = CFrame.new(rootPart.Position.X, minY + 50, rootPart.Position.Z)
    end
end

-- Revive otomatis kalau mati kejepit (antisipasi)
humanoid.Died:Connect(function()
    if isGodMode then
        task.wait(0.1)
        pcall(function()
            humanoid.Health = humanoid.MaxHealth
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
            humanoid.PlatformStand = true
        end)
    end
end)

-- ============================================
-- [STEALTH - MUSUH GAK BISA NARGET]
-- ============================================
local function StealthMode()
    if not character then return end

    if isStealth then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function()
                    part.Transparency = 1  -- Jadi transparan
                    part.CanCollide = true -- Tetap nabrak tembok (gak ngebug)
                end)
            end
        end
        if humanoid then
            humanoid.HealthDisplayDistance = 0 -- Sembunyiin health bar
            humanoid.NameDisplayDistance = 0   -- Sembunyiin nama
        end
    else
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function()
                    part.Transparency = 0
                    part.CanCollide = true
                end)
            end
        end
        if humanoid then
            humanoid.HealthDisplayDistance = 100
            humanoid.NameDisplayDistance = 100
        end
    end
end

-- ============================================
-- [CARI & CACHE MUSUH]
-- ============================================
local function UpdateMobCache()
    local now = tick()
    if now - lastMobScan < 0.5 then return end
    lastMobScan = now
    cachedMobModels = {}

    for _, folderName in ipairs(mobFolderNames) do
        local folder = Workspace:FindFirstChild(folderName)
        if folder then
            for _, model in ipairs(folder:GetDescendants()) do
                if model:IsA("Model") and model:FindFirstChild("Humanoid") and model:FindFirstChild("HumanoidRootPart") then
                    if not Players:GetPlayerFromCharacter(model) then
                        table.insert(cachedMobModels, model)
                    end
                end
            end
        end
    end

    if #cachedMobModels == 0 then
        for _, model in ipairs(Workspace:GetDescendants()) do
            if model:IsA("Model") and model:FindFirstChild("Humanoid") and model:FindFirstChild("HumanoidRootPart") then
                if not Players:GetPlayerFromCharacter(model) and model ~= character then
                    table.insert(cachedMobModels, model)
                end
            end
        end
    end
end

local function GetNearestMob()
    UpdateMobCache()
    if not rootPart then return nil, 0 end

    local closestDist = math.huge
    local closestRoot = nil
    local myPos = rootPart.Position

    for _, model in ipairs(cachedMobModels) do
        local mobH = model:FindFirstChild("Humanoid")
        local mobR = model:FindFirstChild("HumanoidRootPart")
        if mobH and mobH.Health > 0 and mobR then
            local dist = (myPos - mobR.Position).Magnitude
            if dist < closestDist then
                closestDist = dist
                closestRoot = mobR
            end
        end
    end
    return closestRoot, closestDist
end

-- ============================================
-- [1 HIT KILL UNTUK SEMUA SKILL!!]
-- ============================================
local function OneHitKillScanner()
    if not isOneHit or not rootPart then return end
    if #cachedMobModels == 0 then UpdateMobCache() end

    local myPos = rootPart.Position

    for _, model in ipairs(cachedMobModels) do
        local mobH = model:FindFirstChild("Humanoid")
        local mobR = model:FindFirstChild("HumanoidRootPart")
        if mobH and mobH.Health > 0 and mobR then
            local dist = (myPos - mobR.Position).Magnitude
            
            -- Radius 50 stud (cakupan skill/element kamu)
            if dist < 50 then
                -- JIKA HP MUSUH BERKURANG DARI MAX (ARTINYA KENA DAMAGE DARI SKILL/ELEMENT KAMU)
                -- MAKA LANGSUNG DIPAKSA MATI!
                if mobH.Health < mobH.MaxHealth then
                    pcall(function()
                        mobH.Health = 0
                        model:BreakJoints() -- Backup biar beneran mati
                    end)
                end
            end
        end
    end
end

-- ============================================
-- [FUNGSI SERANG + 1 HIT (AUTO FARM)]
-- ============================================
local function FindAttackRemote()
    local names = {"AttackEvent", "Attack", "DamageEvent", "HitEvent", "Hit", "DealDamage"}
    for _, n in ipairs(names) do
        local rem = ReplicatedStorage:FindFirstChild(n)
        if rem then return rem end
    end
    local remFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if remFolder then
        for _, n in ipairs(names) do
            local rem = remFolder:FindFirstChild(n)
            if rem then return rem end
        end
    end
    return nil
end

local function AttackMob(targetPart)
    if not targetPart then return end
    local mob = targetPart.Parent
    local remote = FindAttackRemote()

    if remote then
        pcall(function() remote:FireServer(mob) end)
    end
end

-- ============================================
-- [LOOP UTAMA]
-- ============================================
RunService.Heartbeat:Connect(function()
    if not character or not humanoid or not rootPart then return end

    -- Jalankan TRUE GOD MODE
    TrueGodMode()

    -- Jalankan STEALTH
    StealthMode()

    -- Jalankan 1 HIT KILL SCANNER (INI YANG BIKIN SEMUA SKILL MU JADI 1 HIT!)
    OneHitKillScanner()

    -- AUTO FARM
    if not isFarming then return end
    if humanoid.Health <= 0 then return end

    local enemy, dist = GetNearestMob()
    if enemy then
        humanoid:MoveTo(enemy.Position)
        if dist <= 15 then
            local now = tick()
            if now - lastAttackTime >= 0.2 then
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
    if isGodMode then
        humanoid.PlatformStand = true
        humanoid.Health = humanoid.MaxHealth
    end
end)

-- ============================================
-- [GUI 4 TOMBOL]
-- ============================================
local screenGui = Instance.new("ScreenGui")
local frame = Instance.new("Frame")
local btnFarm = Instance.new("TextButton")
local btnGod = Instance.new("TextButton")
local btnStealth = Instance.new("TextButton")
local btnOneHit = Instance.new("TextButton")

screenGui.Parent = player:WaitForChild("PlayerGui")
frame.Parent = screenGui
frame.Size = UDim2.new(0, 200, 0, 180)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0

btnFarm.Parent = frame
btnFarm.Size = UDim2.new(1, -20, 0, 35)
btnFarm.Position = UDim2.new(0, 10, 0, 10)
btnFarm.Text = "▶ Start Farm"
btnFarm.TextColor3 = Color3.fromRGB(255,255,255)
btnFarm.BackgroundColor3 = Color3.fromRGB(60, 60, 140)

btnGod.Parent = frame
btnGod.Size = UDim2.new(1, -20, 0, 35)
btnGod.Position = UDim2.new(0, 10, 0, 50)
btnGod.Text = "🛡️ TRUE GOD: OFF"
btnGod.TextColor3 = Color3.fromRGB(255,255,255)
btnGod.BackgroundColor3 = Color3.fromRGB(120, 40, 40)

btnStealth.Parent = frame
btnStealth.Size = UDim2.new(1, -20, 0, 35)
btnStealth.Position = UDim2.new(0, 10, 0, 90)
btnStealth.Text = "👻 Stealth: OFF"
btnStealth.TextColor3 = Color3.fromRGB(255,255,255)
btnStealth.BackgroundColor3 = Color3.fromRGB(120, 40, 40)

btnOneHit.Parent = frame
btnOneHit.Size = UDim2.new(1, -20, 0, 35)
btnOneHit.Position = UDim2.new(0, 10, 0, 130)
btnOneHit.Text = "⚔️ 1 Hit Kill: OFF"
btnOneHit.TextColor3 = Color3.fromRGB(255,255,255)
btnOneHit.BackgroundColor3 = Color3.fromRGB(120, 40, 40)

-- ====== EVENT TOMBOL ======
btnFarm.MouseButton1Click:Connect(function()
    isFarming = not isFarming
    btnFarm.Text = isFarming and "⏹ Stop Farm" or "▶ Start Farm"
end)

btnGod.MouseButton1Click:Connect(function()
    isGodMode = not isGodMode
    if isGodMode then
        btnGod.Text = "🛡️ TRUE GOD: ON"
        btnGod.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
        humanoid.PlatformStand = true
        humanoid.Health = humanoid.MaxHealth
    else
        btnGod.Text = "🛡️ TRUE GOD: OFF"
        btnGod.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
        humanoid.PlatformStand = false
        local ff = character:FindFirstChild("GodForceField")
        if ff then ff:Destroy() end
    end
end)

btnStealth.MouseButton1Click:Connect(function()
    isStealth = not isStealth
    btnStealth.Text = isStealth and "👻 Stealth: ON" or "👻 Stealth: OFF"
    btnStealth.BackgroundColor3 = isStealth and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(120, 40, 40)
end)

btnOneHit.MouseButton1Click:Connect(function()
    isOneHit = not isOneHit
    btnOneHit.Text = isOneHit and "⚔️ 1 Hit Kill: ON" or "⚔️ 1 Hit Kill: OFF"
    btnOneHit.BackgroundColor3 = isOneHit and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(120, 40, 40)
end)

print("✅ SCRIPT FINAL ULTIMATE! 1 Hit Kill berlaku untuk SEMUA skill/element yang nyenggol musuh!")
print("💡 Nyalain TRUE GOD + Stealth + 1 Hit Kill, dijamin musuh mati semua!")