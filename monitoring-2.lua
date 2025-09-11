-- Advanced Roblox Network Monitor & Remote Spy
-- Full-featured remote spy with detailed parameter logging
-- For educational and debugging purposes only

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Configuration
local MONITOR_CONFIG = {
    LogRemoteEvents = true,
    LogRemoteFunctions = true,
    LogBindableEvents = true,
    LogBindableFunctions = true,
    MaxLogsPerRemote = 500,
    SaveInterval = 30,
    UIVisible = true,
    LogReturnValues = true,
    GenerateScript = true,
    DetailedMode = true
}

-- Storage for network logs
local NetworkLogs = {
    RemoteEvents = {},
    RemoteFunctions = {},
    BindableEvents = {},
    BindableFunctions = {},
    StartTime = os.time(),
    Player = Players.LocalPlayer and Players.LocalPlayer.Name or "Server"
}

-- Hooked remotes tracking
local HookedRemotes = {}
local RemoteHooks = {}

-- Create UI function
local function CreateUI()
    -- Main ScreenGui
    local NetworkMonitorUI = Instance.new("ScreenGui")
    NetworkMonitorUI.Name = "AdvancedNetworkMonitor"
    NetworkMonitorUI.ResetOnSpawn = false
    NetworkMonitorUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Try to parent to CoreGui
    pcall(function()
        NetworkMonitorUI.Parent = CoreGui
    end)
    if not NetworkMonitorUI.Parent then
        NetworkMonitorUI.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 700, 0, 500)
    MainFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = NetworkMonitorUI
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = MainFrame
    
    -- Shadow
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.Size = UDim2.new(1, 30, 1, 30)
    Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    Shadow.ImageColor3 = Color3.new(0, 0, 0)
    Shadow.ImageTransparency = 0.5
    Shadow.ZIndex = -1
    Shadow.Parent = MainFrame
    
    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 35)
    TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 8)
    TitleCorner.Parent = TitleBar
    
    local TitleFix = Instance.new("Frame")
    TitleFix.Size = UDim2.new(1, 0, 0, 8)
    TitleFix.Position = UDim2.new(0, 0, 1, -8)
    TitleFix.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    TitleFix.BorderSizePixel = 0
    TitleFix.Parent = TitleBar
    
    -- Title Text
    local TitleText = Instance.new("TextLabel")
    TitleText.Text = "🔍 Advanced Network Monitor & Remote Spy"
    TitleText.Size = UDim2.new(0.7, 0, 1, 0)
    TitleText.Position = UDim2.new(0, 10, 0, 0)
    TitleText.BackgroundTransparency = 1
    TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleText.TextSize = 16
    TitleText.Font = Enum.Font.Gotham
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    TitleText.Parent = TitleBar
    
    -- Window Controls
    local Controls = Instance.new("Frame")
    Controls.Size = UDim2.new(0, 70, 1, 0)
    Controls.Position = UDim2.new(1, -70, 0, 0)
    Controls.BackgroundTransparency = 1
    Controls.Parent = TitleBar
    
    local MinimizeBtn = Instance.new("TextButton")
    MinimizeBtn.Text = "—"
    MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
    MinimizeBtn.Position = UDim2.new(0, 0, 0.5, -15)
    MinimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinimizeBtn.Font = Enum.Font.Gotham
    MinimizeBtn.TextSize = 20
    MinimizeBtn.Parent = Controls
    
    local MinCorner = Instance.new("UICorner")
    MinCorner.CornerRadius = UDim.new(0, 6)
    MinCorner.Parent = MinimizeBtn
    
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Text = "✕"
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(0, 35, 0.5, -15)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.Font = Enum.Font.Gotham
    CloseBtn.TextSize = 18
    CloseBtn.Parent = Controls
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 6)
    CloseCorner.Parent = CloseBtn
    
    -- Tab Container
    local TabContainer = Instance.new("Frame")
    TabContainer.Size = UDim2.new(1, -20, 0, 35)
    TabContainer.Position = UDim2.new(0, 10, 0, 40)
    TabContainer.BackgroundTransparency = 1
    TabContainer.Parent = MainFrame
    
    local TabLayout = Instance.new("UIListLayout")
    TabLayout.FillDirection = Enum.FillDirection.Horizontal
    TabLayout.Padding = UDim.new(0, 5)
    TabLayout.Parent = TabContainer
    
    -- Create Tab Function
    local function CreateTab(text, icon)
        local Tab = Instance.new("TextButton")
        Tab.Text = icon .. " " .. text
        Tab.Size = UDim2.new(0, 120, 1, 0)
        Tab.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        Tab.TextColor3 = Color3.fromRGB(200, 200, 200)
        Tab.Font = Enum.Font.Gotham
        Tab.TextSize = 14
        Tab.Parent = TabContainer
        
        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 6)
        TabCorner.Parent = Tab
        
        return Tab
    end
    
    local RemotesTab = CreateTab("Remotes", "📡")
    local ScriptTab = CreateTab("Script Gen", "📝")
    local StatsTab = CreateTab("Statistics", "📊")
    local SettingsTab = CreateTab("Settings", "⚙️")
    local ExportTab = CreateTab("Export", "💾")
    
    -- Content Container
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Size = UDim2.new(1, -20, 1, -90)
    ContentContainer.Position = UDim2.new(0, 10, 0, 80)
    ContentContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    ContentContainer.Parent = MainFrame
    
    local ContentCorner = Instance.new("UICorner")
    ContentCorner.CornerRadius = UDim.new(0, 6)
    ContentCorner.Parent = ContentContainer
    
    -- Remotes Content
    local RemotesContent = Instance.new("Frame")
    RemotesContent.Size = UDim2.new(1, 0, 1, 0)
    RemotesContent.BackgroundTransparency = 1
    RemotesContent.Parent = ContentContainer
    
    -- Search Bar
    local SearchBar = Instance.new("TextBox")
    SearchBar.Size = UDim2.new(1, -20, 0, 30)
    SearchBar.Position = UDim2.new(0, 10, 0, 10)
    SearchBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    SearchBar.TextColor3 = Color3.fromRGB(255, 255, 255)
    SearchBar.PlaceholderText = "🔍 Search remotes..."
    SearchBar.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    SearchBar.Font = Enum.Font.Gotham
    SearchBar.TextSize = 14
    SearchBar.Text = ""
    SearchBar.Parent = RemotesContent
    
    local SearchCorner = Instance.new("UICorner")
    SearchCorner.CornerRadius = UDim.new(0, 6)
    SearchCorner.Parent = SearchBar
    
    -- Filter Buttons
    local FilterFrame = Instance.new("Frame")
    FilterFrame.Size = UDim2.new(1, -20, 0, 30)
    FilterFrame.Position = UDim2.new(0, 10, 0, 50)
    FilterFrame.BackgroundTransparency = 1
    FilterFrame.Parent = RemotesContent
    
    local FilterLayout = Instance.new("UIListLayout")
    FilterLayout.FillDirection = Enum.FillDirection.Horizontal
    FilterLayout.Padding = UDim.new(0, 5)
    FilterLayout.Parent = FilterFrame
    
    local function CreateFilterButton(text, color)
        local FilterBtn = Instance.new("TextButton")
        FilterBtn.Text = text
        FilterBtn.Size = UDim2.new(0, 100, 1, 0)
        FilterBtn.BackgroundColor3 = color
        FilterBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        FilterBtn.Font = Enum.Font.Gotham
        FilterBtn.TextSize = 12
        FilterBtn.Parent = FilterFrame
        
        local FilterCorner = Instance.new("UICorner")
        FilterCorner.CornerRadius = UDim.new(0, 4)
        FilterCorner.Parent = FilterBtn
        
        return FilterBtn
    end
    
    local AllFilter = CreateFilterButton("All", Color3.fromRGB(60, 60, 60))
    local EventsFilter = CreateFilterButton("Events", Color3.fromRGB(59, 166, 241))
    local FunctionsFilter = CreateFilterButton("Functions", Color3.fromRGB(241, 196, 15))
    local ClearBtn = CreateFilterButton("Clear", Color3.fromRGB(231, 76, 60))
    
    -- Remotes List
    local RemotesList = Instance.new("ScrollingFrame")
    RemotesList.Size = UDim2.new(1, -20, 1, -100)
    RemotesList.Position = UDim2.new(0, 10, 0, 90)
    RemotesList.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    RemotesList.BorderSizePixel = 0
    RemotesList.ScrollBarThickness = 4
    RemotesList.CanvasSize = UDim2.new(0, 0, 0, 0)
    RemotesList.Parent = RemotesContent
    
    local RemotesListCorner = Instance.new("UICorner")
    RemotesListCorner.CornerRadius = UDim.new(0, 6)
    RemotesListCorner.Parent = RemotesList
    
    local RemotesLayout = Instance.new("UIListLayout")
    RemotesLayout.Padding = UDim.new(0, 5)
    RemotesLayout.Parent = RemotesList
    
    -- Script Generation Content
    local ScriptContent = Instance.new("Frame")
    ScriptContent.Size = UDim2.new(1, 0, 1, 0)
    ScriptContent.BackgroundTransparency = 1
    ScriptContent.Visible = false
    ScriptContent.Parent = ContentContainer
    
    local ScriptBox = Instance.new("ScrollingFrame")
    ScriptBox.Size = UDim2.new(1, -20, 1, -60)
    ScriptBox.Position = UDim2.new(0, 10, 0, 10)
    ScriptBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    ScriptBox.ScrollBarThickness = 4
    ScriptBox.CanvasSize = UDim2.new(0, 0, 0, 0)
    ScriptBox.Parent = ScriptContent
    
    local ScriptBoxCorner = Instance.new("UICorner")
    ScriptBoxCorner.CornerRadius = UDim.new(0, 6)
    ScriptBoxCorner.Parent = ScriptBox
    
    local ScriptTextBox = Instance.new("TextBox")
    ScriptTextBox.Size = UDim2.new(1, -10, 0, 0)
    ScriptTextBox.Position = UDim2.new(0, 5, 0, 5)
    ScriptTextBox.BackgroundTransparency = 1
    ScriptTextBox.TextColor3 = Color3.fromRGB(200, 200, 200)
    ScriptTextBox.Font = Enum.Font.Code
    ScriptTextBox.TextSize = 14
    ScriptTextBox.TextXAlignment = Enum.TextXAlignment.Left
    ScriptTextBox.TextYAlignment = Enum.TextYAlignment.Top
    ScriptTextBox.ClearTextOnFocus = false
    ScriptTextBox.MultiLine = true
    ScriptTextBox.Text = "-- Generated script will appear here"
    ScriptTextBox.Parent = ScriptBox
    
    local CopyScriptBtn = Instance.new("TextButton")
    CopyScriptBtn.Text = "📋 Copy Script"
    CopyScriptBtn.Size = UDim2.new(0, 150, 0, 35)
    CopyScriptBtn.Position = UDim2.new(0, 10, 1, -45)
    CopyScriptBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
    CopyScriptBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CopyScriptBtn.Font = Enum.Font.Gotham
    CopyScriptBtn.TextSize = 14
    CopyScriptBtn.Parent = ScriptContent
    
    local CopyScriptCorner = Instance.new("UICorner")
    CopyScriptCorner.CornerRadius = UDim.new(0, 6)
    CopyScriptCorner.Parent = CopyScriptBtn
    
    -- Stats Content
    local StatsContent = Instance.new("Frame")
    StatsContent.Size = UDim2.new(1, 0, 1, 0)
    StatsContent.BackgroundTransparency = 1
    StatsContent.Visible = false
    StatsContent.Parent = ContentContainer
    
    local StatsGrid = Instance.new("Frame")
    StatsGrid.Size = UDim2.new(1, -20, 1, -20)
    StatsGrid.Position = UDim2.new(0, 10, 0, 10)
    StatsGrid.BackgroundTransparency = 1
    StatsGrid.Parent = StatsContent
    
    local function CreateStatCard(title, value, color, position)
        local Card = Instance.new("Frame")
        Card.Size = UDim2.new(0.48, 0, 0, 80)
        Card.Position = position
        Card.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        Card.Parent = StatsGrid
        
        local CardCorner = Instance.new("UICorner")
        CardCorner.CornerRadius = UDim.new(0, 8)
        CardCorner.Parent = Card
        
        local CardTitle = Instance.new("TextLabel")
        CardTitle.Text = title
        CardTitle.Size = UDim2.new(1, -20, 0, 25)
        CardTitle.Position = UDim2.new(0, 10, 0, 10)
        CardTitle.BackgroundTransparency = 1
        CardTitle.TextColor3 = Color3.fromRGB(150, 150, 150)
        CardTitle.Font = Enum.Font.Gotham
        CardTitle.TextSize = 12
        CardTitle.TextXAlignment = Enum.TextXAlignment.Left
        CardTitle.Parent = Card
        
        local CardValue = Instance.new("TextLabel")
        CardValue.Name = "Value"
        CardValue.Text = value
        CardValue.Size = UDim2.new(1, -20, 0, 30)
        CardValue.Position = UDim2.new(0, 10, 0, 35)
        CardValue.BackgroundTransparency = 1
        CardValue.TextColor3 = color
        CardValue.Font = Enum.Font.GothamBold
        CardValue.TextSize = 24
        CardValue.TextXAlignment = Enum.TextXAlignment.Left
        CardValue.Parent = Card
        
        return Card
    end
    
    local TotalCallsCard = CreateStatCard("Total Calls", "0", Color3.fromRGB(52, 152, 219), UDim2.new(0, 0, 0, 0))
    local RemoteEventsCard = CreateStatCard("RemoteEvents", "0", Color3.fromRGB(59, 166, 241), UDim2.new(0.52, 0, 0, 0))
    local RemoteFunctionsCard = CreateStatCard("RemoteFunctions", "0", Color3.fromRGB(241, 196, 15), UDim2.new(0, 0, 0, 90))
    local UniqueRemotesCard = CreateStatCard("Unique Remotes", "0", Color3.fromRGB(46, 204, 113), UDim2.new(0.52, 0, 0, 90))
    local SessionTimeCard = CreateStatCard("Session Time", "00:00:00", Color3.fromRGB(155, 89, 182), UDim2.new(0, 0, 0, 180))
    local LastActivityCard = CreateStatCard("Last Activity", "Never", Color3.fromRGB(231, 76, 60), UDim2.new(0.52, 0, 0, 180))
    
    -- Settings Content
    local SettingsContent = Instance.new("Frame")
    SettingsContent.Size = UDim2.new(1, 0, 1, 0)
    SettingsContent.BackgroundTransparency = 1
    SettingsContent.Visible = false
    SettingsContent.Parent = ContentContainer
    
    local SettingsScroll = Instance.new("ScrollingFrame")
    SettingsScroll.Size = UDim2.new(1, -20, 1, -20)
    SettingsScroll.Position = UDim2.new(0, 10, 0, 10)
    SettingsScroll.BackgroundTransparency = 1
    SettingsScroll.ScrollBarThickness = 4
    SettingsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    SettingsScroll.Parent = SettingsContent
    
    local SettingsLayout = Instance.new("UIListLayout")
    SettingsLayout.Padding = UDim.new(0, 10)
    SettingsLayout.Parent = SettingsScroll
    
    local function CreateToggleSetting(text, configKey)
        local Setting = Instance.new("Frame")
        Setting.Size = UDim2.new(1, 0, 0, 40)
        Setting.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        Setting.Parent = SettingsScroll
        
        local SettingCorner = Instance.new("UICorner")
        SettingCorner.CornerRadius = UDim.new(0, 6)
        SettingCorner.Parent = Setting
        
        local SettingText = Instance.new("TextLabel")
        SettingText.Text = text
        SettingText.Size = UDim2.new(0.7, -10, 1, 0)
        SettingText.Position = UDim2.new(0, 10, 0, 0)
        SettingText.BackgroundTransparency = 1
        SettingText.TextColor3 = Color3.fromRGB(200, 200, 200)
        SettingText.Font = Enum.Font.Gotham
        SettingText.TextSize = 14
        SettingText.TextXAlignment = Enum.TextXAlignment.Left
        SettingText.Parent = Setting
        
        local Toggle = Instance.new("Frame")
        Toggle.Size = UDim2.new(0, 50, 0, 24)
        Toggle.Position = UDim2.new(1, -60, 0.5, -12)
        Toggle.BackgroundColor3 = MONITOR_CONFIG[configKey] and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(231, 76, 60)
        Toggle.Parent = Setting
        
        local ToggleCorner = Instance.new("UICorner")
        ToggleCorner.CornerRadius = UDim.new(1, 0)
        ToggleCorner.Parent = Toggle
        
        local ToggleCircle = Instance.new("Frame")
        ToggleCircle.Size = UDim2.new(0, 20, 0, 20)
        ToggleCircle.Position = MONITOR_CONFIG[configKey] and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
        ToggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ToggleCircle.Parent = Toggle
        
        local CircleCorner = Instance.new("UICorner")
        CircleCorner.CornerRadius = UDim.new(1, 0)
        CircleCorner.Parent = ToggleCircle
        
        local ToggleBtn = Instance.new("TextButton")
        ToggleBtn.Size = UDim2.new(1, 0, 1, 0)
        ToggleBtn.BackgroundTransparency = 1
        ToggleBtn.Text = ""
        ToggleBtn.Parent = Toggle
        
        ToggleBtn.MouseButton1Click:Connect(function()
            MONITOR_CONFIG[configKey] = not MONITOR_CONFIG[configKey]
            
            local newPos = MONITOR_CONFIG[configKey] and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
            local newColor = MONITOR_CONFIG[configKey] and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(231, 76, 60)
            
            TweenService:Create(ToggleCircle, TweenInfo.new(0.2), {Position = newPos}):Play()
            TweenService:Create(Toggle, TweenInfo.new(0.2), {BackgroundColor3 = newColor}):Play()
        end)
        
        return Setting
    end
    
    CreateToggleSetting("Log RemoteEvents", "LogRemoteEvents")
    CreateToggleSetting("Log RemoteFunctions", "LogRemoteFunctions")
    CreateToggleSetting("Log Return Values", "LogReturnValues")
    CreateToggleSetting("Generate Scripts", "GenerateScript")
    CreateToggleSetting("Detailed Mode", "DetailedMode")
    
    -- Export Content
    local ExportContent = Instance.new("Frame")
    ExportContent.Size = UDim2.new(1, 0, 1, 0)
    ExportContent.BackgroundTransparency = 1
    ExportContent.Visible = false
    ExportContent.Parent = ContentContainer
    
    local ExportBox = Instance.new("ScrollingFrame")
    ExportBox.Size = UDim2.new(1, -20, 1, -60)
    ExportBox.Position = UDim2.new(0, 10, 0, 10)
    ExportBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    ExportBox.ScrollBarThickness = 4
    ExportBox.CanvasSize = UDim2.new(0, 0, 0, 0)
    ExportBox.Parent = ExportContent
    
    local ExportBoxCorner = Instance.new("UICorner")
    ExportBoxCorner.CornerRadius = UDim.new(0, 6)
    ExportBoxCorner.Parent = ExportBox
    
    local ExportTextBox = Instance.new("TextBox")
    ExportTextBox.Size = UDim2.new(1, -10, 0, 0)
    ExportTextBox.Position = UDim2.new(0, 5, 0, 5)
    ExportTextBox.BackgroundTransparency = 1
    ExportTextBox.TextColor3 = Color3.fromRGB(200, 200, 200)
    ExportTextBox.Font = Enum.Font.Code
    ExportTextBox.TextSize = 12
    ExportTextBox.TextXAlignment = Enum.TextXAlignment.Left
    ExportTextBox.TextYAlignment = Enum.TextYAlignment.Top
    ExportTextBox.ClearTextOnFocus = false
    ExportTextBox.MultiLine = true
    ExportTextBox.Text = "-- Export data will appear here"
    ExportTextBox.Parent = ExportBox
    
    local ExportBtnFrame = Instance.new("Frame")
    ExportBtnFrame.Size = UDim2.new(1, -20, 0, 35)
    ExportBtnFrame.Position = UDim2.new(0, 10, 1, -45)
    ExportBtnFrame.BackgroundTransparency = 1
    ExportBtnFrame.Parent = ExportContent
    
    local ExportBtnLayout = Instance.new("UIListLayout")
    ExportBtnLayout.FillDirection = Enum.FillDirection.Horizontal
    ExportBtnLayout.Padding = UDim.new(0, 10)
    ExportBtnLayout.Parent = ExportBtnFrame
    
    local function CreateExportButton(text, color)
        local Btn = Instance.new("TextButton")
        Btn.Text = text
        Btn.Size = UDim2.new(0, 120, 1, 0)
        Btn.BackgroundColor3 = color
        Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        Btn.Font = Enum.Font.Gotham
        Btn.TextSize = 14
        Btn.Parent = ExportBtnFrame
        
        local BtnCorner = Instance.new("UICorner")
        BtnCorner.CornerRadius = UDim.new(0, 6)
        BtnCorner.Parent = Btn
        
        return Btn
    end
    
    local ExportJSONBtn = CreateExportButton("Export JSON", Color3.fromRGB(52, 152, 219))
    local ExportTxtBtn = CreateExportButton("Export TXT", Color3.fromRGB(46, 204, 113))
    local CopyExportBtn = CreateExportButton("Copy All", Color3.fromRGB(155, 89, 182))
    
    -- Tab switching logic
    local tabs = {
        {btn = RemotesTab, content = RemotesContent},
        {btn = ScriptTab, content = ScriptContent},
        {btn = StatsTab, content = StatsContent},
        {btn = SettingsTab, content = SettingsContent},
        {btn = ExportTab, content = ExportContent}
    }
    
    local function SwitchTab(selectedTab)
        for _, tab in pairs(tabs) do
            if tab.btn == selectedTab then
                tab.btn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
                tab.content.Visible = true
            else
                tab.btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                tab.content.Visible = false
            end
        end
    end
    
    for _, tab in pairs(tabs) do
        tab.btn.MouseButton1Click:Connect(function()
            SwitchTab(tab.btn)
        end)
    end
    
    -- Set default tab
    SwitchTab(RemotesTab)
    
    -- Make draggable
    local dragging, dragStart, startPos
    
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
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
    
    -- Minimize/Close
    local minimized = false
    MinimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        ContentContainer.Visible = not minimized
        TabContainer.Visible = not minimized
        MainFrame.Size = minimized and UDim2.new(0, 700, 0, 35) or UDim2.new(0, 700, 0, 500)
    end)
    
    CloseBtn.MouseButton1Click:Connect(function()
        NetworkMonitorUI:Destroy()
        MONITOR_CONFIG.UIVisible = false
    end)
    
    return {
        UI = NetworkMonitorUI,
        RemotesList = RemotesList,
        ScriptTextBox = ScriptTextBox,
        ExportTextBox = ExportTextBox,
        SearchBar = SearchBar,
        -- Stat cards
        TotalCallsCard = TotalCallsCard,
        RemoteEventsCard = RemoteEventsCard,
        RemoteFunctionsCard = RemoteFunctionsCard,
        UniqueRemotesCard = UniqueRemotesCard,
        SessionTimeCard = SessionTimeCard,
        LastActivityCard = LastActivityCard,
        -- Buttons
        ClearBtn = ClearBtn,
        CopyScriptBtn = CopyScriptBtn,
        ExportJSONBtn = ExportJSONBtn,
        ExportTxtBtn = ExportTxtBtn,
        CopyExportBtn = CopyExportBtn,
        -- Filters
        AllFilter = AllFilter,
        EventsFilter = EventsFilter,
        FunctionsFilter = FunctionsFilter
    }
