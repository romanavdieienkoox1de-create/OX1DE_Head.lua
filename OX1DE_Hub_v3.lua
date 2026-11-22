-- OX1DE Hub v2.6
-- UI matches OX1DE Hub screenshot series: Player / Visual / Combat / Setting.
-- RightShift: menu; E: Aim; X: Fly; Z: Noclip (rebindable in the UI).
-- Client-side local features; experience-specific server checks may limit effects.

local Players=game:GetService('Players')
local UIS=game:GetService('UserInputService')
local RS=game:GetService('RunService')
local TS=game:GetService('TweenService')
local Lighting=game:GetService('Lighting')
local CollectionService=game:GetService('CollectionService')
local LocalPlayer=Players.LocalPlayer
if not LocalPlayer then return end
local PG=LocalPlayer:WaitForChild('PlayerGui')
local G=(type(getgenv)=='function' and getgenv()) or _G
if type(G.OX1DE_CLEANUP)=='function' then pcall(G.OX1DE_CLEANUP) end
if type(G.OX1DE_HUB_CLEANUP)=='function' then pcall(G.OX1DE_HUB_CLEANUP) end
local oldV1=PG:FindFirstChild('OX1DE_Hub')
if oldV1 then oldV1:Destroy() end
for _,name in ipairs({'OX1DE_V2_UI','OX1DE_V2_FOV','OX1DE_V3_UI','OX1DE_V3_FOV'}) do
    local old=PG:FindFirstChild(name)
    if old then old:Destroy() end
end
local connections,pumpkinHighlights={}, {}
local oldCollision={}
local active=true
local flyBV,flyBG,flyAuto=nil,nil,nil
local mouseWasIcon,mouseWasBehavior=nil,nil
local waitingBind=nil
local beginFly,stopFly,restoreCollision
local menuOpen=true
local savedFocus=nil
local palette={bg=Color3.fromRGB(9,10,12),side=Color3.fromRGB(17,18,20),top=Color3.fromRGB(22,23,26),card=Color3.fromRGB(27,29,32),line=Color3.fromRGB(65,69,76),white=Color3.fromRGB(245,246,248),gray=Color3.fromRGB(157,164,175),dark=Color3.fromRGB(19,20,24),red=Color3.fromRGB(255,37,49),green=Color3.fromRGB(68,231,122),enemy=Color3.fromRGB(248,94,94)}
local state={Speed=16,Jump=50,Fly=false,Noclip=false,NameESP=false,DistanceESP=false,TeamVisual=false,SkeletonESP=false,OutlineESP=false,WeaponESP=false,ThroughWalls=false,PumpkinESP=false,Aim=false,WallCheck=false,TeamAim=false,AimPart='Head',AimSpeed=1,FOV=false,FOVRadius=190,Background='Dark',Shadows=false,Opacity=1,Preview=false}
local binds={Aim=Enum.KeyCode.E,Fly=Enum.KeyCode.X,Noclip=Enum.KeyCode.Z}
-- Keep settings across reinjections; persistent disk storage is optional and executor-dependent.
local HttpService=game:GetService('HttpService')
local settingsFile='OX1DE_Hub_settings.json'
local savePending=false
local allowedAimParts={Head=true,Body=true,Legs=true}
local allowedBackgrounds={Dark=true,Frost=true,Clear=true}
local numberRanges={Speed={8,100},Jump={20,120},AimSpeed={0,1},FOVRadius={40,400},Opacity={.2,1}}
local function importSettings(saved)
    if type(saved)~='table' then return end
    local savedState=type(saved.state)=='table' and saved.state or {}
    for k,current in pairs(state) do
        local v=savedState[k]
        if k~='Preview' and type(v)==type(current) then
            if type(v)=='boolean' then state[k]=v
            elseif type(v)=='number' and v==v then
                local limit=numberRanges[k]
                if limit then state[k]=math.clamp(v,limit[1],limit[2]) end
            elseif k=='AimPart' and allowedAimParts[v] then state[k]=v
            elseif k=='Background' and allowedBackgrounds[v] then state[k]=v end
        end
    end
    if type(saved.binds)=='table' then
        for action,_ in pairs(binds) do
            local name=saved.binds[action]
            if type(name)=='string' and name~='RightShift' and name~='Unknown' then
                local ok,key=pcall(function() return Enum.KeyCode[name] end)
                if ok and key then binds[action]=key end
            end
        end
    end
end
local stored
if type(readfile)=='function' then
    local ok,raw=pcall(readfile,settingsFile)
    if ok and type(raw)=='string' then
        local decoded,parsed=pcall(HttpService.JSONDecode,HttpService,raw)
        if decoded and type(parsed)=='table' then stored=parsed end
    end
end
if not stored and type(G.OX1DE_SETTINGS_CACHE)=='table' then stored=G.OX1DE_SETTINGS_CACHE end
importSettings(stored)
local function saveSettings()
    local data={state={},binds={}}
    for k,v in pairs(state) do if k~='Preview' then data.state[k]=v end end
    for action,key in pairs(binds) do data.binds[action]=key.Name end
    G.OX1DE_SETTINGS_CACHE=data
    if type(writefile)=='function' then
        local ok,encoded=pcall(HttpService.JSONEncode,HttpService,data)
        if ok then pcall(writefile,settingsFile,encoded) end
    end
end
local bindLabels={}
local teamColors=function(p)
    -- Team Check OFF always means neutral white; never infer a team color.
    if state.TeamVisual ~= true then return palette.white end
    if LocalPlayer.Team~=nil and p.Team~=nil and p.Team==LocalPlayer.Team then
        return palette.green
    end
    return palette.enemy
