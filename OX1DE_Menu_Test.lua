-- OX1DE UI v0.4.4 • FULL DESIGN PREVIEW, NO GAMEPLAY MODIFICATIONS
-- Isolated launcher for design approval. AIM/ESP/Fly are not activated.
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local SoundService=game:GetService("SoundService")
local Lighting=game:GetService("Lighting")
local RunService=game:GetService("RunService")
local p=Players.LocalPlayer
if not p then error("OX1DE: LocalPlayer unavailable") end
local holder
if type(gethui)=="function" then
 local ok,where=pcall(gethui)
 if ok and where then holder=where end
end
if not holder then holder=p:WaitForChild("PlayerGui",8) end
if not holder then error("OX1DE: PlayerGui unavailable") end
local existing=holder:FindFirstChild("OX1DE_Menu_Test")
if existing then existing:Destroy() end
local gui=Instance.new("ScreenGui")
gui.Name="OX1DE_Menu_Test"
gui.ResetOnSpawn=false;gui.IgnoreGuiInset=true
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.DisplayOrder=950;gui.Parent=holder
local C={
 bg=Color3.fromRGB(12,10,20),head=Color3.fromRGB(18,16,29),
 panel=Color3.fromRGB(22,20,33),card=Color3.fromRGB(32,29,47),
 alt=Color3.fromRGB(41,35,56),purple=Color3.fromRGB(147,68,223),
 bright=Color3.fromRGB(185,114,255),text=Color3.fromRGB(246,243,255),
 sub=Color3.fromRGB(170,163,185),yellow=Color3.fromRGB(255,220,73),
 red=Color3.fromRGB(239,78,98),green=Color3.fromRGB(106,224,142)}
local function mk(kind,parent,t)
 local x=Instance.new(kind)
 for k,v in pairs(t or {}) do x[k]=v end
 x.Parent=parent;return x
end
local function rounded(x,n) mk("UICorner",x,{CornerRadius=UDim.new(0,n or 10)}) end
local function stroke(x,color,alpha,n)
 mk("UIStroke",x,{Color=color or C.purple,Transparency=alpha or 0,Thickness=n or 1})
end
local function block(parent,x,y,w,h,color,r,z)
 local f=mk("Frame",parent,{
  Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),
  BorderSizePixel=0,BackgroundColor3=color or C.panel,ZIndex=z or 3})
 if r then rounded(f,r) end
 return f
end
local function label(parent,value,x,y,w,h,size,bold,color,center,z)
 return mk("TextLabel",parent,{
  Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),
  Text=tostring(value),BackgroundTransparency=1,
  TextColor3=color or C.text,Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,
  TextSize=size or 14,TextXAlignment=center and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
  TextYAlignment=Enum.TextYAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd,
  ZIndex=z or 7})
end
local function button(parent,txt,x,y,w,h,onClick,active,z)
 local b=mk("TextButton",parent,{
  Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),
  BackgroundColor3=active and C.purple or C.card,BorderSizePixel=0,
  Text=tostring(txt),TextColor3=C.text,TextSize=14,Font=Enum.Font.GothamBold,
  AutoButtonColor=true,ZIndex=z or 8})
 rounded(b,10)
 if onClick then b.MouseButton1Click:Connect(onClick) end
 return b
end
local alive=true
local device=UIS.TouchEnabled and not UIS.KeyboardEnabled and "mobile" or "pc"
local current="scripts"
local selectedGame=nil
local tab="main"
local settingsTab="graphics"
local chosenQuality="standard"
local aspect="16:9"
local language="ru"
local previousGame=nil
local history={}
-- Licensed Roblox library samples. Actual playback depends on audio permissions.
local tracks={
 {id="1837849285",name="Upbeat Electronica",genre="Electronic"},
 {id="1848183670",name="Grandiose Fantasy",genre="Cinematic"},
 {id="1843463175",name="Creepy Organ / Dungeon",genre="Atmosphere"},
 {id="1837848642",name="Crystal Clear",genre="Electronic"},
 {id="1836842889",name="Solar Flares",genre="Electronic"},
 {id="1847853099",name="Robotic Dance C",genre="Dance"},
 {id="1841647093",name="Life in an Elevator",genre="Lounge"},
 {id="1848354536",name="Relaxed Scene",genre="Ambient"}
}
local songIndex=1
local musicEnabled=false
local volume=65
local musicMessage=""
local activeFX={}
local graphicsMessage="Выбери профиль графики"
local originalShadows=Lighting.GlobalShadows
local originalQuality=nil
pcall(function()originalQuality=UserSettings():GetService("UserGameSettings").SavedQualityLevel end)
local function clearFX()
 for _,effect in ipairs(activeFX) do pcall(function()effect:Destroy()end) end
 table.clear(activeFX)
