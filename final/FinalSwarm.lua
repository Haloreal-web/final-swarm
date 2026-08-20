-- ============================================================
-- AUTO FOLLOW PRO v10 - FIXED & OPTIMIZED
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- ===== VARIABEL =====
local char, hum, root
local targetChar, targetHum, targetRoot
local followOn = false
local followMode = "keep" -- "keep" = jaga jarak, "close" = dekati
local followDistance = 100
local targetPlayer = nil
local walkSpeed = 100
local noClipOn = false
local cloneList = {}
local MAX_CLONES = 50
local noclipBody = nil
local originalCanCollide = {}
local originalCanCollideInitialized = false -- penanda apakah state asli sudah disimpan

-- Auto Dodge
local autoDodgeOn = false
local lastDodgeTime = 0
local lastPositions = {}
local scanInterval = 0.05
local nextScan = 0
local dodgeCooldown = 1.0

-- statusLabel di-forward declare
local statusLabel

-- Simpan koneksi untuk bisa diputus saat GUI ditutup
local connections = {}

-- ===== FUNGSI DASAR =====
local function isAlive(obj)
    if not obj or obj.Parent == nil then return false end
    if obj:IsA("Humanoid") then return obj.Health > 0 end
    return true
end

local function updateSelf(newChar)
    local oldChar = char
    char = newChar or player.Character
    if not char then
        hum, root = nil, nil
        return
    end

    hum = char:FindFirstChildOfClass("Humanoid")
    root = char:FindFirstChild("HumanoidRootPart")

    if not isAlive(char) or not hum or not root then
        char, hum, root = nil, nil, nil
    else
        -- Reset penyimpanan CanCollide jika karakter berganti
        if char ~= oldChar then
            originalCanCollide = {}
            originalCanCollideInitialized = false
        end
        if noClipOn then
            setNoClip(true)
        end
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

    local tChar = plr.Character
    if tChar and isAlive(tChar) then
        targetChar = tChar
        targetHum = tChar:FindFirstChildOfClass("Humanoid")
        targetRoot = tChar:FindFirstChild("HumanoidRootPart")
    end
end

updateSelf()
player.CharacterAdded:Connect(function(newChar)
    updateSelf(newChar)
end)

-- ===== NO CLIP =====
local function setNoClip(state)
    if not char or not root then return end

    if state then
        -- Jika pertama kali atau karakter baru, simpan state CanCollide asli
        if not originalCanCollideInitialized then
            originalCanCollide = {}
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    originalCanCollide[part] = part.CanCollide
                end
            end
            originalCanCollideInitialized = true
        end

        -- Terapkan no clip ke semua bagian saat ini, simpan yang belum ada
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if originalCanCollide[part] == nil then
                    originalCanCollide[part] = part.CanCollide
                end
                part.CanCollide = false
            end
        end

        -- Buat atau pindahkan BodyVelocity ke root saat ini
        if not noclipBody or noclipBody.Parent ~= root then
            if noclipBody then
                noclipBody:Destroy()
            end
            noclipBody = Instance.new("BodyVelocity")
            noclipBody.Velocity = Vector3.new(0, 0, 0)
            noclipBody.MaxForce = Vector3.new(100000, 100000, 100000)
            noclipBody.Parent = root
        end
        noclipBody.Velocity = Vector3.new(0, 0, 0)
    else
        -- Kembalikan CanCollide asli
        for part, original in pairs(originalCanCollide) do
            if part and part.Parent then
                part.CanCollide = original
            end
        end

        -- Hancurkan BodyVelocity
        if noclipBody then
            noclipBody:Destroy()
            noclipBody = nil
        end
    end
end

local function toggleNoClip()
    noClipOn = not noClipOn
    setNoClip(noClipOn)
    return noClipOn
end

