-- OX1DE Hub v4.0 | clean rebuild
-- LocalScript interface. Runtime features can be restricted by individual Roblox experiences.
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local RS=game:GetService("RunService")
local TS=game:GetService("TweenService")
local CS=game:GetService("CollectionService")
local Http=game:GetService("HttpService")
local lp=Players.LocalPlayer
if not lp then return end
local pg=lp:WaitForChild("PlayerGui")
local env=(type(getgenv)=="function" and getgenv()) or _G
if type(env.OX1DE_CLEANUP)=="function" then pcall(env.OX1DE_CLEANUP) end
if type(env.OX1DE_HUB_CLEANUP)=="function" then pcall(env.OX1DE_HUB_CLEANUP) end
for _,name in ipairs({"OX1DE_V2_UI","OX1DE_V2_FOV","OX1DE_V3_UI","OX1DE_V3_FOV","OX1DE_HUB_V4","OX1DE_HUB_V4_OVERLAY"}) do
  local old=pg:FindFirstChild(name)
  if old then old:Destroy() end
end
for _,obj in ipairs(pg:GetDescendants()) do
  if obj:IsA("BillboardGui") and obj.Name=="OX1DE_Name_ESP" then obj:Destroy() end
end
local oldFolder=workspace:FindFirstChild("OX1DE_V3_ESP_Highlights")
if oldFolder then oldFolder:Destroy() end
local c={
 bg=Color3.fromRGB(9,10,13),panel=Color3.fromRGB(17,18,23),
 card=Color3.fromRGB(27,29,34),hover=Color3.fromRGB(46,49,57),
 border=Color3.fromRGB(81,85,95),white=Color3.fromRGB(246,247,249),
 muted=Color3.fromRGB(160,168,180),red=Color3.fromRGB(255,32,45),
 green=Color3.fromRGB(72,232,128),enemy=Color3.fromRGB(255,99,99)
}
local s={
 Aim=false,TeamAim=false,WallCheck=false,AimPart="Head",AimSpeed=1,FOV=false,FOVRadius=150,
 NameESP=false,DistanceESP=false,TeamVisual=false,SkeletonESP=false,OutlineESP=false,
 WeaponESP=false,ThroughWalls=false,PumpkinESP=false,
 Fly=false,Noclip=false,Speed=16,Jump=50,
 Background="Dark",Shadows=false,Opacity=1,UISize=.82
}
local binds={Aim=Enum.KeyCode.E,Fly=Enum.KeyCode.X,Noclip=Enum.KeyCode.Z}
local cfgName="OX1DE_Hub_v4_settings.json"
local function applySaved(payload)
  if type(payload)~="table" then return end
  if type(payload.state)=="table" then
    for key,val in pairs(payload.state) do
      if s[key]~=nil and type(s[key])==type(val) then
        if type(val)=="boolean" then s[key]=val
        elseif type(val)=="number" and val==val then
          local limits={AimSpeed={0,1},FOVRadius={30,400},Speed={8,100},Jump={20,120},Opacity={.3,1},UISize={.6,1.15}}
          local v=limits[key]
          if v then s[key]=math.clamp(val,v[1],v[2]) end
        elseif key=="AimPart" and (val=="Head" or val=="Body" or val=="Legs") then s[key]=val
        elseif key=="Background" and (val=="Dark" or val=="Clear") then s[key]=val end
      end
    end
  end
  if type(payload.binds)=="table" then
    for kind,_ in pairs(binds) do
      local name=payload.binds[kind]
      if type(name)=="string" and name~="Unknown" and name~="RightShift" then
        local ok,key=pcall(function()return Enum.KeyCode[name] end)
        if ok and key then binds[kind]=key end
      end
    end
  end
end
local saved=nil
if type(readfile)=="function" then
  local ok,raw=pcall(readfile,cfgName)
  if ok and type(raw)=="string" then
    local worked,v=pcall(function()return Http:JSONDecode(raw)end)
    if worked then saved=v end
  end
end
if not saved then saved=env.OX1DE_V4_SETTINGS end
applySaved(saved)
local function save()
  local payload={state={},binds={}}
  for k,v in pairs(s) do payload.state[k]=v end
  for k,v in pairs(binds) do payload.binds[k]=v.Name end
  env.OX1DE_V4_SETTINGS=payload
  if type(writefile)=="function" then
    local ok,raw=pcall(function()return Http:JSONEncode(payload)end)
    if ok then pcall(writefile,cfgName,raw) end
  end
end
local running=true
local links={}
local tempLinks={}
local records={}
local pumpkins={}
local collisions={}
local flyForce,flyGyro,oldRotate=nil,nil,nil
local open=false
local mouseIcon,mouseBehavior=nil,nil
local menu,window,content,scroll,navButtons,chosen,refreshUI
local function connect(sig,fn,temporary)
  local co=sig:Connect(fn)
  table.insert(temporary and tempLinks or links,co)
  return co
end
local function clearTemp()
  for _,co in ipairs(tempLinks) do co:Disconnect() end
  table.clear(tempLinks)
