-- OX1DE BloxStrike | Combined client diagnostics, camera aim and ESP
-- Original implementation. Does not alter server hit validation, recoil or spread.
local P=game:GetService("Players")
local R=game:GetService("RunService")
local U=game:GetService("UserInputService")
local W=workspace
local me=P.LocalPlayer
local cam=W.CurrentCamera
if type(_G.OX1DE_BS_STOP)=="function" then pcall(_G.OX1DE_BS_STOP) end
local on=true
local state={aim=false,esp=true,wall=false,team=false,los=true,fov=175,smooth=.2}
local connections={}
local visuals={}
local gui=Instance.new("ScreenGui")
gui.Name="OX1DE_BloxStrike_Combined"
gui.ResetOnSpawn=false
gui.DisplayOrder=10001
gui.Parent=me:WaitForChild("PlayerGui")
local function listen(sig,fn)
 local c=sig:Connect(fn); table.insert(connections,c);return c
end
local function mk(class,parent,props)
 local o=Instance.new(class)
 for k,v in pairs(props) do o[k]=v end
 o.Parent=parent
 return o
end
local panel=mk("Frame",gui,{Size=UDim2.fromOffset(270,300),Position=UDim2.fromOffset(25,145),BackgroundColor3=Color3.fromRGB(20,20,25),BorderSizePixel=0,Active=true,Draggable=true})
mk("UICorner",panel,{CornerRadius=UDim.new(0,10)})
mk("TextLabel",panel,{Text="OX1DE | BLOXSTRIKE",Font=Enum.Font.GothamBold,TextSize=17,TextColor3=Color3.new(1,1,1),Position=UDim2.fromOffset(10,8),Size=UDim2.fromOffset(250,26),BackgroundTransparency=1})
local buttons={}
local function button(k,caption,y)
 local b=mk("TextButton",panel,{Size=UDim2.fromOffset(246,32),Position=UDim2.fromOffset(12,y),Text="",TextSize=13,Font=Enum.Font.GothamSemibold,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(52,52,59)})
 mk("UICorner",b,{CornerRadius=UDim.new(0,6)})
 local function refresh()
  b.Text=caption..": "..(state[k] and "ON" or "OFF")
  b.BackgroundColor3=state[k] and Color3.fromRGB(35,106,68) or Color3.fromRGB(64,51,58)
 end
 listen(b.MouseButton1Click,function()state[k]=not state[k];refresh() end)
 refresh()
 buttons[k]=refresh
end
button("aim","CAMERA AIM [hold RMB]",42)
button("esp","PLAYER ESP",80)
button("wall","SHOW THROUGH WALLS",118)
button("los","AIM LINE OF SIGHT",156)
local info=mk("TextLabel",panel,{Position=UDim2.fromOffset(12,194),Size=UDim2.fromOffset(246,56),Text="Players: 0 | Visible: 0\nTarget: none",TextWrapped=true,Font=Enum.Font.Code,TextSize=13,TextColor3=Color3.fromRGB(220,220,225),TextXAlignment=Enum.TextXAlignment.Left,BackgroundTransparency=1})
local note=mk("TextLabel",panel,{Position=UDim2.fromOffset(12,252),Size=UDim2.fromOffset(246,40),Text="Camera aim + visual overlays only\nNo server hit / recoil modifications",TextWrapped=true,Font=Enum.Font.Gotham,TextSize=11,TextColor3=Color3.fromRGB(165,165,175),TextXAlignment=Enum.TextXAlignment.Left,BackgroundTransparency=1})
local function valid(plr)
 if plr==me then return end
 if state.team and me.Team and plr.Team==me.Team then return end
 local char=plr.Character; if not char then return end
 local hum=char:FindFirstChildOfClass("Humanoid")
 local head=char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
 if not hum or hum.Health<=0 or not head then return end
 return char,hum,head
end
local function visible(char,head)
 local ray=head.Position-cam.CFrame.Position
 if ray.Magnitude<.01 then return true end
 local param=RaycastParams.new()
 param.FilterType=Enum.RaycastFilterType.Exclude
 param.FilterDescendantsInstances=me.Character and {me.Character} or {}
 local h=W:Raycast(cam.CFrame.Position,ray,param)
 return not h or h.Instance:IsDescendantOf(char)
end
local function clearVisual(plr)
 local v=visuals[plr];if not v then return end
 if v.highlight then v.highlight:Destroy() end
 if v.billboard then v.billboard:Destroy() end
 if v.screenLabel then v.screenLabel:Destroy() end
 visuals[plr]=nil
