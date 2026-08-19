-- ============================================
-- GOD MODE ULTIMATE + REMOTE HEAL SPAM (CLIENT)
-- ============================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character, humanoid, rootPart
local isGodMode = false
local connections = {}
local forceFields = {}
local remoteList = {}  -- daftar remote yang akan dicoba

-- ============================================
-- [DAFTAR REMOTE YANG AKAN DICOBA]
-- ============================================
local function buildRemoteList()
    remoteList = {}

    local function addRemote(path, typeName)
        local obj = ReplicatedStorage:FindFirstChild(path)
        if not obj then
            -- Coba cari di dalam Packages
            local packages = ReplicatedStorage:FindFirstChild("Packages")
            if packages then
                local index = packages:FindFirstChild("_Index")
                if index then
                    local leif = index:FindFirstChild("leifstout_networker@0.3.0")
                    if not leif then
                        leif = index:FindFirstChild("leifstout_networker@0.2.1")
                    end
                    if leif then
                        local net = leif:FindFirstChild("networker")
                        if net then
                            local remotes = net:FindFirstChild("_remotes")
                            if remotes then
                                local service = remotes:FindFirstChild(path)
                                if service then
                                    obj = service:FindFirstChild(typeName == "RemoteEvent" and "RemoteEvent" or "RemoteFunction")
                                end
                            end
                        end
                    end
                end
            end
        end
        if obj then
            table.insert(remoteList, obj)
        end
    end

    -- PlayerStatus
    addRemote("PlayerStatus", "RemoteEvent")
    addRemote("PlayerStatus", "RemoteFunction")
    -- PlayerRunData
    addRemote("PlayerRunData", "RemoteEvent")
    addRemote("PlayerRunData", "RemoteFunction")
    -- GameService
    addRemote("GameService", "RemoteEvent")
    addRemote("GameService", "RemoteFunction")
    -- WeaponService (mungkin ada heal)
    addRemote("WeaponService", "RemoteEvent")
    addRemote("WeaponService", "RemoteFunction")
    -- EnemyService (mungkin ada damage control)
    addRemote("EnemyService", "RemoteEvent")
    addRemote("EnemyService", "RemoteFunction")
    -- CollectableService
    addRemote("CollectableService", "RemoteEvent")
    addRemote("CollectableService", "RemoteFunction")
    -- ChestService
    addRemote("ChestService", "RemoteEvent")
    addRemote("ChestService", "RemoteFunction")
    -- PauseService (bisa pause game, mungkin menghentikan serangan)
    addRemote("PauseService", "RemoteEvent")
    addRemote("PauseService", "RemoteFunction")
    -- MonetizationService (mungkin ada beli health)
    addRemote("MonetizationService", "RemoteEvent")
    addRemote("MonetizationService", "RemoteFunction")
    -- TutorialService
    addRemote("TutorialService", "RemoteEvent")
    addRemote("TutorialService", "RemoteFunction")
    -- Settings
    addRemote("Settings", "RemoteEvent")
    addRemote("Settings", "RemoteFunction")
end

buildRemoteList()

-- ============================================
-- [DAFTAR METHOD YANG AKAN DICOBA]
-- ============================================
local healMethods = {
    -- Format umum heal
    {"Heal", 1e9},
    {"Heal", "Full"},
    {"FullHeal"},
    {"RestoreHealth", 1e9},
    {"RestoreHealth"},
    {"AddHealth", 1e9},
    {"AddHP", 1e9},
    {"SetHealth", 1e9},
    {"SetHP", 1e9},
    {"ChangeHealth", 1e9},
    {"UpdateHealth", 1e9},
    {"RegenerateHealth", 1e9},
    {"Regen", 1e9},
    {"HealthRegen", 1e9},
    {"RegenHealth", 1e9},
    {"SetMaxHealth", 1e9},
    {"MaxHealth", 1e9},
    {"IncreaseMaxHealth", 1e9},
    {"UpgradeHealth", 1e9},
    {"HealthBoost", 1e9},
    {"BoostHealth", 1e9},
    {"AddMaxHealth", 1e9},
    {"SetHealthPercentage", 100},
    {"HealthPercentage", 100},
    {"SetHpPercentage", 100},
    {"SetHealthPercent", 100},
    -- Format data
    {"Set", {Health = 1e9, MaxHealth = 1e9, HP = 1e9, hp = 1e9}},
    {"Update", {Health = 1e9, MaxHealth = 1e9, HP = 1e9, hp = 1e9}},
    {"Change", {Health = 1e9, MaxHealth = 1e9, HP = 1e9, hp = 1e9}},
    {"Add", {Health = 1e9, MaxHealth = 1e9, HP = 1e9, hp = 1e9}},
    {"SetData", {Health = 1e9, MaxHealth = 1e9, HP = 1e9, hp = 1e9}},
    -- Format lain
    {"Health", 1e9},
    {"HP", 1e9},
    {"hp", 1e9},
    {"heal"},
    {"heal", 1e9},
    {"HealPlayer"},
    {"HealCharacter"},
    {"HealMe"},
    {"RestoreFullHealth"},
    {"Regenerate"},
    {"RegenerateAll"},
    {"RegenAll"},
    {"FullRegen"},
    {"Revive"},
    {"Respawn"},
    {"Rebirth"},
    {"ResetHealth"},
    {"ResetHP"},
}

local methodIndex = 1
local remoteIndex = 1
local lastAttempt = 0
local attemptInterval = 0.1 -- detik antar percobaan (cukup agresif)