end

-- Initialize UI
local UI = CreateUI()

-- Advanced serialization function
local function AdvancedSerialize(obj, depth)
    depth = depth or 0
    if depth > 10 then return "MAX_DEPTH_REACHED" end
    
    local objType = typeof(obj)
    
    if objType == "table" then
        local result = {}
        local isArray = true
        local count = 0
        
        for k, v in pairs(obj) do
            count = count + 1
            if type(k) ~= "number" or k ~= count then
                isArray = false
            end
            result[k] = AdvancedSerialize(v, depth + 1)
        end
        
        if isArray then
            local str = "{"
            for i, v in ipairs(result) do
                if i > 1 then str = str .. ", " end
                str = str .. tostring(v)
            end
            return str .. "}"
        else
            local str = "{\n"
            for k, v in pairs(result) do
                str = str .. string.rep("  ", depth + 1) .. "[" .. tostring(k) .. "] = " .. tostring(v) .. ",\n"
            end
            return str .. string.rep("  ", depth) .. "}"
        end
    elseif objType == "Instance" then
        return string.format('game:GetService("%s"):WaitForChild("%s")', obj.Parent and obj.Parent.Name or "Unknown", obj.Name)
    elseif objType == "CFrame" then
        return string.format("CFrame.new(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)",
            obj.X, obj.Y, obj.Z, obj:GetComponents())
    elseif objType == "Vector3" then
        return string.format("Vector3.new(%f, %f, %f)", obj.X, obj.Y, obj.Z)
    elseif objType == "Vector2" then
        return string.format("Vector2.new(%f, %f)", obj.X, obj.Y)
    elseif objType == "UDim2" then
        return string.format("UDim2.new(%f, %f, %f, %f)", obj.X.Scale, obj.X.Offset, obj.Y.Scale, obj.Y.Offset)
    elseif objType == "UDim" then
        return string.format("UDim.new(%f, %f)", obj.Scale, obj.Offset)
    elseif objType == "Color3" then
        return string.format("Color3.new(%f, %f, %f)", obj.R, obj.G, obj.B)
    elseif objType == "BrickColor" then
        return string.format('BrickColor.new("%s")', obj.Name)
    elseif objType == "Enum" or objType == "EnumItem" then
        return tostring(obj)
    elseif objType == "string" then
        return '"' .. obj:gsub('"', '\\"'):gsub('\n', '\\n') .. '"'
    elseif objType == "number" or objType == "boolean" then
        return tostring(obj)
    elseif objType == "function" then
        return "<function>"
    elseif objType == "userdata" then
        return "<userdata: " .. tostring(obj) .. ">"
    elseif objType == "thread" then
        return "<thread>"
    elseif objType == "nil" then
        return "nil"
    else
        return tostring(obj)
    end
