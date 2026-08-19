-- ============================================
-- SCRIPT AUTO FARM + AUTO HINDAR + AUTO ABOVE
-- ============================================
-- Fitur:
--   - Auto Farm : cari musuh terdekat, dekati, serang
--   - Auto Hindar: jauhi musuh/proyektil (Mode Aman/Cepat)
--   - Auto Above: melayang di atas musuh
--   - UI Modern dengan UICorner, UIStroke, Gradasi
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character, humanoid, rootPart

-- Status fitur
local isFarmActive = false
local isDodgeActive = false
local isAboveActive = false
local dodgeMode = "safe"  -- "safe" atau "teleport"

-- Cooldown
local lastAttackTime = 0
local lastDodgeTime = 0
local attackCooldown = 0.2
local dodgeCooldown = 0.3

-- Konfigurasi
local FARM_RANGE = 50
local ATTACK_RANGE = 15
local DODGE_DETECT_RANGE = 12
local PROYEKTIL_RANGE = 15
local DODGE_DISTANCE = 10
local DODGE_HEIGHT = 8
local ABOVE_HEIGHT = 15

-- ============================================
-- [SETUP KARAKTER]
-- ============================================
local function onCharacterAdded(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
end

if player.Character then
    onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

-- ============================================
-- [CARI MUSUH TERDEKAT]
-- ============================================
local function getNearestMob(position, maxDist)
    local closestDist = maxDist or math.huge
    local closestMob = nil
    local mobFolders = {"Monsters", "Enemies", "Mobs", "NPCs", "Zombies"}

    for _, folderName in ipairs(mobFolders) do
        local folder = Workspace:FindFirstChild(folderName)
        if folder then
            for _, model in ipairs(folder:GetDescendants()) do
                if model:IsA("Model") and model:FindFirstChild("Humanoid") and model:FindFirstChild("HumanoidRootPart") then
                    local hum = model.Humanoid
                    if hum.Health > 0 and not Players:GetPlayerFromCharacter(model) then
                        local dist = (position - model.HumanoidRootPart.Position).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            closestMob = model
                        end
                    end
                end
            end
        end
    end

    if not closestMob then
        for _, model in ipairs(Workspace:GetDescendants()) do
            if model:IsA("Model") and model:FindFirstChild("Humanoid") and model:FindFirstChild("HumanoidRootPart") then
                local hum = model.Humanoid
                if hum.Health > 0 and not Players:GetPlayerFromCharacter(model) then
                    local dist = (position - model.HumanoidRootPart.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestMob = model
                    end
                end
            end
        end
    end

    return closestMob, closestDist
end

-- ============================================
-- [CARI REMOTE SERANG]
-- ============================================
local function findAttackRemote()
    local names = {"AttackEvent", "Attack", "DamageEvent", "HitEvent", "Hit", "DealDamage"}
    for _, n in ipairs(names) do
        local r = ReplicatedStorage:FindFirstChild(n)
        if r then return r end
    end
    return nil
end
local attackRemote = findAttackRemote()

-- ============================================
-- [FUNGSI SERANG]
-- ============================================
local function attackMob(mob)
    if not mob then return end
    if attackRemote then
        pcall(function()
            attackRemote:FireServer(mob)
        end)
    end
    pcall(function()
        local mouse = player:GetMouse()
        if mouse and mob:FindFirstChild("HumanoidRootPart") then
            mouse.Target = mob.HumanoidRootPart
        end
    end)
end

-- ============================================
-- [FUNGSI HINDAR MODE TELEPORT]
-- ============================================
local function dodgeTeleport(dangerPos)
    if not rootPart then return end
    if tick() - lastDodgeTime < dodgeCooldown then return end
    lastDodgeTime = tick()

    local awayDir = (rootPart.Position - dangerPos).Unit
    if awayDir.Magnitude < 0.1 then
        awayDir = Vector3.new(math.random(-1, 1), 0, math.random(-1, 1)).Unit
    end
    local angle = math.rad(math.random(-30, 30))
    local cosA = math.cos(angle)
    local sinA = math.sin(angle)
    awayDir = Vector3.new(awayDir.X * cosA - awayDir.Z * sinA, 0, awayDir.X * sinA + awayDir.Z * cosA).Unit

    local targetPos = rootPart.Position + awayDir * DODGE_DISTANCE + Vector3.new(0, DODGE_HEIGHT, 0)
    pcall(function()
        rootPart.CFrame = CFrame.new(targetPos)
    end)
    pcall(function()
        humanoid:ChangeState(Enum.HumanoidStateType.Flying)
    end)
end

-- ============================================
-- [FUNGSI HINDAR MODE AMAN (MOVE + JUMP)]
-- ============================================
local function dodgeSafe(dangerPos)
    if not humanoid or not rootPart then return end
    if tick() - lastDodgeTime < dodgeCooldown then return end
    lastDodgeTime = tick()

    local awayDir = (rootPart.Position - dangerPos).Unit
    if awayDir.Magnitude < 0.1 then
        awayDir = Vector3.new(math.random(-1, 1), 0, math.random(-1, 1)).Unit
    end

    humanoid:Move(awayDir, false)
    humanoid.Jump = true

    task.delay(0.2, function()
        pcall(function()
            humanoid:Move(Vector3.zero, false)
            humanoid.Jump = false
        end)
    end)
end

-- ============================================
-- [DETEKSI PROYEKTIL]
-- ============================================
local function getDangerousProjectile(myPos)
    local closestProj = nil
    local closestDist = PROYEKTIL_RANGE

    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and not part:IsDescendantOf(character) then
            local velocity = part.AssemblyLinearVelocity
            if velocity and velocity.Magnitude > 20 then
                local dist = (myPos - part.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestProj = part
                end
            end
        end
    end

    return closestProj
end

-- ============================================
-- [LOOP UTAMA]
-- ============================================
RunService.Heartbeat:Connect(function()
    if not character or not humanoid or not rootPart then return end

    local myPos = rootPart.Position

    -- AUTO ABOVE
    if isAboveActive then
        local mob = getNearestMob(myPos, FARM_RANGE)
        if mob and mob:FindFirstChild("HumanoidRootPart") then
            local targetPos = mob.HumanoidRootPart.Position + Vector3.new(0, ABOVE_HEIGHT, 0)
            pcall(function()
                rootPart.CFrame = CFrame.new(targetPos)
                humanoid:ChangeState(Enum.HumanoidStateType.Flying)
            end)
        end
    end

    -- AUTO FARM
    if isFarmActive then
        local mob, dist = getNearestMob(myPos, FARM_RANGE)
        if mob and mob:FindFirstChild("HumanoidRootPart") then
            humanoid:MoveTo(mob.HumanoidRootPart.Position)
            if dist <= ATTACK_RANGE and tick() - lastAttackTime >= attackCooldown then
                attackMob(mob)
                lastAttackTime = tick()
            end
        end
    end

    -- AUTO HINDAR
    if isDodgeActive then
        local dangerMob, mobDist = getNearestMob(myPos, DODGE_DETECT_RANGE)
        if dangerMob then
            if dodgeMode == "teleport" then
                dodgeTeleport(dangerMob.HumanoidRootPart.Position)
            else
                dodgeSafe(dangerMob.HumanoidRootPart.Position)
            end
        else
            local proj = getDangerousProjectile(myPos)
            if proj then
                if dodgeMode == "teleport" then
                    dodgeTeleport(proj.Position)
                else
                    dodgeSafe(proj.Position)
                end
            end
        end
    end
end)

-- ============================================
-- [UI MODERN]
-- ============================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SwarmGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Frame utama
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 280, 0, 240)
mainFrame.Position = UDim2.new(0.5, -140, 0.5, -120)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- UICorner untuk frame utama
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- UIStroke untuk frame utama
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(80, 80, 120)
mainStroke.Thickness = 1
mainStroke.Transparency = 0.3
mainStroke.Parent = mainFrame

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 40)
header.Position = UDim2.new(0, 0, 0, 0)
header.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
header.BorderSizePixel = 0
header.Parent = mainFrame

-- Corner header (atas saja)
local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = header

-- Gradient header
local headerGradient = Instance.new("UIGradient")
headerGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 45, 80)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 45))
})
headerGradient.Rotation = 90
headerGradient.Parent = header

