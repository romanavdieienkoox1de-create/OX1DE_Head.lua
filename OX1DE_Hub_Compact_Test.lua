-- OX1DE Hub Compact v1.4 - skeleton overlay frame sync; aim unchanged.
-- No legacy GUI, no automatic world scanning, no auto-enabled gameplay functions.
local P=game:GetService("Players")
local U=game:GetService("UserInputService")
local R=game:GetService("RunService")
local T=game:GetService("TweenService")
local player=P.LocalPlayer
if not player then return end
local pg=player:WaitForChild("PlayerGui")
local env=(type(getgenv)=="function" and getgenv()) or _G
if type(env.OX1DE_CLEANUP)=="function" then pcall(env.OX1DE_CLEANUP) end
if type(env.OX1DE_HUB_CLEANUP)=="function" then pcall(env.OX1DE_HUB_CLEANUP) end
for _,name in ipairs({"OX1DE_HUB_V4","OX1DE_HUB_V4_OVERLAY","OX1DE_CompactSafe"}) do
 local old=pg:FindFirstChild(name)
 if old then old:Destroy() end
end
local alive=true
local conns,overlays={},{}
local states={AllESP=false,Aim=false,FOV=false,TeamCheck=false,Noclip=false,Fly=false}
local binds={Aim=Enum.KeyCode.R,Noclip=Enum.KeyCode.Z,Fly=Enum.KeyCode.X}
local red=Color3.fromRGB(243,65,68)
local green=Color3.fromRGB(58,221,132)
local white=Color3.fromRGB(243,245,248)
local gray=Color3.fromRGB(156,164,176)
local bg=Color3.fromRGB(14,15,19)
local function conn(signal,callback)
 local c=signal:Connect(callback);table.insert(conns,c);return c
end
local function make(class,props,parent)
 local o=Instance.new(class)
 for k,v in pairs(props) do o[k]=v end
 o.Parent=parent
 return o
end
local function corner(obj,n) make("UICorner",{CornerRadius=UDim.new(0,n)},obj);return obj end
local function txt(parent,value,size,color)
 return make("TextLabel",{BackgroundTransparency=1,Text=value,Font=Enum.Font.GothamSemibold,
 TextSize=size,TextColor3=color or white,TextXAlignment=Enum.TextXAlignment.Left},parent)
end
local gui=make("ScreenGui",{Name="OX1DE_CompactSafe",ResetOnSpawn=false,IgnoreGuiInset=true,
 DisplayOrder=120,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},pg)
local panel=corner(make("Frame",{AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(0,8,.5,0),
 Size=UDim2.fromOffset(310,490),BackgroundColor3=bg,BorderSizePixel=0},gui),15)
make("UIStroke",{Color=Color3.fromRGB(85,88,98),Thickness=1},panel)
local panelScale=make("UIScale",{Scale=.23},panel)
local function smooth(object,properties,duration)
 if not object or not object.Parent then return end
 T:Create(object,TweenInfo.new(duration or .2,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),properties):Play()
end
panelScale.Scale=.18
smooth(panelScale,{Scale=.23},.3)
local translucent=false
local header=make("Frame",{Size=UDim2.new(1,0,0,56),BackgroundColor3=Color3.fromRGB(25,27,32),BorderSizePixel=0},panel)
local title=txt(header,"OX1DE Hub",19,white);title.Position=UDim2.fromOffset(16,8);title.Size=UDim2.fromOffset(245,26)
local subtitle=txt(header,"E UP / Q DOWN  •  AIM R",10,gray);subtitle.Position=UDim2.fromOffset(17,34);subtitle.Size=UDim2.fromOffset(270,15)
local line=make("Frame",{Position=UDim2.new(0,0,1,-1),Size=UDim2.new(1,0,0,1),
 BackgroundColor3=Color3.fromRGB(70,73,80),BorderSizePixel=0},header)
local entries={}
local names={{"ALL ESP","AllESP"},{"AIM","Aim","Aim"},{"FOV","FOV"},
 {"TEAM CHECK","TeamCheck"},{"NOCLIP","Noclip","Noclip"},{"FLY","Fly","Fly"}}
