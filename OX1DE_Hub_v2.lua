-- OX1DE Hub v2.0
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
for _,name in ipairs({'OX1DE_V2_UI','OX1DE_V2_FOV'}) do
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
local state={Speed=16,Jump=50,Fly=false,Noclip=false,NameESP=false,DistanceESP=false,TeamVisual=false,SkeletonESP=false,OutlineESP=false,WeaponESP=false,ThroughWalls=false,PumpkinESP=false,Aim=false,WallCheck=true,TeamAim=true,AimPart='Head',AimSpeed=.25,FOV=false,FOVRadius=190,Background='Dark',Shadows=true,Opacity=1,Preview=false}
local binds={Aim=Enum.KeyCode.E,Fly=Enum.KeyCode.X,Noclip=Enum.KeyCode.Z}
local bindLabels={}
local teamColors=function(p)
    if state.TeamVisual then
        if LocalPlayer.Team~=nil and p.Team==LocalPlayer.Team then return palette.green end
        return palette.enemy
    end
    return palette.white
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
local gui=new('ScreenGui',{Name='OX1DE_V2_UI',ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=100,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},PG)
local fovGui=new('ScreenGui',{Name='OX1DE_V2_FOV',ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=90,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},PG)
local highlightFolder=new('Folder',{Name='OX1DE_V2_ESP_Highlights'},workspace)
local circle=new('Frame',{Name='FOV_Red_Circle',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(state.FOVRadius*2,state.FOVRadius*2),BackgroundTransparency=1,BorderSizePixel=0,Visible=true},fovGui)
new('UICorner',{CornerRadius=UDim.new(1,0)},circle)
new('UIStroke',{Color=palette.red,Thickness=2,Transparency=.06,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},circle)
local function refreshFOV()
    circle.Visible=state.FOV or state.Preview
    fovGui.DisplayOrder=state.Preview and 120 or 90
    tween(circle,{Size=UDim2.fromOffset(state.FOVRadius*2,state.FOVRadius*2)},.15)
end
local shadow=round(new('Frame',{Name='WindowShadow',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(.5,0,.5,10),Size=UDim2.fromOffset(928,650),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.57,BorderSizePixel=0},gui),23)
local window=round(new('CanvasGroup',{Name='OX1DE_Hub_v2_Window',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(910,632),BackgroundColor3=palette.bg,BorderSizePixel=0,ClipsDescendants=true,GroupTransparency=0},gui),19)
border(window,palette.line)
local winScale=new('UIScale',{Scale=1},window)
local shadowScale=new('UIScale',{Scale=1},shadow)
local function updateScale()
    local camera=workspace.CurrentCamera
    if not camera then return end
    local s=camera.ViewportSize
    local scale=math.clamp(math.min((s.X-20)/930,(s.Y-20)/652),.4,1.08)
    winScale.Scale=scale;shadowScale.Scale=scale
end
local viewportConnection
local function cameraChanged()
    if viewportConnection then viewportConnection:Disconnect() end
    local cam=workspace.CurrentCamera
    if cam then viewportConnection=track(cam:GetPropertyChangedSignal('ViewportSize'):Connect(updateScale)) end
    updateScale()