end
local function make(class,props,parent)
  local obj=Instance.new(class)
  for k,v in pairs(props or {}) do obj[k]=v end
  obj.Parent=parent
  return obj
end
local function corner(obj,r)
  make("UICorner",{CornerRadius=UDim.new(0,r)},obj)
  return obj
end
local function stroke(obj,col,thick,trans)
  return make("UIStroke",{Color=col or c.border,Thickness=thick or 1,Transparency=trans or 0},obj)
end
local function animate(obj,props,d)
  if obj and obj.Parent then
    local tw=TS:Create(obj,TweenInfo.new(d or .2,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),props)
    tw:Play()
  end
end
local function text(parent,str,size,color,bold)
  return make("TextLabel",{BackgroundTransparency=1,Text=str,Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,
    TextSize=size,TextColor3=color or c.white,TextXAlignment=Enum.TextXAlignment.Left,
    TextTruncate=Enum.TextTruncate.AtEnd},parent)
end
-- Strict UI hierarchy: gameplay overlays live in a separate ScreenGui.
menu=make("ScreenGui",{Name="OX1DE_HUB_V4",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=120},pg)
local overlay=make("ScreenGui",{Name="OX1DE_HUB_V4_OVERLAY",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=110},pg)
local fov=corner(make("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
  Size=UDim2.fromOffset(s.FOVRadius*2,s.FOVRadius*2),BackgroundTransparency=1,Visible=false},overlay),9999)
stroke(fov,c.red,2.5)
local function updateFOV()
  fov.Visible=s.FOV
  animate(fov,{Size=UDim2.fromOffset(s.FOVRadius*2,s.FOVRadius*2)},.15)
end
local shell=corner(make("CanvasGroup",{Name="OX1DE_Hub",AnchorPoint=Vector2.new(.5,.5),
 Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(1010,680),BackgroundColor3=c.bg,
 BorderSizePixel=0,ClipsDescendants=true},menu),22)
stroke(shell,c.border,1.2,.08)
local scale=make("UIScale",{Scale=1},shell)
local function rescale(animated)
  local cam=workspace.CurrentCamera
  if not cam then return end
  local vp=cam.ViewportSize
  local fit=math.min((vp.X-28)/1010,(vp.Y-28)/680)
  local final=math.clamp(math.min(fit,s.UISize),.3,1.15)
  if animated then animate(scale,{Scale=final},.18) else scale.Scale=final end
end
local viewportConnection
local function bindViewport()
  if viewportConnection then viewportConnection:Disconnect() end
  local cam=workspace.CurrentCamera
  if cam then viewportConnection=connect(cam:GetPropertyChangedSignal("ViewportSize"),function()rescale(false)end) end
  rescale(false)
end
bindViewport()
connect(workspace:GetPropertyChangedSignal("CurrentCamera"),bindViewport)
local head=make("Frame",{Size=UDim2.new(1,0,0,76),BackgroundColor3=c.panel,BorderSizePixel=0},shell)
make("UIGradient",{Color=ColorSequence.new(Color3.fromRGB(34,36,41),Color3.fromRGB(11,12,15)),Rotation=0},head)
make("Frame",{Position=UDim2.new(0,0,1,-1),Size=UDim2.new(1,0,0,1),BorderSizePixel=0,BackgroundColor3=c.border},head)
local logo=corner(make("Frame",{Position=UDim2.fromOffset(28,19),Size=UDim2.fromOffset(36,36),
 Rotation=-12,BackgroundTransparency=1},head),9)
stroke(logo,c.white,2.2)
local logo2=corner(make("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
 Size=UDim2.fromOffset(14,14),BackgroundTransparency=1},logo),3)
stroke(logo2,c.white,2.6)
local hTitle=text(head,"OX1DE Hub",27,c.white,true)
hTitle.Position=UDim2.fromOffset(82,18);hTitle.Size=UDim2.fromOffset(245,42)
local version=text(head,"V4.1",12,c.muted,true)
version.Position=UDim2.fromOffset(280,31);version.Size=UDim2.fromOffset(35,17)
local function exitBtn(symbol,x)
  local b=corner(make("TextButton",{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,x,0,20),
    Size=UDim2.fromOffset(38,37),BackgroundColor3=c.card,Text=symbol,TextColor3=c.white,
    TextSize=19,Font=Enum.Font.GothamBold,AutoButtonColor=false},head),10)
  stroke(b,c.border,1,.1)
  connect(b.MouseEnter,function()animate(b,{BackgroundColor3=c.hover},.16)end)
  connect(b.MouseLeave,function()animate(b,{BackgroundColor3=c.card},.16)end)
  return b
end
local side=make("Frame",{Position=UDim2.fromOffset(0,76),Size=UDim2.new(0,243,1,-76),
 BackgroundColor3=Color3.fromRGB(15,16,20),BorderSizePixel=0},shell)
make("Frame",{Position=UDim2.new(1,-1,0,0),Size=UDim2.new(0,1,1,0),
 BackgroundColor3=c.border,BorderSizePixel=0},side)
