-- ============================================
-- SCRIPT FINAL SWARM ULTIMATE (BERSIH & OPTIMAL)
-- ============================================
-- Fitur:
--   ✅ Auto Farm (cari musuh terdekat + serang)
--   ✅ God Mode (4 lapis anti-death: Lock + HealthChanged + Died + ForceField)
--   ✅ Ghost Mode (noclip + fly)
--   ✅ 1 Hit Kill (multi-fallback: remote damage + set health 0 + break joints)
--   ✅ GUI 4 tombol
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- ============================================
-- [VARIABEL UTAMA]
-- ============================================
local character
local humanoid
local rootPart

local isFarming = false
local isGodMode = false
local isGhostMode = false
local isOneHit = false

local lastAttackTime = 0
local originalCollisions = {}   -- simpan CanCollide asli untuk restore

-- Cache mob
local cachedMobModels = {}
local lastMobScan = 0
local mobFolderNames = {"Monsters", "Enemies", "Mobs", "NPCs", "Zombies"}

-- Koneksi god mode
local godHealthConn
local godDiedConn

-- ============================================
-- [FUNGSI SETUP KARAKTER]
-- ============================================
local function ConnectCharacterEvents()
    if not humanoid then return end

    -- Disconnect koneksi lama biar nggak numpuk
    if godHealthConn then godHealthConn:Disconnect() end
    if godDiedConn then godDiedConn:Disconnect() end

    -- HealthChanged : instant recover saat kena damage
    godHealthConn = humanoid.HealthChanged:Connect(function(newHealth)
        if isGodMode and newHealth < humanoid.MaxHealth then
            humanoid.Health = humanoid.MaxHealth
        end
    end)

    -- Died : coba revive kalau god mode aktif
    godDiedConn = humanoid.Died:Connect(function()
        if isGodMode and character then
            task.wait(0.1)
            pcall(function()
                humanoid.Health = humanoid.MaxHealth
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
                rootPart.CFrame = rootPart.CFrame + Vector3.new(0, 5, 0)
            end)
        end
    end)
end