end
local function changeGraphics(preset)
 clearFX()
 chosenQuality=preset
 local requested=({potato=1,standard=5,ultra=10})[preset]
 local qualityOk=false
 if requested then
  local attempted=pcall(function()
   UserSettings():GetService("UserGameSettings").SavedQualityLevel=
    Enum.SavedQualitySetting["QualityLevel"..requested]
  end)
  if attempted then
   qualityOk=pcall(function()
    local current=UserSettings():GetService("UserGameSettings").SavedQualityLevel
    assert(current==Enum.SavedQualitySetting["QualityLevel"..requested])
   end)
  end
 end
 local settingsOK=pcall(function()
  settings().Rendering.QualityLevel=({potato=Enum.QualityLevel.Level01,
   standard=Enum.QualityLevel.Level05,ultra=Enum.QualityLevel.Level10})[preset]
 end)
 local lightingChanged=pcall(function()
  Lighting.GlobalShadows=preset=="potato" and false or originalShadows
 end)
 if preset=="ultra" then
  pcall(function()
   local correction=Instance.new("ColorCorrectionEffect")
   correction.Name="OX1DE_Preview_Colors"
   correction.Contrast=.16
   correction.Saturation=.17
   correction.Brightness=.015
   correction.Parent=Lighting
   table.insert(activeFX,correction)
   local bloom=Instance.new("BloomEffect")
   bloom.Name="OX1DE_Preview_Bloom"
   bloom.Intensity=.18
   bloom.Size=18
   bloom.Threshold=1.5
   bloom.Parent=Lighting
   table.insert(activeFX,bloom)
  end)
 elseif preset=="potato" then
  pcall(function()
   local correction=Instance.new("ColorCorrectionEffect")
   correction.Name="OX1DE_Preview_LowColor"
   correction.Saturation=-.12
   correction.Parent=Lighting
   table.insert(activeFX,correction)
  end)
 end
 local visual=#activeFX>0 or lightingChanged
 if qualityOk or settingsOK then
  graphicsMessage="Уровень качества запрошен; эффекты применены локально"
 elseif visual then
  graphicsMessage="Локальные эффекты применены; Roblox запретил уровень качества"
 else
  graphicsMessage="Roblox не разрешил изменение. Меняй качество через Esc → Настройки"
 end
end
local music=mk("Sound",SoundService,{
 Name="OX1DE_LocalMusicPreview",Volume=.65,Looped=false})
local function T(ru,en) return language=="en" and en or ru end
local function nameFor(id)
 if id=="warfare" then return "WARFARE" end
 return T("Район насилия","Violence District")
end
local win=block(gui,0,0,1000,620,C.bg,22,2)
win.Name="OX1DE_MainMenu"
win.AnchorPoint=Vector2.new(.5,.5)
win.Position=UDim2.fromScale(.5,.5)
stroke(win,C.purple,.12,1.5)
local screenScale=mk("UIScale",win,{Scale=1})
local cameraConn=nil
local function fit()
 local camera=workspace.CurrentCamera
 if camera then
  local vp=camera.ViewportSize
  screenScale.Scale=math.max(.22,math.min(1,(vp.X-18)/1000,(vp.Y-18)/620))
 end
end
local function cameraUpdated()
 if cameraConn then cameraConn:Disconnect();cameraConn=nil end
 local camera=workspace.CurrentCamera
 if camera then cameraConn=camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
 fit()
