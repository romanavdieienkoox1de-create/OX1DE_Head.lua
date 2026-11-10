--[[
    OX1DE Cheating | Violence District (unofficial prototype)
    UI + best-effort local ESP/movement. Not a verified Violence District exploit.
    Use as a LocalScript in StarterPlayer > StarterPlayerScripts in your own
    Roblox Studio test place. Actual game object paths/role data are unknown.

    Implemented: player ESP (nickname, approximate metres, white outline),
    generators ESP (name heuristic), pumpkin ESP with hide on destroy/inactive,
    local NoClip and Fly. Missing game-specific integration: auto skill checks,
    instant generator completion, unlimited stamina, fast window/pallet vault.
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

if type(_G.OX1DE_CHEATING_STOP) == "function" then
    pcall(_G.OX1DE_CHEATING_STOP)
end
local existing = PlayerGui:FindFirstChild("OX1DE_Cheating")
if existing then existing:Destroy() end

local C = {
    BG = Color3.fromRGB(13, 15, 19),
    PANEL = Color3.fromRGB(20, 23, 29),
    ITEM = Color3.fromRGB(28, 32, 40),
    STROKE = Color3.fromRGB(53, 59, 69),
    FG = Color3.fromRGB(244, 247, 250),
    MUTED = Color3.fromRGB(151, 158, 171),
    LIME = Color3.fromRGB(151, 255, 88),
    RED = Color3.fromRGB(255, 79, 99),
    ORANGE = Color3.fromRGB(255, 158, 48),
    CYAN = Color3.fromRGB(100, 215, 244),
    WHITE = Color3.fromRGB(255, 255, 255),
    UNKNOWN = Color3.fromRGB(198, 202, 209),
}

local state = {
    players = true,
    generators = true,
    pumpkins = true,
    noclip = false,
    fly = false,
}
local active = true
local playerFx, worldFx = {}, {}
local oldCollisions = setmetatable({}, { __mode = "k" })
local flyVelocity, flyGyro
local climbUp, climbDown = false, false
local connections = {}

local function connect(signal, fn)
    local conn = signal:Connect(fn)
    table.insert(connections, conn)
    return conn
end
local function prop(className, parent, values)
    local inst = Instance.new(className)
    for name, value in pairs(values or {}) do inst[name] = value end
    inst.Parent = parent
    return inst
end
local function corner(parent, radius)
    return prop("UICorner", parent, {CornerRadius = UDim.new(0, radius or 11)})
end
local function border(parent, color, transparency)
    return prop("UIStroke", parent, {Color = color or C.STROKE, Thickness = 1, Transparency = transparency or 0})
end
local function tween(inst, time, values)
    TweenService:Create(inst, TweenInfo.new(time or .2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), values):Play()
end
local function safeName(inst)
    return string.lower(inst.Name)
end
local function metres(from, to)
    return math.floor((from - to).Magnitude / 3.57 + .5) -- approximate studs -> m
end
local function myRoot()
    local ch = LocalPlayer.Character
    return ch and ch:FindFirstChild("HumanoidRootPart")
end
local function basePart(model)
    if model:IsA("BasePart") then return model end
    if model:IsA("Model") then
        return model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end
local function isInPlayerModel(instance)
    local cursor = instance
    while cursor and cursor ~= Workspace do
        if cursor:IsA("Model") and Players:GetPlayerFromCharacter(cursor) then
            return true
        end
        cursor = cursor.Parent
    end
    return false
end
local function readFlag(inst, flags)
    for _, name in ipairs(flags) do
        local a = inst:GetAttribute(name)
        if a ~= nil then return a end
        local value = inst:FindFirstChild(name)
        if value and value:IsA("ValueBase") then return value.Value end
    end
    return nil
end
local function inactiveWorldObject(inst, kind)
    if not inst or not inst.Parent or not inst:IsDescendantOf(Workspace) then return true end
    if kind == "pumpkins" then
        if readFlag(inst, {"Collected", "IsCollected", "Destroyed", "Smashed", "Broken"}) == true then return true end
        if readFlag(inst, {"Active", "IsActive"}) == false then return true end
        local exists = false
        for _, desc in ipairs(inst:IsA("BasePart") and {inst} or inst:GetDescendants()) do
            if desc:IsA("BasePart") and desc.Transparency < .98 then exists = true break end
        end
        return not exists
    end
    if kind == "generators" then
        return readFlag(inst, {"Completed", "IsCompleted", "Repaired", "IsRepaired"}) == true
    end
    return false
end
local function roleFor(player)
    local character = player.Character
    for _, obj in ipairs({player, character or player}) do
        local marker = readFlag(obj, {"IsKiller", "IsMurderer", "Killer"})
        if marker == true then return "killer" end
        if marker == false then return "survivor" end
    end
    local candidates = {}
    if player.Team then table.insert(candidates, player.Team.Name) end
    for _, obj in ipairs({player, character}) do
        if obj then
            for _, attr in ipairs({"Role", "CurrentRole", "TeamRole", "PlayerRole"}) do
                local v = obj:GetAttribute(attr)
                if type(v) == "string" then table.insert(candidates, v) end
            end
            for _, childName in ipairs({"Role", "CurrentRole", "TeamRole"}) do
                local v = obj:FindFirstChild(childName)
                if v and v:IsA("StringValue") then table.insert(candidates, v.Value) end
            end
        end
    end
    for _, label in ipairs(candidates) do
        local s = string.lower(label)
        if s:find("killer", 1, true) or s:find("murder", 1, true)
           or s:find("hunter", 1, true) or s:find("maniac", 1, true) then
            return "killer"
        end
        if s:find("surviv", 1, true) or s:find("victim", 1, true)
           or s:find("escape", 1, true) then
            return "survivor"
        end
    end
    return "unknown" -- never guess the killer; unknown role = grey
end

-- GUI ----------------------------------------------------------------------
local gui = prop("ScreenGui", PlayerGui, {
    Name = "OX1DE_Cheating", ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true,
})
local window = prop("Frame", gui, {
    Name="Window", Size=UDim2.fromOffset(574, 435),
    Position=UDim2.new(.5,-287,.5,-218),
    BackgroundColor3=C.BG, BorderSizePixel=0, ClipsDescendants=true,
})
corner(window, 17)
border(window)
local shade = prop("Frame", window, {
    Size=UDim2.new(1,0,0,5), Position=UDim2.fromOffset(0,0),
    BackgroundColor3=C.LIME, BorderSizePixel=0,
})
local scale = prop("UIScale",window,{Scale=1})
local function adjustScale()
    local cam = Workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(700,800)
    scale.Scale = math.min(1, math.max(.55, math.min((vp.X-26)/574,(vp.Y-44)/435)))
end
adjustScale()
connect(Workspace:GetPropertyChangedSignal("CurrentCamera"), adjustScale)
if Workspace.CurrentCamera then connect(Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), adjustScale) end

local titleBar = prop("Frame",window, {
    Name="DragArea",Active=true,Position=UDim2.fromOffset(22,19),Size=UDim2.new(1,-44,0,55),
    BackgroundTransparency=1,
})
local title = prop("TextLabel",titleBar, {
    BackgroundTransparency=1,Size=UDim2.fromOffset(360,29),
    Font=Enum.Font.GothamBold,TextSize=25,TextColor3=C.FG,TextXAlignment=Enum.TextXAlignment.Left,
    Text="OX1DE Cheating",
})
prop("TextLabel",titleBar, {
    BackgroundTransparency=1,Position=UDim2.fromOffset(1,31),Size=UDim2.fromOffset(400,17),
    Font=Enum.Font.Gotham,TextSize=11,TextColor3=C.MUTED,TextXAlignment=Enum.TextXAlignment.Left,
    Text="VIOLENCE DISTRICT  /  ESP & MOVEMENT",
})
local hideBtn = prop("TextButton",titleBar, {
    Position=UDim2.new(1,-35,0,1),Size=UDim2.fromOffset(33,33),
    BackgroundColor3=C.ITEM,TextColor3=C.FG,Text="—",TextSize=18,
    Font=Enum.Font.GothamBold,AutoButtonColor=false,BorderSizePixel=0,
})
corner(hideBtn,9)

local content = prop("Frame",window, {
    BackgroundTransparency=1,Position=UDim2.fromOffset(20,86),Size=UDim2.new(1,-40,1,-103)
})
local sidebar = prop("Frame", content,{
    BackgroundColor3=C.PANEL,Size=UDim2.fromOffset(134,326),BorderSizePixel=0,
})
corner(sidebar,12)
local pageArea = prop("Frame",content, {
    BackgroundColor3=C.PANEL,Position=UDim2.fromOffset(148,0),
    Size=UDim2.new(1,-148,1,0),BorderSizePixel=0,ClipsDescendants=true,
})
corner(pageArea,12)

local navButtons = {}
local panels = {}
local currentTab
local function makeTab(name, caption, index)
    local nav = prop("TextButton",sidebar,{
        Size=UDim2.new(1,-16,0,42),Position=UDim2.fromOffset(8,12+(index-1)*50),
        BackgroundColor3=C.ITEM,BackgroundTransparency=1,
        Text=name,TextSize=13,Font=Enum.Font.GothamMedium,
        TextColor3=C.MUTED,AutoButtonColor=false,BorderSizePixel=0,
    })
    corner(nav,9)
    navButtons[name] = nav
    local panel = prop("ScrollingFrame",pageArea,{
        Name=name,Position=UDim2.fromOffset(8,9),Size=UDim2.new(1,-16,1,-18),
        CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,
        ScrollBarThickness=3,ScrollBarImageColor3=C.STROKE,
        BorderSizePixel=0,BackgroundTransparency=1,Visible=false,
    })
    prop("UIPadding",panel,{
        PaddingTop=UDim.new(0,2),PaddingBottom=UDim.new(0,6),
        PaddingLeft=UDim.new(0,3),PaddingRight=UDim.new(0,7),
    })
    prop("UIListLayout",panel,{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder})
    panels[name]=panel
    connect(nav.MouseButton1Click,function()
        if currentTab==name then return end
        currentTab=name
        for n,b in pairs(navButtons) do
            tween(b,.16,{
                BackgroundTransparency=n==name and 0 or 1,
                TextColor3=n==name and C.LIME or C.MUTED,
            })
            panels[n].Visible=(n==name)
        end
        panel.CanvasPosition=Vector2.new(0,0)
    end)
    return panel
end
local espPanel = makeTab("ESP", "ПОДСВЕТКА", 1)
local mainPanel = makeTab("Основное", "ДВИЖЕНИЕ", 2)

local function section(parent,labelText,order)
    local label=prop("TextLabel",parent,{
        LayoutOrder=order,BackgroundTransparency=1,Size=UDim2.new(1,0,0,23),
        Text=labelText,TextXAlignment=Enum.TextXAlignment.Left,
        Font=Enum.Font.GothamBold,TextSize=12,TextColor3=C.MUTED,
    })
    return label
end
local toggles={}
local function toggleRow(parent,text1,desc,key,order,onChanged)
    local row=prop("TextButton",parent,{
        LayoutOrder=order,Size=UDim2.new(1,0,0,58),BackgroundColor3=C.ITEM,
        BorderSizePixel=0,Text="",AutoButtonColor=false,
    })
    corner(row,10)
    prop("TextLabel",row,{
        BackgroundTransparency=1,Position=UDim2.fromOffset(13,9),Size=UDim2.new(1,-81,0,20),
        Font=Enum.Font.GothamBold,TextSize=13,TextColor3=C.FG,TextXAlignment=Enum.TextXAlignment.Left,
        Text=text1,
    })
    prop("TextLabel",row,{
        BackgroundTransparency=1,Position=UDim2.fromOffset(13,30),Size=UDim2.new(1,-81,0,17),
        Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.MUTED,TextXAlignment=Enum.TextXAlignment.Left,
        Text=desc,
    })
    local switch=prop("Frame",row,{
        Position=UDim2.new(1,-55,.5,-13),Size=UDim2.fromOffset(43,26),
        BackgroundColor3=C.STROKE,BorderSizePixel=0,
    })
    corner(switch,13)
    local dot=prop("Frame",switch,{
        Position=UDim2.fromOffset(4,4),Size=UDim2.fromOffset(18,18),
        BackgroundColor3=C.FG,BorderSizePixel=0,
    })
    corner(dot,9)
    local function render()
        tween(switch,.19,{BackgroundColor3=state[key] and C.LIME or C.STROKE})
        tween(dot,.19,{Position=state[key] and UDim2.fromOffset(21,4) or UDim2.fromOffset(4,4),
             BackgroundColor3=state[key] and C.BG or C.FG})
    end
    toggles[key]=render
    connect(row.MouseButton1Click,function()
        state[key]=not state[key]
        render()
        if onChanged then onChanged(state[key]) end
    end)
    render()
end
local function disabledRow(parent,titleText,desc,order)
    local row=prop("Frame",parent,{
        LayoutOrder=order,Size=UDim2.new(1,0,0,56),BackgroundColor3=C.ITEM,
        BackgroundTransparency=.28,BorderSizePixel=0,
    })
    corner(row,10)
    prop("TextLabel",row,{
        BackgroundTransparency=1,Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-24,0,21),
        Font=Enum.Font.GothamBold,TextSize=12,TextColor3=C.MUTED,
        TextXAlignment=Enum.TextXAlignment.Left,Text=titleText.."   ·   НЕТ ПОДКЛЮЧЕНИЯ",
    })
    prop("TextLabel",row,{
        BackgroundTransparency=1,Position=UDim2.fromOffset(12,29),Size=UDim2.new(1,-24,0,18),
        Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.MUTED,
        TextXAlignment=Enum.TextXAlignment.Left,Text=desc,
    })
