-- ============================================================
-- 🛡️ AUTO DODGE ULTIMATE — HINDARI SEMUA OBJEK
-- ============================================================
-- ✅ Hindari semua objek bergerak (proyektil, musuh, player, kendaraan)
-- ✅ Deteksi proyektil berdasarkan kecepatan
-- ✅ Hindari musuh jarak dekat
-- ✅ Opsi toggle: Hindari Player (ON/OFF)
-- ✅ Lompat + dash + zig-zag
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local char, hum, root

local dodgeOn = false
local avoidPlayers = true   -- ← toggle ini di GUI
local lastDodgeTime = 0
local dodgeDir = 1
local isDodging = false
local bodyVelocity = nil

-- ============================================================
-- ⚙️ KONFIGURASI
-- ============================================================
local CONFIG = {
    DodgeMode = "Defensive",  -- "Defensive" / "Aggressive"
    ScanRadius = 50,
    ProjSpeedThreshold = 12,
    ProjPredictionTime = 0.35,
    DangerDistProj = 20,
    DangerDistEnemy = 9,
    DangerDistPlayer = 6,     -- Jarak aman dari player lain
    DodgeCooldown = 0.12,
    DashDistance = 5,
    UseBodyVelocity = true,
    ShowDebug = false,
}

-- ============================================================
-- 🔄 UPDATE KARAKTER
-- ============================================================
local function updateChar()
    char = player.Character
    if char then
        hum = char:FindFirstChildOfClass("Humanoid")
        root = char:FindFirstChild("HumanoidRootPart")
        if CONFIG.UseBodyVelocity and root then
            bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.MaxForce = Vector3.new(100000, 0, 100000)
            bodyVelocity.Velocity = Vector3.zero
            bodyVelocity.Parent = root
        end
    end
end
updateChar()
player.CharacterAdded:Connect(updateChar)

-- ============================================================
-- 🔍 CEK APAKAH OBJEK ADALAH MUSUH / PLAYER / OBJEK BERBAHAYA
-- ============================================================
local function isThreat(obj)
    if not obj or not obj:IsA("Model") then return false end
    
    -- Cek apakah objek adalah player
    local isPlayer = Players:GetPlayerFromCharacter(obj)
    if isPlayer then
        -- Jangan hindari diri sendiri
        if isPlayer == player then return false end
        return avoidPlayers  -- True jika toggle ON
    end

    -- Cek apakah objek memiliki Humanoid (musuh)
    local h = obj:FindFirstChildOfClass("Humanoid")
    if h and h.Health > 0 then
        return true
    end

    return false
end

-- ============================================================
-- 🎯 DETEKSI PROYEKTIL (SEMUA PARTIKEL BERKECEPATAN TINGGI)
-- ============================================================
local function getProjectileThreats()
    if not root then return {} end
    local myPos = root.Position
    local threats = {}

    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and part.Parent ~= char then
            local vel = part.AssemblyLinearVelocity
            if vel and vel.Magnitude > CONFIG.ProjSpeedThreshold then
                local dist = (myPos - part.Position).Magnitude
                if dist < CONFIG.ScanRadius then
                    local futurePos = part.Position + vel * CONFIG.ProjPredictionTime
                    local distToFuture = (myPos - futurePos).Magnitude
                    local dir = (part.Position - myPos).Unit
                    local dot = dir:Dot(vel.Unit)
                    if dot < 0 and distToFuture < CONFIG.DangerDistProj then
                        table.insert(threats, {
                            Part = part,
                            Position = part.Position,
                            FuturePos = futurePos,
                            Distance = dist,
                            Velocity = vel,
                            TimeToImpact = dist / vel.Magnitude
                        })
                    end
                end
            end
        end
    end

    table.sort(threats, function(a, b)
        return (a.TimeToImpact or 999) < (b.TimeToImpact or 999)
    end)

    return threats
end

-- ============================================================
-- 👾 DETEKSI OBJEK BERGERAK (MUSUH, PLAYER, KENDARAAN)
-- ============================================================
local function getMovingThreats()
    if not root then return {} end
    local myPos = root.Position
    local threats = {}

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= char then
            -- Cek apakah objek adalah player atau musuh
            if isThreat(obj) then
                local hrp = obj:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local dist = (myPos - hrp.Position).Magnitude
                    local isPlayer = Players:GetPlayerFromCharacter(obj)
                    local dangerDist = isPlayer and CONFIG.DangerDistPlayer or CONFIG.DangerDistEnemy
                    if dist < dangerDist then
                        table.insert(threats, {
                            Object = obj,
                            Position = hrp.Position,
                            Distance = dist,
                            Type = isPlayer and "Player" or "Enemy"
                        })
                    end
                end
            end
        end
    end

    -- Deteksi AOE (ledakan, area damage)
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and (part.Name:lower():find("explosion") or part.Name:lower():find("aoe") or part.Name:lower():find("fire")) then
            local dist = (myPos - part.Position).Magnitude
            if dist < 12 then
                table.insert(threats, {
                    Object = part,
                    Position = part.Position,
                    Distance = dist,
                    Type = "AOE"
                })
            end
        end
    end

    return threats
end

