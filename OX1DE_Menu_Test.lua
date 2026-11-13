-- OX1DE small menu smoke test 0.4.3 -- GUI ONLY
local Players=game:GetService("Players")
local player=Players.LocalPlayer
if not player then error("OX1DE: Players.LocalPlayer is nil") end
local holder
if type(gethui)=="function" then
 local ok,h=pcall(gethui)
 if ok and h then holder=h end
end
if not holder then holder=player:WaitForChild("PlayerGui",8) end
if not holder then error("OX1DE: no GUI container") end
local previous=holder:FindFirstChild("OX1DE_Menu_Test")
if previous then previous:Destroy() end
local gui=Instance.new("ScreenGui")
gui.Name="OX1DE_Menu_Test"
gui.IgnoreGuiInset=true
gui.DisplayOrder=999
gui.ResetOnSpawn=false
gui.Enabled=true
gui.Parent=holder
local function obj(class,parent,values)
 local o=Instance.new(class)
 for k,v in pairs(values) do o[k]=v end
 o.Parent=parent
 return o
end
local function round(o,n)
 obj("UICorner",o,{CornerRadius=UDim.new(0,n)})
end
local bg=Color3.fromRGB(14,11,23)
local panel=Color3.fromRGB(28,24,39)
local purp=Color3.fromRGB(140,74,219)
local white=Color3.fromRGB(245,244,255)
local muted=Color3.fromRGB(174,171,188)
local window=obj("Frame",gui,{
 AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
 Size=UDim2.fromOffset(810,510),BackgroundColor3=bg,BorderSizePixel=0,
 Visible=true
})
round(window,18)
obj("UIStroke",window,{Color=purp,Thickness=1.5,Transparency=.1})
local sc=obj("UIScale",window,{Scale=1})
local function fit()
 local cam=workspace.CurrentCamera
 if cam then
  local vp=cam.ViewportSize
  sc.Scale=math.max(.3,math.min(1,(vp.X-20)/810,(vp.Y-20)/510))
 end
end
fit()
local header=obj("Frame",window,{
 Size=UDim2.fromOffset(810,68),BackgroundColor3=panel,BorderSizePixel=0
})
round(header,18)
local function text(parent,value,x,y,w,h,size,color)
 return obj("TextLabel",parent,{
  Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),
  Text=tostring(value),TextColor3=color or white,TextSize=size or 15,
  Font=Enum.Font.GothamBold,BackgroundTransparency=1,
  TextXAlignment=Enum.TextXAlignment.Left
 })
end
local function button(parent,name,x,y,w,h,callback,active)
 local b=obj("TextButton",parent,{
  Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),
  Text=name,TextColor3=white,Font=Enum.Font.GothamBold,
  TextSize=15,BackgroundColor3=active and purp or panel,
  BorderSizePixel=0,AutoButtonColor=true
 })
 round(b,11)
 if callback then b.MouseButton1Click:Connect(callback) end
 return b
end
local box=obj("Frame",header,{
 Position=UDim2.fromOffset(12,9),Size=UDim2.fromOffset(51,51),
 BackgroundColor3=Color3.fromRGB(0,0,0),BorderSizePixel=0
})
round(box,9)
text(box,"OX",8,6,44,25,18)
text(box,"1DE",10,27,40,20,12)
text(header,"OX1DE",75,11,290,37,24)
text(header,"ТЕСТ МЕНЮ • без игровых функций",75,43,480,15,11,muted)
text(header,player.DisplayName,547,16,175,24,14)
button(header,"×",756,12,39,42,function()gui:Destroy()end)
local side=obj("Frame",window,{
 Position=UDim2.fromOffset(12,81),Size=UDim2.fromOffset(183,377),
 BackgroundColor3=panel,BorderSizePixel=0
})
round(side,12)
local content=obj("Frame",window,{
 Position=UDim2.fromOffset(207,81),Size=UDim2.fromOffset(590,377),
 BackgroundTransparency=1
})
local current="scripts"
local menuButtons={}
local render
render=function(view)
 current=view
 for key,b in pairs(menuButtons) do
  b.BackgroundColor3=key==view and purp or bg
 end
 for _,child in ipairs(content:GetChildren()) do child:Destroy() end
 if view=="scripts" then
  text(content,"Скрипты",7,0,570,40,25)
  text(content,"Выбери игровой профиль OX1DE",7,37,570,29,13,muted)
  for i,name in ipairs({"Район насилия","WARFARE"}) do
   local y=73+(i-1)*107
   local card=obj("Frame",content,{
    Position=UDim2.fromOffset(7,y),Size=UDim2.fromOffset(574,96),
    BackgroundColor3=panel,BorderSizePixel=0
   })
   round(card,12)
   text(card,name,18,11,340,31,20)
   text(card,"♛ PRIME",453,6,107,27,13,Color3.fromRGB(255,213,70))
   button(card,"ОТКРЫТЬ",380,50,177,35,function()
    render(i==1 and "district" or "warfare")
   end,true)
  end
 elseif view=="settings" then
  text(content,"Настройки",7,0,560,45,24)
  text(content,"Графика  |  Музыка  |  Язык",7,73,570,42,19)
  text(content,"Без изменения игры: проверяем запуск окна.",7,122,574,40,14,muted)
 elseif view=="history" then
  text(content,"История",7,0,570,43,24)
  text(content,"История будет подключена в полной версии.",7,75,570,36,14,muted)
 elseif view=="telegram" then
  text(content,"Telegram",7,0,570,43,24)
  text(content,"https://t.me/playox1de",7,75,570,36,18)
 elseif view=="exit" then
  text(content,"Закрыть тест OX1DE?",7,0,570,48,24)
  button(content,"ОТМЕНА",7,93,260,51,function()render("scripts")end)
  button(content,"ЗАКРЫТЬ",300,93,262,51,function()gui:Destroy()end,true)
 else
  text(content,view=="warfare" and "WARFARE" or "Район насилия",7,0,570,45,24)
  text(content,"Тестовое меню. AIM / ESP / Fly не подключены.",7,78,574,50,14,muted)
  button(content,"← Назад",7,145,225,46,function()render("scripts")end)
 end
end
for i,item in ipairs({
 {"scripts","≡  Скрипты"},{"history","◷  История"},
 {"settings","⚙  Настройки"},{"telegram","➤  Телеграм"},
 {"exit","⏻  Выход"}
}) do
 local id=item[1]
 menuButtons[id]=button(side,item[2],10,10+(i-1)*71,163,59,function()render(id)end,id=="scripts")
end
text(window,"OX1DE • тест запуска 0.4.3",20,467,390,27,12,muted)
text(window,"t.me/playox1de",622,467,172,27,12,muted)
render("scripts")
print("[OX1DE] Lightweight menu v0.4.3 successfully shown in "..holder:GetFullName())