end

section(espPanel,"ПОДСВЕТКА ИГРОКОВ",1)
toggleRow(espPanel,"ESP игроков","Ник • метры • белый контур", "players",2)
section(espPanel,"ОБЪЕКТЫ НА КАРТЕ",3)
toggleRow(espPanel,"ESP генераторов","Голубой контур • расстояние", "generators",4)
toggleRow(espPanel,"ESP тыкв","Оранжевый свет • скрыть после сбора", "pumpkins",5)
section(mainPanel,"ДВИЖЕНИЕ (ЛОКАЛЬНО)",1)
toggleRow(mainPanel,"NoClip","Без столкновений (если сервер разрешит)","noclip",2)
toggleRow(mainPanel,"Fly","WASD • Space вверх • Ctrl вниз", "fly",3)
section(mainPanel,"ТРЕБУЮТ ДАННЫХ ИГРЫ",4)
disabledRow(mainPanel,"Auto Generator / Skill Check","Нужны точные сигналы мини-игры",5)
disabledRow(mainPanel,"Fast Vault","Нужен код анимаций и проверки перелаза",6)
disabledRow(mainPanel,"Бесконечная выносливость","Нужна схема хранения stamina",7)

prop("TextLabel",sidebar,{
    Position=UDim2.new(0,10,1,-44),Size=UDim2.new(1,-20,0,38),
    BackgroundTransparency=1,Text="OX1DE  •  v0.1\nLOCAL DEMO",TextColor3=C.MUTED,
    TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,
})
-- Open first tab and add smooth navigation / dragging.
currentTab = "ESP"
for tabName, button in pairs(navButtons) do
    local isSelected = tabName == "ESP"
    button.BackgroundTransparency = isSelected and 0 or 1
    button.TextColor3 = isSelected and C.LIME or C.MUTED
    panels[tabName].Visible = isSelected