end

-- Generate script from remote call
local function GenerateScript(remotePath, remoteType, args, returnValue)
    local script = "-- Generated by Advanced Network Monitor\n"
    script = script .. "-- " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n\n"
    
    -- Add services
    script = script .. "local ReplicatedStorage = game:GetService('ReplicatedStorage')\n"
    script = script .. "local Players = game:GetService('Players')\n\n"
    
    -- Get remote
    script = script .. "-- Get the remote\n"
    script = script .. "local remote = " .. remotePath .. "\n\n"
    
    -- Generate call
    script = script .. "-- Call the remote\n"
    if remoteType == "RemoteEvent" then
        script = script .. "remote:FireServer("
    elseif remoteType == "RemoteFunction" then
        script = script .. "local result = remote:InvokeServer("
    end
    
    -- Add arguments
    for i, arg in ipairs(args) do
        if i > 1 then script = script .. ", " end
        script = script .. "\n    " .. AdvancedSerialize(arg, 1)
    end
    
    script = script .. "\n)\n"
    
    -- Add return value if RemoteFunction
    if remoteType == "RemoteFunction" and returnValue then
        script = script .. "\n-- Return value:\n"
        script = script .. "-- " .. AdvancedSerialize(returnValue, 0) .. "\n"
    end
    
    return script