end
local cameraChangeConn=workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(cameraUpdated)
cameraUpdated()
local head=block(win,0,0,1000,74,C.head,20,3)
block(head,0,60,1000,14,C.head,nil,3)
block(head,16,73,968,1,C.alt,nil,5)
local logo=block(head,14,10,54,53,Color3.fromRGB(0,0,0),10,6)
stroke(logo,C.text,.35,1)
label(logo,"OX",2,4,50,27,22,true,C.text,true,8)
label(logo,"1DE",3,30,49,17,13,true,C.text,true,8)
label(head,"OX1DE",81,8,320,35,27,true)
label(head,"SCRIPT MENU",83,43,290,17,10,true,C.sub)
local account=label(head,p.DisplayName,678,10,190,27,14,true)
local username=label(head,"@"..p.Name,678,38,194,20,11,false,C.sub)
local crown=label(head,"♛",643,16,29,30,19,true,C.yellow)
local prime=button(head,"PRIME",868,18,68,39,nil,false)
prime.BackgroundColor3=Color3.fromRGB(66,48,27);prime.TextColor3=C.yellow
stroke(prime,C.yellow,.35,.8)
local show
local restore=button(head,"−",941,18,24,39,nil,false)
local hide=button(head,"×",970,18,25,39,nil,false)
restore.TextSize=20;hide.TextSize=22
local side=block(win,12,87,208,475,C.head,15,3)
local content=mk("ScrollingFrame",win,{
 Position=UDim2.fromOffset(235,94),Size=UDim2.fromOffset(754,466),
 BackgroundTransparency=1,ScrollBarThickness=4,ScrollBarImageColor3=C.purple,
 BorderSizePixel=0,CanvasSize=UDim2.fromOffset(0,463),
 ScrollingDirection=Enum.ScrollingDirection.Y,ZIndex=4})
block(win,19,571,960,1,C.alt,nil,4)
label(win,"OX1DE   •   UI TEST v0.4.4",24,578,358,27,12,true,C.sub)
local telegramFooter=button(win,"➤  t.me/playox1de",757,576,218,35,nil,false)
telegramFooter.TextSize=12
local nav={}
local navSpec={
 {"scripts","≡",T("Скрипты","Scripts")},
 {"history","◷",T("История","History")},
 {"settings","⚙",T("Настройки","Settings")},
 {"telegram","➤","Telegram"}
}
local navFunction
for i,item in ipairs(navSpec) do
 local id=item[1]
 nav[id]=button(side,item[2].."   "..item[3],12,12+(i-1)*62,184,49,function()show(id)end)
end
block(side,13,379,182,1,C.alt,nil,4)
local leave=button(side,"⏻  "..T("Выход","Exit"),12,397,184,55,function()show("exit")end)
local balloon=button(gui,"OX",0,0,52,52,nil,true,45)
balloon.BackgroundColor3=C.bg
balloon.Position=UDim2.new(1,-68,.42,0)
stroke(balloon,C.purple,.05,1.4);rounded(balloon,26)
balloon.Visible=false
local function setVisible(open)
 if not alive then return end
 if not open and current=="settings" and previousGame then
  current="game"
 end
 win.Visible=open;balloon.Visible=not open
end
restore.MouseButton1Click:Connect(function()setVisible(false)end)
hide.MouseButton1Click:Connect(function()setVisible(false)end)
local bubbleDragged=false
balloon.MouseButton1Click:Connect(function()
 if bubbleDragged then bubbleDragged=false;return end
 setVisible(true);show(current)
end)
telegramFooter.MouseButton1Click:Connect(function()show("telegram")end)
local closeConfirm=block(win,0,0,1000,620,Color3.fromRGB(10,8,18),nil,35)
closeConfirm.BackgroundTransparency=.07
closeConfirm.Visible=false
local confirmCard=block(closeConfirm,253,173,495,257,C.panel,17,36)
stroke(confirmCard,C.purple,.10,1.3)
label(confirmCard,T("Выйти из OX1DE?","Exit OX1DE?"),24,16,451,44,25,true,C.text,false,38)
local exitNotice=label(confirmCard,T("Меню полностью отключится до повторного запуска.",
 "The menu will close until you run it again."),24,74,444,78,15,false,C.sub,false,38)
