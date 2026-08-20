-- ============================================================
-- 🚀 AUTO FOLLOW PRO v6 — Spam Clone (Naruto Style)
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- ===== VARIABEL =====
local char, hum, root
local targetChar, targetHum, targetRoot
local followOn = false
local followDistance = 100  -- default dekat
local targetPlayer = nil
local SUPER_SPEED = 100
local noClipOn = false
local cloneList = {}  -- daftar clone
local MAX_CLONES = 50  -- batas maksimal clone

-- ===== FUNGSI DASAR =====
local function isAlive(obj)
    if not obj or obj.Parent == nil then return false end
    if obj:IsA("Humanoid") then return obj.Health > 0 end
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
    else
        if noClipOn then setNoClip(true) end
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

updateSelf()
player.CharacterAdded:Connect(function(newChar)
    updateSelf(newChar)
end)

-- ===== NO CLIP =====
local function setNoClip(state)
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not state
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
        statusLabel.Text = "Target tidak valid!"
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
    clone.Parent = workspace
    clone.Name = "Clone_" .. player.Name .. "_" .. (#cloneList + 1)

    -- Posisi acak di sekitar target (radius 15–60 stud)
    local angle = math.random() * 2 * math.pi
    local radius = math.random(15, 60)
    local offset = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
    local pos = targetRoot.Position + offset
    pos = Vector3.new(pos.X, targetRoot.Position.Y, pos.Z)

    local rootPart = clone:FindFirstChild("HumanoidRootPart")
    if rootPart then
        rootPart.CFrame = CFrame.new(pos)
    end

    local humClone = clone:FindFirstChildOfClass("Humanoid")
    if humClone then
        humClone.PlatformStand = true
        humClone.WalkSpeed = 0
        humClone.JumpPower = 0
    end

    -- No clip untuk clone (biar gak aneh)
    for _, part in ipairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end

    table.insert(cloneList, clone)
    statusLabel.Text = "Clone spawned! Total: " .. #cloneList
end

local function removeAllClones()
    for _, cl in ipairs(cloneList) do
        if cl and cl.Parent then
            cl:Destroy()
        end
    end
    cloneList = {}
    statusLabel.Text = "Semua clone dihapus"
end

-- ===== LOOP FOLLOW =====
RunService.Heartbeat:Connect(function()
    if not followOn then return end

    if not isAlive(char) or not isAlive(root) or not isAlive(hum) then
        updateSelf()
        if not isAlive(root) or not isAlive(hum) then return end
    end

    updateTarget()
    if not isAlive(targetRoot) or not isAlive(targetHum) then return end

    local look = targetRoot.CFrame.LookVector
    local desiredPos = targetRoot.Position - (look * followDistance)
    hum:MoveTo(desiredPos)

    if hum.WalkSpeed ~= SUPER_SPEED then
        hum.WalkSpeed = SUPER_SPEED
    end

    local targetJumping = targetHum:GetState() == Enum.HumanoidStateType.Jumping
    local distTotal = (root.Position - targetRoot.Position).Magnitude
    local yDiff = targetRoot.Position.Y - root.Position.Y
    local shouldJump = targetJumping or distTotal > 15 or yDiff > 5

    if shouldJump then
        if hum.FloorMaterial ~= Enum.Material.Air and hum:GetState() ~= Enum.HumanoidStateType.Jumping then
            hum.Jump = true
        end
    end
end)

-- ============================================================
-- 🖥️ UI CERAH + DAFTAR TARGET + SPAM CLONE
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
gui.Name = "AutoFollowPro"
gui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 330)  -- lebih tinggi
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -165)
mainFrame.BackgroundColor3 = Color3.fromRGB(240, 240, 245)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = mainFrame

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 32)
titleBar.BackgroundColor3 = Color3.fromRGB(70, 130, 200)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 6)
titleCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -60, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🎯 AUTO FOLLOW"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 16
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- Close
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -32, 0, 2)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
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
minBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
minBtn.BorderSizePixel = 0
minBtn.Text = "─"
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

-- FOLLOW 100
local btnFollow100 = Instance.new("TextButton")
btnFollow100.Size = UDim2.new(0.46, -5, 0, 32)
btnFollow100.Position = UDim2.new(0, 0, 0, 0)
btnFollow100.Text = "FOLLOW 100"
btnFollow100.TextColor3 = Color3.fromRGB(255, 255, 255)
btnFollow100.BackgroundColor3 = Color3.fromRGB(60, 160, 80)
btnFollow100.BorderSizePixel = 0
btnFollow100.Font = Enum.Font.SourceSansBold
btnFollow100.TextSize = 14
btnFollow100.Parent = content
local corner1 = Instance.new("UICorner")
corner1.CornerRadius = UDim.new(0, 4)
corner1.Parent = btnFollow100