-- ===== SPAM CLONE =====
local function spawnClone()
    if not targetRoot then
        if statusLabel then statusLabel.Text = "Target tidak valid" end
        return
    end

    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        if statusLabel then statusLabel.Text = "Karakter belum siap" end
        return
    end

    -- Hapus clone tertua jika melebihi batas
    while #cloneList >= MAX_CLONES do
        local oldest = table.remove(cloneList, 1)
        if oldest and oldest.Parent then
            oldest:Destroy()
        end
    end

    local clone = player.Character:Clone()

    -- Buang semua script agar tidak error
    for _, desc in ipairs(clone:GetDescendants()) do
        if desc:IsA("Script") or desc:IsA("LocalScript") or desc:IsA("ModuleScript") then
            desc:Destroy()
        end
        -- Hapus juga Humanoid dan Animator di semua descendant
        if desc:IsA("Humanoid") or desc:IsA("Animator") then
            desc:Destroy()
        end
    end

    clone.Parent = workspace
    clone.Name = "Clone_" .. player.Name .. "_" .. (#cloneList + 1)

    -- Hitung posisi acak di sekitar target
    local angle = math.random() * 2 * math.pi
    local radius = math.random(15, 60)
    local offset = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
    local pos = targetRoot.Position + offset
    pos = Vector3.new(pos.X, targetRoot.Position.Y, pos.Z)

    -- Raycast ke bawah untuk mencari tanah (agar clone tidak melayang)
    local rayOrigin = pos + Vector3.new(0, 5, 0)
    local rayDirection = Vector3.new(0, -100, 0)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {player.Character, clone}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    if rayResult then
        pos = Vector3.new(pos.X, rayResult.Position.Y + 3, pos.Z)
    end

    -- Set posisi root clone
    local rootPart = clone:FindFirstChild("HumanoidRootPart")
    if rootPart then
        rootPart.CFrame = CFrame.new(pos)
    end

    -- Anchor semua bagian agar clone diam
    for _, part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = true
            part.CanCollide = false
        end
    end

    table.insert(cloneList, clone)
    if statusLabel then statusLabel.Text = "Clone dibuat, total: " .. #cloneList end
end

local function removeAllClones()
    for _, cl in ipairs(cloneList) do
        if cl and cl.Parent then
            cl:Destroy()
        end
    end
    cloneList = {}
    if statusLabel then statusLabel.Text = "Semua clone dihapus" end
end

-- ===== TELEPORT KE TARGET =====
local function teleportToTarget()
    if not targetPlayer then
        if statusLabel then statusLabel.Text = "Pilih target dulu" end
        return
    end
    updateTarget()
    if not targetRoot or not root then
        if statusLabel then statusLabel.Text = "Target atau karakter tidak valid" end
        return
    end

    -- Teleport 3 stud di samping target (agar tidak bertumpuk)
    local offset = targetRoot.CFrame.RightVector * 3
    local newCFrame = targetRoot.CFrame + offset
    root.CFrame = newCFrame

    if statusLabel then statusLabel.Text = "Teleport ke " .. targetPlayer end
end

-- ===== AUTO DODGE =====
-- Fungsi untuk mendapatkan part di radius tertentu dengan fallback yang aman
local function getPartsInRadius(center, radius)
    -- Gunakan FindPartsInRegion3 (masih tersedia, meski deprecated)
    local region = Region3.new(
        center - Vector3.new(radius, radius, radius),
        center + Vector3.new(radius, radius, radius)
    )
    return workspace:FindPartsInRegion3(region, nil, 100)
end

local function performDodge()
    if not root or not hum then return end
    hum.Jump = true
    local side = math.random(2) == 1 and 1 or -1
    local impulse = root.CFrame.RightVector * side * 30 + Vector3.new(0, 20, 0)

    -- Gunakan Velocity untuk kompatibilitas (AssemblyLinearVelocity juga didukung)
    if root.AssemblyLinearVelocity then
        root.AssemblyLinearVelocity = impulse
    elseif root.Velocity then
        root.Velocity = impulse
    end

    if statusLabel then statusLabel.Text = "Auto Dodge!" end
end

-- Loop auto dodge terpisah
local autoDodgeConnection = RunService.Heartbeat:Connect(function()
    if not autoDodgeOn then return end
    if not isAlive(char) or not isAlive(root) then return end

    local now = tick()
    if now < nextScan then return end
    nextScan = now + scanInterval

    -- Scan radius 15 stud
    local parts = getPartsInRadius(root.Position, 15)
    local currentParts = {}

    for _, part in ipairs(parts) do
        if part and part:IsA("BasePart") and part.Parent and part ~= root then
            local skip = false
            -- Skip bagian dari karakter pemain mana pun
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.Character and part:IsDescendantOf(plr.Character) then
                    skip = true
                    break
                end
            end
            -- Skip clone list
            if not skip then
                for _, cl in ipairs(cloneList) do
                    if part:IsDescendantOf(cl) then
                        skip = true
                        break
                    end
                end
            end
            if not skip then
                currentParts[part] = part.Position
            end
        end
    end

    -- Hitung kecepatan objek yang terlihat sebelumnya
    if lastPositions then
        for part, oldPos in pairs(lastPositions) do
            if part.Parent and currentParts[part] then
                local newPos = currentParts[part]
                local velocity = (newPos - oldPos).Magnitude / scanInterval
                if velocity > 40 then
                    local dirToPlayer = (root.Position - newPos).Unit
                    local moveDir = (newPos - oldPos).Unit
                    local dot = dirToPlayer:Dot(moveDir)
                    if dot > 0.3 then
                        if now - lastDodgeTime > dodgeCooldown then
                            lastDodgeTime = now
                            performDodge()
                        end
                    end
                end
            end
        end
    end

    lastPositions = currentParts
end)

-- ===== LOOP FOLLOW =====
local followConnection = RunService.Heartbeat:Connect(function()
    if not followOn then return end

    if not isAlive(char) or not isAlive(root) or not isAlive(hum) then
        updateSelf()
        if not isAlive(root) or not isAlive(hum) then return end
    end

    updateTarget()
    if not isAlive(targetRoot) or not isAlive(targetHum) then return end

    local desiredPos
    if followMode == "keep" then
        local look = targetRoot.CFrame.LookVector
        desiredPos = targetRoot.Position - look * followDistance
    else
        desiredPos = targetRoot.Position
    end

    hum:MoveTo(desiredPos)

    -- Gunakan walkSpeed yang bisa diubah
    if hum.WalkSpeed ~= walkSpeed then
        hum.WalkSpeed = walkSpeed
    end

    local targetJumping = targetHum:GetState() == Enum.HumanoidStateType.Jumping
    local distTotal = (root.Position - targetRoot.Position).Magnitude
    local yDiff = targetRoot.Position.Y - root.Position.Y
    local shouldJump = targetJumping or distTotal > 15 or yDiff > 5

    if shouldJump and hum.FloorMaterial ~= Enum.Material.Air and hum:GetState() ~= Enum.HumanoidStateType.Jumping then
        hum.Jump = true
    end
end)

-- ============================================================
-- UI CLEAN - TANPA EMOJI
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
gui.Name = "AutoFollowPro"
gui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 470)
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -235)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 32)
titleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -60, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "AUTO FOLLOW PRO v10"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 16
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- Close
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -32, 0, 2)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 16
closeBtn.Parent = titleBar
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 4)
closeCorner.Parent = closeBtn

