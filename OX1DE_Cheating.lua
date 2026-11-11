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
local GameModules={violence_district={title="Район насилия",subtitle="VIOLENCE DISTRICT"}}
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
local state={players=false,killers=false,generators=false,pumpkins=false,pallets=false,windows=false,fly=false,noclip=false,autoSkill=true}
local palette={players=Color3.fromRGB(255,255,255),killers=C.red,survivors=C.green,generators=C.cyan,pumpkins=C.orange,pallets=Color3.fromRGB(245,192,65),windows=Color3.fromRGB(245,192,65)}
local function editableColor(key)
 return key=="players" or key=="generators" or key=="pumpkins" or key=="pallets" or key=="windows"
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
local window=make("Frame",gui,{
 Name="OX1DEWindow",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
 Size=UDim2.fromOffset(1050,676),BackgroundColor3=C.bg,BorderSizePixel=0,ClipsDescendants=true
})
corner(window,22)
border(window,C.green,.28,1.6)
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
text(header,ActiveGame.subtitle,UDim2.fromOffset(31,53),UDim2.fromOffset(490,18),10,false,C.muted)
local keybind={menu=Enum.KeyCode.RightShift,fly=Enum.KeyCode.F6,noclip=Enum.KeyCode.F7}
local bindButtons={}
local waitingFor=nil
local refreshMenuSink
local function niceKey(key)
 if not key or key==Enum.KeyCode.Unknown then return "НАЗНАЧИТЬ" end
 local aliases={RightShift="Right Shift",LeftShift="Left Shift",LeftControl="L Ctrl",RightControl="R Ctrl",Backspace="Backspace"}
 return aliases[key.Name] or key.Name
end
local menuBind=make("TextButton",header,{
 Position=UDim2.fromOffset(666,22),Size=UDim2.fromOffset(197,41),BackgroundColor3=C.card,
 Text="",AutoButtonColor=false,BorderSizePixel=0
})
corner(menuBind,10);border(menuBind,C.edge,.53,1)
local menuBindText=text(menuBind,"Right Shift  •  БИНД МЕНЮ",UDim2.fromOffset(8,0),UDim2.new(1,-16,1,0),12,true,C.green,Enum.TextXAlignment.Center)
local minimize=make("TextButton",header,{Position=UDim2.fromOffset(954,22),Size=UDim2.fromOffset(40,41),BackgroundColor3=C.card,Text="−",Font=Enum.Font.GothamBold,TextSize=21,TextColor3=C.white,BorderSizePixel=0,AutoButtonColor=false})
corner(minimize,10)
local close=make("TextButton",header,{Position=UDim2.fromOffset(999,22),Size=UDim2.fromOffset(40,41),BackgroundColor3=C.card,Text="×",Font=Enum.Font.GothamBold,TextSize=21,TextColor3=C.white,BorderSizePixel=0,AutoButtonColor=false})
corner(close,10)

local smaller=make("TextButton",header,{
 Position=UDim2.fromOffset(869,22),Size=UDim2.fromOffset(37,41),
 BackgroundColor3=C.card,Text="A−",TextColor3=C.white,
 Font=Enum.Font.GothamBold,TextSize=14,BorderSizePixel=0,AutoButtonColor=false
})
corner(smaller,9)
local bigger=make("TextButton",header,{
 Position=UDim2.fromOffset(911,22),Size=UDim2.fromOffset(37,41),
 BackgroundColor3=C.card,Text="A+",TextColor3=C.white,
 Font=Enum.Font.GothamBold,TextSize=14,BorderSizePixel=0,AutoButtonColor=false
})
corner(bigger,9)
listen(smaller.MouseButton1Click,function()
 requestedScale=math.max(.6,requestedScale-.1)
 resize()
end)
listen(bigger.MouseButton1Click,function()
 requestedScale=math.min(1.3,requestedScale+.1)
 resize()
end)