end

local minimized = false
local openPill = prop("TextButton",gui,{
    Name="Reopen",Visible=false,Size=UDim2.fromOffset(158,42),
    Position=UDim2.new(0,18,.5,-21),Text="OX1DE Cheating",
    BackgroundColor3=C.BG,TextColor3=C.LIME,Font=Enum.Font.GothamBold,
    TextSize=13,AutoButtonColor=false,BorderSizePixel=0,
})
corner(openPill,12)
border(openPill)
local function showMenu(value)
    minimized = not value
    window.Visible=value
    openPill.Visible=not value
    if value then
        window.BackgroundTransparency=.2
        tween(window,.23,{BackgroundTransparency=0})
    end
end
connect(hideBtn.MouseButton1Click,function() showMenu(false) end)
connect(openPill.MouseButton1Click,function() showMenu(true) end)
connect(UserInputService.InputBegan,function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode==Enum.KeyCode.RightControl then showMenu(minimized) end
end)

local dragging=false
local dragStart, frameStart
connect(titleBar.InputBegan,function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        dragging=true
        dragStart=input.Position
        frameStart=window.Position
        input.Changed:Connect(function()
            if input.UserInputState==Enum.UserInputState.End then dragging=false end
        end)
    end
end)
connect(UserInputService.InputChanged,function(input)
    if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or
        input.UserInputType==Enum.UserInputType.Touch) then
        local delta=input.Position-dragStart
        window.Position=UDim2.new(frameStart.X.Scale,frameStart.X.Offset+delta.X,
                                  frameStart.Y.Scale,frameStart.Y.Offset+delta.Y)
    end