end
local function track(conn) connections[#connections+1]=conn return conn end
local function new(class,props,parent)
    local obj=Instance.new(class)
    for k,v in pairs(props or {}) do obj[k]=v end
    obj.Parent=parent
    return obj
end
local function round(obj,r) new('UICorner',{CornerRadius=UDim.new(0,r or 9)},obj) return obj end
local function border(obj,c,t) new('UIStroke',{Color=c or palette.line,Thickness=t or 1,Transparency=.15,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},obj) return obj end
local function tween(obj,props,duration)
    if not obj or not obj.Parent then return end
    local tw=TS:Create(obj,TweenInfo.new(duration or .2,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),props)
    tw:Play() return tw
end
local function label(parent,txt,x,y,w,h,size,color,bold)
    return new('TextLabel',{Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundTransparency=1,Text=txt,TextColor3=color or palette.white,Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,TextSize=size or 13,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd},parent)
end
-- Screenshot-matched interface: 1082 x 744 design canvas, centered and scaled.
local gui=new('ScreenGui',{Name='OX1DE_V3_UI',ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=100,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},PG)
local fovGui=new('ScreenGui',{Name='OX1DE_V3_FOV',ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=90,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},PG)
-- Remove leftover OX1DE visual overlays from previous script versions.
-- Old instances could remain even after the old menu was closed.
for _,item in ipairs(PG:GetDescendants()) do
    if item:IsA('BillboardGui') and item.Name=='OX1DE_Name_ESP' then
        item:Destroy()
    end
end
for _,item in ipairs(workspace:GetDescendants()) do
    if item.Name=='OX1DE_V3_ESP_Highlights' or item.Name=='OX1DE_Outline' then
        if item:IsA('Folder') or item:IsA('Highlight') then item:Destroy() end
    end
end
local highlightFolder=new('Folder',{Name='OX1DE_V3_ESP_Highlights'},workspace)
local circle=new('Frame',{Name='FOV_Red_Circle',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(state.FOVRadius*2,state.FOVRadius*2),BackgroundTransparency=1,BorderSizePixel=0,Visible=false},fovGui)
new('UICorner',{CornerRadius=UDim.new(1,0)},circle)
new('UIStroke',{Color=palette.red,Thickness=2.5,Transparency=0,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},circle)
local function refreshFOV()
    circle.Visible=state.FOV or state.Preview
    fovGui.DisplayOrder=state.Preview and 150 or 90
    tween(circle,{Size=UDim2.fromOffset(state.FOVRadius*2,state.FOVRadius*2)},.14)
end
local shadow=round(new('Frame',{Name='WindowShadow',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(.5,0,.5,15),Size=UDim2.fromOffset(1082,744),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=1,BorderSizePixel=0},gui),26)
local window=round(new('CanvasGroup',{Name='OX1DE_Hub_Window',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(1082,744),BackgroundColor3=palette.bg,BorderSizePixel=0,ClipsDescendants=true,GroupTransparency=0},gui),23)
border(window,Color3.fromRGB(89,93,99))
local winScale=new('UIScale',{Scale=1},window)
local shadowScale=new('UIScale',{Scale=1},shadow)
local function updateScale()
    local camera=workspace.CurrentCamera
    if not camera then return end
    local screen=camera.ViewportSize
    local scale=math.clamp(math.min((screen.X-30)/1082,(screen.Y-30)/744),.32,1)
    winScale.Scale=scale
    shadowScale.Scale=scale
end
local viewportConnection
local function cameraChanged()
    if viewportConnection then viewportConnection:Disconnect();viewportConnection=nil end
    local cam=workspace.CurrentCamera
    if cam then viewportConnection=track(cam:GetPropertyChangedSignal('ViewportSize'):Connect(updateScale)) end
    updateScale()
end
cameraChanged()
track(workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(cameraChanged))

-- Monochrome, native-UI vector icons; no external asset IDs to break.
local function vectorIcon(parent,kind,x,y,size,color)
    color=color or palette.white
    local h=new('Frame',{Name='Icon',Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(size,size),BackgroundTransparency=1,BorderSizePixel=0},parent)
    local k=size/24
    local function line(x1,y1,x2,y2,weight)
        local dx,dy=x2-x1,y2-y1
        local obj=new('Frame',{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset((x1+x2)*k/2,(y1+y2)*k/2),Size=UDim2.fromOffset(math.sqrt(dx*dx+dy*dy)*k,(weight or 1.9)*k),Rotation=math.deg(math.atan2(dy,dx)),BackgroundColor3=color,BorderSizePixel=0},h)
        round(obj,2)
    end
    local function oval(x,y,w,hh,thickness)
        local o=round(new('Frame',{Position=UDim2.fromOffset(x*k,y*k),Size=UDim2.fromOffset(w*k,hh*k),BackgroundTransparency=1,BorderSizePixel=0},h),math.floor(math.max(w,hh)*k/2))
        new('UIStroke',{Color=color,Thickness=(thickness or 1.9)*k,Transparency=0},o)
    end
    if kind=='player' or kind=='name' then
        oval(9,2,6,7)
        oval(5,13,14,10)
    elseif kind=='visual' then
        oval(2,7,20,11);oval(9,10,6,6)
    elseif kind=='combat' or kind=='aim' or kind=='fov' then
        oval(5,5,14,14);oval(10,10,4,4)
        line(12,0,12,5);line(12,19,12,24);line(0,12,5,12);line(19,12,24,12)
    elseif kind=='setting' then
        oval(5,5,14,14);oval(10,10,4,4)
        for i=0,7 do
            local a=i*math.pi/4
            line(12+9*math.cos(a),12+9*math.sin(a),12+12*math.cos(a),12+12*math.sin(a),2.4)
        end
    elseif kind=='speed' then
        oval(15,1,4,4)
        line(14,6,9,10);line(9,10,15,14);line(13,8,21,10)
        line(10,11,6,16);line(15,14,21,20);line(10,15,5,22)
    elseif kind=='jump' then
        line(12,23,12,5,2.3);line(12,5,6,11,2.3);line(12,5,18,11,2.3)
    elseif kind=='fly' then
        -- Feathered wing silhouette, with three separated feathers.
        line(3,14,12,7,2.6);line(12,7,22,4,2.6)
        line(4,14,6,20,2.7);line(6,20,14,15,2.7)
        line(14,15,19,10,2.5);line(6,17,13,12,1.6)
        line(8,20,13,19,1.6);line(13,19,17,15,1.6)
        line(12,8,18,6,1.5)
    elseif kind=='noclip' then
        -- Door frame with an opening and a forward motion arrow.
        line(4,22,4,3,2.5);line(4,3,20,3,2.5);line(20,3,20,22,2.5)
        line(4,22,10,22,2.3);line(19,22,20,22,2.3)
        line(8,14,17,14,2.4);line(17,14,13,10,2.4);line(17,14,13,18,2.4)
    elseif kind=='distance' then
        line(3,8,21,8);line(3,16,21,16);line(3,8,7,4);line(3,8,7,12);line(21,16,17,12);line(21,16,17,20)
    elseif kind=='team' then
        oval(4,3,6,7);oval(14,5,6,6);oval(1,14,13,9);oval(13,15,10,8)
    elseif kind=='skeleton' then
        oval(10,1,4,5);line(12,6,12,15);line(5,9,12,10);line(12,10,19,9);line(12,15,6,23);line(12,15,18,23)
    elseif kind=='outline' then
        oval(4,2,16,20);line(8,9,16,9);line(8,15,16,15)
    elseif kind=='weapon' then
        line(2,8,19,8,3);line(19,8,22,11,2);line(22,11,11,13,2);line(11,13,8,20,3);line(8,20,5,20,2);line(5,20,6,13,2)
    elseif kind=='wall' or kind=='background' then
        oval(2,4,20,16);line(2,12,22,12);line(9,4,9,12);line(16,12,16,20)
    elseif kind=='pumpkin' then
        -- Halloween lantern: lobes, curved stem, triangular eyes, smile.
        oval(2,7,20,15,2.3);oval(7,7,10,15,1.25)
        line(11,7,11,3,2.4);line(11,3,15,2,2)
        line(5,14,8,12,2);line(8,12,9,15,2)
        line(15,15,16,12,2);line(16,12,19,14,2)
        line(7,18,11,20,2);line(11,20,16,18,2)
    elseif kind=='opacity' then
        oval(5,5,14,17);line(12,2,5,13);line(12,2,19,13)
    elseif kind=='shadow' then
        oval(3,3,15,15);line(9,21,18,21);line(21,9,21,18)
    elseif kind=='key' then
        oval(1,6,22,13);for i=0,3 do line(5+i*4,10,6+i*4,10,2.3) end;line(6,15,18,15)
    else oval(5,5,14,14) end
    return h
end

local header=new('Frame',{Name='Header',Size=UDim2.new(1,0,0,83),BackgroundColor3=Color3.fromRGB(28,30,33),BorderSizePixel=0},window)
new('UIGradient',{Rotation=0,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(40,42,46)),ColorSequenceKeypoint.new(.48,Color3.fromRGB(16,17,19)),ColorSequenceKeypoint.new(1,Color3.fromRGB(26,28,31))})},header)
new('Frame',{Position=UDim2.new(0,0,1,-1),Size=UDim2.new(1,0,0,1),BackgroundColor3=palette.line,BorderSizePixel=0},header)
local logo=round(new('Frame',{Position=UDim2.fromOffset(31,23),Size=UDim2.fromOffset(38,38),Rotation=-12,BackgroundTransparency=1,BorderSizePixel=0},header),11)
new('UIStroke',{Color=palette.white,Thickness=2.2},logo)
local logoInner=round(new('Frame',{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(15,15),BackgroundTransparency=1,BorderSizePixel=0},logo),4)
new('UIStroke',{Color=palette.white,Thickness=3},logoInner)
label(header,'OX1DE Hub',84,19,250,46,25,palette.white,true)
local version=round(new('Frame',{Position=UDim2.fromOffset(241,31),Size=UDim2.fromOffset(49,22),BackgroundColor3=palette.top,BorderSizePixel=0},header),13)
border(version)
local vLabel=label(version,'V2.6',0,0,49,22,11,palette.gray,true);vLabel.TextXAlignment=Enum.TextXAlignment.Center
local function topButton(symbol,x)
    local btn=round(new('TextButton',{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,x,0,23),Size=UDim2.fromOffset(37,37),BackgroundColor3=palette.card,Text=symbol,TextColor3=palette.white,TextSize=18,Font=Enum.Font.GothamBold,AutoButtonColor=false,BorderSizePixel=0},header),10)
    border(btn)
    track(btn.MouseEnter:Connect(function()tween(btn,{BackgroundColor3=Color3.fromRGB(66,68,72)},.15)end))
    track(btn.MouseLeave:Connect(function()tween(btn,{BackgroundColor3=palette.card},.15)end))
    return btn
