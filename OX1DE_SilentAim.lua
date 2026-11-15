-- OX1DE Silent Aim | experimental client-side module
-- Does not modify the existing OX1DE menu.
-- Compatibility depends on the game's client-side shooting implementation.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = localPlayer:GetMouse()

if type(_G.OX1DE_SILENT_STOP) == "function" then
    pcall(_G.OX1DE_SILENT_STOP)
end

local settings = {
    enabled = true,
    teamCheck = true,
    maxDistance = 1200,
    bulletSpeed = 500, -- studs/second; adjust for the game's projectile speed
    prediction = false, -- hitscan-style test; no travel-time prediction
    hookRaycast = true,
    hookMouse = true,
}
local diagnostics = { raycast = 0, mouse = 0 }
local checkingVisibility = false
local holdingFire = false
local lastFire = 0
local connections = {}
local alive = true
local function connect(signal, callback)
    local c = signal:Connect(callback)
    table.insert(connections, c)
end
local function isFiring()
    return holdingFire or (os.clock() - lastFire) < 0.25
end
local function myRoot()
    local char = localPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end
local function validTarget(p)
    if p == localPlayer then return nil end
    if settings.teamCheck and localPlayer.Team ~= nil and p.Team == localPlayer.Team then return nil end
    local char = p.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local part = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
    if not hum or hum.Health <= 0 or not part then return nil end
    return part
end
local function targetPart()
    local root = myRoot()
    if not root then return nil end
    local nearest, best = nil, settings.maxDistance
    for _, p in ipairs(Players:GetPlayers()) do
        local part = validTarget(p)
        if part then
            local distance = (part.Position - root.Position).Magnitude
            if distance < best then
                best = distance
                nearest = part
            end
        end
    end
    return nearest
end
local function playerCounts()
    local total, visible = 0, 0
    local origin = camera.CFrame.Position
    for _, p in ipairs(Players:GetPlayers()) do
        local part = validTarget(p)
        if part then
            total += 1
            local direction = part.Position - origin
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            local char = localPlayer.Character
            if char then params.FilterDescendantsInstances = {char} end
            checkingVisibility = true
            local hit = workspace:Raycast(origin, direction, params)
            checkingVisibility = false
            if not hit or hit.Instance:IsDescendantOf(part.Parent) then
                visible += 1
            end
        end
    end
    return total, visible
end
local function predictedPosition(part, origin)
    local position = part.Position
    if settings.prediction and settings.bulletSpeed > 1 then
        local travelTime = (position - origin).Magnitude / settings.bulletSpeed
        position += part.AssemblyLinearVelocity * math.clamp(travelTime, 0, 2)
    end
    return position
end

local gui = Instance.new("ScreenGui")
gui.Name = "OX1DE_SilentAim_Test"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10000
gui.Parent = localPlayer:WaitForChild("PlayerGui")
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromOffset(258, 198)
panel.Position = UDim2.fromOffset(24, 155)
panel.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
panel.BorderSizePixel = 0
panel.Active = true
panel.Draggable = true
panel.Parent = gui
local round = Instance.new("UICorner")
round.CornerRadius = UDim.new(0, 10)
round.Parent = panel
local function label(y, size, value, color)
    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromOffset(236, 28)
    text.Position = UDim2.fromOffset(11, y)
    text.BackgroundTransparency = 1
    text.Font = Enum.Font.GothamSemibold
    text.TextSize = size
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.TextColor3 = color or Color3.new(1, 1, 1)
    text.Text = value
    text.Parent = panel
    return text
end
label(7, 16, "OX1DE | SILENT AIM TEST")
local status = label(38, 13, "Loading hooks...")
local targetStatus = label(67, 12, "Target: none", Color3.fromRGB(170, 170, 185))
local countsStatus = label(94, 12, "Players: 0 | Visible: 0")
local hooksStatus = label(120, 11, "Shot hooks: 0 / 0")
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.fromOffset(236, 32)
toggle.Position = UDim2.fromOffset(11, 158)
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 13
toggle.TextColor3 = Color3.new(1, 1, 1)
toggle.BackgroundColor3 = Color3.fromRGB(40, 115, 65)
toggle.Text = "SILENT AIM: ON [RightAlt]"
toggle.Parent = panel
local tc = Instance.new("UICorner")
tc.CornerRadius = UDim.new(0, 6)
tc.Parent = toggle
local function refresh()
    toggle.Text = "SILENT AIM: " .. (settings.enabled and "ON" or "OFF") .. " [RightAlt]"
    toggle.BackgroundColor3 = settings.enabled and Color3.fromRGB(40,115,65) or Color3.fromRGB(115,48,48)