-- FOLLOW 1000
local btnFollow1000 = Instance.new("TextButton")
btnFollow1000.Size = UDim2.new(0.46, -5, 0, 32)
btnFollow1000.Position = UDim2.new(0.54, 0, 0, 0)
btnFollow1000.Text = "FOLLOW 1000"
btnFollow1000.TextColor3 = Color3.fromRGB(255, 255, 255)
btnFollow1000.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
btnFollow1000.BorderSizePixel = 0
btnFollow1000.Font = Enum.Font.SourceSansBold
btnFollow1000.TextSize = 14
btnFollow1000.Parent = content
local corner2 = Instance.new("UICorner")
corner2.CornerRadius = UDim.new(0, 4)
corner2.Parent = btnFollow1000

-- Status follow
local followStatus = Instance.new("TextLabel")
followStatus.Size = UDim2.new(1, 0, 0, 18)
followStatus.Position = UDim2.new(0, 0, 0, 36)
followStatus.BackgroundTransparency = 1
followStatus.Text = "Follow: OFF"
followStatus.TextColor3 = Color3.fromRGB(50, 50, 50)
followStatus.Font = Enum.Font.SourceSans
followStatus.TextSize = 13
followStatus.TextXAlignment = Enum.TextXAlignment.Left
followStatus.Parent = content

-- DAFTAR TARGET
local targetListFrame = Instance.new("ScrollingFrame")
targetListFrame.Size = UDim2.new(1, 0, 0, 100)
targetListFrame.Position = UDim2.new(0, 0, 0, 58)
targetListFrame.BackgroundColor3 = Color3.fromRGB(220, 220, 230)
targetListFrame.BorderSizePixel = 0
targetListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
targetListFrame.ScrollBarThickness = 6
targetListFrame.Parent = content
local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 4)
listCorner.Parent = targetListFrame

local targetListLayout = Instance.new("UIListLayout")
targetListLayout.SortOrder = Enum.SortOrder.LayoutOrder
targetListLayout.Padding = UDim.new(0, 2)
targetListLayout.Parent = targetListFrame

-- SPAM CLONE
local btnSpawnClone = Instance.new("TextButton")
btnSpawnClone.Size = UDim2.new(0.46, -5, 0, 30)
btnSpawnClone.Position = UDim2.new(0, 0, 0, 165)
btnSpawnClone.Text = "SPAWN CLONE"
btnSpawnClone.TextColor3 = Color3.fromRGB(255, 255, 255)
btnSpawnClone.BackgroundColor3 = Color3.fromRGB(180, 100, 180)
btnSpawnClone.BorderSizePixel = 0
btnSpawnClone.Font = Enum.Font.SourceSansBold
btnSpawnClone.TextSize = 14
btnSpawnClone.Parent = content
local corner3 = Instance.new("UICorner")
corner3.CornerRadius = UDim.new(0, 4)
corner3.Parent = btnSpawnClone

local btnRemoveAllClone = Instance.new("TextButton")
btnRemoveAllClone.Size = UDim2.new(0.46, -5, 0, 30)
btnRemoveAllClone.Position = UDim2.new(0.54, 0, 0, 165)
btnRemoveAllClone.Text = "HAPUS SEMUA"
btnRemoveAllClone.TextColor3 = Color3.fromRGB(255, 255, 255)
btnRemoveAllClone.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
btnRemoveAllClone.BorderSizePixel = 0
btnRemoveAllClone.Font = Enum.Font.SourceSansBold
btnRemoveAllClone.TextSize = 14
btnRemoveAllClone.Parent = content
local corner4 = Instance.new("UICorner")
corner4.CornerRadius = UDim.new(0, 4)
corner4.Parent = btnRemoveAllClone

-- NO CLIP
local btnNoClip = Instance.new("TextButton")
btnNoClip.Size = UDim2.new(0.46, -5, 0, 30)
btnNoClip.Position = UDim2.new(0, 0, 0, 200)
btnNoClip.Text = "NO CLIP: OFF"
btnNoClip.TextColor3 = Color3.fromRGB(255, 255, 255)
btnNoClip.BackgroundColor3 = Color3.fromRGB(200, 120, 50)
btnNoClip.BorderSizePixel = 0
btnNoClip.Font = Enum.Font.SourceSansBold
btnNoClip.TextSize = 14
btnNoClip.Parent = content
local corner5 = Instance.new("UICorner")
corner5.CornerRadius = UDim.new(0, 4)
corner5.Parent = btnNoClip