local awaiting=nil
local update,flip
for i,item in ipairs(names) do
 local label,key,bind=item[1],item[2],item[3]
 local y=64+(i-1)*53
 local row=corner(make("Frame",{Position=UDim2.fromOffset(11,y),Size=UDim2.fromOffset(288,47),
  BackgroundColor3=Color3.fromRGB(30,32,37),BorderSizePixel=0},panel),9)
 local led=corner(make("Frame",{Position=UDim2.fromOffset(12,17),Size=UDim2.fromOffset(12,12),BackgroundColor3=red,BorderSizePixel=0},row),8)
 local caption=txt(row,label,13,white)
 caption.Position=UDim2.fromOffset(34,7);caption.Size=UDim2.fromOffset(bind and 115 or 170,32)
 local kb=nil
 if bind then
  kb=corner(make("TextButton",{Position=UDim2.fromOffset(172,8),Size=UDim2.fromOffset(44,31),
    BackgroundColor3=bg,Text=binds[bind].Name,TextColor3=white,TextSize=12,
    Font=Enum.Font.GothamBold,AutoButtonColor=false},row),7)
  conn(kb.MouseButton1Click,function()awaiting=bind;kb.Text="..."end)
 end
 local sw=corner(make("TextButton",{Position=UDim2.fromOffset(225,10),Size=UDim2.fromOffset(51,27),
  BackgroundColor3=Color3.fromRGB(70,73,81),Text="",AutoButtonColor=false},row),14)
 local thumb=corner(make("Frame",{Position=UDim2.fromOffset(4,4),Size=UDim2.fromOffset(19,19),
  BackgroundColor3=white,BorderSizePixel=0},sw),10)
 entries[key]={led=led,sw=sw,thumb=thumb,kb=kb}
 conn(sw.MouseEnter,function()smooth(row,{BackgroundColor3=Color3.fromRGB(46,48,56)},.15)end)
 conn(sw.MouseLeave,function()smooth(row,{BackgroundColor3=Color3.fromRGB(30,32,37)},.16)end)
 conn(sw.MouseButton1Click,function()flip(key)end)
end
local fovLabel=txt(panel,"FOV RADIUS",10,gray)
fovLabel.Position=UDim2.fromOffset(17,390);fovLabel.Size=UDim2.fromOffset(150,20)
local radius=145
local value=txt(panel,tostring(radius),11,white)
value.Position=UDim2.fromOffset(253,390);value.Size=UDim2.fromOffset(42,20)
local bar=corner(make("TextButton",{Position=UDim2.fromOffset(16,424),Size=UDim2.fromOffset(278,7),
 BackgroundColor3=Color3.fromRGB(70,73,81),Text="",AutoButtonColor=false},panel),4)
local fill=corner(make("Frame",{Size=UDim2.fromScale(.31,1),BackgroundColor3=red,BorderSizePixel=0},bar),4)
local dot=corner(make("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.31,.5),
 Size=UDim2.fromOffset(14,14),BackgroundColor3=white,BorderSizePixel=0},bar),8)
local hint=txt(panel,"BACKGROUND: DARK  •  CLICK TO CHANGE",10,gray)
hint.Position=UDim2.fromOffset(17,452);hint.Size=UDim2.fromOffset(280,18)
local backgroundToggle=corner(make("TextButton",{Position=UDim2.fromOffset(16,448),Size=UDim2.fromOffset(278,28),BackgroundColor3=Color3.fromRGB(28,30,35),Text="BACKGROUND  ·  DARK",TextColor3=white,TextSize=11,Font=Enum.Font.GothamBold,AutoButtonColor=false},panel),7)
conn(backgroundToggle.MouseButton1Click,function()
 translucent=not translucent
 panel.BackgroundTransparency=translucent and .26 or 0
 backgroundToggle.Text=translucent and "BACKGROUND  ·  TRANSPARENT" or "BACKGROUND  ·  DARK"
end)
local circle=corner(make("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
 Size=UDim2.fromOffset(radius*2,radius*2),BackgroundTransparency=1,Visible=false},gui),9999)