end
connect(toggle.MouseButton1Click, function()
    settings.enabled = not settings.enabled
    refresh()
end)
connect(UserInputService.InputBegan, function(input, processed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        holdingFire = true
        lastFire = os.clock()
    elseif input.KeyCode == Enum.KeyCode.RightAlt and not processed then
        settings.enabled = not settings.enabled
        refresh()
    end
end)
connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        holdingFire = false
        lastFire = os.clock()
    end
end)

local safeClosure = type(newcclosure) == "function" and newcclosure or function(f) return f end
local oldNamecall, oldIndex
local raycastAvailable = false
local mouseAvailable = false

-- Only change locally-generated gun-like rays while the fire button is pressed.
if type(hookmetamethod) == "function" and type(getnamecallmethod) == "function" and settings.hookRaycast then
    local ok = pcall(function()
        oldNamecall = hookmetamethod(game, "__namecall", safeClosure(function(self, ...)
            local method = getnamecallmethod()
            if alive and settings.enabled and not checkingVisibility and isFiring() and self == workspace and method == "Raycast"
                and not (type(checkcaller) == "function" and checkcaller()) then
                local args = table.pack(...)
                local origin, direction = args[1], args[2]
                if typeof(origin) == "Vector3" and typeof(direction) == "Vector3" and direction.Magnitude > 25 then
                    local root = myRoot()
                    if root and (origin - root.Position).Magnitude < 35 then
                        local part = targetPart()
                        if part then
                            diagnostics.raycast += 1
                            args[2] = (predictedPosition(part, origin) - origin).Unit * direction.Magnitude
                            return oldNamecall(self, table.unpack(args, 1, args.n))
                        end
                    end
                end
            end
            return oldNamecall(self, ...)
        end))
    end)
    raycastAvailable = ok
end

-- Some client weapons read Mouse.Hit or Mouse.Target to choose the shot endpoint.
if type(hookmetamethod) == "function" and settings.hookMouse then
    local ok = pcall(function()
        oldIndex = hookmetamethod(game, "__index", safeClosure(function(self, key)
            if alive and settings.enabled and isFiring() and self == mouse
                and not (type(checkcaller) == "function" and checkcaller()) then
                if key == "Hit" or key == "Target" then
                    local part = targetPart()
                    if part then
                        diagnostics.mouse += 1
                        if key == "Target" then return part end
                        local root = myRoot()
                        local origin = root and root.Position or camera.CFrame.Position
                        return CFrame.new(predictedPosition(part, origin))
                    end
                end
            end
            return oldIndex(self, key)
        end))
    end)
    mouseAvailable = ok
end

status.Text = string.format("Hooks: Raycast %s | Mouse %s",
    raycastAvailable and "YES" or "NO",
    mouseAvailable and "YES" or "NO")
status.TextColor3 = (raycastAvailable or mouseAvailable)
    and Color3.fromRGB(140, 240, 165)
    or Color3.fromRGB(255, 120, 110)
local lastUpdate = 0
connect(RunService.Heartbeat, function()
    if os.clock() - lastUpdate < 0.3 then return end
    lastUpdate = os.clock()
    if not alive then return end
    local part = settings.enabled and targetPart() or nil
    targetStatus.Text = part and ("Target: " .. part.Parent.Name) or "Target: none"
    local total, visible = playerCounts()
    countsStatus.Text = string.format("Players: %d | Visible: %d", total, visible)
    hooksStatus.Text = string.format("Redirect attempts: Ray %d / Mouse %d", diagnostics.raycast, diagnostics.mouse)
end)
_G.OX1DE_SILENT_STOP = function()
    alive = false
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    if gui then gui:Destroy() end
    -- Hooks remain installed but become harmless pass-through wrappers.
end
print("[OX1DE SilentAim] Loaded. Raycast hook:", raycastAvailable, "Mouse hook:", mouseAvailable)