-- Status label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 18)
statusLabel.Position = UDim2.new(0, 0, 0, 235)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Pilih target dari daftar"
statusLabel.TextColor3 = Color3.fromRGB(60, 60, 60)
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
    local listHeight = 0
    for _, plr in ipairs(plrs) do
        if plr ~= player then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -10, 0, 24)
            btn.Position = UDim2.new(0, 5, 0, listHeight)
            btn.Text = plr.Name
            btn.TextColor3 = Color3.fromRGB(30, 30, 30)
            btn.BackgroundColor3 = Color3.fromRGB(240, 240, 250)
            btn.BorderSizePixel = 1
            btn.BorderColor3 = Color3.fromRGB(180, 180, 190)
            btn.Font = Enum.Font.SourceSans
            btn.TextSize = 14
            btn.Parent = targetListFrame

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 3)
            btnCorner.Parent = btn

            btn.MouseButton1Click:Connect(function()
                targetPlayer = plr.Name
                updateTarget()
                statusLabel.Text = "Target: " .. targetPlayer
                for _, b in ipairs(targetListFrame:GetChildren()) do
                    if b:IsA("TextButton") then
                        b.BackgroundColor3 = (b == btn) and Color3.fromRGB(150, 200, 255) or Color3.fromRGB(240, 240, 250)
                    end
                end
            end)

            listHeight = listHeight + 26
        end
    end
    targetListFrame.CanvasSize = UDim2.new(0, 0, 0, listHeight)
end

updateTargetList()
Players.PlayerAdded:Connect(updateTargetList)
Players.PlayerRemoving:Connect(updateTargetList)

-- ===== DRAG =====
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
            miniFrame.BackgroundColor3 = Color3.fromRGB(70, 130, 200)
            miniFrame.BorderSizePixel = 0
            miniFrame.Text = "🎯"
            miniFrame.TextColor3 = Color3.fromRGB(255, 255, 255)
            miniFrame.Font = Enum.Font.SourceSansBold
            miniFrame.TextSize = 20
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

-- ===== CLOSE =====
closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
    removeAllClones()
end)

-- ===== EVENT TOMBOL =====

btnFollow100.MouseButton1Click:Connect(function()
    if not targetPlayer then
        statusLabel.Text = "Pilih target dulu!"
        return
    end
    followOn = not followOn
    followDistance = 100
    if followOn then
        btnFollow100.BackgroundColor3 = Color3.fromRGB(40, 200, 60)
        btnFollow100.Text = "FOLLOW 100 ON"
        btnFollow1000.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
        btnFollow1000.Text = "FOLLOW 1000"
        followStatus.Text = "Follow: ON (100)"
        statusLabel.Text = "Mengikuti " .. targetPlayer .. " (jarak 100)"
    else
        btnFollow100.BackgroundColor3 = Color3.fromRGB(60, 160, 80)
        btnFollow100.Text = "FOLLOW 100"
        followStatus.Text = "Follow: OFF"
        statusLabel.Text = "Follow dimatikan"
    end
end)

btnFollow1000.MouseButton1Click:Connect(function()
    if not targetPlayer then
        statusLabel.Text = "Pilih target dulu!"
        return
    end
    followOn = not followOn
    followDistance = 1000
    if followOn then
        btnFollow1000.BackgroundColor3 = Color3.fromRGB(40, 180, 255)
        btnFollow1000.Text = "FOLLOW 1000 ON"
        btnFollow100.BackgroundColor3 = Color3.fromRGB(60, 160, 80)
        btnFollow100.Text = "FOLLOW 100"
        followStatus.Text = "Follow: ON (1000)"
        statusLabel.Text = "Mengikuti " .. targetPlayer .. " (jarak 1000)"
    else
        btnFollow1000.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
        btnFollow1000.Text = "FOLLOW 1000"
        followStatus.Text = "Follow: OFF"
        statusLabel.Text = "Follow dimatikan"
    end
end)

btnSpawnClone.MouseButton1Click:Connect(function()
    if not targetPlayer then
        statusLabel.Text = "Pilih target dulu!"
        return
    end
    updateTarget()
    if not targetRoot then
        statusLabel.Text = "Target tidak valid"
        return
    end
    spawnClone()
end)

btnRemoveAllClone.MouseButton1Click:Connect(function()
    removeAllClones()
end)

btnNoClip.MouseButton1Click:Connect(function()
    local state = toggleNoClip()
    btnNoClip.Text = state and "NO CLIP: ON" or "NO CLIP: OFF"
    btnNoClip.BackgroundColor3 = state and Color3.fromRGB(50, 200, 100) or Color3.fromRGB(200, 120, 50)
    statusLabel.Text = state and "No Clip aktif" or "No Clip nonaktif"
end)

-- ===== CEK TARGET KELUAR =====
RunService.Heartbeat:Connect(function()
    if followOn and not targetPlayer then
        followOn = false
        followStatus.Text = "Follow: OFF"
        btnFollow100.Text = "FOLLOW 100"
        btnFollow100.BackgroundColor3 = Color3.fromRGB(60, 160, 80)
        btnFollow1000.Text = "FOLLOW 1000"
        btnFollow1000.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
        statusLabel.Text = "Target keluar game, follow dimatikan"
    end
end)

print("✅ Auto Follow Pro v6 siap! Spam clone sebanyak-banyaknya!")