end
cameraChanged()
track(workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(cameraChanged))
local header=new('Frame',{Name='Header',Size=UDim2.new(1,0,0,69),BackgroundColor3=palette.top,BorderSizePixel=0},window)
new('Frame',{Position=UDim2.new(0,0,1,-1),Size=UDim2.new(1,0,0,1),BackgroundColor3=palette.line,BorderSizePixel=0},header)
local logo=round(new('Frame',{Position=UDim2.fromOffset(25,17),Size=UDim2.fromOffset(35,35),Rotation=-10,BackgroundColor3=palette.white,BorderSizePixel=0},header),9)
round(new('Frame',{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(15,15),BackgroundColor3=palette.top,BorderSizePixel=0},logo),4)
label(header,'OX1DE Hub',72,14,205,43,25,palette.white,true)
round(new('Frame',{Position=UDim2.fromOffset(222,25),Size=UDim2.fromOffset(44,21),BackgroundColor3=palette.card,BorderSizePixel=0},header),15)
label(header,'V2.0',231,27,40,17,10,palette.gray,true)
local function topButton(symbol,x)
    local btn=round(new('TextButton',{Position=UDim2.new(1,x,0,19),Size=UDim2.fromOffset(32,32),BackgroundColor3=palette.card,Text=symbol,TextColor3=palette.white,TextSize=19,Font=Enum.Font.GothamBold,AutoButtonColor=false,BorderSizePixel=0},header),9)
    border(btn)
    track(btn.MouseEnter:Connect(function() tween(btn,{BackgroundColor3=Color3.fromRGB(55,58,62)},.15) end))
    track(btn.MouseLeave:Connect(function() tween(btn,{BackgroundColor3=palette.card},.15) end))
    return btn
end
local minimize=topButton('−',-86)
local close=topButton('×',-46)
local sidebar=new('Frame',{Name='Navigation',Position=UDim2.fromOffset(0,69),Size=UDim2.new(0,212,1,-69),BackgroundColor3=palette.side,BorderSizePixel=0},window)
new('Frame',{Position=UDim2.new(1,-1,0,0),Size=UDim2.new(0,1,1,0),BackgroundColor3=palette.line,BorderSizePixel=0},sidebar)
label(sidebar,'N A V I G A T I O N',22,22,180,23,10,palette.gray,true)
local footer=label(sidebar,'●  OX1DE HUB',22,514,170,18,11,palette.white,true)
label(sidebar,'RIGHT SHIFT — OPEN / CLOSE',22,535,182,16,9,palette.gray,false)
label(sidebar,'MONOCHROME UI / RED FOV',22,552,185,16,9,palette.gray,false)
local navKeys={'Player','Visual','Combat','Setting'}
local navIcons={Player='♙',Visual='◎',Combat='⊕',Setting='⚙'}
local subtitles={Player='Character & movement',Visual='Display & highlights',Combat='Aim settings & FOV preview',Setting='Interface preferences'}
local navBtns={}
local content=new('Frame',{Position=UDim2.fromOffset(212,69),Size=UDim2.new(1,-212,1,-69),BackgroundTransparency=1},window)
local sectionIcon=label(content,'♙',26,17,34,36,24,palette.white,true)
local title=label(content,'Player',58,13,350,41,27,palette.white,true)
local desc=label(content,subtitles.Player,27,56,500,20,12,palette.gray,false)
local previewBadge=round(new('Frame',{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-23,0,23),Size=UDim2.fromOffset(103,25),BackgroundColor3=palette.card,BorderSizePixel=0},content),16)
border(previewBadge)
label(previewBadge,'UI / PREVIEW',11,4,91,17,10,palette.white,true)
local list=new('ScrollingFrame',{Position=UDim2.fromOffset(24,87),Size=UDim2.new(1,-48,1,-103),CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=palette.line,ScrollingDirection=Enum.ScrollingDirection.Y},content)
new('UIListLayout',{Padding=UDim.new(0,7),SortOrder=Enum.SortOrder.LayoutOrder},list)
new('UIPadding',{PaddingBottom=UDim.new(0,10)},list)
local sections={}
local order=0
local function clearList()
    for _,ch in ipairs(list:GetChildren()) do
        if ch:IsA('GuiObject') then ch:Destroy() end
    end
    order=0
end
local function nextOrder() order=order+1;return order end
local function sectionText(s)
    label(list,string.upper(s),2,0,475,18,10,palette.gray,true).LayoutOrder=nextOrder()
end
local function row(icon,name,sub,height)
    local h=height or 58
    local card=round(new('Frame',{Size=UDim2.new(1,-5,0,h),BackgroundColor3=palette.card,BorderSizePixel=0,LayoutOrder=nextOrder()},list),12)
    border(card)
    label(card,icon,16,0,31,h,20,palette.white,true)
    label(card,name,58,7,340,25,13,palette.white,true)
    label(card,sub or '',58,30,410,17,11,palette.gray,false)
    return card