-- Judul
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "SWARM ULTIMATE"
titleLabel.TextColor3 = Color3.fromRGB(220, 220, 255)
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 16
titleLabel.Parent = header

-- Tombol Close
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -34, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.BackgroundTransparency = 0.1
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 14
closeBtn.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Fungsi pembuat tombol modern
local function createButton(parent, text, yPos, baseColor)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -24, 0, 40)
    btn.Position = UDim2.new(0, 12, 0, yPos)
    btn.BackgroundColor3 = baseColor or Color3.fromRGB(60, 60, 80)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 13
    btn.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(120, 120, 160)
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = btn

    -- Hover effect
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(80, 80, 110)
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = baseColor or Color3.fromRGB(60, 60, 80)
    end)

    return btn
end

-- Tombol-tombol fitur
local btnFarm = createButton(mainFrame, "AUTO FARM: OFF", 50, Color3.fromRGB(50, 50, 70))
local btnDodge = createButton(mainFrame, "AUTO HINDAR: OFF", 96, Color3.fromRGB(50, 50, 70))
local btnAbove = createButton(mainFrame, "AUTO ABOVE: OFF", 142, Color3.fromRGB(50, 50, 70))
local btnMode = createButton(mainFrame, "MODE: AMAN (Move+Jump)", 188, Color3.fromRGB(60, 60, 100))