end
local minimize=topButton('−',-71)
local close=topButton('×',-29)
local sidebar=new('Frame',{Name='Navigation',Position=UDim2.fromOffset(0,83),Size=UDim2.new(0,252,1,-83),BackgroundColor3=palette.side,BorderSizePixel=0},window)
new('UIGradient',{Rotation=90,Color=ColorSequence.new(Color3.fromRGB(20,22,24),Color3.fromRGB(12,13,15))},sidebar)
new('Frame',{Position=UDim2.new(1,-1,0,0),Size=UDim2.new(0,1,1,0),BackgroundColor3=palette.line,BorderSizePixel=0},sidebar)
label(sidebar,'N A V I G A T I O N',31,26,195,20,10,palette.gray,true)
label(sidebar,'●  OX1DE HUB',29,567,180,17,11,palette.white,true)
label(sidebar,'RIGHT SHIFT — OPEN / CLOSE',29,587,202,15,9,palette.gray)
label(sidebar,'MONOCHROME UI / RED FOV',29,606,205,15,9,palette.gray)
local navKeys={'Player','Visual','Combat','Setting'}
local navIcons={Player='player',Visual='visual',Combat='combat',Setting='setting'}
local subtitles={Player='Character & movement',Visual='Display & highlights',Combat='Aim settings & FOV preview',Setting='Interface & controls'}
local navBtns={}
local content=new('Frame',{Position=UDim2.fromOffset(252,83),Size=UDim2.new(1,-252,1,-83),BackgroundTransparency=1},window)
local sectionIcon=vectorIcon(content,'player',30,23,28)
local title=label(content,'Player',71,16,390,42,27,palette.white,true)
local desc=label(content,subtitles.Player,31,58,510,20,12,palette.gray)
local previewBadge=round(new('Frame',{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-31,0,29),Size=UDim2.fromOffset(109,30),BackgroundColor3=palette.card,BorderSizePixel=0},content),16)
border(previewBadge)
local badgeTxt=label(previewBadge,'UI / PREVIEW',0,0,109,30,10,palette.white,true);badgeTxt.TextXAlignment=Enum.TextXAlignment.Center
local list=new('ScrollingFrame',{Name='PageRows',Position=UDim2.fromOffset(31,84),Size=UDim2.new(1,-62,1,-103),CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=palette.line,ScrollingDirection=Enum.ScrollingDirection.Y},content)
new('UIListLayout',{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},list)
new('UIPadding',{PaddingBottom=UDim.new(0,12)},list)
local pageConnections={}
local function pageTrack(c)pageConnections[#pageConnections+1]=c;return c end
local order=0
local function clearList()
    for _,c in ipairs(pageConnections) do pcall(function()c:Disconnect()end)end
    table.clear(pageConnections)
    for _,child in ipairs(list:GetChildren()) do
        if child:IsA('GuiObject') then child:Destroy() end
    end
    order=0
end
local function nextOrder()order=order+1;return order end
local function sectionText(text)
    local wrapper=new('Frame',{Size=UDim2.new(1,-4,0,14),BackgroundTransparency=1,LayoutOrder=nextOrder()},list)
    label(wrapper,string.upper(text),2,0,730,14,10,palette.gray,true)
end
local function row(icon,name,sub,height)
    local h=height or 54
    local card=round(new('Frame',{Size=UDim2.new(1,-5,0,h),BackgroundColor3=Color3.fromRGB(28,30,34),BorderSizePixel=0,LayoutOrder=nextOrder()},list),13)
    new('UIGradient',{Rotation=0,Color=ColorSequence.new(Color3.fromRGB(31,33,37),Color3.fromRGB(22,24,27))},card)
    border(card,Color3.fromRGB(92,95,103))
    local shine=new('Frame',{Name='HighlightLine',Size=UDim2.new(.92,0,0,1),Position=UDim2.fromScale(.04,0),BackgroundColor3=Color3.fromRGB(195,198,207),BackgroundTransparency=.82,BorderSizePixel=0},card)
    pageTrack(card.MouseEnter:Connect(function()
        tween(card,{BackgroundColor3=Color3.fromRGB(49,52,58)},.2)
        tween(shine,{BackgroundTransparency=.32},.2)
    end))
    pageTrack(card.MouseLeave:Connect(function()
        tween(card,{BackgroundColor3=Color3.fromRGB(28,30,34)},.2)
        tween(shine,{BackgroundTransparency=.82},.2)
    end))
    vectorIcon(card,icon,23,math.floor((h-30)/2),30)
    local yName=h>=85 and 9 or 8
    label(card,name,70,yName,380,21,14,palette.white,true)
    label(card,sub or '',70,yName+21,435,17,11,palette.gray)
    return card
end
local function makeToggle(card,key,callback,offset)
    local btn=round(new('TextButton',{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,offset or -17,.5,0),Size=UDim2.fromOffset(47,27),AutoButtonColor=false,Text='',BackgroundColor3=palette.line,BorderSizePixel=0},card),15)
    local dot=round(new('Frame',{Position=UDim2.fromOffset(4,4),Size=UDim2.fromOffset(19,19),BackgroundColor3=palette.white,BorderSizePixel=0},btn),12)
    local function refresh()
        local enabled=not not state[key]
        tween(btn,{BackgroundColor3=enabled and palette.white or Color3.fromRGB(62,65,71)},.17)
        tween(dot,{Position=UDim2.fromOffset(enabled and 24 or 4,4),BackgroundColor3=enabled and palette.bg or palette.white},.17)
    end
    pageTrack(btn.MouseButton1Click:Connect(function()
        state[key]=not state[key]
        refresh()
        if callback then callback(state[key])end
        saveSettings()
    end))
    refresh()
    return btn