local sidebar=make("Frame",window,{Position=UDim2.fromOffset(0,87),Size=UDim2.fromOffset(204,589),BackgroundColor3=Color3.fromRGB(10,16,15),BorderSizePixel=0,ClipsDescendants=true})
make("UIGradient",sidebar,{Rotation=100,Color=ColorSequence.new(Color3.fromRGB(9,15,15),Color3.fromRGB(9,31,15))})
local wave=make("Frame",sidebar,{Position=UDim2.fromOffset(-130,414),Size=UDim2.fromOffset(380,180),Rotation=-18,BackgroundColor3=C.green,BackgroundTransparency=.90,BorderSizePixel=0})
corner(wave,80)
-- Game name is now the navigation item only
local selectedNav=make("Frame",sidebar,{Position=UDim2.fromOffset(14,34),Size=UDim2.fromOffset(178,59),BackgroundColor3=C.darkgreen,BorderSizePixel=0})
corner(selectedNav,13)
local navStroke=border(selectedNav,C.green,.05,1.4)
text(selectedNav,"⌂",UDim2.fromOffset(20,0),UDim2.fromOffset(30,59),27,true,C.green)
text(selectedNav,"Район насилия",UDim2.fromOffset(51,0),UDim2.fromOffset(125,59),13,true,C.white)
local bindInfo={Text=""}
-- Sidebar stays intentionally minimal; shortcuts remain internal.

local content=make("Frame",window,{Position=UDim2.fromOffset(204,87),Size=UDim2.fromOffset(846,589),BackgroundTransparency=1,ClipsDescendants=true})
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
local heroAccent=make("Frame",hero,{Position=UDim2.fromOffset(773,-10),Size=UDim2.fromOffset(20,100),Rotation=36,BackgroundColor3=C.green,BackgroundTransparency=.72,BorderSizePixel=0})
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
local espScroll=make("ScrollingFrame",espPanel,{
 Position=UDim2.fromOffset(7,45),Size=UDim2.new(1,-14,1,-52),
 BackgroundTransparency=1,BorderSizePixel=0,Active=true,
 CanvasSize=UDim2.fromOffset(0,462),
 ScrollBarThickness=3,ScrollBarImageColor3=C.green,
 ScrollingDirection=Enum.ScrollingDirection.Y,ClipsDescendants=true
})

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
local function beginRebind(key)
 waitingFor=key
 for _,name in ipairs({"menu","fly","noclip"}) do bindVisual(name) end
end
listen(menuBind.MouseButton1Click,function() beginRebind("menu") end)
local function hoverEffect(o)
 listen(o.MouseEnter,function() tween(o,{BackgroundColor3=Color3.fromRGB(35,45,46)},.17) end)
 listen(o.MouseLeave,function() tween(o,{BackgroundColor3=C.row},.2) end)
end
local rows={
 {key="fly",name="Fly",subtitle="Полёт • WASD / Space",icon="✈",bind=true},
 {key="noclip",name="NoClip",subtitle="Проход сквозь препятствия",icon="◇",bind=true},
 {key="autoSkill",name="Auto Skill Check",subtitle="Отслеживание тёмной зоны (эксп.)",icon="◎",bind=false}
}
for i,v in ipairs(rows) do
 local y=48+(i-1)*102
 local f=make("TextButton",functionsPanel,{Position=UDim2.fromOffset(12,y),Size=UDim2.fromOffset(420,88),BackgroundColor3=C.row,Text="",AutoButtonColor=false,BorderSizePixel=0})
 corner(f,11);hoverEffect(f)
 local ib=make("Frame",f,{Position=UDim2.fromOffset(12,24),Size=UDim2.fromOffset(40,40),BackgroundColor3=C.card,BorderSizePixel=0})
 corner(ib,9)
 text(ib,v.icon,UDim2.fromScale(0,0),UDim2.fromScale(1,1),23,true,C.green,Enum.TextXAlignment.Center)
 text(f,v.name,UDim2.fromOffset(61,17),UDim2.fromOffset(228,27),16,true)
 text(f,v.subtitle,UDim2.fromOffset(61,48),UDim2.fromOffset(245,21),11,false,C.muted)
 if v.bind then
  local binding=make("TextButton",f,{Name=v.key.."Bind",Position=UDim2.fromOffset(306,32),Size=UDim2.fromOffset(53,27),BackgroundColor3=C.card,Text=niceKey(keybind[v.key]),TextColor3=C.green,Font=Enum.Font.GothamBold,TextSize=11,BorderSizePixel=0,AutoButtonColor=false})
  corner(binding,6);border(binding,C.edge,.4,1)
  bindButtons[v.key]=binding
  listen(binding.MouseButton1Click,function() beginRebind(v.key) end)
 end
 switch(f,v.key,369,32)
 listen(f.MouseButton1Click,function() toggle(v.key) end)
