-- OX1DE MENU TEST v0.4.2 -- GUI ONLY. No gameplay modifications.
-- Run this ALONE to test whether the new UI can open in your Roblox client.
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local TweenService=game:GetService("TweenService")
local player=Players.LocalPlayer
local parent=player:WaitForChild("PlayerGui",10)
if not parent then return warn("[OX1DE TEST] PlayerGui unavailable") end
local old=parent:FindFirstChild("OX1DE_Menu_Test")
if old then old:Destroy() end
local gui=Instance.new("ScreenGui")
gui.Name="OX1DE_Menu_Test"
gui.ResetOnSpawn=false
gui.IgnoreGuiInset=true
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.DisplayOrder=700
gui.Parent=parent
local color={
 bg=Color3.fromRGB(12,10,19),panel=Color3.fromRGB(23,21,33),
 card=Color3.fromRGB(33,30,46),purple=Color3.fromRGB(158,66,229),
 white=Color3.fromRGB(244,240,255),muted=Color3.fromRGB(161,156,177),
 yellow=Color3.fromRGB(255,220,54),red=Color3.fromRGB(244,76,95)
}
local function add(kind,parent,props)
 local obj=Instance.new(kind)
 for key,val in pairs(props or {}) do obj[key]=val end
 obj.Parent=parent
 return obj
end
local function round(p,r) add("UICorner",p,{CornerRadius=UDim.new(0,r or 12)}) end
local function outline(p,c)
 add("UIStroke",p,{Color=c or color.purple,Transparency=.25,Thickness=1.5})
end
local function label(p,str,x,y,w,h,size,bold,col)
 return add("TextLabel",p,{
  BackgroundTransparency=1,Position=UDim2.fromOffset(x,y),
  Size=UDim2.fromOffset(w,h),Text=str,TextColor3=col or color.white,
  Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,
  TextSize=size or 16,TextXAlignment=Enum.TextXAlignment.Left,
  TextTruncate=Enum.TextTruncate.AtEnd
 })
end
local function button(p,str,x,y,w,h,action,selected)
 local b=add("TextButton",p,{
  Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),Text=str,
  BackgroundColor3=selected and color.purple or color.card,
  TextColor3=color.white,Font=Enum.Font.GothamBold,TextSize=16,
  BorderSizePixel=0,AutoButtonColor=true
 })
 round(b,11)
 if action then b.MouseButton1Click:Connect(action) end
 return b
end
local root=add("Frame",gui,{
 AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
 Size=UDim2.fromOffset(930,570),BackgroundColor3=color.bg,BorderSizePixel=0
})
round(root,19);outline(root)
local scale=add("UIScale",root,{Scale=1})
local function fit()
 local cam=workspace.CurrentCamera
 if not cam then return end
 local view=cam.ViewportSize
 scale.Scale=math.clamp(math.min((view.X-20)/930,(view.Y-20)/570),.26,1)
end
fit()
local vpc
local function cameraChanged()
 if vpc then vpc:Disconnect() end
 if workspace.CurrentCamera then vpc=workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
 fit()