end

-- Create remote log entry in UI
local function CreateRemoteLogEntry(remoteName, remoteType, direction, args, returnValue)
    local LogEntry = Instance.new("Frame")
    LogEntry.Size = UDim2.new(1, -10, 0, 80)
    LogEntry.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    LogEntry.Parent = UI.RemotesList
    
    local EntryCorner = Instance.new("UICorner")
    EntryCorner.CornerRadius = UDim.new(0, 6)
    EntryCorner.Parent = LogEntry
    
    -- Type indicator
    local TypeIndicator = Instance.new("Frame")
    TypeIndicator.Size = UDim2.new(0, 4, 1, -10)
    TypeIndicator.Position = UDim2.new(0, 0, 0, 5)
    TypeIndicator.BackgroundColor3 = remoteType == "RemoteEvent" and Color3.fromRGB(59, 166, 241) or Color3.fromRGB(241, 196, 15)
    TypeIndicator.BorderSizePixel = 0
    TypeIndicator.Parent = LogEntry
    
    local TypeCorner = Instance.new("UICorner")
    TypeCorner.CornerRadius = UDim.new(0, 2)
    TypeCorner.Parent = TypeIndicator
    
    -- Remote info
    local RemoteInfo = Instance.new("Frame")
    RemoteInfo.Size = UDim2.new(1, -20, 0, 30)
    RemoteInfo.Position = UDim2.new(0, 10, 0, 5)
    RemoteInfo.BackgroundTransparency = 1
    RemoteInfo.Parent = LogEntry
    
    local RemoteName = Instance.new("TextLabel")
    RemoteName.Text = remoteName:match("([^.]+)$") or remoteName
    RemoteName.Size = UDim2.new(0.6, 0, 1, 0)
    RemoteName.BackgroundTransparency = 1
    RemoteName.TextColor3 = Color3.fromRGB(255, 255, 255)
    RemoteName.Font = Enum.Font.GothamBold
    RemoteName.TextSize = 14
    RemoteName.TextXAlignment = Enum.TextXAlignment.Left
    RemoteName.Parent = RemoteInfo
    
    local RemoteType = Instance.new("TextLabel")
    RemoteType.Text = remoteType
    RemoteType.Size = UDim2.new(0.2, 0, 1, 0)
    RemoteType.Position = UDim2.new(0.6, 0, 0, 0)
    RemoteType.BackgroundTransparency = 1
    RemoteType.TextColor3 = remoteType == "RemoteEvent" and Color3.fromRGB(59, 166, 241) or Color3.fromRGB(241, 196, 15)
    RemoteType.Font = Enum.Font.Gotham
    RemoteType.TextSize = 12
    RemoteType.Parent = RemoteInfo
    
    local DirectionLabel = Instance.new("TextLabel")
    DirectionLabel.Text = direction
    DirectionLabel.Size = UDim2.new(0.2, -5, 0, 20)
    DirectionLabel.Position = UDim2.new(0.8, 0, 0.5, -10)
    DirectionLabel.BackgroundColor3 = direction == "Incoming" and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(231, 76, 60)
    DirectionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    DirectionLabel.Font = Enum.Font.Gotham
    DirectionLabel.TextSize = 11
    DirectionLabel.Parent = RemoteInfo
    
    local DirCorner = Instance.new("UICorner")
    DirCorner.CornerRadius = UDim.new(0, 4)
    DirCorner.Parent = DirectionLabel
    
    -- Arguments display
    local ArgsFrame = Instance.new("Frame")
    ArgsFrame.Size = UDim2.new(1, -20, 0, 20)
    ArgsFrame.Position = UDim2.new(0, 10, 0, 35)
    ArgsFrame.BackgroundTransparency = 1
    ArgsFrame.Parent = LogEntry
    
    local ArgsLabel = Instance.new("TextLabel")
    ArgsLabel.Text = "📦 Arguments: " .. #args
    ArgsLabel.Size = UDim2.new(0.3, 0, 1, 0)
    ArgsLabel.BackgroundTransparency = 1
    ArgsLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    ArgsLabel.Font = Enum.Font.Gotham
    ArgsLabel.TextSize = 12
    ArgsLabel.TextXAlignment = Enum.TextXAlignment.Left
    ArgsLabel.Parent = ArgsFrame
    
    local ArgsPreview = Instance.new("TextLabel")
    local previewText = ""
    for i = 1, math.min(#args, 3) do
        if i > 1 then previewText = previewText .. ", " end
        local argStr = tostring(AdvancedSerialize(args[i], 0))
        if #argStr > 30 then
            argStr = argStr:sub(1, 27) .. "..."
        end
        previewText = previewText .. argStr
    end
    if #args > 3 then previewText = previewText .. ", ..." end
    
    ArgsPreview.Text = previewText
    ArgsPreview.Size = UDim2.new(0.7, 0, 1, 0)
    ArgsPreview.Position = UDim2.new(0.3, 0, 0, 0)
    ArgsPreview.BackgroundTransparency = 1
    ArgsPreview.TextColor3 = Color3.fromRGB(150, 150, 150)
    ArgsPreview.Font = Enum.Font.Code
    ArgsPreview.TextSize = 11
    ArgsPreview.TextXAlignment = Enum.TextXAlignment.Left
    ArgsPreview.TextTruncate = Enum.TextTruncate.AtEnd
    ArgsPreview.Parent = ArgsFrame
    
    -- Buttons
    local ButtonsFrame = Instance.new("Frame")
    ButtonsFrame.Size = UDim2.new(1, -20, 0, 20)
    ButtonsFrame.Position = UDim2.new(0, 10, 0, 55)
    ButtonsFrame.BackgroundTransparency = 1
    ButtonsFrame.Parent = LogEntry
    
    local ButtonLayout = Instance.new("UIListLayout")
    ButtonLayout.FillDirection = Enum.FillDirection.Horizontal
    ButtonLayout.Padding = UDim.new(0, 5)
    ButtonLayout.Parent = ButtonsFrame
    
    local function CreateActionButton(text, color)
        local Btn = Instance.new("TextButton")
        Btn.Text = text
        Btn.Size = UDim2.new(0, 80, 1, 0)
        Btn.BackgroundColor3 = color
        Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        Btn.Font = Enum.Font.Gotham
        Btn.TextSize = 11
        Btn.Parent = ButtonsFrame
        
        local BtnCorner = Instance.new("UICorner")
        BtnCorner.CornerRadius = UDim.new(0, 4)
        BtnCorner.Parent = Btn
        
        return Btn
    end
    
    local ViewBtn = CreateActionButton("View", Color3.fromRGB(52, 152, 219))
    local CopyBtn = CreateActionButton("Copy", Color3.fromRGB(155, 89, 182))
    local ScriptBtn = CreateActionButton("Script", Color3.fromRGB(46, 204, 113))
    
    -- Button actions
    ViewBtn.MouseButton1Click:Connect(function()
        print("\n" .. string.rep("=", 50))
        print("REMOTE DETAILS")
        print(string.rep("=", 50))
        print("Remote: " .. remoteName)
        print("Type: " .. remoteType)
        print("Direction: " .. direction)
        print("Time: " .. os.date("%H:%M:%S"))
        print("\nArguments (" .. #args .. "):")
        for i, arg in ipairs(args) do
            print("  [" .. i .. "] = " .. AdvancedSerialize(arg, 1))
        end
        if returnValue then
            print("\nReturn Value:")
            print("  " .. AdvancedSerialize(returnValue, 1))
        end
        print(string.rep("=", 50) .. "\n")
    end)
    
    CopyBtn.MouseButton1Click:Connect(function()
        local copyText = remoteName .. "\n"
        for i, arg in ipairs(args) do
            copyText = copyText .. AdvancedSerialize(arg, 0) .. "\n"
        end
        setclipboard(copyText)
        print("[Network Monitor] Copied to clipboard!")
    end)
    
    ScriptBtn.MouseButton1Click:Connect(function()
        local script = GenerateScript(remoteName, remoteType, args, returnValue)
        UI.ScriptTextBox.Text = script
        
        -- Update canvas size
        local textSize = UI.ScriptTextBox.TextBounds
        UI.ScriptTextBox.Size = UDim2.new(1, -10, 0, textSize.Y + 20)
        UI.ScriptBox.CanvasSize = UDim2.new(0, 0, 0, textSize.Y + 30)
        
        print("[Network Monitor] Script generated!")
    end)
    
    -- Update scroll canvas
    UI.RemotesList.CanvasSize = UDim2.new(0, 0, 0, UI.RemotesList.UIListLayout.AbsoluteContentSize.Y)
    
    return LogEntry
end

-- Update statistics
local function UpdateStats()
    if not UI then return end
    
    local totalCalls = 0
    local remoteEvents = 0
    local remoteFunctions = 0
    local uniqueRemotes = 0
    
    for _, logs in pairs(NetworkLogs.RemoteEvents) do
        remoteEvents = remoteEvents + #logs
        totalCalls = totalCalls + #logs
        if #logs > 0 then uniqueRemotes = uniqueRemotes + 1 end
    end
    
    for _, logs in pairs(NetworkLogs.RemoteFunctions) do
        remoteFunctions = remoteFunctions + #logs
        totalCalls = totalCalls + #logs
        if #logs > 0 then uniqueRemotes = uniqueRemotes + 1 end
    end
    
    UI.TotalCallsCard.Value.Text = tostring(totalCalls)
    UI.RemoteEventsCard.Value.Text = tostring(remoteEvents)
    UI.RemoteFunctionsCard.Value.Text = tostring(remoteFunctions)
    UI.UniqueRemotesCard.Value.Text = tostring(uniqueRemotes)
    
    -- Session time
    local sessionTime = os.time() - NetworkLogs.StartTime
    local hours = math.floor(sessionTime / 3600)
    local minutes = math.floor((sessionTime % 3600) / 60)
    local seconds = sessionTime % 60
    UI.SessionTimeCard.Value.Text = string.format("%02d:%02d:%02d", hours, minutes, seconds)
    
    -- Last activity
    UI.LastActivityCard.Value.Text = os.date("%H:%M:%S")
end

-- Advanced hooking function
local function HookRemote(remote, remoteType)
    local remoteName = remote:GetFullName()
    
    if HookedRemotes[remote] then return end
    HookedRemotes[remote] = true
    
    -- Initialize storage
    if remoteType == "RemoteEvent" then
        if not NetworkLogs.RemoteEvents[remoteName] then
            NetworkLogs.RemoteEvents[remoteName] = {}
        end
        
        -- Hook OnClientEvent
        if remote.OnClientEvent then
            remote.OnClientEvent:Connect(function(...)
                if not MONITOR_CONFIG.LogRemoteEvents then return end
                
                local args = {...}
                local logEntry = {
                    Time = os.time(),
                    Direction = "Incoming",
                    Arguments = args,
                    Traceback = debug.traceback()
                }
                
                table.insert(NetworkLogs.RemoteEvents[remoteName], logEntry)
                CreateRemoteLogEntry(remoteName, "RemoteEvent", "Incoming", args, nil)
                UpdateStats()
                
                print(string.format("[Network Monitor] RemoteEvent '%s' received", remoteName:match("([^.]+)$") or remoteName))
            end)
        end
        
        -- Hook FireServer using metatable
        pcall(function()
            local mt = getrawmetatable(remote)
            local oldNamecall = mt.__namecall
            setreadonly(mt, false)
            
            mt.__namecall = newcclosure(function(self, ...)
                local method = getnamecallmethod()
                local args = {...}
                
                if self == remote and method == "FireServer" and MONITOR_CONFIG.LogRemoteEvents then
                    local logEntry = {
                        Time = os.time(),
                        Direction = "Outgoing",
                        Arguments = args,
                        Traceback = debug.traceback()
                    }
                    
                    table.insert(NetworkLogs.RemoteEvents[remoteName], logEntry)
                    CreateRemoteLogEntry(remoteName, "RemoteEvent", "Outgoing", args, nil)
                    UpdateStats()
                    
                    print(string.format("[Network Monitor] FireServer called on '%s'", remoteName:match("([^.]+)$") or remoteName))
                end
                
                return oldNamecall(self, ...)
            end)
            
            setreadonly(mt, true)
        end)
        
    elseif remoteType == "RemoteFunction" then
        if not NetworkLogs.RemoteFunctions[remoteName] then
            NetworkLogs.RemoteFunctions[remoteName] = {}
        end
        
        -- Hook InvokeServer
        pcall(function()
            local mt = getrawmetatable(remote)
            local oldNamecall = mt.__namecall
            setreadonly(mt, false)
            
            mt.__namecall = newcclosure(function(self, ...)
                local method = getnamecallmethod()
                local args = {...}
                
                if self == remote and method == "InvokeServer" and MONITOR_CONFIG.LogRemoteFunctions then
                    local returnValue = {oldNamecall(self, ...)}
                    
                    local logEntry = {
                        Time = os.time(),
                        Direction = "Outgoing",
                        Arguments = args,
                        ReturnValue = MONITOR_CONFIG.LogReturnValues and returnValue or nil,
                        Traceback = debug.traceback()
                    }
                    
                    table.insert(NetworkLogs.RemoteFunctions[remoteName], logEntry)
                    CreateRemoteLogEntry(remoteName, "RemoteFunction", "Outgoing", args, returnValue[1])
                    UpdateStats()
                    
                    print(string.format("[Network Monitor] InvokeServer called on '%s'", remoteName:match("([^.]+)$") or remoteName))
                    
                    return unpack(returnValue)
                end
                
                return oldNamecall(self, ...)
            end)
            
            setreadonly(mt, true)
        end)
    end
end

-- Scan for remotes
local function ScanForRemotes()
    local remoteCount = 0
    
    for _, service in pairs(game:GetChildren()) do
        pcall(function()
            for _, obj in pairs(service:GetDescendants()) do
                if obj:IsA("RemoteEvent") then
                    HookRemote(obj, "RemoteEvent")
                    remoteCount = remoteCount + 1
                elseif obj:IsA("RemoteFunction") then
                    HookRemote(obj, "RemoteFunction")
                    remoteCount = remoteCount + 1
                end
            end
        end)
    end
    
    print(string.format("[Network Monitor] Scanned and hooked %d remotes", remoteCount))
    return remoteCount
end

-- Auto-hook new remotes
game.DescendantAdded:Connect(function(obj)
    if obj:IsA("RemoteEvent") then
        HookRemote(obj, "RemoteEvent")
    elseif obj:IsA("RemoteFunction") then
        HookRemote(obj, "RemoteFunction")
    end
end)

-- Export functions
local function ExportToJSON()
    local exportData = {
        SessionInfo = {
            Player = NetworkLogs.Player,
            StartTime = os.date("%Y-%m-%d %H:%M:%S", NetworkLogs.StartTime),
            ExportTime = os.date("%Y-%m-%d %H:%M:%S")
        },
        RemoteEvents = {},
        RemoteFunctions = {}
    }
    
    for remoteName, logs in pairs(NetworkLogs.RemoteEvents) do
        exportData.RemoteEvents[remoteName] = {}
        for i, log in ipairs(logs) do
            table.insert(exportData.RemoteEvents[remoteName], {
                Time = os.date("%H:%M:%S", log.Time),
                Direction = log.Direction,
                Arguments = log.Arguments
            })
        end
    end
    
    for remoteName, logs in pairs(NetworkLogs.RemoteFunctions) do
        exportData.RemoteFunctions[remoteName] = {}
        for i, log in ipairs(logs) do
            table.insert(exportData.RemoteFunctions[remoteName], {
                Time = os.date("%H:%M:%S", log.Time),
                Direction = log.Direction,
                Arguments = log.Arguments,
                ReturnValue = log.ReturnValue
            })
        end
    end
    
    return HttpService:JSONEncode(exportData)
end

local function ExportToText()
    local output = {}
    
    table.insert(output, "=" .. string.rep("=", 60))
    table.insert(output, "ADVANCED NETWORK MONITOR REPORT")
    table.insert(output, "=" .. string.rep("=", 60))
    table.insert(output, "Generated: " .. os.date("%Y-%m-%d %H:%M:%S"))
    table.insert(output, "Player: " .. NetworkLogs.Player)
    table.insert(output, "Session Start: " .. os.date("%Y-%m-%d %H:%M:%S", NetworkLogs.StartTime))
    table.insert(output, "")
    
    -- RemoteEvents section
    table.insert(output, "-" .. string.rep("-", 60))
    table.insert(output, "REMOTE EVENTS")
    table.insert(output, "-" .. string.rep("-", 60))
    
    for remoteName, logs in pairs(NetworkLogs.RemoteEvents) do
        if #logs > 0 then
            table.insert(output, "\n[" .. remoteName .. "] - Total Calls: " .. #logs)
            for i, log in ipairs(logs) do
                table.insert(output, string.format("\n  Call #%d:", i))
                table.insert(output, "    Time: " .. os.date("%H:%M:%S", log.Time))
                table.insert(output, "    Direction: " .. log.Direction)
                table.insert(output, "    Arguments (" .. #log.Arguments .. "):")
                for j, arg in ipairs(log.Arguments) do
                    table.insert(output, "      [" .. j .. "] = " .. AdvancedSerialize(arg, 2))
                end
            end
        end
    end
    
    -- RemoteFunctions section
    table.insert(output, "\n" .. "-" .. string.rep("-", 60))
    table.insert(output, "REMOTE FUNCTIONS")
    table.insert(output, "-" .. string.rep("-", 60))
    
    for remoteName, logs in pairs(NetworkLogs.RemoteFunctions) do
        if #logs > 0 then
            table.insert(output, "\n[" .. remoteName .. "] - Total Calls: " .. #logs)
            for i, log in ipairs(logs) do
                table.insert(output, string.format("\n  Call #%d:", i))
                table.insert(output, "    Time: " .. os.date("%H:%M:%S", log.Time))
                table.insert(output, "    Direction: " .. log.Direction)
                table.insert(output, "    Arguments (" .. #log.Arguments .. "):")
                for j, arg in ipairs(log.Arguments) do
                    table.insert(output, "      [" .. j .. "] = " .. AdvancedSerialize(arg, 2))
                end
                if log.ReturnValue then
                    table.insert(output, "    Return Value:")
                    table.insert(output, "      " .. AdvancedSerialize(log.ReturnValue[1], 2))
                end
            end
        end
    end
    
    -- Summary
    table.insert(output, "\n" .. "=" .. string.rep("=", 60))
    table.insert(output, "SUMMARY")
    table.insert(output, "=" .. string.rep("=", 60))
    
    local totalRemoteEvents = 0
    local totalRemoteFunctions = 0
    
    for _, logs in pairs(NetworkLogs.RemoteEvents) do
        totalRemoteEvents = totalRemoteEvents + #logs
    end
    
    for _, logs in pairs(NetworkLogs.RemoteFunctions) do
        totalRemoteFunctions = totalRemoteFunctions + #logs
    end
    
    table.insert(output, "Total RemoteEvent Calls: " .. totalRemoteEvents)
    table.insert(output, "Total RemoteFunction Calls: " .. totalRemoteFunctions)
    table.insert(output, "Unique RemoteEvents: " .. table.getn(NetworkLogs.RemoteEvents))
    table.insert(output, "Unique RemoteFunctions: " .. table.getn(NetworkLogs.RemoteFunctions))
    
    return table.concat(output, "\n")
end

-- Button connections
UI.ClearBtn.MouseButton1Click:Connect(function()
    for _, child in pairs(UI.RemotesList:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
    NetworkLogs.RemoteEvents = {}
    NetworkLogs.RemoteFunctions = {}
    UpdateStats()
    print("[Network Monitor] All logs cleared")
end)

UI.CopyScriptBtn.MouseButton1Click:Connect(function()
    setclipboard(UI.ScriptTextBox.Text)
    print("[Network Monitor] Script copied to clipboard!")
end)

UI.ExportJSONBtn.MouseButton1Click:Connect(function()
    local jsonData = ExportToJSON()
    UI.ExportTextBox.Text = jsonData
    
    local textSize = UI.ExportTextBox.TextBounds
    UI.ExportTextBox.Size = UDim2.new(1, -10, 0, textSize.Y + 20)
    UI.ExportBox.CanvasSize = UDim2.new(0, 0, 0, textSize.Y + 30)
    
    print("[Network Monitor] Exported to JSON format")
end)

UI.ExportTxtBtn.MouseButton1Click:Connect(function()
    local textData = ExportToText()
    UI.ExportTextBox.Text = textData
    
    local textSize = UI.ExportTextBox.TextBounds
    UI.-- Network Monitor Part 2 - Continuation
-- Paste this after Part 1

ExportTextBox.Size = UDim2.new(1, -10, 0, textSize.Y + 20)
    UI.ExportBox.CanvasSize = UDim2.new(0, 0, 0, textSize.Y + 30)
    
    print("[Network Monitor] Exported to Text format")
end)

UI.CopyExportBtn.MouseButton1Click:Connect(function()
    setclipboard(UI.ExportTextBox.Text)
    print("[Network Monitor] Export data copied to clipboard!")
end)

-- Search functionality
local currentFilter = "All"

UI.SearchBar:GetPropertyChangedSignal("Text"):Connect(function()
    local searchText = UI.SearchBar.Text:lower()
    
    for _, child in pairs(UI.RemotesList:GetChildren()) do
        if child:IsA("Frame") then
            local remoteName = child:FindFirstChildOfClass("TextLabel")
            if remoteName then
                local nameText = remoteName.Text:lower()
                child.Visible = nameText:find(searchText) ~= nil
            end
        end
    end
    
    -- Update canvas
    UI.RemotesList.CanvasSize = UDim2.new(0, 0, 0, UI.RemotesList.UIListLayout.AbsoluteContentSize.Y)
end)

-- Filter buttons
UI.AllFilter.MouseButton1Click:Connect(function()
    currentFilter = "All"
    for _, child in pairs(UI.RemotesList:GetChildren()) do
        if child:IsA("Frame") then
            child.Visible = true
        end
    end
    UI.RemotesList.CanvasSize = UDim2.new(0, 0, 0, UI.RemotesList.UIListLayout.AbsoluteContentSize.Y)
end)

UI.EventsFilter.MouseButton1Click:Connect(function()
    currentFilter = "Events"
    for _, child in pairs(UI.RemotesList:GetChildren()) do
        if child:IsA("Frame") then
            local typeLabel = child:FindFirstChild("RemoteInfo"):FindFirstChild("RemoteType")
            if typeLabel then
                child.Visible = typeLabel.Text == "RemoteEvent"
            end
        end
    end
    UI.RemotesList.CanvasSize = UDim2.new(0, 0, 0, UI.RemotesList.UIListLayout.AbsoluteContentSize.Y)
end)

UI.FunctionsFilter.MouseButton1Click:Connect(function()
    currentFilter = "Functions"
    for _, child in pairs(UI.RemotesList:GetChildren()) do
        if child:IsA("Frame") then
            local typeLabel = child:FindFirstChild("RemoteInfo"):FindFirstChild("RemoteType")
            if typeLabel then
                child.Visible = typeLabel.Text == "RemoteFunction"
            end
        end
    end
    UI.RemotesList.CanvasSize = UDim2.new(0, 0, 0, UI.RemotesList.UIListLayout.AbsoluteContentSize.Y)
end)

-- Auto-update stats
spawn(function()
    while true do
        wait(1)
        UpdateStats()
    end
end)

-- Auto-save logs
spawn(function()
    while true do
        wait(MONITOR_CONFIG.SaveInterval)
        _G.NetworkMonitorLogs = ExportToText()
        print("[Network Monitor] Auto-saved logs to _G.NetworkMonitorLogs")
    end
end)

-- Global commands
_G.NetworkMonitor = {
    Start = function()
        print("[Network Monitor] Starting deep scan...")
        local count = ScanForRemotes()
        print(string.format("[Network Monitor] Scan complete! Monitoring %d remotes", count))
    end,
    
    Stop = function()
        MONITOR_CONFIG.LogRemoteEvents = false
        MONITOR_CONFIG.LogRemoteFunctions = false
        print("[Network Monitor] Monitoring stopped")
    end,
    
    Resume = function()
        MONITOR_CONFIG.LogRemoteEvents = true
        MONITOR_CONFIG.LogRemoteFunctions = true
        print("[Network Monitor] Monitoring resumed")
    end,
    
    Clear = function()
        NetworkLogs.RemoteEvents = {}
        NetworkLogs.RemoteFunctions = {}
        for _, child in pairs(UI.RemotesList:GetChildren()) do
            if not child:IsA("UIListLayout") then
                child:Destroy()
            end
        end
        UpdateStats()
        print("[Network Monitor] All logs cleared")
    end,
    
    ExportJSON = function()
        local json = ExportToJSON()
        setclipboard(json)
        print("[Network Monitor] JSON data copied to clipboard")
        return json
    end,
    
    ExportText = function()
        local text = ExportToText()
        setclipboard(text)
        print("[Network Monitor] Text data copied to clipboard")
        return text
    end,
    
    ShowUI = function()
        if UI and UI.UI then
            UI.UI.Enabled = true
            MONITOR_CONFIG.UIVisible = true
            print("[Network Monitor] UI shown")
        end
    end,
    
    HideUI = function()
        if UI and UI.UI then
            UI.UI.Enabled = false
            MONITOR_CONFIG.UIVisible = false
            print("[Network Monitor] UI hidden")
        end
    end,
    
    GetStats = function()
        local totalCalls = 0
        local remoteEvents = 0
        local remoteFunctions = 0
        
        for _, logs in pairs(NetworkLogs.RemoteEvents) do
            remoteEvents = remoteEvents + #logs
            totalCalls = totalCalls + #logs
        end
        
        for _, logs in pairs(NetworkLogs.RemoteFunctions) do
            remoteFunctions = remoteFunctions + #logs
            totalCalls = totalCalls + #logs
        end
        
        return {
            TotalCalls = totalCalls,
            RemoteEvents = remoteEvents,
            RemoteFunctions = remoteFunctions,
            UniqueRemotes = table.getn(NetworkLogs.RemoteEvents) + table.getn(NetworkLogs.RemoteFunctions)
        }
    end,
    
    GetLogs = function()
        return NetworkLogs
    end,
    
    -- Advanced functions for specific game analysis
    AnalyzeTrading = function()
        print("\n" .. string.rep("=", 60))
        print("TRADING SYSTEM ANALYSIS")
        print(string.rep("=", 60))
        
        local tradeRemotes = {}
        
        -- Search for trade-related remotes
        for remoteName, logs in pairs(NetworkLogs.RemoteEvents) do
            if remoteName:lower():find("trade") or 
               remoteName:lower():find("exchange") or 
               remoteName:lower():find("offer") or
               remoteName:lower():find("accept") then
                tradeRemotes[remoteName] = logs
            end
        end
        
        for remoteName, logs in pairs(NetworkLogs.RemoteFunctions) do
            if remoteName:lower():find("trade") or 
               remoteName:lower():find("exchange") or 
               remoteName:lower():find("offer") or
               remoteName:lower():find("accept") then
                tradeRemotes[remoteName] = logs
            end
        end
        
        if next(tradeRemotes) then
            print("\nFound trade-related remotes:")
            for remoteName, logs in pairs(tradeRemotes) do
                print("\n[" .. remoteName .. "]")
                print("  Total calls: " .. #logs)
                if #logs > 0 then
                    local lastLog = logs[#logs]
                    print("  Last call: " .. os.date("%H:%M:%S", lastLog.Time))
                    print("  Last arguments:")
                    for i, arg in ipairs(lastLog.Arguments) do
                        print("    [" .. i .. "] = " .. AdvancedSerialize(arg, 2))
                    end
                end
            end
        else
            print("\nNo trade-related remotes found in current logs.")
            print("Try performing a trade action in the game first.")
        end
        
        print(string.rep("=", 60) .. "\n")
    end,
    
    AnalyzeFishing = function()
        print("\n" .. string.rep("=", 60))
        print("FISHING SYSTEM ANALYSIS")
        print(string.rep("=", 60))
        
        local fishRemotes = {}
        
        -- Search for fishing-related remotes
        for remoteName, logs in pairs(NetworkLogs.RemoteEvents) do
            if remoteName:lower():find("fish") or 
               remoteName:lower():find("cast") or 
               remoteName:lower():find("catch") or
               remoteName:lower():find("reel") or
               remoteName:lower():find("bait") then
                fishRemotes[remoteName] = logs
            end
        end
        
        for remoteName, logs in pairs(NetworkLogs.RemoteFunctions) do
            if remoteName:lower():find("fish") or 
               remoteName:lower():find("cast") or 
               remoteName:lower():find("catch") or
               remoteName:lower():find("reel") or
               remoteName:lower():find("bait") then
                fishRemotes[remoteName] = logs
            end
        end
        
        if next(fishRemotes) then
            print("\nFound fishing-related remotes:")
            for remoteName, logs in pairs(fishRemotes) do
                print("\n[" .. remoteName .. "]")
                print("  Total calls: " .. #logs)
                if #logs > 0 then
                    local lastLog = logs[#logs]
                    print("  Last call: " .. os.date("%H:%M:%S", lastLog.Time))
                    print("  Last arguments:")
                    for i, arg in ipairs(lastLog.Arguments) do
                        print("    [" .. i .. "] = " .. AdvancedSerialize(arg, 2))
                    end
                    if lastLog.ReturnValue then
                        print("  Return value: " .. AdvancedSerialize(lastLog.ReturnValue[1], 2))
                    end
                end
            end
        else
            print("\nNo fishing-related remotes found in current logs.")
            print("Try performing fishing actions in the game first.")
        end
        
        print(string.rep("=", 60) .. "\n")
    end,
    
    -- Generate exploit script for specific remote
    GenerateExploit = function(remoteName, ...)
        local args = {...}
        local remote = nil
        
        -- Find the remote
        for _, service in pairs(game:GetChildren()) do
            pcall(function()
                for _, obj in pairs(service:GetDescendants()) do
                    if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and 
                       obj:GetFullName():find(remoteName) then
                        remote = obj
                        break
                    end
                end
            end)
            if remote then break end
        end
        
        if not remote then
            print("[Network Monitor] Remote not found: " .. remoteName)
            return
        end
        
        local script = "-- Auto-generated exploit script\n"
        script = script .. "-- Generated: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n\n"
        script = script .. "local remote = " .. remote:GetFullName() .. "\n\n"
        script = script .. "-- Execute exploit\n"
        script = script .. "while true do\n"
        
        if remote:IsA("RemoteEvent") then
            script = script .. "    remote:FireServer("
        else
            script = script .. "    remote:InvokeServer("
        end
        
        for i, arg in ipairs(args) do
            if i > 1 then script = script .. ", " end
            script = script .. AdvancedSerialize(arg, 0)
        end
        
        script = script .. ")\n"
        script = script .. "    wait(0.1) -- Adjust delay as needed\n"
        script = script .. "end"
        
        setclipboard(script)
        print("[Network Monitor] Exploit script copied to clipboard!")
        return script
    end,
    
    -- Find specific parameter patterns
    FindParameter = function(paramPattern)
        print("\n" .. string.rep("=", 60))
        print("PARAMETER SEARCH: " .. paramPattern)
        print(string.rep("=", 60))
        
        local found = {}
        
        for remoteName, logs in pairs(NetworkLogs.RemoteEvents) do
            for _, log in ipairs(logs) do
                for i, arg in ipairs(log.Arguments) do
                    local serialized = AdvancedSerialize(arg, 0)
                    if serialized:lower():find(paramPattern:lower()) then
                        table.insert(found, {
                            Remote = remoteName,
                            Type = "RemoteEvent",
                            Time = log.Time,
                            ArgIndex = i,
                            Value = arg
                        })
                    end
                end
            end
        end
        
        for remoteName, logs in pairs(NetworkLogs.RemoteFunctions) do
            for _, log in ipairs(logs) do
                for i, arg in ipairs(log.Arguments) do
                    local serialized = AdvancedSerialize(arg, 0)
                    if serialized:lower():find(paramPattern:lower()) then
                        table.insert(found, {
                            Remote = remoteName,
                            Type = "RemoteFunction",
                            Time = log.Time,
                            ArgIndex = i,
                            Value = arg
                        })
                    end
                end
            end
        end
        
        if #found > 0 then
            print("\nFound " .. #found .. " matches:")
            for _, match in ipairs(found) do
                print("\n[" .. match.Type .. "] " .. match.Remote)
                print("  Time: " .. os.date("%H:%M:%S", match.Time))
                print("  Argument #" .. match.ArgIndex .. ": " .. AdvancedSerialize(match.Value, 1))
            end
        else
            print("\nNo parameters matching '" .. paramPattern .. "' found.")
        end
        
        print(string.rep("=", 60) .. "\n")
        
        return found
    end,
    
    -- Monitor specific remote
    MonitorRemote = function(remoteName)
        print("[Network Monitor] Now monitoring: " .. remoteName)
        
        local remote = nil
        for _, service in pairs(game:GetChildren()) do
            pcall(function()
                for _, obj in pairs(service:GetDescendants()) do
                    if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and 
                       obj:GetFullName():find(remoteName) then
                        remote = obj
                        break
                    end
                end
            end)
            if remote then break end
        end
        
        if not remote then
            print("[Network Monitor] Remote not found!")
            return
        end
        
        print("[Network Monitor] Found remote: " .. remote:GetFullName())
        print("[Network Monitor] Type: " .. remote.ClassName)
        print("[Network Monitor] Real-time monitoring started...")
        
        -- Create dedicated monitor
        if remote:IsA("RemoteEvent") then
            remote.OnClientEvent:Connect(function(...)
                local args = {...}
                print("\n[MONITOR] " .. os.date("%H:%M:%S") .. " - OnClientEvent fired")
                for i, arg in ipairs(args) do
                    print("  Arg[" .. i .. "]: " .. AdvancedSerialize(arg, 1))
                end
            end)
        end
        
        return remote
    end
}

-- Keyboard shortcuts
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Ctrl + Shift + H = Hide/Show UI
    if input.KeyCode == Enum.KeyCode.H and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        if MONITOR_CONFIG.UIVisible then
            _G.NetworkMonitor.HideUI()
        else
            _G.NetworkMonitor.ShowUI()
        end
    end
    
    -- Ctrl + Shift + C = Clear logs
    if input.KeyCode == Enum.KeyCode.C and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        _G.NetworkMonitor.Clear()
    end
    
    -- Ctrl + Shift + E = Export
    if input.KeyCode == Enum.KeyCode.E and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        _G.NetworkMonitor.ExportText()
    end
end)

-- Auto-start monitoring
_G.NetworkMonitor.Start()

-- Welcome message
print([[
╔════════════════════════════════════════════════════════════╗
║     ADVANCED NETWORK MONITOR & REMOTE SPY LOADED!         ║
╠════════════════════════════════════════════════════════════╣
║                                                            ║
║  UI Controls:                                              ║
║  • Drag title bar to move window                          ║
║  • Use tabs to navigate between features                  ║
║  • Search bar to filter remotes                           ║
║  • Click buttons on each log for actions                  ║
║                                                            ║
║  Keyboard Shortcuts:                                       ║
║  • Ctrl+Shift+H : Hide/Show UI                           ║
║  • Ctrl+Shift+C : Clear all logs                         ║
║  • Ctrl+Shift+E : Export to clipboard                    ║
║                                                            ║
║  Global Commands:                                          ║
║  • _G.NetworkMonitor.Start()        : Start monitoring    ║
║  • _G.NetworkMonitor.Stop()         : Stop monitoring     ║
║  • _G.NetworkMonitor.Clear()        : Clear logs          ║
║  • _G.NetworkMonitor.ExportJSON()   : Export as JSON      ║
║  • _G.NetworkMonitor.ExportText()   : Export as Text      ║
║  • _G.NetworkMonitor.GetStats()     : Get statistics      ║
║  • _G.NetworkMonitor.ShowUI()       : Show UI             ║
║  • _G.NetworkMonitor.HideUI()       : Hide UI             ║
║                                                            ║
║  Advanced Analysis:                                        ║
║  • _G.NetworkMonitor.AnalyzeTrading()                     ║
║  • _G.NetworkMonitor.AnalyzeFishing()                     ║
║  • _G.NetworkMonitor.FindParameter("search_term")         ║
║  • _G.NetworkMonitor.MonitorRemote("RemoteName")          ║
║  • _G.NetworkMonitor.GenerateExploit("Remote", args...)   ║
║                                                            ║
║  Examples:                                                 ║
║  • Find trade parameters:                                 ║
║    _G.NetworkMonitor.FindParameter("trade")               ║
║                                                            ║
║  • Monitor specific remote:                                ║
║    _G.NetworkMonitor.MonitorRemote("TradeRequest")        ║
║                                                            ║
║  • Generate exploit script:                                ║
║    _G.NetworkMonitor.GenerateExploit("Fish", "tuna", 10)  ║
║                                                            ║
║  Tips:                                                     ║
║  • Perform actions in-game first to capture parameters    ║
║  • Use Filter buttons to sort by RemoteEvent/Function     ║
║  • Click "View" on any log to see detailed parameters     ║
║  • Click "Script" to generate callable code               ║
║  • Export data regularly to save your findings            ║
║                                                            ║
║  Auto-save: Logs saved to _G.NetworkMonitorLogs every 30s ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝

Ready to spy on ]] .. tostring(ScanForRemotes()) .. [[ remotes!
]])

-- Notification
game.StarterGui:SetCore("SendNotification", {
    Title = "Network Monitor",
    Text = "Advanced Remote Spy loaded successfully!",
    Icon = "rbxassetid://7733911828",
    Duration = 5
})