local navCaption=text(side,"N A V I G A T I O N",11,c.muted,true)
navCaption.Position=UDim2.fromOffset(23,20);navCaption.Size=UDim2.fromOffset(210,22)
local nav={Player="◯",Visual="◉",Combat="⊕",Setting="⚙"}
navButtons={}
chosen="Player"
content=make("CanvasGroup",{GroupTransparency=0,Position=UDim2.fromOffset(243,76),Size=UDim2.new(1,-243,1,-76),BackgroundTransparency=1},shell)
local pageIcon=text(content,nav.Player,28,c.white,true)
pageIcon.Position=UDim2.fromOffset(30,22);pageIcon.Size=UDim2.fromOffset(35,37)
local heading=text(content,"Player",27,c.white,true)
heading.Position=UDim2.fromOffset(75,21);heading.Size=UDim2.fromOffset(460,38)
local subheading=text(content,"Character & movement",12,c.muted)
subheading.Position=UDim2.fromOffset(31,63);subheading.Size=UDim2.fromOffset(570,20)
scroll=make("ScrollingFrame",{Position=UDim2.fromOffset(27,99),Size=UDim2.new(1,-54,1,-114),
 BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=c.border,
 CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y},content)
make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,7)},scroll)
make("UIPadding",{PaddingBottom=UDim.new(0,12)},scroll)
local layoutOrder=0
local function nextOrder()
  layoutOrder=layoutOrder+1
  return layoutOrder
end
local function section(name)
  local bar=make("Frame",{Size=UDim2.new(1,-5,0,20),BackgroundTransparency=1,LayoutOrder=nextOrder()},scroll)
  local l=text(bar,string.upper(name),10,c.muted,true)
  l.Position=UDim2.fromOffset(3,0);l.Size=UDim2.new(1,-6,1,0)
end
local function row(name,sub,height)
  local box=corner(make("Frame",{LayoutOrder=nextOrder(),Size=UDim2.new(1,-7,0,height or 59),
    BackgroundColor3=c.card,BorderSizePixel=0},scroll),12)
  stroke(box,c.border,1,.15)
  make("UIGradient",{Color=ColorSequence.new(Color3.fromRGB(38,40,47),Color3.fromRGB(24,26,30)),Rotation=0},box)
  local title=text(box,name,14,c.white,true)
  title.Position=UDim2.fromOffset(19,7);title.Size=UDim2.new(.6,-19,0,24)
  local desc=text(box,sub or "",11,c.muted)
  desc.Position=UDim2.fromOffset(19,30);desc.Size=UDim2.new(.69,-19,0,17)
  local edge=make("Frame",{Position=UDim2.new(.025,0,0,0),Size=UDim2.new(.95,0,0,1),
    BackgroundColor3=c.white,BackgroundTransparency=.9,BorderSizePixel=0},box)
  connect(box.MouseEnter,function()animate(edge,{BackgroundTransparency=.55},.18)end,true)
  connect(box.MouseLeave,function()animate(edge,{BackgroundTransparency=.9},.18)end,true)
  return box
end
local function toggle(box,key,cb)
  local b=corner(make("TextButton",{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-17,.5,0),
    Size=UDim2.fromOffset(49,28),BackgroundColor3=c.border,Text="",AutoButtonColor=false},box),16)
  local dot=corner(make("Frame",{Size=UDim2.fromOffset(20,20),Position=UDim2.fromOffset(4,4),BackgroundColor3=c.white},b),11)
  local function paint()
    animate(b,{BackgroundColor3=s[key] and c.white or Color3.fromRGB(70,74,82)},.17)
    animate(dot,{Position=UDim2.fromOffset(s[key] and 25 or 4,4),
      BackgroundColor3=s[key] and c.bg or c.white},.17)
  end
  connect(b.MouseButton1Click,function()
    s[key]=not s[key]
    paint()
    if cb then cb(s[key]) end
    save()
  end,true)
  paint()
end
local function keybutton(box,action)
  local b=corner(make("TextButton",{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-83,.5,0),
    Size=UDim2.fromOffset(52,29),BackgroundColor3=c.bg,Text=binds[action].Name,
    TextColor3=c.white,TextSize=12,Font=Enum.Font.GothamBold,AutoButtonColor=false},box),8)
  stroke(b,c.border)
  connect(b.MouseButton1Click,function()
    env.OX1DE_PENDING_BIND=action
    b.Text="..."
  end,true)
  return b