local function OnCharacterAdded(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    originalCollisions = {}

    -- Pasang event
    ConnectCharacterEvents()

    -- Reapply god mode jika aktif
    if isGodMode then
        pcall(function()
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
            humanoid.BreakJointsOnDeath = false
        end)
        humanoid.Health = humanoid.MaxHealth
    end

    -- Reapply ghost mode jika aktif
    if isGhostMode then
        ApplyGhostMode()
    end
end

if player.Character then
    OnCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(OnCharacterAdded)

-- ============================================
-- [FUNGSI CARI MOB TERDEKAT]
-- ============================================
local function UpdateMobCache()
    local now = tick()
    if now - lastMobScan < 1 then return end  -- throttle tiap 1 detik
    lastMobScan = now
    cachedMobModels = {}

    -- Cek folder umum
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

    -- Fallback: cari di seluruh Workspace
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

    local myPos = rootPart.Position
    local closestDist = math.huge
    local closestRoot = nil

    for _, model in ipairs(cachedMobModels) do
        local mobHumanoid = model:FindFirstChild("Humanoid")
        local mobRoot = model:FindFirstChild("HumanoidRootPart")
        if mobHumanoid and mobHumanoid.Health > 0 and mobRoot then
            local dist = (myPos - mobRoot.Position).Magnitude
            if dist < closestDist then
                closestDist = dist
                closestRoot = mobRoot
            end
        end
    end

    return closestRoot, closestDist
end

-- ============================================
-- [FUNGSI CARI REMOTE SERANG]
-- ============================================
local function FindAttackRemote()
    local remoteNames = {
        "AttackEvent", "Attack", "DamageEvent", "HitEvent", "Hit",
        "DealDamage", "DoDamage", "TakeDamage"
    }

    for _, name in ipairs(remoteNames) do
        local rem = ReplicatedStorage:FindFirstChild(name)
        if rem then return rem end
    end

    local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if remotesFolder then
        for _, name in ipairs(remoteNames) do
            local rem = remotesFolder:FindFirstChild(name)
            if rem then return rem end
        end
    end

    return nil
end

-- ============================================
-- [FUNGSI SERANG + 1 HIT KILL]
-- ============================================
local function AttackMob(targetPart)
    if not targetPart then return end
    local mob = targetPart.Parent
    local remote = FindAttackRemote()

    if isOneHit then
        -- Metode 1: remote damage besar
        if remote then
            pcall(function()
                remote:FireServer(mob, 999999)
                remote:FireServer(targetPart, 999999)
                remote:FireServer(mob.Name, 999999)
            end)
        end

        -- Metode 2: set health & break joints (backup)
        if mob and mob:FindFirstChild("Humanoid") then
            pcall(function()
                mob.Humanoid.Health = 0
                mob:BreakJoints()
            end)
        end
    else
        -- Serangan normal via remote
        if remote then
            pcall(function()
                remote:FireServer(mob)
            end)
        end
    end
end

-- ============================================
-- [FUNGSI GHOST MODE]
-- ============================================
function ApplyGhostMode()
    if not character then return end

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            if originalCollisions[part] == nil then
                originalCollisions[part] = part.CanCollide
            end
            part.CanCollide = false
        end
    end

    -- Biar nggak jatuh, paksa Flying
    if humanoid then
        pcall(function()
            humanoid:ChangeState(Enum.HumanoidStateType.Flying)
        end)
    end
end

local function RestoreGhostMode()
    for part, origCanCollide in pairs(originalCollisions) do
        if part and part:IsDescendantOf(character) then
            pcall(function()
                part.CanCollide = origCanCollide
            end)
        end
    end
    originalCollisions = {}

    if humanoid then
        pcall(function()
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end)
    end
end

-- ============================================
-- [LOOP UTAMA]
-- ============================================
RunService.Heartbeat:Connect(function()
    if not character or not humanoid or not rootPart then return end

    -- ====== GOD MODE ======
    if isGodMode then
        -- Lock health
        if humanoid.Health ~= humanoid.MaxHealth then
            humanoid.Health = humanoid.MaxHealth
        end

        -- Anti void / kill brick
        local minY = Workspace.FallenPartsDestroyHeight or -500
        if rootPart.Position.Y < minY + 10 then
            rootPart.CFrame = CFrame.new(rootPart.Position.X, minY + 50, rootPart.Position.Z)
        end

        -- ForceField anti damage
        if not character:FindFirstChild("GodForceField") then
            local ff = Instance.new("ForceField")
            ff.Name = "GodForceField"
            ff.Visible = false
            ff.Parent = character
        end
    end

    -- ====== GHOST MODE ======
    if isGhostMode then
        ApplyGhostMode()
    end

    -- ====== AUTO FARM ======
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
-- [GUI 4 TOMBOL]
-- ============================================
local screenGui = Instance.new("ScreenGui")
local frame = Instance.new("Frame")
local btnFarm = Instance.new("TextButton")
local btnGod = Instance.new("TextButton")
local btnGhost = Instance.new("TextButton")
local btnOneHit = Instance.new("TextButton")

screenGui.Parent = player:WaitForChild("PlayerGui")
frame.Parent = screenGui
frame.Size = UDim2.new(0, 200, 0, 180)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0

-- Tombol Farm
btnFarm.Parent = frame
btnFarm.Size = UDim2.new(1, -20, 0, 35)
btnFarm.Position = UDim2.new(0, 10, 0, 10)
btnFarm.Text = "▶ Start Farm"
btnFarm.TextColor3 = Color3.fromRGB(255,255,255)
btnFarm.BackgroundColor3 = Color3.fromRGB(60, 60, 140)

-- Tombol God Mode
btnGod.Parent = frame
btnGod.Size = UDim2.new(1, -20, 0, 35)
btnGod.Position = UDim2.new(0, 10, 0, 50)
btnGod.Text = "🛡️ God Mode: OFF"
btnGod.TextColor3 = Color3.fromRGB(255,255,255)
btnGod.BackgroundColor3 = Color3.fromRGB(120, 40, 40)

-- Tombol Ghost Mode
btnGhost.Parent = frame
btnGhost.Size = UDim2.new(1, -20, 0, 35)
btnGhost.Position = UDim2.new(0, 10, 0, 90)
btnGhost.Text = "👻 Ghost Mode: OFF"
btnGhost.TextColor3 = Color3.fromRGB(255,255,255)
btnGhost.BackgroundColor3 = Color3.fromRGB(120, 40, 40)

-- Tombol 1 Hit Kill
btnOneHit.Parent = frame
btnOneHit.Size = UDim2.new(1, -20, 0, 35)
btnOneHit.Position = UDim2.new(0, 10, 0, 130)
btnOneHit.Text = "⚔️ 1 Hit Kill: OFF"
btnOneHit.TextColor3 = Color3.fromRGB(255,255,255)
btnOneHit.BackgroundColor3 = Color3.fromRGB(120, 40, 40)

-- ============================================
-- [EVENT TOMBOL]
-- ============================================
btnFarm.MouseButton1Click:Connect(function()
    isFarming = not isFarming
    btnFarm.Text = isFarming and "⏹ Stop Farm" or "▶ Start Farm"
end)

btnGod.MouseButton1Click:Connect(function()
    isGodMode = not isGodMode
    if isGodMode then
        btnGod.Text = "🛡️ God Mode: ON"
        btnGod.BackgroundColor3 = Color3.fromRGB(40, 120, 40)

        pcall(function()
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
            humanoid.BreakJointsOnDeath = false
        end)
        if humanoid then humanoid.Health = humanoid.MaxHealth end
    else
        btnGod.Text = "🛡️ God Mode: OFF"
        btnGod.BackgroundColor3 = Color3.fromRGB(120, 40, 40)

        pcall(function()
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
            humanoid.BreakJointsOnDeath = true
        end)
        -- Hapus forcefield
        local ff = character and character:FindFirstChild("GodForceField")
        if ff then ff:Destroy() end
    end
end)

btnGhost.MouseButton1Click:Connect(function()
    isGhostMode = not isGhostMode
    if isGhostMode then
        btnGhost.Text = "👻 Ghost Mode: ON"
        btnGhost.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
        ApplyGhostMode()
    else
        btnGhost.Text = "👻 Ghost Mode: OFF"
        btnGhost.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
        RestoreGhostMode()
    end
end)

btnOneHit.MouseButton1Click:Connect(function()
    isOneHit = not isOneHit
    if isOneHit then
        btnOneHit.Text = "⚔️ 1 Hit Kill: ON"
        btnOneHit.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
    else
        btnOneHit.Text = "⚔️ 1 Hit Kill: OFF"
        btnOneHit.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
    end
end)

print("✅ Script ULTIMATE bersih & optimal siap!")
print("💡 God Mode: 4 lapis | Ghost: fly+noclip | 1Hit: remote+break")