-- Minimize
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 28, 0, 28)
minBtn.Position = UDim2.new(1, -62, 0, 2)
minBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
minBtn.BorderSizePixel = 0
minBtn.Text = "-"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.Font = Enum.Font.SourceSansBold
minBtn.TextSize = 20
minBtn.Parent = titleBar
local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 4)
minCorner.Parent = minBtn

-- Konten
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -20, 1, -42)
content.Position = UDim2.new(0, 10, 0, 38)
content.BackgroundTransparency = 1
content.Parent = mainFrame

-- Tombol Jaga Jarak
local btnKeepDistance = Instance.new("TextButton")
btnKeepDistance.Size = UDim2.new(0.48, 0, 0, 30)
btnKeepDistance.Position = UDim2.new(0, 0, 0, 0)
btnKeepDistance.Text = "Jaga Jarak"
btnKeepDistance.TextColor3 = Color3.fromRGB(255, 255, 255)
btnKeepDistance.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
btnKeepDistance.BorderSizePixel = 0
btnKeepDistance.Font = Enum.Font.SourceSansBold
btnKeepDistance.TextSize = 13
btnKeepDistance.Parent = content
local corner1 = Instance.new("UICorner")
corner1.CornerRadius = UDim.new(0, 4)
corner1.Parent = btnKeepDistance

