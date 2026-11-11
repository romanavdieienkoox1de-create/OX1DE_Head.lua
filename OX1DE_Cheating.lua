-- OX1DE | Район насилия | compact UI
-- Client-side prototype. Game-specific behaviors are not verified.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
-- One module per Roblox place; future game profiles can be registered here.
local GameModules={
 violence_district={title="Район насилия",subtitle="VIOLENCE DISTRICT"},
 warfare={title="WARFARE",subtitle="WARFARE / TEAM & FPV"}
}
local activeTab="violence_district"
local ActiveGame=GameModules.violence_district
local GENERATOR_PREVIEW_ASSET_ID = "" -- Roblox image asset ID; supply after uploading the provided screenshot

if type(_G.OX1DE_CHEATING_STOP)=="function" then pcall(_G.OX1DE_CHEATING_STOP) end
local older=PlayerGui:FindFirstChild("OX1DE_Cheating")
if older then older:Destroy() end

local C={
 bg=Color3.fromRGB(8,11,13),panel=Color3.fromRGB(15,21,24),
 card=Color3.fromRGB(22,28,33),row=Color3.fromRGB(26,33,37),
 edge=Color3.fromRGB(61,87,67),green=Color3.fromRGB(119,255,48),
 cyan=Color3.fromRGB(0,223,239),orange=Color3.fromRGB(255,153,25),
 red=Color3.fromRGB(255,53,68),white=Color3.fromRGB(245,249,251),
 muted=Color3.fromRGB(158,171,176),unknown=Color3.fromRGB(185,187,193),
 darkgreen=Color3.fromRGB(20,57,25)
}
local state={players=false,killers=false,generators=false,pumpkins=false,pallets=false,fly=false,noclip=false,autoSkill=false,
 warAllies=false,warEnemies=false,warNames=true,warWeapons=false,warFPV=false,
 warFly=false,warNoClip=false,warAimPreview=false,warFov=true,warWallCheck=true,warTeamCheck=true,warHoldAim=true}
local palette={players=Color3.fromRGB(255,255,255),killers=C.red,survivors=C.green,generators=C.cyan,pumpkins=C.orange,pallets=Color3.fromRGB(245,192,65),
 warAllies=Color3.fromRGB(119,255,48),warEnemies=Color3.fromRGB(255,67,81),warFPV=Color3.fromRGB(255,197,62),warFov=Color3.fromRGB(119,255,48),warAim=Color3.fromRGB(255,220,72)}
-- Local, per-installation settings. No network sync is used.
local HttpService=game:GetService("HttpService")
local settingsFile="OX1DE_ViolenceDistrict_"..tostring(LocalPlayer.UserId)..".json"
local settingsSupported=type(readfile)=="function" and type(writefile)=="function"
local savedSettings=nil
if settingsSupported then
 local ok,data=pcall(function() return HttpService:JSONDecode(readfile(settingsFile)) end)
 if ok and type(data)=="table" then savedSettings=data end
end
if savedSettings then
 if type(savedSettings.toggles)=="table" then
  for name,value in pairs(savedSettings.toggles) do
   if state[name]~=nil and type(value)=="boolean" then state[name]=value end
  end
 end
 if type(savedSettings.colors)=="table" then
  for name,rgb in pairs(savedSettings.colors) do
   if palette[name] and type(rgb)=="table"
    and type(rgb[1])=="number" and type(rgb[2])=="number" and type(rgb[3])=="number" then
    palette[name]=Color3.fromRGB(math.clamp(rgb[1],0,255),math.clamp(rgb[2],0,255),math.clamp(rgb[3],0,255))
   end
  end
 end
end
local warSettings={fov=160,distance=50,prediction=35,smooth=65,drop=20,mode="legit"}
if savedSettings and type(savedSettings.warfare)=="table" then
 for name,limits in pairs({fov={20,400},distance={10,300},prediction={0,100},smooth={5,100},drop={0,100}}) do
  local v=savedSettings.warfare[name]
  if type(v)=="number" then warSettings[name]=math.clamp(v,limits[1],limits[2]) end
 end
end
if savedSettings and type(savedSettings.warfare)=="table" then
 local rememberedMode=savedSettings.warfare.mode
 if rememberedMode=="hard" or rememberedMode=="legit" then warSettings.mode=rememberedMode end
end
local function editableColor(key)
 return key=="players" or key=="generators" or key=="pumpkins" or key=="pallets"
   or key=="warAllies" or key=="warEnemies" or key=="warFPV" or key=="warFov" or key=="warAim"
end
-- Killer and survivor NICK colours are deliberately fixed.
local swatches={}
local function addSwatch(key,element)
 swatches[key]=swatches[key] or {}
 table.insert(swatches[key],element)
 element.BackgroundColor3=palette[key]
end
local function paintSwatches(key)
 for _,w in ipairs(swatches[key] or {}) do
  if w.Parent then w.BackgroundColor3=palette[key] end
 end
end
local alive=true
local connections={}
local playerFx,objectFx={},{}
local collisions=setmetatable({}, {__mode="k"})
local flyVelocity,flyGyro
local foundText,countText
local onEspToggle
local warFpvStart
local function listen(signal,callback)
 local connection=signal:Connect(callback)
 table.insert(connections,connection)
 return connection
end
local function make(class,parent,props)
 local o=Instance.new(class)
 for k,v in pairs(props or {}) do o[k]=v end
 o.Parent=parent
 return o
end
local function corner(parent,r)
 return make("UICorner",parent,{CornerRadius=UDim.new(0,r or 10)})
end
local function border(parent,color,trans,thick)
 return make("UIStroke",parent,{Color=color or C.edge,Transparency=trans or 0,Thickness=thick or 1})
end
local function tween(o,props,duration)
 if not o or not o.Parent then return end
 local t=TweenService:Create(o,TweenInfo.new(duration or .19,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),props)
 t:Play()
 return t
end
local function text(parent,content,pos,size,sizePx,bold,color,align)
 return make("TextLabel",parent,{
  BackgroundTransparency=1,Position=pos,Size=size,Text=content,
  TextColor3=color or C.white,Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,
  TextSize=sizePx or 14,TextXAlignment=align or Enum.TextXAlignment.Left,
  TextYAlignment=Enum.TextYAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd
 })
end
local function fmtDistance(a,b)
 return math.floor((a-b).Magnitude/3.57+.5)
end
local function root()
 local character=LocalPlayer.Character
 return character and character:FindFirstChild("HumanoidRootPart")
end
local function partOf(o)
 if o:IsA("BasePart") then return o end
 if o:IsA("Model") then return o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart",true) end
 return nil
end
local function readFlag(o,keys)
 if not o then return nil end
 for _,key in ipairs(keys) do
  local a=o:GetAttribute(key)
  if a~=nil then return a end
  local v=o:FindFirstChild(key)
  if v and v:IsA("ValueBase") then return v.Value end
 end
 return nil
