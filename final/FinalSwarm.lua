-- ============================================
-- GOD MODE + REMOTE HEAL (PLAYERSTATUS)
-- ============================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character, humanoid, rootPart
local isGodMode = false
local connections = {}
local forceFields = {}
local healMethods = {
    {"Heal", 1e9},
    {"SetHealth", 1e9},
    {"ChangeHealth", 1e9},
    {"RestoreHealth", 1e9},
    {"FullHeal"},
    {"RegenHealth", 1e9},
    {"AddHealth", 1e9},
    {"UpdateHealth", 1e9},
    {"SetMaxHealth", 1e9},
    {"UpgradeHealth", 1e9},
    {"HealthBoost", 1e9},
    {"IncreaseHealth", 1e9},
    {"SetHP", 1e9},
    {"SetHealthPercentage", 100},
    {"HealPlayer", 1e9},
    {"HealCharacter", 1e9},
    {"HealthRegen", 1e9},
    {"Regen", 1e9},
}
local methodIndex = 1
local lastRemoteAttempt = 0
local remoteAttemptInterval = 1 -- detik antar percobaan remote

-- Cari remote PlayerStatus
local playerStatusRemote
local playerStatusFunction

local function findRemote(name)
    local container = ReplicatedStorage:FindFirstChild("Packages")
    if container then
        local networker = container:FindFirstChild("_Index")
        if networker then
            local leif = networker:FindFirstChild("leifstout_networker@0.3.0")
            if leif then
                local net = leif:FindFirstChild("networker")
                if net then
                    local remotes = net:FindFirstChild("_remotes")
                    if remotes then
                        local service = remotes:FindFirstChild(name)
                        if service then
                            return service:FindFirstChild("RemoteEvent"), service:FindFirstChild("RemoteFunction")
                        end
                    end
                end
            end
        end
    end
    return nil, nil
end

playerStatusRemote, playerStatusFunction = findRemote("PlayerStatus")

-- Jika tidak ketemu, coba versi 0.2.1
if not playerStatusRemote then
    local container = ReplicatedStorage:FindFirstChild("Packages")
    if container then
        local networker = container:FindFirstChild("_Index")
        if networker then
            local leif = networker:FindFirstChild("leifstout_networker@0.2.1")
            if leif then
                local net = leif:FindFirstChild("networker")
                if net then
                    local remotes = net:FindFirstChild("_remotes")
                    if remotes then
                        local service = remotes:FindFirstChild("PlayerStatus")
                        if service then
                            playerStatusRemote = service:FindFirstChild("RemoteEvent")
                            playerStatusFunction = service:FindFirstChild("RemoteFunction")
                        end
                    end
                end
            end
        end
    end
end

print("PlayerStatus RemoteEvent:", playerStatusRemote)
print("PlayerStatus RemoteFunction:", playerStatusFunction)

-- ============================================
-- [FUNGSI HEAL VIA REMOTE]
-- ============================================
local function tryRemoteHeal()
    if not playerStatusRemote and not playerStatusFunction then return end
    if not humanoid or not humanoid.Parent then return end
    if tick() - lastRemoteAttempt < remoteAttemptInterval then return end
    lastRemoteAttempt = tick()

    local args = healMethods[methodIndex]
    methodIndex = methodIndex % #healMethods + 1

    if playerStatusRemote then
        pcall(function()
            playerStatusRemote:FireServer(unpack(args))
        end)
    end

    if playerStatusFunction then
        pcall(function()
            playerStatusFunction:InvokeServer(unpack(args))
        end)
    end
end

-- ============================================
-- [FUNGSI GOD MODE]
-- ============================================
local function ApplyGodMode()
    if not character or not humanoid or not rootPart then return end

    -- Matikan koneksi lama
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    connections = {}

    -- Set health lokal
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
    for i = 1, 5 do
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

    -- Auto respawn kalau mati
    local diedConn = humanoid.Died:Connect(function()
        if isGodMode then
            task.wait(0.1)
            pcall(function()
                player:LoadCharacter()
            end)
        end
    end)
    table.insert(connections, diedConn)

    -- Loop utama
    local heartbeatLoop = RunService.Heartbeat:Connect(function()
        if isGodMode and humanoid and humanoid.Parent then
            -- Set health lokal terus
            if humanoid.Health < 1e9 then
                humanoid.Health = 1e9
            end
            if humanoid.MaxHealth ~= 1e9 then
                humanoid.MaxHealth = 1e9
            end
            -- Coba remote heal secara periodik
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
-- [GUI]
-- ============================================
local screenGui = Instance.new("ScreenGui")
local frame = Instance.new("Frame")
local btn = Instance.new("TextButton")

screenGui.Parent = player:WaitForChild("PlayerGui")
frame.Parent = screenGui
frame.Size = UDim2.new(0, 220, 0, 60)
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

btn.MouseButton1Click:Connect(function()
    isGodMode = not isGodMode
    if isGodMode then
        btn.Text = "🛡️ GOD MODE: ON (REMOTE HEAL)"
        btn.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
        ApplyGodMode()
    else
        btn.Text = "🛡️ GOD MODE: OFF"
        btn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
        RemoveGodMode()
    end
end)

print("✅ Script God Mode + Remote Heal aktif!")
print("💡 Script ini mencoba memanggil PlayerStatus remote dengan berbagai metode heal.")
print("⚠️ Jika masih mati, coba ganti daftar metode di 'healMethods' atau gunakan server script.")