make("UIStroke",{Color=red,Thickness=2},circle)
local function fovDraw()
 circle.Visible=states.FOV
 circle.Size=UDim2.fromOffset(radius*2,radius*2)
end
local function updateSwitches()
 for k,row in pairs(entries) do
  local on=states[k]
  row.led.BackgroundColor3=on and green or red
  smooth(row.sw,{BackgroundColor3=on and green or Color3.fromRGB(70,73,81)},.18)
  smooth(row.thumb,{Position=UDim2.fromOffset(on and 28 or 4,4)},.18)
  if row.kb and awaiting~=k then row.kb.Text=binds[k].Name end
 end
end
local movedParts={}
local velocity,gyro,rot=nil,nil,nil
local function stopFly()
 if velocity then velocity:Destroy();velocity=nil end
 if gyro then gyro:Destroy();gyro=nil end
 local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
 if h and rot~=nil then h.AutoRotate=rot end
 rot=nil
end
local function startFly()
 stopFly()
 local ch=player.Character
 local root=ch and ch:FindFirstChild("HumanoidRootPart")
 local h=ch and ch:FindFirstChildOfClass("Humanoid")
 if not root or not h then states.Fly=false;updateSwitches();return end
 rot=h.AutoRotate;h.AutoRotate=false
 velocity=make("BodyVelocity",{Velocity=Vector3.zero,MaxForce=Vector3.new(1e7,1e7,1e7)},root)
 gyro=make("BodyGyro",{CFrame=workspace.CurrentCamera.CFrame,MaxTorque=Vector3.new(1e7,1e7,1e7)},root)
end
local function restoreCollision()
 for part,old in pairs(movedParts) do if part.Parent then part.CanCollide=old end end
 table.clear(movedParts)
end
local function erase(p)
 local rec=overlays[p]
 if rec then
  if rec.bill then rec.bill:Destroy() end
  if rec.hi then rec.hi:Destroy() end
  for _,l in ipairs(rec.lines) do l:Destroy() end
 end
 overlays[p]=nil
