-- OX1DE v0.9 startup test; deliberately minimal to isolate launcher errors
local Players = game:GetService("Players")
local player = Players.LocalPlayer
assert(player, "LocalPlayer is missing")
local playerGui = player:WaitForChild("PlayerGui", 10)
assert(playerGui, "PlayerGui is unavailable")
local old = playerGui:FindFirstChild("OX1DE_V09_TEST")
if old then old:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "OX1DE_V09_TEST"
gui.ResetOnSpawn = false
gui.DisplayOrder = 9999
gui.Parent = playerGui
local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(300, 110)
frame.Position = UDim2.new(0.5, -150, 0.25, 0)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
frame.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -16, 1, -16)
status.Position = UDim2.fromOffset(8, 8)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(255, 255, 255)
status.Font = Enum.Font.GothamBold
status.TextScaled = true
status.TextWrapped = true
status.Text = "OX1DE v0.9 TEST LOADED\nLua and PlayerGui work"
status.Parent = frame
print("[OX1DE v0.9] UI loaded successfully")
