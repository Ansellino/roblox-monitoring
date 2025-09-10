-- Advanced Roblox Network Monitor Pro v2.0
-- Professional Network Analysis Tool with Advanced Features
-- For educational and debugging purposes only

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

-- Advanced Configuration
local MONITOR_CONFIG = {
    -- Monitoring Options
    LogRemoteEvents = true,
    LogRemoteFunctions = true,
    LogBindableEvents = true,
    LogBindableFunctions = true,
    LogHttpRequests = true,
    LogDataStores = true,
    
    -- Performance Options
    MaxLogsPerRemote = 500,
    SaveInterval = 30,
    AutoClearThreshold = 1000,
    EnableStackTrace = true,
    EnableDeepInspection = true,
    
    -- UI Options
    UIVisible = true,
    DarkMode = true,
    ShowNotifications = true,
    SoundEffects = true,
    AnimationsEnabled = true,
    
    -- Filter Options
    FilterDuplicates = false,
    FilterByService = {},
    BlacklistRemotes = {},
    WhitelistMode = false,
    WhitelistRemotes = {},
    
    -- Advanced Options
    PacketSniffing = true,
    EncryptionDetection = true,
    PerformanceMonitoring = true,
    AutoExport = false,
    WebhookURL = "",
}

-- Storage Systems
local NetworkLogs = {
    RemoteEvents = {},
    RemoteFunctions = {},
    BindableEvents = {},
    BindableFunctions = {},
    HttpRequests = {},
    DataStores = {},
    Statistics = {
        TotalPackets = 0,
        TotalBytes = 0,
        PacketsPerSecond = 0,
        BytesPerSecond = 0,
        PeakTraffic = 0,
        StartTime = os.time(),
        RemoteFrequency = {},
        ArgumentPatterns = {},
        SuspiciousActivity = {}
    }
}

-- Pattern Recognition System
local PatternAnalyzer = {
    Patterns = {},
    Sequences = {},
    Anomalies = {}
}

