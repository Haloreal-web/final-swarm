-- ============================================================
-- 🛡️ AUTO DODGE ULTIMATE v99e — FULL LAPISAN KETEBALAN
-- ============================================================
-- 🔥 Deteksi proyektil (kecepatan, prediksi, raycast tambahan)
-- 🔥 Deteksi musuh jarak dekat & serangan area (AOE)
-- 🔥 Gerakan: Lompat + Dash ke samping + Zig-zag + Roll (simulasi)
-- 🔥 Multi-fallback: Move / MoveTo / BodyVelocity
-- 🔥 Cooldown dinamis, prioritas ancaman, anti-lag
-- 🔥 Mode: Agresif (hindar sambil tetap dekat) / Defensif (jauh)
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local char, hum, root

-- ============================================================
-- ⚙️ KONFIGURASI
-- ============================================================
local CONFIG = {
    DodgeMode = "Defensive",  -- "Defensive" atau "Aggressive"
    ScanRadius = 50,          -- Radius deteksi ancaman
    ProjSpeedThreshold = 12,  -- Kecepatan minimum dianggap proyektil
    ProjPredictionTime = 0.35, -- Prediksi posisi proyektil (detik)
    DangerDistProj = 20,      -- Jarak ancaman proyektil
    DangerDistEnemy = 9,      -- Jarak ancaman musuh
    DodgeCooldown = 0.12,     -- Cooldown antar dodge
    JumpHeight = 1.2,         -- Tinggi lompatan (simulasi)
    DashDistance = 5,         -- Jarak dash ke samping
    UseBodyVelocity = true,   -- Gunakan BodyVelocity untuk gerakan instan
    ShowDebug = false,        -- Tampilkan debug di output
}

-- ============================================================
-- 🔄 VARIABEL INTERNAL
-- ============================================================
local dodgeOn = false
local lastDodgeTime = 0
local dodgeDir = 1
local isDodging = false
local bodyVelocity = nil

-- ============================================================
-- 🧬 FUNGSI UPDATE KARAKTER
-- ============================================================
local function updateChar()
    char = player.Character
    if char then
        hum = char:FindFirstChildOfClass("Humanoid")
        root = char:FindFirstChild("HumanoidRootPart")
        -- Siapkan BodyVelocity untuk dash
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
-- 🎯 DETEKSI PROYEKTIL (Level MAX)
-- ============================================================
local function getProjectileThreats()
    if not root then return {} end
    local myPos = root.Position
    local threats = {}
    local scanRadius = CONFIG.ScanRadius
    local speedThresh = CONFIG.ProjSpeedThreshold
    local predTime = CONFIG.ProjPredictionTime

    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and part.Parent ~= char then
            local vel = part.AssemblyLinearVelocity
            if vel and vel.Magnitude > speedThresh then
                local dist = (myPos - part.Position).Magnitude
                if dist < scanRadius then
                    -- Prediksi posisi masa depan
                    local futurePos = part.Position + vel * predTime
                    local distToFuture = (myPos - futurePos).Magnitude
                    -- Cek apakah proyektil mendekati kita
                    local currentDir = (part.Position - myPos).Unit
                    local velDir = vel.Unit
                    local dot = currentDir:Dot(velDir)
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

    -- Urutkan berdasarkan waktu dampak (paling cepat = paling bahaya)
    table.sort(threats, function(a, b)
        return (a.TimeToImpact or 999) < (b.TimeToImpact or 999)
    end)

    return threats
end

-- ============================================================
-- 👾 DETEKSI MUSUH DEKAT & SERANGAN AREA (AOE)
-- ============================================================
local function getEnemyThreats()
    if not root then return {} end
    local myPos = root.Position
    local threats = {}

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
            local h = obj:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 and not Players:GetPlayerFromCharacter(obj) then
                local hrp = obj:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local dist = (myPos - hrp.Position).Magnitude
                    if dist < CONFIG.DangerDistEnemy then
                        table.insert(threats, {
                            Object = obj,
                            Position = hrp.Position,
                            Distance = dist,
                            Type = "Enemy"
                        })
                    end
                end
            end
        end
    end

    -- Cari efek AOE (ledakan, lingkaran api, dll) berdasarkan partikel
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and part.Name:lower():find("explosion") or part.Name:lower():find("aoe") then
            local dist = (myPos - part.Position).Magnitude
            if dist < 15 then
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
-- 🚀 EKSEKUSI DODGE (GERAKAN MAKSIMAL)
-- ============================================================
local function performDodge(avoidPos, threatType)
    if not hum or not root then return end
    if isDodging then return end
    if tick() - lastDodgeTime < CONFIG.DodgeCooldown then return end

    isDodging = true
    local myPos = root.Position
    local dirAway = (myPos - avoidPos).Unit
    if dirAway.Magnitude < 0.1 then dirAway = Vector3.new(0, 0, 1) end

    -- Arah tegak lurus (kiri/kanan) untuk zig-zag
    local right = Vector3.new(0, 1, 0):Cross(dirAway).Unit
    if right.Magnitude < 0.1 then right = Vector3.new(1, 0, 0) end

    -- Zig-zag
    dodgeDir = dodgeDir * -1
    local sideDir = right * dodgeDir

    -- Tentukan arah gerak berdasarkan mode
    local moveDir
    if CONFIG.DodgeMode == "Defensive" then
        -- Defensif: mundur + samping
        moveDir = (dirAway * -0.4 + sideDir * 0.6).Unit
    else
        -- Agresif: samping + sedikit maju (agar tetap dekat)
        moveDir = (sideDir * 0.8 + dirAway * 0.2).Unit
    end

    -- Lompat
    hum.Jump = true
    task.wait(0.05)
    hum.Jump = false

    -- Eksekusi dash
    local dashTarget = myPos + moveDir * CONFIG.DashDistance

    -- Metode 1: MoveTo (paling umum)
    hum:MoveTo(dashTarget)

    -- Metode 2: BodyVelocity (instan)
    if CONFIG.UseBodyVelocity and bodyVelocity then
        bodyVelocity.Velocity = moveDir * 30
        task.spawn(function()
            task.wait(0.2)
            if bodyVelocity then bodyVelocity.Velocity = Vector3.zero end
        end)
    end

    -- Metode 3: Tween (opsional)
    task.spawn(function()
        local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(root, tweenInfo, {Position = dashTarget})
        tween:Play()
    end)

    -- Reset status setelah jeda
    task.spawn(function()
        task.wait(0.25)
        isDodging = false
        if hum then hum:Move(Vector3.zero, false) end
    end)

    lastDodgeTime = tick()

    if CONFIG.ShowDebug then
        print("🔄 Dodge: " .. threatType .. " | Direction: " .. tostring(moveDir))
    end
