-- OX1DE v0.6.0 BETA • Unified launcher + separate gameplay engine • FULL DESIGN PREVIEW, NO GAMEPLAY MODIFICATIONS
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
local HttpService=game:GetService("HttpService")
local prefsFile="OX1DE_Menu_"..tostring(p.UserId)..".json"
local hasFiles=type(readfile)=="function" and type(writefile)=="function"
local cfg={}
if hasFiles then
 local ok,data=pcall(function()return HttpService:JSONDecode(readfile(prefsFile))end)
 if ok and type(data)=="table" then cfg=data end
end
local fpsEnabled=cfg.showFPS==true
local pingEnabled=cfg.showPing==true
local bindingTarget=nil
local keyNames={menu="RightShift",fly="F6",noclip="F7",warFly="F9",warNoClip="F8",warAim="F10"}
if type(cfg.binds)=="table" then
 for k,v in pairs(cfg.binds) do
  local ok=type(v)=="string" and #v<35 and pcall(function()return Enum.KeyCode[v]end)
  if keyNames[k] and ok then keyNames[k]=v end
 end
end
local env=_G
if type(getgenv)=="function" then
 local ok,e=pcall(getgenv)
 if ok and type(e)=="table" then env=e end
end
local bridgeError=""
local engineStarting=false
local function gameplay()
 local b=env.OX1DE_BRIDGE or _G.OX1DE_BRIDGE
 if b and type(b.alive)=="function" and b.alive() then return b end
 return nil
end
-- Licensed Roblox library samples. Actual playback depends on audio permissions.
local tracks={
 -- New genres: music asset IDs listed on Roblox Creator Store.
 {id="136932193331774",name="ROBLOX PHONK — Misutra",genre="Phonk"},
 {id="125476440612900",name="67 KID PHONK — DRIFTGØD",genre="Phonk"},
 {id="92733699101708",name="Pretty Rave Girl — Vilaxxs",genre="Synthwave"},
 {id="14145621151",name="Emotional Damage — Phonk Vol. 1",genre="Phonk"},
 {id="14145621445",name="Raven's Theme — Phonk Vol. 1",genre="Phonk"},
 {id="14145626744",name="Unbreakable — Phonk Vol. 2",genre="Phonk"},
 {id="1837116095",name="Vast Array — Synthwave",genre="Synthwave"},
 {id="97684046608381",name="Cold Synthwave Style",genre="Electronic"},
 {id="1836105293",name="Tender Tropical House — AXS",genre="House"},
 {id="1846368080",name="Stadium Rave (A)",genre="Dance"},
 {id="1837015626",name="Tokyo Drift",genre="Electronic"},
 {id="9043887091",name="Lo-fi Chill",genre="Lo-fi"},
 {id="1837848642",name="Crystal Clear",genre="Electronic"},
 {id="1836842889",name="Solar Flares",genre="Electronic"},
 {id="1847853099",name="Robotic Dance C",genre="Dance"},
 {id="1842627030",name="Funky Beats",genre="Dance"},
 {id="1842801942",name="Full Force",genre="Electronic"},
 {id="1837560230",name="Classic Chase",genre="Cinematic"},
 {id="1840044242",name="Shooting Star",genre="Electronic"},
 {id="1841647093",name="Life in an Elevator",genre="Lounge"},
 {id="1848354536",name="Relaxed Scene",genre="Ambient"},
 {id="1837849285",name="Upbeat Electronica",genre="Electronic"},
 {id="1848183670",name="Grandiose Fantasy",genre="Cinematic"},
 {id="1843463175",name="Creepy Organ / Dungeon",genre="Atmosphere"}
}
local songIndex=1
local musicEnabled=false
local volume=65
if cfg.language=="ru" or cfg.language=="en" then language=cfg.language end
if cfg.quality=="potato" or cfg.quality=="standard" or cfg.quality=="ultra" then chosenQuality=cfg.quality end
if type(cfg.aspect)=="string" then aspect=cfg.aspect end
if type(cfg.volume)=="number" then volume=math.clamp(cfg.volume,0,100) end
if type(cfg.tracks)=="table" and #cfg.tracks>0 then
 local existing={}
 for _,item in ipairs(tracks) do existing[item.id]=true end
 for i,item in ipairs(cfg.tracks) do
  if i>120 then break end
  if type(item)=="table" and type(item.id)=="string" and item.id:match("^%d+$") and type(item.name)=="string" then
   if not existing[item.id] then
    tracks[#tracks+1]={id=item.id,name=item.name:sub(1,75),genre=type(item.genre)=="string" and item.genre or "Roblox Audio"}
    existing[item.id]=true
   end
  end
 end
end
local function savePrefs()
 if not hasFiles then return end
 cfg.showFPS=fpsEnabled;cfg.showPing=pingEnabled;cfg.binds=keyNames
 cfg.language=language;cfg.quality=chosenQuality;cfg.aspect=aspect
 cfg.volume=volume;cfg.tracks=tracks
 pcall(function()writefile(prefsFile,HttpService:JSONEncode(cfg))end)
end
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
   standard=Enum.QualityLevel.Level05,ultra=Enum.QualityLevel.Level21})[preset]
 end)
 local lightingChanged=pcall(function()
  Lighting.GlobalShadows=preset=="potato" and false or (preset=="ultra" and true or originalShadows)
 end)
 -- Ultra requests Roblox's highest permitted rendering quality, not an
 -- artificial color filter. Only Potato uses optional lightweight color FX.
 if preset=="potato" then
  pcall(function()
   local correction=Instance.new("ColorCorrectionEffect")
   correction.Name="OX1DE_Preview_LowColor"
   correction.Saturation=-.1
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
 Name="OX1DE_LocalMusic",Volume=volume/100,Looped=false})
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
label(logo,"OX1DE",3,3,49,47,13,true,C.text,true,8)
label(head,"OX1DE",81,8,320,35,27,true)
label(head,"SCRIPT MENU",83,43,290,17,10,true,C.sub)
local account=label(head,p.DisplayName,711,10,206,27,13,true)
local username=label(head,"@"..p.Name,711,38,207,20,11,false,C.sub)
local show
local restore=button(head,"−",941,18,24,39,nil,false)
local hide=button(head,"×",970,18,25,39,nil,false)
restore.TextSize=20;hide.TextSize=22
local side=block(win,12,87,208,475,C.head,15,3)
-- Account block follows the compact OX1DE mockup; real Roblox avatar/name.
local profile=block(side,9,9,190,82,C.panel,11,5)
local avatar=mk("ImageLabel",profile,{
 Position=UDim2.fromOffset(8,9),Size=UDim2.fromOffset(61,61),
 BackgroundColor3=Color3.fromRGB(16,13,26),BorderSizePixel=0,
 Image="",ScaleType=Enum.ScaleType.Crop,ZIndex=7})
