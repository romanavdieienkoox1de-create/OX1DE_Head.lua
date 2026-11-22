-- OX1DE Hub safe diagnostic UI. No character, camera or workspace modifications.
local Players=game:GetService("Players")
local player=Players.LocalPlayer
if not player then return end
local pg=player:WaitForChild("PlayerGui")
local old=pg:FindFirstChild("OX1DE_UI_DIAGNOSTIC")
if old then old:Destroy() end
local gui=Instance.new("ScreenGui")
gui.Name="OX1DE_UI_DIAGNOSTIC"
gui.ResetOnSpawn=false
gui.IgnoreGuiInset=true
gui.DisplayOrder=100
gui.Parent=pg
local panel=Instance.new("Frame")
panel.Name="CompactPanel"
panel.AnchorPoint=Vector2.new(0,.5)
panel.Position=UDim2.new(0,10,.5,0)
panel.Size=UDim2.fromOffset(310,466)
panel.BackgroundColor3=Color3.fromRGB(14,15,19)
panel.BorderSizePixel=0
panel.Parent=gui
local sc=Instance.new("UIScale")
sc.Scale=.23
sc.Parent=panel
local corner=Instance.new("UICorner")
corner.CornerRadius=UDim.new(0,15)
corner.Parent=panel
local title=Instance.new("TextLabel")
title.Text="OX1DE Hub  |  SAFE UI TEST"
title.Font=Enum.Font.GothamBold
title.TextSize=17
title.TextColor3=Color3.fromRGB(250,250,250)
title.BackgroundTransparency=1
title.Position=UDim2.fromOffset(14,12)
title.Size=UDim2.fromOffset(280,32)
title.TextXAlignment=Enum.TextXAlignment.Left
title.Parent=panel
local names={"ALL ESP","AIM","FOV","TEAM CHECK","NOCLIP","FLY"}
for i,name in ipairs(names) do
 local state=false
 local row=Instance.new("Frame")
 row.Position=UDim2.fromOffset(10,54+(i-1)*56)
 row.Size=UDim2.fromOffset(290,47)
 row.BackgroundColor3=Color3.fromRGB(29,31,36)
 row.BorderSizePixel=0
 row.Parent=panel
 local rc=Instance.new("UICorner");rc.CornerRadius=UDim.new(0,9);rc.Parent=row
 local dot=Instance.new("Frame")
 dot.Position=UDim2.fromOffset(11,17)
 dot.Size=UDim2.fromOffset(12,12)
 dot.BackgroundColor3=Color3.fromRGB(242,65,68)
 dot.BorderSizePixel=0
 dot.Parent=row
 local dc=Instance.new("UICorner");dc.CornerRadius=UDim.new(1,0);dc.Parent=dot
 local label=Instance.new("TextLabel")
 label.BackgroundTransparency=1
 label.Position=UDim2.fromOffset(34,4)
 label.Size=UDim2.fromOffset(184,39)
 label.Text=name
 label.TextColor3=Color3.fromRGB(245,245,245)
 label.TextXAlignment=Enum.TextXAlignment.Left
 label.Font=Enum.Font.GothamBold
 label.TextSize=14
 label.Parent=row
 local button=Instance.new("TextButton")
 button.Size=UDim2.fromOffset(48,29)
 button.Position=UDim2.fromOffset(230,9)
 button.Text="OFF"
 button.Font=Enum.Font.GothamBold
 button.TextSize=10
 button.TextColor3=Color3.fromRGB(245,245,245)
 button.BackgroundColor3=Color3.fromRGB(67,69,75)
 button.BorderSizePixel=0
 button.Parent=row
 local bc=Instance.new("UICorner");bc.CornerRadius=UDim.new(0,9);bc.Parent=button
 button.MouseButton1Click:Connect(function()
  state=not state
  button.Text=state and "ON" or "OFF"
  button.BackgroundColor3=state and Color3.fromRGB(42,155,98) or Color3.fromRGB(67,69,75)
  dot.BackgroundColor3=state and Color3.fromRGB(58,221,132) or Color3.fromRGB(242,65,68)
 end)
end
local note=Instance.new("TextLabel")
note.Position=UDim2.fromOffset(14,411)
note.Size=UDim2.fromOffset(280,30)
note.BackgroundTransparency=1
note.Text="DIAGNOSTIC ONLY - UI SWITCHES"
note.Font=Enum.Font.GothamBold
note.TextSize=11
note.TextColor3=Color3.fromRGB(165,170,180)
note.TextXAlignment=Enum.TextXAlignment.Left
note.Parent=panel