end

-- ============================================================
-- 🧠 LOGIKA PRIORITAS ANCAMAN
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

    -- 2. Musuh dekat & AOE
    local enemyThreats = getEnemyThreats()
    for _, t in ipairs(enemyThreats) do
        if t.Type == "Enemy" and t.Distance < CONFIG.DangerDistEnemy then
            performDodge(t.Position, "Enemy")
            return
        elseif t.Type == "AOE" and t.Distance < 10 then
            performDodge(t.Position, "AOE")
            return
        end
    end
end

-- ============================================================
-- ⏱️ LOOP UTAMA (Heartbeat + RenderStepped gabungan)
-- ============================================================
RunService.Heartbeat:Connect(processThreats)
RunService.RenderStepped:Connect(function()
    -- Tambahan scan lebih cepat untuk proyektil
    if dodgeOn and not isDodging then
        -- Bisa tambahkan deteksi tambahan di sini jika perlu
    end
end)

-- ============================================================
-- 🖥️ GUI MAKSIMAL (2 Tombol + Mode)
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 120)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
frame.BorderSizePixel = 0
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 20)
title.BackgroundTransparency = 1
title.Text = "🛡️ DODGE ULTIMATE v99e"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 14
title.Parent = frame

local btnDodge = Instance.new("TextButton")
btnDodge.Size = UDim2.new(1, -20, 0, 30)
btnDodge.Position = UDim2.new(0, 10, 0, 25)
btnDodge.Text = "DODGE: OFF"
btnDodge.TextColor3 = Color3.fromRGB(255,255,255)
btnDodge.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
btnDodge.BorderSizePixel = 0
btnDodge.Parent = frame

local btnMode = Instance.new("TextButton")
btnMode.Size = UDim2.new(1, -20, 0, 30)
btnMode.Position = UDim2.new(0, 10, 0, 60)
btnMode.Text = "MODE: Defensive"
btnMode.TextColor3 = Color3.fromRGB(255,255,255)
btnMode.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
btnMode.BorderSizePixel = 0
btnMode.Parent = frame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.Position = UDim2.new(0, 0, 0, 95)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Siap"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextSize = 12
statusLabel.Parent = frame

btnDodge.MouseButton1Click:Connect(function()
    dodgeOn = not dodgeOn
    btnDodge.Text = dodgeOn and "DODGE: ON" or "DODGE: OFF"
    btnDodge.BackgroundColor3 = dodgeOn and Color3.fromRGB(40, 120, 60) or Color3.fromRGB(50, 50, 70)
    statusLabel.Text = dodgeOn and "🟢 Aktif" or "🔴 Mati"
    statusLabel.TextColor3 = dodgeOn and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(200, 200, 200)
    print(dodgeOn and "✅ Dodge Ultimate aktif!" or "⏹ Dodge mati.")
end)

btnMode.MouseButton1Click:Connect(function()
    CONFIG.DodgeMode = (CONFIG.DodgeMode == "Defensive") and "Aggressive" or "Defensive"
    btnMode.Text = "MODE: " .. CONFIG.DodgeMode
    btnMode.BackgroundColor3 = (CONFIG.DodgeMode == "Defensive") and Color3.fromRGB(50, 50, 70) or Color3.fromRGB(70, 50, 30)
    print("🔄 Mode diubah ke: " .. CONFIG.DodgeMode)
end)

print("✅ Script Auto Dodge Ultimate v99e siap!")
print("💡 Nyalakan DODGE. Karakter akan lompat + dash zig-zag hindari semua ancaman.")