rounded(avatar,11);stroke(avatar,C.purple,.34,1)
label(profile,p.DisplayName,77,13,105,26,13,true)
label(profile,"@"..p.Name,77,35,106,19,10,false,C.sub)
label(profile,T("В сети","Online"),77,57,102,15,10,true,C.green)
task.spawn(function()
 local ok,img=pcall(function()
  return Players:GetUserThumbnailAsync(p.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100)
 end)
 if ok and avatar.Parent then avatar.Image=img end
end)
local content=mk("ScrollingFrame",win,{
 Position=UDim2.fromOffset(235,169),Size=UDim2.fromOffset(754,390),
 BackgroundTransparency=1,ScrollBarThickness=4,ScrollBarImageColor3=C.purple,
 BorderSizePixel=0,CanvasSize=UDim2.fromOffset(0,463),
 ScrollingDirection=Enum.ScrollingDirection.Y,ZIndex=4})
block(win,19,571,960,1,C.alt,nil,4)
label(win,"OX1DE   •   v0.6.0 BETA",24,578,358,27,12,true,C.sub)
local telegramFooter=button(win,"t.me/playox1de",757,576,218,35,nil,false)
telegramFooter.TextSize=12
local nav={}
local navSpec={
 {"scripts","≡",T("Скрипты","Scripts")},
 {"history","◷",T("История","History")},
 {"settings","⚙",T("Настройки","Settings")},
 {"telegram","","Telegram"}
}
local navFunction
for i,item in ipairs(navSpec) do
 local id=item[1]
 nav[id]=button(side,item[2].."    "..item[3],12,104+(i-1)*57,184,49,function()show(id)end)
