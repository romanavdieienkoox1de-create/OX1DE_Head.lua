-- OX1DE Launcher UI / client-only companion for OX1DE_Cheating.lua
-- This file owns only the user interface. The original game's runtimes remain intact.
return function(api)
 local make,corner,border=api.make,api.corner,api.border
 local window,gui,player=api.window,api.gui,api.player
 local state,warSettings=api.state,api.warSettings
 local UIS=game:GetService("UserInputService")
 local RunService=game:GetService("RunService")
 local SoundService=game:GetService("SoundService")
 local Lighting=game:GetService("Lighting")
 local C={bg=Color3.fromRGB(11,11,19),panel=Color3.fromRGB(24,24,34),
   row=Color3.fromRGB(32,31,46),edge=Color3.fromRGB(91,66,130),
   violet=Color3.fromRGB(156,68,237),light=Color3.fromRGB(245,242,255),
   muted=Color3.fromRGB(165,160,181),yellow=Color3.fromRGB(255,215,42),
   red=Color3.fromRGB(255,72,90),green=Color3.fromRGB(103,241,153)}
 local z=340
 local lang=api.uiData.language=="en" and "en" or "ru"
 local tracks=api.uiData.musicTracks or {}
 local musicVolume=math.clamp(tonumber(api.uiData.musicVolume) or 70,0,100)
 local history=api.uiData.history or {}
 local view="scripts"
 local gameSection="main"
 local settingSection="graphics"
 local currentGame=nil
 local musicIndex=1
 local musicEnabled=false
 local searchText=""
 local musicFilter=""
 local dynamicConnections={}
 local sound=Instance.new("Sound")
 sound.Name="OX1DE_LocalMusic"
 sound.Volume=musicVolume/100
 sound.Looped=false
 sound.Parent=SoundService
 local ultraBloom=nil
 local ultraColor=nil
 local startingShadows=Lighting.GlobalShadows
 local function T(ru,en) return lang=="en" and en or ru end
 local function create(parent,class,properties)
  properties=properties or {}
  if properties.ZIndex==nil and class~="UICorner" and class~="UIStroke" and class~="UIGradient" then
   properties.ZIndex=z+2
  end
  return make(class,parent,properties)
 end
 local function pane(parent,x,y,w,h,color,round,zz)
  local p=create(parent,"Frame",{Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),
    BackgroundColor3=color or C.panel,BorderSizePixel=0,ZIndex=zz or z+3})
  if round then corner(p,round) end
  return p
 end
 local function lbl(parent,value,x,y,w,h,size,bold,color,align,zz)
  return create(parent,"TextLabel",{
   Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),
   BackgroundTransparency=1,Text=tostring(value),TextSize=size or 14,
   TextColor3=color or C.light,Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,
   TextXAlignment=align or Enum.TextXAlignment.Left,
   TextYAlignment=Enum.TextYAlignment.Center,
   TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=zz or z+6})
 end
 local function dyn(signal,callback)
  local c=signal:Connect(callback)
  dynamicConnections[#dynamicConnections+1]=c
  return c
 end
 local function btn(parent,caption,x,y,w,h,callback,accent,zz)
  local b=create(parent,"TextButton",{
   Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),
   BackgroundColor3=accent and C.violet or C.row,Text=tostring(caption),
   TextColor3=C.light,TextSize=14,Font=Enum.Font.GothamBold,
   BorderSizePixel=0,AutoButtonColor=true,ZIndex=zz or z+7})
  corner(b,10)
  if callback then dyn(b.MouseButton1Click,callback) end
  return b
 end
 local function clearDynamic()
  for _,c in ipairs(dynamicConnections) do pcall(function() c:Disconnect() end) end
  table.clear(dynamicConnections)
 end
 -- Existing interface remains in memory for its game bindings, but the player
 -- sees only this unified launcher/feature shell.
 for _,child in ipairs(window:GetChildren()) do
  if child:IsA("GuiObject") then child.Visible=false end
 end
 local shell=pane(window,0,0,1050,676,C.bg,26,z)
 shell.Name="OX1DE_LauncherShell"
 border(shell,C.violet,.27,1.4)
 local header=pane(shell,0,0,1050,82,Color3.fromRGB(17,16,27),23,z+3)
 pane(header,0,69,1050,13,Color3.fromRGB(17,16,27),nil,z+4)
 pane(header,20,79,1010,1,C.edge,nil,z+5)
 local logo=pane(header,18,10,61,61,Color3.fromRGB(0,0,0),14,z+5)
 border(logo,Color3.fromRGB(255,255,255),.44,1)
 lbl(logo,"OX",4,12,53,26,23,true,C.light,Enum.TextXAlignment.Center,z+8)
 lbl(logo,"1DE",3,37,55,16,14,true,C.light,Enum.TextXAlignment.Center,z+8)
 local brand=lbl(header,"OX1DE",95,14,270,43,29,true,C.light)
 lbl(header,"SCRIPT MENU",98,50,280,18,10,true,C.muted)
 local userName=lbl(header,player.DisplayName,704,18,160,31,14,true)
 lbl(header,"@"..player.Name,704,47,165,18,10,false,C.muted)
 local prime=btn(header,"♛  PRIME",867,22,104,41,nil,true,z+6)
 prime.BackgroundColor3=Color3.fromRGB(91,61,25)
 prime.TextColor3=C.yellow
 border(prime,C.yellow,.30,1)
 local hide=btn(header,"×",989,22,43,41,function()api.setVisible(false)end,false,z+7)
 hide.TextSize=24
 local side=pane(shell,12,90,219,515,Color3.fromRGB(18,17,28),15,z+3)
 local nav={}
 local show
 local navItems={{id="scripts",ru="Скрипты",en="Scripts",icon="≡",y=21},
  {id="history",ru="История",en="History",icon="◷",y=86},
  {id="settings",ru="Настройки",en="Settings",icon="⚙",y=151},
  {id="telegram",ru="Телеграм",en="Telegram",icon="➤",y=216}}
 for _,item in ipairs(navItems) do
  local b=btn(side,"",13,item.y,194,53,function()show(item.id)end,false,z+7)
  nav[item.id]=b
 end
 pane(side,14,417,190,1,C.edge,nil,z+4)
 local exitButton=btn(side,"",13,443,194,53,function()show("exit")end,false,z+7)
 local pageTitle=lbl(shell,"",251,97,750,34,22,true)
 local pageCaption=lbl(shell,"",252,129,752,23,12,false,C.muted)
 local scroll=create(shell,"ScrollingFrame",{
  Position=UDim2.fromOffset(247,161),Size=UDim2.fromOffset(785,433),
  BackgroundTransparency=1,BorderSizePixel=0,
  CanvasSize=UDim2.fromOffset(0,442),ScrollBarThickness=4,
  ScrollBarImageColor3=C.violet,ScrollingDirection=Enum.ScrollingDirection.Y,
  ZIndex=z+4})
 pane(shell,18,614,1015,1,C.edge,nil,z+4)
 local version=lbl(shell,"OX1DE  v0.4 • TEST",24,625,260,28,12,true,C.muted)
 local footer=btn(shell,"➤  t.me/playox1de",786,620,240,37,function()show("telegram")end,false,z+6)
 local loading=pane(shell,0,0,1050,676,C.bg,26,z+20)
 loading.Visible=false
 lbl(loading,"OX1DE",0,181,1050,67,46,true,C.light,Enum.TextXAlignment.Center,z+22)
 local loadingInfo=lbl(loading,"",235,286,580,35,16,true,C.light,Enum.TextXAlignment.Center,z+22)
 local loadingTrack=pane(loading,236,349,578,17,C.row,8,z+22)
 local loadingFill=pane(loadingTrack,0,0,0,17,C.violet,8,z+23)
 local loadingPercent=lbl(loading,"0%",236,387,578,30,17,true,C.light,Enum.TextXAlignment.Center,z+22)
 local confirm=pane(shell,0,0,1050,676,Color3.fromRGB(9,8,16),nil,z+25)
 confirm.BackgroundTransparency=.12
 confirm.Visible=false
 local confirmBox=pane(confirm,285,205,480,245,C.panel,20,z+27)
 border(confirmBox,C.violet,.2,1.3)
 lbl(confirmBox,T("Выключить OX1DE?","Exit OX1DE?"),25,22,435,48,25,true,C.light,nil,z+29)
 lbl(confirmBox,T("Скрипт и меню будут отключены до повторного запуска.",
   "The script and menu will stop until you run it again."),25,78,432,62,14,false,C.muted,nil,z+29).TextWrapped=true
 local cancel=btn(confirmBox,T("Отмена","Cancel"),23,172,208,51,function()confirm.Visible=false;show(currentGame and "game" or "scripts")end,false,z+30)
 local accept=btn(confirmBox,T("Подтвердить","Confirm"),249,172,208,51,function()api.stop()end,true,z+30)
 local function store()
  api.uiData.language=lang
  api.uiData.musicVolume=musicVolume
  api.uiData.musicTracks=tracks
  api.uiData.history=history
  api.save()
 end
 local function heading(title,subtitle)
  pageTitle.Text=title
  pageCaption.Text=subtitle or ""
 end
 local function rowToggle(title,desc,key,y)
  local r=pane(scroll,4,y,738,62,C.row,10,z+5)
  lbl(r,title,15,7,555,26,15,true)
  lbl(r,desc or "",15,34,550,18,11,false,C.muted)
  local b=btn(r,state[key] and "ВКЛ" or "ВЫКЛ",626,11,99,40,nil,state[key],z+7)
  local function refresh()
   b.Text=state[key] and T("ВКЛ","ON") or T("ВЫКЛ","OFF")
   b.BackgroundColor3=state[key] and C.violet or Color3.fromRGB(66,63,79)
  end
  refresh()
  dyn(b.MouseButton1Click,function()
   api.setOption(key,not state[key])
   refresh()
  end)
 end
 local function sliderRow(title,key,low,high,step,unit,y,defaultValue,onChange)
  local r=pane(scroll,4,y,738,83,C.row,10,z+5)
  lbl(r,title,15,4,495,29,14,true)
  local value=lbl(r,"",584,5,136,27,13,true,C.yellow,Enum.TextXAlignment.Right)
  local track=btn(r,"",22,55,689,10,nil,false,z+7)
  track.BackgroundColor3=Color3.fromRGB(73,67,88)
  local fill=pane(track,0,0,1,10,C.violet,5,z+8)
  local knob=pane(track,0,-5,20,20,C.light,10,z+9)
  local function render()
   local current=defaultValue()
   value.Text=tostring(current)..(unit or "")
   local t=math.clamp((current-low)/(high-low),0,1)
   fill.Size=UDim2.new(t,0,1,0)
   knob.Position=UDim2.new(t,-10,0,-5)
  end
  local dragging=false
  local function update(x)
   local width=track.AbsoluteSize.X
   if width<5 then return end
   local t=math.clamp((x-track.AbsolutePosition.X)/width,0,1)
   local new=math.clamp(math.floor((low+t*(high-low))/step+.5)*step,low,high)
   onChange(new)
   render()
  end
  dyn(track.InputBegan,function(input)
   if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
    dragging=true;update(input.Position.X)
   end
  end)
  dyn(UIS.InputChanged,function(input)
   if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
    update(input.Position.X)
   end
  end)
  dyn(UIS.InputEnded,function(input)
   if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
    if dragging then dragging=false;store() end
   end
  end)
  render()
 end
 local function gameName(id)
  return id=="warfare" and "WARFARE" or T("Район насилия","Violence District")
 end
 local function renderScripts()
  heading(T("Скрипты","Scripts"),T("Выбери игровую функцию OX1DE","Choose an OX1DE game profile"))
  for i,id in ipairs({"violence_district","warfare"}) do
   local y=7+(i-1)*171
   local card=pane(scroll,4,y,737,155,C.panel,14,z+5)
   border(card,C.violet,.39,1)
   local art=pane(card,15,14,115,125,Color3.fromRGB(12,8,22),12,z+6)
   lbl(art,id=="warfare" and "W" or "OX1DE",2,33,111,55,id=="warfare" and 40 or 22,true,C.light,Enum.TextXAlignment.Center,z+8)
   lbl(card,gameName(id),148,18,380,38,23,true,C.light)
   lbl(card,T("Игровой профиль с настройками","Game profile and settings"),148,58,390,25,13,false,C.muted)
   local tag=btn(card,"♛  PRIME",602,14,120,35,nil,false,z+7)
   tag.TextColor3=C.yellow;tag.BackgroundColor3=Color3.fromRGB(49,39,22)
   border(tag,C.yellow,.37,1)
   btn(card,T("▶  Запустить","▶  Launch"),493,90,226,47,function()
    currentGame=id;gameSection="main"
    loading.Visible=true
    loadingFill.Size=UDim2.fromOffset(0,17)
    loadingPercent.Text="0%"
    loadingInfo.Text=T("Подготовка профиля...","Preparing game profile...")
    task.spawn(function()
     local steps={{20,T("Проверка интерфейса","Checking interface")},
      {45,T("Проверка персонажа","Checking character")},
      {70,T("Активация игрового профиля","Activating game profile")},
      {100,T("Профиль готов","Profile ready")}}
     for j,step in ipairs(steps) do
      if not api.isAlive() or not loading.Parent then return end
      if j==2 then
       local character=player.Character
       if character then character:FindFirstChild("HumanoidRootPart") end
      elseif j==3 then
       api.activateTab(id)
      end
      loadingInfo.Text=step[2]
      loadingPercent.Text=tostring(step[1]).."%"
      loadingFill.Size=UDim2.fromOffset(math.floor(578*step[1]/100),17)
      RunService.Heartbeat:Wait()
     end
     table.insert(history,1,{name=gameName(id),time=os.date("%d.%m.%Y %H:%M")})
     while #history>15 do table.remove(history) end
     store()
     loading.Visible=false
     show("game")
    end)
   end,true,z+7)
  end
  local search=create(scroll,"TextBox",{
   Position=UDim2.fromOffset(4,359),Size=UDim2.fromOffset(480,50),
   BackgroundColor3=C.row,TextColor3=C.light,PlaceholderColor3=C.muted,
   PlaceholderText=T("Найти скрипт...","Find a script..."),Text=searchText,
   TextSize=14,Font=Enum.Font.Gotham,ClearTextOnFocus=false,BorderSizePixel=0,ZIndex=z+7
  })
  corner(search,11)
  dyn(search:GetPropertyChangedSignal("Text"),function()
   searchText=search.Text
   for i,id in ipairs({"violence_district","warfare"}) do
    local parent=scroll:FindFirstChild("GameCard_"..id)
    if parent then parent.Visible=id:find(searchText:lower(),1,true)~=nil or gameName(id):lower():find(searchText:lower(),1,true)~=nil or searchText=="" end
   end
  end)
  btn(scroll,T("⟳  Обновить","⟳  Refresh"),499,359,244,50,function()
   local note=lbl(scroll,T("Список двух профилей обновлён","Two profiles refreshed"),10,415,560,23,12,false,C.green)
   task.delay(2,function()if note.Parent then note:Destroy()end end)
  end,false,z+7)
  scroll.CanvasSize=UDim2.fromOffset(0,443)
 end
 local function renderHistory()
  heading(T("История","History"),T("Последние запущенные профили","Recently launched profiles"))
  if #history==0 then
   lbl(scroll,T("История пока пустая. Запусти любой скрипт.","History is empty. Launch a script first."),15,25,700,44,15,false,C.muted)
  end
  for i,item in ipairs(history) do
   local r=pane(scroll,4,7+(i-1)*56,740,48,C.row,10)
   lbl(r,item.name or "OX1DE",16,5,500,37,15,true)
   lbl(r,item.time or "",530,5,195,37,12,false,C.muted,Enum.TextXAlignment.Right)
  end
  scroll.CanvasSize=UDim2.fromOffset(0,math.max(433,15+#history*57))
 end
 local function renderGame()
  heading("OX1DE • "..gameName(currentGame),T("Функции выбранной игры","Selected game features"))
  for i,item in ipairs({
   {"main",T("Главное","Main")},{"aim","AIM"},{"esp","ESP"},{"other",T("Прочее","Other")}
  }) do
   local w=175,x=4+(i-1)*185
   local b=btn(scroll,item[2],x,4,w,44,function()gameSection=item[1];show("game")end,gameSection==item[1])
   if gameSection~=item[1] then b.BackgroundColor3=C.panel end
  end
  local y=64
  if currentGame=="warfare" then
   if gameSection=="main" then
    rowToggle("Fly",T("Полёт на WASD / Space / Ctrl","Camera flight on WASD / Space / Ctrl"),"warFly",y);y+=70
    rowToggle("NoClip",T("Проход через препятствия","Pass through obstacles"),"warNoClip",y);y+=70
    rowToggle("AIM",T("Камера следует за выбранной целью","Camera follows a selected target"),"warAimPreview",y);y+=70
    lbl(scroll,T("Отдельно: AIM, ESP, Прочее","More controls: AIM, ESP, Other"),14,y+10,700,37,13,false,C.muted)
   elseif gameSection=="aim" then
    for _,entry in ipairs({{"warAimPreview","AIM","Наведение камеры"},
      {"warFov","FOV","Показывать окружность"},
      {"warTeamCheck","Team Check","Проверка команды"},
      {"warWallCheck","Wall Check","Проверка препятствий"},
      {"warHoldAim","Удержание","ПКМ / ЛКМ"}}) do
     rowToggle(entry[2],entry[3],entry[1],y);y+=69
    end
    local mode=btn(scroll,"LEGIT",4,y,164,43,function()warSettings.mode="legit";store();show("game")end,warSettings.mode=="legit")
    btn(scroll,"HARD",184,y,164,43,function()warSettings.mode="hard";store();show("game")end,warSettings.mode=="hard")
    y+=58
    for _,entry in ipairs({{"fov","FOV",20,400,5," px"},{"distance","Дальность",10,300,5," м"},
      {"prediction","Упреждение",0,100,5," %"},{"smooth","Плавность LEGIT",5,100,5," %"},
      {"height","Высота прицела",-100,100,5," %"},{"drop","Поправка падения",0,100,5," %"}}) do
     local key=entry[1]
     sliderRow(entry[2],key,entry[3],entry[4],entry[5],entry[6],y,function()return warSettings[key]end,
      function(n)warSettings[key]=n end)
     y+=91
    end
   elseif gameSection=="esp" then
    for _,entry in ipairs({{"warAllies","Союзники"},{"warEnemies","Противники"},{"warNames","Имена и дистанция"},
      {"warWeapons","Оружие"},{"warFPV","FPV-дроны"},{"warShowHP","HP игроков"},
      {"warTeamHud","Мини-HUD команд"}}) do
     rowToggle(entry[2],T("Подсветка и информация","Overlay and information"),entry[1],y);y+=70
    end
   else
    rowToggle("Fly","WASD / Space / Ctrl","warFly",y);y+=70
    rowToggle("NoClip",T("Без столкновений","No collisions"),"warNoClip",y);y+=70
   end
  else
   if gameSection=="aim" then
    lbl(scroll,T("Для этого профиля AIM не предусмотрен.","This profile has no AIM feature."),15,20+y,710,40,17,false,C.muted)
    y+=100
   elseif gameSection=="esp" then
    for _,entry in ipairs({{"players","Игроки"},{"killers","Убийца"},{"generators","Генераторы"},
      {"pumpkins","Тыквы"},{"pallets","Паллеты"}}) do
     rowToggle(entry[2],T("Визуализация объектов","Object highlight"),entry[1],y);y+=70
    end
   else
    rowToggle("Fly",T("Полёт","Flight"),"fly",y);y+=70
    rowToggle("NoClip",T("Проход сквозь объекты","No collisions"),"noclip",y);y+=70
    rowToggle(T("Автопроверка навыка","Auto Skill Check"),T("Экспериментальная функция","Experimental feature"),"autoSkill",y);y+=70
   end
  end
  btn(scroll,T("←  К списку скриптов","←  Back to scripts"),4,y+17,308,44,function()show("scripts")end,false)
  scroll.CanvasSize=UDim2.fromOffset(0,math.max(435,y+86))
 end
 local function applyGraphics(mode)
  api.uiData.graphicsMode=mode
  api.graphicsMode(mode)
  if ultraBloom then ultraBloom:Destroy();ultraBloom=nil end
  if ultraColor then ultraColor:Destroy();ultraColor=nil end
  pcall(function()
   if mode=="low" then Lighting.GlobalShadows=false
   elseif mode=="high" then Lighting.GlobalShadows=true
   else Lighting.GlobalShadows=startingShadows end
  end)
  if mode=="high" then
   ultraBloom=Instance.new("BloomEffect")
   ultraBloom.Name="OX1DE_UltraBloom"
   ultraBloom.Intensity=.13;ultraBloom.Size=18;ultraBloom.Threshold=1.4
   ultraBloom.Parent=Lighting
   ultraColor=Instance.new("ColorCorrectionEffect")
   ultraColor.Name="OX1DE_UltraColor"
   ultraColor.Contrast=.07;ultraColor.Saturation=.08
   ultraColor.Parent=Lighting
  end
  store()
 end
 local function renderGraphics()
  heading(T("Настройки • Графика","Settings • Graphics"),T("Профили качества Roblox","Roblox quality presets"))
  lbl(scroll,T("Качество графики","Graphics quality"),8,5,640,35,20,true)
  for i,cfg in ipairs({{"low","POTATO"},{"medium",T("Стандартная","Standard")},{"high",T("Ультра","Ultra")}}) do
   local x=4+(i-1)*250
   local active=api.uiData.graphicsMode==cfg[1]
   local b=btn(scroll,cfg[2],x,50,240,77,function()applyGraphics(cfg[1]);show("settings")end,active)
   if not active then b.BackgroundColor3=C.panel end
  end
  lbl(scroll,T("Соотношение сторон","Aspect ratio"),8,151,690,31,19,true)
  local aspectLabels={"4:3","16:9","16:10","5:4","5:3","3:2","3:4"}
  for i,aspect in ipairs(aspectLabels) do
   local b=btn(scroll,aspect,4+(i-1)*105,190,98,47,function()
    -- Player-facing feedback: the game viewport cannot be stretched via this Lua.
    api.uiData.aspectPreview=aspect
    show("settings")
   end,api.uiData.aspectPreview==aspect)
   if api.uiData.aspectPreview~=aspect then b.BackgroundColor3=C.panel end
  end
  local status=pane(scroll,4,263,737,100,Color3.fromRGB(62,28,37),12)
  lbl(status,T("Важно: скрипт не может растянуть изображение Roblox.","Important: scripts cannot stretch Roblox's display."),15,9,703,40,14,true,C.red).TextWrapped=true
  lbl(status,T("Настрой формат экрана в Windows/драйвере видеокарты. На телефоне недоступно.",
   "Change display aspect ratio through your PC display or graphics driver settings."),15,47,697,42,12,false,C.light).TextWrapped=true
  scroll.CanvasSize=UDim2.fromOffset(0,433)
 end
 local function playTrack(i)
  if not tracks[i] then
   musicEnabled=false;sound:Stop()
   return
  end
  musicIndex=i
  musicEnabled=true
  sound:Stop()
  sound.SoundId="rbxassetid://"..tostring(tracks[i].id)
  sound.Volume=musicVolume/100
  sound:Play()
 end
 local function renderMusic()
  heading(T("Настройки • Музыка","Settings • Music"),
   T("Звук слышен только на твоём клиенте","Audio plays only on your client"))
  lbl(scroll,T("Локальный музыкальный плеер","Local music player"),7,8,598,34,19,true)
  local toggle=btn(scroll,musicEnabled and T("■  Стоп","■  Stop") or T("▶  Включить","▶  Play"),564,5,177,46,function()
   if musicEnabled then musicEnabled=false;sound:Pause() else
    if sound.SoundId~="" then musicEnabled=true;sound:Resume()
    else playTrack(musicIndex) end
   end
   show("settings")
  end,musicEnabled)
  lbl(scroll,T("Громкость музыки","Music volume"),10,77,680,29,16,true)
  sliderRow(T("Громкость музыки","Music volume"),"volume",0,100,5,"%",116,function()return musicVolume end,function(n)
   musicVolume=n;sound.Volume=n/100;api.uiData.musicVolume=n
  end)
  lbl(scroll,T("Roblox Audio ID (только доступные аудио)","Roblox Audio ID (permitted audio only)"),10,216,680,30,14,true)
  local audioID=create(scroll,"TextBox",{
   Position=UDim2.fromOffset(6,253),Size=UDim2.fromOffset(497,49),
   BackgroundColor3=C.row,TextColor3=C.light,PlaceholderColor3=C.muted,
   PlaceholderText=T("Вставь числовой Audio ID","Enter numeric Audio ID"),
   Text="",TextSize=15,Font=Enum.Font.Gotham,
   ClearTextOnFocus=false,BorderSizePixel=0,ZIndex=z+7})
  corner(audioID,10)
  local notice=lbl(scroll,"",6,314,730,31,12,false,C.muted)
  btn(scroll,T("+  Добавить","+  Add"),518,253,224,49,function()
   local id=audioID.Text:gsub("%D","")
   if #id<6 or #id>15 then
    notice.Text=T("Укажи числовой Roblox Audio ID.","Please enter a valid Roblox Audio ID.")
    return
   end
   table.insert(tracks,{id=id,name="Audio "..id})
   audioID.Text=""
   store()
   show("settings")
  end,true)
  btn(scroll,"◀◀",4,360,115,46,function()
   if #tracks>0 then playTrack((musicIndex-2)%#tracks+1);show("settings")end
  end)
  btn(scroll,"▶ / ▌▌",128,360,140,46,function()
   if musicEnabled then musicEnabled=false;sound:Pause()
   elseif sound.SoundId~="" then musicEnabled=true;sound:Resume()
   else playTrack(musicIndex) end
   show("settings")
  end,true)
  btn(scroll,"▶▶",277,360,115,46,function()
   if #tracks>0 then playTrack(musicIndex%#tracks+1);show("settings")end
  end)
  local current=tracks[musicIndex]
  lbl(scroll,current and current.name or T("Добавь трек по ID","Add a track by ID"),403,361,330,44,13,true,C.light)
  lbl(scroll,T("Плейлист","Playlist"),8,432,660,31,18,true)
  for i,item in ipairs(tracks) do
   local y=468+(i-1)*62
   local r=pane(scroll,4,y,739,55,C.row,9)
   lbl(r,item.name,13,5,468,41,14,true)
   btn(r,"▶",526,9,79,36,function()playTrack(i);show("settings")end,i==musicIndex and musicEnabled)
   btn(r,"×",620,9,99,36,function()
    if musicIndex==i then sound:Stop();musicEnabled=false end
    table.remove(tracks,i)
    if musicIndex>#tracks then musicIndex=math.max(1,#tracks) end
    store()
    show("settings")
   end,false)
  end
  local warn=lbl(scroll,T("Песни Google напрямую не поддерживаются: Roblox требует разрешённый Audio ID.",
   "Direct Google music streaming is unsupported. Roblox requires an allowed Audio ID."),9,469+#tracks*62,729,48,12,false,C.muted)
  warn.TextWrapped=true
  scroll.CanvasSize=UDim2.fromOffset(0,math.max(660,529+#tracks*62))
 end
 local function renderSettings()
  heading(T("Настройки","Settings"),T("Графика, музыка и язык","Graphics, music and language"))
  for i,cfg in ipairs({{"graphics",T("Графика","Graphics")},{"music",T("Музыка","Music")},{"language",T("Язык","Language")}}) do
   local x=4+(i-1)*250
   local b=btn(scroll,cfg[2],x,4,240,47,function()settingSection=cfg[1];show("settings")end,settingSection==cfg[1])
   if settingSection~=cfg[1] then b.BackgroundColor3=C.panel end
  end
  if settingSection=="graphics" then
   lbl(scroll,T("Качество графики","Graphics quality"),8,68,640,31,19,true)
   for i,cfg in ipairs({{"low","POTATO"},{"medium",T("Стандартная","Standard")},{"high",T("Ультра","Ultra")}}) do
    local x=4+(i-1)*250
    local active=api.uiData.graphicsMode==cfg[1]
    local b=btn(scroll,cfg[2],x,110,240,71,function()
     applyGraphics(cfg[1]);show("settings")
    end,active)
    if not active then b.BackgroundColor3=C.panel end
   end
   lbl(scroll,T("Соотношение экрана (справочно)","Display aspect ratios (reference)"),8,207,720,30,18,true)
   for i,aspect in ipairs({"4:3","16:9","16:10","5:4","5:3","3:2","3:4"}) do
    local x=4+(i-1)*105
    local b=btn(scroll,aspect,x,247,98,43,function()api.uiData.aspectPreview=aspect;show("settings")end,api.uiData.aspectPreview==aspect)
    if api.uiData.aspectPreview~=aspect then b.BackgroundColor3=C.panel end
   end
   local notice=pane(scroll,4,308,740,91,Color3.fromRGB(59,27,36),11)
   lbl(notice,T("Растяжение всей игры из Roblox Lua недоступно.","Full-game stretching cannot be changed through Roblox Lua."),12,8,710,34,15,true,C.red).TextWrapped=true
   lbl(notice,T("ПК: настрой экран в Windows или драйвере. На телефоне эта функция недоступна.",
    "PC: use display/driver settings. The option is unavailable on mobile."),12,44,710,36,13,false,C.light).TextWrapped=true
   scroll.CanvasSize=UDim2.fromOffset(0,433)
  elseif settingSection=="music" then
   -- Music uses this same content area; no separate window or device chooser.
   renderMusic()
  else
   lbl(scroll,T("Язык интерфейса","Interface language"),12,85,700,36,21,true)
   btn(scroll,"Русский",8,151,355,73,function()lang="ru";store();show("settings")end,lang=="ru")
   btn(scroll,"English",383,151,355,73,function()lang="en";store();show("settings")end,lang=="en")
   lbl(scroll,T("Язык изменится в основном меню и настройках.","The language changes in the main menu and settings."),
    12,244,719,46,13,false,C.muted)
   scroll.CanvasSize=UDim2.fromOffset(0,433)
  end
 end
 local telegramMessage=""
 local function renderTelegram()
  heading("Telegram","https://t.me/playox1de")
  lbl(scroll,T("Официальный канал OX1DE","OX1DE channel"),10,24,721,40,23,true)
  lbl(scroll,"https://t.me/playox1de",10,84,720,40,18,false,C.light)
  local status=lbl(scroll,telegramMessage,10,227,715,46,14,false,C.muted)
  btn(scroll,T("➤  Открыть Telegram","➤  Open Telegram"),10,146,476,65,function()
   local url="https://t.me/playox1de"
   local opened=pcall(function()game:GetService("GuiService"):OpenBrowserWindow(url)end)
   if opened then
    telegramMessage=T("Открываю Telegram...","Opening Telegram...")
   else
    local copied=false
    if type(setclipboard)=="function" then copied=pcall(setclipboard,url)
    elseif type(toclipboard)=="function" then copied=pcall(toclipboard,url) end
    telegramMessage=copied and T("Ссылка скопирована.","Link copied.") or T("Открой адрес вручную: ","Open manually: ")..url
   end
   status.Text=telegramMessage
  end,true)
  scroll.CanvasSize=UDim2.fromOffset(0,433)
 end
 local function renderExit()
  heading(T("Выход","Exit"),T("Полное отключение OX1DE","Completely stop OX1DE"))
  confirm.Visible=true
  scroll.CanvasSize=UDim2.fromOffset(0,433)
 end
 local function refreshNav()
  for _,item in ipairs(navItems) do
   local b=nav[item.id]
   b.Text=item.icon.."   "..T(item.ru,item.en)
   b.BackgroundColor3=view==item.id and C.violet or C.row
  end
  exitButton.Text="⏻   "..T("Выход","Exit")
  hide.Text="×"
  footer.Text="➤  t.me/playox1de"
 end
 show=function(nextView)
  if not api.isAlive() then return end
  if nextView=="game" and not currentGame then nextView="scripts" end
  view=nextView
  refreshNav()
  clearDynamic()
  for _,obj in ipairs(scroll:GetChildren()) do obj:Destroy() end
  scroll.CanvasPosition=Vector2.zero
  scroll.CanvasSize=UDim2.fromOffset(0,433)
  if view=="scripts" then renderScripts()
  elseif view=="history" then renderHistory()
  elseif view=="game" then renderGame()
  elseif view=="settings" then renderSettings()
  elseif view=="telegram" then renderTelegram()
  elseif view=="exit" then renderExit()
  end
 end
 -- Recover the last launched profile after closing shared Settings.
 api.onClose(function()
  if view=="settings" and currentGame then show("game") end
 end)
 api.listen(sound.Ended,function()
  if musicEnabled and #tracks>0 then
   playTrack(musicIndex%#tracks+1)
   if view=="settings" and settingSection=="music" then show("settings") end
  end
 end)
 -- Mobile uses exactly the same shell with an accessible floating re-open button.
 if UIS.TouchEnabled then
  local float=create(gui,"TextButton",{
   Name="OX1DE_TouchLauncher",Position=UDim2.new(1,-69,.44,0),Size=UDim2.fromOffset(54,54),
   BackgroundColor3=C.bg,Text="OX",TextSize=18,Font=Enum.Font.GothamBold,
   TextColor3=C.light,AutoButtonColor=true,BorderSizePixel=0,ZIndex=400})
  corner(float,27);border(float,C.violet,.05,1.6)
  local holding=false
  local startFinger=nil
  local startPos=nil
  local dragged=0
  local touch=nil
  api.listen(float.InputBegan,function(input)
   if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
    holding=true;touch=input.UserInputType==Enum.UserInputType.Touch and input or nil
    startFinger=input.Position;startPos=float.AbsolutePosition;dragged=0
   end
  end)
  api.listen(UIS.InputChanged,function(input)
   if not holding or not startFinger then return end
   if touch then if input~=touch then return end
   elseif input.UserInputType~=Enum.UserInputType.MouseMovement then return end
   local offset=input.Position-startFinger
   dragged=math.max(dragged,offset.Magnitude)
   if dragged<7 then return end
   local camera=workspace.CurrentCamera
   local size=camera and camera.ViewportSize or Vector2.new(1000,600)
   float.Position=UDim2.fromOffset(math.clamp(startPos.X+offset.X,0,size.X-54),math.clamp(startPos.Y+offset.Y,0,size.Y-54))
  end)
  api.listen(UIS.InputEnded,function(input)
   if input.UserInputType==Enum.UserInputType.MouseButton1 or (touch and input==touch) then
    holding=false;touch=nil
   end
  end)
  api.listen(float.MouseButton1Click,function()
   if dragged>7 then dragged=0;return end
   api.setVisible(not api.isOpen())
  end)
 end
 show("scripts")
 return function()
  if sound then sound:Stop();sound:Destroy() end
  if ultraBloom then ultraBloom:Destroy() end
  if ultraColor then ultraColor:Destroy() end
  pcall(function()Lighting.GlobalShadows=startingShadows end)
  clearDynamic()
 end
end
