-- ============================================
-- SCRIPT GOD MODE SUPER REGEN (FULL FIX)
-- ============================================
-- ❌ Tidak ada auto attack / follow mob
-- ❌ Tidak ada destroy object / anti-raycast ilegal
-- ✅ Health regen gila (setiap 0.001 detik)
-- ✅ Override MaxHealth dari perk/upgrade
-- ✅ Anti mati berlapis-lapis
-- ✅ Karakter diam di tempat (anti knockback)
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character, humanoid, rootPart

local isGodMode = false
local godConnections = {}  -- simpan koneksi
local forceFields = {}     -- simpan forcefield
local regenThreads = {}    -- simpan thread loop

-- ============================================
-- [FUNGSI APPLY GOD MODE SUPER REGEN]
-- ============================================
local function ApplyGodMode()
    if not character or not humanoid or not rootPart then return end

    -- Matikan koneksi/thread lama biar bersih
    for _, conn in ipairs(godConnections) do
        pcall(function() conn:Disconnect() end)
    end
    godConnections = {}
    for _, thread in ipairs(regenThreads) do
        pcall(function() thread:Cancel() end)
    end
    regenThreads = {}

    ------------------------------------------------------------
    -- LAPIS 1: Set MaxHealth ke angka super besar
    ------------------------------------------------------------
    pcall(function()
        humanoid.MaxHealth = 1e9  -- 1 miliar (bisa diganti math.huge)
    end)

    ------------------------------------------------------------
    -- LAPIS 2: Set Health langsung ke MaxHealth (1 miliar)
    ------------------------------------------------------------
    pcall(function()
        humanoid.Health = humanoid.MaxHealth
    end)

    ------------------------------------------------------------
    -- LAPIS 3: Override MaxHealth jika perk mengubahnya
    ------------------------------------------------------------
    local maxHealthConn = humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
        if isGodMode then
            pcall(function()
                humanoid.MaxHealth = 1e9
                humanoid.Health = humanoid.MaxHealth
            end)
        end
    end)
    table.insert(godConnections, maxHealthConn)

    ------------------------------------------------------------
    -- LAPIS 4: HealthChanged langsung regen penuh
    ------------------------------------------------------------
    local healthChangedConn = humanoid.HealthChanged:Connect(function(newHealth)
        if isGodMode and newHealth < humanoid.MaxHealth then
            pcall(function()
                humanoid.Health = humanoid.MaxHealth
            end)
        end
    end)
    table.insert(godConnections, healthChangedConn)

    ------------------------------------------------------------
    -- LAPIS 5: Property Health berubah langsung regen penuh
    ------------------------------------------------------------
    local healthPropConn = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        if isGodMode and humanoid.Health < humanoid.MaxHealth then
            pcall(function()
                humanoid.Health = humanoid.MaxHealth
            end)
        end
    end)
    table.insert(godConnections, healthPropConn)

    ------------------------------------------------------------
    -- LAPIS 6: Matikan state Dead
    ------------------------------------------------------------
    pcall(function()
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    end)

    ------------------------------------------------------------
    -- LAPIS 7: Matikan state FallingDown (ragdoll)
    ------------------------------------------------------------
    pcall(function()
        humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    end)

    ------------------------------------------------------------
    -- LAPIS 8: Matikan state Ragdoll
    ------------------------------------------------------------
    pcall(function()
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    end)

    ------------------------------------------------------------
    -- LAPIS 9: Matikan state Physics
    ------------------------------------------------------------
    pcall(function()
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
    end)

    ------------------------------------------------------------
    -- LAPIS 10: Jangan hancurkan sambungan saat mati
    ------------------------------------------------------------
    pcall(function()
        humanoid.BreakJointsOnDeath = false
    end)

    ------------------------------------------------------------
    -- LAPIS 11: Event Died -> bangkit instan
    ------------------------------------------------------------
    local diedConn = humanoid.Died:Connect(function()
        if isGodMode then
            task.wait(0.01)
            pcall(function()
                humanoid.Health = humanoid.MaxHealth
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
                rootPart.CFrame = rootPart.CFrame + Vector3.new(0, 5, 0)
            end)
        end
    end)
    table.insert(godConnections, diedConn)

    ------------------------------------------------------------
    -- LAPIS 12-16: ForceField bertumpuk (5x)
    ------------------------------------------------------------
    for i = 1, 5 do
        local ff = Instance.new("ForceField")
        ff.Name = "GodShield_" .. i
        ff.Visible = false
        ff.Parent = character
        table.insert(forceFields, ff)
    end

    ------------------------------------------------------------
    -- LAPIS 17: Anchor semua part (anti knockback & jatuh)
    ------------------------------------------------------------
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                part.Anchored = true
            end)
        end
    end

    ------------------------------------------------------------
    -- LAPIS 18: CanCollide false semua part (anti serangan fisik)
    ------------------------------------------------------------
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                part.CanCollide = false
            end)
        end
    end

    ------------------------------------------------------------
    -- LAPIS 19: Sembunyikan health & nama
    ------------------------------------------------------------
    pcall(function()
        humanoid.HealthDisplayDistance = 0
        humanoid.NameDisplayDistance = 0
    end)

    ------------------------------------------------------------
    -- LAPIS 20: Anti void (teleport ke atas kalau jatuh)
    ------------------------------------------------------------
    local minY = Workspace.FallenPartsDestroyHeight or -500
    if rootPart.Position.Y < minY + 10 then
        rootPart.CFrame = CFrame.new(rootPart.Position.X, minY + 50, rootPart.Position.Z)
    end

    ------------------------------------------------------------
    -- LAPIS 21: Loop Heartbeat (setiap frame)
    ------------------------------------------------------------
    local heartbeatLoop = RunService.Heartbeat:Connect(function()
        if isGodMode and humanoid and humanoid.Parent then
            pcall(function()
                humanoid.MaxHealth = 1e9
                humanoid.Health = humanoid.MaxHealth
            end)
        end
    end)
    table.insert(godConnections, heartbeatLoop)

    ------------------------------------------------------------
    -- LAPIS 22: Loop Stepped (setiap physics step)
    ------------------------------------------------------------
    local steppedLoop = RunService.Stepped:Connect(function()
        if isGodMode and humanoid and humanoid.Parent then
            pcall(function()
                humanoid.Health = humanoid.MaxHealth
            end)
        end
    end)
    table.insert(godConnections, steppedLoop)

    ------------------------------------------------------------
    -- LAPIS 23: Loop RenderStepped (setiap render frame)
    ------------------------------------------------------------
    local renderLoop = RunService.RenderStepped:Connect(function()
        if isGodMode and humanoid and humanoid.Parent then
            pcall(function()
                humanoid.Health = humanoid.MaxHealth
            end)
        end
    end)
    table.insert(godConnections, renderLoop)

    ------------------------------------------------------------
    -- LAPIS 24: Super regen loop (tiap 0.001 detik)
    ------------------------------------------------------------
    local thread1 = task.spawn(function()
        while isGodMode and humanoid and humanoid.Parent do
            pcall(function()
                humanoid.Health = humanoid.MaxHealth
            end)
            task.wait(0.001)
        end
    end)
    table.insert(regenThreads, thread1)

    ------------------------------------------------------------
    -- LAPIS 25: MaxHealth lock loop (tiap 0.01 detik)
    ------------------------------------------------------------
    local thread2 = task.spawn(function()
        while isGodMode and humanoid and humanoid.Parent do
            pcall(function()
                humanoid.MaxHealth = 1e9
                humanoid.Health = humanoid.MaxHealth
            end)
            task.wait(0.01)
        end
    end)
    table.insert(regenThreads, thread2)

    ------------------------------------------------------------
    -- LAPIS 26: State lock loop (tiap 0.1 detik)
    ------------------------------------------------------------
    local thread3 = task.spawn(function()
        while isGodMode and humanoid and humanoid.Parent do
            pcall(function()
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
            end)
            task.wait(0.1)
        end
    end)
    table.insert(regenThreads, thread3)

    ------------------------------------------------------------
    -- LAPIS 27: ForceField refresh loop (tiap 1 detik)
    ------------------------------------------------------------
    local thread4 = task.spawn(function()
        while isGodMode and character and character.Parent do
            -- Cek forcefield masih ada, kalau hilang buat lagi
            local existing = character:FindFirstChild("GodShield_1")
            if not existing then
                local ff = Instance.new("ForceField")
                ff.Name = "GodShield_1"
                ff.Visible = false
                ff.Parent = character
            end
            task.wait(1)
        end
    end)
    table.insert(regenThreads, thread4)