-- Tombol Dekati
local btnClose = Instance.new("TextButton")
btnClose.Size = UDim2.new(0.48, 0, 0, 30)
btnClose.Position = UDim2.new(0.52, 0, 0, 0)
btnClose.Text = "Dekati"
btnClose.TextColor3 = Color3.fromRGB(255, 255, 255)
btnClose.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
btnClose.BorderSizePixel = 0
btnClose.Font = Enum.Font.SourceSansBold
btnClose.TextSize = 13
btnClose.Parent = content
local corner2 = Instance.new("UICorner")
corner2.CornerRadius = UDim.new(0, 4)
corner2.Parent = btnClose

-- Status follow
local followStatus = Instance.new("TextLabel")
followStatus.Size = UDim2.new(1, 0, 0, 18)
followStatus.Position = UDim2.new(0, 0, 0, 34)
followStatus.BackgroundTransparency = 1
followStatus.Text = "Follow: OFF"
followStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
followStatus.Font = Enum.Font.SourceSans
followStatus.TextSize = 13
followStatus.TextXAlignment = Enum.TextXAlignment.Left
followStatus.Parent = content

-- Frame daftar target
local targetListFrame = Instance.new("ScrollingFrame")
targetListFrame.Size = UDim2.new(1, 0, 0, 100)
targetListFrame.Position = UDim2.new(0, 0, 0, 58)
targetListFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
targetListFrame.BorderSizePixel = 0
targetListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
targetListFrame.ScrollBarThickness = 6
targetListFrame.Parent = content
local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 4)
listCorner.Parent = targetListFrame

-- Tombol Spawn Clone
local btnSpawnClone = Instance.new("TextButton")
btnSpawnClone.Size = UDim2.new(0.48, 0, 0, 30)
btnSpawnClone.Position = UDim2.new(0, 0, 0, 165)
btnSpawnClone.Text = "Spawn Clone"
btnSpawnClone.TextColor3 = Color3.fromRGB(255, 255, 255)
btnSpawnClone.BackgroundColor3 = Color3.fromRGB(120, 80, 140)
btnSpawnClone.BorderSizePixel = 0
btnSpawnClone.Font = Enum.Font.SourceSansBold
btnSpawnClone.TextSize = 13
btnSpawnClone.Parent = content
local corner3 = Instance.new("UICorner")
corner3.CornerRadius = UDim.new(0, 4)
corner3.Parent = btnSpawnClone

-- Tombol Hapus Semua Clone
local btnRemoveAllClone = Instance.new("TextButton")
btnRemoveAllClone.Size = UDim2.new(0.48, 0, 0, 30)
btnRemoveAllClone.Position = UDim2.new(0.52, 0, 0, 165)
btnRemoveAllClone.Text = "Hapus Semua"
btnRemoveAllClone.TextColor3 = Color3.fromRGB(255, 255, 255)
btnRemoveAllClone.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
btnRemoveAllClone.BorderSizePixel = 0
btnRemoveAllClone.Font = Enum.Font.SourceSansBold
btnRemoveAllClone.TextSize = 13
btnRemoveAllClone.Parent = content
local corner4 = Instance.new("UICorner")
corner4.CornerRadius = UDim.new(0, 4)
corner4.Parent = btnRemoveAllClone