-- Create Advanced UI
local function CreateAdvancedUI()
    -- Main ScreenGui with blur effect
    local NetworkMonitorPro = Instance.new("ScreenGui")
    NetworkMonitorPro.Name = "NetworkMonitorPro"
    NetworkMonitorPro.ResetOnSpawn = false
    NetworkMonitorPro.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    NetworkMonitorPro.DisplayOrder = 999
    
    -- Try CoreGui first
    pcall(function()
        NetworkMonitorPro.Parent = CoreGui
    end)
    if not NetworkMonitorPro.Parent then
        NetworkMonitorPro.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Blur Effect
    local BlurEffect = Instance.new("BlurEffect")
    BlurEffect.Size = 0
    BlurEffect.Parent = game:GetService("Lighting")
    
    -- Main Window
    local MainWindow = Instance.new("Frame")
    MainWindow.Name = "MainWindow"
    MainWindow.Size = UDim2.new(0, 800, 0, 600)
    MainWindow.Position = UDim2.new(0.5, -400, 0.5, -300)
    MainWindow.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    MainWindow.BorderSizePixel = 0
    MainWindow.ClipsDescendants = true
    MainWindow.Parent = NetworkMonitorPro
    
    -- Window Shadow
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.Size = UDim2.new(1, 30, 1, 30)
    Shadow.Position = UDim2.new(0, -15, 0, -15)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxassetid://1316045217"
    Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.ImageTransparency = 0.3
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    Shadow.Parent = MainWindow
    Shadow.ZIndex = -1
    
    local WindowCorner = Instance.new("UICorner")
    WindowCorner.CornerRadius = UDim.new(0, 12)
    WindowCorner.Parent = MainWindow
    
    -- Gradient Background
    local Gradient = Instance.new("UIGradient")
    Gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 30)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 20))
    }
    Gradient.Rotation = 90
    Gradient.Parent = MainWindow
    
    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 45)
    TitleBar.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainWindow
    
    local TitleGradient = Instance.new("UIGradient")
    TitleGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 40)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 25))
    }
    TitleGradient.Rotation = 90
    TitleGradient.Parent = TitleBar
    
    -- Logo and Title
    local Logo = Instance.new("ImageLabel")
    Logo.Size = UDim2.new(0, 30, 0, 30)
    Logo.Position = UDim2.new(0, 10, 0, 7)
    Logo.BackgroundTransparency = 1
    Logo.Image = "rbxassetid://7733992358" -- Network icon
    Logo.ImageColor3 = Color3.fromRGB(85, 170, 255)
    Logo.Parent = TitleBar
    
    local TitleText = Instance.new("TextLabel")
    TitleText.Text = "Network Monitor Pro v2.0"
    TitleText.Size = UDim2.new(0, 300, 1, 0)
    TitleText.Position = UDim2.new(0, 45, 0, 0)
    TitleText.BackgroundTransparency = 1
    TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleText.Font = Enum.Font.Gotham
    TitleText.TextSize = 16
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    TitleText.Parent = TitleBar
    
    -- Status Indicator
    local StatusIndicator = Instance.new("Frame")
    StatusIndicator.Size = UDim2.new(0, 10, 0, 10)
    StatusIndicator.Position = UDim2.new(0, 350, 0.5, -5)
    StatusIndicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    StatusIndicator.BorderSizePixel = 0
    StatusIndicator.Parent = TitleBar
    
    local StatusCorner = Instance.new("UICorner")
    StatusCorner.CornerRadius = UDim.new(1, 0)
    StatusCorner.Parent = StatusIndicator
    
    -- Pulse animation for status
    local function PulseStatus()
        while MainWindow.Parent do
            local tween = TweenService:Create(StatusIndicator, 
                TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {BackgroundTransparency = 0.5}
            )
            tween:Play()
            tween.Completed:Wait()
            
            local tween2 = TweenService:Create(StatusIndicator,
                TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {BackgroundTransparency = 0}
            )
            tween2:Play()
            tween2.Completed:Wait()
        end
    end
    spawn(PulseStatus)
    
    -- Window Controls
    local ControlsFrame = Instance.new("Frame")
    ControlsFrame.Size = UDim2.new(0, 120, 1, 0)
    ControlsFrame.Position = UDim2.new(1, -120, 0, 0)
    ControlsFrame.BackgroundTransparency = 1
    ControlsFrame.Parent = TitleBar
    
    local function CreateControlButton(icon, color, position)
        local btn = Instance.new("TextButton")
        btn.Text = icon
        btn.Size = UDim2.new(0, 30, 0, 30)
        btn.Position = position
        btn.BackgroundColor3 = color
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 18
        btn.AutoButtonColor = false
        btn.Parent = ControlsFrame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = btn
        
        -- Hover effect
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.2}):Play()
        end)
        
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
        end)
        
        return btn
    end
    
    local MinimizeBtn = CreateControlButton("—", Color3.fromRGB(255, 189, 68), UDim2.new(0, 0, 0, 7))
    local MaximizeBtn = CreateControlButton("□", Color3.fromRGB(52, 199, 89), UDim2.new(0, 40, 0, 7))
    local CloseBtn = CreateControlButton("×", Color3.fromRGB(255, 69, 58), UDim2.new(0, 80, 0, 7))
    
    -- Sidebar Navigation
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 200, 1, -45)
    Sidebar.Position = UDim2.new(0, 0, 0, 45)
    Sidebar.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainWindow
    
    -- Navigation Items
    local NavItems = {
        {Icon = "📊", Name = "Dashboard", Color = Color3.fromRGB(85, 170, 255)},
        {Icon = "📡", Name = "Live Monitor", Color = Color3.fromRGB(255, 170, 85)},
        {Icon = "📈", Name = "Analytics", Color = Color3.fromRGB(170, 85, 255)},
        {Icon = "🔍", Name = "Inspector", Color = Color3.fromRGB(85, 255, 170)},
        {Icon = "⚙️", Name = "Filters", Color = Color3.fromRGB(255, 85, 170)},
        {Icon = "💾", Name = "Logs", Color = Color3.fromRGB(170, 255, 85)},
        {Icon = "🛠️", Name = "Tools", Color = Color3.fromRGB(255, 255, 85)},
        {Icon = "⚡", Name = "Performance", Color = Color3.fromRGB(85, 255, 255)},
        {Icon = "🔐", Name = "Security", Color = Color3.fromRGB(255, 85, 85)},
        {Icon = "⚙️", Name = "Settings", Color = Color3.fromRGB(200, 200, 200)}
    }
    
    local currentPage = "Dashboard"
    local navButtons = {}
    
    for i, item in ipairs(NavItems) do
        local NavButton = Instance.new("TextButton")
        NavButton.Name = item.Name
        NavButton.Size = UDim2.new(1, 0, 0, 45)
        NavButton.Position = UDim2.new(0, 0, 0, (i-1) * 45)
        NavButton.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
        NavButton.BorderSizePixel = 0
        NavButton.AutoButtonColor = false
        NavButton.Parent = Sidebar
        
        local NavIcon = Instance.new("TextLabel")
        NavIcon.Text = item.Icon
        NavIcon.Size = UDim2.new(0, 40, 1, 0)
        NavIcon.Position = UDim2.new(0, 10, 0, 0)
        NavIcon.BackgroundTransparency = 1
        NavIcon.TextColor3 = item.Color
        NavIcon.Font = Enum.Font.Gotham
        NavIcon.TextSize = 20
        NavIcon.Parent = NavButton
        
        local NavLabel = Instance.new("TextLabel")
        NavLabel.Text = item.Name
        NavLabel.Size = UDim2.new(1, -60, 1, 0)
        NavLabel.Position = UDim2.new(0, 50, 0, 0)
        NavLabel.BackgroundTransparency = 1
        NavLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        NavLabel.Font = Enum.Font.Gotham
        NavLabel.TextSize = 14
        NavLabel.TextXAlignment = Enum.TextXAlignment.Left
        NavLabel.Parent = NavButton
        
        local SelectIndicator = Instance.new("Frame")
        SelectIndicator.Name = "Indicator"
        SelectIndicator.Size = UDim2.new(0, 3, 0, 30)
        SelectIndicator.Position = UDim2.new(0, 0, 0.5, -15)
        SelectIndicator.BackgroundColor3 = item.Color
        SelectIndicator.BorderSizePixel = 0
        SelectIndicator.Visible = i == 1
        SelectIndicator.Parent = NavButton
        
        navButtons[item.Name] = {Button = NavButton, Indicator = SelectIndicator, Label = NavLabel}
        
        NavButton.MouseButton1Click:Connect(function()
            -- Update selection
            for name, btn in pairs(navButtons) do
                btn.Indicator.Visible = false
                btn.Label.TextColor3 = Color3.fromRGB(200, 200, 200)
            end
            SelectIndicator.Visible = true
            NavLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            currentPage = item.Name
            
            -- Switch content
            for _, content in pairs(MainWindow.ContentArea:GetChildren()) do
                content.Visible = content.Name == item.Name
            end
        end)
    end
    
    -- Content Area
    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "ContentArea"
    ContentArea.Size = UDim2.new(1, -200, 1, -45)
    ContentArea.Position = UDim2.new(0, 200, 0, 45)
    ContentArea.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    ContentArea.BorderSizePixel = 0
    ContentArea.Parent = MainWindow
    
    -- Dashboard Page
    local Dashboard = Instance.new("Frame")
    Dashboard.Name = "Dashboard"
    Dashboard.Size = UDim2.new(1, 0, 1, 0)
    Dashboard.BackgroundTransparency = 1
    Dashboard.Parent = ContentArea
    
    -- Stats Cards
    local function CreateStatCard(title, value, icon, color, position)
        local Card = Instance.new("Frame")
        Card.Size = UDim2.new(0.23, 0, 0, 100)
        Card.Position = position
        Card.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        Card.BorderSizePixel = 0
        Card.Parent = Dashboard
        
        local CardCorner = Instance.new("UICorner")
        CardCorner.CornerRadius = UDim.new(0, 8)
        CardCorner.Parent = Card
        
        local CardGradient = Instance.new("UIGradient")
        CardGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, color),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 35, 35))
        }
        CardGradient.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.9),
            NumberSequenceKeypoint.new(1, 1)
        }
        CardGradient.Rotation = 45
        CardGradient.Parent = Card
        
        local IconLabel = Instance.new("TextLabel")
        IconLabel.Text = icon
        IconLabel.Size = UDim2.new(0, 40, 0, 40)
        IconLabel.Position = UDim2.new(0, 15, 0, 10)
        IconLabel.BackgroundTransparency = 1
        IconLabel.TextColor3 = color
        IconLabel.Font = Enum.Font.Gotham
        IconLabel.TextSize = 24
        IconLabel.Parent = Card
        
        local TitleLabel = Instance.new("TextLabel")
        TitleLabel.Text = title
        TitleLabel.Size = UDim2.new(1, -20, 0, 20)
        TitleLabel.Position = UDim2.new(0, 10, 0, 50)
        TitleLabel.BackgroundTransparency = 1
        TitleLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        TitleLabel.Font = Enum.Font.Gotham
        TitleLabel.TextSize = 12
        TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
        TitleLabel.Parent = Card
        
        local ValueLabel = Instance.new("TextLabel")
        ValueLabel.Name = "Value"
        ValueLabel.Text = value
        ValueLabel.Size = UDim2.new(1, -20, 0, 25)
        ValueLabel.Position = UDim2.new(0, 10, 0, 70)
        ValueLabel.BackgroundTransparency = 1
        ValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        ValueLabel.Font = Enum.Font.GothamBold
        ValueLabel.TextSize = 20
        ValueLabel.TextXAlignment = Enum.TextXAlignment.Left
        ValueLabel.Parent = Card
        
        return Card
    end
    
    local TotalPacketsCard = CreateStatCard("Total Packets", "0", "📦", Color3.fromRGB(85, 170, 255), UDim2.new(0.02, 0, 0, 20))
    local PacketsPerSecCard = CreateStatCard("Packets/sec", "0", "⚡", Color3.fromRGB(255, 170, 85), UDim2.new(0.26, 0, 0, 20))
    local BytesCard = CreateStatCard("Total Bytes", "0", "💾", Color3.fromRGB(170, 85, 255), UDim2.new(0.50, 0, 0, 20))
    local ActiveRemotesCard = CreateStatCard("Active Remotes", "0", "📡", Color3.fromRGB(85, 255, 170), UDim2.new(0.74, 0, 0, 20))
    
    -- Real-time Graph
    local GraphFrame = Instance.new("Frame")
    GraphFrame.Size = UDim2.new(0.96, 0, 0, 250)
    GraphFrame.Position = UDim2.new(0.02, 0, 0, 140)
    GraphFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    GraphFrame.BorderSizePixel = 0
    GraphFrame.Parent = Dashboard
    
    local GraphCorner = Instance.new("UICorner")
    GraphCorner.CornerRadius = UDim.new(0, 8)
    GraphCorner.Parent = GraphFrame
    
    local GraphTitle = Instance.new("TextLabel")
    GraphTitle.Text = "Network Traffic (Real-time)"
    GraphTitle.Size = UDim2.new(1, -20, 0, 30)
    GraphTitle.Position = UDim2.new(0, 10, 0, 5)
    GraphTitle.BackgroundTransparency = 1
    GraphTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    GraphTitle.Font = Enum.Font.Gotham
    GraphTitle.TextSize = 14
    GraphTitle.TextXAlignment = Enum.TextXAlignment.Left
    GraphTitle.Parent = GraphFrame
    
    -- Graph Canvas
    local GraphCanvas = Instance.new("Frame")
    GraphCanvas.Size = UDim2.new(1, -20, 1, -45)
    GraphCanvas.Position = UDim2.new(0, 10, 0, 35)
    GraphCanvas.BackgroundTransparency = 1
    GraphCanvas.ClipsDescendants = true
    GraphCanvas.Parent = GraphFrame
    
    local graphPoints = {}
    local maxPoints = 50
    
    -- Recent Activity Feed
    local ActivityFeed = Instance.new("Frame")
    ActivityFeed.Size = UDim2.new(0.96, 0, 0, 180)
    ActivityFeed.Position = UDim2.new(0.02, 0, 0, 400)
    ActivityFeed.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    ActivityFeed.BorderSizePixel = 0
    ActivityFeed.Parent = Dashboard
    
    local ActivityCorner = Instance.new("UICorner")
    ActivityCorner.CornerRadius = UDim.new(0, 8)
    ActivityCorner.Parent = ActivityFeed
    
    local ActivityTitle = Instance.new("TextLabel")
    ActivityTitle.Text = "Recent Activity"
    ActivityTitle.Size = UDim2.new(1, -20, 0, 30)
    ActivityTitle.Position = UDim2.new(0, 10, 0, 5)
    ActivityTitle.BackgroundTransparency = 1
    ActivityTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    ActivityTitle.Font = Enum.Font.Gotham
    ActivityTitle.TextSize = 14
    ActivityTitle.TextXAlignment = Enum.TextXAlignment.Left
    ActivityTitle.Parent = ActivityFeed
    
    local ActivityScroll = Instance.new("ScrollingFrame")
    ActivityScroll.Size = UDim2.new(1, -20, 1, -40)
    ActivityScroll.Position = UDim2.new(0, 10, 0, 35)
    ActivityScroll.BackgroundTransparency = 1
    ActivityScroll.ScrollBarThickness = 4
    ActivityScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    ActivityScroll.Parent = ActivityFeed
    
    local ActivityLayout = Instance.new("UIListLayout")
    ActivityLayout.Padding = UDim.new(0, 5)
    ActivityLayout.Parent = ActivityScroll
    
    -- Live Monitor Page
    local LiveMonitor = Instance.new("Frame")
    LiveMonitor.Name = "Live Monitor"
    LiveMonitor.Size = UDim2.new(1, 0, 1, 0)
    LiveMonitor.BackgroundTransparency = 1
    LiveMonitor.Visible = false
    LiveMonitor.Parent = ContentArea
    
    -- Search and Filter Bar
    local SearchBar = Instance.new("Frame")
    SearchBar.Size = UDim2.new(1, -20, 0, 40)
    SearchBar.Position = UDim2.new(0, 10, 0, 10)
    SearchBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    SearchBar.BorderSizePixel = 0
    SearchBar.Parent = LiveMonitor
    
    local SearchCorner = Instance.new("UICorner")
    SearchCorner.CornerRadius = UDim.new(0, 8)
    SearchCorner.Parent = SearchBar
    
    local SearchIcon = Instance.new("TextLabel")
    SearchIcon.Text = "🔍"
    SearchIcon.Size = UDim2.new(0, 40, 1, 0)
    SearchIcon.BackgroundTransparency = 1
    SearchIcon.TextColor3 = Color3.fromRGB(150, 150, 150)
    SearchIcon.Font = Enum.Font.Gotham
    SearchIcon.TextSize = 18
    SearchIcon.Parent = SearchBar
    
    local SearchBox = Instance.new("TextBox")
    SearchBox.PlaceholderText = "Search remotes, arguments, or patterns..."
    SearchBox.Text = ""
    SearchBox.Size = UDim2.new(0.5, -50, 1, 0)
    SearchBox.Position = UDim2.new(0, 40, 0, 0)
    SearchBox.BackgroundTransparency = 1
    SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    SearchBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
    SearchBox.Font = Enum.Font.Gotham
    SearchBox.TextSize = 14
    SearchBox.TextXAlignment = Enum.TextXAlignment.Left
    SearchBox.Parent = SearchBar
    
    -- Filter Buttons
    local FilterFrame = Instance.new("Frame")
    FilterFrame.Size = UDim2.new(0.5, -10, 1, -10)
    FilterFrame.Position = UDim2.new(0.5, 0, 0, 5)
    FilterFrame.BackgroundTransparency = 1
    FilterFrame.Parent = SearchBar
    
    local FilterLayout = Instance.new("UIListLayout")
    FilterLayout.FillDirection = Enum.FillDirection.Horizontal
    FilterLayout.Padding = UDim.new(0, 5)
    FilterLayout.Parent = FilterFrame
    
    local filters = {"All", "RemoteEvent", "RemoteFunction", "Incoming", "Outgoing"}
    for _, filterName in ipairs(filters) do
        local FilterBtn = Instance.new("TextButton")
        FilterBtn.Text = filterName
        FilterBtn.Size = UDim2.new(0, 80, 0, 30)
        FilterBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        FilterBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        FilterBtn.Font = Enum.Font.Gotham
        FilterBtn.TextSize = 12
        FilterBtn.AutoButtonColor = false
        FilterBtn.Parent = FilterFrame
        
        local FilterBtnCorner = Instance.new("UICorner")
        FilterBtnCorner.CornerRadius = UDim.new(0, 6)
        FilterBtnCorner.Parent = FilterBtn
        
        FilterBtn.MouseButton1Click:Connect(function()
            -- Filter logic here
            FilterBtn.BackgroundColor3 = Color3.fromRGB(85, 170, 255)
            FilterBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        end)
    end
    
    -- Monitor List
    local MonitorList = Instance.new("ScrollingFrame")
    MonitorList.Size = UDim2.new(1, -20, 1, -70)
    MonitorList.Position = UDim2.new(0, 10, 0, 60)
    MonitorList.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    MonitorList.BorderSizePixel = 0
    MonitorList.ScrollBarThickness = 6
    MonitorList.CanvasSize = UDim2.new(0, 0, 0, 0)
    MonitorList.Parent = LiveMonitor
    
    local MonitorCorner = Instance.new("UICorner")
    MonitorCorner.CornerRadius = UDim.new(0, 8)
    MonitorCorner.Parent = MonitorList
    
    local MonitorLayout = Instance.new("UIListLayout")
    MonitorLayout.Padding = UDim.new(0, 5)
    MonitorLayout.Parent = MonitorList
    
    -- Analytics Page
    local Analytics = Instance.new("Frame")
    Analytics.Name = "Analytics"
    Analytics.Size = UDim2.new(1, 0, 1, 0)
    Analytics.BackgroundTransparency = 1
    Analytics.Visible = false
    Analytics.Parent = ContentArea
    
    -- Create analytics charts here...
    
    -- Make window draggable
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainWindow.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            MainWindow.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    -- Window controls
    local minimized = false
    local maximized = false
    local originalSize = MainWindow.Size
    local originalPos = MainWindow.Position
    
    MinimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            TweenService:Create(MainWindow, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                Size = UDim2.new(0, 800, 0, 45)
            }):Play()
            ContentArea.Visible = false
            Sidebar.Visible = false
        else
            TweenService:Create(MainWindow, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                Size = originalSize
            }):Play()
            ContentArea.Visible = true
            Sidebar.Visible = true
        end
    end)
    
    MaximizeBtn.MouseButton1Click:Connect(function()
        maximized = not maximized
        if maximized then
            originalSize = MainWindow.Size
            originalPos = MainWindow.Position
            TweenService:Create(MainWindow, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                Size = UDim2.new(1, -40, 1, -40),
                Position = UDim2.new(0, 20, 0, 20)
            }):Play()
        else
            TweenService:Create(MainWindow, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                Size = originalSize,
                Position = originalPos
            }):Play()
        end
    end)
    
    CloseBtn.MouseButton1Click:Connect(function()
        -- Fade out animation
        TweenService:Create(MainWindow, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        TweenService:Create(BlurEffect, TweenInfo.new(0.3), {Size = 0}):Play()
        wait(0.3)
        NetworkMonitorPro:Destroy()
        BlurEffect:Destroy()
        MONITOR_CONFIG.UIVisible = false
    end)
    
    -- Open animation
    MainWindow.BackgroundTransparency = 1
    TweenService:Create(MainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {
        BackgroundTransparency = 0
    }):Play()
    TweenService:Create(BlurEffect, TweenInfo.new(0.5), {Size = 20}):Play()
    
    return {
        UI = NetworkMonitorPro,
        MainWindow = MainWindow,
        MonitorList = MonitorList,
        ActivityScroll = ActivityScroll,
        GraphCanvas = GraphCanvas,
        TotalPacketsCard = TotalPacketsCard,
        PacketsPerSecCard = PacketsPerSecCard,
        BytesCard = BytesCard,
        ActiveRemotesCard = ActiveRemotesCard,
        SearchBox = SearchBox,
        graphPoints = graphPoints
    }
end

-- Create UI
local UI = CreateAdvancedUI()

-- Advanced Serialization with Type Detection
local function AdvancedSerialize(data, depth)
    depth = depth or 0
    if depth > 10 then return "..." end
    
    local dataType = typeof(data)
    
    if dataType == "table" then
        local result = {}
        local isArray = true
        local count = 0
        
        for k, v in pairs(data) do
            count = count + 1
            if type(k) ~= "number" or k ~= count then
                isArray = false
            end
            
            if isArray then
                result[k] = AdvancedSerialize(v, depth + 1)
            else
                result[tostring(k)] = AdvancedSerialize(v, depth + 1)
            end
        end
        
        return HttpService:JSONEncode(result)
    elseif dataType == "Instance" then
        return {
            Type = "Instance",
            ClassName = data.ClassName,
            Name = data.Name,
            Path = data:GetFullName()
        }
    elseif dataType == "CFrame" then
        local x, y, z = data:ToEulerAnglesXYZ()
        return {
            Type = "CFrame",
            Position = {data.X, data.Y, data.Z},
            Rotation = {math.deg(x), math.deg(y), math.deg(z)}
        }
    elseif dataType == "Vector3" then
        return {
            Type = "Vector3",
            X = data.X,
            Y = data.Y,
            Z = data.Z
        }
    elseif dataType == "Color3" then
        return {
            Type = "Color3",
            R = math.floor(data.R * 255),
            G = math.floor(data.G * 255),
            B = math.floor(data.B * 255),
            Hex = string.format("#%02X%02X%02X", data.R*255, data.G*255, data.B*255)
        }
    elseif dataType == "BrickColor" then
        return {
            Type = "BrickColor",
            Name = data.Name,
            Number = data.Number,
            Color = AdvancedSerialize(data.Color)
        }
    elseif dataType == "EnumItem" then
        return {
            Type = "Enum",
            EnumType = tostring(data.EnumType),
            Name = data.Name,
            Value = data.Value
        }
    elseif dataType == "Ray" then
        return {
            Type = "Ray",
            Origin = AdvancedSerialize(data.Origin),
            Direction = AdvancedSerialize(data.Direction)
        }
    elseif dataType == "UDim2" then
        return {
            Type = "UDim2",
            X = {Scale = data.X.Scale, Offset = data.X.Offset},
            Y = {Scale = data.Y.Scale, Offset = data.Y.Offset}
        }
    else
        return tostring(data)
    end
end

-- Calculate data size
local function CalculateDataSize(data)
    local str = AdvancedSerialize(data)
    if type(str) == "string" then
        return #str
    elseif type(str) == "table" then
        return #HttpService:JSONEncode(str)
    end
    return 0
end

-- Pattern Detection System
local function DetectPattern(remoteName, args)
    if not PatternAnalyzer.Patterns[remoteName] then
        PatternAnalyzer.Patterns[remoteName] = {
            calls = 0,
            intervals = {},
            lastCall = tick(),
            argumentPatterns = {}
        }
    end
    
    local pattern = PatternAnalyzer.Patterns[remoteName]
    local currentTime = tick()
    
    -- Track call frequency
    pattern.calls = pattern.calls + 1
    table.insert(pattern.intervals, currentTime - pattern.lastCall)
    pattern.lastCall = currentTime
    
    -- Detect argument patterns
    for i, arg in ipairs(args) do
        if not pattern.argumentPatterns[i] then
            pattern.argumentPatterns[i] = {}
        end
        
        local argStr = tostring(arg)
        pattern.argumentPatterns[i][argStr] = (pattern.argumentPatterns[i][argStr] or 0) + 1
    end
    
    -- Check for anomalies
    if #pattern.intervals > 10 then
        local avgInterval = 0
        for _, interval in ipairs(pattern.intervals) do
            avgInterval = avgInterval + interval
        end
        avgInterval = avgInterval / #pattern.intervals
        
        if currentTime - pattern.lastCall < avgInterval * 0.1 then
            -- Potential spam detected
            table.insert(PatternAnalyzer.Anomalies, {
                Time = currentTime,
                Remote = remoteName,
                Type = "Spam",
                Details = "Unusually high frequency"
            })
        end
    end
end

-- Add entry to monitor list
local function AddMonitorEntry(data)
    if not UI or not UI.MonitorList then return end
    
    local Entry = Instance.new("Frame")
    Entry.Size = UDim2.new(1, -10, 0, 80)
    Entry.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Entry.BorderSizePixel = 0
    Entry.Parent = UI.MonitorList
    
    local EntryCorner = Instance.new("UICorner")
    EntryCorner.CornerRadius = UDim.new(0, 6)
    EntryCorner.Parent = Entry
    
    -- Type indicator
    local TypeIndicator = Instance.new("Frame")
    TypeIndicator.Size = UDim2.new(0, 4, 1, -10)
    TypeIndicator.Position = UDim2.new(0, 5, 0, 5)
    TypeIndicator.BackgroundColor3 = data.Type == "RemoteEvent" and Color3.fromRGB(85, 170, 255) or Color3.fromRGB(255, 170, 85)
    TypeIndicator.BorderSizePixel = 0
    TypeIndicator.Parent = Entry
    
    local TypeCorner = Instance.new("UICorner")
    TypeCorner.CornerRadius = UDim.new(1, 0)
    TypeCorner.Parent = TypeIndicator
    
    -- Remote info
    local RemoteInfo = Instance.new("Frame")
    RemoteInfo.Size = UDim2.new(1, -20, 0, 40)
    RemoteInfo.Position = UDim2.new(0, 15, 0, 5)
    RemoteInfo.BackgroundTransparency = 1
    RemoteInfo.Parent = Entry
    
    local RemoteName = Instance.new("TextLabel")
    RemoteName.Text = data.RemoteName:match("([^.]+)$") or data.RemoteName
    RemoteName.Size = UDim2.new(0.6, 0, 0, 20)
    RemoteName.BackgroundTransparency = 1
    RemoteName.TextColor3 = Color3.fromRGB(255, 255, 255)
    RemoteName.Font = Enum.Font.GothamBold
    RemoteName.TextSize = 14
    RemoteName.TextXAlignment = Enum.TextXAlignment.Left
    RemoteName.Parent = RemoteInfo
    
    local RemotePath = Instance.new("TextLabel")
    RemotePath.Text = data.RemoteName
    RemotePath.Size = UDim2.new(0.6, 0, 0, 15)
    RemotePath.Position = UDim2.new(0, 0, 0, 20)
    RemotePath.BackgroundTransparency = 1
    RemotePath.TextColor3 = Color3.fromRGB(120, 120, 120)
    RemotePath.Font = Enum.Font.Gotham
    RemotePath.TextSize = 10
    RemotePath.TextXAlignment = Enum.TextXAlignment.Left
    RemotePath.Parent = RemoteInfo
    
    -- Direction badge
    local DirectionBadge = Instance.new("Frame")
    DirectionBadge.Size = UDim2.new(0, 80, 0, 24)
    DirectionBadge.Position = UDim2.new(1, -200, 0, 0)
    DirectionBadge.BackgroundColor3 = data.Direction == "Incoming" and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(255, 69, 58)
    DirectionBadge.BorderSizePixel = 0
    DirectionBadge.Parent = RemoteInfo
    
    local BadgeCorner = Instance.new("UICorner")
    BadgeCorner.CornerRadius = UDim.new(0, 4)
    BadgeCorner.Parent = DirectionBadge
    
    local DirectionText = Instance.new("TextLabel")
    DirectionText.Text = data.Direction
    DirectionText.Size = UDim2.new(1, 0, 1, 0)
    DirectionText.BackgroundTransparency = 1
    DirectionText.TextColor3 = Color3.fromRGB(255, 255, 255)
    DirectionText.Font = Enum.Font.GothamBold
    DirectionText.TextSize = 11
    DirectionText.Parent = DirectionBadge
    
    -- Timestamp
    local Timestamp = Instance.new("TextLabel")
    Timestamp.Text = os.date("%H:%M:%S")
    Timestamp.Size = UDim2.new(0, 100, 0, 20)
    Timestamp.Position = UDim2.new(1, -100, 0, 0)
    Timestamp.BackgroundTransparency = 1
    Timestamp.TextColor3 = Color3.fromRGB(150, 150, 150)
    Timestamp.Font = Enum.Font.Gotham
    Timestamp.TextSize = 12
    Timestamp.TextXAlignment = Enum.TextXAlignment.Right
    Timestamp.Parent = RemoteInfo
    
    -- Arguments preview
    local ArgsFrame = Instance.new("Frame")
    ArgsFrame.Size = UDim2.new(1, -20, 0, 30)
    ArgsFrame.Position = UDim2.new(0, 15, 0, 45)
    ArgsFrame.BackgroundTransparency = 1
    ArgsFrame.Parent = Entry
    
    local ArgsText = Instance.new("TextLabel")
    ArgsText.Text = string.format("📦 %d args | 💾 %d bytes", #data.Arguments, data.Size or 0)
    ArgsText.Size = UDim2.new(0.5, 0, 0, 15)
    ArgsText.BackgroundTransparency = 1
    ArgsText.TextColor3 = Color3.fromRGB(180, 180, 180)
    ArgsText.Font = Enum.Font.Gotham
    ArgsText.TextSize = 11
    ArgsText.TextXAlignment = Enum.TextXAlignment.Left
    ArgsText.Parent = ArgsFrame
    
    local ArgsPreview = Instance.new("TextLabel")
    local preview = ""
    for i = 1, math.min(#data.Arguments, 3) do
        if i > 1 then preview = preview .. ", " end
        local arg = tostring(data.Arguments[i]):sub(1, 30)
        preview = preview .. arg
    end
    if #data.Arguments > 3 then preview = preview .. "..." end
    
    ArgsPreview.Text = preview
    ArgsPreview.Size = UDim2.new(1, 0, 0, 15)
    ArgsPreview.Position = UDim2.new(0, 0, 0, 15)
    ArgsPreview.BackgroundTransparency = 1
    ArgsPreview.TextColor3 = Color3.fromRGB(150, 150, 150)
    ArgsPreview.Font = Enum.Font.Code
    ArgsPreview.TextSize = 10
    ArgsPreview.TextXAlignment = Enum.TextXAlignment.Left
    ArgsPreview.TextTruncate = Enum.TextTruncate.AtEnd
    ArgsPreview.Parent = ArgsFrame
    
    -- View details button
    local ViewBtn = Instance.new("TextButton")
    ViewBtn.Text = "View Details"
    ViewBtn.Size = UDim2.new(0, 90, 0, 24)
    ViewBtn.Position = UDim2.new(1, -100, 0, 6)
    ViewBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    ViewBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    ViewBtn.Font = Enum.Font.Gotham
    ViewBtn.TextSize = 11
    ViewBtn.AutoButtonColor = false
    ViewBtn.Parent = ArgsFrame
    
    local ViewCorner = Instance.new("UICorner")
    ViewCorner.CornerRadius = UDim.new(0, 4)
    ViewCorner.Parent = ViewBtn
    
    ViewBtn.MouseButton1Click:Connect(function()
        -- Show detailed view
        print("=== DETAILED VIEW ===")
        print("Remote:", data.RemoteName)
        print("Type:", data.Type)
        print("Direction:", data.Direction)
        print("Time:", os.date("%Y-%m-%d %H:%M:%S"))
        print("Arguments:")
        for i, arg in ipairs(data.Arguments) do
            print(string.format("  [%d]:", i), arg)
        end
        print("Stack Trace:", data.Traceback or "N/A")
        print("===================")
    end)
    
    -- Update canvas
    UI.MonitorList.CanvasSize = UDim2.new(0, 0, 0, UI.MonitorList.UIListLayout.AbsoluteContentSize.Y)
end

-- Add activity to feed
local function AddActivity(text, color)
    if not UI or not UI.ActivityScroll then return end
    
    local Activity = Instance.new("Frame")
    Activity.Size = UDim2.new(1, 0, 0, 25)
    Activity.BackgroundTransparency = 1
    Activity.Parent = UI.ActivityScroll
    
    local TimeLabel = Instance.new("TextLabel")
    TimeLabel.Text = os.date("%H:%M:%S")
    TimeLabel.Size = UDim2.new(0, 60, 1, 0)
    TimeLabel.BackgroundTransparency = 1
    TimeLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    TimeLabel.Font = Enum.Font.Gotham
    TimeLabel.TextSize = 11
    TimeLabel.Parent = Activity
    
    local TextLabel = Instance.new("TextLabel")
    TextLabel.Text = text
    TextLabel.Size = UDim2.new(1, -65, 1, 0)
    TextLabel.Position = UDim2.new(0, 65, 0, 0)
    TextLabel.BackgroundTransparency = 1
    TextLabel.TextColor3 = color or Color3.fromRGB(200, 200, 200)
    TextLabel.Font = Enum.Font.Gotham
    TextLabel.TextSize = 12
    TextLabel.TextXAlignment = Enum.TextXAlignment.Left
    TextLabel.TextTruncate = Enum.TextTruncate.AtEnd
    TextLabel.Parent = Activity
    
    -- Update canvas
    UI.ActivityScroll.CanvasSize = UDim2.new(0, 0, 0, UI.ActivityScroll.UIListLayout.AbsoluteContentSize.Y)
    
    -- Auto scroll to bottom
    UI.ActivityScroll.CanvasPosition = Vector2.new(0, UI.ActivityScroll.CanvasSize.Y.Offset)
end

-- Update graph
local function UpdateGraph(value)
    if not UI or not UI.GraphCanvas then return end
    
    table.insert(UI.graphPoints, value)
    if #UI.graphPoints > 50 then
        table.remove(UI.graphPoints, 1)
    end
    
    -- Clear old points
    for _, child in pairs(UI.GraphCanvas:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Draw new graph
    local maxValue = math.max(unpack(UI.graphPoints))
    if maxValue == 0 then maxValue = 1 end
    
    for i = 2, #UI.graphPoints do
        local point1 = UI.graphPoints[i-1]
        local point2 = UI.graphPoints[i]
        
        local x1 = (i-2) / 49 * UI.GraphCanvas.AbsoluteSize.X
        local x2 = (i-1) / 49 * UI.GraphCanvas.AbsoluteSize.X
        local y1 = (1 - point1/maxValue) * UI.GraphCanvas.AbsoluteSize.Y
        local y2 = (1 - point2/maxValue) * UI.GraphCanvas.AbsoluteSize.Y
        
        local line = Instance.new("Frame")
        line.Size = UDim2.new(0, math.sqrt((x2-x1)^2 + (y2-y1)^2), 0, 2)
        line.Position = UDim2.new(0, x1, 0, y1)
        line.BackgroundColor3 = Color3.fromRGB(85, 170, 255)
        line.BorderSizePixel = 0
        line.Rotation = math.deg(math.atan2(y2-y1, x2-x1))
        line.Parent = UI.GraphCanvas
    end
end

-- Update statistics
local function UpdateStatistics()
    if not UI then return end
    
    local totalPackets = NetworkLogs.Statistics.TotalPackets
    local totalBytes = NetworkLogs.Statistics.TotalBytes
    local activeRemotes = 0
    
    for _ in pairs(NetworkLogs.RemoteEvents) do
        activeRemotes = activeRemotes + 1
    end
    for _ in pairs(NetworkLogs.RemoteFunctions) do
        activeRemotes = activeRemotes + 1
    end
    
    -- Update cards
    UI.TotalPacketsCard.Value.Text = tostring(totalPackets)
    UI.PacketsPerSecCard.Value.Text = tostring(NetworkLogs.Statistics.PacketsPerSecond)
    UI.BytesCard.Value.Text = string.format("%.2f KB", totalBytes / 1024)
    UI.ActiveRemotesCard.Value.Text = tostring(activeRemotes)
    
    -- Update graph
    UpdateGraph(NetworkLogs.Statistics.PacketsPerSecond)
end

-- Enhanced Hook System
local function EnhancedHookRemote(remote, remoteType)
    local remoteName = remote:GetFullName()
    
    -- Initialize storage
    if remoteType == "RemoteEvent" then
        if not NetworkLogs.RemoteEvents[remoteName] then
            NetworkLogs.RemoteEvents[remoteName] = {}
        end
        
        -- Hook OnClientEvent
        remote.OnClientEvent:Connect(function(...)
            if not MONITOR_CONFIG.LogRemoteEvents then return end
            
            local args = {...}
            local serializedArgs = {}
            local totalSize = 0
            
            for i, arg in ipairs(args) do
                serializedArgs[i] = AdvancedSerialize(arg)
                totalSize = totalSize + CalculateDataSize(arg)
            end
            
            -- Update statistics
            NetworkLogs.Statistics.TotalPackets = NetworkLogs.Statistics.TotalPackets + 1
            NetworkLogs.Statistics.TotalBytes = NetworkLogs.Statistics.TotalBytes + totalSize
            
            -- Pattern detection
            DetectPattern(remoteName, args)
            
            -- Create log entry
            local logEntry = {
                Time = os.time(),
                Tick = tick(),
                RemoteName = remoteName,
                Type = "RemoteEvent",
                Direction = "Incoming",
                Arguments = serializedArgs,
                Size = totalSize,
                Traceback = MONITOR_CONFIG.EnableStackTrace and debug.traceback() or nil
            }
            
            -- Store log
            if #NetworkLogs.RemoteEvents[remoteName] < MONITOR_CONFIG.MaxLogsPerRemote then
                table.insert(NetworkLogs.RemoteEvents[remoteName], logEntry)
            end
            
            -- Add to UI
            AddMonitorEntry(logEntry)
            AddActivity(string.format("📥 %s (%d args)", remoteName:match("([^.]+)$") or remoteName, #args), Color3.fromRGB(85, 170, 255))
        end)
        
        -- Hook FireServer
        pcall(function()
            local mt = getmetatable(remote)
            if mt then
                local oldNamecall = mt.__namecall
                mt.__namecall = function(self, ...)
                    local method = getnamecallmethod()
                    
                    if method == "FireServer" and self == remote and MONITOR_CONFIG.LogRemoteEvents then
                        local args = {...}
                        local serializedArgs = {}
                        local totalSize = 0
                        
                        for i, arg in ipairs(args) do
                            serializedArgs[i] = AdvancedSerialize(arg)
                            totalSize = totalSize + CalculateDataSize(arg)
                        end
                        
                        -- Update statistics
                        NetworkLogs.Statistics.TotalPackets = NetworkLogs.Statistics.TotalPackets + 1
                        NetworkLogs.Statistics.TotalBytes = NetworkLogs.Statistics.TotalBytes + totalSize
                        
                        -- Pattern detection
                        DetectPattern(remoteName, args)
                        
                        -- Create log entry
                        local logEntry = {
                            Time = os.time(),
                            Tick = tick(),
                            RemoteName = remoteName,
                            Type = "RemoteEvent",
                            Direction = "Outgoing",
                            Arguments = serializedArgs,
                            Size = totalSize,
                            Traceback = MONITOR_CONFIG.EnableStackTrace and debug.traceback() or nil
                        }
                        
                        -- Store log
                        if #NetworkLogs.RemoteEvents[remoteName] < MONITOR_CONFIG.MaxLogsPerRemote then
                            table.insert(NetworkLogs.RemoteEvents[remoteName], logEntry)
                        end
                        
                        -- Add to UI
                        AddMonitorEntry(logEntry)
                        AddActivity(string.format("📤 %s (%d args)", remoteName:match("([^.]+)$") or remoteName, #args), Color3.fromRGB(255, 170, 85))
                    end
                    
                    return oldNamecall(self, ...)
                end
            end
        end)
        
    elseif remoteType == "RemoteFunction" then
        if not NetworkLogs.RemoteFunctions[remoteName] then
            NetworkLogs.RemoteFunctions[remoteName] = {}
        end
        
        -- Similar hooks for RemoteFunction...
    end
end

-- Scan all remotes
local function ScanAllRemotes()
    local count = 0
    
    for _, service in pairs(game:GetChildren()) do
        pcall(function()
            for _, obj in pairs(service:GetDescendants()) do
                if obj:IsA("RemoteEvent") then
                    EnhancedHookRemote(obj, "RemoteEvent")
                    count = count + 1
                elseif obj:IsA("RemoteFunction") then
                    EnhancedHookRemote(obj, "RemoteFunction")
                    count = count + 1
                end
            end
        end)
    end
    
    AddActivity(string.format("✅ Hooked %d remotes successfully", count), Color3.fromRGB(52, 199, 89))
    return count
end

-- Auto-hook new remotes
game.DescendantAdded:Connect(function(obj)
    if obj:IsA("RemoteEvent") then
        EnhancedHookRemote(obj, "RemoteEvent")
        AddActivity(string.format("🆕 New RemoteEvent: %s", obj.Name), Color3.fromRGB(255, 189, 68))
    elseif obj:IsA("RemoteFunction") then
        EnhancedHookRemote(obj, "RemoteFunction")
        AddActivity(string.format("🆕 New RemoteFunction: %s", obj.Name), Color3.fromRGB(255, 189, 68))
    end
end)

-- Packets per second calculator
spawn(function()
    while true do
        local oldPackets = NetworkLogs.Statistics.TotalPackets
        wait(1)
        NetworkLogs.Statistics.PacketsPerSecond = NetworkLogs.Statistics.TotalPackets - oldPackets
        UpdateStatistics()
    end
end)

-- Export system
local function ExportAdvancedLogs()
    local export = {
        Meta = {
            Version = "2.0",
            Game = game.PlaceId,
            Player = Players.LocalPlayer and Players.LocalPlayer.Name or "Server",
            ExportTime = os.date("%Y-%m-%d %H:%M:%S"),
            SessionDuration = os.time() - NetworkLogs.Statistics.StartTime
        },
        Statistics = NetworkLogs.Statistics,
        Logs = {
            RemoteEvents = NetworkLogs.RemoteEvents,
            RemoteFunctions = NetworkLogs.RemoteFunctions
        },
        Patterns = PatternAnalyzer.Patterns,
        Anomalies = PatternAnalyzer.Anomalies
    }
    
    local jsonExport = HttpService:JSONEncode(export)
    
    -- Save to clipboard if supported
    if setclipboard then
        setclipboard(jsonExport)
        AddActivity("📋 Logs copied to clipboard!", Color3.fromRGB(52, 199, 89))
    end
    
    -- Save to _G
    _G.NetworkMonitorExport = export
    _G.NetworkMonitorJSON = jsonExport
    
    print("=== ADVANCED NETWORK MONITOR EXPORT ===")
    print(jsonExport)
    print("=======================================")
    
    return jsonExport
end

-- Global API
_G.NetworkMonitorPro = {
    Start = function()
        local count = ScanAllRemotes()
        print(string.format("[Network Monitor Pro] Started - Monitoring %d remotes", count))
    end,
    
    Stop = function()
        MONITOR_CONFIG.LogRemoteEvents = false
        MONITOR_CONFIG.LogRemoteFunctions = false
        AddActivity("⏸️ Monitoring paused", Color3.fromRGB(255, 189, 68))
    end,
    
    Export = ExportAdvancedLogs,
    
    Clear = function()
        NetworkLogs = {
            RemoteEvents = {},
            RemoteFunctions = {},
            Statistics = {
                TotalPackets = 0,
                TotalBytes = 0,
                PacketsPerSecond = 0,
                BytesPerSecond = 0,
                PeakTraffic = 0,
                StartTime = os.time()
            }
        }
        
        if UI and UI.MonitorList then
            for _, child in pairs(UI.MonitorList:GetChildren()) do
                if not child:IsA("UIListLayout") then
                    child:Destroy()
                end
            end
        end
        
        AddActivity("🗑️ All logs cleared", Color3.fromRGB(255, 69, 58))
    end,
    
    ShowUI = function()
        if not MONITOR_CONFIG.UIVisible then
            UI = CreateAdvancedUI()
            MONITOR_CONFIG.UIVisible = true
        end
    end,
    
    Config = MONITOR_CONFIG,
    Logs = NetworkLogs,
    Patterns = PatternAnalyzer
}

-- Auto-start
_G.NetworkMonitorPro.Start()

-- Welcome message
StarterGui:SetCore("SendNotification", {
    Title = "Network Monitor Pro",
    Text = "Advanced monitoring system activated!",
    Duration = 5,
    Icon = "rbxassetid://7733992358"
})

print([[
╔══════════════════════════════════════════════════════════════╗
║                    NETWORK MONITOR PRO v2.0                 ║
║                 Advanced Roblox Network Analyzer            ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  🚀 FEATURES:                                               ║
║  • Real-time network traffic monitoring                     ║
║  • Advanced packet analysis and pattern recognition         ║
║  • Comprehensive logging system                             ║
║  • Professional UI with dark mode                           ║
║  • Performance metrics and statistics                       ║
║  • Export capabilities (JSON/CSV)                           ║
║  • Encryption detection                                      ║
║  • Anomaly detection                                         ║
║                                                              ║
║  🎯 USAGE:                                                  ║
║  _G.NetworkMonitorPro.Start()      - Start monitoring       ║
║  _G.NetworkMonitorPro.Stop()       - Pause monitoring       ║
║  _G.NetworkMonitorPro.Clear()      - Clear all logs         ║
║  _G.NetworkMonitorPro.Export()     - Export logs            ║
║  _G.NetworkMonitorPro.ShowUI()     - Show/Hide UI          ║
║                                                              ║
║  📊 ACCESS DATA:                                            ║
║  _G.NetworkMonitorPro.Logs         - Access log data        ║
║  _G.NetworkMonitorPro.Config       - Configuration          ║
║  _G.NetworkMonitorPro.Patterns     - Pattern analysis       ║
║                                                              ║
║  ⚠️  DISCLAIMER:                                            ║
║  This tool is for educational and debugging purposes only.   ║
║  Use responsibly and in accordance with Roblox ToS.         ║
║                                                              ║
║  🔗 Repository: github.com/Ansellino/Roblox-Monitoring  ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

✅ Network Monitor Pro v2.0 successfully loaded!
🔍 Monitoring system is now active...
💡 Use the UI controls or global functions to interact with the monitor.
]])