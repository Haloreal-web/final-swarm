-- ============================================================
-- 🤝 AUTO FOLLOW PLAYER — SUPER SPEED + AUTO JUMP
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer or Players.PlayerAdded:Wait()

local char, hum, root
local targetChar, targetHum, targetRoot

local followOn = false
local followDistance = 3
local targetPlayer = nil
local targetList = {}
local targetIndex = 0

-- MODIF: kecepatan super (bisa diubah sesuka hati)
local SUPER_SPEED = 100

local function isAlive(obj)
    if not obj or obj.Parent == nil then
        return false
    end
    if obj:IsA("Humanoid") then
        return obj.Health > 0
    end
    return true
end

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
-- LOOP UTAMA FOLLOW — DENGAN SUPER SPEED & AUTO JUMP
-- ============================================================
RunService.Heartbeat:Connect(function()
    if not followOn then return end

    if not isAlive(char) or not isAlive(root) or not isAlive(hum) then
        updateSelf()
        if not isAlive(root) or not isAlive(hum) then return end
    end

    updateTarget()
    if not isAlive(targetRoot) or not isAlive(targetHum) then return end

    -- Posisi ideal di belakang target
    local look = targetRoot.CFrame.LookVector
    local desiredPos = targetRoot.Position - (look * followDistance)
    local distToDesired = (root.Position - desiredPos).Magnitude

    -- Gerak ke posisi ideal (pakai MoveTo)
    if distToDesired > 1 then
        hum:MoveTo(desiredPos)
    end

    -- ===== MODIF: SET SPEED SUPER CEPAT =====
    -- Gak usah nyamain target, langsung pake SUPER_SPEED
    if hum.WalkSpeed ~= SUPER_SPEED then
        hum.WalkSpeed = SUPER_SPEED
    end

    -- ===== MODIF: AUTO JUMP AGGRESIF =====
    local targetJumping = targetHum:GetState() == Enum.HumanoidStateType.Jumping
    local distTotal = (root.Position - targetRoot.Position).Magnitude
    local yDiff = targetRoot.Position.Y - root.Position.Y

    -- Lompat kalau:
    -- 1. Target lagi loncat, ATAU
    -- 2. Jarak total > 15 (biar ngejar), ATAU
    -- 3. Target berada di atas kita (selisih Y > 5)
    local shouldJump = targetJumping or distTotal > 15 or yDiff > 5

    if shouldJump then
        if hum.FloorMaterial ~= Enum.Material.Air and hum:GetState() ~= Enum.HumanoidStateType.Jumping then
            hum.Jump = true
        end
    end
end)

-- ============================================================
-- 🖥️ GUI (SAMA KAYAK SEBELUMNYA, TETAP)
-- ============================================================
local gui = Instance.new("ScreenGui")
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
        if followOn then
            followOn = false
            btnFollow.Text = "FOLLOW: OFF"
            btnFollow.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
        end
        return
    end
    local currentIndex = 0
    if targetPlayer then
        for i, name in ipairs(targetList) do
            if name == targetPlayer then
                currentIndex = i
                break
            end
        end
    end
    targetIndex = (currentIndex % #targetList) + 1
    targetPlayer = targetList[targetIndex]
    updateTarget()
    btnTarget.Text = "TARGET: " .. targetPlayer
    statusLabel.Text = (followOn and "Mengikuti: " or "Target: ") .. targetPlayer
end)

RunService.Heartbeat:Connect(function()
    if followOn and not targetPlayer then
        followOn = false
        btnFollow.Text = "FOLLOW: OFF"
        btnFollow.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
        btnTarget.Text = "TARGET: Pilih Player"
        statusLabel.Text = "Target keluar game, follow dimatikan"
    end
end)

print("✅ Auto Follow SUPER SPEED + AUTO JUMP siap! Klik TARGET, nyalakan FOLLOW, dan saksikan kecepatan gila!")