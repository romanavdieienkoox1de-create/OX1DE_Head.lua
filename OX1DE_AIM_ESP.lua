-- OX1DE AIM/ESP v0.1
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local localPlayer=Players.LocalPlayer
if not localPlayer then return end
if _G.OX1DE_HEAD_CLEANUP then pcall(_G.OX1DE_HEAD_CLEANUP) end
local connections={}
local highlights={}
local aimOn=false
local espOn=false
local fov=50
local gui=Instance.new("ScreenGui")
gui.Name="OX1DE_Head_Menu"
gui.ResetOnSpawn=false
gui.Parent=localPlayer:WaitForChild("PlayerGui")
local function connect(signal,fn)
 local c=signal:Connect(fn)
 table.insert(connections,c)
 return c
end
local frame=Instance.new("Frame")
frame.Name="Window"
frame.Size=UDim2.fromOffset(260,180)
frame.Position=UDim2.new(0,30,0.35,0)
frame.BackgroundColor3=Color3.fromRGB(18,18,24)
frame.BorderSizePixel=0
frame.Active=true
frame.Draggable=true
frame.Parent=gui
Instance.new("UICorner",frame).CornerRadius=UDim.new(0,10)
local function makeButton(text,y)
 local b=Instance.new("TextButton")
 b.Text=text
 b.Font=Enum.Font.GothamSemibold
 b.TextSize=13
 b.TextColor3=Color3.fromRGB(255,255,255)
 b.Size=UDim2.new(1,-20,0,35)
 b.Position=UDim2.fromOffset(10,y)
 b.BackgroundColor3=Color3.fromRGB(50,50,60)
 b.Parent=frame
 Instance.new("UICorner",b).CornerRadius=UDim.new(0,7)
 return b
end
local aimBtn=makeButton("AIM [E]: OFF",10)
local espBtn=makeButton("ESP: OFF",52)
local fovBtn=makeButton("FOV: 50 / 100  (click to set)",104)
local closeBtn=makeButton("CLOSE",146)
closeBtn.Size=UDim2.new(1,-20,0,25)
local function refreshESP()
 for _,h in pairs(highlights) do h:Destroy() end
 table.clear(highlights)
 if not espOn then return end
 for _,p in ipairs(Players:GetPlayers()) do
  if p~=localPlayer and p.Character then
   local h=Instance.new("Highlight")
   h.Name="OX1DE_ESP"
   h.Adornee=p.Character
   h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
   h.FillColor=Color3.fromRGB(155,155,155)
   h.FillTransparency=0.45
   h.OutlineColor=Color3.fromRGB(255,255,255)
   h.Parent=gui
   highlights[p]=h
  end
 end
end
local function toggleAim()
 aimOn=not aimOn
 aimBtn.Text="AIM [E]: "..(aimOn and "ON" or "OFF")
end
connect(aimBtn.MouseButton1Click,toggleAim)
connect(espBtn.MouseButton1Click,function()
 espOn=not espOn
 espBtn.Text="ESP: "..(espOn and "ON" or "OFF")
 refreshESP()
end)
connect(fovBtn.MouseButton1Click,function()
 fov=(fov+10)%110
 fovBtn.Text="FOV: "..fov.." / 100  (click to set)"
end)
connect(UIS.InputBegan,function(input,processed)
 if not processed and input.KeyCode==Enum.KeyCode.E and not UIS:GetFocusedTextBox() then toggleAim() end
end)
connect(Players.PlayerAdded,function(p)
 connect(p.CharacterAdded,function() task.defer(refreshESP) end)
end)
for _,p in ipairs(Players:GetPlayers()) do
 if p~=localPlayer then connect(p.CharacterAdded,function() task.defer(refreshESP) end) end
end
connect(Players.PlayerRemoving,function(p)
 if highlights[p] then highlights[p]:Destroy(); highlights[p]=nil end
end)
connect(RunService.RenderStepped,function()
 if not aimOn or fov==0 then return end
 local camera=workspace.CurrentCamera
 if not camera then return end
 local middle=Vector2.new(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
 local closest,dist=nil,fov*3
 for _,p in ipairs(Players:GetPlayers()) do
  if p~=localPlayer and p.Character then
   local humanoid=p.Character:FindFirstChildOfClass("Humanoid")
   local head=p.Character:FindFirstChild("Head")
   if head and humanoid and humanoid.Health>0 then
    local pos,visible=camera:WorldToViewportPoint(head.Position)
    if visible and pos.Z>0 then
     local d=(Vector2.new(pos.X,pos.Y)-middle).Magnitude
     if d<dist then closest=head;dist=d end
    end
   end
  end
 end
 if closest then
  camera.CFrame=CFrame.lookAt(camera.CFrame.Position,closest.Position)
 end
end)
_G.OX1DE_HEAD_CLEANUP=function()
 for _,c in ipairs(connections) do pcall(function() c:Disconnect() end) end
 for _,h in pairs(highlights) do pcall(function() h:Destroy() end) end
 pcall(function() gui:Destroy() end)
 _G.OX1DE_HEAD_CLEANUP=nil
end
connect(closeBtn.MouseButton1Click,function() _G.OX1DE_HEAD_CLEANUP() end)