end)

local counter = prop("TextLabel",espPanel,{
    LayoutOrder=6,Size=UDim2.new(1,0,0,44),BackgroundTransparency=1,
    Text="Поиск объектов…",TextXAlignment=Enum.TextXAlignment.Left,
    TextWrapped=true,TextSize=11,Font=Enum.Font.Gotham,
    TextColor3=C.MUTED,
})

-- Player ESP: outlines + nickname + distance. Red only when role is
-- actually identifiable from replicated data; otherwise gray (unknown).
local function createBillboard(part, color, textValue)
    local bill=prop("BillboardGui",gui,{
        Adornee=part,AlwaysOnTop=true,LightInfluence=0,
        Size=UDim2.fromOffset(220,44),StudsOffsetWorldSpace=Vector3.new(0,3.3,0),
        MaxDistance=100000,
    })
    local textLabel=prop("TextLabel",bill,{
        BackgroundTransparency=1,Size=UDim2.fromScale(1,1),
        Font=Enum.Font.GothamBold,TextSize=13,TextWrapped=true,
        TextStrokeColor3=C.BG,TextStrokeTransparency=.05,
        TextColor3=color,Text=textValue,
    })
    return bill,textLabel
end
local function killPlayerFx(player)
    local fx=playerFx[player]
    if not fx then return end
    if fx.highlight then fx.highlight:Destroy() end
    if fx.billboard then fx.billboard:Destroy() end
    playerFx[player]=nil