end
local function bindButton(card,kind)
    local btn=round(new('TextButton',{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-76,.5,0),Size=UDim2.fromOffset(43,33),BackgroundColor3=palette.bg,Text=binds[kind].Name:upper(),TextColor3=palette.white,TextSize=13,Font=Enum.Font.GothamBold,AutoButtonColor=false,BorderSizePixel=0},card),9)
    border(btn,Color3.fromRGB(116,121,130))
    local hint=label(card,'KEY',0,0,36,16,9,palette.gray,true)
    hint.AnchorPoint=Vector2.new(1,.5)
    hint.Position=UDim2.new(1,-126,.5,0)
    bindLabels[kind]=btn
    pageTrack(btn.MouseButton1Click:Connect(function()
        waitingBind=kind
        btn.Text='...'
        tween(btn,{BackgroundColor3=Color3.fromRGB(65,70,78)},.16)
    end))
end
local function changeWalk()
    local char=LocalPlayer.Character
    local hum=char and char:FindFirstChildOfClass('Humanoid')
    if hum then
        hum.WalkSpeed=state.Speed
        if hum.UseJumpPower then hum.JumpPower=state.Jump else hum.JumpHeight=state.Jump/7 end
    end
end
local function addSlider(icon,name,sub,key,minimum,maximum,decimals,callback)
    local card=row(icon,name,sub,73)
    local value=round(new('TextLabel',{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-17,.5,0),Size=UDim2.fromOffset(45,30),BackgroundColor3=palette.bg,BorderSizePixel=0,TextColor3=palette.white,TextSize=12,Font=Enum.Font.GothamBold},card),8)
    border(value)
    local bar=round(new('TextButton',{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-79,.5,0),Size=UDim2.fromOffset(182,6),BackgroundColor3=Color3.fromRGB(79,83,89),BorderSizePixel=0,Text='',AutoButtonColor=false},card),4)
    local fill=round(new('Frame',{Size=UDim2.fromScale(0,1),BackgroundColor3=palette.white,BorderSizePixel=0},bar),4)
    local knob=round(new('Frame',{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(0,.5),Size=UDim2.fromOffset(15,15),BackgroundColor3=palette.white,BorderSizePixel=0},bar),9)
    local dragging=false
    local function set(v)
        local power=10^decimals
        state[key]=math.floor(math.clamp(v,minimum,maximum)*power+.5)/power
        local ratio=(state[key]-minimum)/(maximum-minimum)
        value.Text=decimals>0 and string.format('%.'..decimals..'f',state[key]) or tostring(math.floor(state[key]))
        fill.Size=UDim2.fromScale(ratio,1)
        knob.Position=UDim2.fromScale(ratio,.5)
        if callback then callback(state[key])end
        saveSettings()
    end
    local function fromX(x)
        set(minimum+(maximum-minimum)*math.clamp((x-bar.AbsolutePosition.X)/math.max(1,bar.AbsoluteSize.X),0,1))
    end
    pageTrack(bar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true;fromX(i.Position.X)end
    end))
    pageTrack(UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch)then fromX(i.Position.X)end
    end))
    pageTrack(UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end))
    set(state[key])
    return card
end
local function switchRow(icon,name,info,key,bind,callback)
    local card=row(icon,name,info,54)
    if bind then bindButton(card,bind)end
    makeToggle(card,key,callback)
    return card
end
local function choiceRow(icon,name,info,choices,key,callback)
    local card=row(icon,name,info,54)
    local holders={}
    local choiceWidth=key=='AimPart' and 80 or 76
    local total=#choices*(choiceWidth+3)+6
    local bg=round(new('Frame',{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-17,.5,0),Size=UDim2.fromOffset(total,39),BackgroundColor3=palette.bg,BorderSizePixel=0},card),10)
    border(bg)
    for i,text in ipairs(choices)do
        local btn=round(new('TextButton',{Position=UDim2.fromOffset(3+(i-1)*(choiceWidth+3),3),Size=UDim2.fromOffset(choiceWidth,33),BackgroundColor3=palette.bg,Text=text,TextSize=12,Font=Enum.Font.GothamBold,TextColor3=palette.gray,BorderSizePixel=0,AutoButtonColor=false},bg),8)
        holders[i]=btn
        pageTrack(btn.MouseButton1Click:Connect(function()
            state[key]=text
            for _,b in ipairs(holders)do
                local selected=b.Text==text
                tween(b,{BackgroundColor3=selected and palette.white or palette.bg,TextColor3=selected and palette.bg or palette.gray},.17)
            end
            if callback then callback(text)end
            saveSettings()
        end))
    end
    for _,b in ipairs(holders)do
        local selected=b.Text==state[key]
        b.BackgroundColor3=selected and palette.white or palette.bg
        b.TextColor3=selected and palette.bg or palette.gray
    end
    return card