end
block(side,13,395,182,1,C.alt,nil,4)
local leave=button(side,"⏻  "..T("Выход","Exit"),12,404,184,51,function()show("exit")end)
-- HUD is embedded beside the minimize/close buttons, rather than floating
-- above Roblox or covering the top-right of the launcher.
local statsPanel=block(head,434,18,231,39,C.panel,10,9)
stroke(statsPanel,C.purple,.5,1)
local statsText=label(statsPanel,"",7,1,217,37,12,true,C.text,true,11)
statsPanel.Visible=fpsEnabled or pingEnabled
local sampledFrames=0
local elapsedStats=0
local lastFps=0
local lastPing=0
local statsConn=RunService.RenderStepped:Connect(function(dt)
 if not alive then return end
 statsPanel.Visible=win.Visible and (fpsEnabled or pingEnabled)
 if not (fpsEnabled or pingEnabled) then
  elapsedStats=0;sampledFrames=0
  statsText.Text=""
  return
 end
 sampledFrames+=1;elapsedStats+=dt
 if elapsedStats<.7 then return end
 lastFps=math.floor(sampledFrames/elapsedStats+.5)
 elapsedStats=0;sampledFrames=0
 local ok,seconds=pcall(function()return p:GetNetworkPing()end)
 if ok and type(seconds)=="number" then lastPing=math.floor(seconds*1000+.5)end
 local data={}
 if fpsEnabled then data[#data+1]="FPS: "..lastFps end
 if pingEnabled then data[#data+1]="PING: "..lastPing.." мс" end
 statsText.Text=table.concat(data,"    |    ")
end)
local balloon=button(gui,"OX1DE",0,0,52,52,nil,true,45)
local mobileBubbleOnly=UIS.TouchEnabled and not UIS.KeyboardEnabled
balloon.BackgroundColor3=C.bg
balloon.Position=UDim2.new(1,-68,.42,0)
stroke(balloon,C.purple,.05,1.4);rounded(balloon,26)
balloon.Visible=false
local function setVisible(open)
 if not alive then return end
 local b=gameplay()
 if not open then
  -- Hiding the menu suspends visual ESP and generator highlights immediately;
  -- save the user's switches unchanged for the next open.
  selectedGame="violence_district"
  previousGame="violence_district"
  tab="main"
  current="game"
  if b then
   pcall(b.setTab,"violence_district")
   if b.setOverlaysVisible then pcall(b.setOverlaysVisible,false) end
  end
 elseif b and b.setOverlaysVisible then
  pcall(b.setOverlaysVisible,true)
 end
 win.Visible=open
 balloon.Visible=mobileBubbleOnly and not open
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
 local b=gameplay()
 if b then pcall(b.stop) end
 savePrefs()
 alive=false
 clearFX()
 pcall(function()Lighting.GlobalShadows=originalShadows end)
 if originalQuality then pcall(function()
  UserSettings():GetService("UserGameSettings").SavedQualityLevel=originalQuality
 end) end
 music:Stop();music:Destroy()
 if cameraConn then cameraConn:Disconnect() end
 if cameraChangeConn then cameraChangeConn:Disconnect() end
 if statsConn then statsConn:Disconnect() end
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
local function demoToggle(k,txt,desc,y,bindKey)
 local b=gameplay()
 local enabled=b and b.getOption(k)==true or false
 local row=block(content,4,y,734,64,C.panel,12,6)
 label(row,txt,15,7,bindKey and 375 or 570,28,16,true)
 label(row,desc or "",15,35,bindKey and 377 or 580,20,11,false,C.sub)
 if bindKey then
  local keyCaption=bindingTarget==bindKey and T("ЖДУ КЛАВИШУ","PRESS KEY")
    or (T("БИНД: ","KEY: ")..(keyNames[bindKey] or "?"))
  button(row,keyCaption,409,12,201,39,function()
   bindingTarget=bindKey
   _G.OX1DE_SHELL_BINDING=true
   env.OX1DE_SHELL_BINDING=true
   show("game")
  end,false,8)
 end
 local toggle=button(row,not b and "—" or (enabled and T("ВКЛ","ON") or T("ВЫКЛ","OFF")),
  620,12,100,39,nil,enabled,8)
 if not b then toggle.BackgroundColor3=C.alt;toggle.AutoButtonColor=false;return row end
 toggle.MouseButton1Click:Connect(function()
  local now=gameplay()
  if now then
   now.setOption(k,not now.getOption(k))
   local selected=now.getOption(k)
   toggle.Text=selected and T("ВКЛ","ON") or T("ВЫКЛ","OFF")
   toggle.BackgroundColor3=selected and C.purple or C.card
  end
 end)
 return row
end
local function valueRow(titleText,value,y)
 local row=block(content,4,y,734,56,C.panel,11,6)
 label(row,titleText,15,5,440,45,15,true)
 label(row,tostring(value),490,5,225,45,15,true,C.purple)
 return row
end
local function bindRow(titleText,key,y)
 local r=block(content,4,y,734,57,C.panel,11,6)
 label(r,titleText,16,6,450,42,15,true)
 local currentName=keyNames[key] or "?"
 button(r,bindingTarget==key and T("Нажми клавишу","Press a key") or currentName,
  509,7,209,43,function()
   bindingTarget=key
   _G.OX1DE_SHELL_BINDING=true
   env.OX1DE_SHELL_BINDING=true
   show(current=="settings" and "settings" or "game")
  end,true)
end
local function engineSlider(key,titleText,minimum,maximum,step,unit,y)
 local b=gameplay()
 if not b or not b.warSettings then return end
 local r=block(content,4,y,734,74,C.panel,11,6)
 label(r,titleText,14,4,450,29,14,true)
 local value=label(r,"",579,4,134,29,13,true,C.bright)
 local track=block(r,22,50,683,9,C.alt,5,8)
 track.Active=true
 local fill=block(track,0,0,1,9,C.purple,5,9)
 local dot=block(track,0,-5,19,19,C.text,10,10)
 local function sync()
  local v=tonumber(b.warSettings[key]) or minimum
  local t=math.clamp((v-minimum)/(maximum-minimum),0,1)
  fill.Size=UDim2.new(t,0,1,0)
  dot.Position=UDim2.new(t,-9,0,-5)
  value.Text=tostring(v)..(unit or "")
 end
 local function move(x)
  local t=math.clamp((x-track.AbsolutePosition.X)/math.max(1,track.AbsoluteSize.X),0,1)
  local v=math.clamp(math.floor(((minimum+(maximum-minimum)*t)/step)+.5)*step,minimum,maximum)
  b.warSettings[key]=v
  sync()
 end
 local dragged=false
 local dragTouch=nil
 track.InputBegan:Connect(function(i)
  if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
   dragged=true;dragTouch=i.UserInputType==Enum.UserInputType.Touch and i or nil
   move(i.Position.X)
  end
 end)
 local moving=UIS.InputChanged:Connect(function(i)
  if not dragged then return end
  if dragTouch then if i~=dragTouch then return end
  elseif i.UserInputType~=Enum.UserInputType.MouseMovement then return end
  move(i.Position.X)
 end)
 local ending=UIS.InputEnded:Connect(function(i)
  if i.UserInputType==Enum.UserInputType.MouseButton1 or (dragTouch and i==dragTouch) then
   if dragged then
    dragged=false;dragTouch=nil
    if b.save then b.save() end
   end
  end
 end)
 track.Destroying:Connect(function()moving:Disconnect();ending:Disconnect()end)
 sync()
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
local function prepareEngine(id)
 local b=gameplay()
 if not b then
  env.OX1DE_SHELL_MODE=true;_G.OX1DE_SHELL_MODE=true
  local function ignoreNativeToggle()end
  env.OX1DE_SHELL_TOGGLE=ignoreNativeToggle
  _G.OX1DE_SHELL_TOGGLE=ignoreNativeToggle
  local ok,err=pcall(function()
   local url="https://raw.githubusercontent.com/romanavdieienkoox1de-create/OX1DE_Head.lua/main/OX1DE_Cheating.lua"
   local source=game:HttpGet(url)
   local chunk=loadstring(source)
   assert(type(chunk)=="function","Не удалось собрать игровой модуль")
   chunk()
  end)
  if not ok then
   bridgeError="Ошибка игрового модуля: "..tostring(err)
   env.OX1DE_SHELL_MODE=nil;_G.OX1DE_SHELL_MODE=nil
   env.OX1DE_SHELL_TOGGLE=nil;_G.OX1DE_SHELL_TOGGLE=nil
   return false
  end
 end
 b=gameplay()
 if not b then bridgeError="Игровой модуль не предоставил управление";return false end
 if not alive then
  pcall(b.stop)
  return false
 end
 for key,name in pairs(keyNames) do
  local ok,code=pcall(function()return Enum.KeyCode[name]end)
  if ok and code and code~=Enum.KeyCode.Unknown then b.keybind[key]=code end
 end
 pcall(b.setTab,id)
 if b.hideNative then pcall(b.hideNative) end
 if b.setOverlaysVisible then pcall(b.setOverlaysVisible,win.Visible) end
 pcall(b.save)
 bridgeError=""
 return true
end
local function launchGame(id)
 if engineStarting then return end
 engineStarting=true
 selectedGame=id;previousGame=id;tab="main"
 loadTitle.Text=T("Подготовка профиля","Preparing game profile")
 loadFill.Size=UDim2.fromOffset(0,18)
 loadPct.Text="0%"
 loadLayer.Visible=true
 task.spawn(function()
  if not alive then engineStarting=false;return end
  loadPct.Text="20%"
  loadTitle.Text=T("Подключение игрового модуля...","Connecting game module...")
  loadFill.Size=UDim2.fromOffset(115,18)
  local ok,result=pcall(prepareEngine,id)
  loadPct.Text=ok and result and "85%" or "Ошибка"
  loadTitle.Text=ok and result and T("Открытие интерфейса","Opening menu")
   or T("Игровой модуль не подключён","Gameplay module unavailable")
  loadFill.Size=UDim2.fromOffset(ok and result and 490 or 0,18)
  RunService.Heartbeat:Wait()
  if not ok then bridgeError=tostring(result) end
  if not alive then engineStarting=false;return end
  if ok and result then
   loadPct.Text="100%"
   loadFill.Size=UDim2.fromOffset(574,18)
   table.insert(history,1,{name=nameFor(id),time=os.date("%d.%m.%Y %H:%M")})
   if #history>12 then table.remove(history,13) end
   savePrefs()
  end
  engineStarting=false
  loadLayer.Visible=false
  show("game")
 end)
end
local function renderScripts()
 heading(T("Скрипты","Scripts"),T("Список доступных игровых профилей OX1DE","Available OX1DE game profiles"))
 local cards={}
 local defs={{id="violence_district",symbol="R",category="SURVIVAL • HORROR"},
  {id="warfare",symbol="W",category="TEAM • FPS"}}
 for i,entry in ipairs(defs) do
  local id=entry.id
  local y=5+(i-1)*157
  local r=block(content,4,y,734,145,C.panel,14,6)
  r.Name="GameCard_"..id
  stroke(r,C.purple,.52,1.1)
  mk("UIGradient",r,{Color=ColorSequence.new({
   ColorSequenceKeypoint.new(0,Color3.fromRGB(38,28,57)),
   ColorSequenceKeypoint.new(.52,Color3.fromRGB(26,24,37)),
   ColorSequenceKeypoint.new(1,Color3.fromRGB(20,19,30))}),Rotation=0})
  cards[id]=r
  local stripe=block(r,0,12,4,120,C.purple,2,7)
  local art=block(r,14,15,115,114,Color3.fromRGB(15,12,26),11,7)
  stroke(art,C.purple,.62,1)
  label(art,entry.symbol,0,14,115,76,57,true,C.text,true,9)
  label(art,"OX1DE",0,88,115,22,11,true,C.purple,true,9)
  label(r,nameFor(id),151,13,399,41,23,true)
  label(r,entry.category,152,53,415,23,11,true,C.sub)
  label(r,T("Выберите профиль, чтобы открыть функции","Open this profile to view its features"),
   151,85,402,23,12,false,C.sub)
  local primeTag=block(r,614,12,106,33,Color3.fromRGB(45,36,22),8,8)
  stroke(primeTag,C.yellow,.31,.9)
  label(primeTag,"♛ PRIME",0,4,106,23,13,true,C.yellow,true,9)
  button(r,T("▶   ОТКРЫТЬ","▶   OPEN"),518,84,201,46,
   function()launchGame(id)end,true,9)
 end
 local search=mk("TextBox",content,{
  Position=UDim2.fromOffset(4,322),Size=UDim2.fromOffset(490,45),
  BackgroundColor3=C.card,BorderSizePixel=0,
  PlaceholderColor3=C.sub,PlaceholderText=T("  Поиск по названию...","  Search games..."),
  ClearTextOnFocus=false,Text="",TextSize=15,TextColor3=C.text,
  Font=Enum.Font.Gotham,ZIndex=8})
 rounded(search,10)
 local note=label(content,"",4,370,727,27,12,false,C.sub)
 local function filter(q)
  q=q:lower()
  local count=0
  for id,r in pairs(cards) do
   local found=q=="" or nameFor(id):lower():find(q,1,true)~=nil
      or id:find(q,1,true)~=nil
   r.Visible=found
   if found then count+=1 end
  end
  note.Text=count==0 and T("По этому запросу нет профилей","No matching profiles")
   or T("Найдено профилей: ","Profiles found: ")..count
 end
 search:GetPropertyChangedSignal("Text"):Connect(function()filter(search.Text)end)
 button(content,T("⟳   ОБНОВИТЬ","⟳   REFRESH"),507,322,231,45,function()
  search.Text="";filter("")
  note.Text=T("Список обновлён • доступны 2 профиля","List refreshed • 2 profiles available")
 end,false)
 filter("")
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
 if not selectedGame then selectedGame="violence_district" end
 heading("OX1DE  •  "..nameFor(selectedGame),T("Управление функциями игры","Game controls"))
 local isWar=selectedGame=="warfare"
 local tabs=isWar and {{"main",T("Главное","Main")},{"aim","AIM"},{"esp","ESP"}}
   or {{"main",T("Главное","Main")},{"esp","ESP"}}
 if not isWar and tab=="aim" then tab="main" end
 for i,item in ipairs(tabs) do
  local w=math.floor(734/#tabs)-7
  local x=4+(i-1)*(w+10)
  button(content,item[2],x,4,w,46,function()tab=item[1];show("game")end,tab==item[1],8)
 end
 local y=63
 local b=gameplay()
 if not b then
  local notice=rowNotice(bridgeError~="" and bridgeError or
   T("Игровой модуль ещё не подключён. Вернись к списку и нажми «Открыть».",
     "Game module is not connected. Return to the list and launch it."),
    4,y,734,82)
  local retry=button(content,T("↻  Повторить запуск","↻  Retry launch"),4,y+96,325,48,function()
   launchGame(selectedGame)
  end,true)
  content.CanvasSize=UDim2.fromOffset(0,430)
  return
 end
 if isWar then
  if tab=="main" then
   demoToggle("warFly","Fly",T("Полёт относительно камеры","Camera flight"),y,"warFly");y+=72
   demoToggle("warNoClip","NoClip",T("Без столкновений","No collisions"),y,"warNoClip");y+=72
   demoToggle("warTeamHud",T("Счётчик команд","Team counter"),T("Союзники и противники","Allies and enemies"),y);y+=72
  elseif tab=="aim" then
   demoToggle("warAimPreview","AIM",T("Настройка из оригинального игрового модуля","Original game module settings"),y,"warAim");y+=72
   demoToggle("warFov","FOV",T("Отображать FOV","Show FOV"),y);y+=72
   demoToggle("warTeamCheck","Team Check",T("Проверять команду","Check teams"),y);y+=72
   demoToggle("warWallCheck","Wall Check",T("Проверять препятствия","Check obstacles"),y);y+=72
   demoToggle("warHoldAim",T("Удержание AIM","Hold AIM"),"RMB / LMB",y);y+=72
   local mode=b.warSettings.mode
   label(content,T("Режим наведения","Aim mode"),11,y,300,35,16,true)
   button(content,"HARD",340,y,182,39,function()
    b.warSettings.mode="hard";b.save();show("game")
   end,mode=="hard")
   button(content,"LEGIT",538,y,191,39,function()
    b.warSettings.mode="legit";b.save();show("game")
   end,mode=="legit")
   y+=52
   local specs={
    {"fov","FOV",20,400,5," px"},
    {"distance",T("Дальность","Range"),10,300,5," м"},
    {"prediction",T("Упреждение","Prediction"),0,100,5," %"},
    {"smooth",T("Плавность","Smoothness"),5,100,5," %"},
    {"height",T("Высота","Height"),-100,100,5," %"},
    {"drop",T("Коррекция падения","Drop correction"),0,100,5," %"}
   }
   for _,item in ipairs(specs) do
    engineSlider(item[1],item[2],item[3],item[4],item[5],item[6],y)
    y+=82
   end
  else
   for _,entry in ipairs({
    {"warAllies",T("Союзники","Allies")},{"warEnemies",T("Противники","Enemies")},
    {"warNames",T("Никнеймы и метры","Names and distance")},
    {"warWeapons",T("Оружие","Weapon info")},{"warFPV","FPV"},
    {"warShowHP","HP"},{"warTeamHud",T("Счётчик команд","Team counter")}
   }) do
    demoToggle(entry[1],entry[2],T("Информация на экране","On-screen display"),y);y+=72
   end
  end
 else
  if tab=="esp" then
   for _,entry in ipairs({{"players",T("Игроки","Players")},
    {"killers",T("Убийца","Killer")},{"generators",T("Генераторы","Generators")},
    {"pumpkins",T("Тыквы","Pumpkins")},{"pallets",T("Паллеты","Pallets")}}) do
    demoToggle(entry[1],entry[2],T("Подсветка объектов","Object highlight"),y);y+=72
   end
  else
   demoToggle("fly","Fly",T("Полёт","Flight"),y,"fly");y+=72
   demoToggle("noclip","NoClip",T("Без столкновений","No collisions"),y,"noclip");y+=72
   demoToggle("autoSkill",T("Автопроверка навыка","Auto Skill Check"),
    T("Ранее добавленная функция","Existing game function"),y);y+=72
  end
 end
 button(content,T("←  Все скрипты","←  Scripts"),4,y+12,287,46,function()
  show("scripts")
 end)
 content.CanvasSize=UDim2.fromOffset(0,math.max(424,y+83))
end
local function renderQuality()
 label(content,T("Качество изображения","Image quality"),10,73,650,33,20,true)
 for i,cfg in ipairs({
  {"potato","POTATO",T("Минимум теней","Less shadows")},
  {"standard",T("Стандарт","Standard"),T("Без доп. эффектов","No extra effects")},
  {"ultra",T("Ультра • MAX","Ultra • MAX"),T("Максимум Roblox","Roblox maximum")}
 }) do
  local id=cfg[1]
  local x=4+(i-1)*247
  local selected=chosenQuality==id
  local card=block(content,x,113,239,89,selected and Color3.fromRGB(63,38,88) or C.panel,12,6)
  if selected then stroke(card,C.purple,.10,1.5) else stroke(card,C.alt,.6,1) end
  button(card,cfg[2],8,8,222,39,function()
   changeGraphics(id)
   savePrefs()
   show("settings")
  end,selected,8)
  label(card,cfg[3],10,52,217,26,11,false,C.sub,true)
 end
 local result=block(content,4,214,734,58,C.panel,10,6)
 local status=label(result,graphicsMessage,13,6,705,45,13,false,C.sub)
 status.TextWrapped=true
 label(content,T("Соотношение сторон • справка","Aspect ratio • reference"),11,284,704,31,17,true)
 for i,opt in ipairs({"3:4","5:4","4:3","3:2","16:10","5:3","16:9","21:9","32:9"}) do
  local col=(i-1)%5
  local row=math.floor((i-1)/5)
  local b=button(content,opt,4+col*148,325+row*47,141,40,function()
   aspect=opt;savePrefs();show("settings")
  end,aspect==opt)
  if aspect~=opt then b.BackgroundColor3=C.panel end
 end
 local warn=block(content,4,432,734,68,Color3.fromRGB(56,27,41),10,6)
 local msg=label(warn,T("Растянуть весь Roblox через Lua нельзя. ПК: Windows / драйвер. Телефон: недоступно.",
  "Lua cannot change full Roblox stretching. PC: Windows / GPU driver. Mobile: unavailable."),
  12,6,705,56,13,false,C.text)
 msg.TextWrapped=true
 content.CanvasSize=UDim2.fromOffset(0,520)
end
local function startTrack(i)
 local track=tracks[i]
 if not track then musicMessage=T("Список треков пуст.","Playlist is empty.");return end
 songIndex=i;musicEnabled=true;musicMessage=""
 music:Stop()
 music.SoundId="rbxassetid://"..tostring(track.id)
 music.Volume=volume/100
 local ok,err=pcall(function()music:Play()end)
 if not ok then
  musicEnabled=false
  musicMessage="Ошибка: "..tostring(err)
 end
 local expected=music.SoundId
 task.delay(8,function()
  if not alive or not music.Parent or not musicEnabled or music.SoundId~=expected then return end
  if not music.IsLoaded then
   musicEnabled=false;music:Stop()
   musicMessage=T("Roblox не разрешил этот Audio ID или трек недоступен.",
      "Roblox denied this audio asset or it is unavailable.")
   if current=="settings" and settingsTab=="music" then show("settings") end
  end
 end)
end
music.Ended:Connect(function()
 if musicEnabled and alive and #tracks>0 then
  startTrack(songIndex%#tracks+1)
  if current=="settings" and settingsTab=="music" then show("settings") end
 end
end)
local function renderMusic()
 label(content,T("Музыкальный плеер","Music player"),9,64,494,36,20,true)
 local now=tracks[songIndex]
 local playerBox=block(content,4,108,734,113,C.panel,13,6)
 stroke(playerBox,C.alt,.42,1)
 local art=block(playerBox,12,10,88,91,Color3.fromRGB(43,23,75),12,7)
 label(art,"♫",0,21,88,47,33,true,C.bright,true,8)
 label(playerBox,now and now.name or T("Нет трека","No track"),115,13,361,35,18,true)
 label(playerBox,now and (now.genre or "Roblox Audio") or "",
  115,49,356,22,12,false,C.sub)
 label(playerBox,T("Локальный звук • слышен только тебе","Local music • only you hear it"),
  115,75,370,21,11,false,C.sub)
 button(playerBox,"◀◀",508,28,61,54,function()
  if #tracks>0 then startTrack((songIndex-2)%#tracks+1);show("settings")end
 end,false)
 button(playerBox,musicEnabled and "■" or "▶",577,28,61,54,function()
  if musicEnabled then musicEnabled=false;music:Stop()
  else startTrack(songIndex)end
  show("settings")
 end,true)
 button(playerBox,"▶▶",646,28,61,54,function()
  if #tracks>0 then startTrack(songIndex%#tracks+1);show("settings")end
 end,false)
 local status=label(content,musicMessage,11,224,727,28,12,false,C.red)
 label(content,T("Громкость музыки","Music volume"),10,258,580,28,16,true)
 local volText=label(content,tostring(volume).."%",626,258,106,27,14,true,C.yellow)
 local volTrack=block(content,12,308,713,11,C.alt,6,7)
 local volFill=block(volTrack,0,0,volume*7.13,11,C.purple,6,8)
 local knob=block(volTrack,volume*7.13-9,-5,20,20,C.text,10,9)
 local dragging=false
 local dragTouch=nil
 local function updateVolume(x)
  local t=math.clamp((x-volTrack.AbsolutePosition.X)/math.max(1,volTrack.AbsoluteSize.X),0,1)
  volume=math.floor(t*100+.5)
  volText.Text=tostring(volume).."%"
  volFill.Size=UDim2.new(volume/100,0,1,0)
  knob.Position=UDim2.new(volume/100,-9,0,-5)
  music.Volume=volume/100
 end
 volTrack.InputBegan:Connect(function(input)
  if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
   dragging=true
   dragTouch=input.UserInputType==Enum.UserInputType.Touch and input or nil
   updateVolume(input.Position.X)
  end
 end)
 local dragConn=UIS.InputChanged:Connect(function(input)
  if not dragging then return end
  if dragTouch then if input~=dragTouch then return end
  elseif input.UserInputType~=Enum.UserInputType.MouseMovement then return end
  updateVolume(input.Position.X)
 end)
 local endConn=UIS.InputEnded:Connect(function(input)
  if input.UserInputType==Enum.UserInputType.MouseButton1 or (dragTouch and input==dragTouch) then
   dragging=false;dragTouch=nil
   savePrefs()
  end
 end)
 volTrack.Destroying:Connect(function()
  dragConn:Disconnect();endConn:Disconnect()
 end)
 label(content,T("Плейлист Roblox","Roblox playlist"),9,339,450,31,18,true)
 local find=mk("TextBox",content,{
  Position=UDim2.fromOffset(443,340),Size=UDim2.fromOffset(290,35),
  Text="",PlaceholderText=T("Поиск по названию...","Search by title..."),
  TextColor3=C.text,PlaceholderColor3=C.sub,Font=Enum.Font.Gotham,
  TextSize=12,ClearTextOnFocus=false,BackgroundColor3=C.card,
  BorderSizePixel=0,ZIndex=9})
 rounded(find,8)
 local rowFrames={}
 for i,track in ipairs(tracks) do
  local y=387+(i-1)*60
  local row=block(content,4,y,734,54,i==songIndex and Color3.fromRGB(56,38,76) or C.panel,9,6)
  rowFrames[i]=row
  label(row,string.format("%02d",i),10,3,33,47,12,true,C.sub)
  label(row,track.name,47,3,449,26,14,true)
  label(row,track.genre or "Roblox Audio",47,29,438,19,10,false,C.sub)
  button(row,"▶",554,7,70,39,function()
   startTrack(i);show("settings")
  end,i==songIndex and musicEnabled)
  button(row,"×",636,7,86,39,function()
   local currentTrack=tracks[i]
   if currentTrack and music.SoundId=="rbxassetid://"..currentTrack.id then
    musicEnabled=false;music:Stop()
   end
   table.remove(tracks,i)
   songIndex=math.max(1,math.min(songIndex,#tracks))
   savePrefs()
   show("settings")
  end,false)
 end
 local function filter(query)
  local search=query:lower()
  local visibleCount=0
  for i,track in ipairs(tracks) do
   local good=search=="" or track.name:lower():find(search,1,true)~=nil
      or tostring(track.id):find(search,1,true)~=nil
   if rowFrames[i] then
    rowFrames[i].Visible=good
    if good then
     rowFrames[i].Position=UDim2.fromOffset(4,387+visibleCount*60)
     visibleCount+=1
    end
   end
  end
 end
 find:GetPropertyChangedSignal("Text"):Connect(function()filter(find.Text)end)
 local bottom=391+#tracks*60
 label(content,T("Добавить свой Roblox Audio ID","Add Roblox Audio ID"),
  9,bottom+10,700,31,16,true)
 local title=mk("TextBox",content,{
  Position=UDim2.fromOffset(4,bottom+49),Size=UDim2.fromOffset(365,44),
  Text="",PlaceholderText=T("Название трека","Track title"),
  TextColor3=C.text,PlaceholderColor3=C.sub,Font=Enum.Font.Gotham,
  TextSize=13,ClearTextOnFocus=false,BackgroundColor3=C.card,
  BorderSizePixel=0,ZIndex=8})
 rounded(title,9)
 local idInput=mk("TextBox",content,{
  Position=UDim2.fromOffset(377,bottom+49),Size=UDim2.fromOffset(227,44),
  Text="",PlaceholderText="Audio ID",
  TextColor3=C.text,PlaceholderColor3=C.sub,Font=Enum.Font.Gotham,
  TextSize=13,ClearTextOnFocus=false,BackgroundColor3=C.card,
  BorderSizePixel=0,ZIndex=8})
 rounded(idInput,9)
 button(content,"+",615,bottom+49,121,44,function()
  local id=idInput.Text:gsub("%D","")
  if #id<6 or #id>15 then
   musicMessage=T("Нужен корректный числовой Audio ID.","Enter a numeric Audio ID.")
   show("settings");return
  end
  local songName=title.Text:gsub("^%s+",""):gsub("%s+$","")
  if songName=="" then songName="Audio "..id end
  tracks[#tracks+1]={id=id,name=songName,genre="Мой трек"}
  savePrefs()
  musicMessage=T("Трек добавлен. Воспроизведение зависит от прав Roblox.","Track added; availability depends on Roblox.")
  show("settings")
 end,true)
 local foot=label(content,T("Любые песни из Google напрямую не воспроизводятся. Используй доступные аудио Roblox.",
  "Streaming any Google song is unavailable. Use permitted Roblox audio assets."),
  9,bottom+112,718,47,12,false,C.sub)
 foot.TextWrapped=true
 content.CanvasSize=UDim2.fromOffset(0,bottom+173)
end
local function renderLanguage()
 label(content,T("Язык интерфейса","Interface language"),10,84,697,42,21,true)
 button(content,"Русский",4,155,353,68,function()
  language="ru";savePrefs();show("settings")
 end,language=="ru")
 button(content,"English",383,155,355,68,function()
  language="en";savePrefs();show("settings")
 end,language=="en")
 label(content,T("Выбор меняет основные надписи меню.","This changes the main menu labels."),
  10,252,720,42,14,false,C.sub)
end
local function renderControls()
 label(content,T("Отображение и управление","Display and controls"),9,67,709,35,19,true)
 local function option(titleText,desc,key,y)
  local r=block(content,4,y,734,67,C.panel,11,6)
  label(r,titleText,15,4,551,30,15,true)
  label(r,desc,15,35,570,24,12,false,C.sub)
  local enabled
  if key=="fps" then enabled=fpsEnabled else enabled=pingEnabled end
  button(r,enabled and T("ВКЛ","ON") or T("ВЫКЛ","OFF"),
   609,12,111,43,function()
    if key=="fps" then fpsEnabled=not fpsEnabled
    else pingEnabled=not pingEnabled end
    statsText.Text=""
    statsPanel.Visible=win.Visible and (fpsEnabled or pingEnabled)
    savePrefs()
    show("settings")
   end,enabled)
 end
 option(T("Счётчик FPS","FPS counter"),T("Показывать кадры в секунду","Show frames per second"),"fps",109)
 option(T("Счётчик PING","Ping counter"),T("Показывать задержку сети","Show network latency"),"ping",184)
 bindRow(T("Открыть / закрыть меню","Open / close menu"),"menu",268)
 local hint=label(content,hasFiles and T("Клавиша меню сохраняется на устройстве.",
   "Menu shortcut is saved locally.") or T("Автосохранение недоступно; после перезапуска клавиша сбросится.",
   "File saving unavailable; shortcut resets after restart."),
    10,345,720,65,12,false,C.sub)
 hint.TextWrapped=true
 content.CanvasSize=UDim2.fromOffset(0,433)
end
local function renderSettings()
 heading(T("Настройки","Settings"),
  T("Графика, музыка, управление и язык","Graphics, music, controls and language"))
 for i,item in ipairs({{"graphics",T("Графика","Graphics")},
  {"music",T("Музыка","Music")},
  {"controls",T("Управление","Controls")},
  {"language",T("Язык","Language")}}) do
  local id=item[1]
  panelTab(item[2],4+(i-1)*185,settingsTab==id,function()
   settingsTab=id;show("settings")
  end)
 end
 if settingsTab=="graphics" then renderQuality()
 elseif settingsTab=="music" then renderMusic()
 elseif settingsTab=="controls" then renderControls()
 else renderLanguage() end
end
local function renderTelegram()
 heading("Telegram","https://t.me/playox1de")
 local card=block(content,4,18,734,331,C.panel,15,6)
 stroke(card,C.alt,.4,1)
 local badge=block(card,21,24,72,70,Color3.fromRGB(32,84,135),14,7)
 label(badge,"➤",0,10,72,48,33,true,C.text,true,8)
 label(card,T("Канал OX1DE","OX1DE channel"),113,25,589,43,24,true)
 label(card,T("Новости, обновления и связь с командой",
  "Updates, news and team contact"),114,70,580,29,14,false,C.sub)
 local url="https://t.me/playox1de"
 local link=mk("TextBox",card,{
  Position=UDim2.fromOffset(20,132),Size=UDim2.fromOffset(692,47),
  Text=url,TextEditable=false,ClearTextOnFocus=false,
  TextColor3=C.text,TextSize=16,Font=Enum.Font.Gotham,
  BackgroundColor3=C.card,BorderSizePixel=0,ZIndex=9})
 rounded(link,10)
 local status=label(card,T("Кнопка копирования доступна, если исполнитель разрешает буфер обмена.",
   "Copy works when the script environment supports clipboard access."),
   21,266,684,47,12,false,C.sub)
 status.TextWrapped=true
 local function copyLink()
  local copied=false
  if type(setclipboard)=="function" then copied=pcall(setclipboard,url)
  elseif type(toclipboard)=="function" then copied=pcall(toclipboard,url)
  end
  if copied then
   status.Text=T("Ссылка скопирована! Вставь её в браузер или Telegram.",
    "Link copied! Paste it into your browser or Telegram.")
  else
   pcall(function()
    link:CaptureFocus()
    link.CursorPosition=#url+1
    link.SelectionStart=1
   end)
   status.Text=T("Ссылка выделена. Нажми Ctrl+C или скопируй её вручную.",
    "Link selected. Press Ctrl+C or copy it manually.")
  end
  return copied
 end
 button(card,T("➤   ОТКРЫТЬ TELEGRAM","➤   OPEN TELEGRAM"),19,196,332,57,function()
  local ok=pcall(function()
   local gs=game:GetService("GuiService")
   gs:OpenBrowserWindow(url)
  end)
  if not ok then
   copyLink()
   status.Text=T("Roblox заблокировал браузер. Ссылка доступна выше для копирования.",
    "Roblox blocked the browser. You can copy the link above.")
  else
   status.Text=T("Запрос на открытие Telegram отправлен.","Requested to open Telegram.")
  end
 end,true)
 button(card,T("▣   КОПИРОВАТЬ ССЫЛКУ","▣   COPY LINK"),365,196,347,57,copyLink,false)
 rowNotice(T("Нельзя обещать автоматическое открытие внешней ссылки из любой игры Roblox.",
  "Automatic external-link opening cannot be guaranteed in every Roblox experience."),
  4,369,734,60)
 content.CanvasSize=UDim2.fromOffset(0,463)
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
 if not alive then return end
 if bindingTarget then
  local target=bindingTarget
  bindingTarget=nil
  _G.OX1DE_SHELL_BINDING=nil
  env.OX1DE_SHELL_BINDING=nil
  if input.KeyCode~=Enum.KeyCode.Unknown and input.KeyCode~=Enum.KeyCode.Escape then
   keyNames[target]=input.KeyCode.Name
   local b=gameplay()
   if b and b.keybind then
    b.keybind[target]=input.KeyCode
    if b.save then b.save() end
   end
   savePrefs()
  end
  show(current)
  return
 end
 if UIS:GetFocusedTextBox() then return end
 if input.KeyCode==Enum.KeyCode.Escape and win.Visible then
  setVisible(false)
  return
 end
 if not processed and input.KeyCode.Name==keyNames.menu then
  setVisible(not win.Visible)
  if win.Visible then show(current) end
 end
end)
gui.Destroying:Connect(function()
 alive=false
 env.OX1DE_SHELL_MODE=nil
 _G.OX1DE_SHELL_MODE=nil
 env.OX1DE_SHELL_TOGGLE=nil
 _G.OX1DE_SHELL_TOGGLE=nil
 env.OX1DE_SHELL_BINDING=nil
 _G.OX1DE_SHELL_BINDING=nil
 savePrefs()
 clearFX()
 pcall(function()Lighting.GlobalShadows=originalShadows end)
 if keyConn then keyConn:Disconnect() end
 if statsConn then statsConn:Disconnect() end
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
if cfg.quality=="potato" or cfg.quality=="standard" or cfg.quality=="ultra" then
 pcall(changeGraphics,cfg.quality)
end
show("scripts")
print("[OX1DE] OX1DE v0.6.0 beta launcher initialized")
