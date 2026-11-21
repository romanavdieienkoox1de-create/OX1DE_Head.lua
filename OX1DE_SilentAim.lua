-- OX1DE Silent Aim | experimental client-side module + screen FOV
-- Experimental: client hook attempts are NOT confirmed hits.
-- Works only if the experience actually uses these client-side shot APIs.

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
    fovRadius = 150, -- circle radius in screen pixels (30..400)
    showFov = true,
    visibilityCheck = true,
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
-- Check line of sight without allowing our own raycast hook to intercept it.
local function visibleTarget(part)
    local cam = workspace.CurrentCamera
    if not cam then return false end
    local origin = cam.CFrame.Position
    local direction = part.Position - origin
    if direction.Magnitude < 0.01 then return true end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local char = localPlayer.Character
    if char then params.FilterDescendantsInstances = {char} end

    checkingVisibility = true
    local ok, hit = pcall(function()
        return workspace:Raycast(origin, direction, params)
    end)
    checkingVisibility = false
    return ok and (not hit or hit.Instance:IsDescendantOf(part.Parent))
end

-- Select by screen distance to the center of the crosshair, not world distance.
local function targetPart()
    local root = myRoot()
    local cam = workspace.CurrentCamera
    if not root or not cam then return nil end
    local view = cam.ViewportSize
    local screenCenter = Vector2.new(view.X * 0.5, view.Y * 0.5)
    local nearest, bestPixels = nil, settings.fovRadius

    for _, p in ipairs(Players:GetPlayers()) do
        local part = validTarget(p)
        if part and (part.Position - root.Position).Magnitude <= settings.maxDistance then
            local screen, onScreen = cam:WorldToViewportPoint(part.Position)
            if onScreen and screen.Z > 0 then
                local pixels = (Vector2.new(screen.X, screen.Y) - screenCenter).Magnitude
                if pixels <= bestPixels and (not settings.visibilityCheck or visibleTarget(part)) then
                    bestPixels = pixels
                    nearest = part
                end
            end
        end
    end
    return nearest
end
local function playerCounts()
    local total, visible = 0, 0
    local cam = workspace.CurrentCamera
    if not cam then return 0, 0 end
    local origin = cam.CFrame.Position
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
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10000
gui.Parent = localPlayer:WaitForChild("PlayerGui")
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromOffset(258, 304)
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
local hooksStatus = label(120, 11, "Redirect attempts: 0 / 0")
label(136, 10, "Attempts are not confirmed hits.", Color3.fromRGB(245, 179, 110))
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
-- Visible crosshair-centered FOV ring; this is only a target-selection display.
local fovRing = Instance.new("Frame")
fovRing.Name = "FOV_Ring"
fovRing.AnchorPoint = Vector2.new(0.5, 0.5)
fovRing.Position = UDim2.fromScale(0.5, 0.5)
fovRing.BackgroundTransparency = 1
fovRing.BorderSizePixel = 0
fovRing.Active = false
fovRing.Parent = gui
local ringCorner = Instance.new("UICorner")
ringCorner.CornerRadius = UDim.new(1, 0)
ringCorner.Parent = fovRing
local ringStroke = Instance.new("UIStroke")
ringStroke.Color = Color3.fromRGB(114, 217, 156)
ringStroke.Thickness = 1.5
ringStroke.Transparency = 0.15
ringStroke.Parent = fovRing

local fovText = label(196, 12, "FOV: 150 px", Color3.fromRGB(190, 205, 210))
local fovTrack = Instance.new("Frame")
fovTrack.Name = "FOV_Slider"
fovTrack.Size = UDim2.fromOffset(236, 9)
fovTrack.Position = UDim2.fromOffset(11, 233)
fovTrack.BackgroundColor3 = Color3.fromRGB(59, 63, 78)
fovTrack.BorderSizePixel = 0
fovTrack.Active = true
fovTrack.Parent = panel
local trackCorner = Instance.new("UICorner")
trackCorner.CornerRadius = UDim.new(1, 0)
trackCorner.Parent = fovTrack
local fovFill = Instance.new("Frame")
fovFill.BackgroundColor3 = Color3.fromRGB(114, 217, 156)
fovFill.BorderSizePixel = 0
fovFill.Size = UDim2.fromScale(0, 1)
fovFill.Parent = fovTrack
local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = fovFill
local fovSwitch = Instance.new("TextButton")
fovSwitch.Size = UDim2.fromOffset(236, 28)
fovSwitch.Position = UDim2.fromOffset(11, 257)
fovSwitch.BackgroundColor3 = Color3.fromRGB(37, 44, 54)
fovSwitch.TextColor3 = Color3.new(1, 1, 1)
fovSwitch.Font = Enum.Font.GothamSemibold
fovSwitch.TextSize = 12
fovSwitch.Parent = panel
local switchCorner = Instance.new("UICorner")
switchCorner.CornerRadius = UDim.new(0, 6)
switchCorner.Parent = fovSwitch

local function updateFov()
    settings.fovRadius = math.clamp(math.floor(settings.fovRadius + 0.5), 30, 400)
    fovText.Text = string.format("FOV: %d px (30-400)", settings.fovRadius)
    fovFill.Size = UDim2.fromScale((settings.fovRadius - 30) / 370, 1)
    fovRing.Size = UDim2.fromOffset(settings.fovRadius * 2, settings.fovRadius * 2)
    fovRing.Visible = settings.showFov
    fovSwitch.Text = "SHOW FOV CIRCLE: " .. (settings.showFov and "ON" or "OFF")
end
updateFov()
connect(fovSwitch.MouseButton1Click, function()
    settings.showFov = not settings.showFov
    updateFov()
end)
local sliding = false
local function slideTo(x)
    local width = fovTrack.AbsoluteSize.X
    if width <= 0 then return end
    local ratio = math.clamp((x - fovTrack.AbsolutePosition.X) / width, 0, 1)
    settings.fovRadius = 30 + 370 * ratio
    updateFov()
end
connect(fovTrack.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        sliding = true
        slideTo(input.Position.X)
    end
end)
connect(UserInputService.InputChanged, function(input)
    if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or
                    input.UserInputType == Enum.UserInputType.Touch) then
        slideTo(input.Position.X)
    end
end)
connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        sliding = false
    end
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

status.Text = string.format("Client hooks: Raycast %s | Mouse %s",
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