exitNotice.TextWrapped=true
local function shutdown()
 if not alive then return end
 alive=false
 music:Stop();music:Destroy()
 if cameraConn then cameraConn:Disconnect() end
 if cameraChangeConn then cameraChangeConn:Disconnect() end
 gui:Destroy()
end
button(confirmCard,T("Отмена","Cancel"),20,177,211,52,function()
 closeConfirm.Visible=false;show(selectedGame and "game" or "scripts")
end,false,39)
button(confirmCard,T("Подтвердить","Confirm"),260,177,210,52,shutdown,true,39)
local title=label(win,"",244,95,727,39,25,true)
local subtitle=label(win,"",244,136,728,24,12,false,C.sub)
local function heading(a,b)
 title.Text=a;subtitle.Text=b or ""
end
local function clearContent()
 for _,child in ipairs(content:GetChildren()) do child:Destroy() end
 content.CanvasPosition=Vector2.new(0,0)
 content.CanvasSize=UDim2.fromOffset(0,463)
end
local function rowNotice(txt,x,y,w,h)
 local notice=block(content,x,y,w,h,C.panel,12,6)
 local l=label(notice,txt,13,6,w-26,h-12,13,false,C.sub,false,8)
 l.TextWrapped=true
 return notice
end
local function onlyPreview(y)
 return rowNotice(T("Демонстрация оформления. Игровые функции пока отключены — проверяем стабильность нового меню.",
 "Visual preview. Game functions are disabled until the UI is stable."),4,y,734,59)
end
local function demoToggle(k,txt,desc,y,value)
 local row=block(content,4,y,734,64,C.panel,12,6)
 label(row,txt,15,7,570,28,16,true)
 label(row,desc,15,35,580,20,11,false,C.sub)
 local toggle=button(row,value and T("ВКЛ","ON") or "OFF",620,12,100,39,nil,value,8)
 toggle.TextColor3=C.sub
 toggle.BackgroundColor3=C.alt
 toggle.AutoButtonColor=false
 return row
end
local function valueRow(titleText,value,y)
 local row=block(content,4,y,734,56,C.panel,11,6)
 label(row,titleText,15,5,440,45,15,true)
 label(row,tostring(value),490,5,225,45,15,true,C.purple)
 return row
end
local function panelTab(txt,x,active,callback)
 return button(content,txt,x,4,178,46,callback,active,8)
end
local loadLayer=block(win,0,0,1000,620,C.bg,20,42)
loadLayer.Visible=false
label(loadLayer,"OX1DE",0,161,1000,68,47,true,C.text,true,44)
local loadTitle=label(loadLayer,"",190,268,621,35,18,true,C.text,true,44)
local loadBar=block(loadLayer,213,341,574,18,C.card,9,44)
local loadFill=block(loadBar,0,0,0,18,C.purple,9,45)
local loadPct=label(loadLayer,"",204,377,594,34,18,true,C.text,true,44)
local function launchGame(id)
 selectedGame=id;previousGame=id;tab="main"
 loadTitle.Text=T("Проверка интерфейса...","Checking interface...")
 loadFill.Size=UDim2.fromOffset(0,18);loadPct.Text="0%"
 loadLayer.Visible=true
 task.spawn(function()
  for i,pct in ipairs({20,45,75,100}) do
   if not alive then return end
   loadTitle.Text=i==1 and T("Подготовка окна","Preparing window")
      or i==2 and T("Проверка профиля","Checking profile")
      or i==3 and T("Открытие разделов","Opening sections")
      or T("Интерфейс готов","Interface ready")
   loadFill.Size=UDim2.fromOffset(math.floor(574*pct/100),18)
   loadPct.Text=tostring(pct).."%"
   RunService.Heartbeat:Wait()
  end
  if not alive then return end
  table.insert(history,1,{name=nameFor(id),time=os.date("%d.%m.%Y %H:%M")})
  if #history>12 then table.remove(history,13) end
  loadLayer.Visible=false
  show("game")
 end)