end
local function slider(name,subtitle,key,min,max,places,cb)
  local box=row(name,subtitle,69)
  local value=text(box,"",12,c.white,true)
  value.Position=UDim2.new(1,-70,.5,-14);value.Size=UDim2.fromOffset(53,28);value.TextXAlignment=Enum.TextXAlignment.Right
  local bar=corner(make("TextButton",{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-94,.5,0),
    Size=UDim2.fromOffset(190,6),Text="",BackgroundColor3=c.border,AutoButtonColor=false},box),4)
  local fill=corner(make("Frame",{Size=UDim2.fromScale(.2,1),BackgroundColor3=c.white,BorderSizePixel=0},bar),4)
  local knob=corner(make("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.2,.5),
    Size=UDim2.fromOffset(16,16),BackgroundColor3=c.white,BorderSizePixel=0},bar),9)
  local dragging=false
  local function set(v,persist)
    local scale10=10^places
    s[key]=math.floor(math.clamp(v,min,max)*scale10+.5)/scale10
    local ratio=(s[key]-min)/(max-min)
    fill.Size=UDim2.fromScale(ratio,1)
    knob.Position=UDim2.fromScale(ratio,.5)
    value.Text=string.format("%."..places.."f",s[key])
    if cb then cb() end
    if persist then save() end
  end
  local function fromPointer(x)
    set(min+(max-min)*math.clamp((x-bar.AbsolutePosition.X)/math.max(1,bar.AbsoluteSize.X),0,1),true)
  end
  connect(bar.InputBegan,function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
      dragging=true;fromPointer(i.Position.X)
    end
  end,true)
  connect(UIS.InputChanged,function(i)
    if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then fromPointer(i.Position.X) end
  end,true)
  connect(UIS.InputEnded,function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end
  end,true)
  set(s[key],false)
