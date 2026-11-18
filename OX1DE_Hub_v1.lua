-- OX1DE Hub v1.0 | Roblox LocalScript (your own experience)
-- G = toggle menu/cursor | X = Fly | Z = NoClip
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local state = {esp = true, pumpkins = false, fly = false, noclip = false, menu = true}
local conns, playerTags, pumpkinTags, originalCollisions = {}, {}, {}, {}
local flyVelocity, flyGyro, previousAutoRotate = nil, nil, nil
local active = true
local env = (type(getgenv) == "function" and getgenv()) or shared
if env.OX1DE_HUB_CLEANUP then pcall(env.OX1DE_HUB_CLEANUP) end
local function on(signal, callback)
    local conn = signal:Connect(callback)
    table.insert(conns, conn)
    return conn
end
local function destroyTag(t)
    if t then
        if t.h then t.h:Destroy() end
        if t.b then t.b:Destroy() end
    end
end
local function stopFly()
    if flyVelocity then flyVelocity:Destroy(); flyVelocity = nil end
    if flyGyro then flyGyro:Destroy(); flyGyro = nil end
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and previousAutoRotate ~= nil then hum.AutoRotate = previousAutoRotate end
    previousAutoRotate = nil
end
local function startFly()
    stopFly()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then state.fly = false; return end
    previousAutoRotate = hum.AutoRotate
    hum.AutoRotate = false
    flyVelocity = Instance.new("BodyVelocity")
    flyVelocity.Name = "OX1DE_FlyVelocity"
    flyVelocity.MaxForce = Vector3.new(1e9,1e9,1e9)
    flyVelocity.P = 12000
    flyVelocity.Velocity = Vector3.zero
    flyVelocity.Parent = root
    flyGyro = Instance.new("BodyGyro")
    flyGyro.Name = "OX1DE_FlyGyro"
    flyGyro.MaxTorque = Vector3.new(1e9,1e9,1e9)
    flyGyro.P = 16000
    flyGyro.CFrame = camera.CFrame
    flyGyro.Parent = root
end
local function restoreCollision()
    for part, old in pairs(originalCollisions) do
        if part and part.Parent then pcall(function() part.CanCollide = old end) end
    end
    table.clear(originalCollisions)
end
local existing = player:WaitForChild("PlayerGui"):FindFirstChild("OX1DE_Hub")
if existing then existing:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "OX1DE_Hub"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player.PlayerGui
local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(236, 280)
frame.Position = UDim2.new(0, 18, 0.5, -140)
frame.BackgroundColor3 = Color3.fromRGB(16,17,23)
frame.BorderSizePixel = 0
frame.Parent = gui
local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0,11); corner.Parent = frame
local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(62,64,80); stroke.Thickness = 1; stroke.Parent = frame
local header = Instance.new("TextLabel")
header.Size = UDim2.new(1,-16,0,40)
header.Position = UDim2.fromOffset(8,0)
header.BackgroundTransparency = 1
header.Text = "OX1DE  |  HUB"
header.TextColor3 = Color3.fromRGB(240,243,248)
header.TextSize = 17
header.Font = Enum.Font.GothamBold
header.TextXAlignment = Enum.TextXAlignment.Left
header.Active = true
header.Parent = frame
local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1,-20,0,24)
hint.Position = UDim2.fromOffset(10,245)
hint.BackgroundTransparency = 1
hint.Text = "G  Menu    X  Fly    Z  NoClip"
hint.Font = Enum.Font.Gotham
hint.TextSize = 11
hint.TextColor3 = Color3.fromRGB(162,169,184)
hint.Parent = frame
local buttons = {}
local function addButton(key, label, y)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,-20,0,43)
    btn.Position = UDim2.fromOffset(10,y)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    btn.Parent = frame
    local round = Instance.new("UICorner"); round.CornerRadius=UDim.new(0,7); round.Parent=btn
    buttons[key] = {button=btn,label=label}
    return btn
end
addButton("esp","Player ESP + Names",46)
addButton("pumpkins","Pumpkin ESP",94)
addButton("fly","Fly",142)
addButton("noclip","NoClip",190)
local function updateButtons()
    for key, entry in pairs(buttons) do
        local enabled = state[key]
        entry.button.Text = entry.label .. (enabled and "     ON" or "     OFF")
        entry.button.BackgroundColor3 = enabled and Color3.fromRGB(28,72,58) or Color3.fromRGB(35,37,47)
        entry.button.TextColor3 = enabled and Color3.fromRGB(137,255,199) or Color3.fromRGB(214,217,225)
    end
end
local function setFly(v)
    state.fly = v
    if v then startFly() else stopFly() end
    updateButtons()
end
local function setNoclip(v)
    state.noclip = v
    if not v then restoreCollision() end
    updateButtons()
end
local function newTag(obj, adornee, color)
    local h = Instance.new("Highlight")
    h.Name = "OX1DE_ESP"
    h.Adornee = obj
    h.FillTransparency = 0.86
    h.FillColor = color
    h.OutlineTransparency = 0
    h.OutlineColor = color
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = gui
    local b = Instance.new("BillboardGui")
    b.Name = "OX1DE_Name"
    b.Adornee = adornee
    b.Size = UDim2.fromOffset(225,45)
    b.StudsOffsetWorldSpace = Vector3.new(0,2.4,0)
    b.AlwaysOnTop = true
    b.Parent = gui
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1,1)
    label.BackgroundTransparency = 1
    label.TextColor3 = color
    label.TextStrokeColor3 = Color3.new(0,0,0)
    label.TextStrokeTransparency = 0.1
    label.TextSize = 13
    label.Font = Enum.Font.GothamBold
    label.Parent = b
    return {h=h,b=b,label=label,adornee=adornee}
