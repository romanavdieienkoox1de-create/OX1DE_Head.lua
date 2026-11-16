-- OX1DE Studio Utilities
-- LocalScript in StarterPlayer > StarterPlayerScripts (for your own Roblox experience)
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local fly, noclip = false, false
local speed = 55
local velocity, gyro
local labels = {}
local function character() return player.Character end
local function destroyFlightForces()
    if velocity then velocity:Destroy(); velocity=nil end
    if gyro then gyro:Destroy(); gyro=nil end
end

local function clearFlight()
    destroyFlightForces()
    local c=character()
    local h=c and c:FindFirstChildOfClass("Humanoid")
    local root=c and c:FindFirstChild("HumanoidRootPart")
    if root then
        root.AssemblyLinearVelocity=Vector3.zero
        root.AssemblyAngularVelocity=Vector3.zero
    end
    if h then
        h.PlatformStand=false
        h.AutoRotate=true
        h.Sit=false
        h:ChangeState(Enum.HumanoidStateType.GettingUp)
        task.defer(function()
            if h.Parent and not fly then
                h:ChangeState(Enum.HumanoidStateType.Running)
            end
        end)
    end
end
local function beginFlight()
    destroyFlightForces()
    local c=character()
    local root=c and c:FindFirstChild("HumanoidRootPart")
    local h=c and c:FindFirstChildOfClass("Humanoid")
    if not root or not h then fly=false; return end
    h.PlatformStand=true
    h.AutoRotate=false
    h:ChangeState(Enum.HumanoidStateType.Physics)
    velocity=Instance.new("BodyVelocity")
    velocity.MaxForce=Vector3.new(1e9,1e9,1e9)
    velocity.Velocity=Vector3.zero
    velocity.Parent=root
    gyro=Instance.new("BodyGyro")
    gyro.MaxTorque=Vector3.new(1e9,1e9,1e9)
    gyro.P=20000
    gyro.CFrame=root.CFrame
    gyro.Parent=root
end
local function addMarker(target, color, textValue)
    if labels[target] or not target:IsA("Model") and not target:IsA("BasePart") then return end
    local adornee=target:IsA("Model") and (target:FindFirstChild("Head") or target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")) or target
    if not adornee then return end
    local highlight=Instance.new("Highlight")
    highlight.Name="OX1DE_Marker"
    highlight.Adornee=target
    highlight.FillTransparency=1
    highlight.OutlineTransparency=0
    highlight.OutlineColor=color
    highlight.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent=target
    local gui=Instance.new("BillboardGui")
    gui.Name="OX1DE_Label"
    gui.Adornee=adornee
    gui.Size=UDim2.fromOffset(220,36)
    gui.StudsOffsetWorldSpace=Vector3.new(0,2.8,0)
    gui.AlwaysOnTop=true
    gui.Parent=adornee
    local label=Instance.new("TextLabel")
    label.Size=UDim2.fromScale(1,1)
    label.BackgroundTransparency=1
    label.TextColor3=Color3.new(1,1,1)
    label.TextStrokeTransparency=0.25
    label.Font=Enum.Font.GothamBold
    label.TextSize=14
    label.Text=textValue
    label.Parent=gui
    labels[target]={highlight,gui}
end
local function refreshPlayer(p)
    if p==player then return end
    local function onCharacter(c)
        task.wait(0.2)
        addMarker(c,Color3.fromRGB(0,255,130),p.DisplayName)
    end
    p.CharacterAdded:Connect(onCharacter)
    if p.Character then task.spawn(onCharacter,p.Character) end
end
for _,p in ipairs(Players:GetPlayers()) do refreshPlayer(p) end
Players.PlayerAdded:Connect(refreshPlayer)
local function checkPumpkin(obj)
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return end
    local name=obj.Name:lower()
    if name:find("pumpkin",1,true) or name:find("тыква",1,true) then
        addMarker(obj,Color3.fromRGB(255,155,0),"🎃 Тыква")
    end
end
for _,obj in ipairs(Workspace:GetDescendants()) do checkPumpkin(obj) end
Workspace.DescendantAdded:Connect(checkPumpkin)
UIS.InputBegan:Connect(function(input,processed)
    if processed or UIS:GetFocusedTextBox() then return end
    if input.KeyCode==Enum.KeyCode.X then
        fly=not fly
        if fly then beginFlight() else clearFlight() end
    elseif input.KeyCode==Enum.KeyCode.Z then
        noclip=not noclip
    end
end)
RunService.RenderStepped:Connect(function()
    local c=character()
    if not c then return end
    if noclip then
        for _,part in ipairs(c:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide=false end
        end
    end
    if fly and velocity and gyro then
        local direction=Vector3.zero
        local cf=camera.CFrame
        if UIS:IsKeyDown(Enum.KeyCode.W) then direction+=cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then direction-=cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then direction+=cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then direction-=cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then direction+=Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then direction-=Vector3.yAxis end
        velocity.Velocity=direction.Magnitude>0 and direction.Unit*speed or Vector3.zero
        gyro.CFrame=cf
        local h=c:FindFirstChildOfClass("Humanoid")
        if h and not h.PlatformStand then
            h.PlatformStand=true
            h:ChangeState(Enum.HumanoidStateType.Physics)
        end
    end
end)
player.CharacterAdded:Connect(function()
    fly=false
    noclip=false
    clearFlight()
end)

-- X: Fly, Z: NoClip. S is normal backwards movement.
-- In Studio, the server may override character movement; this script cannot defeat server correction.
