-- OX1DE BloxStrike Combined v3 SAFE
-- Lightweight client HUD; no hooks, no hidden-part scans.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local player=Players.LocalPlayer
if not player then return end
if type(_G.OX1DE_BS_STOP)=="function" then pcall(_G.OX1DE_BS_STOP) end
local running=true
local conns,labels={},{}
local cfg={esp=false,aim=false,range=750,maxLabels=12}
local gui=Instance.new("ScreenGui")
gui.Name="OX1DE_BloxStrike_SafeV3"
gui.ResetOnSpawn=false
gui.DisplayOrder=999
gui.Parent=player:WaitForChild("PlayerGui")
local function make(class,parent,properties)
 local obj=Instance.new(class)
 for k,v in pairs(properties) do obj[k]=v end
 obj.Parent=parent
 return obj
end
local function link(sig,fn)
 local c=sig:Connect(fn);conns[#conns+1]=c
end
local panel=make("Frame",gui,{Size=UDim2.fromOffset(250,166),Position=UDim2.fromOffset(20,145),BackgroundColor3=Color3.fromRGB(23,23,28),BorderSizePixel=0,Active=true,Draggable=true})
make("UICorner",panel,{CornerRadius=UDim.new(0,10)})
make("TextLabel",panel,{Size=UDim2.fromOffset(235,29),Position=UDim2.fromOffset(9,6),Text="OX1DE BLOXSTRIKE | SAFE v3",Font=Enum.Font.GothamBold,TextSize=14,TextColor3=Color3.new(1,1,1),BackgroundTransparency=1})
local function button(y,name,key)
 local b=make("TextButton",panel,{Size=UDim2.fromOffset(230,30),Position=UDim2.fromOffset(10,y),BackgroundColor3=Color3.fromRGB(62,46,48),TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamSemibold,TextSize=13})
 make("UICorner",b,{CornerRadius=UDim.new(0,6)})
 local function redraw()
  b.Text=name..": "..(cfg[key] and "ON" or "OFF")
  b.BackgroundColor3=cfg[key] and Color3.fromRGB(33,97,64) or Color3.fromRGB(62,46,48)
 end
 link(b.MouseButton1Click,function()cfg[key]=not cfg[key];redraw() end)
 redraw()
end
button(38,"NAMES + HP + DISTANCE","esp")
button(75,"CAMERA AIM [hold RMB]","aim")
local status=make("TextLabel",panel,{Position=UDim2.fromOffset(10,111),Size=UDim2.fromOffset(230,44),Text="Found: 0 | Labels: 0",Font=Enum.Font.Code,TextSize=12,TextColor3=Color3.fromRGB(210,210,220),TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,BackgroundTransparency=1})
local function remove(plr)
 local label=labels[plr]
 if label then label:Destroy();labels[plr]=nil end
end
local function ensure(plr)
 if labels[plr] then return labels[plr] end
 local label=make("TextLabel",gui,{Name="Label_"..plr.UserId,Size=UDim2.fromOffset(195,32),AnchorPoint=Vector2.new(.5,1),BackgroundColor3=Color3.fromRGB(21,21,26),BackgroundTransparency=.3,TextStrokeTransparency=.5,TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamSemibold,TextSize=11,Visible=false})
 make("UICorner",label,{CornerRadius=UDim.new(0,5)})
 labels[plr]=label
 return label
end
local held=false
link(UIS.InputBegan,function(input,processed)
 if not processed and input.UserInputType==Enum.UserInputType.MouseButton2 then held=true end
end)
link(UIS.InputEnded,function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton2 then held=false end
end)
link(Players.PlayerRemoving,remove)
local acc=0
link(RunService.Heartbeat,function(dt)
 if not running then return end
 acc+=dt
 if acc<.35 then return end
 acc=0
 local ok,err=pcall(function()
  local camera=workspace.CurrentCamera
  if not camera then return end
  local myChar=player.Character
  local myRoot=myChar and myChar:FindFirstChild("HumanoidRootPart")
  local found,shown=0,0
  local target,best=nil,130
  for _,plr in ipairs(Players:GetPlayers()) do
   if plr~=player then
    local ch=plr.Character
    local hum=ch and ch:FindFirstChildOfClass("Humanoid")
    local head=ch and (ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart"))
    local label=labels[plr]
    if hum and head and hum.Health>0 then
     found+=1
     local distance=myRoot and (head.Position-myRoot.Position).Magnitude or math.huge
     local screen,inView=camera:WorldToViewportPoint(head.Position)
     if cfg.esp and distance<=cfg.range and inView and screen.Z>0 and shown<cfg.maxLabels then
      label=ensure(plr)
      label.Visible=true
      label.Position=UDim2.fromOffset(screen.X,screen.Y-28)
      label.Text=string.format("%s | HP %d | %d studs",plr.DisplayName,math.ceil(hum.Health),math.floor(distance+.5))
      shown+=1
     elseif label then label.Visible=false end
     if cfg.aim and held and inView and screen.Z>0 then
      local d=(Vector2.new(screen.X,screen.Y)-camera.ViewportSize/2).Magnitude
      if d<best then best=d;target=head end
     end
    elseif label then label.Visible=false end
   end
  end
  if target and target.Parent then
   camera.CFrame=camera.CFrame:Lerp(CFrame.lookAt(camera.CFrame.Position,target.Position),.18)
  end
  status.Text=string.format("Found: %d | Labels: %d\nDisplay: %s",found,shown,cfg.esp and "ON" or "OFF")
 end)
 if not ok then status.Text="Diagnostic error: "..tostring(err):sub(1,52) end
end)
_G.OX1DE_BS_STOP=function()
 running=false
 for _,c in ipairs(conns) do pcall(function()c:Disconnect() end) end
 for plr in pairs(labels) do remove(plr) end
 gui:Destroy()
end
print("[OX1DE] BloxStrike Safe v3 loaded; overlay disabled by default")