end
local function makeToggle(card,key,callback)
    local btn=round(new('TextButton',{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-17,.5,0),Size=UDim2.fromOffset(44,25),AutoButtonColor=false,Text='',BackgroundColor3=palette.line,BorderSizePixel=0},card),14)
    local dot=round(new('Frame',{Position=UDim2.fromOffset(4,4),Size=UDim2.fromOffset(17,17),BackgroundColor3=palette.white,BorderSizePixel=0},btn),11)
    local function refresh()
        local yes=state[key]
        tween(btn,{BackgroundColor3=yes and palette.white or palette.line},.17)
        tween(dot,{Position=UDim2.fromOffset(yes and 23 or 4,4),BackgroundColor3=yes and palette.dark or palette.white},.17)
    end
    track(btn.MouseButton1Click:Connect(function()
        state[key]=not state[key]
        refresh()
        if callback then callback(state[key]) end
    end))
    refresh()
    return btn
end
local function bindButton(card,bindName)
    local b=round(new('TextButton',{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-67,.5,0),Size=UDim2.fromOffset(39,28),BackgroundColor3=palette.bg,Text=binds[bindName].Name:upper(),TextColor3=palette.white,TextSize=12,Font=Enum.Font.GothamBold,AutoButtonColor=false,BorderSizePixel=0},card),8)
    border(b)
    local keyTxt=label(card,'KEY',0,0,27,15,9,palette.gray,true)
    keyTxt.AnchorPoint=Vector2.new(1,.5)
    keyTxt.Position=UDim2.new(1,-115,.5,0)
    bindLabels[bindName]=b
    track(b.MouseButton1Click:Connect(function()
        waitingBind=bindName
        b.Text='...'
        tween(b,{BackgroundColor3=Color3.fromRGB(72,76,83)},.15)
    end))
end
local function changeWalk()
    local c=LocalPlayer.Character
    local hum=c and c:FindFirstChildOfClass('Humanoid')
    if hum then
        hum.WalkSpeed=state.Speed
        if hum.UseJumpPower then hum.JumpPower=state.Jump else hum.JumpHeight=state.Jump/7 end
    end
end
local function addSlider(icon,name,sub,key,minimum,maximum,decimals,callback)
    local card=row(icon,name,sub,64)
    local box=round(new('TextLabel',{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-15,.5,0),Size=UDim2.fromOffset(44,27),BackgroundColor3=palette.bg,BorderSizePixel=0,TextColor3=palette.white,TextSize=12,Font=Enum.Font.GothamBold},card),8)
    border(box)
    local bar=round(new('TextButton',{Position=UDim2.new(1,-215,.5,-3),Size=UDim2.fromOffset(146,6),BackgroundColor3=palette.line,BorderSizePixel=0,Text='',AutoButtonColor=false},card),4)
    local fill=round(new('Frame',{Size=UDim2.fromScale(.3,1),BackgroundColor3=palette.white,BorderSizePixel=0},bar),4)
    local knob=round(new('Frame',{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.3,.5),Size=UDim2.fromOffset(13,13),BackgroundColor3=palette.white,BorderSizePixel=0},bar),10)
    local dragging=false
    local function set(v)
        local pow=10^decimals
        state[key]=math.floor(math.clamp(v,minimum,maximum)*pow+.5)/pow
        local ratio=(state[key]-minimum)/(maximum-minimum)
        box.Text=decimals>0 and string.format('%.'..decimals..'f',state[key]) or tostring(math.floor(state[key]))
        fill.Size=UDim2.fromScale(ratio,1);knob.Position=UDim2.fromScale(ratio,.5)
        if callback then callback(state[key]) end
    end
    local function fromX(x)
        local ratio=math.clamp((x-bar.AbsolutePosition.X)/math.max(bar.AbsoluteSize.X,1),0,1)
        set(minimum+(maximum-minimum)*ratio)
    end
    track(bar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true;fromX(i.Position.X) end
    end))
    track(UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then fromX(i.Position.X) end
    end))
    track(UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end))
    set(state[key])
    return card