end
local currentPage='Player'
local function setMenuPage(page)
    if not active then return end
    currentPage=page
    if page~='Combat' and state.Preview then state.Preview=false;refreshFOV()end
    clearList()
    for key,btn in pairs(navBtns)do
        local selected=key==page
        tween(btn,{BackgroundColor3=selected and palette.white or palette.card},.24)
        local txt=btn:FindFirstChild('Text')
        if txt then txt.TextColor3=selected and palette.bg or palette.white end
        local iconHolder=btn:FindFirstChild('Vector')
        if iconHolder then
            -- Icons are redrawn on page change to keep a crisp, matching monochrome line weight.
            iconHolder:Destroy()
        end
        local holder=vectorIcon(btn,navIcons[key],17,19,27,selected and palette.bg or palette.white)
        holder.Name='Vector'
    end
    if sectionIcon then sectionIcon:Destroy()end
    sectionIcon=vectorIcon(content,navIcons[page],30,23,28)
    title.Text=page
    desc.Text=subtitles[page]
    list.CanvasPosition=Vector2.zero
    if page=='Player' then
        sectionText('Movement')
        addSlider('speed','Walk Speed','Adjust your movement speed.','Speed',8,100,0,changeWalk)
        addSlider('jump','Jump Height','Adjust your jump height.','Jump',20,120,0,changeWalk)
        sectionText('Movement modes')
        switchRow('fly','Fly','Toggle flight mode.','Fly','Fly',function(on)if on then beginFly()else stopFly()end end)
        switchRow('noclip','Noclip','Toggle collision bypass.','Noclip','Noclip',function(on)if not on then restoreCollision()end end)
    elseif page=='Visual' then
        sectionText('Player labels')
        switchRow('name','Name ESP','Display name and @username, on separate lines.','NameESP')
        switchRow('distance','Distance ESP','Show distance to players.','DistanceESP')
        switchRow('team','Team Check','Teammates green · opponents red.','TeamVisual')
        sectionText('Character display')
        switchRow('skeleton','Skeleton ESP','Character joint lines for R6 / R15.','SkeletonESP')
        switchRow('outline','Outline ESP','Soft white outline around characters.','OutlineESP')
        switchRow('weapon','Weapon ESP','Show equipped tool or weapon name.','WeaponESP')
        switchRow('wall','Through Walls','Display overlays behind obstacles.','ThroughWalls')
        sectionText('Halloween · temporary')
        switchRow('pumpkin','Pumpkin ESP','Highlight detected pumpkins in the map.','PumpkinESP')
    elseif page=='Combat' then
        sectionText('Aim controls')
        switchRow('aim','Enable Aim','Aim toggle with editable keybind.','Aim','Aim')
        switchRow('wall','Wall Check','Do not select targets behind walls.','WallCheck')
        switchRow('team','Team Check','Exclude teammates from targeting.','TeamAim')
        choiceRow('combat','Aim Part','Choose a character target area.',{'Head','Body','Legs'},'AimPart')
        sectionText('Precision')
        addSlider('speed','Aim Speed','0 — smooth    ·    1 — instant','AimSpeed',0,1,2)
        local fovRow=row('fov','FOV Radius','Red circle on game screen.',88)
        local previewHint=label(fovRow,'Preview appears over the menu',70,59,310,16,10,palette.red,true)
        makeToggle(fovRow,'FOV',refreshFOV,-353)
        local value=round(new('TextLabel',{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-124,.5,0),Size=UDim2.fromOffset(45,30),BackgroundColor3=palette.bg,TextColor3=palette.white,Font=Enum.Font.GothamBold,TextSize=12,BorderSizePixel=0},fovRow),8)
        border(value)
        local bar=round(new('TextButton',{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-187,.5,0),Size=UDim2.fromOffset(116,6),BackgroundColor3=palette.line,BorderSizePixel=0,Text='',AutoButtonColor=false},fovRow),4)
        local fill=round(new('Frame',{BackgroundColor3=palette.white,Size=UDim2.fromScale(0,1),BorderSizePixel=0},bar),4)
        local knob=round(new('Frame',{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(0,.5),Size=UDim2.fromOffset(14,14),BackgroundColor3=palette.white,BorderSizePixel=0},bar),8)
        local function setRadius(v)
            state.FOVRadius=math.floor(math.clamp(v,40,400)+.5)
            local ratio=(state.FOVRadius-40)/360
            fill.Size=UDim2.fromScale(ratio,1)
            knob.Position=UDim2.fromScale(ratio,.5)
            value.Text=tostring(state.FOVRadius)
            if state.Preview or state.FOV then refreshFOV()end
            saveSettings()
        end
        local drag=false
        pageTrack(bar.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=true;setRadius(40+360*math.clamp((i.Position.X-bar.AbsolutePosition.X)/math.max(1,bar.AbsoluteSize.X),0,1))end end))
        pageTrack(UIS.InputChanged:Connect(function(i)if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch)then setRadius(40+360*math.clamp((i.Position.X-bar.AbsolutePosition.X)/math.max(1,bar.AbsoluteSize.X),0,1))end end))
        pageTrack(UIS.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end end))
        setRadius(state.FOVRadius)
        local btn=round(new('TextButton',{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-15,.5,0),Size=UDim2.fromOffset(96,31),BackgroundColor3=palette.bg,Text='PREVIEW ◯',TextColor3=palette.red,TextSize=11,Font=Enum.Font.GothamBold,AutoButtonColor=false,BorderSizePixel=0},fovRow),9)
        border(btn,palette.red)
        pageTrack(btn.MouseButton1Click:Connect(function()
            state.Preview=not state.Preview
            btn.Text=state.Preview and 'HIDE ◯' or 'PREVIEW ◯'
            refreshFOV()
        end))
    elseif page=='Setting' then
        sectionText('Appearance')
        choiceRow('background','Background','Choose the menu backdrop.',{'Dark','Frost','Clear'},'Background',function()if _G.OX1DE_BG_REFRESH then _G.OX1DE_BG_REFRESH()end end)
        switchRow('shadow','Shadows','Soft shadows around the menu window.','Shadows',nil,function(yes)shadow.Visible=menuOpen and yes end)
        addSlider('opacity','Opacity','Adjust menu transparency.','Opacity',.6,1,2,function()if menuOpen then tween(window,{GroupTransparency=1-state.Opacity},.15)end end)
        sectionText('Controls')
        local r=row('key','Menu Key','Open / close the menu.',62)
        local btn=round(new('TextLabel',{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-16,.5,0),Size=UDim2.fromOffset(100,33),BackgroundColor3=palette.bg,Text='RightShift',TextColor3=palette.white,TextSize=12,Font=Enum.Font.GothamBold,BorderSizePixel=0},r),9)
        border(btn)
        local r2=row('player','Cursor Behavior','Restore original game cursor on close.',62)
        local pill=round(new('TextLabel',{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-16,.5,0),Size=UDim2.fromOffset(109,28),BackgroundColor3=palette.bg,Text='AUTO RESTORE',TextColor3=palette.gray,TextSize=10,Font=Enum.Font.GothamBold,BorderSizePixel=0},r2),12)
        border(pill)
    end