-- Label status
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -24, 0, 24)
statusLabel.Position = UDim2.new(0, 12, 0, 232)
statusLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
statusLabel.BorderSizePixel = 0
statusLabel.Text = "STATUS: STANDBY"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextSize = 11
statusLabel.Parent = mainFrame

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 6)
statusCorner.Parent = statusLabel

local statusStroke = Instance.new("UIStroke")
statusStroke.Color = Color3.fromRGB(100, 100, 140)
statusStroke.Thickness = 1
statusStroke.Transparency = 0.7
statusStroke.Parent = statusLabel

-- ============================================
-- [EVENT TOMBOL]
-- ============================================
btnFarm.MouseButton1Click:Connect(function()
    isFarmActive = not isFarmActive
    btnFarm.Text = isFarmActive and "AUTO FARM: ON" or "AUTO FARM: OFF"
    btnFarm.BackgroundColor3 = isFarmActive and Color3.fromRGB(40, 130, 60) or Color3.fromRGB(50, 50, 70)
    statusLabel.Text = isFarmActive and "STATUS: FARM AKTIF" or "STATUS: STANDBY"
end)

btnDodge.MouseButton1Click:Connect(function()
    isDodgeActive = not isDodgeActive
    btnDodge.Text = isDodgeActive and "AUTO HINDAR: ON" or "AUTO HINDAR: OFF"
    btnDodge.BackgroundColor3 = isDodgeActive and Color3.fromRGB(40, 130, 60) or Color3.fromRGB(50, 50, 70)
    if isDodgeActive then
        statusLabel.Text = "STATUS: HINDAR " .. string.upper(dodgeMode)
    else
        statusLabel.Text = "STATUS: STANDBY"
    end
end)

btnAbove.MouseButton1Click:Connect(function()
    isAboveActive = not isAboveActive
    btnAbove.Text = isAboveActive and "AUTO ABOVE: ON" or "AUTO ABOVE: OFF"
    btnAbove.BackgroundColor3 = isAboveActive and Color3.fromRGB(40, 130, 60) or Color3.fromRGB(50, 50, 70)
    statusLabel.Text = isAboveActive and "STATUS: ABOVE AKTIF" or "STATUS: STANDBY"
end)

btnMode.MouseButton1Click:Connect(function()
    if dodgeMode == "safe" then
        dodgeMode = "teleport"
        btnMode.Text = "MODE: CEPAT (TELEPORT)"
        btnMode.BackgroundColor3 = Color3.fromRGB(140, 70, 40)
    else
        dodgeMode = "safe"
        btnMode.Text = "MODE: AMAN (Move+Jump)"
        btnMode.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
    end
    if isDodgeActive then
        statusLabel.Text = "STATUS: HINDAR " .. string.upper(dodgeMode)
    end
end)

print("UI modern terpasang. Script siap digunakan.")