end
local function switchRow(icon,name,info,key,bind,callback)
    local card=row(icon,name,info)
    if bind then bindButton(card,bind) end
    makeToggle(card,key,callback)
    return card
end
local function choiceRow(icon,name,info,choices,key)
    local card=row(icon,name,info)
    local holders={}
    local total=#choices*62
    for i,s in ipairs(choices) do
        local btn=round(new('TextButton',{Position=UDim2.new(1,-total-13+(i-1)*62,.5,-16),Size=UDim2.fromOffset(59,32),BackgroundColor3=palette.bg,Text=s,TextSize=11,Font=Enum.Font.GothamBold,TextColor3=palette.gray,BorderSizePixel=0,AutoButtonColor=false},card),7)
        holders[i]=btn
        track(btn.MouseButton1Click:Connect(function()
            state[key]=s
            for _,ch in ipairs(holders) do
                tween(ch,{BackgroundColor3=ch.Text==s and palette.white or palette.bg,TextColor3=ch.Text==s and palette.dark or palette.gray},.14)
            end
            if key=='Background' then
                -- handled after the interface is constructed
                if _G.OX1DE_BG_REFRESH then _G.OX1DE_BG_REFRESH() end
            end
        end))
    end
    for _,b in ipairs(holders) do
        b.BackgroundColor3=b.Text==state[key] and palette.white or palette.bg
        b.TextColor3=b.Text==state[key] and palette.dark or palette.gray
    end
    return card
end
local currentPage='Player'
local function setMenuPage(page)
    currentPage=page
    clearList()
    for k,b in pairs(navBtns) do
        local yes=k==page
        tween(b,{BackgroundColor3=yes and palette.white or palette.card},.17)
        local txt=b:FindFirstChild('Text')
        local ico=b:FindFirstChild('Icon')
        if txt then txt.TextColor3=yes and palette.dark or palette.white end
        if ico then ico.TextColor3=yes and palette.dark or palette.white end
    end
    sectionIcon.Text=navIcons[page]
    title.Text=page
    desc.Text=subtitles[page]
    list.CanvasPosition=Vector2.new(0,0)
    if page=='Player' then
        sectionText('Movement')
        addSlider('♧','Walk Speed','Adjust your movement speed.','Speed',8,100,0,changeWalk)
        addSlider('⇧','Jump Height','Adjust your jump height.','Jump',20,120,0,changeWalk)
        sectionText('Movement modes')
        switchRow('➤','Fly','Toggle flight mode.','Fly','Fly',function(on) if on then beginFly() else stopFly() end end)
        switchRow('≋','Noclip','Toggle collision bypass.','Noclip','Noclip',function(on) if not on then restoreCollision() end end)
    elseif page=='Visual' then
        sectionText('Player labels')
        switchRow('♙','Name ESP','Display name and @username, on separate lines.','NameESP')
        switchRow('↔','Distance ESP','Show distance to players.','DistanceESP')
        switchRow('♧','Team Check','Teammates green • opponents red.','TeamVisual')
        sectionText('Character display')
        switchRow('☷','Skeleton ESP','Character joint lines for R6 / R15.','SkeletonESP')
        switchRow('▢','Outline ESP','Soft white outline around characters.','OutlineESP')
        switchRow('➛','Weapon ESP','Show equipped tool or weapon name.','WeaponESP')
        switchRow('⊞','Through Walls','Display overlays behind obstacles.','ThroughWalls')
        sectionText('Halloween • temporary')
        switchRow('✦','Pumpkin ESP','Highlight detected pumpkins in the map.','PumpkinESP')
    elseif page=='Combat' then
        sectionText('Aim controls')
        switchRow('⊙','Enable Aim','Aim toggle with editable keybind.','Aim','Aim')
        switchRow('⊞','Wall Check','Do not select targets behind walls.','WallCheck')
        switchRow('♧','Team Check','Exclude teammates from targeting.','TeamAim')
        choiceRow('⊕','Aim Part','Choose a character target area.',{'Head','Body','Legs'},'AimPart')
        sectionText('Precision')
        addSlider('⌁','Aim Speed','0 — smooth    •    1 — instant','AimSpeed',0,1,2)
        local fovRow=addSlider('⊕','FOV Radius','Red circle on game screen.','FOVRadius',40,400,0,refreshFOV)
        -- The last row receives a FOV switch and a compact preview button.
        local ft=makeToggle(fovRow,'FOV',refreshFOV)
        ft.Position=UDim2.new(1,-258,.5,0)
        -- Keep radius slider visible; use the row underneath for preview controls.
        local p=row('◉','FOV Preview','Show the red circle over the menu.',52)
        local preview=round(new('TextButton',{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-16,.5,0),Size=UDim2.fromOffset(96,28),BackgroundColor3=palette.bg,Text='PREVIEW',TextColor3=palette.red,TextSize=10,Font=Enum.Font.GothamBold,AutoButtonColor=false,BorderSizePixel=0},p),8)
        border(preview,palette.red)
        track(preview.MouseButton1Click:Connect(function()
            state.Preview=not state.Preview
            preview.Text=state.Preview and 'HIDE PREVIEW' or 'PREVIEW'
            refreshFOV()
        end))
    elseif page=='Setting' then
        sectionText('Appearance')
        choiceRow('▤','Background','Choose menu background style.',{'Dark','Blur','Transparent'},'Background')
        switchRow('◈','Shadows','Enable soft shadows around the menu.','Shadows',nil,function(yes) shadow.Visible=yes end)
        addSlider('◌','Opacity','Adjust menu transparency.','Opacity',.6,1,2,function() if menuOpen then tween(window,{GroupTransparency=1-state.Opacity},.14) end end)
        sectionText('Controls')
        local box=row('⌨','Menu Key','Open / close the menu.')
        local b=round(new('TextLabel',{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-16,.5,0),Size=UDim2.fromOffset(91,28),BackgroundColor3=palette.bg,Text='RightShift',TextColor3=palette.white,TextSize=11,Font=Enum.Font.GothamBold,BorderSizePixel=0},box),8)
        border(b)
    end
