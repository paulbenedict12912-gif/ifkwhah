--==================================================
-- OISHI HUB
-- Full Mobile + PC Version
-- Tab: Main
--==================================================

pcall(function(...)
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Lutosys/opensrc/refs/heads/main/stealaeggspeedbypass.lua"))()
end)

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
local isPC = not UIS.TouchEnabled

--==================================================
-- CONFIG
--==================================================

local CONFIG = {
    Accent = Color3.new(1, 1, 1),
    Background = Color3.fromRGB(5, 5, 5),
    Surface = Color3.fromRGB(15, 15, 15),
    SurfaceLight = Color3.fromRGB(25, 25, 25),
    Text = Color3.fromRGB(200, 200, 200),
    TextSecondary = Color3.fromRGB(100, 100, 100),
    ToggleOn = Color3.new(1, 1, 1),
    ToggleOff = Color3.fromRGB(40, 40, 40),
    TabActive = Color3.new(1, 1, 1),
    TabInactive = Color3.fromRGB(30, 30, 30),
    Border = Color3.new(1, 1, 1),
    HoverSurface = Color3.fromRGB(40, 40, 40),
    Font = Enum.Font.GothamBold,
    FontMedium = Enum.Font.GothamMedium,
}

local ANIM = {
    OpenTime = 0.28,
    CloseTime = 0.2,
    TabTime = 0.2,
    DropdownTime = 0.2,
    HoverTime = 0.12,
    EasingStyle = Enum.EasingStyle.Quint,
    EasingDirection = Enum.EasingDirection.Out,
}

local function tween(object, time, properties)
    local info = TweenInfo.new(time, ANIM.EasingStyle, ANIM.EasingDirection)
    return TweenService:Create(object, info, properties)
end

--==================================================
-- UTILITY
--==================================================

local utility = {
    ProximityPromptService = ProximityPromptService,
    Players = Players,
    ReplicatedStorage = ReplicatedStorage,
    Workspace = Workspace,
    RunService = RunService,
    LocalPlayer = Player,
    Target = nil,
    conns = {},

    BatRange = 16.5,
    BatConnection = nil,
    BatLast = 0,
    BatEnabled = false,
    BatAttackInterval = 0.1,

    AntiRagdollEnabled = false,
    RigSyncConnections = nil,
    RigSyncFunctions = nil,
}

function utility:bind(connection, callback)
    local s, r = pcall(function(...)
        local conn = connection:Connect(callback)
        self.conns[conn] = conn
        return self.conns[conn]
    end)
    if s and r then return r end
    return nil
end

function utility:unbind(connection)
    local s, r = pcall(function(...)
        local conn = self.conns[connection]
        if conn then
            conn:Disconnect()
            self.conns[connection] = nil
            return true
        end
        return false
    end)
    if s and r then return true end
    return false
end

--==================================================
-- BAT AURA
--==================================================

function utility:CreateSeed()
    local s, r = pcall(function(...)
        return ("%*:%*:%*"):format(
            self.LocalPlayer.UserId, 100,
            (math.floor(self.Workspace:GetServerTimeNow() * 1000))
        )
    end)
    if s and r then return r end
    return nil
end

function utility:CanUseTool()
    local s, r = pcall(function(...)
        local c = self.LocalPlayer.Character
        if not c then return false end
        local t = c:FindFirstChildOfClass("Tool")
        if not t or t:GetAttribute("ItemType") ~= "Gear" then return false end
        local h = c and c:FindFirstChild("HumanoidRootPart")
        if not h then return false end
        local n = not self.ToolGameplayGuard.IsLocalInsideArena()
        if n then return false end
        if self.Workspace:GetAttribute("Event_MonsterEvent") then
            if h then
                local i = -268 < h.Position.Z
                if i then return true end
            end
            return false
        else
            return true
        end
    end)
    if s and r then return r end
    return false
end

function utility:attack(p)
    pcall(function(...)
        return self["RE/BatSwing/Trigger"]:FireServer(p, self:CreateSeed())
    end)
end