end
local function createPlayerFx(player)
    if player==LocalPlayer then return end
    killPlayerFx(player)
    local char=player.Character
    if not char then return end
    local head=char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    if not head then return end
    local h=prop("Highlight",char,{
        Name="OX1DE_PlayerOutline",Adornee=char,
        FillTransparency=1,OutlineTransparency=0,
        OutlineColor=C.WHITE,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,
        Enabled=state.players,
    })
    local b,t=createBillboard(head,C.UNKNOWN,player.DisplayName)
    b.Enabled=state.players
    playerFx[player]={highlight=h,billboard=b,text=t,head=head}
end
local function listenPlayer(player)
    if player==LocalPlayer then return end
    connect(player.CharacterAdded,function()
        task.delay(.45,function() if active then createPlayerFx(player) end end)
    end)
    if player.Character then createPlayerFx(player) end
end
for _,p in ipairs(Players:GetPlayers()) do listenPlayer(p) end
connect(Players.PlayerAdded,listenPlayer)
connect(Players.PlayerRemoving,killPlayerFx)

-- World ESP: tracks EVERY discoverable pumpkin / generator in the Workspace.
-- Not just the nearest one, and never capped at one object.
local function contains(s,word)
    return s:find(word,1,true) ~= nil
end
local function objectCategory(obj)
    local n=safeName(obj)
    if contains(n,"pumpkin") or contains(n,"jackolantern") or
       contains(n,"jack_o_lantern") or contains(n,"jack-o-lantern") or
       contains(n,"тыкв") then
        return "pumpkins"
    end
    if contains(n,"generator") or contains(n,"генератор") then
        return "generators"
    end
    return nil
