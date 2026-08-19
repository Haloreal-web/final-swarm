-- ============================================================
-- 🤝 AUTO FOLLOW PLAYER — NEMPEL BANGET (FIXED v2)
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Pastikan LocalPlayer sudah ada (script bisa jalan terlalu awal)
local player = Players.LocalPlayer or Players.PlayerAdded:Wait()

local char, hum, root
local targetChar, targetHum, targetRoot

local followOn = false
local followDistance = 3 -- jarak offset di belakang target (stud)

local targetPlayer = nil
local targetList = {}
local targetIndex = 0

-- BUG FIX: cek Parent DAN Health, supaya karakter yang sudah mati
-- (tapi belum di-destroy/parent belum nil) tidak dianggap "alive".
local function isAlive(obj)
    if not obj or obj.Parent == nil then
        return false
    end
    if obj:IsA("Humanoid") then
        return obj.Health > 0
    end
    return true
end

-- BUG FIX: HumanoidRootPart & Humanoid belum tentu langsung ada
-- saat CharacterAdded fire (masih proses loading). Pakai WaitForChild
-- dengan timeout supaya tidak dapat nil di frame pertama.
local function updateSelf(newChar)
    char = newChar or player.Character
    if not char then
        hum, root = nil, nil
        return
    end

    hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
    root = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 5)

    if not isAlive(char) then
        char, hum, root = nil, nil, nil
    end
end

local function updateTarget()
    targetChar, targetHum, targetRoot = nil, nil, nil
    if not targetPlayer then return end

    local plr = Players:FindFirstChild(targetPlayer)
    if not plr then
        -- BUG FIX: target sudah leave game -> reset supaya UI tidak
        -- terus2an menampilkan nama player yang sudah tidak ada
        targetPlayer = nil
        return
    end

    if plr and isAlive(plr.Character) then
        targetChar = plr.Character
        targetHum = targetChar:FindFirstChildOfClass("Humanoid")
        targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    end
end

local function refreshTargetList()
    targetList = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            table.insert(targetList, plr.Name)
        end
    end
end

updateSelf()
player.CharacterAdded:Connect(function(newChar)
    updateSelf(newChar)
end)

-- ============================================================
-- LOOP UTAMA FOLLOW
-- ============================================================
RunService.Heartbeat:Connect(function()
    if not followOn then return end

    if not isAlive(char) or not isAlive(root) or not isAlive(hum) then
        updateSelf()
        if not isAlive(root) or not isAlive(hum) then return end
    end

    updateTarget()
    if not isAlive(targetRoot) or not isAlive(targetHum) then return end

    -- Posisi ideal: di belakang target sejauh followDistance
    local look = targetRoot.CFrame.LookVector
    local desiredPos = targetRoot.Position - (look * followDistance)
    local distToDesired = (root.Position - desiredPos).Magnitude

    if distToDesired > 1 then
        hum:MoveTo(desiredPos)
    end

    -- Ikut lompat hanya kalau target lompat & kita di tanah
    if targetHum:GetState() == Enum.HumanoidStateType.Jumping then
        if hum.FloorMaterial ~= Enum.Material.Air and hum:GetState() ~= Enum.HumanoidStateType.Jumping then
            hum.Jump = true
        end
    end

    -- Samakan kecepatan jalan target
    if targetHum.WalkSpeed ~= hum.WalkSpeed then
        hum.WalkSpeed = targetHum.WalkSpeed
    end
end)

-- ============================================================
-- 🖥️ GUI PILIH TARGET (klik untuk cycle player)
-- ============================================================
local gui = Instance.new("ScreenGui")
-- BUG FIX: tanpa ini, GUI akan otomatis dihapus setiap kali karakter
-- respawn (default ResetOnSpawn = true), sehingga tombol hilang setelah mati.
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 240, 0, 130)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
frame.BorderSizePixel = 0
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 20)
title.BackgroundTransparency = 1
title.Text = "🎯 FOLLOW PLAYER"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 14
title.Parent = frame

local btnFollow = Instance.new("TextButton")
btnFollow.Size = UDim2.new(1, -20, 0, 32)
btnFollow.Position = UDim2.new(0, 10, 0, 25)
btnFollow.Text = "FOLLOW: OFF"
btnFollow.TextColor3 = Color3.fromRGB(255, 255, 255)
btnFollow.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
btnFollow.BorderSizePixel = 0
btnFollow.Parent = frame

local btnTarget = Instance.new("TextButton")
btnTarget.Size = UDim2.new(1, -20, 0, 32)
btnTarget.Position = UDim2.new(0, 10, 0, 62)
btnTarget.Text = "TARGET: Pilih Player"
btnTarget.TextColor3 = Color3.fromRGB(255, 255, 255)
btnTarget.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
btnTarget.BorderSizePixel = 0
btnTarget.Parent = frame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.Position = UDim2.new(0, 0, 0, 100)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Belum ada target"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextSize = 12
statusLabel.Parent = frame

btnFollow.MouseButton1Click:Connect(function()
    followOn = not followOn

    if followOn and not targetPlayer then
        followOn = false
        statusLabel.Text = "Pilih target dulu!"
    else
        statusLabel.Text = followOn and ("Mengikuti: " .. targetPlayer) or "Follow dimatikan"
    end

    btnFollow.Text = followOn and "FOLLOW: ON" or "FOLLOW: OFF"
    btnFollow.BackgroundColor3 = followOn and Color3.fromRGB(40, 120, 60) or Color3.fromRGB(50, 50, 70)
end)

btnTarget.MouseButton1Click:Connect(function()
    refreshTargetList()

    if #targetList == 0 then
        targetPlayer = nil
        targetChar, targetHum, targetRoot = nil, nil, nil
        btnTarget.Text = "TARGET: Tidak ada player"
        statusLabel.Text = "Tidak ada player lain"
        -- BUG FIX: kalau follow lagi nyala tapi tidak ada target lagi,
        -- matikan follow supaya UI dan state konsisten.
        if followOn then
            followOn = false
            btnFollow.Text = "FOLLOW: OFF"
            btnFollow.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
        end
        return
    end

    -- Cari index target saat ini di daftar
    local currentIndex = 0
    if targetPlayer then
        for i, name in ipairs(targetList) do
            if name == targetPlayer then
                currentIndex = i
                break
            end
        end
    end

    -- Pilih player berikutnya
    targetIndex = (currentIndex % #targetList) + 1
    targetPlayer = targetList[targetIndex]

    updateTarget()
    btnTarget.Text = "TARGET: " .. targetPlayer
    statusLabel.Text = (followOn and "Mengikuti: " or "Target: ") .. targetPlayer
end)

-- BUG FIX: kalau target keluar game saat followOn aktif, UI tetap
-- menunjukkan nama lama. Loop kecil ini menjaga label tetap akurat.
RunService.Heartbeat:Connect(function()
    if followOn and not targetPlayer then
        followOn = false
        btnFollow.Text = "FOLLOW: OFF"
        btnFollow.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
        btnTarget.Text = "TARGET: Pilih Player"
        statusLabel.Text = "Target keluar game, follow dimatikan"
    end
end)

print("✅ Script Auto Follow siap! Klik TARGET untuk ganti player, lalu nyalakan FOLLOW.")