end

local pickerLayer
local wheelHeld,sliderHeld=false,false
local openPicker
local descriptions={
 {key="players",name="ESP игроков",subtitle="Белая обводка • ник • метры",icon=""},
 {key="killers",name="ESP маньяка",subtitle="Ник красный • фиксирован",icon="☠"},
 {key="generators",name="ESP генераторов",subtitle="Генераторы на карте",icon=""},
 {key="pumpkins",name="ESP тыкв",subtitle="Тыквы на карте",icon="🎃"},
 {key="pallets",name="ESP паллет",subtitle="Золотая обводка • метры",icon=""},
 {key="windows",name="ESP окон",subtitle="Золотая обводка • метры",icon=""}
}
for i,v in ipairs(descriptions) do
 local y=4+(i-1)*76
 local f=make("TextButton",espScroll,{Position=UDim2.fromOffset(4,y),Size=UDim2.fromOffset(329,70),BackgroundColor3=C.row,Text="",AutoButtonColor=false,BorderSizePixel=0})
 corner(f,11);hoverEffect(f)
 local iconBox=make("Frame",f,{Position=UDim2.fromOffset(11,16),Size=UDim2.fromOffset(38,38),BackgroundColor3=C.card,BorderSizePixel=0})
 corner(iconBox,9)
 if v.key=="players" then
  local head=make("Frame",iconBox,{Position=UDim2.fromOffset(13,7),Size=UDim2.fromOffset(12,12),BackgroundColor3=C.white,BorderSizePixel=0})
  corner(head,12)
  local shoulders=make("Frame",iconBox,{Position=UDim2.fromOffset(6,23),Size=UDim2.fromOffset(26,11),BackgroundColor3=C.white,BorderSizePixel=0})
  corner(shoulders,8)
 elseif v.key=="pallets" then
  local frame=make("Frame",iconBox,{Position=UDim2.fromOffset(5,8),Size=UDim2.fromOffset(28,24),BackgroundTransparency=1,BorderSizePixel=0})
  border(frame,palette.pallets,.1,2)
  for n=0,2 do
   make("Frame",frame,{Position=UDim2.fromOffset(3,3+n*7),Size=UDim2.fromOffset(22,4),BackgroundColor3=palette.pallets,BorderSizePixel=0})
  end
 elseif v.key=="windows" then
  local frame=make("Frame",iconBox,{Position=UDim2.fromOffset(6,6),Size=UDim2.fromOffset(26,27),BackgroundTransparency=1,BorderSizePixel=0})
  border(frame,palette.windows,.1,2)
  make("Frame",frame,{Position=UDim2.fromOffset(12,0),Size=UDim2.fromOffset(2,27),BackgroundColor3=palette.windows,BorderSizePixel=0})
  make("Frame",frame,{Position=UDim2.fromOffset(0,12),Size=UDim2.fromOffset(26,2),BackgroundColor3=palette.windows,BorderSizePixel=0})
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
  for _,name in ipairs({"menu","fly","noclip"}) do bindVisual(name) end
  if refreshMenuSink then refreshMenuSink() end
  return
 end
 if UserInputService:GetFocusedTextBox() then return end
 if key==keybind.menu then
  -- setVisible is defined below and referenced dynamically.
  if _G.OX1DE_LOCAL_TOGGLE then _G.OX1DE_LOCAL_TOGGLE() end
  return
 end
 for _,name in ipairs({"fly","noclip"}) do
  if keybind[name]~=Enum.KeyCode.Unknown and key==keybind[name] then toggle(name);return end
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
 if editableColor(chosenKey) then palette[chosenKey]=color;paintSwatches(chosenKey) end
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
 local names={players="Игроки • обводка",generators="Генераторы",pumpkins="Тыквы",pallets="Паллеты",windows="Окна"}
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