-- ============================================================
-- 🚀 EKSEKUSI DODGE
-- ============================================================
local function performDodge(avoidPos, threatType)
    if not hum or not root then return end
    if isDodging then return end
    if tick() - lastDodgeTime < CONFIG.DodgeCooldown then return end

    isDodging = true
    local myPos = root.Position
    local dirAway = (myPos - avoidPos).Unit
    if dirAway.Magnitude < 0.1 then dirAway = Vector3.new(0, 0, 1) end

    local right = Vector3.new(0, 1, 0):Cross(dirAway).Unit
    if right.Magnitude < 0.1 then right = Vector3.new(1, 0, 0) end

    dodgeDir = dodgeDir * -1
    local sideDir = right * dodgeDir

    local moveDir
    if CONFIG.DodgeMode == "Defensive" then
        moveDir = (dirAway * -0.4 + sideDir * 0.6).Unit
    else
        moveDir = (sideDir * 0.8 + dirAway * 0.2).Unit
    end

    hum.Jump = true
    task.wait(0.05)
    hum.Jump = false

    local dashTarget = myPos + moveDir * CONFIG.DashDistance
    hum:MoveTo(dashTarget)

    if CONFIG.UseBodyVelocity and bodyVelocity then
        bodyVelocity.Velocity = moveDir * 35
        task.spawn(function()
            task.wait(0.2)
            if bodyVelocity then bodyVelocity.Velocity = Vector3.zero end
        end)
    end

    task.spawn(function()
        task.wait(0.25)
        isDodging = false
        if hum then hum:Move(Vector3.zero, false) end
    end)

    lastDodgeTime = tick()
    if CONFIG.ShowDebug then
        print("🔄 Dodge: " .. threatType)
    end
end

-- ============================================================
-- 🧠 LOOP UTAMA
-- ============================================================
local function processThreats()
    if not dodgeOn then return end
    if not root or not hum then return end

    -- 1. Proyektil (prioritas tertinggi)
    local projThreats = getProjectileThreats()
    if #projThreats > 0 then
        local top = projThreats[1]
        if top.Distance < CONFIG.DangerDistProj then
            performDodge(top.Position, "Projectile")
            return
        end
    end

    -- 2. Objek bergerak (musuh, player, AOE)
    local threats = getMovingThreats()
    for _, t in ipairs(threats) do
        if t.Distance < (t.Type == "Player" and CONFIG.DangerDistPlayer or CONFIG.DangerDistEnemy) then
            performDodge(t.Position, t.Type)
            return
        end
    end
end

RunService.Heartbeat:Connect(processThreats)

-- ============================================================
-- 🖥️ GUI — dengan tombol toggle "Hindari Player"
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 240, 0, 150)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
frame.BorderSizePixel = 0
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 20)
title.BackgroundTransparency = 1
title.Text = "🛡️ DODGE ULTIMATE"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 14
title.Parent = frame

-- Tombol Dodge
local btnDodge = Instance.new("TextButton")
btnDodge.Size = UDim2.new(1, -20, 0, 30)
btnDodge.Position = UDim2.new(0, 10, 0, 25)
btnDodge.Text = "DODGE: OFF"
btnDodge.TextColor3 = Color3.fromRGB(255,255,255)
btnDodge.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
btnDodge.BorderSizePixel = 0
btnDodge.Parent = frame

-- Tombol Mode
local btnMode = Instance.new("TextButton")
btnMode.Size = UDim2.new(1, -20, 0, 30)
btnMode.Position = UDim2.new(0, 10, 0, 60)
btnMode.Text = "MODE: Defensive"
btnMode.TextColor3 = Color3.fromRGB(255,255,255)
btnMode.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
btnMode.BorderSizePixel = 0
btnMode.Parent = frame

-- Tombol Hindari Player (toggle)
local btnPlayer = Instance.new("TextButton")
btnPlayer.Size = UDim2.new(1, -20, 0, 30)
btnPlayer.Position = UDim2.new(0, 10, 0, 95)
btnPlayer.Text = "HINDARI PLAYER: ON"
btnPlayer.TextColor3 = Color3.fromRGB(255,255,255)
btnPlayer.BackgroundColor3 = Color3.fromRGB(40, 120, 60)
btnPlayer.BorderSizePixel = 0
btnPlayer.Parent = frame

-- Event tombol
btnDodge.MouseButton1Click:Connect(function()
    dodgeOn = not dodgeOn
    btnDodge.Text = dodgeOn and "DODGE: ON" or "DODGE: OFF"
    btnDodge.BackgroundColor3 = dodgeOn and Color3.fromRGB(40, 120, 60) or Color3.fromRGB(50, 50, 70)
    print(dodgeOn and "✅ Dodge aktif!" or "⏹ Dodge mati.")
end)

btnMode.MouseButton1Click:Connect(function()
    CONFIG.DodgeMode = (CONFIG.DodgeMode == "Defensive") and "Aggressive" or "Defensive"
    btnMode.Text = "MODE: " .. CONFIG.DodgeMode
    btnMode.BackgroundColor3 = (CONFIG.DodgeMode == "Defensive") and Color3.fromRGB(50, 50, 70) or Color3.fromRGB(70, 50, 30)
    print("🔄 Mode: " .. CONFIG.DodgeMode)
end)

btnPlayer.MouseButton1Click:Connect(function()
    avoidPlayers = not avoidPlayers
    btnPlayer.Text = "HINDARI PLAYER: " .. (avoidPlayers and "ON" or "OFF")
    btnPlayer.BackgroundColor3 = avoidPlayers and Color3.fromRGB(40, 120, 60) or Color3.fromRGB(50, 50, 70)
    print(avoidPlayers and "✅ Akan menghindari player lain" or "⏹ Player lain diabaikan")
end)

print("✅ Script siap! Nyalakan DODGE, atur toggle 'Hindari Player' sesuai keinginan.")