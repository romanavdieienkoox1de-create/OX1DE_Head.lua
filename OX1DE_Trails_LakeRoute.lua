-- OX1DE Trails Lake Route v0.1 | standalone client-side test
-- Record an actual trip around the lake, save points, then TEST seat steering.
-- This does not teleport a vehicle. Actual movement depends on the game's
-- VehicleSeat/chassis controls and server permissions.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local UIS=game:GetService("UserInputService")
local player=Players.LocalPlayer
if not player then error("OX1DE Trails: LocalPlayer отсутствует") end
local env=_G
if type(getgenv)=="function" then
 local ok,result=pcall(getgenv)
 if ok and type(result)=="table" then env=result end
end
local previous=env.OX1DE_TRAILS_STOP or _G.OX1DE_TRAILS_STOP
if type(previous)=="function" then pcall(previous) end
local container
if type(gethui)=="function" then
 local ok,h=pcall(gethui)
 if ok and h then container=h end
end
if not container then container=player:WaitForChild("PlayerGui",8) end
if not container then error("OX1DE Trails: PlayerGui недоступен") end
local alive=true
local recording=false
local driving=false
local markers={}
local connections={}
local route={}
local pathFile="OX1DE_Trails_Lake_"..tostring(player.UserId)..".json"
local speedOptions={.32,.55,.78}
local speedIndex=2
local currentIndex=1
local distanceDriven=0
local recordSeat=nil
local driveSeat=nil
local lastPosition=nil
local stuckClock=0
local stepClock=0
local lastThrottle=0
local lastSteer=0
local status="Сядь на квадроцикл. Затем нажми «Записать»."
local note="Маршрут вокруг озера: записывай береговую дорогу, не сокращая путь."
local function listen(signal,callback)
 local c=signal:Connect(callback)
 connections[#connections+1]=c
 return c
end
local function seatOf()
 local char=player.Character
 local hum=char and char:FindFirstChildOfClass("Humanoid")
 local seat=hum and hum.SeatPart
 if seat and seat:IsA("BasePart") and seat.Parent then return seat end
 return nil
end
local function positionOf(seat)
 return seat and seat.Position or nil
end
local function asPoint(v)
 return {x=v.X,y=v.Y,z=v.Z}
end
local function asVector(t)
 return Vector3.new(t.x,t.y,t.z)
end
local function distance2d(a,b)
 local dx=a.X-b.X
 local dz=a.Z-b.Z
 return math.sqrt(dx*dx+dz*dz)
end
local function routeDistance()
 local dist=0
 for i=2,#route do dist+=distance2d(asVector(route[i-1]),asVector(route[i])) end
 return dist
end
local gui=Instance.new("ScreenGui")
gui.Name="OX1DE_Trails_LakeRoute"
gui.ResetOnSpawn=false
gui.IgnoreGuiInset=true
gui.DisplayOrder=850
gui.Parent=container
local function make(class,parent,props)
 local o=Instance.new(class)
 for k,v in pairs(props or {}) do o[k]=v end
 o.Parent=parent
 return o
end
local function rounded(item,r)
 make("UICorner",item,{CornerRadius=UDim.new(0,r or 10)})
end
local C={
 bg=Color3.fromRGB(15,14,23),card=Color3.fromRGB(32,28,44),
 light=Color3.fromRGB(240,238,255),muted=Color3.fromRGB(181,171,197),
 accent=Color3.fromRGB(161,79,233),warning=Color3.fromRGB(255,198,108)
}
local window=make("Frame",gui,{
 AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
 Size=UDim2.fromOffset(485,420),BackgroundColor3=C.bg,BorderSizePixel=0
})
rounded(window,16)
make("UIStroke",window,{Color=C.accent,Thickness=1.4,Transparency=.17})
local scale=make("UIScale",window,{Scale=1})
local function fit()
 local camera=workspace.CurrentCamera
 if camera then
  local view=camera.ViewportSize
  scale.Scale=math.max(.35,math.min(1,(view.X-24)/485,(view.Y-24)/420))
 end
end
fit()
local function label(text,x,y,w,h,size,color)
 return make("TextLabel",window,{
  BackgroundTransparency=1,Text=text,Position=UDim2.fromOffset(x,y),
  Size=UDim2.fromOffset(w,h),TextColor3=color or C.light,
  Font=Enum.Font.Gotham,TextSize=size or 13,
  TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true
 })
end
local function button(title,x,y,w,h,onClick)
 local b=make("TextButton",window,{
  Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),
  BackgroundColor3=C.card,TextColor3=C.light,Text=title,
  Font=Enum.Font.GothamBold,TextSize=14,BorderSizePixel=0
 })
 rounded(b,9)
 if onClick then listen(b.MouseButton1Click,onClick) end
 return b