-- Tombol No Clip
local btnNoClip = Instance.new("TextButton")
btnNoClip.Size = UDim2.new(0.48, 0, 0, 30)
btnNoClip.Position = UDim2.new(0, 0, 0, 200)
btnNoClip.Text = "No Clip: OFF"
btnNoClip.TextColor3 = Color3.fromRGB(255, 255, 255)
btnNoClip.BackgroundColor3 = Color3.fromRGB(150, 100, 60)
btnNoClip.BorderSizePixel = 0
btnNoClip.Font = Enum.Font.SourceSansBold
btnNoClip.TextSize = 13
btnNoClip.Parent = content
local corner5 = Instance.new("UICorner")
corner5.CornerRadius = UDim.new(0, 4)
corner5.Parent = btnNoClip

-- Speed Label
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, 0, 0, 20)
speedLabel.Position = UDim2.new(0, 0, 0, 235)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Kecepatan: " .. walkSpeed
speedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
speedLabel.Font = Enum.Font.SourceSans
speedLabel.TextSize = 13
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = content

-- Speed Input
local speedInput = Instance.new("TextBox")
speedInput.Size = UDim2.new(0.55, 0, 0, 28)
speedInput.Position = UDim2.new(0, 0, 0, 258)
speedInput.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
speedInput.BorderSizePixel = 1
speedInput.BorderColor3 = Color3.fromRGB(80, 80, 90)
speedInput.Text = tostring(walkSpeed)
speedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
speedInput.Font = Enum.Font.SourceSans
speedInput.TextSize = 13
speedInput.PlaceholderText = "Masukkan angka"
speedInput.Parent = content
local speedCorner = Instance.new("UICorner")
speedCorner.CornerRadius = UDim.new(0, 4)
speedCorner.Parent = speedInput

-- Set Speed Button
local btnSetSpeed = Instance.new("TextButton")
btnSetSpeed.Size = UDim2.new(0.40, 0, 0, 28)
btnSetSpeed.Position = UDim2.new(0.60, 0, 0, 258)
btnSetSpeed.Text = "Set Speed"
btnSetSpeed.TextColor3 = Color3.fromRGB(255, 255, 255)
btnSetSpeed.BackgroundColor3 = Color3.fromRGB(70, 130, 200)
btnSetSpeed.BorderSizePixel = 0
btnSetSpeed.Font = Enum.Font.SourceSansBold
btnSetSpeed.TextSize = 13
btnSetSpeed.Parent = content
local speedBtnCorner = Instance.new("UICorner")
speedBtnCorner.CornerRadius = UDim.new(0, 4)
speedBtnCorner.Parent = btnSetSpeed

-- Teleport Button
local btnTeleport = Instance.new("TextButton")
btnTeleport.Size = UDim2.new(1, 0, 0, 30)
btnTeleport.Position = UDim2.new(0, 0, 0, 290)
btnTeleport.Text = "Teleport ke Target"
btnTeleport.TextColor3 = Color3.fromRGB(255, 255, 255)
btnTeleport.BackgroundColor3 = Color3.fromRGB(70, 130, 200)
btnTeleport.BorderSizePixel = 0
btnTeleport.Font = Enum.Font.SourceSansBold
btnTeleport.TextSize = 13
btnTeleport.Parent = content
local teleportCorner = Instance.new("UICorner")
teleportCorner.CornerRadius = UDim.new(0, 4)
teleportCorner.Parent = btnTeleport

-- Auto Dodge Button
local btnAutoDodge = Instance.new("TextButton")
btnAutoDodge.Size = UDim2.new(1, 0, 0, 30)
btnAutoDodge.Position = UDim2.new(0, 0, 0, 325)
btnAutoDodge.Text = "Auto Dodge: OFF"
btnAutoDodge.TextColor3 = Color3.fromRGB(255, 255, 255)
btnAutoDodge.BackgroundColor3 = Color3.fromRGB(150, 100, 60)
btnAutoDodge.BorderSizePixel = 0
btnAutoDodge.Font = Enum.Font.SourceSansBold
btnAutoDodge.TextSize = 13
btnAutoDodge.Parent = content
local dodgeCorner = Instance.new("UICorner")
dodgeCorner.CornerRadius = UDim.new(0, 4)
dodgeCorner.Parent = btnAutoDodge