end
for i,page in ipairs(navKeys)do
    local btn=round(new('TextButton',{Name=page,Position=UDim2.fromOffset(16,62+(i-1)*77),Size=UDim2.fromOffset(221,66),BackgroundColor3=palette.card,BorderSizePixel=0,Text='',AutoButtonColor=false},sidebar),13)
    border(btn,Color3.fromRGB(69,73,80))
    local titleLabel=label(btn,page,56,18,130,31,15,palette.white,true);titleLabel.Name='Text'
    local arrow=label(btn,'›',193,15,22,34,26,palette.gray,true);arrow.TextXAlignment=Enum.TextXAlignment.Center
    navBtns[page]=btn
    track(btn.MouseEnter:Connect(function()
        if currentPage~=page then tween(btn,{BackgroundColor3=Color3.fromRGB(63,65,72)},.17) end
    end))
    track(btn.MouseLeave:Connect(function()
        if currentPage~=page then tween(btn,{BackgroundColor3=palette.card},.17) end
    end))
    track(btn.MouseButton1Click:Connect(function()setMenuPage(page)end))
end
setMenuPage('Player')
-- Built-in menu transitions, no separate Animations setting.
local blur=new('BlurEffect',{Name='OX1DE_V3_Blur',Enabled=false,Size=9},Lighting)
local function applyBackground()
    if not active then return end
    blur.Enabled=menuOpen and state.Background=='Frost'
    if state.Background=='Clear' then
        window.BackgroundColor3=Color3.fromRGB(16,17,19)
        window.BackgroundTransparency=.18
    else
        window.BackgroundColor3=palette.bg
        window.BackgroundTransparency=0
    end
end
_G.OX1DE_BG_REFRESH=applyBackground
local toggleInProgress=false
local originalInputCaptured=false
local function setMenu(open)
    if not active then return end
    menuOpen=open
    if not open then state.Preview=false; refreshFOV() end
    applyBackground()
    if open then
        if not originalInputCaptured then
            mouseWasIcon=UIS.MouseIconEnabled
            mouseWasBehavior=UIS.MouseBehavior
            originalInputCaptured=true
        end
        UIS.MouseBehavior=Enum.MouseBehavior.Default
        UIS.MouseIconEnabled=true
        window.Visible=true
        shadow.Visible=false
        window.GroupTransparency=1
        tween(window,{GroupTransparency=1-state.Opacity,Position=UDim2.new(.5,0,.5,0)},.23)
        tween(winScale,{Scale=math.clamp(winScale.Scale, .4,1.08)},.2)
        shadow.BackgroundTransparency=1
        shadow.BackgroundTransparency=1
    else
        blur.Enabled=false
        tween(window,{GroupTransparency=1,Position=UDim2.new(.5,0,.5,12)},.2)
        tween(shadow,{BackgroundTransparency=1},.2)
        task.delay(.2,function()
            if active and not menuOpen then window.Visible=false;shadow.Visible=false end
        end)
        -- Restore game-side mouse control without retaining a GUI cursor lock.
        task.defer(function()
            if active and not menuOpen then
                if mouseWasBehavior~=nil then UIS.MouseBehavior=mouseWasBehavior end
                if mouseWasIcon~=nil then UIS.MouseIconEnabled=mouseWasIcon end
            end
        end)
    end
end
track(minimize.MouseButton1Click:Connect(function()setMenu(false)end))
track(close.MouseButton1Click:Connect(function()setMenu(false)end))
-- Draggable title bar, supports mouse and touch.
local dragging,dragStart,startPos=false,nil,nil
track(header.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        dragging=true;dragStart=i.Position;startPos=window.Position
    end
end))
track(UIS.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        local v=i.Position-dragStart
        window.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+v.X,startPos.Y.Scale,startPos.Y.Offset+v.Y)
        shadow.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+v.X,startPos.Y.Scale,startPos.Y.Offset+v.Y+10)
    end
end))
track(UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end
end))

stopFly=function()
    if flyBV then flyBV:Destroy() flyBV=nil end
    if flyBG then flyBG:Destroy() flyBG=nil end
    local char=LocalPlayer.Character
    local hum=char and char:FindFirstChildOfClass('Humanoid')
    if hum and flyAuto~=nil then hum.AutoRotate=flyAuto end
    flyAuto=nil
end
beginFly=function()
    stopFly()
    local char=LocalPlayer.Character
    local root=char and char:FindFirstChild('HumanoidRootPart')
    local hum=char and char:FindFirstChildOfClass('Humanoid')
    if not root or not hum then state.Fly=false return end
    flyAuto=hum.AutoRotate;hum.AutoRotate=false
    flyBV=new('BodyVelocity',{Name='OX1DE_V3_Velocity',Velocity=Vector3.zero,MaxForce=Vector3.new(1e8,1e8,1e8),P=12500},root)
    flyBG=new('BodyGyro',{Name='OX1DE_V3_Orientation',MaxTorque=Vector3.new(1e8,1e8,1e8),P=13500,CFrame=workspace.CurrentCamera.CFrame},root)
end
restoreCollision=function()
    for part,val in pairs(oldCollision) do
        if part and part.Parent then pcall(function() part.CanCollide=val end) end
    end
    table.clear(oldCollision)
end
local function toggleFeature(k)
    state[k]=not state[k]
    saveSettings()
    if k=='Fly' then if state.Fly then beginFly() else stopFly() end end
    if k=='Noclip' and not state.Noclip then restoreCollision() end
    -- Refresh the currently displayed page so the switches reflect hotkeys.
    setMenuPage(currentPage or 'Player')
