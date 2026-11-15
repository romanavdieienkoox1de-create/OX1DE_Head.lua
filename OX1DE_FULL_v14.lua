-- OX1DE 1.0 | rebuilt menu with recoverable features and error indicator
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local player = Players.LocalPlayer
assert(player, "No LocalPlayer")
local pg = player:WaitForChild("PlayerGui", 10)
assert(pg, "No PlayerGui")
if type(_G.OX1DE_CLEANUP) == "function" then pcall(_G.OX1DE_CLEANUP) end
for _, name in ipairs({"OX1DE_Head_Menu","OX1DE_Head_Menu_v07","OX1DE_Head_Menu_v08","OX1DE_V09_TEST","OX1DE_FULL_V10"}) do
 local old = pg:FindFirstChild(name)
 if old then old:Destroy() end
end
local connections = {}
local function on(signal, fn)
 local c = signal:Connect(fn)
 table.insert(connections, c)
 return c
end
local gui = Instance.new("ScreenGui")
gui.Name="OX1DE_FULL_V10"
gui.ResetOnSpawn=false
gui.DisplayOrder=9999
gui.IgnoreGuiInset=true
gui.Parent=pg
local function make(class, props, parent)
 local o=Instance.new(class)
 for k,v in pairs(props) do o[k]=v end
 o.Parent=parent
 return o
end
local window=make("Frame",{
 Name="Window",Size=UDim2.fromOffset(270,480),Position=UDim2.new(0,24,0.24,0),
 BackgroundColor3=Color3.fromRGB(19,19,25),BorderSizePixel=0,Active=true,Draggable=true,ZIndex=10
},gui)
make("UICorner",{CornerRadius=UDim.new(0,10)},window)
local heading=make("TextLabel",{
 Text="OX1DE 1.4",Font=Enum.Font.GothamBold,TextSize=19,TextColor3=Color3.new(1,1,1),
 BackgroundTransparency=1,Position=UDim2.fromOffset(10,8),Size=UDim2.fromOffset(250,28),ZIndex=11
},window)
local status=make("TextLabel",{
 Text="READY",Font=Enum.Font.Gotham,TextSize=11,TextColor3=Color3.fromRGB(135,245,160),
 BackgroundTransparency=1,Position=UDim2.fromOffset(10,449),Size=UDim2.fromOffset(250,20),ZIndex=11
},window)
local function fail(message)
 status.Text="ERROR: "..tostring(message):sub(1,70)
 status.TextColor3=Color3.fromRGB(255,90,90)
 warn("[OX1DE] "..tostring(message))
end
local function button(text,y)
 local b=make("TextButton",{
  Text=text,Font=Enum.Font.GothamSemibold,TextSize=13,TextColor3=Color3.new(1,1,1),
  Size=UDim2.fromOffset(248,32),Position=UDim2.fromOffset(11,y),
  BackgroundColor3=Color3.fromRGB(46,46,59),BorderSizePixel=0,ZIndex=12
 },window)
 make("UICorner",{CornerRadius=UDim.new(0,6)},b)
 return b