-- ESP: world objects ------------------------------------------------------
local function category(obj)
    local n=string.lower(obj.Name)
    if n:find("pumpkin",1,true) or n:find("jack_o_lantern",1,true) or n:find("jack-o-lantern",1,true) or n:find("jackolantern",1,true) or n:find("тыкв",1,true) then return "pumpkins" end
    if n:find("generator",1,true) or n:find("генератор",1,true) then return "generators" end
    if n:find("pallet",1,true) or n:find("паллет",1,true) or n:find("палет",1,true) or n:find("поддон",1,true) then return "pallets" end
    if n:find("window",1,true) or n:find("окно",1,true) or n:find("окн",1,true) or n:find("vaultwindow",1,true) then return "windows" end
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
    if kind=="pallets" or kind=="windows" then
        return readFlag(obj,{"Destroyed","IsDestroyed","Broken","IsBroken"})==true
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
    if p==LocalPlayer then return end
    clearPlayer(p)
    local ch=p.Character
    if not ch then return end
    local h=ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart")
    if not h then return end
    local highlight=make("Highlight",ch,{Name="OX1DE_Person",Adornee=ch,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,OutlineColor=palette.players,OutlineTransparency=0,FillTransparency=1,Enabled=true})
    local bb,lab=billboard(h,C.unknown,p.DisplayName)
    playerFx[p]={h=highlight,bb=bb,lab=lab,part=h}
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
    local h=make("Highlight",obj,{Name="OX1DE_Object",Adornee=obj,FillColor=color,FillTransparency=(kind=="pallets" or kind=="windows") and .9 or .66,OutlineColor=color,OutlineTransparency=0,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,Enabled=state[kind]})
    local labels={pumpkins="Тыква",generators="Генератор",pallets="Паллета",windows="Окно"}
    local bb,lab=billboard(part,color,labels[kind] or "Объект")
    objectFx[obj]={kind=kind,h=h,bb=bb,lab=lab,part=part}
    -- Safe test: no scene model cloning in the preview
end
local function scanOne(obj)
    local target,kind=candidate(obj)
    if target and state[kind] then addObject(target,kind) end
end
local scanPending=false
local function scanAll()
    if scanPending or not (state.generators or state.pumpkins or state.pallets or state.windows) then return end
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
    if enabled and (key=="generators" or key=="pumpkins" or key=="pallets" or key=="windows") then scanAll() end
end
listen(Workspace.DescendantAdded,function(obj)
    if not alive or not (state.generators or state.pumpkins or state.pallets or state.windows) then return end
    if category(obj) then scanOne(obj) end
    if obj.Parent and category(obj.Parent) then scanOne(obj.Parent) end
end)


-- Skill check: local GUI detection only, no generator auto-repair.
local virtualInput=nil
local skillLastAt=0
local skillWasShown=false
local skillStatus="ожидание"
local function sendKey(key,down)
 local ok,im=pcall(function()
  if not virtualInput then virtualInput=game:GetService("VirtualInputManager") end
  return virtualInput
 end)
 if not ok or not im then return false end
 return pcall(function() im:SendKeyEvent(down,key,false,game) end)
end
local function visibleGui(o)
    if not o or not o.Parent or not o:IsA("GuiObject") then return false end
    local q=o
    while q and q~=PlayerGui do
        if q:IsA("GuiObject") and not q.Visible then return false end
        q=q.Parent
    end
    return true
end
local function findSkillContainer()
    for _,o in ipairs(PlayerGui:GetDescendants()) do
        if o:IsA("GuiObject") and visibleGui(o) then
            local n=string.lower(o.Name)
            if n:find("skill",1,true) or n:find("check",1,true) or n:find("timing",1,true) or n:find("minigame",1,true) then
                if #o:GetDescendants()>=2 then return o end
            end
        end
    end
    return nil