end
local function role(p)
 local ch=p.Character
 for _,v in ipairs({p,ch or p}) do
  local flag=readFlag(v,{"IsKiller","IsMurderer","Killer"})
  if flag==true then return "killer" end
  if flag==false then return "survivor" end
 end
 local words={}
 if p.Team then words[#words+1]=p.Team.Name end
 for _,o in ipairs({p,ch or p}) do
  for _,k in ipairs({"Role","CurrentRole","TeamRole","PlayerRole"}) do
   local a=o:GetAttribute(k)
   if type(a)=="string" then words[#words+1]=a end
   local v=o:FindFirstChild(k)
   if v and v:IsA("StringValue") then words[#words+1]=v.Value end
  end
 end
 for _,v in ipairs(words) do
  local s=string.lower(v)
  if s:find("killer",1,true) or s:find("murder",1,true) or s:find("hunter",1,true) or s:find("maniac",1,true) then return "killer" end
  if s:find("surviv",1,true) or s:find("escape",1,true) or s:find("victim",1,true) then return "survivor" end
 end
 return "unknown"
end

-- One-window design ---------------------------------------------------------
local gui=Instance.new("ScreenGui")
gui.Name="OX1DE_Cheating"
gui.ResetOnSpawn=false
gui.IgnoreGuiInset=true
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.DisplayOrder=100
local guiParent=PlayerGui
pcall(function()
 local parent
 if type(gethui)=="function" then parent=gethui() end
 if not parent then parent=game:GetService("CoreGui") end
 if parent then gui.Parent=parent;guiParent=parent end
end)
if not gui.Parent then gui.Parent=PlayerGui;guiParent=PlayerGui end
-- Player tags are native BillboardGui attached to character parts.
-- Avoid manual screen position updates that lag or jitter on camera turns.
local window=make("Frame",gui,{
 Name="OX1DEWindow",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
 Size=UDim2.fromOffset(1050,676),BackgroundColor3=C.bg,BorderSizePixel=0,ClipsDescendants=true
})
corner(window,22)
local windowStroke=border(window,C.green,.34,1.6)
TweenService:Create(windowStroke,TweenInfo.new(2.8,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Transparency=.12,Thickness=2}):Play()
make("UIGradient",window,{Rotation=16,Color=ColorSequence.new({
 ColorSequenceKeypoint.new(0,Color3.fromRGB(9,17,14)),
 ColorSequenceKeypoint.new(.58,Color3.fromRGB(7,10,13)),
 ColorSequenceKeypoint.new(1,Color3.fromRGB(8,18,12))
})})
local scale=make("UIScale",window,{Scale=1})
local requestedScale=1
local function resize()
 local camera=Workspace.CurrentCamera
 if not camera then return end
 local vp=camera.ViewportSize
 local fit=math.min((vp.X-28)/1050,(vp.Y-28)/676)
 scale.Scale=math.max(.22,math.min(requestedScale,fit))
end
local cameraConn
local function updateCamera()
 if cameraConn then cameraConn:Disconnect() end
 local camera=Workspace.CurrentCamera
 if camera then cameraConn=camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
 resize()
end
updateCamera()
listen(Workspace:GetPropertyChangedSignal("CurrentCamera"),updateCamera)

local header=make("Frame",window,{Position=UDim2.fromOffset(0,0),Size=UDim2.new(1,0,0,86),BackgroundTransparency=1,Active=true})
make("Frame",window,{Position=UDim2.fromOffset(0,86),Size=UDim2.new(1,0,0,1),BackgroundColor3=Color3.fromRGB(51,81,41),BorderSizePixel=0})
text(header,"OX1DE",UDim2.fromOffset(29,13),UDim2.fromOffset(510,38),30,true,C.green)
local subtitleLabel=text(header,ActiveGame.subtitle,UDim2.fromOffset(31,53),UDim2.fromOffset(490,18),10,false,C.muted)
local keybind={menu=Enum.KeyCode.RightShift,fly=Enum.KeyCode.F6,noclip=Enum.KeyCode.F7,warFly=Enum.KeyCode.F9,warNoClip=Enum.KeyCode.F8,warAim=Enum.KeyCode.F10}
if savedSettings and type(savedSettings.keys)=="table" then
 for name in pairs(keybind) do
  local keyName=savedSettings.keys[name]
  if type(keyName)=="string" and #keyName<40 then
   local ok,key=pcall(function() return Enum.KeyCode[keyName] end)
   if ok and key and key~=Enum.KeyCode.Unknown then keybind[name]=key end
  end
 end
end
local savedVersion=0
local function saveSettingsNow()
 if not settingsSupported or not alive then return end
 local snapshot={version=2,toggles={},colors={},keys={},warfare=warSettings}
 for name,value in pairs(state) do if type(value)=="boolean" then snapshot.toggles[name]=value end end
 for name,color in pairs(palette) do
  snapshot.colors[name]={math.floor(color.R*255+.5),math.floor(color.G*255+.5),math.floor(color.B*255+.5)}
 end
 for name,key in pairs(keybind) do snapshot.keys[name]=key.Name end
 pcall(function() writefile(settingsFile,HttpService:JSONEncode(snapshot)) end)
end
local function scheduleSettingsSave()
 if not settingsSupported then return end
 savedVersion+=1
 local current=savedVersion
 task.delay(.35,function()
  if alive and savedVersion==current then saveSettingsNow() end
 end)
end
local bindButtons={}
local waitingFor=nil
local refreshMenuSink
local function niceKey(key)
 if not key or key==Enum.KeyCode.Unknown then return "НАЗНАЧИТЬ" end
 local aliases={RightShift="Right Shift",LeftShift="Left Shift",LeftControl="L Ctrl",RightControl="R Ctrl",Backspace="Backspace"}
 return aliases[key.Name] or key.Name
end
local menuBind=make("TextButton",header,{
 Position=UDim2.fromOffset(762,22),Size=UDim2.fromOffset(188,41),BackgroundColor3=C.card,
 Text="",AutoButtonColor=false,BorderSizePixel=0
})
corner(menuBind,10);border(menuBind,C.edge,.53,1)
local menuBindText=text(menuBind,"Right Shift  •  БИНД МЕНЮ",UDim2.fromOffset(8,0),UDim2.new(1,-16,1,0),12,true,C.green,Enum.TextXAlignment.Center)
local minimize=make("TextButton",header,{Position=UDim2.fromOffset(961,22),Size=UDim2.fromOffset(37,41),BackgroundColor3=C.card,Text="−",Font=Enum.Font.GothamBold,TextSize=21,TextColor3=C.white,BorderSizePixel=0,AutoButtonColor=false})
corner(minimize,10)
local close=make("TextButton",header,{Position=UDim2.fromOffset(1004,22),Size=UDim2.fromOffset(37,41),BackgroundColor3=C.card,Text="×",Font=Enum.Font.GothamBold,TextSize=21,TextColor3=C.white,BorderSizePixel=0,AutoButtonColor=false})
corner(close,10)

-- Drag the bottom-right handle to resize the whole window, like a desktop app.
local sizeGrip=make("TextButton",window,{
 Name="ResizeGrip",Position=UDim2.new(1,-31,1,-30),
 Size=UDim2.fromOffset(26,25),Text="◢",TextColor3=C.green,
 Font=Enum.Font.GothamBold,TextSize=20,BackgroundColor3=C.card,
 BackgroundTransparency=.06,BorderSizePixel=0,AutoButtonColor=false,
 Active=true,ZIndex=20
})
corner(sizeGrip,7)

local sidebar=make("Frame",window,{Position=UDim2.fromOffset(0,87),Size=UDim2.fromOffset(204,589),BackgroundColor3=Color3.fromRGB(10,16,15),BorderSizePixel=0,ClipsDescendants=true})
make("UIGradient",sidebar,{Rotation=100,Color=ColorSequence.new(Color3.fromRGB(9,15,15),Color3.fromRGB(9,31,15))})
local wave=make("Frame",sidebar,{Position=UDim2.fromOffset(-130,414),Size=UDim2.fromOffset(380,180),Rotation=-18,BackgroundColor3=C.green,BackgroundTransparency=.90,BorderSizePixel=0})
corner(wave,80)
TweenService:Create(wave,TweenInfo.new(3.6,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{BackgroundTransparency=.78}):Play()
-- Game name is now the navigation item only
local selectedNav=make("TextButton",sidebar,{Position=UDim2.fromOffset(14,34),Size=UDim2.fromOffset(178,59),BackgroundColor3=C.darkgreen,BorderSizePixel=0,Text="",AutoButtonColor=false})
corner(selectedNav,13)
local navStroke=border(selectedNav,C.green,.05,1.4)
text(selectedNav,"⌂",UDim2.fromOffset(20,0),UDim2.fromOffset(30,59),27,true,C.green)
text(selectedNav,"Район насилия",UDim2.fromOffset(51,0),UDim2.fromOffset(125,59),13,true,C.white)
local warNav=make("TextButton",sidebar,{Position=UDim2.fromOffset(14,101),Size=UDim2.fromOffset(178,59),BackgroundColor3=C.card,Text="",BorderSizePixel=0,AutoButtonColor=false})
corner(warNav,13);border(warNav,C.edge,.4,1)
text(warNav,"✦",UDim2.fromOffset(19,0),UDim2.fromOffset(28,59),24,true,C.green)
text(warNav,"WARFARE",UDim2.fromOffset(52,0),UDim2.fromOffset(120,59),15,true,C.white)
local bindInfo={Text=""}
-- Sidebar stays intentionally minimal; shortcuts remain internal.

local content=make("Frame",window,{Position=UDim2.fromOffset(204,87),Size=UDim2.fromOffset(846,589),BackgroundTransparency=1,ClipsDescendants=true})
local warContent=make("Frame",window,{Position=UDim2.fromOffset(204,87),Size=UDim2.fromOffset(846,589),BackgroundTransparency=1,ClipsDescendants=true,Visible=false})
local function panel(parent,pos,size,col)
 local f=make("Frame",parent,{Position=pos,Size=size,BackgroundColor3=C.panel,BorderSizePixel=0,ClipsDescendants=true})
 corner(f,16);border(f,col or C.edge,.22,1)
 return f
end
local hero=panel(content,UDim2.fromOffset(14,14),UDim2.fromOffset(816,182),C.green)
make("UIGradient",hero,{Rotation=0,Color=ColorSequence.new({
 ColorSequenceKeypoint.new(0,Color3.fromRGB(11,25,21)),
 ColorSequenceKeypoint.new(.58,Color3.fromRGB(14,20,23)),
 ColorSequenceKeypoint.new(1,Color3.fromRGB(12,30,19))
})})
local heroAccent=make("Frame",hero,{Position=UDim2.fromOffset(773,-10),Size=UDim2.fromOffset(20,100),Rotation=36,BackgroundColor3=C.green,BackgroundTransparency=.84,BorderSizePixel=0})
TweenService:Create(heroAccent,TweenInfo.new(4,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{BackgroundTransparency=.58}):Play()
make("Frame",hero,{Position=UDim2.fromOffset(495,24),Size=UDim2.fromOffset(1,132),BackgroundColor3=Color3.fromRGB(49,94,71),BorderSizePixel=0})
local generatorPhoto=make("ImageLabel",hero,{
 Position=UDim2.fromOffset(13,12),Size=UDim2.fromOffset(470,158),
 BackgroundColor3=Color3.fromRGB(11,18,21),BorderSizePixel=0,
 Image=GENERATOR_PREVIEW_ASSET_ID~="" and ("rbxassetid://"..GENERATOR_PREVIEW_ASSET_ID) or "",
 ScaleType=Enum.ScaleType.Fit,Visible=GENERATOR_PREVIEW_ASSET_ID~="",ZIndex=2
})
corner(generatorPhoto,12)
local viewport=make("ViewportFrame",hero,{
 Position=UDim2.fromOffset(13,12),Size=UDim2.fromOffset(470,158),Visible=GENERATOR_PREVIEW_ASSET_ID=="",
 BackgroundColor3=Color3.fromRGB(11,18,21),BorderSizePixel=0,
 Ambient=Color3.fromRGB(145,166,175),LightColor=Color3.fromRGB(220,238,240),LightDirection=Vector3.new(-1,-1,-1)
})
corner(viewport,12)
local world=make("WorldModel",viewport,{})
local previewCamera=make("Camera",viewport,{CFrame=CFrame.lookAt(Vector3.new(8,4,12),Vector3.zero),FieldOfView=35})
viewport.CurrentCamera=previewCamera
-- Until Workspace provides a generator model, show a restrained placeholder, not a fake machine.
local placeholder=make("Model",world,{Name="PreviewLoading"})
local function previewBlock(name,pos,size,color)
 return make("Part",placeholder,{Name=name,Size=size,Anchored=true,CanCollide=false,Color=color,Material=Enum.Material.Metal,CFrame=CFrame.new(pos)})
end
previewBlock("Body",Vector3.new(0,0,0),Vector3.new(5.7,2.0,2),Color3.fromRGB(119,42,36))
previewBlock("Front",Vector3.new(0,-.2,1.04),Vector3.new(4,1.14,.08),Color3.fromRGB(55,63,65))
for i=-2,2 do
 local v=previewBlock("PanelWire",Vector3.new(i*.6,-.24,1.1),Vector3.new(.11,.93,.08),C.cyan)
 v.Material=Enum.Material.Neon
end
for i=-1,1 do previewBlock("Piston",Vector3.new(i*1.28,1.27,.0),Vector3.new(.7,.83,.75),Color3.fromRGB(77,90,94)) end
local previewLabel=text(hero,"ГЕНЕРАТОР",UDim2.fromOffset(26,16),UDim2.fromOffset(420,24),12,true,C.cyan)
previewLabel.ZIndex=4
local generatorTitle=text(hero,"Генератор",UDim2.fromOffset(518,30),UDim2.fromOffset(276,41),27,true,C.white)
local distanceLabel=text(hero,"Модель в радиусе загрузки",UDim2.fromOffset(519,73),UDim2.fromOffset(270,24),12,false,C.muted)
local previewAccent=make("Frame",hero,{Position=UDim2.fromOffset(520,128),Size=UDim2.fromOffset(20,20),BackgroundColor3=C.cyan,BorderSizePixel=0})
corner(previewAccent,5)
text(hero,"Цвет ESP генераторов — в панели справа",UDim2.fromOffset(553,120),UDim2.fromOffset(258,37),12,false,C.muted)

local functionsPanel=panel(content,UDim2.fromOffset(14,207),UDim2.fromOffset(444,368))
local espPanel=panel(content,UDim2.fromOffset(471,207),UDim2.fromOffset(359,368))
text(functionsPanel,"⚙",UDim2.fromOffset(16,9),UDim2.fromOffset(34,34),24,true,C.green)
text(functionsPanel,"Основные функции",UDim2.fromOffset(51,9),UDim2.fromOffset(370,34),19,true)
text(espPanel,"◉",UDim2.fromOffset(13,9),UDim2.fromOffset(34,34),23,true,C.green)
text(espPanel,"ESP  •  Подсветка",UDim2.fromOffset(50,9),UDim2.fromOffset(300,34),18,true)
local espScroll=espPanel

local allRows={}
local function applyToggle(key)
 for _,v in ipairs(allRows) do
  if v.key==key then
   tween(v.back,{BackgroundColor3=state[key] and C.green or Color3.fromRGB(67,79,78)},.18)
   tween(v.dot,{Position=state[key] and UDim2.fromOffset(23,3) or UDim2.fromOffset(3,3),BackgroundColor3=state[key] and C.bg or C.white},.18)
  end
 end
end
local function setOption(key,enabled)
 if state[key]==enabled then return end
 state[key]=enabled
 applyToggle(key)
 if onEspToggle then onEspToggle(key,enabled) end
 scheduleSettingsSave()
end
local function toggle(key)
 setOption(key,not state[key])
end
local function switch(parent,key,x,y)
 local back=make("Frame",parent,{Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(44,25),BackgroundColor3=state[key] and C.green or C.edge,BorderSizePixel=0})
 corner(back,13)
 local dot=make("Frame",back,{Position=state[key] and UDim2.fromOffset(23,3) or UDim2.fromOffset(3,3),Size=UDim2.fromOffset(19,19),BackgroundColor3=state[key] and C.bg or C.white,BorderSizePixel=0})
 corner(dot,12)
 allRows[#allRows+1]={key=key,back=back,dot=dot}
end
local function bindVisual(key)
 if key=="menu" then
  menuBindText.Text=(waitingFor=="menu" and "НАЖМИ КЛАВИШУ..." or niceKey(keybind.menu).."  •  БИНД МЕНЮ")
  return
 end
 local button=bindButtons[key]
 if button then
  button.Text=(waitingFor==key and "ЖМИ..." or niceKey(keybind[key]))
  button.TextColor3=(waitingFor==key and C.white or C.green)
  tween(button,{BackgroundColor3=(waitingFor==key and C.darkgreen or C.card)},.15)
 end
 bindInfo.Text=niceKey(keybind.fly).." — Fly\n"..niceKey(keybind.noclip).." — NoClip"
end
bindVisual("menu")
local function beginRebind(key)
 waitingFor=key
 for _,name in ipairs({"menu","fly","noclip","warFly","warNoClip","warAim"}) do bindVisual(name) end
end
listen(menuBind.MouseButton1Click,function() beginRebind("menu") end)
local function hoverEffect(o)
 listen(o.MouseEnter,function() tween(o,{BackgroundColor3=Color3.fromRGB(35,45,46)},.17) end)
 listen(o.MouseLeave,function() tween(o,{BackgroundColor3=C.row},.2) end)
end
local skillSubtitle
local openPicker
local rows={
 {key="fly",name="Fly",subtitle="Полёт • WASD / Space",icon="✈",bind=true},
 {key="noclip",name="NoClip",subtitle="Проход сквозь препятствия",icon="⇥",bind=true},
 {key="autoSkill",name="Auto Skill Check",subtitle="Поиск отметки на шкале (эксп.)",icon="◎",bind=false},
 {key="pallets",name="ESP паллет",subtitle="Золотой контур • метры снизу",icon="▤",bind=false}
}
for i,v in ipairs(rows) do
 local y=48+(i-1)*74
 local f=make("TextButton",functionsPanel,{Position=UDim2.fromOffset(12,y),Size=UDim2.fromOffset(420,65),BackgroundColor3=C.row,Text="",AutoButtonColor=false,BorderSizePixel=0})
 corner(f,11);hoverEffect(f)
 local ib=make("Frame",f,{Position=UDim2.fromOffset(9,13),Size=UDim2.fromOffset(38,38),BackgroundColor3=C.card,BorderSizePixel=0})
 corner(ib,9)
 text(ib,v.icon,UDim2.fromScale(0,0),UDim2.fromScale(1,1),23,true,C.green,Enum.TextXAlignment.Center)
 text(f,v.name,UDim2.fromOffset(54,7),UDim2.fromOffset(242,26),15,true)
 local subtitle=text(f,v.subtitle,UDim2.fromOffset(54,34),UDim2.fromOffset(250,21),11,false,C.muted)
 if v.key=="autoSkill" then skillSubtitle=subtitle end
 if v.bind then
  local binding=make("TextButton",f,{Name=v.key.."Bind",Position=UDim2.fromOffset(302,20),Size=UDim2.fromOffset(55,25),BackgroundColor3=C.card,Text=niceKey(keybind[v.key]),TextColor3=C.green,Font=Enum.Font.GothamBold,TextSize=11,BorderSizePixel=0,AutoButtonColor=false})
  corner(binding,6);border(binding,C.edge,.4,1)
  bindButtons[v.key]=binding
  listen(binding.MouseButton1Click,function() beginRebind(v.key) end)
 end
 if v.key=="pallets" then
  local swatch=make("TextButton",f,{Position=UDim2.fromOffset(324,20),Size=UDim2.fromOffset(25,25),
   BackgroundColor3=palette.pallets,Text="",BorderSizePixel=0,AutoButtonColor=false})
  corner(swatch,6)
  addSwatch("pallets",swatch)
  listen(swatch.MouseButton1Click,function()
   if openPicker then openPicker("pallets") end
  end)
 end
 switch(f,v.key,365,20)
 listen(f.MouseButton1Click,function() toggle(v.key) end)
end

local pickerLayer
local wheelHeld,sliderHeld=false,false
local descriptions={
 {key="players",name="ESP игроков",subtitle="Белая обводка • ник • метры",icon=""},
 {key="killers",name="ESP маньяка",subtitle="Ник красный • фиксирован",icon="☠"},
 {key="generators",name="ESP генераторов",subtitle="Генераторы на карте",icon=""},
 {key="pumpkins",name="ESP тыкв",subtitle="Тыквы на карте",icon="🎃"}
}
for i,v in ipairs(descriptions) do
 local y=46+(i-1)*76
 local f=make("TextButton",espScroll,{Position=UDim2.fromOffset(11,y),Size=UDim2.fromOffset(337,70),BackgroundColor3=C.row,Text="",AutoButtonColor=false,BorderSizePixel=0})
 corner(f,11);hoverEffect(f)
 local iconBox=make("Frame",f,{Position=UDim2.fromOffset(11,16),Size=UDim2.fromOffset(38,38),BackgroundColor3=C.card,BorderSizePixel=0})
 corner(iconBox,9)
 if v.key=="players" then
  local head=make("Frame",iconBox,{Position=UDim2.fromOffset(13,7),Size=UDim2.fromOffset(12,12),BackgroundColor3=C.white,BorderSizePixel=0})
  corner(head,12)
  local shoulders=make("Frame",iconBox,{Position=UDim2.fromOffset(6,23),Size=UDim2.fromOffset(26,11),BackgroundColor3=C.white,BorderSizePixel=0})
  corner(shoulders,8)
 elseif v.key=="generators" then
  local body=make("Frame",iconBox,{Position=UDim2.fromOffset(5,11),Size=UDim2.fromOffset(25,19),BackgroundColor3=Color3.fromRGB(25,47,52),BorderSizePixel=0})
  corner(body,3);border(body,C.cyan,.1,1)
  for n=0,2 do
   make("Frame",body,{Position=UDim2.fromOffset(4+n*7,5),Size=UDim2.fromOffset(3,9),BackgroundColor3=C.cyan,BorderSizePixel=0})
  end
  for n=0,1 do make("Frame",iconBox,{Position=UDim2.fromOffset(9+n*11,7),Size=UDim2.fromOffset(6,4),BackgroundColor3=C.cyan,BorderSizePixel=0}) end
 else
  text(iconBox,v.icon,UDim2.fromScale(0,0),UDim2.fromScale(1,1),21,true,v.key=="players" and C.white or palette[v.key],Enum.TextXAlignment.Center)
 end
 text(f,v.name,UDim2.fromOffset(55,10),UDim2.fromOffset(195,25),14,true)
 text(f,v.subtitle,UDim2.fromOffset(55,37),UDim2.fromOffset(195,22),10,false,C.muted)
 local swatch=make("TextButton",f,{Position=UDim2.fromOffset(239,9),Size=UDim2.fromOffset(27,27),Text="",BackgroundColor3=palette[v.key],BorderSizePixel=0,AutoButtonColor=false})
 corner(swatch,7)
 if editableColor(v.key) then
  addSwatch(v.key,swatch)
  border(swatch,palette[v.key],.5,1)
  listen(swatch.MouseButton1Click,function() if openPicker then openPicker(v.key) end end)
 else
  local smallLock=text(swatch,"•",UDim2.fromScale(0,0),UDim2.fromScale(1,1),16,true,C.white,Enum.TextXAlignment.Center)
  smallLock.TextTransparency=.20
  listen(swatch.MouseButton1Click,function()
   -- Role colours are locked: killer red, survivor green.
   tween(swatch,{BackgroundTransparency=.28},.1)
   task.delay(.12,function() if alive and swatch.Parent then tween(swatch,{BackgroundTransparency=0},.15) end end)
  end)
 end
 switch(f,v.key,281,40)
 listen(f.MouseButton1Click,function() toggle(v.key) end)
end

-- Rebind keys. Escape cancels; Backspace clears action binds, not menu bind.
listen(UserInputService.InputBegan,function(input,handled)
 if input.UserInputType~=Enum.UserInputType.Keyboard or not alive then return end
 local key=input.KeyCode
 if waitingFor then
  local target=waitingFor
  waitingFor=nil
  if key~=Enum.KeyCode.Escape and key~=Enum.KeyCode.Unknown then
   if key~=Enum.KeyCode.Backspace or target~="menu" then
    for other,assigned in pairs(keybind) do
     if other~=target and assigned==key then keybind[other]=Enum.KeyCode.Unknown end
    end
    keybind[target]=(key==Enum.KeyCode.Backspace and Enum.KeyCode.Unknown or key)
   end
  end
  for _,name in ipairs({"menu","fly","noclip","warFly","warNoClip","warAim"}) do bindVisual(name) end
  if refreshMenuSink then refreshMenuSink() end
  scheduleSettingsSave()
  return
 end
 if UserInputService:GetFocusedTextBox() then return end
 if key==keybind.menu then
  -- setVisible is defined below and referenced dynamically.
  if _G.OX1DE_LOCAL_TOGGLE then _G.OX1DE_LOCAL_TOGGLE() end
  return
 end
 for _,name in ipairs({"fly","noclip","warFly","warNoClip","warAim"}) do
  if keybind[name]~=Enum.KeyCode.Unknown and key==keybind[name] then
   if (name=="fly" or name=="noclip") and activeTab~="violence_district" then return end
   if (name=="warFly" or name=="warNoClip" or name=="warAim") and activeTab~="warfare" then return end
   toggle(name=="warAim" and "warAimPreview" or name)
   return
  end
 end
end)

-- Camera/mouse management. Never force cursor settings while the menu is closed.
local isOpen=true
local lastMenuOpenTick=0
local oldMouseIcon=UserInputService.MouseIconEnabled
local oldMouseBehavior=UserInputService.MouseBehavior
local cursorStep="OX1DE_CURSOR_"..tostring(LocalPlayer.UserId)
local captureBound=false
local function exposeMouse()
 pcall(function()
  UserInputService.MouseIconEnabled=true
  UserInputService.MouseBehavior=Enum.MouseBehavior.Default
 end)
end
local function startMenuMouse()
 oldMouseIcon=UserInputService.MouseIconEnabled
 oldMouseBehavior=UserInputService.MouseBehavior
 exposeMouse()
end
local function stopMenuMouse()
 pcall(function()
  UserInputService.MouseIconEnabled=oldMouseIcon
  UserInputService.MouseBehavior=oldMouseBehavior
 end)
end
local closeRevision=0
local function setVisible(show)
 if not alive then return end
 if isOpen==show then return end
 closeRevision+=1
 local revision=closeRevision
 isOpen=show
 if show then
  window.Visible=true
  window.BackgroundTransparency=.18
  window.Position=UDim2.fromScale(.5,.516)
  startMenuMouse()
  tween(window,{BackgroundTransparency=0,Position=UDim2.fromScale(.5,.5)},.22)
 else
  if pickerLayer then pickerLayer.Visible=false end
  wheelHeld=false;sliderHeld=false
  -- Mouse is released immediately, not after the hide animation.
  stopMenuMouse()
  tween(window,{BackgroundTransparency=.22,Position=UDim2.fromScale(.5,.516)},.14)
  task.delay(.15,function()
   if alive and closeRevision==revision and not isOpen then window.Visible=false end
  end)
 end
end
_G.OX1DE_LOCAL_TOGGLE=function() if alive then setVisible(not isOpen) end end
refreshMenuSink=function() end
refreshMenuSink()
startMenuMouse()
listen(minimize.MouseButton1Click,function() setVisible(false) end)
listen(close.MouseButton1Click,function()
 setVisible(false)
end)
local resizing=false
local resizeStart,scaleAtStart
listen(sizeGrip.InputBegan,function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
  resizing=true
  resizeStart=input.Position
  scaleAtStart=requestedScale
 end
end)
listen(UserInputService.InputEnded,function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
  resizing=false
 end
end)
listen(UserInputService.InputChanged,function(input)
 if not resizing or (input.UserInputType~=Enum.UserInputType.MouseMovement and input.UserInputType~=Enum.UserInputType.Touch) then return end
 local delta=input.Position-resizeStart
 local dx=delta.X/1050
 local dy=delta.Y/676
 requestedScale=math.clamp(scaleAtStart+(math.abs(dx)>math.abs(dy) and dx or dy),.55,1.45)
 resize()
end)
local dragging=false
local dragInput,dragStart,startPos
listen(header.InputBegan,function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
  dragging=true;dragInput=input;dragStart=input.Position;startPos=window.Position
 end
end)
listen(UserInputService.InputEnded,function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end
end)
listen(UserInputService.InputChanged,function(input)
 if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input==dragInput) then
  local delta=input.Position-dragStart
  window.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
 end
end)

-- Full HSV wheel: ring of small colour tiles, saturation radial and brightness slider.
pickerLayer=make("Frame",window,{Name="PickerOverlay",Size=UDim2.fromScale(1,1),BackgroundColor3=C.bg,BackgroundTransparency=.28,BorderSizePixel=0,Visible=false,Active=true,ZIndex=50})
local picker=make("Frame",pickerLayer,{Position=UDim2.fromScale(.5,.5),AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(377,446),BackgroundColor3=Color3.fromRGB(16,23,27),BorderSizePixel=0,ZIndex=51})
corner(picker,17);border(picker,C.green,.13,1.6)
local pickerHeading=text(picker,"Цвет ESP",UDim2.fromOffset(21,15),UDim2.fromOffset(295,32),20,true)
pickerHeading.ZIndex=52
local pickerX=make("TextButton",picker,{Position=UDim2.fromOffset(329,15),Size=UDim2.fromOffset(31,32),Text="×",TextColor3=C.white,TextSize=23,Font=Enum.Font.GothamBold,BackgroundColor3=C.card,BorderSizePixel=0,AutoButtonColor=false,ZIndex=55})
corner(pickerX,9)
local wheel=make("Frame",picker,{Position=UDim2.fromOffset(78,56),Size=UDim2.fromOffset(220,220),BackgroundTransparency=1,Active=true,ZIndex=54})
local wheelCenter=Vector2.new(110,110)
local wheelRadius=101
-- Continuous-looking HSV disk: radial gradient spokes instead of dotted tiles.
local sectors=144
for seg=0,sectors-1 do
 local hue=seg/sectors
 local spoke=make("Frame",wheel,{
  AnchorPoint=Vector2.new(.5,1),Position=UDim2.fromOffset(110,110),
  Size=UDim2.fromOffset(8,106),Rotation=hue*360+90,
  BackgroundColor3=C.white,BorderSizePixel=0,ZIndex=54,Active=false
 })
 make("UIGradient",spoke,{
  Rotation=90,Color=ColorSequence.new({
   ColorSequenceKeypoint.new(0,Color3.fromHSV(hue,1,1)),
   ColorSequenceKeypoint.new(1,Color3.new(1,1,1))
  })
 })
end
local pickerDot=make("Frame",wheel,{Position=UDim2.fromOffset(103,3),Size=UDim2.fromOffset(14,14),BackgroundColor3=C.white,BorderSizePixel=0,ZIndex=56,Active=false})
corner(pickerDot,9);border(pickerDot,C.bg,0,2)
local sample=make("Frame",picker,{Position=UDim2.fromOffset(22,295),Size=UDim2.fromOffset(48,43),BackgroundColor3=C.white,BorderSizePixel=0,ZIndex=52})
corner(sample,9)
local brightCaption=text(picker,"Яркость",UDim2.fromOffset(81,292),UDim2.fromOffset(230,21),14,true)
brightCaption.ZIndex=53
local slider=make("Frame",picker,{Position=UDim2.fromOffset(82,324),Size=UDim2.fromOffset(267,16),BackgroundColor3=C.white,BorderSizePixel=0,Active=true,ZIndex=53})
corner(slider,8)
local sliderGradient=make("UIGradient",slider,{Color=ColorSequence.new(Color3.new(0,0,0),Color3.new(1,1,1))})
local sliderThumb=make("Frame",slider,{Size=UDim2.fromOffset(11,25),Position=UDim2.fromOffset(255,-5),BackgroundColor3=C.white,BorderSizePixel=0,ZIndex=55,Active=false})
corner(sliderThumb,5);border(sliderThumb,C.bg,0,1)
local pickerNote=text(picker,"По кругу — оттенок, к краю — насыщеннее",UDim2.fromOffset(23,359),UDim2.fromOffset(334,19),11,false,C.muted)
pickerNote.ZIndex=52
local pickerDone=make("TextButton",picker,{Position=UDim2.fromOffset(21,391),Size=UDim2.fromOffset(334,39),BackgroundColor3=C.darkgreen,Text="ГОТОВО",TextColor3=C.green,TextSize=14,Font=Enum.Font.GothamBold,AutoButtonColor=false,BorderSizePixel=0,ZIndex=53})
corner(pickerDone,10)
local chosenKey="generators"
local h,s,v=0,1,1
local function applyColor()
 local color=Color3.fromHSV(h,s,v)
 if editableColor(chosenKey) then palette[chosenKey]=color;paintSwatches(chosenKey);scheduleSettingsSave() end
 sample.BackgroundColor3=color
 local r=wheelRadius*(.05+.95*s)
 local angle=h*math.pi*2
 pickerDot.Position=UDim2.fromOffset(110+math.cos(angle)*r-7,110+math.sin(angle)*r-7)
 sliderThumb.Position=UDim2.fromOffset(math.floor(v*256),-5)
 sliderGradient.Color=ColorSequence.new(Color3.new(0,0,0),Color3.fromHSV(h,s,1))
end
openPicker=function(key)
 if not editableColor(key) then return end
 chosenKey=key
 local names={players="Игроки • обводка",generators="Генераторы",pumpkins="Тыквы",pallets="Паллеты",warAllies="Союзники WARFARE",warEnemies="Противники WARFARE",warFPV="FPV WARFARE",warFov="FOV • круг",warAim="Цель WARFARE"}
 pickerHeading.Text="Цвет  •  "..(names[key] or "ESP")
 h,s,v=palette[key]:ToHSV()
 pickerLayer.Visible=true
 applyColor()
end
local function wheelInput(pos)
 local xy=Vector2.new(pos.X,pos.Y)-wheel.AbsolutePosition-wheelCenter
 local angle=math.atan2(xy.Y,xy.X)
 if angle<0 then angle=angle+2*math.pi end
 h=(angle/(2*math.pi))%1
 s=math.clamp((xy.Magnitude/wheelRadius-.05)/.95,0,1)
 applyColor()
end
local function sliderInput(pos)
 v=math.clamp((pos.X-slider.AbsolutePosition.X)/slider.AbsoluteSize.X,0,1)
 applyColor()
end
listen(wheel.InputBegan,function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then wheelHeld=true;wheelInput(input.Position) end
end)
listen(slider.InputBegan,function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then sliderHeld=true;sliderInput(input.Position) end
end)
listen(UserInputService.InputChanged,function(input)
 if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then
  if wheelHeld then wheelInput(input.Position) end
  if sliderHeld then sliderInput(input.Position) end
 end
end)
listen(UserInputService.InputEnded,function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then wheelHeld=false;sliderHeld=false end
end)
listen(pickerDone.MouseButton1Click,function() pickerLayer.Visible=false end)
listen(pickerX.MouseButton1Click,function() pickerLayer.Visible=false end)


-- WARFARE shared declarations
local warFovCircle,warFovStroke,warStatus,warAimStatus
local warfareCleanup
do -- WARFARE UI scoped
-- WARFARE: separate profile, preserving all original Violence District controls.
local wh=panel(warContent,UDim2.fromOffset(14,14),UDim2.fromOffset(816,145),C.green)
make("UIGradient",wh,{Color=ColorSequence.new(Color3.fromRGB(9,30,18),Color3.fromRGB(9,19,24))})
text(wh,"WARFARE",UDim2.fromOffset(27,11),UDim2.fromOffset(650,54),35,true,C.green)
text(wh,"TEAM  •  FPV  •  WEAPON INFO",UDim2.fromOffset(30,68),UDim2.fromOffset(650,27),13,true)
warStatus=text(wh,"Команды: Roblox Team • FPV: модели",UDim2.fromOffset(30,91),UDim2.fromOffset(750,24),11,false,C.muted)
warAimStatus=text(wh,"Цель: ожидание",UDim2.fromOffset(30,117),UDim2.fromOffset(740,20),11,true,C.green)
local wm=panel(warContent,UDim2.fromOffset(14,172),UDim2.fromOffset(444,402))
local we=panel(warContent,UDim2.fromOffset(471,172),UDim2.fromOffset(359,402))
text(wm,"Основные функции",UDim2.fromOffset(18,8),UDim2.fromOffset(370,33),19,true,C.white)
text(we,"ESP • Подсветка",UDim2.fromOffset(18,8),UDim2.fromOffset(327,33),18,true,C.white)
local mscroll=make("ScrollingFrame",wm,{Position=UDim2.fromOffset(8,46),Size=UDim2.fromOffset(427,345),CanvasSize=UDim2.fromOffset(0,1130),ScrollBarThickness=3,ScrollBarImageColor3=C.green,BackgroundTransparency=1,BorderSizePixel=0})
local escroll=make("ScrollingFrame",we,{Position=UDim2.fromOffset(8,46),Size=UDim2.fromOffset(342,345),CanvasSize=UDim2.fromOffset(0,425),ScrollBarThickness=3,ScrollBarImageColor3=C.green,BackgroundTransparency=1,BorderSizePixel=0})
local function warRow(parent,y,key,heading,details,colorKey,binding)
 local isMain=parent==mscroll
 local w=isMain and 398 or 322
 local row=make("TextButton",parent,{Position=UDim2.fromOffset(5,y),Size=UDim2.fromOffset(w,74),Text="",BackgroundColor3=C.row,AutoButtonColor=false,BorderSizePixel=0})
 corner(row,10);hoverEffect(row)
 text(row,heading,UDim2.fromOffset(13,7),UDim2.fromOffset(230,27),14,true)
 text(row,details,UDim2.fromOffset(13,39),UDim2.fromOffset(252,22),10,false,C.muted)
 local x=w-54
 if colorKey then
  local chip=make("TextButton",row,{Position=UDim2.fromOffset(x-35,10),Size=UDim2.fromOffset(23,23),BackgroundColor3=palette[colorKey],Text="",BorderSizePixel=0,AutoButtonColor=false})
  corner(chip,6);addSwatch(colorKey,chip)
  listen(chip.MouseButton1Click,function() if openPicker then openPicker(colorKey) end end)
 end
 if binding then
  local keyButton=make("TextButton",row,{Position=UDim2.fromOffset(246,10),Size=UDim2.fromOffset(57,24),BackgroundColor3=C.card,Text=niceKey(keybind[binding]),TextColor3=C.green,TextSize=11,Font=Enum.Font.GothamBold,BorderSizePixel=0})
  corner(keyButton,6)
  bindButtons[binding]=keyButton
  listen(keyButton.MouseButton1Click,function() beginRebind(binding) end)
 end
 switch(row,key,x,41)
 listen(row.MouseButton1Click,function() toggle(key) end)
end
warRow(mscroll,0,"warAimPreview","AIM • наведение","Legit / Hard • бинд F10","warAim","warAim")
warRow(mscroll,82,"warFly","Fly","Полёт по WASD / Space",nil,"warFly")
warRow(mscroll,164,"warNoClip","NoClip","Проход сквозь препятствия",nil,"warNoClip")
warRow(mscroll,246,"warFov","FOV • круг","Цвет и радиус FOV","warFov")
warRow(mscroll,328,"warWallCheck","Wall Check","Проверять препятствия")
warRow(mscroll,410,"warTeamCheck","Team Check","Не выбирать своих тиммейтов")
warRow(mscroll,492,"warHoldAim","AIM • удержание","ПКМ или ЛКМ при стрельбе")
local aimModeRow=make("Frame",mscroll,{
 Position=UDim2.fromOffset(5,574),Size=UDim2.fromOffset(398,74),
 BackgroundColor3=C.row,BorderSizePixel=0
})
corner(aimModeRow,10)
text(aimModeRow,"Режим AIM",UDim2.fromOffset(13,8),UDim2.fromOffset(175,28),14,true,C.white)
text(aimModeRow,"Legit • плавно / Hard • сразу",UDim2.fromOffset(13,39),UDim2.fromOffset(220,24),10,false,C.muted)
local modeButtons={}
for _,opt in ipairs({{key="legit",name="LEGIT",x=242},{key="hard",name="HARD",x=317}}) do
 local btn=make("TextButton",aimModeRow,{
  Position=UDim2.fromOffset(opt.x,21),Size=UDim2.fromOffset(70,35),
  Text=opt.name,TextColor3=C.white,TextSize=12,Font=Enum.Font.GothamBold,
  BackgroundColor3=C.card,BorderSizePixel=0,AutoButtonColor=false
 })
 corner(btn,8)
 modeButtons[opt.key]=btn
 listen(btn.MouseButton1Click,function()
  warSettings.mode=opt.key
  for key,button in pairs(modeButtons) do
   tween(button,{BackgroundColor3=key==warSettings.mode and C.darkgreen or C.card},.18)
   button.TextColor3=key==warSettings.mode and C.green or C.white
  end
  scheduleSettingsSave()
 end)
end
for key,button in pairs(modeButtons) do
 button.BackgroundColor3=key==warSettings.mode and C.darkgreen or C.card
 button.TextColor3=key==warSettings.mode and C.green or C.white
end
-- Slider controls instead of plus/minus buttons. The values are display/
-- selection preferences, not modifications to remote damage or projectiles.
local warSliderState={dragging=false}
local function warValue(y,key,title,unit,minV,maxV,step)
 local row=make("Frame",mscroll,{
  Position=UDim2.fromOffset(5,y),Size=UDim2.fromOffset(398,73),
  BackgroundColor3=C.row,BorderSizePixel=0
 })
 corner(row,10)
 text(row,title,UDim2.fromOffset(14,5),UDim2.fromOffset(265,29),14,true)
 local value=text(row,"",UDim2.fromOffset(283,7),UDim2.fromOffset(99,27),13,true,C.green,Enum.TextXAlignment.Right)
 local slider=make("TextButton",row,{
  Position=UDim2.fromOffset(17,45),Size=UDim2.fromOffset(362,12),
  BackgroundColor3=Color3.fromRGB(59,76,71),BorderSizePixel=0,
  Text="",AutoButtonColor=false,Active=true
 })
 corner(slider,7)
 local track=make("Frame",slider,{
  Size=UDim2.new(0,0,1,0),BackgroundColor3=C.green,
  BorderSizePixel=0
 })
 corner(track,7)
 local knob=make("Frame",slider,{
  AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(0,.5),
  Size=UDim2.fromOffset(19,19),BackgroundColor3=C.white,
  BorderSizePixel=0,ZIndex=4
 })
 corner(knob,12);border(knob,C.green,0,1.5)
 local function render()
  value.Text=tostring(warSettings[key])..unit
  local alpha=math.clamp((warSettings[key]-minV)/(maxV-minV),0,1)
  track.Size=UDim2.new(alpha,0,1,0)
  knob.Position=UDim2.new(alpha,0,.5,0)
 end
 local function updateAt(x)
  local width=slider.AbsoluteSize.X
  if width<=0 then return end
  local alpha=math.clamp((x-slider.AbsolutePosition.X)/width,0,1)
  local raw=minV+alpha*(maxV-minV)
  warSettings[key]=math.clamp(math.floor(raw/step+.5)*step,minV,maxV)
  render();scheduleSettingsSave()
 end
 listen(slider.InputBegan,function(input)
  if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
   warSliderState.dragging=key
   updateAt(input.Position.X)
  end
 end)
 listen(UserInputService.InputChanged,function(input)
  if warSliderState.dragging==key and
    (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
   updateAt(input.Position.X)
  end
 end)
 listen(UserInputService.InputEnded,function(input)
  if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
   if warSliderState.dragging==key then warSliderState.dragging=false end
  end
 end)
 render()
end
warValue(660,"fov","FOV • радиус"," px",20,400,5)
warValue(739,"distance","Макс. дальность"," м",10,300,5)
warValue(818,"prediction","Упреждение движения"," %",0,100,5)
warValue(897,"smooth","Скорость Legit"," %",5,100,5)
warValue(976,"drop","Поправка по дальности"," %",0,100,5)
warRow(escroll,0,"warAllies","Союзники","Салатовая подсветка и контур","warAllies")
warRow(escroll,82,"warEnemies","Противники","Красная подсветка и контур","warEnemies")
warRow(escroll,164,"warNames","Никнеймы ESP","Цвет ника зависит от команды")
warRow(escroll,246,"warWeapons","Оружие в руках","Показывать Tool у персонажа")
warRow(escroll,328,"warFPV","FPV-дроны","Контур моделей дронов","warFPV")
bindVisual("warFly");bindVisual("warNoClip");bindVisual("warAim")
warFovCircle=make("Frame",gui,{Name="OX1DE_WarFOV",Position=UDim2.fromScale(.5,.5),AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(warSettings.fov*2,warSettings.fov*2),BackgroundTransparency=1,Visible=false,Active=false})
corner(warFovCircle,1000)
warFovStroke=border(warFovCircle,palette.warFov,.25,1.4)
local function setTab(tab)
 if tab~="warfare" and tab~="violence_district" then return end
 activeTab=tab
 content.Visible=tab=="violence_district"
 warContent.Visible=tab=="warfare"
 subtitleLabel.Text=GameModules[tab].subtitle
 tween(selectedNav,{BackgroundColor3=tab=="violence_district" and C.darkgreen or C.card},.15)
 tween(warNav,{BackgroundColor3=tab=="warfare" and C.darkgreen or C.card},.15)
 if tab=="warfare" then
  -- Avoid two Highlights on the same model and reclaim inactive slots.
  -- The old mode recreates its effects on demand when selected again.
  for player,fx in pairs(playerFx) do
   if fx.h then fx.h:Destroy() end
   if fx.bb then fx.bb:Destroy() end
   playerFx[player]=nil
  end
 end
end
listen(selectedNav.MouseButton1Click,function()setTab("violence_district")end)
listen(warNav.MouseButton1Click,function()setTab("warfare")end)

end -- WARFARE UI scoped

-- ESP: world objects ------------------------------------------------------
local function category(obj)
    local n=string.lower(obj.Name)
    if n:find("pumpkin",1,true) or n:find("jack_o_lantern",1,true) or n:find("jack-o-lantern",1,true) or n:find("jackolantern",1,true) or n:find("тыкв",1,true) then return "pumpkins" end
    if n:find("generator",1,true) or n:find("генератор",1,true) then return "generators" end
    if n:find("pallet",1,true) or n:find("паллет",1,true) or n:find("палет",1,true) or n:find("поддон",1,true) then return "pallets" end
    return nil
end
local function insidePlayer(obj)
    local n=obj
    while n and n~=Workspace do
        if n:IsA("Model") and Players:GetPlayerFromCharacter(n) then return true end
        n=n.Parent
    end
    return false
end
local function candidate(obj)
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return nil,nil end
    local kind=category(obj)
    if (not kind and not (obj.Parent and obj.Parent:IsA("Folder") and category(obj.Parent))) or insidePlayer(obj) then return nil,nil end
    if kind then
        local up=obj.Parent
        while up and up~=Workspace do
            if up:IsA("Model") and category(up)==kind then return up,kind end
            up=up.Parent
        end
        return obj,kind
    end
    if obj.Parent and obj.Parent:IsA("Folder") then
        local folderKind=category(obj.Parent)
        if folderKind then return obj,folderKind end
    end
    return nil,nil
end
local function inactive(obj,kind)
    if not obj or not obj.Parent or not obj:IsDescendantOf(Workspace) then return true end
    if kind=="pumpkins" then
        if readFlag(obj,{"Collected","IsCollected","Destroyed","Smashed","Broken"})==true then return true end
        if readFlag(obj,{"Active","IsActive"})==false then return true end
        local hasVisible=false
        if obj:IsA("BasePart") then
            hasVisible=obj.Transparency<.97
        else
            for _,v in ipairs(obj:GetDescendants()) do
                if v:IsA("BasePart") and v.Transparency<.97 then hasVisible=true;break end
            end
        end
        return not hasVisible
    end
    if kind=="generators" then
        return readFlag(obj,{"Completed","IsCompleted","Repaired","IsRepaired"})==true
    end
    if kind=="pallets" then
        if readFlag(obj,{"Destroyed","IsDestroyed","Broken","IsBroken","Dropped","IsDropped","Fallen","IsFallen","Used","IsUsed"})==true then return true end
        if readFlag(obj,{"Active","IsActive","Available","IsAvailable"})==false then return true end
        local p=partOf(obj)
        if p and p.Transparency>=.98 then return true end
    end
    return false
end
local function billboard(part,color,label)
    local bb=make("BillboardGui",gui,{Adornee=part,AlwaysOnTop=true,LightInfluence=0,MaxDistance=100000,Size=UDim2.fromOffset(215,44),StudsOffsetWorldSpace=Vector3.new(0,3.4,0)})
    local labelObject=make("TextLabel",bb,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text=label,TextColor3=color,Font=Enum.Font.GothamBold,TextSize=13,TextStrokeColor3=C.bg,TextStrokeTransparency=.1,TextWrapped=true})
    return bb,labelObject
end
local function clearPlayer(p)
    local fx=playerFx[p]
    if not fx then return end
    if fx.h then fx.h:Destroy() end
    if fx.bb then fx.bb:Destroy() end
    playerFx[p]=nil
end
local function addPlayer(p)
    if p==LocalPlayer or activeTab~="violence_district" then return end
    clearPlayer(p)
    local ch=p.Character
    if not ch then return end
    local head=ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart")
    if not head then return end
    local highlight=make("Highlight",ch,{
        Name="OX1DE_Person",Adornee=ch,
        DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,
        OutlineColor=palette.players,OutlineTransparency=0,
        FillTransparency=1,Enabled=false
    })
    local bb,label=billboard(head,C.unknown,p.DisplayName)
    bb.Name="OX1DE_Player_"..tostring(p.UserId)
    bb.Size=UDim2.fromOffset(160,29)
    bb.StudsOffsetWorldSpace=Vector3.new(0,2.5,0)
    bb.MaxDistance=225
    bb.Enabled=false
    label.TextSize=12
    label.TextWrapped=false
    label.TextTruncate=Enum.TextTruncate.AtEnd
    playerFx[p]={h=highlight,bb=bb,lab=label,part=head}
end
local function watchPlayer(p)
    if p==LocalPlayer then return end
    listen(p.CharacterAdded,function()
        task.delay(.4,function() if alive then addPlayer(p) end end)
    end)
    if p.Character then addPlayer(p) end
end
for _,p in ipairs(Players:GetPlayers()) do watchPlayer(p) end
listen(Players.PlayerAdded,watchPlayer)
listen(Players.PlayerRemoving,clearPlayer)
local function clearObject(obj)
    local fx=objectFx[obj]
    if not fx then return end
    if fx.h then fx.h:Destroy() end
    if fx.bb then fx.bb:Destroy() end
    objectFx[obj]=nil
end
-- Generator preview model cloning removed with the hero panel.
local function addObject(obj,kind)
    if objectFx[obj] or not obj:IsDescendantOf(Workspace) or inactive(obj,kind) then return end
    local part=partOf(obj)
    if not part then return end
    local up=obj.Parent
    while up and up~=Workspace do
        if objectFx[up] then return end
        up=up.Parent
    end
    if obj:IsA("Model") then
        for other in pairs(objectFx) do
            if other~=obj and other:IsDescendantOf(obj) then clearObject(other) end
        end
    end
    local color=palette[kind]
    local h=make("Highlight",obj,{Name="OX1DE_Object",Adornee=obj,FillColor=color,FillTransparency=kind=="pallets" and .93 or .66,OutlineColor=color,OutlineTransparency=0,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,Enabled=state[kind]})
    local labels={pumpkins="Тыква",generators="Генератор"}
    local bb,lab=billboard(part,color,kind=="pallets" and "" or (labels[kind] or "Объект"))
    if kind=="pallets" then
        bb.StudsOffsetWorldSpace=Vector3.new(0,-math.max(.8,part.Size.Y*.5+.7),0)
        bb.Size=UDim2.fromOffset(110,23)
        bb.MaxDistance=350
        lab.TextSize=12
    end
    objectFx[obj]={kind=kind,h=h,bb=bb,lab=lab,part=part}
    -- Safe test: no scene model cloning in the preview
end
local function scanOne(obj)
    local target,kind=candidate(obj)
    if target and state[kind] then addObject(target,kind) end
end
local scanPending=false
local function scanAll()
    if scanPending or not (state.generators or state.pumpkins or state.pallets) then return end
    scanPending=true
    task.spawn(function()
        local ok=pcall(function()
            local items=Workspace:GetDescendants()
            for i,obj in ipairs(items) do
                if not alive then break end
                if (obj:IsA("Model") or obj:IsA("BasePart")) and category(obj) then
                    scanOne(obj)
                end
                if i % 64==0 then task.wait() end
            end
        end)
        scanPending=false
    end)
end
onEspToggle=function(key,enabled)
 if enabled and (key=="generators" or key=="pumpkins" or key=="pallets") then scanAll() end
 if enabled and key=="warFPV" and warFpvStart then warFpvStart() end
end
listen(Workspace.DescendantAdded,function(obj)
    if not alive or not (state.generators or state.pumpkins or state.pallets) then return end
    if category(obj) then scanOne(obj) end
    if obj.Parent and category(obj.Parent) then scanOne(obj.Parent) end
end)
-- Restore selected object overlays when stored toggles were enabled on this device.
if state.generators or state.pumpkins or state.pallets then scanAll() end

-- Skill Check: scoped and rate-limited to keep gameplay responsive.
-- Client GUI cannot inspect individual pixels of a single textured meter.
do -- Scoped skill-check worker; also avoids Luau's 200-local top-level limit.
 local virtualInput
 local skillLastAt=-10
 local skillStatus="выключено"
 local lastGuiStatus,guiStatusTime="",0
 local cachedContainer,cachedNeedle,cachedZone=nil,nil,nil
 local lastContainerScan,lastPairScan=-10,-10
 local lastAligned,pressBusy=false,false
 local markerWords={"needle","pointer","cursor","indicator","arrow","sweep","marker","стрел","указател"}
 local targetWords={"target","success","perfect","hit","dark","black","shadow","safezone","zone","сектор","зона"}
 local frameWords={"skillcheck","skill_check","skill","timing","minigame","qte","reaction","проверканавыка"}

 local function enabled()
  return alive and state.autoSkill and activeTab=="violence_district" and not isOpen
 end
 local function hasWord(name,words)
  for _,word in ipairs(words) do
   if name:find(word,1,true) then return true end
  end
  return false
 end
 local function visibleGui(obj)
  if not obj or not obj.Parent or not obj:IsA("GuiObject") or obj:IsDescendantOf(gui) then return false end
  local node=obj
  while node and node~=PlayerGui do
   if node:IsA("GuiObject") and not node.Visible then return false end
   if node:IsA("ScreenGui") and not node.Enabled then return false end
   node=node.Parent
  end
  return node==PlayerGui and obj.AbsoluteSize.X>1 and obj.AbsoluteSize.Y>1
 end
 local function findContainer(now)
  if cachedContainer and visibleGui(cachedContainer) then return cachedContainer end
  cachedContainer,cachedNeedle,cachedZone=nil,nil,nil
  if now-lastContainerScan<1.25 then return nil end
  lastContainerScan=now
  -- Full PlayerGui traversal is expensive: at most once every 1.25 seconds,
  -- never from RenderStepped, and never for the OX1DE menu itself.
  local ok,all=pcall(function() return PlayerGui:GetDescendants() end)
  if not ok then return nil end
  for _,obj in ipairs(all) do
   if (obj:IsA("Frame") or obj:IsA("ImageLabel") or obj:IsA("CanvasGroup"))
       and visibleGui(obj) and hasWord(string.lower(obj.Name),frameWords) then
    cachedContainer=obj
    return obj
   end
  end
  return nil
 end
 local function resolveParts(container,now)
  if cachedNeedle and cachedZone and
     cachedNeedle:IsDescendantOf(container) and cachedZone:IsDescendantOf(container)
     and visibleGui(cachedNeedle) and visibleGui(cachedZone) then
   return cachedNeedle,cachedZone
  end
  cachedNeedle,cachedZone=nil,nil
  if now-lastPairScan<.75 then return nil,nil end
  lastPairScan=now
  local all=container:GetDescendants()
  if #all>500 then return nil,nil end -- Unknown GUI; do not spend time traversing it.
  local needles,zones={},{}
  for _,obj in ipairs(all) do
   if obj:IsA("GuiObject") and visibleGui(obj) then
    local n=string.lower(obj.Name)
    if hasWord(n,markerWords) then needles[#needles+1]=obj end
    if hasWord(n,targetWords) then zones[#zones+1]=obj end
   end
  end
  -- Require two distinct visible UI objects. A white image alone cannot be
  -- treated as a success zone and must never trigger a key press.
  local nearest=math.huge
  for _,needle in ipairs(needles) do
   local mid=needle.AbsolutePosition+needle.AbsoluteSize*.5
   for _,zone in ipairs(zones) do
    if needle~=zone then
     local middle=zone.AbsolutePosition+zone.AbsoluteSize*.5
     local distance=(mid-middle).Magnitude
     if distance<nearest then
      nearest=distance;cachedNeedle=needle;cachedZone=zone
     end
    end
   end
  end
  return cachedNeedle,cachedZone
 end
 local function aligned(needle,zone)
  local np,ns=needle.AbsolutePosition,needle.AbsoluteSize
  local zp,zs=zone.AbsolutePosition,zone.AbsoluteSize
  if math.min(ns.X,ns.Y,zs.X,zs.Y)<=0 then return false end
  local nx,ny=np.X+ns.X*.5,np.Y+ns.Y*.5
  local zx,zy=zp.X+zs.X*.5,zp.Y+zs.Y*.5
  -- Don't fire when the "target zone" is the entire screen.
  local camera=Workspace.CurrentCamera
  if camera and (zs.X>camera.ViewportSize.X*.6 or zs.Y>camera.ViewportSize.Y*.6) then return false end
  if (needle.Rotation~=0 or zone.Rotation~=0) and
     math.abs(nx-zx)<math.max(70,zs.X) and math.abs(ny-zy)<math.max(70,zs.Y) then
   local diff=(needle.Rotation-zone.Rotation+540)%360-180
   return math.abs(diff)<=9
  end
  local tolerance=math.min(zs.X*.10,6)
  return math.abs(ny-zy)<=math.max(zs.Y,15)
     and nx>=zp.X+tolerance and nx<=zp.X+zs.X-tolerance
 end
 local function pressOnce()
  if pressBusy or not enabled() or os.clock()-skillLastAt<.65 then return end
  pressBusy=true
  skillLastAt=os.clock() -- cooldown even on input failure
  local ok=false
  if not virtualInput then
   pcall(function() virtualInput=game:GetService("VirtualInputManager") end)
  end
  if virtualInput then
   ok=pcall(function()
    virtualInput:SendKeyEvent(true,Enum.KeyCode.Space,false,game)
    task.wait(.025)
    virtualInput:SendKeyEvent(false,Enum.KeyCode.Space,false,game)
   end)
  end
  if not ok and type(keypress)=="function" and type(keyrelease)=="function" then
   ok=pcall(function() keypress(0x20);task.wait(.025);keyrelease(0x20) end)
  end
  skillStatus=ok and "Space отправлен" or "ввод недоступен"
  pressBusy=false
 end
 task.spawn(function()
  while alive do
   local now=os.clock()
   local delaySeconds=.35
   if not state.autoSkill then
    skillStatus="выключено"
    lastAligned=false
   elseif activeTab~="violence_district" then
    skillStatus="неактивен в WARFARE"
    lastAligned=false
   elseif isOpen then
    skillStatus="пауза: меню открыто"
    lastAligned=false
   else
    local container=findContainer(now)
    if not container then
     skillStatus="шкала не найдена"
     lastAligned=false
     delaySeconds=.3
    else
     local needle,zone=resolveParts(container,now)
     if not needle or not zone then
      skillStatus="нет маркера / зоны"
      lastAligned=false
      delaySeconds=.18
     else
      local hit=aligned(needle,zone)
      if hit and not lastAligned then task.spawn(pressOnce) end
      lastAligned=hit
      if now-skillLastAt>.45 then
       skillStatus=hit and "совпадение" or "ожидание"
      end
      delaySeconds=.08
     end
    end
   end
   if skillSubtitle and skillSubtitle.Parent and
       (skillStatus~=lastGuiStatus or now-guiStatusTime>=1.5) then
    skillSubtitle.Text="Статус: "..skillStatus
    lastGuiStatus=skillStatus
    guiStatusTime=now
   end
   task.wait(delaySeconds)
  end
 end)
end -- skill-check worker

-- Local movement ----------------------------------------------------------
local function stopFly()
    if flyVelocity then flyVelocity:Destroy();flyVelocity=nil end
    if flyGyro then flyGyro:Destroy();flyGyro=nil end
    local ch=LocalPlayer.Character
    local h=ch and ch:FindFirstChildOfClass("Humanoid")
    if h then h.PlatformStand=false end
end
local function startFly()
    stopFly()
    local r=root()
    if not r then return end
    local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand=true end
    flyVelocity=make("BodyVelocity",r,{Velocity=Vector3.zero,MaxForce=Vector3.new(10000000,10000000,10000000),P=10000})
    flyGyro=make("BodyGyro",r,{MaxTorque=Vector3.new(10000000,10000000,10000000),P=8000,D=200,CFrame=r.CFrame})
end
local function restore()
    for p,value in pairs(collisions) do
        if p.Parent then p.CanCollide=value end
        collisions[p]=nil
    end
end
listen(RunService.Stepped,function()
    if not ((activeTab=="violence_district" and state.noclip) or (activeTab=="warfare" and state.warNoClip)) then return end
    local ch=LocalPlayer.Character
    if not ch then return end
    for _,v in ipairs(ch:GetDescendants()) do
        if v:IsA("BasePart") then
            if collisions[v]==nil then collisions[v]=v.CanCollide end
            v.CanCollide=false
        end
    end
end)
listen(RunService.RenderStepped,function()
    if not alive or not ((activeTab=="violence_district" and state.fly) or (activeTab=="warfare" and state.warFly)) then return end
    local r=root()
    if not r then return end
    if not flyVelocity or not flyVelocity.Parent then startFly() end
    local cam=Workspace.CurrentCamera
    if not cam then return end
    local cf=cam.CFrame
    local move=Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then move+=cf.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then move-=cf.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then move+=cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then move-=cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move+=Vector3.yAxis end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move-=Vector3.yAxis end
    if UserInputService.TouchEnabled then
        local h=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then move+=h.MoveDirection end
    end
    if move.Magnitude>.001 then move=move.Unit*56 end
    if flyVelocity then flyVelocity.Velocity=move end
    if flyGyro then flyGyro.CFrame=cf end
end)
local function recoverGui()
    if not alive then return end
    local current=(guiParent and guiParent.Parent and guiParent) or LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if current and gui.Parent~=current then
        pcall(function() gui.Parent=current end)
    end
    if gui.Parent and not gui.Enabled then gui.Enabled=true end
end
listen(LocalPlayer.CharacterAdded,function()
    -- Character transitions can happen when returning to the lobby.
    -- Close the window first so mouse movement returns to Roblox.
    if isOpen then setVisible(false) end
    stopFly();restore()
    task.delay(.6,function()
        if alive then
            recoverGui()
            if (activeTab=="violence_district" and state.fly) or (activeTab=="warfare" and state.warFly) then startFly() end
        end
    end)
end)
-- If the game teleports to another Place, client GUI and script state are reset.
-- Some execution environments provide a queue function; use it only when present.
local rejoinSource='loadstring(game:HttpGet("https://raw.githubusercontent.com/romanavdieienkoox1de-create/OX1DE_Head.lua/main/OX1DE_Cheating.lua"))()'
local queueTeleport=queue_on_teleport
if type(queueTeleport)~="function" then
    pcall(function() if syn and type(syn.queue_on_teleport)=="function" then queueTeleport=syn.queue_on_teleport end end)
end
if type(queueTeleport)=="function" then
    listen(LocalPlayer.OnTeleport,function(st)
        if st==Enum.TeleportState.Started then pcall(queueTeleport,rejoinSource) end
    end)
end

do -- WARFARE runtime scoped
-- WARFARE local-world visualization: team, weapon and FPV outlines.
local warfarePlayers,warfareDrones={},{}
local function warfareTeamKey(player)
 if not player then return nil end
 -- Prefer actual Roblox team membership. Some games leave Neutral=true
 -- even while assigning a custom team.
 if player.Team then return "team:"..string.lower(player.Team.Name) end
 -- WARFARE variants may store the team on Player or Character instead.
 for _,key in ipairs({"TeamId","TeamID","TeamName","Team","Faction","FactionId","Side","SideId","Squad","Army","Nation","Group"}) do
  for _,source in ipairs({player,player.Character}) do
   if source then
    local value=source:GetAttribute(key)
    if value==nil then
     local instance=source:FindFirstChild(key)
     if instance and instance:IsA("ValueBase") then value=instance.Value end
    end
    if type(value)=="string" and value~="" then
     return string.lower(key)..":"..string.lower(value)
    elseif type(value)=="number" then
     return string.lower(key)..":"..tostring(value)
    end
   end
  end
 end
 -- BrickColor is a useful fallback when the game does use Roblox teams,
 -- but the Team instance is not replicated.
 if not player.Neutral and player.TeamColor then
  return "teamcolor:"..tostring(player.TeamColor.Number)
 end
 return nil
end
local function warfareTeamKind(player)
 local mine,theirs=warfareTeamKey(LocalPlayer),warfareTeamKey(player)
 if mine and theirs then
  return mine==theirs and "warAllies" or "warEnemies"
 end
 return nil
end
local function clearWarfarePlayer(player)
 local fx=warfarePlayers[player]
 if not fx then return end
 if fx.highlight then fx.highlight:Destroy() end
 if fx.billboard then fx.billboard:Destroy() end
 if fx.weaponBillboard then fx.weaponBillboard:Destroy() end
 warfarePlayers[player]=nil
end
local function addWarfarePlayer(player)
 local character=player.Character
 local head=character and (character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart"))
 if not head then return nil end
 -- Put the Highlight outside the player's rig. This avoids nested
 -- Highlight rendering conflicts and survives custom character hierarchy.
 local highlight=make("Highlight",Workspace,{
  Name="OX1DE_WARFARE_Player_"..tostring(player.UserId),
  Adornee=character,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,
  FillColor=C.white,FillTransparency=.42,
  OutlineColor=C.white,OutlineTransparency=0,Enabled=false
 })
 local bill,label=billboard(head,C.white,player.DisplayName)
 bill.MaxDistance=320
 bill.Size=UDim2.fromOffset(166,41)
 bill.StudsOffsetWorldSpace=Vector3.new(0,2.6,0)
 bill.Enabled=false
 label.TextSize=12
 label.TextStrokeTransparency=.05
 label.TextWrapped=true
 label.TextTruncate=Enum.TextTruncate.AtEnd
 -- Separate weapon label below the character's feet; name stays over the head.
 local footRoot=character:FindFirstChild("HumanoidRootPart") or head
 local humanoid=character:FindFirstChildOfClass("Humanoid")
 local footOffset=math.max(1.8,(humanoid and humanoid.HipHeight or 1.5)+footRoot.Size.Y*.5)+.55
 local weaponBillboard,weaponLabel=billboard(footRoot,C.white,"")
 weaponBillboard.Name="OX1DE_WARFARE_Weapon_"..tostring(player.UserId)
 weaponBillboard.Size=UDim2.fromOffset(170,23)
 weaponBillboard.StudsOffsetWorldSpace=Vector3.new(0,-footOffset,0)
 weaponBillboard.MaxDistance=270
 weaponBillboard.Enabled=false
 weaponLabel.TextSize=12
 weaponLabel.TextWrapped=false
 weaponLabel.TextTruncate=Enum.TextTruncate.AtEnd
 weaponLabel.TextStrokeTransparency=.08
 local fx={character=character,head=head,highlight=highlight,billboard=bill,label=label,
   weaponBillboard=weaponBillboard,weaponLabel=weaponLabel}
 warfarePlayers[player]=fx
 return fx
end
local droneWords={"fpv","drone","uav","copter","quadrocopter","quadcopter","дрон","бпла","квадрокоптер"}
local function isWarfareDrone(object)
 if not object or not object:IsA("Model") then return false end
 local name=string.lower(object.Name)
 for _,word in ipairs(droneWords) do
  if name:find(word,1,true) then return true end
 end
 return false
end
local function deadWarfareDrone(object)
 if not object or not object:IsDescendantOf(Workspace) then return true end
 if readFlag(object,{"Destroyed","IsDestroyed","Broken","Exploded"})==true then return true end
 return partOf(object)==nil
end
local function addWarfareDrone(object)
 if not alive or not state.warFPV or not isWarfareDrone(object)
    or deadWarfareDrone(object) or warfareDrones[object] then return end
 local parent=object.Parent
 while parent and parent~=Workspace do
  if isWarfareDrone(parent) then return end
  parent=parent.Parent
 end
 warfareDrones[object]=make("Highlight",object,{
  Name="OX1DE_WARFARE_FPV",Adornee=object,FillTransparency=1,
  OutlineColor=palette.warFPV,OutlineTransparency=0,
  DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,Enabled=false
 })
end
local warScanBusy=false
warFpvStart=function()
 if warScanBusy or not state.warFPV then return end
 warScanBusy=true
 task.spawn(function()
  pcall(function()
   for i,object in ipairs(Workspace:GetDescendants()) do
    if not alive or not state.warFPV then break end
    if isWarfareDrone(object) then addWarfareDrone(object) end
    if i%96==0 then task.wait() end
   end
  end)
  warScanBusy=false
 end)
end
listen(Workspace.DescendantAdded,function(object)
 if alive and state.warFPV and isWarfareDrone(object) then addWarfareDrone(object) end
end)
if state.warFPV then warFpvStart() end

local warAimMark=make("TextLabel",gui,{
 Name="OX1DE_WARFARE_Target",AnchorPoint=Vector2.new(.5,1),
 Position=UDim2.fromOffset(-500,-500),Size=UDim2.fromOffset(176,27),
 BackgroundColor3=Color3.fromRGB(22,24,26),BackgroundTransparency=.22,
 TextColor3=palette.warAim,TextStrokeTransparency=.3,TextSize=12,
 Font=Enum.Font.GothamBold,Text="",
 BorderSizePixel=0,Visible=false,Active=false
})
corner(warAimMark,7)
local function warfareTarget()
 local cam=Workspace.CurrentCamera
 local ownRoot=root()
 if not cam or not ownRoot then return nil,nil,nil end
 local screen=cam.ViewportSize
 local center=Vector2.new(screen.X*.5,screen.Y*.5)
 local maxRange=warSettings.distance*3.57
 local best,bestPoint,bestDist,bestAimPoint=nil,nil,math.huge,nil
 local ownTeam=warfareTeamKey(LocalPlayer)
 for _,player in ipairs(Players:GetPlayers()) do
  if player~=LocalPlayer and player.Character then
   local theirTeam=warfareTeamKey(player)
   -- Never choose a known teammate, even if strict Team Check is disabled.
   local friend=ownTeam~=nil and theirTeam~=nil and ownTeam==theirTeam
   local allowed=not friend and (not state.warTeamCheck or
       (ownTeam~=nil and theirTeam~=nil and ownTeam~=theirTeam))
   if allowed then
    local ch=player.Character
    -- The Head part is used at its current world position: crouching and
    -- prone animations shift it automatically, unlike a fixed torso offset.
    local part=ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart")
    local hum=ch:FindFirstChildOfClass("Humanoid")
    if part and hum and hum.Health>0 and (ownRoot.Position-part.Position).Magnitude<=maxRange then
     -- Roblox-only approximate correction; distance controls how far
     -- movement lead and vertical aim offset shift the camera target.
     -- Actual projectile physics vary per WARFARE weapon.
     local range=(ownRoot.Position-part.Position).Magnitude
     local distanceFactor=math.clamp(range/300,0,2.5)
     local lead=part.Position+
       part.AssemblyLinearVelocity*(warSettings.prediction/100)*distanceFactor*.30+
       Vector3.new(0,(warSettings.drop/100)*distanceFactor*distanceFactor*9,0)
     local point,visible=cam:WorldToViewportPoint(lead)
     if visible and point.Z>0 then
      local xy=Vector2.new(point.X,point.Y)
      local px=(xy-center).Magnitude
      -- Choose nearest player in 3D, not the smallest pixel distance to
      -- the crosshair. Pixel distance is used only as a tie-breaker.
      if px<=warSettings.fov and (range<bestDist-1 or
       (math.abs(range-bestDist)<=1 and (not bestPoint or px<(bestPoint-center).Magnitude))) then
       local unobstructed=true
       if state.warWallCheck then
        local origin=cam.CFrame.Position
        local ray=lead-origin
        local params=RaycastParams.new()
        params.FilterType=Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances={LocalPlayer.Character}
        local hit=Workspace:Raycast(origin,ray,params)
        unobstructed=not hit or hit.Instance:IsDescendantOf(ch)
       end
       if unobstructed then best,bestPoint,bestDist,bestAimPoint=player,xy,range,lead end
      end
     end
    end
   end
  end
 end
 return best,bestPoint,bestDist,bestAimPoint
end
-- FOV ring follows the viewport center; the value is the radius in pixels.
listen(RunService.RenderStepped,function()
 if not alive then return end
 local camera=Workspace.CurrentCamera
 local show=activeTab=="warfare" and state.warAimPreview and state.warFov and not isOpen
 warFovCircle.Visible=show
 if not camera or not show then return end
 local size=camera.ViewportSize
 warFovCircle.Size=UDim2.fromOffset(warSettings.fov*2,warSettings.fov*2)
 warFovCircle.Position=UDim2.fromOffset(size.X*.5,size.Y*.5)
end)
local warUpdateClock=0
local warCurrentTarget,warCurrentAimPoint=nil,nil
listen(RunService.RenderStepped,function(delta)
 if not alive then return end
 warUpdateClock+=delta
 if warUpdateClock<.07 then return end
 warUpdateClock=0
 local isWar=activeTab=="warfare"
 local showFov=isWar and state.warAimPreview and state.warFov and not isOpen
 warFovCircle.Visible=showFov
 warFovCircle.Size=UDim2.fromOffset(warSettings.fov*2,warSettings.fov*2)
 warFovStroke.Color=palette.warFov
 warAimMark.TextColor3=palette.warAim
 warAimMark.Visible=false
 if not isWar or not state.warAimPreview then
  warCurrentTarget,warCurrentAimPoint=nil,nil
  return
 end
 local target,position,_,goal=warfareTarget()
 warCurrentTarget,warCurrentAimPoint=target,goal
 if warAimStatus and warAimStatus.Parent then
  warAimStatus.Text=target and ("AIM "..string.upper(warSettings.mode).." • "..target.DisplayName.." • "..(state.warHoldAim and "ПКМ или ЛКМ" or "активен")) or "AIM: нет доступного противника"
 end
 if target and position then
  warAimMark.Text=target.DisplayName.."  •  ЦЕЛЬ"
  warAimMark.Position=UDim2.fromOffset(position.X,position.Y-27)
  warAimMark.Visible=not isOpen
 end
end)
-- Run after Roblox's normal camera update so the AIM actually follows a
-- visible avatar. It never fires weapons or changes game hit detection.
local aimRenderName="OX1DE_WARFARE_AIM_"..tostring(LocalPlayer.UserId)
local aimRenderEnabled=false
local registered=pcall(function()
 RunService:BindToRenderStep(aimRenderName,Enum.RenderPriority.Camera.Value+1,function(dt)
  if not alive or isOpen or activeTab~="warfare" or not state.warAimPreview then return end
  -- When "hold" is on, aim while RMB is held OR while shooting with LMB.
  -- This allows tracking a target without using ADS.
  if state.warHoldAim and not (
   UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
   or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
  ) then return end
  local target,goal=warCurrentTarget,warCurrentAimPoint
  local hum=target and target.Character and target.Character:FindFirstChildOfClass("Humanoid")
  if not target or not target.Character or not hum or hum.Health<=0 or not goal then
   -- Target died or despawned. Refresh nearest valid enemy immediately.
   local nextTarget,_,_,nextGoal=warfareTarget()
   target,goal=nextTarget,nextGoal
   warCurrentTarget,warCurrentAimPoint=target,goal
  end
  if not target or not goal then return end
  local cam=Workspace.CurrentCamera
  if not cam then return end
  -- Refresh the head at render rate, without scanning every other player.
  -- This keeps AIM attached to a moving/crouching head between target scans.
  local head=target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")
  local ownRoot=root()
  if not head or not ownRoot then return end
  local range=(ownRoot.Position-head.Position).Magnitude
  if range>warSettings.distance*3.57 then return end
  local distanceFactor=math.clamp(range/300,0,2.5)
  goal=head.Position+
   head.AssemblyLinearVelocity*(warSettings.prediction/100)*distanceFactor*.30+
   Vector3.new(0,(warSettings.drop/100)*distanceFactor*distanceFactor*9,0)
  warCurrentAimPoint=goal
  local dir=goal-cam.CFrame.Position
  if dir.Magnitude<.01 then return end
  local aimFrame=CFrame.lookAt(cam.CFrame.Position,goal)
  if warSettings.mode=="hard" then
   -- Hard: snap directly; the target is refreshed when it is downed
   -- or dies, so the next nearest valid opponent is selected.
   cam.CFrame=aimFrame
  else
   -- Legit: higher smooth value follows faster, with frame-rate independence.
   local speed=2+(warSettings.smooth/100)*22
   local alpha=1-math.exp(-speed*math.min(dt,.075))
   cam.CFrame=cam.CFrame:Lerp(aimFrame,alpha)
  end
 end)
 aimRenderEnabled=true
end)
if not registered or not aimRenderEnabled then
 warAimStatus.Text="AIM: управление камерой недоступно"
end

local warStatusClock=0
listen(RunService.Heartbeat,function(dt)
 if not alive then return end
 warStatusClock+=dt
 if warStatusClock<.24 then return end
 warStatusClock=0
 local selected=activeTab=="warfare"
 local my=root()
 local teamPlayers,otherPlayers,unknownPlayers,droneCount=0,0,0,0
 for _,player in ipairs(Players:GetPlayers()) do
  if player~=LocalPlayer then
   local kind=warfareTeamKind(player)
   local fx=warfarePlayers[player]
   if fx and (fx.character~=player.Character or not fx.head.Parent
      or not fx.highlight or not fx.highlight.Parent) then
    clearWarfarePlayer(player);fx=nil
   end
   local outlined=selected and (kind~=nil and state[kind] or false)
   local unknown=selected and kind==nil and state.warNames and (state.warAllies or state.warEnemies)
   local named=selected and state.warNames and (outlined or unknown or state.warWeapons)
   local need=outlined or named or (selected and state.warWeapons)
   if need and not fx then fx=addWarfarePlayer(player) end
   if fx then
    fx.billboard.Enabled=named and true or false
    fx.highlight.Enabled=outlined and true or false
    fx.highlight.OutlineColor=kind and palette[kind] or C.white
    fx.highlight.FillColor=kind and palette[kind] or C.white
    fx.label.TextColor3=kind and palette[kind] or C.white
    fx.weaponLabel.TextColor3=kind and palette[kind] or C.white
    local heldWeapon=nil
    if selected and state.warWeapons then
     local character=player.Character
     local tool=character and character:FindFirstChildOfClass("Tool")
     if tool then
      heldWeapon=tool.Name
     elseif character then
      for _,key in ipairs({"EquippedWeapon","WeaponName","CurrentWeapon","HeldWeapon"}) do
       local value=character:GetAttribute(key)
       if type(value)=="string" and value~="" then heldWeapon=value;break end
      end
     end
    end
    fx.weaponBillboard.Enabled=selected and state.warWeapons and heldWeapon~=nil
    fx.weaponLabel.Text=heldWeapon or ""
    if named then
     local distance=my and fmtDistance(my.Position,fx.head.Position) or "?"
     local nick=player.DisplayName
     if nick=="" then nick=player.Name end
     local len= utf8 and utf8.len and utf8.len(nick)
     if len and len>17 then
      local cut=utf8.offset(nick,18)
      if cut then nick=string.sub(nick,1,cut-1).."…" end
     elseif not len and #nick>22 then
      nick=string.sub(nick,1,19).."…"
     end
     fx.label.Text=nick.."  •  "..tostring(distance).." м"
    end
   end
   if kind=="warAllies" then teamPlayers+=1 elseif kind=="warEnemies" then otherPlayers+=1 else unknownPlayers+=1 end
  end
 end
 for object,highlight in pairs(warfareDrones) do
  if deadWarfareDrone(object) then
   highlight:Destroy();warfareDrones[object]=nil
  else
   highlight.Enabled=selected and state.warFPV
   highlight.OutlineColor=palette.warFPV
   if highlight.Enabled then droneCount+=1 end
  end
 end
 if selected then
  local team=warfareTeamKey(LocalPlayer)
  warStatus.Text=team and ("Свои: "..teamPlayers.."  •  Враги: "..otherPlayers.."  •  Не определены: "..unknownPlayers.."  •  FPV: "..droneCount)
   or "Команда не определена: нужна проверка Place ID WARFARE"
 end
end)
task.spawn(function()
 while alive do
  task.wait(18)
  if alive and state.warFPV then warFpvStart() end
 end
end)

warfareCleanup=function()
 pcall(function() RunService:UnbindFromRenderStep(aimRenderName) end)
 if warFovCircle then warFovCircle.Visible=false end
 if warAimMark then warAimMark.Visible=false end
 for player in pairs(warfarePlayers) do clearWarfarePlayer(player) end
 for object,highlight in pairs(warfareDrones) do
  if highlight then highlight:Destroy() end
  warfareDrones[object]=nil
 end
end
end -- WARFARE runtime scoped

-- BillboardGui follows character positions directly on every render frame.
-- No on-screen repositioning or collision-offset hopping.
local lastFly,lastNoClip=false,false
local accumulated=0
listen(RunService.Heartbeat,function(dt)
    if not alive then return end
    local flyNow=(activeTab=="violence_district" and state.fly) or (activeTab=="warfare" and state.warFly)
    if flyNow~=lastFly then
        lastFly=flyNow
        if lastFly then startFly() else stopFly() end
    end
    local noclipNow=(activeTab=="violence_district" and state.noclip) or (activeTab=="warfare" and state.warNoClip)
    if noclipNow~=lastNoClip then
        lastNoClip=noclipNow
        if not lastNoClip then restore() end
    end
    accumulated+=dt
    if accumulated<.33 then return end
    accumulated=0
    local my=root()
    local nPlayer,nGenerator,nPumpkin=0,0,0
    for player,fx in pairs(playerFx) do
        if not player.Parent or not player.Character or not fx.part.Parent then
            clearPlayer(player)
        else
            nPlayer+=1
            local r=role(player)
            local shown=activeTab=="violence_district" and
              ((r=="killer" and state.killers) or (r~="killer" and state.players))
            fx.bb.Enabled=shown
            fx.h.Enabled=shown
            fx.h.OutlineColor=palette.players
            -- Show one compact nickname instead of DisplayName plus repeated username.
            local nickname=player.DisplayName
            if nickname=="" then nickname=player.Name end
            local maxChars=19
            local chars=utf8 and utf8.len and utf8.len(nickname)
            if chars and chars>maxChars then
                local cut=utf8.offset(nickname,maxChars+1)
                if cut then nickname=string.sub(nickname,1,cut-1).."…" end
            elseif not chars and #nickname>25 then
                nickname=string.sub(nickname,1,22).."…"
            end
            fx.lab.TextColor3=r=="killer" and C.red or r=="survivor" and C.green or C.white
            fx.lab.Text=nickname.."  •  "..(my and fmtDistance(my.Position,fx.part.Position) or "?").." м"
        end
    end
    for obj,fx in pairs(objectFx) do
        if inactive(obj,fx.kind) or not fx.part.Parent then
            clearObject(obj)
        else
            fx.h.Enabled=state[fx.kind]
            fx.bb.Enabled=state[fx.kind]
            fx.h.FillColor=palette[fx.kind]
            fx.h.OutlineColor=palette[fx.kind]
            fx.lab.TextColor3=palette[fx.kind]
            local distance=(my and fmtDistance(my.Position,fx.part.Position) or "?").." м"
            if fx.kind=="pallets" then
                fx.lab.Text=distance
            else
                local labels={pumpkins="Тыква",generators="Генератор"}
                fx.lab.Text=(labels[fx.kind] or "Объект").."  •  "..distance
            end
            if fx.kind=="pumpkins" then nPumpkin+=1 elseif fx.kind=="generators" then nGenerator+=1 end
        end
    end
    if activeTab=="violence_district" then
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LocalPlayer and p.Character and not playerFx[p] then addPlayer(p) end
        end
    end
    if foundText and foundText.Parent then
        foundText.Text=string.format("Найдено: игроков %d  •  генераторов %d  •  тыкв %d",nPlayer,nGenerator,nPumpkin)
    end
    if countText and countText.Parent then
        countText.Text=string.format("Игроков: %d\nГенераторов: %d\nТыкв: %d",nPlayer,nGenerator,nPumpkin)
    end
end)
task.spawn(function()
    while alive do
        task.wait(20)
        if alive then
            recoverGui()
            -- Changed map objects are normally discovered through DescendantAdded.
            -- A slow fallback scan handles streaming / reparented collections.
            scanAll()
        end
    end
end)
_G.OX1DE_CHEATING_STOP=function()
    saveSettingsNow()
    alive=false;state.fly=false;state.noclip=false;state.warFly=false;state.warNoClip=false;state.warAimPreview=false
    state.autoSkill=false
    stopFly();restore()
    if isOpen then stopMenuMouse() end
    pcall(function() ContextActionService:UnbindAction("OX1DE_MenuKey") end)
    if cameraConn then cameraConn:Disconnect() end
    for _,c in ipairs(connections) do c:Disconnect() end
    for p in pairs(playerFx) do clearPlayer(p) end
    for obj in pairs(objectFx) do clearObject(obj) end
    if warfareCleanup then pcall(warfareCleanup) end
    _G.OX1DE_CHEATING_STOP=nil
    _G.OX1DE_LOCAL_TOGGLE=nil
    if gui then gui:Destroy() end
end
