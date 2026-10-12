-- OX1DE | Head menu
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- Удаление предыдущего экземпляра
local env = getgenv()
if env.OX1DEHeadCleanup then
    env.OX1DEHeadCleanup()
end

local enabled = false
local size = 5
local saved = {}
local connections = {}

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end

local function restore()
    for head, properties in pairs(saved) do
        if head.Parent then
            pcall(function()
                head.Size = properties.Size
                head.Transparency = properties.Transparency
                head.CanCollide = properties.CanCollide
            end)
        end
    end
    table.clear(saved)
end

local gui = Instance.new("ScreenGui")
gui.Name = "OX1DEHeadMenu"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(260, 220)
frame.Position = UDim2.new(0.5, -130, 0.5, -110)
frame.BackgroundColor3 = Color3.fromRGB(25, 27, 33)
frame.Active = true
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local function label(text, y)
    local item = Instance.new("TextLabel")
    item.Size = UDim2.new(1, -24, 0, 30)
    item.Position = UDim2.fromOffset(12, y)
    item.BackgroundTransparency = 1
    item.Text = text
    item.TextColor3 = Color3.fromRGB(240, 240, 245)
    item.Font = Enum.Font.GothamBold
    item.TextSize = 16
    item.Parent = frame
    return item
end

local function button(text, x, y, width)
    local item = Instance.new("TextButton")
    item.Size = UDim2.fromOffset(width, 36)
    item.Position = UDim2.fromOffset(x, y)
    item.BackgroundColor3 = Color3.fromRGB(50, 54, 65)
    item.TextColor3 = Color3.new(1, 1, 1)
    item.Font = Enum.Font.GothamBold
    item.TextSize = 15
    item.Text = text
    item.Parent = frame
    Instance.new("UICorner", item).CornerRadius = UDim.new(0, 8)
    return item
end

local title = label("OX1DE | Голова", 8)
local toggle = button("Выключено", 12, 48, 236)
local counter = label("Размер: 5", 93)
local minus = button("−", 12, 128, 112)
local plus = button("+", 136, 128, 112)
local close = button("Закрыть и восстановить", 12, 174, 236)

connect(toggle.Activated, function()
    enabled = not enabled
    toggle.Text = enabled and "Включено" or "Выключено"
    toggle.BackgroundColor3 = enabled
        and Color3.fromRGB(210, 110, 35)
        or Color3.fromRGB(50, 54, 65)
    if not enabled then restore() end
end)

local function change(amount)
    size = math.clamp(size + amount, 1, 15)
    counter.Text = "Размер: " .. size
end

connect(minus.Activated, function() change(-1) end)
connect(plus.Activated, function() change(1) end)

-- Перетаскивание за заголовок
local dragging = false
local startMouse
local startPosition

title.Active = true
connect(title.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        startMouse = input.Position
        startPosition = frame.Position
    end
end)

connect(UIS.InputChanged, function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - startMouse
        frame.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

connect(UIS.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

connect(UIS.InputBegan, function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.F1 then
        frame.Visible = not frame.Visible
    end
end)

-- Поиск моделей по структуре из присланного скрипта
local models = {}

local function consider(model)
    if model:IsA("Model") then
        models[model] = true
    end
end

for _, model in ipairs(workspace:GetChildren()) do
    consider(model)
end

connect(workspace.ChildAdded, consider)
connect(workspace.ChildRemoved, function(model)
    models[model] = nil
end)

connect(RunService.Heartbeat, function()
    if not enabled then return end

    for model in pairs(models) do
        if model ~= player.Character
            and model.Name ~= "LocalCharacter" then
            local head = model:FindFirstChild("Head")
            local torso = model:FindFirstChild("LowerTorso")

            if head and head:IsA("BasePart") and torso then
                if not saved[head] then
                    saved[head] = {
                        Size = head.Size,
                        Transparency = head.Transparency,
                        CanCollide = head.CanCollide,
                    }
                end

                head.Size = Vector3.new(size, size, size)
                head.Transparency = 0.65
                head.CanCollide = false
            end
        end
    end

    for head in pairs(saved) do
        if not head.Parent then
            saved[head] = nil
        end
    end
end)

local function cleanup()
    enabled = false
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    restore()
    gui:Destroy()
    if env.OX1DEHeadCleanup == cleanup then
        env.OX1DEHeadCleanup = nil
    end
end

env.OX1DEHeadCleanup = cleanup
connect(close.Activated, cleanup)