function utility:GetClosetPlayer()
    local c = nil
    local cd = math.huge
    for _, p in next, self.Players:GetPlayers() do
        if p == self.LocalPlayer then continue end
        local char = p.Character
        if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        local dist = self.LocalPlayer:DistanceFromCharacter(hrp.Position)
        if dist < cd and dist <= self.BatRange then
            cd = dist
            c = p
        end
    end
    return c
end

function utility:startBatAura()
    if self.BatConnection then return true end
    self.BatLast = tick()
    self.BatEnabled = true
    self.BatConnection = self.RunService.Heartbeat:Connect(function()
        if not self.BatEnabled then return end
        self.Target = self:GetClosetPlayer()
        if self.Target then
            if tick() - self.BatLast >= self.BatAttackInterval then
                if self:CanUseTool() then
                    self:attack(self.Target)
                    self.BatLast = tick()
                end
            end
        end
    end)
    return self.BatConnection ~= nil
end

function utility:stopBatAura()
    self.BatEnabled = false
    self.Target = nil
    if self.BatConnection then
        self.BatConnection:Disconnect()
        self.BatConnection = nil
    end
    return true
end

--==================================================
-- ANTI RAGDOLL
--==================================================

function utility.GetConnections(obj, signal)
    local s, r = pcall(function(...)
        return getconnections(obj[signal])
    end)
    if s and r then return r end
    return nil
end

function utility.Disconnect(conns)
    local s, r = pcall(function(...)
        local patched = 0
        for _, conn in next, conns do
            conn:Disconnect()
            patched += 1
        end
        return patched
    end)
    if s and r ~= 0 then return r end
    return 0
end

function utility:enableAntiRagdoll()
    if self.AntiRagdollEnabled then return true end
    if not self["RE/RigSync/Refresh"] then return false end
    if not getconnections then return false end
    local conns = self.GetConnections(self["RE/RigSync/Refresh"], "OnClientEvent")
    if not conns then return false end
    self.RigSyncFunctions = {}
    for i, conn in ipairs(conns) do
        local ok, fn = pcall(function() return conn.Function end)
        if ok and fn then table.insert(self.RigSyncFunctions, fn) end
    end
    self.RigSyncConnections = conns
    self.Disconnect(conns)
    self.AntiRagdollEnabled = true
    return true
end

function utility:disableAntiRagdoll()
    if not self.AntiRagdollEnabled then return true end
    if not self["RE/RigSync/Refresh"] then return false end
    if self.RigSyncFunctions then
        for _, fn in ipairs(self.RigSyncFunctions) do
            pcall(function()
                self["RE/RigSync/Refresh"].OnClientEvent:Connect(fn)
            end)
        end
    end
    self.RigSyncConnections = nil
    self.RigSyncFunctions = nil
    self.AntiRagdollEnabled = false
    return true
end

--==================================================
-- UTILITY INIT
--==================================================

function utility:init()
    self.LocalPlayer = self.LocalPlayer or self.Players.LocalPlayer
    if not self.LocalPlayer then return end

    self.Packages = self.ReplicatedStorage:FindFirstChild("Packages")
    if self.Packages then
        self.Networking = self.Packages:FindFirstChild("Networking")
        if self.Networking then
            self["RE/BatSwing/Trigger"] = self.Networking:FindFirstChild("RE/BatSwing/Trigger")
            self["RE/RigSync/Refresh"] = self.Networking:FindFirstChild("RE/RigSync/Refresh")
        end
    end

    self.Client = self.ReplicatedStorage:FindFirstChild("Client")
    if self.Client then
        local guard = self.Client:FindFirstChild("ToolGameplayGuard")
        if guard then self.ToolGameplayGuard = require(guard) end
    end
end

utility:init()

--==================================================
-- REMOVE OLD UI
--==================================================

local oldUI = PlayerGui:FindFirstChild("Oishi hub")
if oldUI then oldUI:Destroy() end

--==================================================
-- SCREEN GUI
--==================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Oishi hub"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local uiWidth = isPC and 600 or math.min(440, Camera.ViewportSize.X - 20)
local uiHeight = isPC and 450 or math.min(400, Camera.ViewportSize.Y * 0.5)

