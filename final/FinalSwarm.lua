-- ============================================
-- SCRIPT GOD MODE 25 LAPIS (FULL TANPA SINGKAT)
-- ============================================
-- ❌ Tidak ada auto farm / follow mob
-- ❌ Tidak ada destroy object / anti-raycast ilegal
-- ❌ Tidak ada auto attack
-- ✅ Hanya God Mode 25 lapis anti mati
-- ✅ Karakter diam di tempat (anti knockback/fall)
-- ✅ Health tidak bisa berkurang
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character, humanoid, rootPart

local isGodMode = false
local godConnections = {}  -- simpan koneksi untuk disconnect
local forceFields = {}     -- simpan forcefield yang dibuat

-- ============================================
-- [FUNGSI APPLY GOD MODE 25 LAPIS]
-- ============================================
local function ApplyGodMode25()
    if not character or not humanoid or not rootPart then return end

    ------------------------------------------------------------
    -- LAPIS 1: MaxHealth tak terbatas
    ------------------------------------------------------------
    pcall(function()
        humanoid.MaxHealth = math.huge
    end)

    ------------------------------------------------------------
    -- LAPIS 2: Health langsung di-set tak terbatas
    ------------------------------------------------------------
    pcall(function()
        humanoid.Health = math.huge
    end)

    ------------------------------------------------------------
    -- LAPIS 3: Matikan state Dead
    ------------------------------------------------------------
    pcall(function()
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    end)

    ------------------------------------------------------------
    -- LAPIS 4: Matikan state FallingDown (ragdoll)
    ------------------------------------------------------------
    pcall(function()
        humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    end)

    ------------------------------------------------------------
    -- LAPIS 5: Matikan state Ragdoll
    ------------------------------------------------------------
    pcall(function()
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    end)

    ------------------------------------------------------------
    -- LAPIS 6: Matikan state Physics (biar tidak terpengaruh fisika)
    ------------------------------------------------------------
    pcall(function()
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
    end)

    ------------------------------------------------------------
    -- LAPIS 7: Jangan hancurkan sambungan saat mati
    ------------------------------------------------------------
    pcall(function()
        humanoid.BreakJointsOnDeath = false
    end)

    ------------------------------------------------------------
    -- LAPIS 8: HealthChanged langsung recover
    ------------------------------------------------------------
    local conn8 = humanoid.HealthChanged:Connect(function(newHealth)
        if isGodMode and newHealth ~= math.huge then
            humanoid.Health = math.huge
        end
    end)
    table.insert(godConnections, conn8)

    ------------------------------------------------------------
    -- LAPIS 9: Property Health berubah langsung recover
    ------------------------------------------------------------
    local conn9 = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        if isGodMode and humanoid.Health ~= math.huge then
            humanoid.Health = math.huge
        end
    end)
    table.insert(godConnections, conn9)

    ------------------------------------------------------------
    -- LAPIS 10: Heartbeat loop (setiap frame)
    ------------------------------------------------------------
    local conn10 = RunService.Heartbeat:Connect(function()
        if isGodMode and humanoid and humanoid.Health ~= math.huge then
            humanoid.Health = math.huge
        end
    end)
    table.insert(godConnections, conn10)

    ------------------------------------------------------------
    -- LAPIS 11: Stepped loop (setiap physics step)
    ------------------------------------------------------------
    local conn11 = RunService.Stepped:Connect(function()
        if isGodMode and humanoid and humanoid.Health ~= math.huge then
            humanoid.Health = math.huge
        end
    end)
    table.insert(godConnections, conn11)

    ------------------------------------------------------------
    -- LAPIS 12: RenderStepped loop (setiap render frame)
    ------------------------------------------------------------
    local conn12 = RunService.RenderStepped:Connect(function()
        if isGodMode and humanoid and humanoid.Health ~= math.huge then
            humanoid.Health = math.huge
        end
    end)
    table.insert(godConnections, conn12)

    ------------------------------------------------------------
    -- LAPIS 13: Died event -> revive instan
    ------------------------------------------------------------
    local conn13 = humanoid.Died:Connect(function()
        if isGodMode then
            task.wait(0.05)
            pcall(function()
                humanoid.Health = math.huge
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
                rootPart.CFrame = rootPart.CFrame + Vector3.new(0, 5, 0)
            end)
        end
    end)
    table.insert(godConnections, conn13)

    ------------------------------------------------------------
    -- LAPIS 14: ForceField pertama
    ------------------------------------------------------------
    local ff1 = Instance.new("ForceField")
    ff1.Name = "GodShield_1"
    ff1.Visible = false
    ff1.Parent = character
    table.insert(forceFields, ff1)

    ------------------------------------------------------------
    -- LAPIS 15: ForceField kedua
    ------------------------------------------------------------
    local ff2 = Instance.new("ForceField")
    ff2.Name = "GodShield_2"
    ff2.Visible = false
    ff2.Parent = character
    table.insert(forceFields, ff2)

    ------------------------------------------------------------
    -- LAPIS 16: ForceField ketiga
    ------------------------------------------------------------
    local ff3 = Instance.new("ForceField")
    ff3.Name = "GodShield_3"
    ff3.Visible = false
    ff3.Parent = character
    table.insert(forceFields, ff3)

    ------------------------------------------------------------
    -- LAPIS 17: ForceField keempat
    ------------------------------------------------------------
    local ff4 = Instance.new("ForceField")
    ff4.Name = "GodShield_4"
    ff4.Visible = false
    ff4.Parent = character
    table.insert(forceFields, ff4)

    ------------------------------------------------------------
    -- LAPIS 18: ForceField kelima
    ------------------------------------------------------------
    local ff5 = Instance.new("ForceField")
    ff5.Name = "GodShield_5"
    ff5.Visible = false
    ff5.Parent = character
    table.insert(forceFields, ff5)

    ------------------------------------------------------------
    -- LAPIS 19: Anchor semua part (anti knockback & jatuh)
    ------------------------------------------------------------
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                part.Anchored = true
            end)
        end
    end

    ------------------------------------------------------------
    -- LAPIS 20: Set CanCollide false semua part (supaya serangan fisik menembus)
    ------------------------------------------------------------
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                part.CanCollide = false
            end)
        end
    end

    ------------------------------------------------------------
    -- LAPIS 21: Sembunyikan tampilan health & nama
    ------------------------------------------------------------
    pcall(function()
        humanoid.HealthDisplayDistance = 0
        humanoid.NameDisplayDistance = 0
    end)

    ------------------------------------------------------------
    -- LAPIS 22: Anti void (teleport ke atas kalau jatuh ke bawah)
    ------------------------------------------------------------
    local minY = Workspace.FallenPartsDestroyHeight or -500
    if rootPart.Position.Y < minY + 10 then
        rootPart.CFrame = CFrame.new(rootPart.Position.X, minY + 50, rootPart.Position.Z)
    end

    ------------------------------------------------------------
    -- LAPIS 23: Set health tak terbatas ulang via task.spawn loop
    ------------------------------------------------------------
    task.spawn(function()
        while isGodMode and humanoid and humanoid.Parent do
            pcall(function()
                humanoid.Health = math.huge
            end)
            task.wait(0.01)
        end
    end)

    ------------------------------------------------------------
    -- LAPIS 24: Set MaxHealth tak terbatas ulang via task.spawn loop
    ------------------------------------------------------------
    task.spawn(function()
        while isGodMode and humanoid and humanoid.Parent do
            pcall(function()
                humanoid.MaxHealth = math.huge
            end)
            task.wait(0.1)
        end
    end)

    ------------------------------------------------------------
    -- LAPIS 25: Set ulang state enabled false setiap saat
    ------------------------------------------------------------
    task.spawn(function()
        while isGodMode and humanoid and humanoid.Parent do
            pcall(function()
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
            end)
            task.wait(0.5)
        end
    end)