-- Status label (di-assign ke variabel forward)
statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 18)
statusLabel.Position = UDim2.new(0, 0, 0, 360)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Pilih target dari daftar"
statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextSize = 12
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = content

-- ===== FUNGSI UPDATE DAFTAR TARGET =====
local function updateTargetList()
    for _, child in ipairs(targetListFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local plrs = Players:GetPlayers()
    local y = 0
    for _, plr in ipairs(plrs) do
        if plr ~= player then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -10, 0, 24)
            btn.Position = UDim2.new(0, 5, 0, y)
            btn.Text = plr.Name
            btn.TextColor3 = Color3.fromRGB(220, 220, 220)
            btn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
            btn.BorderSizePixel = 1
            btn.BorderColor3 = Color3.fromRGB(80, 80, 90)
            btn.Font = Enum.Font.SourceSans
            btn.TextSize = 13
            btn.Parent = targetListFrame

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 3)
            btnCorner.Parent = btn

            btn.MouseButton1Click:Connect(function()
                targetPlayer = plr.Name
                updateTarget()
                if statusLabel then statusLabel.Text = "Target: " .. targetPlayer end
                for _, b in ipairs(targetListFrame:GetChildren()) do
                    if b:IsA("TextButton") then
                        b.BackgroundColor3 = (b == btn) and Color3.fromRGB(70, 130, 200) or Color3.fromRGB(45, 45, 50)
                    end
                end
            end)

            y = y + 26
        end
    end

    targetListFrame.CanvasSize = UDim2.new(0, 0, 0, y)
end

updateTargetList()
Players.PlayerAdded:Connect(updateTargetList)
Players.PlayerRemoving:Connect(function(plr)
    updateTargetList()
    if targetPlayer == plr.Name then
        targetPlayer = nil
        followOn = false
        updateFollowButtons()
        if statusLabel then statusLabel.Text = "Target keluar, follow dimatikan" end
    end
end)

-- ===== FUNGSI UPDATE TOMBOL FOLLOW =====
local function updateFollowButtons()
    local keepActive = followOn and followMode == "keep"
    local closeActive = followOn and followMode == "close"

    btnKeepDistance.Text = keepActive and "Jaga Jarak: ON" or "Jaga Jarak"
    btnKeepDistance.BackgroundColor3 = keepActive and Color3.fromRGB(40, 160, 80) or Color3.fromRGB(60, 60, 70)

    btnClose.Text = closeActive and "Dekati: ON" or "Dekati"
    btnClose.BackgroundColor3 = closeActive and Color3.fromRGB(40, 160, 80) or Color3.fromRGB(60, 60, 70)

    if followOn then
        followStatus.Text = "Follow: ON (" .. (followMode == "keep" and "jaga jarak" or "dekat") .. ")"
    else
        followStatus.Text = "Follow: OFF"
    end
end

local function setFollow(mode)
    if not targetPlayer then
        if statusLabel then statusLabel.Text = "Pilih target dulu" end
        return
    end

    if followOn and followMode == mode then
        followOn = false
        updateFollowButtons()
        if statusLabel then statusLabel.Text = "Follow dimatikan" end
        return
    end

    followOn = true
    followMode = mode
    if mode == "keep" then
        followDistance = 100
    else
        followDistance = 0
    end

    updateFollowButtons()
    if statusLabel then
        statusLabel.Text = "Mengikuti " .. targetPlayer .. " (" .. (mode == "keep" and "jaga jarak" or "dekat") .. ")"
    end
end

-- ===== DRAG UI =====
local dragActive = false
local dragStart, frameStart

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragActive = true
        dragStart = input.Position
        frameStart = mainFrame.Position
    end
end)

titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragActive = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragActive and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            frameStart.X.Scale,
            frameStart.X.Offset + delta.X,
            frameStart.Y.Scale,
            frameStart.Y.Offset + delta.Y
        )
    end
end)

