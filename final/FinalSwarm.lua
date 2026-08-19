-- ============================================
-- REMOTE LIST GUI + COPY (TANPA F9)
-- ============================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Hapus GUI lama
if playerGui:FindFirstChild("RemoteListGUI") then
    playerGui:FindFirstChild("RemoteListGUI"):Destroy()
end

-- Buat ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RemoteListGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Frame utama
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 350, 0, 450)
mainFrame.Position = UDim2.new(0.5, -175, 0.5, -225)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- Judul
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 70)
titleLabel.Text = "📡 REMOTE LIST"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 16
titleLabel.Parent = mainFrame

-- Tombol close
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

-- Tombol Copy
local copyBtn = Instance.new("TextButton")
copyBtn.Size = UDim2.new(0, 80, 0, 30)
copyBtn.Position = UDim2.new(1, -115, 0, 0)
copyBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 120)
copyBtn.Text = "📋 Copy"
copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
copyBtn.Font = Enum.Font.SourceSansBold
copyBtn.TextSize = 14
copyBtn.Parent = mainFrame

-- ScrollingFrame
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -10, 1, -70)
scrollFrame.Position = UDim2.new(0, 5, 0, 35)
scrollFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 5
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = mainFrame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 2)
layout.SortOrder = Enum.SortOrder.Name
layout.Parent = scrollFrame

-- Status label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 25)
statusLabel.Position = UDim2.new(0, 0, 1, -30)
statusLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 70)
statusLabel.Text = "Mencari remote..."
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextSize = 12
statusLabel.Parent = mainFrame

-- Fungsi tambah remote ke daftar
local remoteList = {}  -- simpan path

local function addRemoteEntry(remote)
    local entry = Instance.new("TextLabel")
    entry.Size = UDim2.new(1, -10, 0, 25)
    entry.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    entry.Text = string.format("[%s] %s", remote.ClassName, remote:GetFullName())
    entry.TextColor3 = Color3.fromRGB(255, 255, 255)
    entry.Font = Enum.Font.SourceSans
    entry.TextSize = 12
    entry.TextXAlignment = Enum.TextXAlignment.Left
    entry.Parent = scrollFrame
    table.insert(remoteList, remote:GetFullName())
end

-- Scan semua container yang mungkin
local containers = {
    ReplicatedStorage,
    Workspace,
    player:WaitForChild("PlayerGui"),
    StarterGui,
    player:WaitForChild("Backpack"),
    player:WaitForChild("PlayerScripts")
}

for _, container in ipairs(containers) do
    pcall(function()
        for _, obj in ipairs(container:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                addRemoteEntry(obj)
            end
        end
    end)
end

-- Update status
if #remoteList == 0 then
    statusLabel.Text = "❌ Remote tidak ditemukan!"
else
    statusLabel.Text = "✅ Total Remote: " .. #remoteList
end

-- Tombol Copy
copyBtn.MouseButton1Click:Connect(function()
    local text = table.concat(remoteList, "\n")
    if text ~= "" then
        -- Coba setclipboard (biasanya tersedia di executor)
        pcall(function()
            setclipboard(text)
            statusLabel.Text = "✅ Berhasil dicopy ke clipboard!"
        end)
        -- Fallback: kalau gagal, tampilkan pesan
        if not pcall(setclipboard, text) then
            statusLabel.Text = "⚠️ Clipboard tidak didukung executor ini."
        end
    else
        statusLabel.Text = "❌ Tidak ada remote untuk dicopy."
    end
end)

print("✅ GUI Remote List tampil! Jika tidak ada remote, cek ulang script atau game.")