end
local function updatePlayerESP()
    local character = player.Character
    local myRoot = character and character:FindFirstChild("HumanoidRootPart")
    for p,t in pairs(playerTags) do
        if not state.esp or not p.Parent or p.Character ~= t.model or not t.model.Parent then
            destroyTag(t); playerTags[p] = nil
        end
    end
    if not state.esp then return end
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            local c = p.Character
            local root = c and c:FindFirstChild("HumanoidRootPart")
            local head = c and (c:FindFirstChild("Head") or root)
            if c and root and head and not playerTags[p] then
                local t = newTag(c,head,Color3.fromRGB(96,255,157))
                t.model = c
                playerTags[p] = t
            end
            local t = playerTags[p]
            if t and root then
                local dist = myRoot and math.floor((myRoot.Position-root.Position).Magnitude+0.5) or 0
                t.label.Text = p.DisplayName .. "  @" .. p.Name .. "\n" .. dist .. " studs"
            end
        end
    end
end
local function isPumpkin(obj)
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return false end
    local n = obj.Name:lower()
    return n:find("pumpkin",1,true) ~= nil or n:find("тыква",1,true) ~= nil or n:find("pump",1,true) == 1
end
local function updatePumpkinESP()
    for obj,t in pairs(pumpkinTags) do
        if not state.pumpkins or not obj.Parent or not t.adornee.Parent then
            destroyTag(t); pumpkinTags[obj] = nil
        end
    end
    if not state.pumpkins then return end
    for _,obj in ipairs(workspace:GetDescendants()) do
        if isPumpkin(obj) and not pumpkinTags[obj] then
            local adorn = obj:IsA("BasePart") and obj or (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart",true))
            if adorn then
                local t = newTag(obj,adorn,Color3.fromRGB(255,171,60))
                t.label.Text = "🎃 Pumpkin"
                pumpkinTags[obj] = t
            end
        end
    end
end
on(buttons.esp.button.MouseButton1Click, function() state.esp = not state.esp; updateButtons(); updatePlayerESP() end)
on(buttons.pumpkins.button.MouseButton1Click, function() state.pumpkins = not state.pumpkins; updateButtons(); updatePumpkinESP() end)
on(buttons.fly.button.MouseButton1Click, function() setFly(not state.fly) end)
on(buttons.noclip.button.MouseButton1Click, function() setNoclip(not state.noclip) end)
-- Drag the menu by its header.
local dragging, dragStart, frameStart = false,nil,nil
on(header.InputBegan,function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; frameStart = frame.Position
    end
end)
on(UIS.InputEnded,function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging=false end
end)
on(UIS.InputChanged,function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position-dragStart
        frame.Position = UDim2.new(frameStart.X.Scale,frameStart.X.Offset+d.X,frameStart.Y.Scale,frameStart.Y.Offset+d.Y)
    end
end)
on(UIS.InputBegan,function(input, processed)
    if processed or UIS:GetFocusedTextBox() then return end
    if input.KeyCode == Enum.KeyCode.G then
        state.menu = not state.menu
        frame.Visible = state.menu
        if state.menu then UIS.MouseBehavior = Enum.MouseBehavior.Default; UIS.MouseIconEnabled = true end
    elseif input.KeyCode == Enum.KeyCode.X then
        setFly(not state.fly)
    elseif input.KeyCode == Enum.KeyCode.Z then
        setNoclip(not state.noclip)
    end
end)
on(RunService.Stepped,function()
    if not active or not state.noclip then return end
    local c = player.Character
    if c then
        for _,part in ipairs(c:GetDescendants()) do
            if part:IsA("BasePart") then
                if originalCollisions[part] == nil then originalCollisions[part]=part.CanCollide end
                part.CanCollide = false
            end
        end
    end
end)
on(RunService.RenderStepped,function()
    if state.menu then
        UIS.MouseBehavior = Enum.MouseBehavior.Default
        UIS.MouseIconEnabled = true
    end
    if state.fly and flyVelocity and flyGyro then
        local cam = workspace.CurrentCamera
        local cf = cam.CFrame
        local dir = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis end
        flyVelocity.Velocity = dir.Magnitude > 0 and dir.Unit*55 or Vector3.zero
        flyGyro.CFrame = cf
    end
end)
on(player.CharacterAdded,function()
    stopFly()
    state.fly=false
    state.noclip=false
    table.clear(originalCollisions)
    updateButtons()
end)
local tickCounter = 0
on(RunService.Heartbeat,function(dt)
    tickCounter += dt
    if tickCounter < 0.3 then return end
    tickCounter=0
    updatePlayerESP()
end)
local pumpkinCounter = 0
on(RunService.Heartbeat,function(dt)
    if not state.pumpkins then return end
    pumpkinCounter += dt
    if pumpkinCounter < 2 then return end
    pumpkinCounter=0
    updatePumpkinESP()
end)
env.OX1DE_HUB_CLEANUP = function()
    active=false
    stopFly()
    restoreCollision()
    for _,c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    for _,t in pairs(playerTags) do destroyTag(t) end
    for _,t in pairs(pumpkinTags) do destroyTag(t) end
    if gui then gui:Destroy() end
end
updateButtons()
updatePlayerESP()