end
local function renderScripts()
 heading(T("Скрипты","Scripts"),T("Выбери профиль, чтобы открыть его меню","Select a game profile"))
 local cards={}
 for i,id in ipairs({"violence_district","warfare"}) do
  local y=9+(i-1)*173
  local r=block(content,4,y,729,158,C.panel,14,6)
  stroke(r,C.purple,.52,1)
  cards[id]=r
  local visual=block(r,13,13,123,131,Color3.fromRGB(13,9,26),12,7)
  label(visual,id=="warfare" and "W" or "OX1DE",3,33,116,63,
    id=="warfare" and 54 or 23,true,C.text,true,9)
  label(r,nameFor(id),153,18,406,39,24,true)
  label(r,T("Профиль игры OX1DE","OX1DE game profile"),153,58,388,25,13,false,C.sub)
  local primeTag=button(r,"♛ PRIME",599,13,116,36,nil,false,9)
  primeTag.TextColor3=C.yellow
  primeTag.BackgroundColor3=Color3.fromRGB(62,45,25)
  stroke(primeTag,C.yellow,.45,.8)
  button(r,T("▶  Открыть","▶  Open"),483,96,231,47,function()launchGame(id)end,true,9)
 end
 local search=mk("TextBox",content,{
  Position=UDim2.fromOffset(4,363),Size=UDim2.fromOffset(480,47),
  BackgroundColor3=C.card,BorderSizePixel=0,
  PlaceholderColor3=C.sub,PlaceholderText=T("Найти игру...","Find a game..."),
  ClearTextOnFocus=false,Text="",TextSize=15,TextColor3=C.text,
  Font=Enum.Font.Gotham, ZIndex=8})
 rounded(search,10)
 local function filter(q)
  q=q:lower()
  for id,r in pairs(cards) do
   r.Visible=q=="" or nameFor(id):lower():find(q,1,true)~=nil or id:find(q,1,true)~=nil
  end
 end
 search:GetPropertyChangedSignal("Text"):Connect(function()filter(search.Text)end)
 button(content,T("⟳  Обновить","⟳  Refresh"),498,363,235,47,function()
  search.Text="";filter("")
 end,false)