end
local bonesR15={{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
 {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
 {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
 {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
 {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}}
local bonesR6={{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}
local function getRec(p)
 local ch=p.Character;local h=ch and ch:FindFirstChildOfClass("Humanoid");local hd=ch and ch:FindFirstChild("Head")
 if not ch or not hd or not h or h.Health<=0 then erase(p);return nil end
 local rec=overlays[p]
 if rec and rec.char~=ch then erase(p);rec=nil end
 if rec then return rec end
 rec={char=ch,lines={}}
 rec.bill=make("BillboardGui",{Adornee=hd,Size=UDim2.fromOffset(190,66),
 StudsOffsetWorldSpace=Vector3.new(0,2,0),AlwaysOnTop=true},gui)
 rec.name=txt(rec.bill,p.DisplayName,14,white);rec.name.Size=UDim2.fromOffset(190,20);rec.name.TextXAlignment=Enum.TextXAlignment.Center
 rec.user=txt(rec.bill,"@"..p.Name,11,gray);rec.user.Position=UDim2.fromOffset(0,20);rec.user.Size=UDim2.fromOffset(190,18);rec.user.TextXAlignment=Enum.TextXAlignment.Center
 rec.meta=txt(rec.bill,"",11,gray);rec.meta.Position=UDim2.fromOffset(0,40);rec.meta.Size=UDim2.fromOffset(190,19);rec.meta.TextXAlignment=Enum.TextXAlignment.Center
 rec.hi=make("Highlight",{Adornee=ch,FillTransparency=1,OutlineTransparency=.25,
 DepthMode=Enum.HighlightDepthMode.AlwaysOnTop},ch)
 local links=h.RigType==Enum.HumanoidRigType.R15 and bonesR15 or bonesR6
 for i=1,#links do rec.lines[i]=make("Frame",{Visible=false,BorderSizePixel=0,
 AnchorPoint=Vector2.new(.5,.5),BackgroundColor3=white,Size=UDim2.fromOffset(1,2)},gui) end
 overlays[p]=rec
 return rec
end
local function updateOverlay(p,rec)
 local ch=rec.char
 local cam=workspace.CurrentCamera
 if not cam then return end
 local root=ch:FindFirstChild("HumanoidRootPart")
 local myroot=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 local tint=white
 if states.TeamCheck then tint=(player.Team~=nil and p.Team~=nil and player.Team==p.Team) and green or red end
 rec.name.Text=p.DisplayName
 rec.name.TextColor3=tint;rec.hi.OutlineColor=tint
 local tool=ch:FindFirstChildOfClass("Tool")
 local a={}
 if tool then table.insert(a,tool.Name) end
 if root and myroot then table.insert(a,math.floor((root.Position-myroot.Position).Magnitude+.5).." studs") end
 rec.meta.Text=table.concat(a," • ")
 local hum=ch:FindFirstChildOfClass("Humanoid")
 local links=hum and hum.RigType==Enum.HumanoidRigType.R15 and bonesR15 or bonesR6

end
local function updateSkeleton(p,rec)
 if not rec or not rec.char or not rec.char.Parent then return end
 local ch=rec.char
 local cam=workspace.CurrentCamera
 if not cam then return end
 local tint=white
 if states.TeamCheck then tint=(player.Team~=nil and p.Team~=nil and player.Team==p.Team) and green or red end
 local hum=ch:FindFirstChildOfClass("Humanoid")
 local links=hum and hum.RigType==Enum.HumanoidRigType.R15 and bonesR15 or bonesR6
 for i,line in ipairs(rec.lines) do
  line.Visible=false
  local parts=links[i]
  local pa=parts and ch:FindFirstChild(parts[1]);local pb=parts and ch:FindFirstChild(parts[2])
  if pa and pb then
   local v1,on1=cam:WorldToViewportPoint(pa.Position)
   local v2,on2=cam:WorldToViewportPoint(pb.Position)
   if on1 and on2 and v1.Z>0 and v2.Z>0 then
    local dx=v2.X-v1.X;local dy=v2.Y-v1.Y
    line.Position=UDim2.fromOffset((v1.X+v2.X)/2,(v1.Y+v2.Y)/2)
    line.Size=UDim2.fromOffset(math.sqrt(dx*dx+dy*dy),2)
    line.Rotation=math.deg(math.atan2(dy,dx));line.BackgroundColor3=tint;line.Visible=true
   end
  end
 end
end
flip=function(key)
 states[key]=not states[key]
 if key=="FOV" then fovDraw() end
 if key=="Fly" then if states.Fly then startFly() else stopFly() end end
 if key=="Noclip" and not states.Noclip then restoreCollision() end
 if key=="AllESP" and not states.AllESP then
  for p,_ in pairs(overlays) do erase(p) end
 end
 updateSwitches()
end
update=function()updateSwitches()end
local drag=false
local function setRadius(x)
 radius=math.floor(30+370*math.clamp((x-bar.AbsolutePosition.X)/math.max(1,bar.AbsoluteSize.X),0,1))
 local ratio=(radius-30)/370
 fill.Size=UDim2.fromScale(ratio,1);dot.Position=UDim2.fromScale(ratio,.5);value.Text=tostring(radius);fovDraw()
end
conn(bar.InputBegan,function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true;setRadius(i.Position.X)end end)
conn(U.InputChanged,function(i)if drag and i.UserInputType==Enum.UserInputType.MouseMovement then setRadius(i.Position.X)end end)
conn(U.InputEnded,function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
conn(U.InputBegan,function(i,processed)
 if not alive or i.UserInputType~=Enum.UserInputType.Keyboard then return end
 if awaiting then
  if i.KeyCode~=Enum.KeyCode.Escape and i.KeyCode~=Enum.KeyCode.Unknown then binds[awaiting]=i.KeyCode end
  awaiting=nil;updateSwitches();return
 end
 if processed then return end
 for k,key in pairs(binds) do if i.KeyCode==key then flip(k);break end end
end)
conn(player.CharacterAdded,function()stopFly();restoreCollision()end)
conn(P.PlayerRemoving,erase)
local elapsed=0
conn(R.Heartbeat,function(dt)
 if not alive then return end
 if states.Noclip and player.Character then
  for _,part in ipairs(player.Character:GetChildren()) do
   if part:IsA("BasePart") then
    if movedParts[part]==nil then movedParts[part]=part.CanCollide end
    part.CanCollide=false
   end
  end
 end
 if states.Fly and velocity and gyro and workspace.CurrentCamera then
  local cam=workspace.CurrentCamera;local d=Vector3.zero
  if U:IsKeyDown(Enum.KeyCode.W) then d=d+cam.CFrame.LookVector end
  if U:IsKeyDown(Enum.KeyCode.S) then d=d-cam.CFrame.LookVector end
  if U:IsKeyDown(Enum.KeyCode.A) then d=d-cam.CFrame.RightVector end
  if U:IsKeyDown(Enum.KeyCode.D) then d=d+cam.CFrame.RightVector end
  if U:IsKeyDown(Enum.KeyCode.E) then d=d+Vector3.yAxis end
  if U:IsKeyDown(Enum.KeyCode.Q) then d=d-Vector3.yAxis end
  velocity.Velocity=d.Magnitude>0 and d.Unit*40 or Vector3.zero
  gyro.CFrame=cam.CFrame
 end
 elapsed=elapsed+dt
 if elapsed<.12 then return end
 elapsed=0
 if states.AllESP then
  for _,p in ipairs(P:GetPlayers()) do
   if p~=player then local rec=getRec(p);if rec then updateOverlay(p,rec) end end
  end
 end
end)
local function unobstructed(target,character)
 local camera=workspace.CurrentCamera
 if not camera then return false end
 local direction=target.Position-camera.CFrame.Position
 if direction.Magnitude<.01 then return true end
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances={player.Character or camera}
 params.IgnoreWater=true
 local hit=workspace:Raycast(camera.CFrame.Position,direction,params)
 return hit==nil or hit.Instance:IsDescendantOf(character)
end
-- Update skeleton lines every rendered frame instead of the old 120 ms refresh loop.
-- No target selection or camera movement is changed here.
conn(R.RenderStepped,function()
 if not alive or not states.AllESP then return end
 for p,rec in pairs(overlays) do updateSkeleton(p,rec) end
end)
conn(R.RenderStepped,function()
 if not alive or not states.Aim then return end
 local cam=workspace.CurrentCamera
 if not cam then return end
 local nearest,best=nil,radius
 for _,p in ipairs(P:GetPlayers()) do
  if p~=player and (not states.TeamCheck or not (player.Team and p.Team and player.Team==p.Team)) then
   local ch=p.Character;local hum=ch and ch:FindFirstChildOfClass("Humanoid")
   local hd=ch and ch:FindFirstChild("Head")
   if hum and hum.Health>0 and hd and unobstructed(hd,ch) then
    local xy,on=cam:WorldToViewportPoint(hd.Position)
    if on and xy.Z>0 then
     local dist=(Vector2.new(xy.X,xy.Y)-cam.ViewportSize/2).Magnitude
     if dist<best then nearest=hd;best=dist end
    end
   end
  end
 end
 if nearest then cam.CFrame=CFrame.lookAt(cam.CFrame.Position,nearest.Position) end
end)
local function cleanup()
 if not alive then return end
 alive=false
 stopFly();restoreCollision()
 for _,co in ipairs(conns) do co:Disconnect() end
 for p,_ in pairs(overlays) do erase(p) end
 gui:Destroy()
end
env.OX1DE_CLEANUP=cleanup
env.OX1DE_HUB_CLEANUP=cleanup
updateSwitches()