end

-- ============================================
-- [FUNGSI REMOVE GOD MODE 25 LAPIS]
-- ============================================
local function RemoveGodMode25()
    -- Matikan koneksi
    for _, conn in ipairs(godConnections) do
        pcall(function() conn:Disconnect() end)
    end
    godConnections = {}

    -- Hapus semua forcefield
    for _, ff in ipairs(forceFields) do
        pcall(function() ff:Destroy() end)
    end
    forceFields = {}

    -- Kembalikan state & properti
    pcall(function()
        if humanoid then
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
            humanoid.BreakJointsOnDeath = true
            humanoid.MaxHealth = 100  -- ganti sesuai default game
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

    -- Kalau god mode sedang aktif, reapply
    if isGodMode then
        ApplyGodMode25()
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
        btnGod.Text = "🛡️ GOD MODE: ON (25 LAPIS)"
        btnGod.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
        ApplyGodMode25()
    else
        btnGod.Text = "🛡️ GOD MODE: OFF"
        btnGod.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
        RemoveGodMode25()
    end
end)

print("✅ God Mode 25 lapis aktif! Karakter tidak bisa mati, health terkunci tak terbatas.")
print("⚠️ Catatan: Jika server full authoritative, masih ada kemungkinan mati. Gunakan server script untuk hasil 100%.")