end
for i,p in ipairs(navKeys) do
    local btn=round(new('TextButton',{Name=p,Position=UDim2.fromOffset(15,51+(i-1)*65),Size=UDim2.fromOffset(182,54),BackgroundColor3=palette.card,BorderSizePixel=0,Text='',AutoButtonColor=false},sidebar),11)
    border(btn)
    local ic=label(btn,navIcons[p],19,7,25,40,22,palette.white,true);ic.Name='Icon'
    local tx=label(btn,p,55,11,95,33,14,palette.white,true);tx.Name='Text'
    label(btn,'›',158,10,18,33,25,palette.gray,true)
    navBtns[p]=btn
    track(btn.MouseButton1Click:Connect(function()setMenuPage(p)end))
end
setMenuPage('Player')

-- Built-in menu transitions, no separate Animations setting.
local blur=new('BlurEffect',{Name='OX1DE_V2_Blur',Enabled=false,Size=9},Lighting)
local function applyBackground()
    if not active then return end
    blur.Enabled=menuOpen and state.Background=='Blur'
    if state.Background=='Transparent' then
        window.BackgroundColor3=Color3.fromRGB(16,17,19)
        window.BackgroundTransparency=.18
    else
        window.BackgroundColor3=palette.bg
        window.BackgroundTransparency=0
    end