end
track(LocalPlayer.CharacterAdded:Connect(function()
    stopFly();restoreCollision()
    task.wait(.6)
    if not active then return end
    changeWalk()
    if state.Fly then beginFly() end
end))
track(UIS.InputBegan:Connect(function(input,gameProcessed)
    if not active or UIS:GetFocusedTextBox() then return end
    if input.UserInputType~=Enum.UserInputType.Keyboard then return end
    local key=input.KeyCode
    if waitingBind then
        local which=waitingBind
        waitingBind=nil
        if key~=Enum.KeyCode.Escape and key~=Enum.KeyCode.RightShift and key~=Enum.KeyCode.Unknown then
            binds[which]=key
            saveSettings()
        end
        local b=bindLabels[which]
        if b and b.Parent then
            b.Text=binds[which].Name:upper()
            tween(b,{BackgroundColor3=palette.bg},.12)
        end
        return
    end
    if key~=Enum.KeyCode.RightShift and gameProcessed then return end
    if key==Enum.KeyCode.RightShift then
        setMenu(not menuOpen)
        return
    end
    for action,bind in pairs(binds) do
        if key==bind then toggleFeature(action) break end
    end
end))
track(RS.Heartbeat:Connect(function(dt)
    if not active then return end
    if state.Noclip then
        local char=LocalPlayer.Character
        if char then
            for _,part in ipairs(char:GetDescendants()) do
                if part:IsA('BasePart') and part.CanCollide then
                    if oldCollision[part]==nil then oldCollision[part]=part.CanCollide end
                    part.CanCollide=false
                end
            end
        end
    end
end))
-- ESP overlays: player name/username, tool, distance, highlights, and skeleton lines.
local playerRecords={}
local skeletonLinksR15={
 {'Head','UpperTorso'},{'UpperTorso','LowerTorso'},
 {'UpperTorso','LeftUpperArm'},{'LeftUpperArm','LeftLowerArm'},{'LeftLowerArm','LeftHand'},
 {'UpperTorso','RightUpperArm'},{'RightUpperArm','RightLowerArm'},{'RightLowerArm','RightHand'},
 {'LowerTorso','LeftUpperLeg'},{'LeftUpperLeg','LeftLowerLeg'},{'LeftLowerLeg','LeftFoot'},
 {'LowerTorso','RightUpperLeg'},{'RightUpperLeg','RightLowerLeg'},{'RightLowerLeg','RightFoot'},
}
local skeletonLinksR6={{'Head','Torso'},{'Torso','Left Arm'},{'Torso','Right Arm'},{'Torso','Left Leg'},{'Torso','Right Leg'}}
local function isTeammate(p)
    return LocalPlayer.Team~=nil and p.Team~=nil and p.Team==LocalPlayer.Team
end
local function visiblePoint(part,char)
    if not part or not char then return false end
    local camera=workspace.CurrentCamera
    if not camera then return false end
    local origin=camera.CFrame.Position
    local delta=part.Position-origin
    if delta.Magnitude<.02 then return true end
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances={LocalPlayer.Character or camera}
    params.IgnoreWater=true
    local hit=workspace:Raycast(origin,delta,params)
    return not hit or hit.Instance:IsDescendantOf(char)
end
local function removeRecord(p)
    local rec=playerRecords[p]
    if not rec then return end
    if rec.bill then rec.bill:Destroy() end
    if rec.hi then rec.hi:Destroy() end
    for _,f in ipairs(rec.lines or {}) do f:Destroy() end
    playerRecords[p]=nil
end
local function ensureRecord(p)
    local char=p.Character
    local hum=char and char:FindFirstChildOfClass('Humanoid')
    local head=char and char:FindFirstChild('Head')
    if not char or not head or not hum or hum.Health<=0 then removeRecord(p) return end
    local rec=playerRecords[p]
    if rec and rec.char~=char then removeRecord(p);rec=nil end
    if rec then return rec end
    rec={char=char,lines={}}
    local bill=new('BillboardGui',{Name='OX1DE_Name_ESP',Adornee=head,AlwaysOnTop=true,Size=UDim2.fromOffset(198,67),StudsOffsetWorldSpace=Vector3.new(0,2.1,0),Enabled=false},PG)
    rec.bill=bill
    rec.name=label(bill,'',0,0,198,20,13,palette.white,true)
    rec.name.TextXAlignment=Enum.TextXAlignment.Center
    rec.user=label(bill,'',0,19,198,18,11,palette.gray,false)
    rec.user.TextXAlignment=Enum.TextXAlignment.Center
    rec.info=label(bill,'',0,38,198,20,11,palette.gray,true)
    rec.info.TextXAlignment=Enum.TextXAlignment.Center
    rec.hi=new('Highlight',{Name='OX1DE_Outline',Adornee=char,Enabled=false,FillTransparency=1,OutlineTransparency=.20,OutlineColor=palette.white,DepthMode=Enum.HighlightDepthMode.Occluded},highlightFolder)
    local links=hum.RigType==Enum.HumanoidRigType.R15 and skeletonLinksR15 or skeletonLinksR6
    for i=1,#links do
        local line=new('Frame',{Name='Bone'..i,AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(1,2),BackgroundColor3=palette.white,BorderSizePixel=0,Visible=false},fovGui)
        rec.lines[i]=line
    end
    playerRecords[p]=rec
    return rec
end
local function drawSkeleton(p,rec)
    local camera=workspace.CurrentCamera
    local char=rec.char
    local hum=char:FindFirstChildOfClass('Humanoid')
    local links=hum and hum.RigType==Enum.HumanoidRigType.R15 and skeletonLinksR15 or skeletonLinksR6
    local ok=state.SkeletonESP and char and char.Parent~=nil
    for i,ln in ipairs(rec.lines) do
        local a=char:FindFirstChild(links[i][1]);local b=char:FindFirstChild(links[i][2])
        if ok and a and b and camera then
            local aa,va=camera:WorldToViewportPoint(a.Position)
            local bb,vb=camera:WorldToViewportPoint(b.Position)
            if va and vb and aa.Z>0 and bb.Z>0 then
                local dx=bb.X-aa.X;local dy=bb.Y-aa.Y
                ln.Visible=true;ln.Position=UDim2.fromOffset((aa.X+bb.X)/2,(aa.Y+bb.Y)/2)
                ln.Size=UDim2.fromOffset(math.sqrt(dx*dx+dy*dy),2)
                ln.Rotation=math.deg(math.atan2(dy,dx))
                ln.BackgroundColor3=teamColors(p)
            else ln.Visible=false end
        else ln.Visible=false end
    end
end
local function pumpkinCandidate(obj)
    if not obj:IsA('Model') and not obj:IsA('BasePart') then return false end
    if string.find(string.lower(obj.Name),'pumpkin',1,true) then return true end
    return CollectionService:HasTag(obj,'Pumpkin')
end
local function addPumpkin(obj)
    if not pumpkinCandidate(obj) or pumpkinHighlights[obj] then return end
    pumpkinHighlights[obj]=new('Highlight',{Name='OX1DE_Pumpkin_ESP',Adornee=obj,Enabled=state.PumpkinESP,FillColor=palette.white,FillTransparency=.78,OutlineColor=palette.white,OutlineTransparency=.1,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop},highlightFolder)