end
local function ensureVisual(plr,char,head)
 local v=visuals[plr]
 if v and v.character~=char then clearVisual(plr);v=nil end
 if not v then
  local h=mk("Highlight",char,{Name="OX1DE_ESP_HIGHLIGHT",FillColor=Color3.fromRGB(245,65,65),OutlineColor=Color3.new(1,1,1),FillTransparency=.75,OutlineTransparency=.05,DepthMode=Enum.HighlightDepthMode.Occluded})
  local board=mk("BillboardGui",head,{Name="OX1DE_HP_TAG",Size=UDim2.fromOffset(150,46),StudsOffsetWorldSpace=Vector3.new(0,2.4,0),AlwaysOnTop=false,Adornee=head})
  local txt=mk("TextLabel",board,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,TextColor3=Color3.new(1,1,1),TextStrokeTransparency=.25,TextSize=12,Font=Enum.Font.GothamBold,Text=""})
  local tag=mk("TextLabel",gui,{
   Name="OX1DE_PLAYER_"..plr.UserId,AnchorPoint=Vector2.new(.5,1),
   Size=UDim2.fromOffset(210,43),BackgroundColor3=Color3.fromRGB(15,15,22),
   BackgroundTransparency=.4,BorderSizePixel=0,TextColor3=Color3.fromRGB(255,255,255),
   TextStrokeTransparency=.5,TextSize=12,Font=Enum.Font.GothamBold,
   Text="",Visible=false,ZIndex=5
  })
  mk("UICorner",tag,{CornerRadius=UDim.new(0,5)})
  v={character=char,highlight=h,billboard=board,text=txt,screenLabel=tag};visuals[plr]=v
 end
 return v
end
local held=false
listen(U.InputBegan,function(input,consumed)
 if input.UserInputType==Enum.UserInputType.MouseButton2 and not consumed then held=true end
end)
listen(U.InputEnded,function(input)
 if input.UserInputType==Enum.UserInputType.MouseButton2 then held=false end
end)
listen(P.PlayerRemoving,clearVisual)
local accumulator=0
listen(R.RenderStepped,function(dt)
 if not on then return end
 cam=W.CurrentCamera
 if not cam then return end
 accumulator+=dt
 if accumulator<.08 then return end
 accumulator=0
 local total,seen=0,0
 local chosen,bestScreen,bestDistance=nil,nil,state.fov
 for _,plr in ipairs(P:GetPlayers()) do
  local char,hum,head=valid(plr)
  if char then
   total+=1
   local canSee=visible(char,head)
   if canSee then seen+=1 end
   if state.esp then
    local v=ensureVisual(plr,char,head)
    v.highlight.Enabled=true
    v.highlight.DepthMode=state.wall and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    v.billboard.AlwaysOnTop=state.wall
    v.billboard.Enabled=true
    local root=me.Character and (me.Character:FindFirstChild("HumanoidRootPart") or me.Character:FindFirstChild("Head"))
    local distance=root and math.floor((head.Position-root.Position).Magnitude+.5) or -1
    local displayDistance=distance>=0 and (tostring(distance).." studs") or "? studs"
    v.text.Text=string.format("%s | HP %d/%d | %s",plr.DisplayName,math.ceil(hum.Health),math.ceil(hum.MaxHealth),displayDistance)
    local point,inView=cam:WorldToViewportPoint(head.Position)
    v.screenLabel.Visible=inView and point.Z>0
    if v.screenLabel.Visible then
     v.screenLabel.Position=UDim2.fromOffset(point.X,point.Y-33)
     v.screenLabel.Text=string.format("%s (@%s)\nHP %d/%d  |  %s",plr.DisplayName,plr.Name,math.ceil(hum.Health),math.ceil(hum.MaxHealth),displayDistance)
    end
   else clearVisual(plr) end
   if not state.los or canSee then
    local point,onScreen=cam:WorldToViewportPoint(head.Position)
    if onScreen and point.Z>0 then
     local center=cam.ViewportSize/2
     local d=(Vector2.new(point.X,point.Y)-center).Magnitude
     if d<bestDistance then
      chosen=head;bestScreen=plr.Name;bestDistance=d
     end
    end
   end
  else clearVisual(plr) end
 end
 info.Text=string.format("Players: %d | Visible: %d\nAim target: %s",total,seen,bestScreen or "none")
 if state.aim and held and chosen and chosen.Parent then
  local goal=CFrame.lookAt(cam.CFrame.Position,chosen.Position)
  cam.CFrame=cam.CFrame:Lerp(goal,state.smooth)
 end
end)
_G.OX1DE_BS_STOP=function()
 on=false
 for _,c in ipairs(connections) do pcall(function()c:Disconnect()end) end
 for plr,_ in pairs(visuals) do clearVisual(plr) end
 if gui then gui:Destroy()end
end
print("[OX1DE BloxStrike] Loaded: aim camera / ESP / HP diagnostic")