end
label("OX1DE  /  TRAILS",19,13,270,37,23,C.light)
label("МАРШРУТ ВОКРУГ ОЗЕРА  •  TEST 0.1",21,49,424,22,11,C.muted)
local close=button("×",437,14,34,31,function()
 if env.OX1DE_TRAILS_STOP then env.OX1DE_TRAILS_STOP() end
end)
close.TextSize=20
local message=label(status,20,84,443,48,14,C.light)
local info=label(note,20,136,444,42,12,C.muted)
local recordButton,saveButton,driveButton,stopButton,routeButton,speedButton
local counters=label("Точек: 0  •  Длина: 0 м",20,332,447,32,13,C.muted)
local seatInfo=label("Транспорт: не определён",20,367,443,33,12,C.warning)
local function setStatus(v)
 status=v
 if message and message.Parent then message.Text=v end
end
local function refresh()
 local count=#route
 local gap=0
 if count>1 then gap=distance2d(asVector(route[1]),asVector(route[count])) end
 counters.Text=string.format("Точек: %d  •  Длина: %.0f studs  •  Разрыв: %.0f",count,routeDistance(),gap)
 local seat=seatOf()
 seatInfo.Text=seat and ("Транспорт: "..seat.ClassName.." ("..seat.Name..")") or "Транспорт: не в сиденье"
 recordButton.Text=recording and "■  Завершить запись" or "●  Записать"
 driveButton.Text=driving and "▶ Автоезда..." or "▶ Автоезда"
 speedButton.Text=string.format("Скорость: %d%%",math.floor(speedOptions[speedIndex]*100+.5))
end
local function cleanMarkers()
 for _,m in ipairs(markers) do pcall(function()m:Destroy()end) end
 table.clear(markers)
end
local function releaseSeat(seat)
 if not seat or not seat.Parent then return end
 if seat:IsA("VehicleSeat") then
  pcall(function()seat.ThrottleFloat=0 end)
  pcall(function()seat.SteerFloat=0 end)
 end
end
local function stopDrive(reason)
 driving=false
 lastThrottle=0
 lastSteer=0
 releaseSeat(driveSeat)
 driveSeat=nil
 stuckClock=0
 currentIndex=1
 if reason then setStatus(reason) end
 refresh()