end
local function choice(name,sub,key,options)
  local box=row(name,sub,59)
  local holder=corner(make("Frame",{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-16,.5,0),
    Size=UDim2.fromOffset(#options*86+8,39),BackgroundColor3=c.bg},box),9)
  local buttons={}
  for i,opt in ipairs(options) do
    local b=corner(make("TextButton",{Position=UDim2.fromOffset(4+(i-1)*86,4),
      Size=UDim2.fromOffset(82,31),Text=opt,TextSize=12,Font=Enum.Font.GothamBold,AutoButtonColor=false},holder),7)
    buttons[i]=b
    connect(b.MouseButton1Click,function()
      s[key]=opt
      for j,button in ipairs(buttons) do
        animate(button,{BackgroundColor3=j==i and c.white or c.bg,
          TextColor3=j==i and c.bg or c.muted},.14)
      end
      save()
    end,true)
  end
  for i,b in ipairs(buttons) do
    b.BackgroundColor3=options[i]==s[key] and c.white or c.bg
    b.TextColor3=options[i]==s[key] and c.bg or c.muted
  end
end
local function stopFly()
  if flyForce then flyForce:Destroy();flyForce=nil end
  if flyGyro then flyGyro:Destroy();flyGyro=nil end
  local ch=lp.Character
  local hum=ch and ch:FindFirstChildOfClass("Humanoid")
  if hum and oldRotate~=nil then hum.AutoRotate=oldRotate end
  oldRotate=nil
end
local function startFly()
  stopFly()
  local ch=lp.Character
  local root=ch and ch:FindFirstChild("HumanoidRootPart")
  local hum=ch and ch:FindFirstChildOfClass("Humanoid")
  if not root or not hum then return end
  oldRotate=hum.AutoRotate;hum.AutoRotate=false
  flyForce=make("BodyVelocity",{Name="OX1DE_FlyForce",MaxForce=Vector3.new(1e8,1e8,1e8),P=10000,Velocity=Vector3.zero},root)
  flyGyro=make("BodyGyro",{Name="OX1DE_FlyRotation",MaxTorque=Vector3.new(1e8,1e8,1e8),P=15000,CFrame=workspace.CurrentCamera.CFrame},root)
end
local function restoreCollision()
  for part,old in pairs(collisions) do if part and part.Parent then part.CanCollide=old end end
  table.clear(collisions)
end
local function speed()
  local hum=lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
  if hum then
    hum.WalkSpeed=s.Speed
    if hum.UseJumpPower then hum.JumpPower=s.Jump else hum.JumpHeight=s.Jump/7 end
  end
end
local pageNames={"Player","Visual","Combat","Setting"}
local subtitles={Player="Character & movement",Visual="Player overlays & Halloween",Combat="Aim controls & field of view",Setting="Appearance & keybinds"}
local function drawPage(which)
  if which~=chosen then
    content.GroupTransparency=1
    content.Position=UDim2.fromOffset(255,76)
  end
  chosen=which
  clearTemp()
  for _,child in ipairs(scroll:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
  layoutOrder=0
  heading.Text=which;pageIcon.Text=nav[which];subheading.Text=subtitles[which]
  scroll.CanvasPosition=Vector2.zero
  for name,b in pairs(navButtons) do
    local selected=name==which
    animate(b,{BackgroundColor3=selected and c.white or c.card,
      TextColor3=selected and c.bg or c.white},.2)
  end
  animate(content,{GroupTransparency=0,Position=UDim2.fromOffset(243,76)},.26)
  if which=="Player" then
    section("Movement")
    slider("Walk Speed","Character movement speed","Speed",8,100,0,speed)
    slider("Jump Height","Character jump height","Jump",20,120,0,speed)
    section("Movement modes")
    local f=row("Fly","Toggle flight mode • X")
    keybutton(f,"Fly");toggle(f,"Fly",function(on) if on then startFly() else stopFly() end end)
    local n=row("Noclip","Toggle collision • Z")
    keybutton(n,"Noclip");toggle(n,"Noclip",function(on) if not on then restoreCollision() end end)
  elseif which=="Visual" then
    section("Player labels")
    local n=row("Name ESP","DisplayName and @username on separate lines")
    toggle(n,"NameESP")
    local d=row("Distance ESP","Distance in Roblox studs")
    toggle(d,"DistanceESP")
    local t=row("Team Check","Green teammates • red opponents • off = white")
    toggle(t,"TeamVisual")
    section("Character display")
    local a=row("Skeleton ESP","R6 / R15 joint lines");toggle(a,"SkeletonESP")
    local o=row("Outline ESP","Subtle outline around players");toggle(o,"OutlineESP")
    local w=row("Weapon ESP","Equipped tool name");toggle(w,"WeaponESP")
    local tw=row("Through Walls","Render overlay behind obstacles");toggle(tw,"ThroughWalls")
    section("Halloween • temporary")
    local p=row("Pumpkin ESP","Highlight pumpkin-labelled objects");toggle(p,"PumpkinESP")
  elseif which=="Combat" then
    section("Aim")
    local a=row("Enable Aim","Toggle • E (rebindable)");keybutton(a,"Aim");toggle(a,"Aim")
    local wc=row("Wall Check","Exclude targets blocked by geometry");toggle(wc,"WallCheck")
    local tc=row("Team Check","Exclude actual teammates when enabled");toggle(tc,"TeamAim")
    choice("Aim Part","Select target area","AimPart",{"Head","Body","Legs"})
    section("Precision")
    slider("Aim Speed","0 smooth • 1 instant","AimSpeed",0,1,2)
    local f=row("Red FOV","Circular overlay centered on the screen");toggle(f,"FOV",updateFOV)
    slider("FOV Radius","Screen-space circle radius","FOVRadius",30,400,0,updateFOV)
  else
    section("Appearance")
    choice("Background","Choose panel appearance","Background",{"Dark","Clear"})
    local sh=row("Shadows","Subtle window border shadow");toggle(sh,"Shadows")
    slider("Opacity","Window transparency","Opacity",.3,1,2,function()
      shell.GroupTransparency=1-s.Opacity
    end)
    section("Controls")
    local k=row("Menu Key","RightShift — open / close");local l=text(k,"RIGHT SHIFT",12,c.white,true)
    l.Position=UDim2.new(1,-125,.5,-13);l.Size=UDim2.fromOffset(110,26)
    local m=row("Mouse behavior","Restore game input when menu closes")
    local status=text(m,"AUTO RESTORE",11,c.white,true)
    status.Position=UDim2.new(1,-138,.5,-13);status.Size=UDim2.fromOffset(120,26)
  end
end
for i,name in ipairs(pageNames) do
  local b=corner(make("TextButton",{Position=UDim2.fromOffset(16,61+(i-1)*74),
    Size=UDim2.fromOffset(210,63),BackgroundColor3=c.card,Text=nav[name].."   "..name,
    TextColor3=c.white,TextSize=17,Font=Enum.Font.GothamBold,AutoButtonColor=false},side),12)
  stroke(b,c.border,1,.15)
  navButtons[name]=b
  connect(b.MouseButton1Click,function()drawPage(name)end)
  connect(b.MouseEnter,function()if chosen~=name then animate(b,{BackgroundColor3=c.hover},.17) end end)
  connect(b.MouseLeave,function()if chosen~=name then animate(b,{BackgroundColor3=c.card},.17) end end)
end
local resizeHint=text(side,"DRAG CORNER TO RESIZE",10,c.muted,true)
resizeHint.Position=UDim2.new(0,21,1,-75);resizeHint.Size=UDim2.fromOffset(213,22)
local foot=text(side,"OX1DE HUB  •  RIGHT SHIFT",10,c.muted,true)
foot.Position=UDim2.new(0,22,1,-47);foot.Size=UDim2.fromOffset(207,26)
-- Drag the bottom-right handle to scale the menu without clipping its fixed layout.
local grip=corner(make("TextButton",{Name="ResizeGrip",AnchorPoint=Vector2.new(1,1),
  Position=UDim2.new(1,-7,1,-7),Size=UDim2.fromOffset(36,36),BackgroundColor3=c.card,
  Text="↘",TextColor3=c.white,TextSize=21,Font=Enum.Font.GothamBold,AutoButtonColor=false,
  ZIndex=40},shell),10)
stroke(grip,c.border,1,.1)
connect(grip.MouseEnter,function()animate(grip,{BackgroundColor3=c.hover},.15)end)
connect(grip.MouseLeave,function()animate(grip,{BackgroundColor3=c.card},.15)end)
local resizing=false
local resizeStart=nil
local sizeStart=.82
connect(grip.InputBegan,function(i)
  if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
    resizing=true;resizeStart=i.Position;sizeStart=s.UISize
  end
end)
connect(UIS.InputChanged,function(i)
  if resizing and resizeStart and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
    local diff=i.Position-resizeStart
    s.UISize=math.clamp(sizeStart+(diff.X+diff.Y)/1050,.6,1.15)
    rescale(false)
  end
end)
connect(UIS.InputEnded,function(i)
  if resizing and (i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch) then
    resizing=false;resizeStart=nil;save()
  end
end)
local function setOpen(show)
  if show==open then return end
  open=show
  if show then
    mouseIcon=UIS.MouseIconEnabled;mouseBehavior=UIS.MouseBehavior
    UIS.MouseBehavior=Enum.MouseBehavior.Default
    UIS.MouseIconEnabled=true
    shell.Visible=true
    shell.Position=UDim2.new(.5,0,.5,10)
    shell.GroupTransparency=1
    animate(shell,{Position=UDim2.fromScale(.5,.5),GroupTransparency=1-s.Opacity},.23)
  else
    animate(shell,{GroupTransparency=1,Position=UDim2.new(.5,0,.5,10)},.17)
    task.delay(.18,function()if running and not open then shell.Visible=false end end)
    -- Stop overriding mouse input immediately; game camera may manage its own cursor.
    if mouseBehavior then UIS.MouseBehavior=mouseBehavior end
    if mouseIcon~=nil then UIS.MouseIconEnabled=mouseIcon end
  end
end
connect(exitBtn("−",-73).MouseButton1Click,function()setOpen(false)end)
connect(exitBtn("×",-27).MouseButton1Click,function()setOpen(false)end)
local dragStart,positionStart=nil,nil
connect(head.InputBegan,function(i)
  if i.UserInputType==Enum.UserInputType.MouseButton1 then
    dragStart=i.Position;positionStart=shell.Position
  end
end)
connect(UIS.InputChanged,function(i)
  if dragStart and i.UserInputType==Enum.UserInputType.MouseMovement then
    local delta=i.Position-dragStart
    shell.Position=UDim2.new(positionStart.X.Scale,positionStart.X.Offset+delta.X,
      positionStart.Y.Scale,positionStart.Y.Offset+delta.Y)
  end
end)
connect(UIS.InputEnded,function(i)
  if i.UserInputType==Enum.UserInputType.MouseButton1 then dragStart=nil end
end)
-- Player ESP is independent of the visual team-check toggle.
local overlayPlayers={}
local skeletonR15={
 {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
 {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
 {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
 {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
 {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}
}
local skeletonR6={
 {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},
 {"Torso","Left Leg"},{"Torso","Right Leg"}
}
local function colorFor(p)
  if s.TeamVisual~=true then return c.white end
  if lp.Team~=nil and p.Team~=nil and lp.Team==p.Team then return c.green end
  return c.enemy
end
local function visibleToCamera(ch)
  local headpart=ch and (ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart"))
  local cam=workspace.CurrentCamera
  if not cam or not headpart then return false end
  local origin=cam.CFrame.Position
  local ray=headpart.Position-origin
  local params=RaycastParams.new()
  params.FilterType=Enum.RaycastFilterType.Exclude
  params.FilterDescendantsInstances={lp.Character or cam}
  params.IgnoreWater=true
  local result=workspace:Raycast(origin,ray,params)
  return result==nil or result.Instance:IsDescendantOf(ch)
end
local function erase(p)
  local rec=overlayPlayers[p]
  if not rec then return end
  if rec.bill then rec.bill:Destroy() end
  if rec.hi then rec.hi:Destroy() end
  for _,line in ipairs(rec.lines) do line:Destroy() end
  overlayPlayers[p]=nil
end
local function ensure(p)
  local ch=p.Character
  local hum=ch and ch:FindFirstChildOfClass("Humanoid")
  local headpart=ch and ch:FindFirstChild("Head")
  if not ch or not hum or hum.Health<=0 or not headpart then erase(p);return nil end
  local rec=overlayPlayers[p]
  if rec and rec.char~=ch then erase(p);rec=nil end
  if rec then return rec end
  rec={char=ch,lines={}}
  rec.bill=make("BillboardGui",{Name="OX1DE_V4_Player",Adornee=headpart,
    AlwaysOnTop=true,Size=UDim2.fromOffset(210,78),
    StudsOffsetWorldSpace=Vector3.new(0,2.4,0),Enabled=false},overlay)
  rec.name=text(rec.bill,"",15,c.white,true)
  rec.name.Position=UDim2.fromOffset(0,1);rec.name.Size=UDim2.fromOffset(210,22)
  rec.name.TextXAlignment=Enum.TextXAlignment.Center
  rec.user=text(rec.bill,"",12,c.muted)
  rec.user.Position=UDim2.fromOffset(0,24);rec.user.Size=UDim2.fromOffset(210,18)
  rec.user.TextXAlignment=Enum.TextXAlignment.Center
  rec.meta=text(rec.bill,"",12,c.muted,true)
  rec.meta.Position=UDim2.fromOffset(0,44);rec.meta.Size=UDim2.fromOffset(210,18)
  rec.meta.TextXAlignment=Enum.TextXAlignment.Center
  rec.hi=make("Highlight",{Name="OX1DE_V4_PlayerOutline",Adornee=ch,Enabled=false,
    FillTransparency=1,OutlineTransparency=.25,OutlineColor=c.white},ch)
  local which=hum.RigType==Enum.HumanoidRigType.R15 and skeletonR15 or skeletonR6
  for i=1,#which do
    rec.lines[i]=make("Frame",{Name="Skeleton"..i,Visible=false,
      AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(1,2),
      BackgroundColor3=c.white,BorderSizePixel=0},overlay)
  end
  overlayPlayers[p]=rec
  return rec
end
local function updateOverlay(p,rec,localRoot)
  local ch=rec.char
  local root=ch:FindFirstChild("HumanoidRootPart")
  local camera=workspace.CurrentCamera
  local show=s.ThroughWalls or visibleToCamera(ch)
  local tint=colorFor(p)
  local info={}
  if s.DistanceESP and root then
    local from=localRoot and localRoot.Position or (camera and camera.CFrame.Position)
    if from then table.insert(info,math.floor((root.Position-from).Magnitude+.5).." studs") end
  end
  local tool=ch:FindFirstChildOfClass("Tool")
  if s.WeaponESP and tool then table.insert(info,tool.Name) end
  rec.bill.Enabled=show and (s.NameESP or #info>0)
  rec.name.Visible=s.NameESP
  rec.user.Visible=s.NameESP
  rec.name.Text=p.DisplayName
  rec.user.Text="@"..p.Name
  rec.meta.Text=table.concat(info,"  ·  ")
  rec.name.TextColor3=tint
  rec.user.TextColor3=s.TeamVisual and tint or c.muted
  rec.meta.TextColor3=s.TeamVisual and tint or c.muted
  rec.hi.Enabled=s.OutlineESP and show
  rec.hi.OutlineColor=tint
  rec.hi.DepthMode=s.ThroughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
  local hum=ch:FindFirstChildOfClass("Humanoid")
  local bones=hum and hum.RigType==Enum.HumanoidRigType.R15 and skeletonR15 or skeletonR6
  for i,line in ipairs(rec.lines) do
    local link=bones[i]
    local a=link and ch:FindFirstChild(link[1])
    local b=link and ch:FindFirstChild(link[2])
    line.Visible=false
    if s.SkeletonESP and show and a and b and camera then
      local p1,v1=camera:WorldToViewportPoint(a.Position)
      local p2,v2=camera:WorldToViewportPoint(b.Position)
      if v1 and v2 and p1.Z>0 and p2.Z>0 then
        local dx=p2.X-p1.X;local dy=p2.Y-p1.Y
        line.Position=UDim2.fromOffset((p1.X+p2.X)*.5,(p1.Y+p2.Y)*.5)
        line.Size=UDim2.fromOffset(math.sqrt(dx*dx+dy*dy),2)
        line.Rotation=math.deg(math.atan2(dy,dx))
        line.BackgroundColor3=tint;line.Visible=true
      end
    end
  end
end
local function pumpkinCandidate(obj)
  if not obj:IsA("Model") and not obj:IsA("BasePart") then return false end
  return string.find(obj.Name:lower(),"pumpkin",1,true)~=nil or CS:HasTag(obj,"Pumpkin")
end
local function markPumpkin(obj)
  if not pumpkinCandidate(obj) or pumpkins[obj] then return end
  pumpkins[obj]=make("Highlight",{Name="OX1DE_V4_Pumpkin",Adornee=obj,
    FillColor=c.white,FillTransparency=.82,OutlineColor=c.white,OutlineTransparency=.05,
    DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,Enabled=s.PumpkinESP},obj)
end
connect(workspace.DescendantAdded,function(obj)
  if running and pumpkinCandidate(obj) then markPumpkin(obj) end
end)
task.spawn(function()
  for i,obj in ipairs(workspace:GetDescendants()) do
    if not running then break end
    if pumpkinCandidate(obj) then markPumpkin(obj) end
    if i%300==0 then task.wait() end
  end
end)
connect(Players.PlayerRemoving,erase)
connect(lp.CharacterAdded,function()
  stopFly();restoreCollision()
  task.delay(.5,function()
    if running then speed();if s.Fly then startFly() end end
  end)
end)
connect(UIS.InputBegan,function(input,processed)
  if not running or UIS:GetFocusedTextBox() then return end
  if input.UserInputType~=Enum.UserInputType.Keyboard then return end
  local key=input.KeyCode
  if env.OX1DE_PENDING_BIND then
    local kind=env.OX1DE_PENDING_BIND
    env.OX1DE_PENDING_BIND=nil
    if key~=Enum.KeyCode.Escape and key~=Enum.KeyCode.RightShift and key~=Enum.KeyCode.Unknown then
      binds[kind]=key;save()
    end
    drawPage(chosen)
    return
  end
  if key==Enum.KeyCode.RightShift then setOpen(not open);return end
  if processed then return end
  for kind,bind in pairs(binds) do
    if key==bind then
      s[kind]=not s[kind]
      if kind=="Fly" then if s.Fly then startFly() else stopFly() end end
      if kind=="Noclip" and not s.Noclip then restoreCollision() end
      save();drawPage(chosen);break
    end
  end
end)
connect(RS.Heartbeat,function()
  if not running then return end
  if s.Noclip and lp.Character then
    for _,part in ipairs(lp.Character:GetDescendants()) do
      if part:IsA("BasePart") then
        if collisions[part]==nil then collisions[part]=part.CanCollide end
        part.CanCollide=false
      end
    end
  end
end)
local pulse=0
connect(RS.RenderStepped,function(dt)
  if not running then return end
  if s.Fly and flyForce and flyForce.Parent and workspace.CurrentCamera then
    local cam=workspace.CurrentCamera
    local dir=Vector3.zero
    if UIS:IsKeyDown(Enum.KeyCode.W) then dir=dir+cam.CFrame.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.S) then dir=dir-cam.CFrame.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.A) then dir=dir-cam.CFrame.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.D) then dir=dir+cam.CFrame.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.Space) then dir=dir+Vector3.yAxis end
    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir=dir-Vector3.yAxis end
    flyForce.Velocity=dir.Magnitude>0 and dir.Unit*45 or Vector3.zero
    flyGyro.CFrame=cam.CFrame
  end
  pulse=pulse+dt
  if pulse<.05 then return end
  pulse=0
  local any=s.NameESP or s.DistanceESP or s.SkeletonESP or s.OutlineESP or s.WeaponESP
  local root=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
  for _,p in ipairs(Players:GetPlayers()) do
    if p~=lp then
      if any then
        local rec=ensure(p)
        if rec then updateOverlay(p,rec,root) end
      else erase(p) end
    end
  end
  for obj,h in pairs(pumpkins) do
    if obj.Parent and h.Parent then h.Enabled=s.PumpkinESP
    else if h.Parent then h:Destroy() end;pumpkins[obj]=nil end
  end
end)
local function partFor(ch)
  if s.AimPart=="Head" then return ch:FindFirstChild("Head") end
  if s.AimPart=="Legs" then
    return ch:FindFirstChild("LeftFoot") or ch:FindFirstChild("Left Leg") or ch:FindFirstChild("LeftLowerLeg")
  end
  return ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso") or ch:FindFirstChild("HumanoidRootPart")
end
RS:BindToRenderStep("OX1DE_V4_Aim",Enum.RenderPriority.Camera.Value+5,function()
  if not running or not s.Aim or open then return end
  local cam=workspace.CurrentCamera
  if not cam then return end
  local midpoint=cam.ViewportSize*.5
  local target,best=nil,s.FOVRadius
  for _,p in ipairs(Players:GetPlayers()) do
    if p~=lp and (not s.TeamAim or not (lp.Team~=nil and p.Team~=nil and lp.Team==p.Team)) then
      local ch=p.Character
      local hum=ch and ch:FindFirstChildOfClass("Humanoid")
      local part=ch and partFor(ch)
      if hum and hum.Health>0 and part and (not s.WallCheck or visibleToCamera(ch)) then
        local q,onscreen=cam:WorldToViewportPoint(part.Position)
        if onscreen and q.Z>0 then
          local gap=(Vector2.new(q.X,q.Y)-midpoint).Magnitude
          if gap<best then target=part;best=gap end
        end
      end
    end
  end
  if target then
    local wanted=CFrame.lookAt(cam.CFrame.Position,target.Position)
    local amount=s.AimSpeed>=.995 and 1 or (.03+s.AimSpeed*.97)
    cam.CFrame=cam.CFrame:Lerp(wanted,amount)
  end
end)
local function cleanup()
  if not running then return end
  save()
  running=false
  pcall(function() RS:UnbindFromRenderStep("OX1DE_V4_Aim") end)
  stopFly();restoreCollision();clearTemp()
  if viewportConnection then viewportConnection:Disconnect() end
  for _,co in ipairs(links) do co:Disconnect() end
  for p,_ in pairs(overlayPlayers) do erase(p) end
  for _,h in pairs(pumpkins) do if h.Parent then h:Destroy() end end
  if open then
    if mouseBehavior then UIS.MouseBehavior=mouseBehavior end
    if mouseIcon~=nil then UIS.MouseIconEnabled=mouseIcon end
  end
  if menu then menu:Destroy() end
  if overlay then overlay:Destroy() end
end
env.OX1DE_CLEANUP=cleanup
env.OX1DE_HUB_CLEANUP=cleanup
drawPage("Player")
updateFOV()
speed()
if s.Fly then task.defer(function()if running then startFly()end end) end
shell.Visible=false
setOpen(true)