end
-- Find Halloween objects already in the world and include future spawned ones.
task.spawn(function()
    for n,obj in ipairs(workspace:GetDescendants()) do
        if not active then break end
        if pumpkinCandidate(obj) then addPumpkin(obj) end
        if n%400==0 then task.wait() end
    end
end)
track(workspace.DescendantAdded:Connect(function(obj)
    if active and pumpkinCandidate(obj) then addPumpkin(obj) end
end))
track(CollectionService:GetInstanceAddedSignal('Pumpkin'):Connect(function(obj)
    if active then addPumpkin(obj) end
end))
local espTimer=0
track(RS.RenderStepped:Connect(function(dt)
    if not active then return end
    if state.Fly and flyBV and flyBG and flyBV.Parent and workspace.CurrentCamera then
        local camera=workspace.CurrentCamera
        local direction=Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then direction=direction+camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then direction=direction-camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then direction=direction+camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then direction=direction-camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then direction=direction+Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then direction=direction-Vector3.new(0,1,0) end
        flyBV.Velocity=direction.Magnitude>0 and direction.Unit*48 or Vector3.zero
        flyBG.CFrame=camera.CFrame
    end
    if state.SkeletonESP then
        for p,rec in pairs(playerRecords) do
            if rec.char and rec.char.Parent then drawSkeleton(p,rec) end
        end
    else
        for _,rec in pairs(playerRecords) do
            for _,line in ipairs(rec.lines) do line.Visible=false end
        end
    end
    espTimer=espTimer+dt
    if espTimer<.20 then return end
    espTimer=0
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer then
            local any=state.NameESP or state.DistanceESP or state.WeaponESP or state.OutlineESP or state.SkeletonESP
            if any then
                local rec=ensureRecord(p)
                if rec then
                    local char=rec.char
                    local root=char:FindFirstChild('HumanoidRootPart')
                    local localRoot=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
                    local cameraRoot=workspace.CurrentCamera
                    local origin=localRoot and localRoot.Position or (cameraRoot and cameraRoot.CFrame.Position)
                    local distance=root and origin and math.floor((root.Position-origin).Magnitude+.5) or nil
                    local tool=char:FindFirstChildOfClass('Tool')
                    rec.name.Text=p.DisplayName
                    rec.user.Text='@'..p.Name
                    local info={}
                    if state.DistanceESP and distance then info[#info+1]=tostring(distance)..'m' end
                    if state.WeaponESP and tool then info[#info+1]=tool.Name end
                    rec.info.Text=table.concat(info,'  •  ')
                    local charRoot=root or char:FindFirstChild('Head')
                    local visible=state.ThroughWalls or visiblePoint(charRoot,char)
                    rec.bill.Enabled=(state.ThroughWalls or visible or state.DistanceESP) and (state.NameESP or #info>0)
                    rec.name.Visible=state.NameESP
                    rec.user.Visible=state.NameESP
                    rec.name.TextColor3=teamColors(p)
                    rec.user.TextColor3=state.TeamVisual and teamColors(p) or palette.white
                    rec.info.TextColor3=state.TeamVisual and teamColors(p) or palette.white
                    rec.hi.Enabled=state.OutlineESP and visible
                    rec.hi.OutlineColor=teamColors(p)
                    rec.hi.DepthMode=state.ThroughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
                end
            else removeRecord(p) end
        end
    end
    for obj,hi in pairs(pumpkinHighlights) do
        if not obj.Parent or not hi.Parent then
            if hi.Parent then hi:Destroy() end
            pumpkinHighlights[obj]=nil
        else
            hi.Enabled=state.PumpkinESP
        end
    end
end))
track(Players.PlayerRemoving:Connect(removeRecord))

-- Camera-based aim-assist for client-side testing. Respects FOV / wall / team settings.
local function targetPart(char)
    if state.AimPart=='Head' then return char:FindFirstChild('Head') end
    if state.AimPart=='Legs' then
        return char:FindFirstChild('LeftFoot') or char:FindFirstChild('Left Leg') or char:FindFirstChild('LeftLowerLeg')
    end
    return char:FindFirstChild('UpperTorso') or char:FindFirstChild('Torso') or char:FindFirstChild('HumanoidRootPart')
end
RS:BindToRenderStep('OX1DE_V3_Aim',Enum.RenderPriority.Camera.Value+5,function(dt)
    if not active or not state.Aim or menuOpen then return end
    -- Aim activates directly with the Aim toggle (default E); no right mouse required.
    local cam=workspace.CurrentCamera
    if not cam then return end
    local midpoint=cam.ViewportSize/2
    local closest,closestDistance=nil,state.FOVRadius
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer and (not state.TeamAim or not isTeammate(p)) then
            local char=p.Character
            local hum=char and char:FindFirstChildOfClass('Humanoid')
            local part=char and targetPart(char)
            if hum and hum.Health>0 and part then
                local v,onScreen=cam:WorldToViewportPoint(part.Position)
                if onScreen and v.Z>0 then
                    local gap=(Vector2.new(v.X,v.Y)-midpoint).Magnitude
                    if gap<closestDistance and (not state.WallCheck or visiblePoint(part,char)) then
                        closest=part;closestDistance=gap
                    end
                end
            end
        end
    end
    if closest then
        local goal=CFrame.lookAt(cam.CFrame.Position,closest.Position)
        local smoothing=math.clamp(state.AimSpeed,0,1)
        local alpha=smoothing>=.995 and 1 or (0.04+math.pow(smoothing,2)*.96)
        cam.CFrame=cam.CFrame:Lerp(goal,alpha)
    end
end)

local function cleanup()
    if not active then return end
    saveSettings()
    active=false
    pcall(function() RS:UnbindFromRenderStep('OX1DE_V3_Aim') end)
    stopFly();restoreCollision()
    for _,c in ipairs(pageConnections) do pcall(function()c:Disconnect()end) end
    for _,c in ipairs(connections) do pcall(function()c:Disconnect()end) end
    if viewportConnection then pcall(function()viewportConnection:Disconnect()end) end
    for p,_ in pairs(playerRecords) do removeRecord(p) end
    for obj,hi in pairs(pumpkinHighlights) do hi:Destroy();pumpkinHighlights[obj]=nil end
    if mouseWasIcon~=nil then UIS.MouseIconEnabled=mouseWasIcon end
    if mouseWasBehavior~=nil then UIS.MouseBehavior=mouseWasBehavior end
    if blur then blur:Destroy()end
    if gui then gui:Destroy()end
    if fovGui then fovGui:Destroy()end
    if highlightFolder then highlightFolder:Destroy()end
    if _G.OX1DE_BG_REFRESH==applyBackground then _G.OX1DE_BG_REFRESH=nil end
end
G.OX1DE_CLEANUP=cleanup
G.OX1DE_HUB_CLEANUP=cleanup
applyBackground()
refreshFOV()
changeWalk()
if state.Fly then task.defer(function() if active then beginFly() end end) end
window.Position=UDim2.new(.5,0,.5,15)
window.GroupTransparency=1
shadow.BackgroundTransparency=1
setMenu(true)