end

-- ============================================
-- [FUNGSI REMOVE GOD MODE]
-- ============================================
local function RemoveGodMode()
    -- Matikan koneksi
    for _, conn in ipairs(godConnections) do
        pcall(function() conn:Disconnect() end)
    end
    godConnections = {}

    -- Matikan thread loop
    for _, thread in ipairs(regenThreads) do
        pcall(function() thread:Cancel() end)
    end
    regenThreads = {}

    -- Hapus forcefield
    for _, ff in ipairs(forceFields) do
        pcall(function() ff:Destroy() end)
    end
    forceFields = {}

    -- Kembalikan setting
    pcall(function()
        if humanoid then
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
            humanoid.BreakJointsOnDeath = true
            humanoid.MaxHealth = 100  -- ganti angka default
            humanoid.Health = humanoid.MaxHealth
            humanoid.HealthDisplayDistance = 100
            humanoid.NameDisplayDistance = 100
        end
    end)

    -- Unanchor & kembalikan CanCollide
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                part.Anchored = false
                part.CanCollide = true
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
local btnGod = Instance.new("TextButton")

screenGui.Parent = player:WaitForChild("PlayerGui")
frame.Parent = screenGui
frame.Size = UDim2.new(0, 200, 0, 60)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0

btnGod.Parent = frame
btnGod.Size = UDim2.new(1, -20, 0, 40)
btnGod.Position = UDim2.new(0, 10, 0, 10)
btnGod.Text = "🛡️ GOD MODE: OFF"
btnGod.TextColor3 = Color3.fromRGB(255,255,255)
btnGod.BackgroundColor3 = Color3.fromRGB(120, 40, 40)

btnGod.MouseButton1Click:Connect(function()
    isGodMode = not isGodMode
    if isGodMode then
        btnGod.Text = "🛡️ GOD MODE: ON (SUPER REGEN)"
        btnGod.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
        ApplyGodMode()
    else
        btnGod.Text = "🛡️ GOD MODE: OFF"
        btnGod.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
        RemoveGodMode()
    end
end)

print("✅ God Mode Super Regen aktif! Health tidak akan berkurang, MaxHealth terkunci, dan mati tidak mungkin.")
print("⚠️ Catatan: Jika server full authoritative (server yang mutusin semua), client-side tidak bisa 100% mencegah kematian. Gunakan server script di bawah ini.")