end
local function skillMatch(container)
    if not container then return false end
    local needle, zone=nil,nil
    for _,obj in ipairs(container:GetDescendants()) do
        if obj:IsA("GuiObject") and visibleGui(obj) then
            local n=string.lower(obj.Name)
            local marker=(n:find("needle",1,true) or n:find("pointer",1,true) or n:find("cursor",1,true) or n:find("indicator",1,true) or n:find("arrow",1,true) or n:find("line",1,true))
            local target=(n:find("target",1,true) or n:find("zone",1,true) or n:find("success",1,true) or n:find("perfect",1,true) or n:find("great",1,true) or n:find("hit",1,true) or n:find("white",1,true))
            if marker and not needle then needle=obj end
            if target and not zone then zone=obj end
        end
    end
    if not needle or not zone or needle==zone then return false end
    local nPos,nSize=needle.AbsolutePosition,needle.AbsoluteSize
    local zPos,zSize=zone.AbsolutePosition,zone.AbsoluteSize
    if nSize.X<1 or zSize.X<1 then return false end
    -- A horizontal skill-check bar: the needle's centre has reached
    -- the inner part of the visible success zone.
    local nx=nPos.X+nSize.X*.5
    local zy=zPos.Y+zSize.Y*.5
    local ny=nPos.Y+nSize.Y*.5
    local early=math.min(zSize.X*.25,9)
    if math.abs(ny-zy)<=math.max(zSize.Y*1.5,32) and nx>=zPos.X-early and nx<=zPos.X+zSize.X*.72 then
        return true
    end
    -- Circular gauges sometimes use Rotation for needle and target.
    if needle.Rotation~=0 or zone.Rotation~=0 then
        local diff=(needle.Rotation-zone.Rotation+540)%360-180
        if math.abs(diff)<=8 then return true end
    end
    return false
end
local function skillPress()
    if os.clock()-skillLastAt<.65 then return end
    skillLastAt=os.clock()
    local key=Enum.KeyCode.Space
    if sendKey(key,true) then
        task.wait(.035)
        sendKey(key,false)
        skillStatus="нажато"
    else
        skillStatus="ввод недоступен"
    end
end
-- Jobs are throttled to avoid scanning the entire Workspace each frame.
task.spawn(function()
    while alive do
        if state.autoSkill then
            local container=findSkillContainer()
            local aligned=skillMatch(container)
            if container then
                skillStatus=aligned and "совпадение" or "отслеживание"
                if aligned and not skillWasShown then
                    task.spawn(skillPress)
                end
            else
                skillStatus="шкала не найдена"
            end
            skillWasShown=aligned
        else
            skillWasShown=false
            skillStatus="выключено"
        end
        task.wait(.12)
    end
end)

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
    if not state.noclip then return end
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
    if not alive or not state.fly then return end
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
            if state.fly then startFly() end
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
local lastFly,lastNoClip=false,false
local accumulated=0
listen(RunService.Heartbeat,function(dt)
    if not alive then return end
    if state.fly~=lastFly then
        lastFly=state.fly
        if lastFly then startFly() else stopFly() end
    end
    if state.noclip~=lastNoClip then
        lastNoClip=state.noclip
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
            local shown=state.players or state.killers
            fx.bb.Enabled=shown and (r~="killer" and state.players or r=="killer" and state.killers)
            fx.h.Enabled=fx.bb.Enabled
            fx.h.OutlineColor=palette.players
            -- Only role nickname colors differ; contour remains the selected white color.
            -- Unknown roles are neutral white rather than incorrectly shown as killers.
            fx.lab.TextColor3=r=="killer" and C.red or r=="survivor" and C.green or C.white
            fx.lab.Text=player.DisplayName.." ["..player.Name.."]\n"..(my and fmtDistance(my.Position,fx.part.Position) or "?").." м"
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
            local labels={pumpkins="Тыква",generators="Генератор",pallets="Паллета",windows="Окно"}
            fx.lab.Text=(labels[fx.kind] or "Объект").."  •  "..(my and fmtDistance(my.Position,fx.part.Position) or "?").." м"
            if fx.kind=="pumpkins" then nPumpkin+=1 elseif fx.kind=="generators" then nGenerator+=1 end
        end
    end
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and p.Character and not playerFx[p] then addPlayer(p) end
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
    alive=false;state.fly=false;state.noclip=false
    state.autoSkill=false
    stopFly();restore()
    if isOpen then stopMenuMouse() end
    pcall(function() ContextActionService:UnbindAction("OX1DE_MenuKey") end)
    if cameraConn then cameraConn:Disconnect() end
    for _,c in ipairs(connections) do c:Disconnect() end
    for p in pairs(playerFx) do clearPlayer(p) end
    for obj in pairs(objectFx) do clearObject(obj) end
    _G.OX1DE_CHEATING_STOP=nil
    _G.OX1DE_LOCAL_TOGGLE=nil
    if gui then gui:Destroy() end
end
