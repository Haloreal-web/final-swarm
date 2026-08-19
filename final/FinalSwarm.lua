-- ============================================
-- TAMPILKAN SEMUA REMOTE DI GUI (SAFE)
-- ============================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Hapus GUI lama kalau ada
local oldGui = playerGui:FindFirstChild("RemoteListGUI")
if oldGui then oldGui:Destroy() end

-- Buat ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RemoteListGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Buat Frame utama
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 300, 0, 400)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- Judul
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
titleLabel.Text = "📡 REMOTE LIST"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 16
titleLabel.Parent = mainFrame

-- Tombol Close
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 16
closeBtn.Parent = mainFrame
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- ScrollingFrame
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -10, 1, -40)
scrollFrame.Position = UDim2.new(0, 5, 0, 35)
scrollFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 5
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = mainFrame

-- Layout untuk daftar
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 2)
layout.SortOrder = Enum.SortOrder.Name
layout.Parent = scrollFrame

-- Fungsi tambah remote ke daftar
local function addRemoteEntry(remote)
    local entry = Instance.new("TextLabel")
    entry.Size = UDim2.new(1, -10, 0, 25)
    entry.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    entry.Text = string.format("[%s] %s", remote.ClassName, remote:GetFullName())
    entry.TextColor3 = Color3.fromRGB(255, 255, 255)
    entry.Font = Enum.Font.SourceSans
    entry.TextSize = 12
    entry.TextWrapped = false
    entry.TextXAlignment = Enum.TextXAlignment.Left
    entry.Parent = scrollFrame
    return entry
end

-- Scan ReplicatedStorage
for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        addRemoteEntry(obj)
    end
end

-- Scan Workspace (opsional)
for _, obj in ipairs(Workspace:GetDescendants()) do
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        addRemoteEntry(obj)
    end
end

-- Tampilkan info jumlah
local countLabel = Instance.new("TextLabel")
countLabel.Size = UDim2.new(1, 0, 0, 20)
countLabel.Position = UDim2.new(0, 0, 1, -25)
countLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
countLabel.Text = "Total Remote: " .. #scrollFrame:GetChildren()
countLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
countLabel.Font = Enum.Font.SourceSans
countLabel.TextSize = 12
countLabel.Parent = mainFrame

print("✅ GUI Remote List sudah tampil!")