--==================================================
-- MAIN
--==================================================

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, uiWidth, 0, uiHeight)
Main.Position = UDim2.new(0.5, -uiWidth / 2, 0.5, -uiHeight / 2)
Main.BackgroundColor3 = CONFIG.Background
Main.BorderSizePixel = 0
Main.Active = true
Main.Visible = false
Main.ZIndex = 10
Main.Parent = ScreenGui

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.new(1, 1, 1)
MainStroke.Thickness = 2
MainStroke.Parent = Main

local MainScale = Instance.new("UIScale")
MainScale.Scale = 0.88
MainScale.Parent = Main

local function OpenUI()
    Main.Visible = true
    MainScale.Scale = 0.88
    tween(MainScale, ANIM.OpenTime, { Scale = 1 }):Play()
end

local function CloseUI()
    local animation = tween(MainScale, ANIM.CloseTime, { Scale = 0.88 })
    animation:Play()
    animation.Completed:Connect(function()
        if Main then Main.Visible = false end
    end)
end

--==================================================
-- HEADER
--==================================================

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 30)
Header.BackgroundColor3 = CONFIG.Surface
Header.BorderSizePixel = 0
Header.ZIndex = 11
Header.Parent = Main

local HeaderTitle = Instance.new("TextLabel")
HeaderTitle.Size = UDim2.new(0, 300, 0, 20)
HeaderTitle.Position = UDim2.new(0, 10, 0, 5)
HeaderTitle.BackgroundTransparency = 1
HeaderTitle.Text = "OISHI HUB"
HeaderTitle.Font = CONFIG.Font
HeaderTitle.TextSize = 12
HeaderTitle.TextColor3 = Color3.new(1, 1, 1)
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
HeaderTitle.ZIndex = 12
HeaderTitle.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 20, 0, 20)
CloseBtn.Position = UDim2.new(1, -25, 0, 5)
CloseBtn.BackgroundColor3 = CONFIG.SurfaceLight
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "X"
CloseBtn.Font = CONFIG.Font
CloseBtn.TextSize = 10
CloseBtn.TextColor3 = CONFIG.Text
CloseBtn.ZIndex = 12
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = Header

CloseBtn.MouseButton1Click:Connect(function()
    CloseUI()
end)

--==================================================
-- BODY (full width)
--==================================================

local Body = Instance.new("Frame")
Body.Size = UDim2.new(1, 0, 1, -30)
Body.Position = UDim2.new(0, 0, 0, 30)
Body.BackgroundColor3 = CONFIG.Surface
Body.BorderSizePixel = 0
Body.ZIndex = 11
Body.Parent = Main

local TabFrame = Instance.new("Frame")
TabFrame.Size = UDim2.new(1, 0, 0, 26)
TabFrame.BackgroundColor3 = CONFIG.Surface
TabFrame.BorderSizePixel = 0
TabFrame.ZIndex = 11
TabFrame.Parent = Body

local Tabs = {
    { name = "Main" },
}

local currentTab = "Main"
local TabButtons = {}
local TabContents = {}

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, 0, 1, -26)
ContentContainer.Position = UDim2.new(0, 0, 0, 26)
ContentContainer.BackgroundTransparency = 1
ContentContainer.BorderSizePixel = 0
ContentContainer.ClipsDescendants = true
ContentContainer.ZIndex = 11
ContentContainer.Parent = Body

local tabCount = #Tabs