end
local function worldCandidate(obj)
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return nil,nil end
    if isInPlayerModel(obj) then return nil,nil end
    local kind=objectCategory(obj)
    if kind then
        -- Prefer an enclosing named model over its matching parts.
        local parent=obj.Parent
        if parent and parent:IsA("Model") and objectCategory(parent)==kind then
            return parent,kind
        end
        return obj,kind
    end
    -- Some maps store pumpkins under a folder named 'Pumpkins' and
    -- give each object a number rather than a descriptive name.
    local parent=obj.Parent
    if parent and parent:IsA("Folder") then
        local folderKind=objectCategory(parent)
        if folderKind then return obj,folderKind end
    end
    return nil,nil
end
local function clearWorldFx(obj)
    local fx=worldFx[obj]
    if not fx then return end
    if fx.highlight then fx.highlight:Destroy() end
    if fx.billboard then fx.billboard:Destroy() end
    worldFx[obj]=nil
end
local function addWorldFx(obj,kind)
    if worldFx[obj] or not basePart(obj) or not obj:IsDescendantOf(Workspace) then return end
    -- Avoid double highlights if an enclosing model is already tracked.
    local ancestor=obj.Parent
    while ancestor and ancestor~=Workspace do
        if worldFx[ancestor] then return end
        ancestor=ancestor.Parent
    end
    if obj:IsA("Model") then
        for oldObj,_ in pairs(worldFx) do
            if oldObj~=obj and oldObj:IsDescendantOf(obj) then clearWorldFx(oldObj) end
        end
    end
    if inactiveWorldObject(obj,kind) then return end
    local color=kind=="pumpkins" and C.ORANGE or C.CYAN
    local outline=kind=="pumpkins" and Color3.fromRGB(255,214,91) or C.CYAN
    local h=prop("Highlight",obj,{
        Name="OX1DE_WorldOutline",Adornee=obj,
        FillColor=color,FillTransparency=.45,
        OutlineColor=outline,OutlineTransparency=0,
        DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,
        Enabled=state[kind],
    })
    local b,t=createBillboard(basePart(obj),color,kind=="pumpkins" and "🎃 Тыква" or "Генератор")
    b.Enabled=state[kind]
    worldFx[obj]={kind=kind,highlight=h,billboard=b,text=t,part=basePart(obj)}
end
local function scanObject(obj)
    local target,kind=worldCandidate(obj)
    if target then addWorldFx(target,kind) end
end
local function scanAll()
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            scanObject(obj)
        end
    end
end
scanAll()
connect(Workspace.DescendantAdded,function(obj)
    if not active then return end
    -- The model may be inserted before its parts, so check additions too.
    scanObject(obj)
    if obj.Parent then scanObject(obj.Parent) end
end)

-- Local movement prototypes. The game's server may correct movement.
local function stopFly()
    if flyVelocity then flyVelocity:Destroy(); flyVelocity=nil end
    if flyGyro then flyGyro:Destroy(); flyGyro=nil end
    local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand=false end
end
local function startFly()
    stopFly()
    local root=myRoot()
    if not root then return end
    local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand=true end
    flyVelocity=prop("BodyVelocity",root,{
        Name="OX1DE_FlyVelocity",Velocity=Vector3.zero,
        MaxForce=Vector3.new(1e7,1e7,1e7),P=11000,
    })
    flyGyro=prop("BodyGyro",root,{
        Name="OX1DE_FlyGyro",MaxTorque=Vector3.new(1e7,1e7,1e7),
        P=8500,D=180,CFrame=root.CFrame,
    })
end
local function restoreCollisions()
    for part,value in pairs(oldCollisions) do
        if part.Parent then part.CanCollide=value end
        oldCollisions[part]=nil
    end