end
local cameraConnection=workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(cameraChanged)
cameraChanged()
local header=add("Frame",root,{
 Position=UDim2.fromOffset(0,0),Size=UDim2.fromOffset(930,85),
 BackgroundColor3=color.panel,BorderSizePixel=0
})
round(header,19)
local logo=add("Frame",header,{
 Position=UDim2.fromOffset(18,13),Size=UDim2.fromOffset(57,57),
 BackgroundColor3=Color3.fromRGB(0,0,0),BorderSizePixel=0
})
round(logo,10);outline(logo,Color3.fromRGB(255,255,255))
label(logo,"OX",5,5,52,26,22,true,color.white)
label(logo,"1DE",9,32,45,15,14,true,color.white)
label(header,"OX1DE",88,9,270,42,29,true)
label(header,"ТЕСТ НОВОГО МЕНЮ • БЕЗ ИГРОВЫХ ФУНКЦИЙ",89,49,430,20,11,false,color.muted)
label(header,player.DisplayName,627,18,161,26,17,true)
label(header,"@"..player.Name,627,46,165,18,11,false,color.muted)
local close=button(header,"×",865,20,45,44,function()gui:Destroy()end)
close.TextSize=25
local side=add("Frame",root,{
 Position=UDim2.fromOffset(13,98),Size=UDim2.fromOffset(206,411),
 BackgroundColor3=color.panel,BorderSizePixel=0
})
round(side,15)
local body=add("Frame",root,{
 Position=UDim2.fromOffset(233,102),Size=UDim2.fromOffset(684,406),
 BackgroundColor3=color.bg,BorderSizePixel=0
})
local nav={}
local refresh
local function show(selected)
 for key,b in pairs(nav) do b.BackgroundColor3=key==selected and color.purple or color.card end
 for _,o in ipairs(body:GetChildren()) do o:Destroy() end
 if selected=="scripts" then
  label(body,"Скрипты",12,7,630,40,26,true)
  label(body,"Выбери игру для просмотра",12,47,629,25,14,false,color.muted)
  for i,name in ipairs({"Район насилия","WARFARE"}) do
   local y=91+(i-1)*139
   local r=add("Frame",body,{
    Position=UDim2.fromOffset(9,y),Size=UDim2.fromOffset(656,127),
    BackgroundColor3=color.panel,BorderSizePixel=0
   })
   round(r,12);outline(r)
   label(r,name,18,17,430,40,23,true)
   label(r,"ТЕСТ МЕНЮ: игровые функции пока не подключены",18,54,505,30,12,false,color.muted)
   local tag=label(r,"♛ PRIME",533,9,120,29,14,true,color.yellow)
   button(r,"▶  Открыть",467,77,177,42,function()
    for _,o in ipairs(body:GetChildren()) do o:Destroy() end
    label(body,name,15,11,610,44,25,true)
    label(body,"Это облегчённый тест интерфейса. AIM, ESP и Fly не запускаются.",
     15,73,625,78,16,false,color.muted).TextWrapped=true
    button(body,"← Назад",15,193,212,51,function()show("scripts")end)
   end,true)
  end
  button(body,"⟳  Обновить",10,375,215,31,function()show("scripts")end)
 elseif selected=="settings" then
  label(body,"Настройки",11,7,610,44,27,true)
  label(body,"Графика",13,70,610,32,19,true)
  label(body,"Potato    |    Стандартная    |    Ультра",13,116,630,37,17,false)
  label(body,"Музыка",13,181,630,32,19,true)
  label(body,"Плеер будет подключён после проверки запуска меню.",13,230,640,45,15,false,color.muted)
  label(body,"Растяжение 4:3, 16:9 зависит от настроек Windows/Roblox.",13,309,650,46,14,false,color.red)
 elseif selected=="history" then
  label(body,"История",11,7,610,44,27,true)
  label(body,"Список игр появится после подключения основных функций.",13,89,648,59,15,false,color.muted)
 elseif selected=="telegram" then
  label(body,"Телеграм",11,7,610,44,27,true)
  label(body,"https://t.me/playox1de",13,90,600,50,19,true)
 else
  label(body,"Выход",11,7,610,44,27,true)
  label(body,"Вы точно хотите закрыть тестовое меню?",13,94,630,55,19,true)
  button(body,"Отмена",13,179,219,51,function()show("scripts")end)
  button(body,"Подтвердить",254,179,219,51,function()gui:Destroy()end,true)
 end
end
for i,item in ipairs({
 {"scripts","≡  Скрипты"},{"history","◷  История"},
 {"settings","⚙  Настройки"},{"telegram","➤  Телеграм"},
 {"exit","⏻  Выход"}
}) do
 local key=item[1]
 nav[key]=button(side,item[2],11,13+(i-1)*73,184,59,function()show(key)end,key=="scripts")
end
label(root,"OX1DE  •  SAFE UI TEST v0.4.2",23,528,410,25,12,true,color.muted)
label(root,"t.me/playox1de",737,528,172,25,12,true,color.muted)
show("scripts")
print("[OX1DE TEST] New lightweight menu launched successfully")
