-- ============================================
-- LIST SEMUA REMOTE EVENT & FUNCTION
-- ============================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

print("===== REMOTES DI REPLICATEDSTORAGE =====")
for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        print("📡", obj.ClassName, "|", obj:GetFullName())
    end
end

print("===== REMOTES DI WORKSPACE =====")
for _, obj in ipairs(Workspace:GetDescendants()) do
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        print("📡", obj.ClassName, "|", obj:GetFullName())
    end
end

print("✅ Selesai! Cari nama yang mengandung kata 'Heal', 'Health', 'Damage', 'Hit', 'Revive', dll.")