for i, tab in ipairs(Tabs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1 / tabCount, -1, 0, 22)
    btn.Position = UDim2.new((i - 1) * (1 / tabCount), 0.5, 0, 2)
    btn.BackgroundColor3 = tab.name == currentTab and CONFIG.TabActive or CONFIG.TabInactive
    btn.BackgroundTransparency = tab.name == currentTab and 0.3 or 0.5
    btn.BorderSizePixel = 0
    btn.Text = tab.name
    btn.Font = CONFIG.Font
    btn.TextSize = 8
    btn.TextColor3 = tab.name == currentTab and Color3.new(0, 0, 0) or CONFIG.Text
    btn.ZIndex = 12
    btn.AutoButtonColor = false
    btn.Parent = TabFrame

    TabButtons[tab.name] = btn

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, 0, 1, 0)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.Visible = tab.name == currentTab
    content.ZIndex = 11
    content.Parent = ContentContainer

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = CONFIG.Accent
    scroll.ScrollBarImageTransparency = 0.3
    scroll.CanvasSize = UDim2.new(0, 0, 0, 400)
    scroll.ZIndex = 12
    scroll.Parent = content

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.Parent = scroll

    TabContents[tab.name] = { frame = content, scroll = scroll, layout = layout }

    btn.MouseButton1Click:Connect(function()
        if currentTab == tab.name then return end
        local oldTab = currentTab
        currentTab = tab.name
        for name, b in pairs(TabButtons) do
            if name == tab.name then
                tween(b, ANIM.TabTime, {
                    BackgroundColor3 = CONFIG.TabActive,
                    BackgroundTransparency = 0.3,
                    TextColor3 = Color3.new(0, 0, 0)
                }):Play()
            else
                tween(b, ANIM.TabTime, {
                    BackgroundColor3 = CONFIG.TabInactive,
                    BackgroundTransparency = 0.5,
                    TextColor3 = CONFIG.Text
                }):Play()
            end
        end
        local oldContent = TabContents[oldTab]
        local newContent = TabContents[tab.name]
        if oldContent and newContent then
            oldContent.frame.Visible = false
            newContent.frame.Visible = true
            local scale = newContent.frame:FindFirstChild("TabScale")
            if not scale then
                scale = Instance.new("UIScale")
                scale.Name = "TabScale"
                scale.Scale = 0.96
                scale.Parent = newContent.frame
            end
            tween(scale, ANIM.TabTime, { Scale = 1 }):Play()
        end
    end)
end

--==================================================
-- HELPERS
--==================================================

local function CreateSectionLabel(tabName, text)
    local content = TabContents[tabName]
    if not content then return end
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = CONFIG.Font
    label.TextSize = 9
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 13
    label.Parent = content.scroll
    return label
end

local function CreateToggle(tabName, name, default, callback)
    local content = TabContents[tabName]
    if not content then return end

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 34)
    container.BackgroundColor3 = CONFIG.Surface
    container.BorderSizePixel = 0
    container.ZIndex = 12
    container.Parent = content.scroll

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, 0, 0, 14)
    label.Position = UDim2.new(0, 8, 0, 10)
    label.BackgroundTransparency = 1
    label.Text = name
    label.Font = CONFIG.FontMedium
    label.TextSize = 9
    label.TextColor3 = CONFIG.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 13
    label.Parent = container

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 32, 0, 18)
    button.Position = UDim2.new(1, -40, 0, 8)
    button.BackgroundColor3 = default and CONFIG.ToggleOn or CONFIG.ToggleOff
    button.BorderSizePixel = 0
    button.Text = ""
    button.AutoButtonColor = false
    button.ZIndex = 13
    button.Parent = container

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = default and UDim2.new(0,17,0,3) or UDim2.new(0,3,0,3)
    knob.BackgroundColor3 = Color3.new(0, 0, 0)
    knob.BorderSizePixel = 0
    knob.ZIndex = 14
    knob.Parent = button

    local knobStroke = Instance.new("UIStroke")
    knobStroke.Color = Color3.new(1, 1, 1)
    knobStroke.Transparency = 0.2
    knobStroke.Thickness = 1
    knobStroke.Parent = knob

    local state = default or false

    button.MouseButton1Click:Connect(function()
        state = not state
        if state then
            tween(button, 0.2, { BackgroundColor3 = CONFIG.ToggleOn }):Play()
            tween(knob, 0.2, { Position = UDim2.new(0,17,0,3) }):Play()
        else
            tween(button, 0.2, { BackgroundColor3 = CONFIG.ToggleOff }):Play()
            tween(knob, 0.2, { Position = UDim2.new(0,3,0,3) }):Play()
        end
        if callback then callback(state) end
    end)

    return container
