-- ============================================
-- REMOTE SPY (LOG SEMUA REMOTE)
-- ============================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local connections = {}

local function hookRemote(remote)
    if connections[remote] then return end
    connections[remote] = true

    local oldNamecall
    oldNamecall = hookmetamethod(remote, "__namecall", function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
        if method == "FireServer" then
            print("🔥 Remote FIRED:", self:GetFullName())
            for i, v in ipairs(args) do
                print("   Arg", i, "=", v, "| Type:", typeof(v))
            end
        end
        return oldNamecall(self, ...)
    end)
end

-- Scan semua remote di ReplicatedStorage
local function scanRemotes()
    for _, descendant in ipairs(ReplicatedStorage:GetDescendants()) do
        if descendant:IsA("RemoteEvent") or descendant:IsA("RemoteFunction") then
            hookRemote(descendant)
        end
    end
end

scanRemotes()
ReplicatedStorage.DescendantAdded:Connect(function(desc)
    if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
        hookRemote(desc)
    end
end)

print("✅ RemoteSpy aktif! Sekarang coba biarin karakter lo kena damage / mati, lalu lihat output console.")