-- ============================================
-- [FUNGSI COBA REMOTE HEAL]
-- ============================================
local function tryRemoteHeal()
    if #remoteList == 0 or #healMethods == 0 then return end
    if tick() - lastAttempt < attemptInterval then return end
    lastAttempt = tick()

    local remote = remoteList[remoteIndex]
    local args = healMethods[methodIndex]

    -- Pindah ke method berikutnya untuk percobaan selanjutnya
    methodIndex = methodIndex % #healMethods + 1
    -- Pindah ke remote berikutnya setelah semua method dicoba
    if methodIndex == 1 then
        remoteIndex = remoteIndex % #remoteList + 1
    end

    if remote then
        pcall(function()
            if remote:IsA("RemoteEvent") then
                remote:FireServer(unpack(args))
            elseif remote:IsA("RemoteFunction") then
                remote:InvokeServer(unpack(args))
            end
        end)
    end
end

-- ============================================
-- [FUNGSI GOD MODE]
-- ============================================
local function ApplyGodMode()
    if not character or not humanoid or not rootPart then return end

    -- Bersihkan koneksi lama
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    connections = {}

    -- Set health awal
    pcall(function()
        humanoid.MaxHealth = 1e9
        humanoid.Health = 1e9
    end)

    -- Reactive heal
    local healthChanged = humanoid.HealthChanged:Connect(function(newHealth)
        if isGodMode and newHealth < 1e9 then
            humanoid.Health = 1e9
        end
    end)
    table.insert(connections, healthChanged)

    -- Jaga MaxHealth
    local maxHealthChanged = humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
        if isGodMode then
            humanoid.MaxHealth = 1e9
            humanoid.Health = 1e9
        end
    end)
    table.insert(connections, maxHealthChanged)

    -- Matikan state mati
    pcall(function()
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
        humanoid.BreakJointsOnDeath = false
    end)

    -- ForceField bertumpuk
    for i = 1, 10 do
        local ff = Instance.new("ForceField")
        ff.Name = "GodShield_" .. i
        ff.Visible = false
        ff.Parent = character
        table.insert(forceFields, ff)
    end

    -- Anchor semua part (anti knockback)
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                part.Anchored = true
            end)
        end
    end

    -- Anti void
    local minY = Workspace.FallenPartsDestroyHeight or -500
    if rootPart.Position.Y < minY + 10 then
        rootPart.CFrame = CFrame.new(rootPart.Position.X, minY + 50, rootPart.Position.Z)
    end

    -- Auto respawn super cepat jika mati
    local diedConn = humanoid.Died:Connect(function()
        if isGodMode then
            -- Langsung respawn dalam 0.05 detik
            task.wait(0.05)
            pcall(function()
                player:LoadCharacter()
            end)
        end
    end)
    table.insert(connections, diedConn)

    -- Loop utama
    local heartbeatLoop = RunService.Heartbeat:Connect(function()
        if isGodMode and humanoid and humanoid.Parent then
            -- Paksa health tetap tinggi
            if humanoid.Health < 1e9 then
                humanoid.Health = 1e9
            end
            if humanoid.MaxHealth ~= 1e9 then
                humanoid.MaxHealth = 1e9
            end
            -- Coba remote heal
            tryRemoteHeal()
        end
    end)
    table.insert(connections, heartbeatLoop)
end

-- ============================================
-- [FUNGSI MATIKAN GOD MODE]
-- ============================================
local function RemoveGodMode()
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    connections = {}

    for _, ff in ipairs(forceFields) do
        pcall(function() ff:Destroy() end)
    end
    forceFields = {}

    pcall(function()
        if humanoid then
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
            humanoid.BreakJointsOnDeath = true
            humanoid.MaxHealth = 100
            humanoid.Health = 100
        end
    end)

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                part.Anchored = false
            end)
        end
    end
end

-- ============================================
-- [EVENT CHARACTER]
-- ============================================
local function OnCharacterAdded(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")

    if isGodMode then
        ApplyGodMode()
    end
end

if player.Character then
    OnCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(OnCharacterAdded)

-- ============================================
-- [GUI TOMBOL]
-- ============================================
local screenGui = Instance.new("ScreenGui")
local frame = Instance.new("Frame")
local btn = Instance.new("TextButton")
local status = Instance.new("TextLabel")

screenGui.Parent = player:WaitForChild("PlayerGui")
frame.Parent = screenGui
frame.Size = UDim2.new(0, 250, 0, 90)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0

btn.Parent = frame
btn.Size = UDim2.new(1, -20, 0, 40)
btn.Position = UDim2.new(0, 10, 0, 10)
btn.Text = "🛡️ GOD MODE: OFF"
btn.TextColor3 = Color3.fromRGB(255,255,255)
btn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)

status.Parent = frame
status.Size = UDim2.new(1, -20, 0, 25)
status.Position = UDim2.new(0, 10, 0, 55)
status.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
status.Text = "Remote heal: standby"
status.TextColor3 = Color3.fromRGB(255,255,255)
status.Font = Enum.Font.SourceSans
status.TextSize = 12

btn.MouseButton1Click:Connect(function()
    isGodMode = not isGodMode
    if isGodMode then
        btn.Text = "🛡️ GOD MODE: ON (ULTIMATE)"
        btn.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
        ApplyGodMode()
        status.Text = "Remote heal: aktif, mencoba semua method..."
    else
        btn.Text = "🛡️ GOD MODE: OFF"
        btn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
        RemoveGodMode()
        status.Text = "Remote heal: off"
    end
end)

print("✅ Script God Mode Ultimate aktif!")
print("💡 Jika masih mati, server memang full authoritative. Gunakan server script untuk hasil 100%.")