end
local aimBtn=button("AIM [E]: OFF",44)
local espBtn=button("ESP: ON",82)
local fovLabel=make("TextLabel",{Text="FOV: 50 / 100",Font=Enum.Font.GothamBold,TextSize=13,TextColor3=Color3.new(1,1,1),BackgroundTransparency=1,Position=UDim2.fromOffset(10,124),Size=UDim2.fromOffset(250,23),ZIndex=11},window)
local slider=make("TextButton",{Text="",Position=UDim2.fromOffset(18,152),Size=UDim2.fromOffset(234,16),BackgroundColor3=Color3.fromRGB(70,70,76),BorderSizePixel=0,ZIndex=13},window)
make("UICorner",{CornerRadius=UDim.new(1,0)},slider)
local sliderFill=make("Frame",{Size=UDim2.fromScale(.5,1),BackgroundColor3=Color3.fromRGB(255,44,44),BorderSizePixel=0,ZIndex=14},slider)
make("UICorner",{CornerRadius=UDim.new(1,0)},sliderFill)
local flyBtn=button("FLY [F]: OFF",183)
local noclipBtn=button("NOCLIP [N]: OFF",221)
local hitboxBtn=button("HITBOX VIEW x8: OFF",259)
local pushBtn=button("PUSH DASH: OFF",297)
local closeBtn=button("CLOSE",374)
local languageButton=button("Язык: Русский",412)
languageButton.Size=UDim2.fromOffset(150,32)
local bindHint=make("TextLabel",{
 Text="Bind: click the small key button, then press a key",
 Font=Enum.Font.Gotham,TextSize=10,TextColor3=Color3.fromRGB(190,190,205),
 BackgroundTransparency=1,Size=UDim2.fromOffset(250,18),
 Position=UDim2.fromOffset(10,348),ZIndex=11
},window)
local state={aim=false,esp=true,fly=false,noclip=false,hitbox=false,push=false,fov=50}
local bindings={aim=Enum.KeyCode.E,fly=Enum.KeyCode.F,noclip=Enum.KeyCode.N,hitbox=Enum.KeyCode.H,push=Enum.KeyCode.P}
local bindButtons={}
local awaitingBind=nil
local currentLanguage="ru"
local function bindButton(feature,y)
 local b=make("TextButton",{
  Text=bindings[feature].Name,Font=Enum.Font.GothamBold,TextSize=11,
  TextColor3=Color3.fromRGB(255,255,255),BackgroundColor3=Color3.fromRGB(120,40,40),
  BorderSizePixel=0,Size=UDim2.fromOffset(54,32),Position=UDim2.fromOffset(204,y),ZIndex=16
 },window)
 make("UICorner",{CornerRadius=UDim.new(0,6)},b)
 bindButtons[feature]=b
 on(b.MouseButton1Click,function()
  awaitingBind=feature
  b.Text="..."
  status.Text=tr("press")..string.upper(feature)
 end)
end
bindButton("aim",44)
bindButton("fly",183)
bindButton("noclip",221)
bindButton("hitbox",259)
bindButton("push",297)
for _,b in ipairs({aimBtn,flyBtn,noclipBtn,hitboxBtn,pushBtn}) do b.Size=UDim2.fromOffset(185,32) end
local translations={
 ru={on="ВКЛ",off="ВЫКЛ",aim="Наведение",esp="Подсветка",push="Рывок",close="Закрыть",lang="Язык: Русский",hint="Бинд: нажми кнопку с буквой, затем новую клавишу",ready="Готово",press="Нажми новую клавишу: ",cancel="Назначение отменено",busy="Клавиша уже занята: ",bound="Назначено: "},
 en={on="ON",off="OFF",aim="Aim",esp="ESP",push="Dash",close="Close",lang="Language: English",hint="Bind: click a key button, then press a new key",ready="Ready",press="Press a new key for ",cancel="Bind cancelled",busy="Key already bound: ",bound="Bound: "}
}
local function tr(key) return translations[currentLanguage][key] end
local function updateBindLabels()
 local onOff=function(v) return v and tr("on") or tr("off") end
 aimBtn.Text=tr("aim").." ["..bindings.aim.Name.."]: "..onOff(state.aim)
 flyBtn.Text="Fly ["..bindings.fly.Name.."]: "..onOff(state.fly)
 noclipBtn.Text="No Clip ["..bindings.noclip.Name.."]: "..onOff(state.noclip)
 hitboxBtn.Text="Hitbox: "..onOff(state.hitbox)
 pushBtn.Text=tr("push")..": "..onOff(state.push)
 closeBtn.Text=tr("close")
 languageButton.Text=tr("lang")
 bindHint.Text=tr("hint")
 espBtn.Text=tr("esp")..": "..onOff(state.esp)
end
on(languageButton.MouseButton1Click,function()
 currentLanguage=currentLanguage=="ru" and "en" or "ru"
 updateBindLabels()
 status.Text=tr("ready")
end)
updateBindLabels()
-- A separate transparent overlay ring, independent from the menu frame
local ringSegments={}
for i=1,64 do
 ringSegments[i]=make("Frame",{
  Name="FOV_"..i,AnchorPoint=Vector2.new(.5,.5),
  Size=UDim2.fromOffset(10,3),BackgroundColor3=Color3.fromRGB(255,25,25),
  BorderSizePixel=0,ZIndex=3
 },gui)