-- ===== MINIMIZE =====
local minimized = false
local miniFrame = nil

local function toggleMinimize()
    minimized = not minimized
    if minimized then
        mainFrame.Visible = false
        if not miniFrame then
            miniFrame = Instance.new("TextButton")
            miniFrame.Size = UDim2.new(0, 40, 0, 40)
            miniFrame.Position = UDim2.new(1, -50, 1, -50)
            miniFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            miniFrame.BorderSizePixel = 0
            miniFrame.Text = "AF"
            miniFrame.TextColor3 = Color3.fromRGB(255, 255, 255)
            miniFrame.Font = Enum.Font.SourceSansBold
            miniFrame.TextSize = 14
            miniFrame.Parent = gui
            local miniCorner = Instance.new("UICorner")
            miniCorner.CornerRadius = UDim.new(0, 10)
            miniCorner.Parent = miniFrame
            miniFrame.MouseButton1Click:Connect(toggleMinimize)
        else
            miniFrame.Visible = true
        end
    else
        mainFrame.Visible = true
        if miniFrame then miniFrame.Visible = false end
    end
end

minBtn.MouseButton1Click:Connect(toggleMinimize)

-- ===== EVENT TOMBOL =====

btnKeepDistance.MouseButton1Click:Connect(function()
    setFollow("keep")
end)

btnClose.MouseButton1Click:Connect(function()
    setFollow("close")
end)

btnSpawnClone.MouseButton1Click:Connect(function()
    if not targetPlayer then
        if statusLabel then statusLabel.Text = "Pilih target dulu" end
        return
    end
    updateTarget()
    if not targetRoot then
        if statusLabel then statusLabel.Text = "Target tidak valid" end
        return
    end
    spawnClone()
end)

btnRemoveAllClone.MouseButton1Click:Connect(function()
    removeAllClones()
end)

btnNoClip.MouseButton1Click:Connect(function()
    local state = toggleNoClip()
    btnNoClip.Text = state and "No Clip: ON" or "No Clip: OFF"
    btnNoClip.BackgroundColor3 = state and Color3.fromRGB(50, 180, 90) or Color3.fromRGB(150, 100, 60)
    if statusLabel then statusLabel.Text = state and "No Clip aktif" or "No Clip nonaktif" end
end)

-- Event Speed
btnSetSpeed.MouseButton1Click:Connect(function()
    local newSpeed = tonumber(speedInput.Text)
    if newSpeed and newSpeed > 0 then
        walkSpeed = newSpeed
        speedLabel.Text = "Kecepatan: " .. walkSpeed
        if hum then
            hum.WalkSpeed = walkSpeed
        end
        if statusLabel then statusLabel.Text = "Kecepatan diubah ke " .. walkSpeed end
    else
        if statusLabel then statusLabel.Text = "Masukkan angka valid > 0" end
    end
end)

-- Event Teleport
btnTeleport.MouseButton1Click:Connect(function()
    teleportToTarget()
end)

-- Event Auto Dodge
btnAutoDodge.MouseButton1Click:Connect(function()
    autoDodgeOn = not autoDodgeOn
    btnAutoDodge.Text = autoDodgeOn and "Auto Dodge: ON" or "Auto Dodge: OFF"
    btnAutoDodge.BackgroundColor3 = autoDodgeOn and Color3.fromRGB(50, 180, 90) or Color3.fromRGB(150, 100, 60)
    if statusLabel then statusLabel.Text = autoDodgeOn and "Auto Dodge aktif" or "Auto Dodge nonaktif" end
    if not autoDodgeOn then
        lastPositions = {}
    end
end)

-- Close GUI
closeBtn.MouseButton1Click:Connect(function()
    -- Bersihkan semua koneksi heartbeat yang berjalan
    followConnection:Disconnect()
    autoDodgeConnection:Disconnect()

    removeAllClones()
    if noclipBody then noclipBody:Destroy() end
    gui:Destroy()
end)

print("Auto Follow Pro v10 Fixed siap. Semua fitur berfungsi optimal.")