end
_G.OX1DE_BG_REFRESH=applyBackground
local toggleInProgress=false
local function setMenu(open)
    if not active then return end
    menuOpen=open
    applyBackground()
    if open then
        mouseWasIcon=UIS.MouseIconEnabled
        mouseWasBehavior=UIS.MouseBehavior
        UIS.MouseBehavior=Enum.MouseBehavior.Default
        UIS.MouseIconEnabled=true
        window.Visible=true
        shadow.Visible=state.Shadows
        window.GroupTransparency=1
        tween(window,{GroupTransparency=1-state.Opacity,Position=UDim2.new(.5,0,.5,0)},.23)
        tween(winScale,{Scale=math.clamp(winScale.Scale, .4,1.08)},.2)
        shadow.BackgroundTransparency=1
        tween(shadow,{BackgroundTransparency=.57},.21)
    else
        blur.Enabled=false
        tween(window,{GroupTransparency=1,Position=UDim2.new(.5,0,.5,12)},.2)
        tween(shadow,{BackgroundTransparency=1},.2)
        task.delay(.2,function()
            if active and not menuOpen then window.Visible=false;shadow.Visible=false end
        end)
        if mouseWasIcon~=nil then UIS.MouseIconEnabled=mouseWasIcon end
        if mouseWasBehavior~=nil then UIS.MouseBehavior=mouseWasBehavior end
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
    flyBV=new('BodyVelocity',{Name='OX1DE_V2_Velocity',Velocity=Vector3.zero,MaxForce=Vector3.new(1e8,1e8,1e8),P=12500},root)
    flyBG=new('BodyGyro',{Name='OX1DE_V2_Orientation',MaxTorque=Vector3.new(1e8,1e8,1e8),P=13500,CFrame=workspace.CurrentCamera.CFrame},root)
end
restoreCollision=function()
    for part,val in pairs(oldCollision) do
        if part and part.Parent then pcall(function() part.CanCollide=val end) end
    end
    table.clear(oldCollision)
end
local function toggleFeature(k)
    state[k]=not state[k]
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
    if key~=Enum.KeyCode.RightShift and gameProcessed then return end
    if waitingBind then
        local which=waitingBind
        waitingBind=nil
        if key~=Enum.KeyCode.Escape and key~=Enum.KeyCode.RightShift and key~=Enum.KeyCode.Unknown then
            binds[which]=key
        end
        local b=bindLabels[which]
        if b and b.Parent then
            b.Text=binds[which].Name:upper()
            tween(b,{BackgroundColor3=palette.bg},.12)
        end
        return
    end
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
    local ok=state.SkeletonESP and (state.ThroughWalls or visiblePoint(char:FindFirstChild('HumanoidRootPart') or char:FindFirstChild('Head'),char))
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
                    local distance=root and localRoot and math.floor((root.Position-localRoot.Position).Magnitude+.5) or nil
                    local tool=char:FindFirstChildOfClass('Tool')
                    rec.name.Text=p.DisplayName
                    rec.user.Text='@'..p.Name
                    local info={}
                    if state.DistanceESP and distance then info[#info+1]=tostring(distance)..'m' end
                    if state.WeaponESP and tool then info[#info+1]=tool.Name end
                    rec.info.Text=table.concat(info,'  •  ')
                    local charRoot=root or char:FindFirstChild('Head')
                    local visible=state.ThroughWalls or visiblePoint(charRoot,char)
                    rec.bill.Enabled=visible and (state.NameESP or #info>0)
                    rec.name.Visible=state.NameESP
                    rec.user.Visible=state.NameESP
                    rec.name.TextColor3=teamColors(p)
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
RS:BindToRenderStep('OX1DE_V2_Aim',Enum.RenderPriority.Camera.Value+5,function(dt)
    if not active or not state.Aim then return end
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
        local alpha=smoothing>=.995 and 1 or (0.018+math.pow(smoothing,2)*.982)
        cam.CFrame=cam.CFrame:Lerp(goal,alpha)
    end
end)

local function cleanup()
    if not active then return end
    active=false
    pcall(function() RS:UnbindFromRenderStep('OX1DE_V2_Aim') end)
    stopFly();restoreCollision()
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
applyBackground()
refreshFOV()
changeWalk()
window.Position=UDim2.new(.5,0,.5,15)
window.GroupTransparency=1
shadow.BackgroundTransparency=1
setMenu(true)