end
local function renderHistory()
 heading(T("История","History"),T("Недавно открытые игровые профили","Recently opened game profiles"))
 if #history==0 then rowNotice(T("История пока пустая.","No launch history yet."),4,18,730,83)end
 for i,item in ipairs(history) do
  local y=7+(i-1)*67
  local row=block(content,4,y,732,59,C.panel,11,6)
  label(row,item.name,18,8,485,40,17,true)
  label(row,item.time,503,8,216,40,12,false,C.sub)
 end
 content.CanvasSize=UDim2.fromOffset(0,math.max(463,75+#history*67))
end
local function renderGame()
 heading("OX1DE  •  "..nameFor(selectedGame),T("Меню функций игры","Game features menu"))
 for i,item in ipairs({
  {"main",T("Главное","Main")},{"aim","AIM"},{"esp","ESP"},{"other",T("Прочее","Other")}
 }) do
  panelTab(item[2],4+(i-1)*184,tab==item[1],function()tab=item[1];show("game")end)
 end
 local y=67
 if selectedGame=="warfare" then
  if tab=="main" then
   demoToggle("warFly","Fly","WASD / Space / Ctrl",y,false);y+=71
   demoToggle("warNoClip","NoClip",T("Проход через объекты","Pass through objects"),y,false);y+=71
   demoToggle("warAimPreview","AIM",T("Наведение камеры","Camera aiming"),y,false);y+=71
  elseif tab=="aim" then
   for _,row in ipairs({{"AIM",false},{"FOV",true},{"Wall Check",true},{"Team Check",true},{"Удержание AIM",true}}) do
    demoToggle("aim",row[1],T("Параметр наведения","Aiming option"),y,row[2]);y+=71
   end
   valueRow("FOV","160 px",y);y+=63
   valueRow(T("Дальность","Range"),"50 м",y);y+=63
  elseif tab=="esp" then
   for _,r in ipairs({"Союзники","Противники","Никнеймы","Оружие","FPV-дроны","HP игроков"}) do
    demoToggle("esp",r,T("Подсветка в игре","In-game highlight"),y,false);y+=71
   end
  else
   demoToggle("warFly","Fly","WASD",y,false);y+=71
   demoToggle("warNoClip","NoClip","WASD",y,false);y+=71
  end
 else
  if tab=="esp" then
   for _,r in ipairs({"Игроки","Убийца","Генераторы","Тыквы","Паллеты"}) do
    demoToggle("esp",r,T("Подсветка объектов","Object ESP"),y,false);y+=71
   end
  elseif tab=="aim" then
   rowNotice(T("Для «Района насилия» в текущем скрипте нет AIM.",
       "The Violence District script currently has no AIM."),4,y,734,82);y+=91
  else
   for _,r in ipairs({"Fly","NoClip",T("Автопроверка навыка","Auto Skill Check")}) do
    demoToggle("main",r,T("Игровая функция","Game feature"),y,false);y+=71
   end
  end
 end
 onlyPreview(y+9)
 button(content,T("←  Вернуться к играм","←  Back to games"),4,y+77,335,47,function()show("scripts")end,false)
 content.CanvasSize=UDim2.fromOffset(0,math.max(464,y+137))
end
local function renderQuality()
 label(content,T("Качество графики","Graphics quality"),10,75,630,33,19,true)
 for i,entry in ipairs({{"potato","POTATO"},{"standard",T("Стандартная","Standard")},{"ultra",T("Ультра","Ultra")}}) do
  local id,name=entry[1],entry[2]
  local b=button(content,name,4+(i-1)*247,118,238,73,function()
   chosenQuality=id;show("settings")
  end,chosenQuality==id)
  if chosenQuality~=id then b.BackgroundColor3=C.panel end
 end
 label(content,T("Формат экрана • предварительный выбор","Display format • preview"),
  10,211,716,33,17,true)
 for i,opt in ipairs({"4:3","16:9","16:10","5:4","5:3","3:2","3:4"}) do
  local b=button(content,opt,4+(i-1)*104,259,96,43,function()
   aspect=opt;show("settings")
  end,aspect==opt)
  if aspect~=opt then b.BackgroundColor3=C.panel end
 end
 local warn=block(content,4,327,734,104,Color3.fromRGB(54,24,37),12,6)
 local top=label(warn,T("ВНИМАНИЕ • Из Roblox Lua нельзя растянуть всю игру.",
  "WARNING • Roblox Lua cannot stretch the entire game."),13,7,700,42,15,true,C.red)
 top.TextWrapped=true
 local bottom=label(warn,T("На ПК меняй формат в Windows или драйвере. На телефоне смена разрешения недоступна.",
  "Change aspect ratio through Windows or graphics drivers; not available on mobile."),
  13,52,702,45,13,false,C.text)
 bottom.TextWrapped=true
end
local function startTrack(i)
 local row=tracks[i]
 if not row then return end
 songIndex=i
 musicEnabled=true
 music:Stop();music.SoundId="rbxassetid://"..row.id
 music.Volume=volume/100
 pcall(function()music:Play()end)
end
music.Ended:Connect(function()
 if musicEnabled and alive and #tracks>0 then
  startTrack(songIndex%#tracks+1)
 end
end)
local function renderMusic()
 label(content,T("Музыкальный плеер","Music player"),9,70,485,35,20,true)
 local active=button(content,musicEnabled and T("■  Стоп","■  Stop") or T("▶  Включить","▶  Play"),
  537,70,195,45,function()
   if musicEnabled then musicEnabled=false;music:Stop()
   else startTrack(songIndex) end
   show("settings")
  end,musicEnabled)
 label(content,T("Громкость музыки","Music volume"),9,130,580,35,17,true)
 local volText=label(content,tostring(volume).."%",602,129,127,35,16,true,C.yellow)
 local volTrack=block(content,12,184,716,10,C.alt,5,7)
 local volFill=block(volTrack,0,0,volume*7.16,10,C.purple,5,8)
 local knob=block(volTrack,volume*7.16-9,-5,19,19,C.text,10,9)
 local moving=false
 local function updateVolume(x)
  local t=math.clamp((x-volTrack.AbsolutePosition.X)/math.max(1,volTrack.AbsoluteSize.X),0,1)
  volume=math.floor(t*100+.5)
  volText.Text=volume.."%"
  volFill.Size=UDim2.new(volume/100,0,1,0)
  knob.Position=UDim2.new(volume/100,-9,0,-5)
  music.Volume=volume/100
 end
 volTrack.InputBegan:Connect(function(input)
  if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
   moving=true;updateVolume(input.Position.X)
  end
 end)
 volTrack.InputEnded:Connect(function()moving=false end)
 local c1=UIS.InputChanged:Connect(function(input)
  if moving and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
   updateVolume(input.Position.X)
  end
 end)
 -- Disconnect global handlers when this page is destroyed.
 volTrack.Destroying:Connect(function()c1:Disconnect()end)
 label(content,T("Добавить трек Roblox Audio ID","Add Roblox Audio ID"),10,215,720,31,15,true)
 local field=mk("TextBox",content,{
  Position=UDim2.fromOffset(4,255),Size=UDim2.fromOffset(490,46),
  Text="",PlaceholderText=T("Числовой Audio ID","Numeric Audio ID"),
  TextColor3=C.text,PlaceholderColor3=C.sub,TextSize=14,Font=Enum.Font.Gotham,
  ClearTextOnFocus=false,BackgroundColor3=C.panel,BorderSizePixel=0,ZIndex=8})
 rounded(field,10)
 local status=label(content,"",10,305,718,30,12,false,C.red)
 button(content,T("+ Добавить","+ Add"),506,255,226,46,function()
  local id=field.Text:gsub("%D","")
  if #id<6 then
   status.Text=T("Укажи числовой Roblox Audio ID.","Enter a numeric Roblox Audio ID.")
   return
  end
  tracks[#tracks+1]={id=id,name="Audio "..id}
  show("settings")
 end,true)
 label(content,T("Плейлист","Playlist"),9,351,570,28,17,true)
 for i,track in ipairs(tracks) do
  local y=388+(i-1)*61
  local row=block(content,4,y,732,54,C.panel,10,6)
  label(row,track.name,12,4,470,45,14,true)
  button(row,"▶",504,7,93,39,function()startTrack(i);show("settings")end,i==songIndex and musicEnabled)
  button(row,"×",608,7,113,39,function()
   if i==songIndex then music:Stop();musicEnabled=false end
   table.remove(tracks,i)
   songIndex=math.max(1,math.min(songIndex,#tracks))
   show("settings")
  end,false)
 end
 local info=label(content,T("Музыка звучит только у тебя. Права на аудио проверяет Roblox; поиск любых песен Google недоступен.",
 "Audio is local. Roblox controls audio permissions; Google-wide song search is unavailable."),
  10,397+#tracks*61,718,75,12,false,C.sub)
 info.TextWrapped=true
 content.CanvasSize=UDim2.fromOffset(0,math.max(465,489+#tracks*61))
end
local function renderLanguage()
 label(content,T("Язык интерфейса","Interface language"),10,84,697,42,21,true)
 button(content,"Русский",4,155,353,68,function()
  language="ru";show("settings")
 end,language=="ru")
 button(content,"English",383,155,355,68,function()
  language="en";show("settings")
 end,language=="en")
 label(content,T("Выбор меняет основные надписи меню.","This changes the main menu labels."),
  10,252,720,42,14,false,C.sub)
end
local function renderSettings()
 heading(T("Настройки","Settings"),T("Графика, музыка, язык","Graphics, music and language"))
 for i,item in ipairs({{"graphics",T("Графика","Graphics")},
  {"music",T("Музыка","Music")},{"language",T("Язык","Language")}}) do
  local id=item[1]
  panelTab(item[2],4+(i-1)*247,settingsTab==id,function()
   settingsTab=id;show("settings")
  end)
 end
 if settingsTab=="graphics" then renderQuality()
 elseif settingsTab=="music" then renderMusic()
 else renderLanguage() end
end
local function renderTelegram()
 heading("Telegram","https://t.me/playox1de")
 label(content,T("Канал OX1DE","OX1DE channel"),11,30,700,51,27,true)
 label(content,"https://t.me/playox1de",11,95,705,43,19,true)
 local status=label(content,"",11,252,720,51,14,false,C.sub)
 button(content,T("➤  Открыть Telegram","➤  Open Telegram"),11,170,500,57,function()
  local url="https://t.me/playox1de"
  local ok=pcall(function()game:GetService("GuiService"):OpenBrowserWindow(url)end)
  if not ok then
   if type(setclipboard)=="function" then pcall(setclipboard,url) end
   status.Text=T("Если ссылка не открылась, используй: ","Open the link manually: ")..url
  end
 end,true)
end
show=function(page)
 if not alive then return end
 if page~="exit" then current=page end
 if page=="exit" then closeConfirm.Visible=true;return end
 closeConfirm.Visible=false
 for id,b in pairs(nav) do
  b.BackgroundColor3=id==page and C.purple or C.card
 end
 for i,item in ipairs(navSpec) do
  nav[item[1]].Text=item[2].."   "..T(
   ({"Скрипты","История","Настройки","Телеграм"})[i],
   ({"Scripts","History","Settings","Telegram"})[i])
 end
 leave.Text="⏻  "..T("Выход","Exit")
 clearContent()
 if page=="scripts" then renderScripts()
 elseif page=="history" then renderHistory()
 elseif page=="game" then renderGame()
 elseif page=="settings" then renderSettings()
 elseif page=="telegram" then renderTelegram()
 end
end
-- Shift closes/reopens the menu without stopping this demo.
local keyConn=UIS.InputBegan:Connect(function(input,processed)
 if not processed and input.KeyCode==Enum.KeyCode.RightShift then
  setVisible(not win.Visible)
  if win.Visible then show(current) end
 end
end)
gui.Destroying:Connect(function()
 alive=false
 if keyConn then keyConn:Disconnect() end
 if cameraConn then cameraConn:Disconnect() end
 if cameraChangeConn then cameraChangeConn:Disconnect() end
 if music then pcall(function()music:Stop();music:Destroy()end)end
end)
-- Draggable mobile re-open bubble.
do
 local pressed=false
 local startInput,startPosition,finger=nil,nil,nil
 local moved=0
 balloon.InputBegan:Connect(function(i)
  if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
   pressed=true;finger=i.UserInputType==Enum.UserInputType.Touch and i or nil
   startInput=i.Position;startPosition=balloon.AbsolutePosition;moved=0;bubbleDragged=false
  end
 end)
 UIS.InputChanged:Connect(function(i)
  if not alive or not pressed or not startInput then return end
  if finger then if i~=finger then return end
  elseif i.UserInputType~=Enum.UserInputType.MouseMovement then return end
  local delta=i.Position-startInput
  moved=math.max(moved,delta.Magnitude)
  if moved<8 then return end
  bubbleDragged=true
  local camera=workspace.CurrentCamera
  local vp=camera and camera.ViewportSize or Vector2.new(1200,700)
  balloon.Position=UDim2.fromOffset(
   math.clamp(startPosition.X+delta.X,0,vp.X-52),
   math.clamp(startPosition.Y+delta.Y,0,vp.Y-52))
 end)
 UIS.InputEnded:Connect(function(i)
  if i.UserInputType==Enum.UserInputType.MouseButton1 or (finger and i==finger) then
   pressed=false;finger=nil
  end
 end)
end
show("scripts")
print("[OX1DE] Unified themed GUI preview 0.4.4 loaded successfully")
