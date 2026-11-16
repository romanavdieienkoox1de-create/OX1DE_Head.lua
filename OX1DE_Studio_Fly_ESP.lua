-- OX1DE Studio Utilities - CLEAN
-- Only: Fly, NoClip, Player ESP/Nickname, Pumpkin ESP

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local fly = false
local noclip = false
local flySpeed = 55

local bodyVelocity
local bodyGyro
local labels = {}

local function getCharacter()
    return player.Character
end

local function restoreCharacter()
    local char = getCharacter()
    if not char then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")

    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
    if bodyGyro then
        bodyGyro:Destroy()
        bodyGyro = nil
    end

    -- restore normal Roblox character controls after older versions of this script
    if hum then
        hum.PlatformStand = false
        hum.AutoRotate = true
        hum.Sit = false
        hum:ChangeState(Enum.HumanoidStateType.Running)
    end
    if root then
        root.AssemblyAngularVelocity = Vector3.zero
    end
end

-- clean up any bad state left by an older version
restoreCharacter()

local function stopFly()
    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
    if bodyGyro then
        bodyGyro:Destroy()
        bodyGyro = nil
    end

    local char = getCharacter()
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.PlatformStand = false
        hum.AutoRotate = true
        hum:ChangeState(Enum.HumanoidStateType.Running)
    end
end

local function startFly()
    stopFly()

    local char = getCharacter()
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then
        fly = false
        return
    end

    hum.PlatformStand = true
    hum.AutoRotate = false

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Name = "OX1DE_FlyVelocity"
    bodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.Parent = root

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.Name = "OX1DE_FlyGyro"
    bodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    bodyGyro.P = 20000
    bodyGyro.CFrame = root.CFrame
    bodyGyro.Parent = root
end

local function addMarker(target, color, textValue)
    if labels[target] then return end
    if not (target:IsA("Model") or target:IsA("BasePart")) then return end

    local adornee
    if target:IsA("Model") then
        adornee = target:FindFirstChild("Head") or target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
    else
        adornee = target
    end
    if not adornee then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "OX1DE_Marker"
    highlight.Adornee = target
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = color
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = target

    local gui = Instance.new("BillboardGui")
    gui.Name = "OX1DE_Label"
    gui.Adornee = adornee
    gui.Size = UDim2.fromOffset(220, 36)
    gui.StudsOffsetWorldSpace = Vector3.new(0, 2.8, 0)
    gui.AlwaysOnTop = true
    gui.Parent = adornee

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0.25
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.Text = textValue
    label.Parent = gui

    labels[target] = {highlight, gui}
end

local function setupPlayer(p)
    if p == player then return end

    local function onCharacter(char)
        task.wait(0.2)
        addMarker(char, Color3.fromRGB(0, 255, 130), p.DisplayName)
    end

    p.CharacterAdded:Connect(onCharacter)
    if p.Character then
        task.spawn(onCharacter, p.Character)
    end
end

for _, p in ipairs(Players:GetPlayers()) do
    setupPlayer(p)
end
Players.PlayerAdded:Connect(setupPlayer)

local function checkPumpkin(obj)
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return end

    local name = obj.Name:lower()
    if name:find("pumpkin", 1, true) or name:find("тыква", 1, true) then
        addMarker(obj, Color3.fromRGB(255, 155, 0), "Тыква")
    end
end

for _, obj in ipairs(Workspace:GetDescendants()) do
    checkPumpkin(obj)
end
Workspace.DescendantAdded:Connect(checkPumpkin)

UIS.InputBegan:Connect(function(input, processed)
    if processed or UIS:GetFocusedTextBox() then return end

    if input.KeyCode == Enum.KeyCode.X then
        fly = not fly
        if fly then
            startFly()
        else
            stopFly()
        end
    elseif input.KeyCode == Enum.KeyCode.Z then
        noclip = not noclip
    end
end)

RunService.RenderStepped:Connect(function()
    local char = getCharacter()
    if not char then return end

    if noclip then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end

    if fly and bodyVelocity and bodyGyro then
        local direction = Vector3.zero
        local cf = camera.CFrame

        if UIS:IsKeyDown(Enum.KeyCode.W) then direction += cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then direction -= cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then direction += cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then direction -= cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then direction += Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then direction -= Vector3.yAxis end

        bodyVelocity.Velocity = direction.Magnitude > 0 and direction.Unit * flySpeed or Vector3.zero
        bodyGyro.CFrame = cf
    end
end)

player.CharacterAdded:Connect(function()
    fly = false
    noclip = false
    bodyVelocity = nil
    bodyGyro = nil
    task.wait(0.3)
    restoreCharacter()
end)

-- X = Fly
-- Z = NoClip