end
local function setFov(val)
 state.fov=math.clamp(math.floor(val+.5),0,100)
 fovLabel.Text="FOV: "..state.fov.." / 100"
 sliderFill.Size=UDim2.fromScale(state.fov/100,1)
 local radius=state.fov*3
 for i,seg in ipairs(ringSegments) do
  local angle=i*2*math.pi/#ringSegments
  seg.Visible=radius>0
  seg.Size=UDim2.fromOffset(math.max(3,2*math.pi*radius/#ringSegments+2),3)
  seg.Position=UDim2.new(.5,math.cos(angle)*radius,.5,math.sin(angle)*radius)
  seg.Rotation=math.deg(angle)+90
 end
end
setFov(50)
local sliding=false
local function slideAt(pos)
 if slider.AbsoluteSize.X>0 then
  setFov(((pos-slider.AbsolutePosition.X)/slider.AbsoluteSize.X)*100)
 end
end
on(slider.InputBegan,function(i)
 if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
  sliding=true
  slideAt(i.Position.X)
 end
end)
on(UIS.InputChanged,function(i)
 if sliding and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
  slideAt(i.Position.X)
 end
end)
on(UIS.InputEnded,function(i)
 if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sliding=false end
end)
local highlights={}
local labels={}
local function clearPlayerVisuals()
 for _,h in pairs(highlights) do pcall(function() h:Destroy() end) end
 for _,entry in pairs(labels) do
  pcall(function() entry.name:Destroy() end)
  pcall(function() entry.distance:Destroy() end)
 end
 table.clear(highlights)
 table.clear(labels)
end
local function createBillboard(part, offset, value)
 local b=make("BillboardGui",{
  Size=UDim2.fromOffset(200,25),Adornee=part,StudsOffsetWorldSpace=offset,
  AlwaysOnTop=true,MaxDistance=800,Enabled=true
 },gui)
 local t=make("TextLabel",{
  Size=UDim2.fromScale(1,1),Text=value,
  BackgroundTransparency=1,TextColor3=Color3.new(1,1,1),
  TextStrokeTransparency=0,Font=Enum.Font.GothamBold,TextSize=14
 },b)
 return b,t
end
local function refreshESP()
 clearPlayerVisuals()
 if not state.esp then return end
 for _,other in ipairs(Players:GetPlayers()) do
  if other~=player and other.Character then
   local head=other.Character:FindFirstChild("Head")
   local root=other.Character:FindFirstChild("HumanoidRootPart")
   if head and root then
    local h=make("Highlight",{
     Adornee=other.Character,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,
     FillColor=Color3.fromRGB(150,150,150),FillTransparency=.55,
     OutlineColor=Color3.fromRGB(255,255,255)
    },gui)
    highlights[other]=h
    local nameBoard=createBillboard(head,Vector3.new(0,2.4,0),other.DisplayName)
    local distBoard,distText=createBillboard(root,Vector3.new(0,-3,0),"")
    labels[other]={name=nameBoard,distance=distBoard,distText=distText}
   end
  end
 end
end
local function protectedRefresh()
 local ok,err=pcall(refreshESP)
 if not ok then fail(err) end
end
local flyVelocity,flyGyro
local function stopFly()
 if flyVelocity then flyVelocity:Destroy();flyVelocity=nil end
 if flyGyro then flyGyro:Destroy();flyGyro=nil end
end
local function setFly(value)
 state.fly=value
 updateBindLabels()
 stopFly()
 if not value then return end
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 if not root then return end
 flyVelocity=make("BodyVelocity",{
  MaxForce=Vector3.new(1e7,1e7,1e7),Velocity=Vector3.new(0,0,0)
 },root)
 flyGyro=make("BodyGyro",{
  MaxTorque=Vector3.new(1e7,1e7,1e7),P=3000
 },root)
end
local collisionOriginal={}
local hitboxVisuals={}
local function clearHitboxVisuals()
 for _,adornment in pairs(hitboxVisuals) do
  pcall(function() adornment:Destroy() end)
 end
 table.clear(hitboxVisuals)
end
local function setNoclip(value)
 state.noclip=value
 updateBindLabels()
 if not value then
  for part,collide in pairs(collisionOriginal) do
   if part.Parent then part.CanCollide=collide end
  end
  table.clear(collisionOriginal)
 end
end
local function setHitboxes(value)
 state.hitbox=value
 updateBindLabels()
 if not value then clearHitboxVisuals() end
end
local function toggleAim()
 state.aim=not state.aim
 updateBindLabels()
end
on(aimBtn.MouseButton1Click,toggleAim)
on(espBtn.MouseButton1Click,function()
 state.esp=not state.esp
 updateBindLabels()
 protectedRefresh()
end)
on(flyBtn.MouseButton1Click,function() local ok,err=pcall(setFly,not state.fly);if not ok then fail(err) end end)
on(noclipBtn.MouseButton1Click,function() local ok,err=pcall(setNoclip,not state.noclip);if not ok then fail(err) end end)
on(hitboxBtn.MouseButton1Click,function() local ok,err=pcall(setHitboxes,not state.hitbox);if not ok then fail(err) end end)
local pushBoost=0
local function setPush(value)
 state.push=value
 updateBindLabels()
 if not value then pushBoost=0 end
end
on(pushBtn.MouseButton1Click,function() setPush(not state.push) end)
on(UIS.InputBegan,function(i,processed)
 if awaitingBind then
  if i.UserInputType~=Enum.UserInputType.Keyboard then return end
  if i.KeyCode==Enum.KeyCode.Escape then
   bindButtons[awaitingBind].Text=bindings[awaitingBind].Name
   awaitingBind=nil
   status.Text=tr("cancel")
   return
  end
  if i.KeyCode==Enum.KeyCode.Unknown then return end
  local feature=awaitingBind
  for other,key in pairs(bindings) do
   if other~=feature and key==i.KeyCode then
    status.Text=tr("busy")..other
    bindButtons[feature].Text=bindings[feature].Name
    awaitingBind=nil
    return
   end
  end
  bindings[feature]=i.KeyCode
  bindButtons[feature].Text=i.KeyCode.Name
  awaitingBind=nil
  updateBindLabels()
  status.Text=tr("bound")..feature.." -> "..i.KeyCode.Name
  return
 end
 if processed or UIS:GetFocusedTextBox() then return end
 local key=i.KeyCode
 if key==bindings.aim then toggleAim() end
 if key==bindings.fly then pcall(setFly,not state.fly) end
 if key==bindings.noclip then pcall(setNoclip,not state.noclip) end
 if key==bindings.hitbox then pcall(setHitboxes,not state.hitbox) end
 if key==bindings.push then setPush(not state.push) end
end)
on(Players.PlayerAdded,function(other)
 on(other.CharacterAdded,function() task.defer(protectedRefresh) end)
end)
for _,other in ipairs(Players:GetPlayers()) do
 if other~=player then
  on(other.CharacterAdded,function() task.defer(protectedRefresh) end)
 end
end
on(Players.PlayerRemoving,function(other)
 task.defer(protectedRefresh)
end)
on(player.CharacterAdded,function()
 stopFly()
 task.delay(.5,function()
  if state.fly then pcall(setFly,true) end
 end)
end)
local frameCounter=0
on(RS.Heartbeat,function()
 frameCounter=frameCounter+1
 if state.noclip and player.Character then
  for _,part in ipairs(player.Character:GetDescendants()) do
   if part:IsA("BasePart") then
    if collisionOriginal[part]==nil then collisionOriginal[part]=part.CanCollide end
    part.CanCollide=false
   end
  end
 end
 if state.hitbox and frameCounter%8==0 then
  local current={}
  for _,other in ipairs(Players:GetPlayers()) do
   if other~=player and other.Character then
    local root=other.Character:FindFirstChild("HumanoidRootPart")
    if root then
     current[other]=true
     local visual=hitboxVisuals[other]
     if not visual or not visual.Parent or visual.Adornee~=root then
      if visual then visual:Destroy() end
      visual=Instance.new("BoxHandleAdornment")
      visual.Name="OX1DE_VisualHitbox"
      visual.Adornee=root
      visual.AlwaysOnTop=true
      visual.ZIndex=2
      visual.Size=Vector3.new(8,8,8)
      visual.Color3=Color3.fromRGB(255,40,40)
      visual.Transparency=0.45
      visual.Parent=gui
      hitboxVisuals[other]=visual
     end
    end
   end
  end
  for other,visual in pairs(hitboxVisuals) do
   if not current[other] then
    visual:Destroy()
    hitboxVisuals[other]=nil
   end
  end
 end
 -- Movement-only push mode: a short self dash, not a server-side knockback
 if state.push and frameCounter%20==0 and player.Character then
  local root=player.Character:FindFirstChild("HumanoidRootPart")
  local hum=player.Character:FindFirstChildOfClass("Humanoid")
  local camera=workspace.CurrentCamera
  if root and hum and camera and hum.MoveDirection.Magnitude>0 then
   local d=hum.MoveDirection.Unit
   root.AssemblyLinearVelocity=Vector3.new(d.X*45,root.AssemblyLinearVelocity.Y,d.Z*45)
  end
 end
 if state.fly and flyVelocity and flyGyro then
  local camera=workspace.CurrentCamera
  if camera then
   local v=Vector3.new(0,0,0)
   if UIS:IsKeyDown(Enum.KeyCode.W) then v=v+camera.CFrame.LookVector end
   if UIS:IsKeyDown(Enum.KeyCode.S) then v=v-camera.CFrame.LookVector end
   if UIS:IsKeyDown(Enum.KeyCode.D) then v=v+camera.CFrame.RightVector end
   if UIS:IsKeyDown(Enum.KeyCode.A) then v=v-camera.CFrame.RightVector end
   if UIS:IsKeyDown(Enum.KeyCode.Space) then v=v+Vector3.new(0,1,0) end
   if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then v=v-Vector3.new(0,1,0) end
   flyVelocity.Velocity=v.Magnitude>0 and v.Unit*45 or Vector3.new(0,0,0)
   flyGyro.CFrame=camera.CFrame
  end
 end
end)
on(RS.RenderStepped,function()
 if state.esp then
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  for other,entry in pairs(labels) do
   local target=other.Character and other.Character:FindFirstChild("HumanoidRootPart")
   local studs=root and target and (root.Position-target.Position).Magnitude or math.huge
   local meters=math.floor(studs*.28+.5)
   local show=studs<math.huge and meters<=220
   entry.name.Enabled=show
   entry.distance.Enabled=show
   if show then entry.distText.Text=tostring(meters).." м" end
  end
 end
 if not state.aim or state.fov<=0 then return end
 local camera=workspace.CurrentCamera
 if not camera then return end
 local middle=Vector2.new(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
 local closest,best=nil,state.fov*3
 for _,other in ipairs(Players:GetPlayers()) do
  if other~=player and other.Character then
   local head=other.Character:FindFirstChild("Head")
   local hum=other.Character:FindFirstChildOfClass("Humanoid")
   if head and hum and hum.Health>0 then
    local p,visible=camera:WorldToViewportPoint(head.Position)
    if visible and p.Z>0 then
     local dist=(Vector2.new(p.X,p.Y)-middle).Magnitude
     if dist<best then best=dist; closest=head end
    end
   end
  end
 end
 if closest then camera.CFrame=CFrame.lookAt(camera.CFrame.Position,closest.Position) end
end)
_G.OX1DE_CLEANUP=function()
 pcall(stopFly)
 pcall(setNoclip,false)
 pcall(setHitboxes,false)
 state.push=false
 pcall(clearPlayerVisuals)
 for _,c in ipairs(connections) do pcall(function() c:Disconnect() end) end
 pcall(function() gui:Destroy() end)
 _G.OX1DE_CLEANUP=nil
end
on(closeBtn.MouseButton1Click,function() _G.OX1DE_CLEANUP() end)
protectedRefresh()
print("[OX1DE] v1.4: Russian/English language selector")