end

local function CreateSlider(tabName, name, min, max, default, callback)
    local content = TabContents[tabName]
    if not content then return end

    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 44)
    container.BackgroundColor3 = CONFIG.Surface
    container.BorderSizePixel = 0
    container.Active = true
    container.ZIndex = 12
    container.Parent = content.scroll

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.55, 0, 0, 14)
    label.Position = UDim2.new(0, 8, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = name
    label.Font = CONFIG.FontMedium
    label.TextSize = 8
    label.TextColor3 = CONFIG.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 13
    label.Parent = container

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.3, 0, 0, 14)
    valueLabel.Position = UDim2.new(0.65, -5, 0, 5)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.Font = CONFIG.FontMedium
    valueLabel.TextSize = 8
    valueLabel.TextColor3 = Color3.new(1, 1, 1)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.ZIndex = 13
    valueLabel.Parent = container

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -24, 0, 6)
    sliderBg.Position = UDim2.new(0, 12, 0, 28)
    sliderBg.BackgroundColor3 = CONFIG.SurfaceLight
    sliderBg.BorderSizePixel = 0
    sliderBg.Active = true
    sliderBg.ZIndex = 13
    sliderBg.Parent = container

    local barStroke = Instance.new("UIStroke")
    barStroke.Color = Color3.new(1, 1, 1)
    barStroke.Transparency = 0.5
    barStroke.Thickness = 1
    barStroke.Parent = sliderBg

    local percentage = math.clamp((default - min) / (max - min), 0, 1)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(percentage, 0, 1, 0)
    fill.BackgroundColor3 = Color3.new(1, 1, 1)
    fill.BorderSizePixel = 0
    fill.ZIndex = 14
    fill.Parent = sliderBg

    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(percentage, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel = 0
    knob.Text = ""
    knob.AutoButtonColor = false
    knob.Active = true
    knob.ZIndex = 16
    knob.Parent = sliderBg

    local knobStroke = Instance.new("UIStroke")
    knobStroke.Color = Color3.new(1, 1, 1)
    knobStroke.Transparency = 0.2
    knobStroke.Thickness = 1
    knobStroke.Parent = knob

    local draggingSlider = false

    local function updateSlider(input)
        local pos = sliderBg.AbsolutePosition
        local size = sliderBg.AbsoluteSize
        local relative = (input.Position.X - pos.X) / size.X
        relative = math.clamp(relative, 0, 1)
        local value = min + (max - min) * relative
        value = math.floor(value + 0.5)
        local final = math.clamp((value - min) / (max - min), 0, 1)
        fill.Size = UDim2.new(final, 0, 1, 0)
        knob.Position = UDim2.new(final, 0, 0.5, 0)
        valueLabel.Text = tostring(value)
        if callback then callback(value) end
    end

    local function beginSlider(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = true
            updateSlider(input)
        end
    end

    sliderBg.InputBegan:Connect(beginSlider)
    knob.InputBegan:Connect(beginSlider)

    local moveConnection = UIS.InputChanged:Connect(function(input)
        if not draggingSlider then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            updateSlider(input)
        end
    end)

    local endConnection = UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = false
        end
    end)

    container.Destroying:Connect(function()
        draggingSlider = false
        moveConnection:Disconnect()
        endConnection:Disconnect()
    end)

    return container
end

--==================================================
-- MAIN TAB
--==================================================

local pickUpConnection = nil

CreateSectionLabel("Main", "FEATURES")

CreateToggle(
    "Main",
    "Instant pick up",
    false,
    function(state)
        if state then
            pickUpConnection = utility:bind(
                utility.ProximityPromptService.PromptButtonHoldBegan,
                function(ProximityPrompt, Player)
                    if Player == utility.LocalPlayer
                        and tostring(ProximityPrompt) == "CarryAreaEgg" then
                        ProximityPrompt.HoldDuration = 0
                    end
                end
            )
        else
            if pickUpConnection then
                utility:unbind(pickUpConnection)
                pickUpConnection = nil
            end
        end
    end
)

CreateToggle(
    "Main",
    "Bat aura",
    false,
    function(state)
        if state then
            utility:startBatAura()
        else
            utility:stopBatAura()
        end
    end
)

CreateSlider(
    "Main",
    "Bat aura range",
    5,
    50,
    17,
    function(value)
        utility.BatRange = value
    end
)

CreateToggle(
    "Main",
    "Anti ragdoll",
    false,
    function(state)
        if state then
            utility:enableAntiRagdoll()
        else
            utility:disableAntiRagdoll()
        end
    end
)

--==================================================
-- UPDATE CANVAS
--==================================================

task.wait()

for _, content in pairs(TabContents) do
    content.scroll.CanvasSize =
        UDim2.new(0, 0, 0, content.layout.AbsoluteContentSize.Y + 20)
end

--==================================================
-- HEADER DRAG
--==================================================

local dragging = false
local dragStart
local startPos

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

--==================================================
-- MOBILE CONTROLS
--==================================================

if isMobile then
    local isUnlocked = false

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 88, 0, 30)
    ToggleBtn.Position = UDim2.new(0, 10, 0, 150)
    ToggleBtn.BackgroundColor3 = Color3.new(1, 1, 1)
    ToggleBtn.BorderSizePixel = 0
    ToggleBtn.Text = "Toggle UI"
    ToggleBtn.Font = CONFIG.Font
    ToggleBtn.TextSize = 10
    ToggleBtn.TextColor3 = Color3.new(0, 0, 0)
    ToggleBtn.ZIndex = 999999
    ToggleBtn.AutoButtonColor = false
    ToggleBtn.Parent = ScreenGui

    ToggleBtn.MouseButton1Click:Connect(function()
        if Main.Visible then CloseUI() else OpenUI() end
    end)

    local LockBtn = Instance.new("TextButton")
    LockBtn.Size = UDim2.new(0, 88, 0, 30)
    LockBtn.Position = UDim2.new(0, 10, 0, 190)
    LockBtn.BackgroundColor3 = CONFIG.Surface
    LockBtn.BorderSizePixel = 0
    LockBtn.Text = "Unlock UI"
    LockBtn.Font = CONFIG.Font
    LockBtn.TextSize = 10
    LockBtn.TextColor3 = Color3.new(1,1,1)
    LockBtn.ZIndex = 999999
    LockBtn.AutoButtonColor = false
    LockBtn.Parent = ScreenGui

    LockBtn.MouseButton1Click:Connect(function()
        isUnlocked = not isUnlocked
        LockBtn.Text = isUnlocked and "Lock UI" or "Unlock UI"
        LockBtn.BackgroundColor3 = isUnlocked and Color3.new(1, 1, 1) or CONFIG.Surface
        LockBtn.TextColor3 = isUnlocked and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
    end)

    local function makeDraggable(btn)
        local draggingButton = false
        local start
        local position

        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch
                or input.UserInputType == Enum.UserInputType.MouseButton1 then
                draggingButton = true
                start = input.Position
                position = btn.Position
            end
        end)

        UIS.InputChanged:Connect(function(input)
            if not draggingButton then return end
            if not isUnlocked then return end
            if input.UserInputType == Enum.UserInputType.Touch
                or input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - start
                btn.Position = UDim2.new(
                    position.X.Scale, position.X.Offset + delta.X,
                    position.Y.Scale, position.Y.Offset + delta.Y
                )
            end
        end)

        UIS.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch
                or input.UserInputType == Enum.UserInputType.MouseButton1 then
                draggingButton = false
            end
        end)
    end

    makeDraggable(ToggleBtn)
    makeDraggable(LockBtn)
end

--==================================================
-- PC RIGHT SHIFT
--==================================================

if isPC then
    UIS.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            if Main.Visible then CloseUI() else OpenUI() end
        end
    end)
end

if isPC then
    OpenUI()
end