end
local function endRecord()
 recording=false
 if recordSeat and recordSeat.Parent and #route>0 then
  local pos=positionOf(recordSeat)
  if pos and distance2d(asVector(route[#route]),pos)>3 then
   route[#route+1]=asPoint(pos)
  end
 end
 recordSeat=nil
 if #route<15 then
  setStatus("Записано мало точек. Проедь вокруг озера целиком.")
 else
  local gap=distance2d(asVector(route[1]),asVector(route[#route]))
  setStatus(gap<=60 and "Маршрут готов! Нажми «Сохранить»." or
   "Запись готова, но финиш далеко от старта: "..math.floor(gap).." studs.")
 end
 refresh()
end
local function recordToggle()
 if driving then stopDrive("Автоезда остановлена перед записью.") end
 if recording then endRecord();return end
 local seat=seatOf()
 if not seat then setStatus("Сначала сядь на квадроцикл или другое транспортное средство.");return end
 cleanMarkers()
 route={}
 recordSeat=seat
 route[1]=asPoint(positionOf(seat))
 recording=true
 distanceDriven=0
 setStatus("Идёт запись. Объедь озеро и вернись к старту.")
 refresh()
end
local function persist()
 if recording then endRecord() end
 if #route<15 or routeDistance()<120 then
  setStatus("Для сохранения нужно проехать длинный маршрут вокруг озера.")
  return
 end
 local data={version=1,placeId=game.PlaceId,points=route}
 local encoded=HttpService:JSONEncode(data)
 if type(writefile)=="function" then
  local ok=pcall(writefile,pathFile,encoded)
  if ok then setStatus("Маршрут сохранён: "..#route.." точек. Можно тестировать автоезду.") return end
 end
 if type(setclipboard)=="function" then
  local ok=pcall(setclipboard,encoded)
  if ok then setStatus("Файл не поддерживается. Маршрут скопирован в буфер обмена.") return end
 end
 setStatus("Маршрут есть в памяти до перезапуска. Сохранение недоступно.")
end
local function startDrive()
 if recording then endRecord() end
 local seat=seatOf()
 if not seat then setStatus("Для автоезды сначала сядь на квадроцикл.");return end
 if not seat:IsA("VehicleSeat") then
  setStatus("У этой машины сиденье типа "..seat.ClassName..". Нужна адаптация управления.")
  return
 end
 if #route<15 or routeDistance()<120 then
  setStatus("Сначала запиши маршрут вокруг озера и сохрани его.")
  return
 end
 local gap=distance2d(asVector(route[#route]),asVector(route[1]))
 if gap>60 then
  setStatus("Финиш далеко от старта ("..math.floor(gap).." studs). Замкни маршрут записью.")
  return
 end
 local pos=seat.Position
 local first=asVector(route[1])
 if distance2d(pos,first)>55 then
  setStatus("Подъедь к началу записанного маршрута (осталось "..math.floor(distance2d(pos,first)).." studs).")
  return
 end
 driveSeat=seat
 driving=true
 currentIndex=2
 lastPosition=pos
 stuckClock=0
 setStatus("Тест автоезды запущен. Кнопка «Стоп» остановит управление.")
 refresh()
end
local function showRoute()
 if #markers>0 then
  cleanMarkers()
  setStatus("Метки маршрута скрыты.")
  return
 end
 if #route==0 then setStatus("Маршрут ещё не записан.");return end
 local skip=math.max(1,math.ceil(#route/65))
 for i=1,#route,skip do
  local p=asVector(route[i])
  local dot=Instance.new("Part")
  dot.Name="OX1DE_LakeWaypoint"
  dot.Shape=Enum.PartType.Ball
  dot.Anchored=true
  dot.CanCollide=false
  dot.CanTouch=false
  dot.CanQuery=false
  dot.Size=Vector3.new(1.2,1.2,1.2)
  dot.Material=Enum.Material.Neon
  dot.Color=i==1 and Color3.fromRGB(120,245,144) or C.accent
  dot.Transparency=.1
  dot.Position=p+Vector3.new(0,2,0)
  dot.Parent=workspace
  markers[#markers+1]=dot
 end
 setStatus("Показаны метки вдоль твоего маршрута.")
end
recordButton=button("●  Записать",19,195,218,48,recordToggle)
saveButton=button("↓  Сохранить",249,195,218,48,persist)
driveButton=button("▶ Автоезда",19,253,218,49,startDrive)
stopButton=button("■  Стоп",249,253,218,49,function()
 if recording then endRecord() end
 if driving then stopDrive("Автоезда остановлена.") end
end)
routeButton=button("◉  Показать путь",19,308,218,22,showRoute)
speedButton=button("Скорость: 55%",249,308,218,22,function()
 speedIndex=speedIndex%#speedOptions+1
 refresh()
end)
local runningConnection
runningConnection=listen(RunService.Heartbeat,function(dt)
 if not alive then return end
 -- VehicleSeat steering and throttle may reset to zero every frame.
 -- Refresh the last safe command every heartbeat; navigate less often.
 if driving and driveSeat and driveSeat.Parent then
  pcall(function()
   driveSeat.ThrottleFloat=lastThrottle
   driveSeat.SteerFloat=lastSteer
  end)
 end
 stepClock+=dt
 if stepClock<.12 then return end
 local delta=stepClock
 stepClock=0
 if recording then
  local seat=seatOf()
  if not seat or seat~=recordSeat then
   endRecord()
   setStatus("Запись остановлена: ты покинул квадроцикл.")
  else
   local pos=positionOf(seat)
   local prev=asVector(route[#route])
   local d=distance2d(pos,prev)
   if d>=7 then
    route[#route+1]=asPoint(pos)
    distanceDriven+=d
    if #route>=2500 then
     endRecord();setStatus("Достигнут лимит 2500 точек. Сохрани маршрут.")
    end
   end
  end
 end
 if driving then
  local seat=seatOf()
  if not seat or seat~=driveSeat then
   stopDrive("Автоезда остановлена: пересел на другое место.")
  else
   local pos=seat.Position
   local target=asVector(route[currentIndex])
   local dist=distance2d(pos,target)
   if dist>95 then
    stopDrive("Сошёл с маршрута на "..math.floor(dist).." studs. Остановлено.")
   else
    local motion=seat.AssemblyLinearVelocity.Magnitude
    local closeEnough=math.clamp(9+motion*.18,9,19)
    if dist<closeEnough then
     currentIndex=currentIndex%#route+1
     target=asVector(route[currentIndex])
     dist=distance2d(pos,target)
    end
    local flat=Vector3.new(target.X-pos.X,0,target.Z-pos.Z)
    if flat.Magnitude>=.1 then
     local heading=flat.Unit
     local right=Vector3.new(seat.CFrame.RightVector.X,0,seat.CFrame.RightVector.Z)
     local forward=Vector3.new(seat.CFrame.LookVector.X,0,seat.CFrame.LookVector.Z)
     local angle=math.atan2(heading:Dot(right),heading:Dot(forward))
     local steer=math.clamp(angle*1.55,-1,1)
     local throttle=speedOptions[speedIndex]
     if math.abs(angle)>1.0 then throttle=throttle*.45 end
     lastThrottle=throttle
     lastSteer=steer
     local ok=pcall(function()
      seat.ThrottleFloat=lastThrottle
      seat.SteerFloat=lastSteer
     end)
     if not ok then
      stopDrive("Trails не разрешил управление VehicleSeat из этого скрипта.")
     else
      local moved=distance2d(pos,lastPosition or pos)
      if moved<1.1 then stuckClock+=delta else stuckClock=0 end
      lastPosition=pos
      if stuckClock>7 then
       stopDrive("Нет движения: управление квадроцикла несовместимо или он застрял.")
      else
       setStatus(string.format("Автоезда: точка %d/%d • до неё %.0f studs",currentIndex,#route,dist))
      end
     end
    end
   end
  end
 end
 refresh()
end)
local function stopAll()
 if not alive then return end
 alive=false
 recording=false
 driving=false
 releaseSeat(driveSeat)
 cleanMarkers()
 for _,c in ipairs(connections) do pcall(function()c:Disconnect()end) end
 if gui then gui:Destroy() end
 if env.OX1DE_TRAILS_STOP==stopAll then env.OX1DE_TRAILS_STOP=nil end
 if _G.OX1DE_TRAILS_STOP==stopAll then _G.OX1DE_TRAILS_STOP=nil end
end
env.OX1DE_TRAILS_STOP=stopAll
_G.OX1DE_TRAILS_STOP=stopAll
listen(gui.Destroying,function()
 if alive then stopAll() end
end)
if type(readfile)=="function" and type(isfile)=="function" then
 local ok,data=pcall(function()
  if not isfile(pathFile) then return nil end
  return HttpService:JSONDecode(readfile(pathFile))
 end)
 if ok and type(data)=="table" and type(data.points)=="table" then
  local parsed={}
  for i,item in ipairs(data.points) do
   if i>2500 then break end
   if type(item)=="table" and type(item.x)=="number"
    and type(item.y)=="number" and type(item.z)=="number" then
    parsed[#parsed+1]={x=item.x,y=item.y,z=item.z}
   end
  end
  if #parsed>0 then
   route=parsed
   setStatus("Загружен маршрут из файла: "..#parsed.." точек.")
  end
 end
end
refresh()
print("[OX1DE Trails] Route recorder ready. Auto Drive requires a compatible VehicleSeat.")