end
local function updateNoClip()
    if not state.noclip then restoreCollisions(); return end
    local char=LocalPlayer.Character
    if not char then return end
    for _,obj in ipairs(char:GetDescendants()) do
        if obj:IsA("BasePart") then
            if oldCollisions[obj]==nil then oldCollisions[obj]=obj.CanCollide end
            obj.CanCollide=false
        end
    end
end
connect(RunService.Stepped,updateNoClip)
connect(RunService.RenderStepped,function()
    if not active or not state.fly then return end
    local root=myRoot()
    if not root then return end
    if not flyVelocity or not flyVelocity.Parent then startFly() end
    local camera=Workspace.CurrentCamera
    if not camera then return end
    local cf=camera.CFrame
    local movement=Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then movement+=cf.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then movement-=cf.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then movement-=cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then movement+=cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then movement+=Vector3.yAxis end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then movement-=Vector3.yAxis end
    -- Mobile sticks can still control horizontal flight.
    if UserInputService.TouchEnabled then
        local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then movement+=hum.MoveDirection end
    end
    if movement.Magnitude>0 then movement=movement.Unit*56 end
    if flyVelocity then flyVelocity.Velocity=movement end
    if flyGyro then flyGyro.CFrame=cf end
end)
connect(LocalPlayer.CharacterAdded,function()
    stopFly()
    restoreCollisions()
    task.delay(.6,function() if active and state.fly then startFly() end end)
end)

-- Toggle side effects.
local oldFlyRender=toggles.fly
local oldNoClipRender=toggles.noclip
-- Those callbacks are wired into the actual buttons below via a watcher.
local lastFly,lastNoClip=state.fly,state.noclip

local elapsed=0
connect(RunService.Heartbeat,function(dt)
    if not active then return end
    if lastFly~=state.fly then
        lastFly=state.fly
        if state.fly then startFly() else stopFly() end
    end
    if lastNoClip~=state.noclip then
        lastNoClip=state.noclip
        if not state.noclip then restoreCollisions() end
    end
    elapsed+=dt
    if elapsed<.35 then return end
    elapsed=0
    local root=myRoot()
    local nPlayers,nGens,nPumpkins=0,0,0
    for player,fx in pairs(playerFx) do
        if not player.Parent or not player.Character or not fx.head.Parent then
            killPlayerFx(player)
        else
            nPlayers+=1
            local role=roleFor(player)
            local color=(role=="killer" and C.RED) or
                        (role=="survivor" and C.LIME) or C.UNKNOWN
            fx.text.TextColor3=color
            local dist=root and metres(root.Position,fx.head.Position) or 0
            fx.text.Text=player.DisplayName.." ["..player.Name.."]\n"..dist.." м"
            fx.highlight.Enabled=state.players
            fx.billboard.Enabled=state.players
        end
    end
    for obj,fx in pairs(worldFx) do
        if inactiveWorldObject(obj,fx.kind) or not fx.part.Parent then
            clearWorldFx(obj)
        else
            local dist=root and metres(root.Position,fx.part.Position) or 0
            fx.text.Text=(fx.kind=="pumpkins" and "🎃 Тыква" or "Генератор").."  •  "..dist.." м"
            fx.highlight.Enabled=state[fx.kind]
            fx.billboard.Enabled=state[fx.kind]
            if fx.kind=="pumpkins" then nPumpkins+=1 else nGens+=1 end
        end
    end
    counter.Text=string.format("Найдено: игроки %d  •  генераторы %d  •  тыквы %d\nОтображаются все загруженные тыквы одновременно.",nPlayers,nGens,nPumpkins)
end)
-- Periodic rescan covers objects whose BaseParts were added after the parent.
task.spawn(function()
    while active do
        task.wait(8)
        if active then scanAll() end
    end
end)

-- Dispose any local objects when script is run again.
_G.OX1DE_CHEATING_STOP=function()
    active=false
    state.fly=false
    state.noclip=false
    stopFly()
    restoreCollisions()
    for _,conn in ipairs(connections) do conn:Disconnect() end
    for player,_ in pairs(playerFx) do killPlayerFx(player) end
    for obj,_ in pairs(worldFx) do clearWorldFx(obj) end
    gui:Destroy()
end