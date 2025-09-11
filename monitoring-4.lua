-- Roblox Network Monitor Script with UI - Enhanced Version
-- Script ini untuk tujuan debugging dan pembelajaran saja
-- Gunakan dengan bijak dan sesuai ToS Roblox

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")

-- Configuration
local MONITOR_CONFIG = {
    LogRemoteEvents = true,
    LogRemoteFunctions = true,
    LogBindableEvents = true,
    LogBindableFunctions = true,
    MaxLogsPerRemote = 100,
    SaveInterval = 30,
    UIVisible = true,
    AutoStart = true
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

-- Selected log for detailed view
local SelectedLog = nil

-- UI Creation
local function CreateUI()
    -- Main ScreenGui
    local NetworkMonitorUI = Instance.new("ScreenGui")
    NetworkMonitorUI.Name = "NetworkMonitorUI"
    NetworkMonitorUI.ResetOnSpawn = false
    NetworkMonitorUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Try to parent to CoreGui, fallback to PlayerGui
    pcall(function()
        NetworkMonitorUI.Parent = CoreGui
    end)
    if not NetworkMonitorUI.Parent then
        NetworkMonitorUI.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 800, 0, 600)
    MainFrame.Position = UDim2.new(0.5, -400, 0.5, -300)
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = NetworkMonitorUI
    
    -- Add corner rounding
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = MainFrame
    
    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
    TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 10)
    TitleCorner.Parent = TitleBar
    
    -- Fix title bar corners
    local TitleFix = Instance.new("Frame")
    TitleFix.Size = UDim2.new(1, 0, 0, 10)
    TitleFix.Position = UDim2.new(0, 0, 1, -10)
    TitleFix.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    TitleFix.BorderSizePixel = 0
    TitleFix.Parent = TitleBar
    
    -- Title Text
    local TitleText = Instance.new("TextLabel")
    TitleText.Text = "🔍 Network Monitor - Enhanced"
    TitleText.Size = UDim2.new(0.7, 0, 1, 0)
    TitleText.Position = UDim2.new(0, 10, 0, 0)
    TitleText.BackgroundTransparency = 1
    TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleText.TextSize = 16
    TitleText.Font = Enum.Font.SourceSansBold
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    TitleText.Parent = TitleBar
    
    -- Status Indicator
    local StatusIndicator = Instance.new("Frame")
    StatusIndicator.Name = "StatusIndicator"
    StatusIndicator.Size = UDim2.new(0, 10, 0, 10)
    StatusIndicator.Position = UDim2.new(0, 5, 0.5, -5)
    StatusIndicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    StatusIndicator.BorderSizePixel = 0
    StatusIndicator.Parent = TitleBar
    
    local StatusCorner = Instance.new("UICorner")
    StatusCorner.CornerRadius = UDim.new(1, 0)
    StatusCorner.Parent = StatusIndicator
    
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Text = "Running"
    StatusLabel.Size = UDim2.new(0, 60, 0, 20)
    StatusLabel.Position = UDim2.new(0, 20, 0.5, -10)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    StatusLabel.TextSize = 12
    StatusLabel.Font = Enum.Font.SourceSans
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Parent = TitleBar
    
    -- Minimize Button
    local MinimizeBtn = Instance.new("TextButton")
    MinimizeBtn.Text = "−"
    MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
    MinimizeBtn.Position = UDim2.new(1, -70, 0, 5)
    MinimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinimizeBtn.Font = Enum.Font.SourceSansBold
    MinimizeBtn.TextSize = 18
    MinimizeBtn.Parent = TitleBar
    
    local MinimizeCorner = Instance.new("UICorner")
    MinimizeCorner.CornerRadius = UDim.new(0, 5)
    MinimizeCorner.Parent = MinimizeBtn
    
    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Text = "×"
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -35, 0, 5)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.Font = Enum.Font.SourceSansBold
    CloseBtn.TextSize = 18
    CloseBtn.Parent = TitleBar
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 5)
    CloseCorner.Parent = CloseBtn
    
    -- Tab Container
    local TabContainer = Instance.new("Frame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(1, -20, 0, 35)
    TabContainer.Position = UDim2.new(0, 10, 0, 50)
    TabContainer.BackgroundTransparency = 1
    TabContainer.Parent = MainFrame
    
    -- Tab Buttons
    local TabLayout = Instance.new("UIListLayout")
    TabLayout.FillDirection = Enum.FillDirection.Horizontal
    TabLayout.Padding = UDim.new(0, 5)
    TabLayout.Parent = TabContainer
    
    local function CreateTabButton(text, isActive)
        local TabBtn = Instance.new("TextButton")
        TabBtn.Text = text
        TabBtn.Size = UDim2.new(0, 100, 1, 0)
        TabBtn.BackgroundColor3 = isActive and Color3.fromRGB(70, 70, 70) or Color3.fromRGB(40, 40, 40)
        TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        TabBtn.Font = Enum.Font.SourceSans
        TabBtn.TextSize = 14
        TabBtn.Parent = TabContainer
        
        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 5)
        TabCorner.Parent = TabBtn
        
        return TabBtn
    end
    
    local MonitorTab = CreateTabButton("Monitor", true)
    local StatsTab = CreateTabButton("Stats", false)
    local SettingsTab = CreateTabButton("Settings", false)
    local LogsTab = CreateTabButton("Logs", false)
    local DetailTab = CreateTabButton("Details", false)
    
    -- Content Frame
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Size = UDim2.new(1, -20, 1, -100)
    ContentFrame.Position = UDim2.new(0, 10, 0, 90)
    ContentFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    ContentFrame.BorderSizePixel = 0
    ContentFrame.Parent = MainFrame
    
    local ContentCorner = Instance.new("UICorner")
    ContentCorner.CornerRadius = UDim.new(0, 5)
    ContentCorner.Parent = ContentFrame
    
    -- Monitor Content (ScrollingFrame for logs)
    local MonitorContent = Instance.new("ScrollingFrame")
    MonitorContent.Name = "MonitorContent"
    MonitorContent.Size = UDim2.new(1, -10, 1, -10)
    MonitorContent.Position = UDim2.new(0, 5, 0, 5)
    MonitorContent.BackgroundTransparency = 1
    MonitorContent.ScrollBarThickness = 6
    MonitorContent.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    MonitorContent.CanvasSize = UDim2.new(0, 0, 0, 0)
    MonitorContent.Parent = ContentFrame
    
    local LogLayout = Instance.new("UIListLayout")
    LogLayout.Padding = UDim.new(0, 5)
    LogLayout.Parent = MonitorContent
    
    -- Stats Content
    local StatsContent = Instance.new("Frame")
    StatsContent.Name = "StatsContent"
    StatsContent.Size = UDim2.new(1, -10, 1, -10)
    StatsContent.Position = UDim2.new(0, 5, 0, 5)
    StatsContent.BackgroundTransparency = 1
    StatsContent.Visible = false
    StatsContent.Parent = ContentFrame
    
    -- Stats Labels
    local function CreateStatLabel(text, position)
        local StatFrame = Instance.new("Frame")
        StatFrame.Size = UDim2.new(1, 0, 0, 40)
        StatFrame.Position = position
        StatFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        StatFrame.BorderSizePixel = 0
        StatFrame.Parent = StatsContent
        
        local StatCorner = Instance.new("UICorner")
        StatCorner.CornerRadius = UDim.new(0, 5)
        StatCorner.Parent = StatFrame
        
        local StatText = Instance.new("TextLabel")
        StatText.Text = text
        StatText.Size = UDim2.new(0.6, -10, 1, 0)
        StatText.Position = UDim2.new(0, 10, 0, 0)
        StatText.BackgroundTransparency = 1
        StatText.TextColor3 = Color3.fromRGB(200, 200, 200)
        StatText.TextSize = 14
        StatText.Font = Enum.Font.SourceSans
        StatText.TextXAlignment = Enum.TextXAlignment.Left
        StatText.Parent = StatFrame
        
        local StatValue = Instance.new("TextLabel")
        StatValue.Name = "Value"
        StatValue.Text = "0"
        StatValue.Size = UDim2.new(0.4, -10, 1, 0)
        StatValue.Position = UDim2.new(0.6, 0, 0, 0)
        StatValue.BackgroundTransparency = 1
        StatValue.TextColor3 = Color3.fromRGB(100, 255, 100)
        StatValue.TextSize = 14
        StatValue.Font = Enum.Font.SourceSansBold
        StatValue.TextXAlignment = Enum.TextXAlignment.Right
        StatValue.Parent = StatFrame
        
        return StatFrame
    end
    
    local TotalRemoteEvents = CreateStatLabel("Total RemoteEvents:", UDim2.new(0, 0, 0, 0))
    local TotalRemoteFunctions = CreateStatLabel("Total RemoteFunctions:", UDim2.new(0, 0, 0, 50))
    local TotalBindableEvents = CreateStatLabel("Total BindableEvents:", UDim2.new(0, 0, 0, 100))
    local TotalBindableFunctions = CreateStatLabel("Total BindableFunctions:", UDim2.new(0, 0, 0, 150))
    local UniqueRemotes = CreateStatLabel("Unique Remotes:", UDim2.new(0, 0, 0, 200))
    local SessionTime = CreateStatLabel("Session Time:", UDim2.new(0, 0, 0, 250))
    local LastUpdate = CreateStatLabel("Last Update:", UDim2.new(0, 0, 0, 300))
    
    -- Settings Content
    local SettingsContent = Instance.new("Frame")
    SettingsContent.Name = "SettingsContent"
    SettingsContent.Size = UDim2.new(1, -10, 1, -10)
    SettingsContent.Position = UDim2.new(0, 5, 0, 5)
    SettingsContent.BackgroundTransparency = 1
    SettingsContent.Visible = false
    SettingsContent.Parent = ContentFrame
    
    -- Settings Options
    local function CreateToggle(text, position, configKey)
        local ToggleFrame = Instance.new("Frame")
        ToggleFrame.Size = UDim2.new(1, 0, 0, 40)
        ToggleFrame.Position = position
        ToggleFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        ToggleFrame.BorderSizePixel = 0
        ToggleFrame.Parent = SettingsContent
        
        local ToggleCorner = Instance.new("UICorner")
        ToggleCorner.CornerRadius = UDim.new(0, 5)
        ToggleCorner.Parent = ToggleFrame
        
        local ToggleText = Instance.new("TextLabel")
        ToggleText.Text = text
        ToggleText.Size = UDim2.new(0.7, -10, 1, 0)
        ToggleText.Position = UDim2.new(0, 10, 0, 0)
        ToggleText.BackgroundTransparency = 1
        ToggleText.TextColor3 = Color3.fromRGB(200, 200, 200)
        ToggleText.TextSize = 14
        ToggleText.Font = Enum.Font.SourceSans
        ToggleText.TextXAlignment = Enum.TextXAlignment.Left
        ToggleText.Parent = ToggleFrame
        
        local ToggleBtn = Instance.new("TextButton")
        ToggleBtn.Size = UDim2.new(0, 60, 0, 30)
        ToggleBtn.Position = UDim2.new(1, -70, 0.5, -15)
        ToggleBtn.BackgroundColor3 = MONITOR_CONFIG[configKey] and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
        ToggleBtn.Text = MONITOR_CONFIG[configKey] and "ON" or "OFF"
        ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        ToggleBtn.Font = Enum.Font.SourceSansBold
        ToggleBtn.TextSize = 12
        ToggleBtn.Parent = ToggleFrame
        
        local ToggleBtnCorner = Instance.new("UICorner")
        ToggleBtnCorner.CornerRadius = UDim.new(0, 5)
        ToggleBtnCorner.Parent = ToggleBtn
        
        ToggleBtn.MouseButton1Click:Connect(function()
            MONITOR_CONFIG[configKey] = not MONITOR_CONFIG[configKey]
            ToggleBtn.BackgroundColor3 = MONITOR_CONFIG[configKey] and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
            ToggleBtn.Text = MONITOR_CONFIG[configKey] and "ON" or "OFF"
        end)
        
        return ToggleFrame
    end
    
    CreateToggle("Log RemoteEvents", UDim2.new(0, 0, 0, 0), "LogRemoteEvents")
    CreateToggle("Log RemoteFunctions", UDim2.new(0, 0, 0, 50), "LogRemoteFunctions")
    CreateToggle("Log BindableEvents", UDim2.new(0, 0, 0, 100), "LogBindableEvents")
    CreateToggle("Log BindableFunctions", UDim2.new(0, 0, 0, 150), "LogBindableFunctions")
    CreateToggle("Auto Start", UDim2.new(0, 0, 0, 200), "AutoStart")
    
    -- Clear Logs Button
    local ClearLogsBtn = Instance.new("TextButton")
    ClearLogsBtn.Text = "Clear All Logs"
    ClearLogsBtn.Size = UDim2.new(0, 150, 0, 40)
    ClearLogsBtn.Position = UDim2.new(0, 0, 0, 260)
    ClearLogsBtn.BackgroundColor3 = Color3.fromRGB(170, 85, 0)
    ClearLogsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ClearLogsBtn.Font = Enum.Font.SourceSansBold
    ClearLogsBtn.TextSize = 14
    ClearLogsBtn.Parent = SettingsContent
    
    local ClearCorner = Instance.new("UICorner")
    ClearCorner.CornerRadius = UDim.new(0, 5)
    ClearCorner.Parent = ClearLogsBtn
    
    -- Export Button
    local ExportBtn = Instance.new("TextButton")
    ExportBtn.Text = "Export to Console"
    ExportBtn.Size = UDim2.new(0, 150, 0, 40)
    ExportBtn.Position = UDim2.new(0, 160, 0, 260)
    ExportBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 170)
    ExportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ExportBtn.Font = Enum.Font.SourceSansBold
    ExportBtn.TextSize = 14
    ExportBtn.Parent = SettingsContent
    
    local ExportCorner = Instance.new("UICorner")
    ExportCorner.CornerRadius = UDim.new(0, 5)
    ExportCorner.Parent = ExportBtn
    
    -- Logs Content (Text display)
    local LogsContent = Instance.new("ScrollingFrame")
    LogsContent.Name = "LogsContent"
    LogsContent.Size = UDim2.new(1, -10, 1, -10)
    LogsContent.Position = UDim2.new(0, 5, 0, 5)
    LogsContent.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    LogsContent.ScrollBarThickness = 6
    LogsContent.CanvasSize = UDim2.new(0, 0, 0, 0)
    LogsContent.Visible = false
    LogsContent.Parent = ContentFrame
    
    local LogsCorner = Instance.new("UICorner")
    LogsCorner.CornerRadius = UDim.new(0, 5)
    LogsCorner.Parent = LogsContent
    
    local LogsTextBox = Instance.new("TextBox")
    LogsTextBox.Size = UDim2.new(1, -10, 0, 0)
    LogsTextBox.Position = UDim2.new(0, 5, 0, 5)
    LogsTextBox.BackgroundTransparency = 1
    LogsTextBox.TextColor3 = Color3.fromRGB(200, 200, 200)
    LogsTextBox.Font = Enum.Font.Code
    LogsTextBox.TextSize = 14
    LogsTextBox.TextXAlignment = Enum.TextXAlignment.Left
    LogsTextBox.TextYAlignment = Enum.TextYAlignment.Top
    LogsTextBox.ClearTextOnFocus = false
    LogsTextBox.MultiLine = true
    LogsTextBox.TextEditable = false
    LogsTextBox.Text = "Logs will appear here..."
    LogsTextBox.Parent = LogsContent
    
    -- Detail Content
    local DetailContent = Instance.new("ScrollingFrame")
    DetailContent.Name = "DetailContent"
    DetailContent.Size = UDim2.new(1, -10, 1, -10)
    DetailContent.Position = UDim2.new(0, 5, 0, 5)
    DetailContent.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    DetailContent.ScrollBarThickness = 6
    DetailContent.CanvasSize = UDim2.new(0, 0, 0, 0)
    DetailContent.Visible = false
    DetailContent.Parent = ContentFrame
    
    local DetailCorner = Instance.new("UICorner")
    DetailCorner.CornerRadius = UDim.new(0, 5)
    DetailCorner.Parent = DetailContent
    
    local DetailTitle = Instance.new("TextLabel")
    DetailTitle.Text = "Event Details"
    DetailTitle.Size = UDim2.new(1, -10, 0, 30)
    DetailTitle.Position = UDim2.new(0, 5, 0, 5)
    DetailTitle.BackgroundTransparency = 1
    DetailTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    DetailTitle.TextSize = 16
    DetailTitle.Font = Enum.Font.SourceSansBold
    DetailTitle.TextXAlignment = Enum.TextXAlignment.Left
    DetailTitle.Parent = DetailContent
    
    local DetailText = Instance.new("TextLabel")
    DetailText.Name = "DetailText"
    DetailText.Size = UDim2.new(1, -10, 1, -40)
    DetailText.Position = UDim2.new(0, 5, 0, 40)
    DetailText.BackgroundTransparency = 1
    DetailText.TextColor3 = Color3.fromRGB(200, 200, 200)
    DetailText.Font = Enum.Font.Code
    DetailText.TextSize = 12
    DetailText.TextXAlignment = Enum.TextXAlignment.Left
    DetailText.TextYAlignment = Enum.TextYAlignment.Top
    DetailText.TextWrapped = true
    DetailText.Text = "Select a log entry to view details"
    DetailText.Parent = DetailContent
    
    -- Copy Detail Button
    local CopyDetailBtn = Instance.new("TextButton")
    CopyDetailBtn.Text = "Copy Details"
    CopyDetailBtn.Size = UDim2.new(0, 100, 0, 30)
    CopyDetailBtn.Position = UDim2.new(1, -110, 0, 5)
    CopyDetailBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 170)
    CopyDetailBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CopyDetailBtn.Font = Enum.Font.SourceSansBold
    CopyDetailBtn.TextSize = 12
    CopyDetailBtn.Visible = false
    CopyDetailBtn.Parent = DetailContent
    
    local CopyDetailCorner = Instance.new("UICorner")
    CopyDetailCorner.CornerRadius = UDim.new(0, 5)
    CopyDetailCorner.Parent = CopyDetailBtn
    
    -- Tab switching
    local currentTab = "Monitor"
    local tabs = {
        Monitor = {btn = MonitorTab, content = MonitorContent},
        Stats = {btn = StatsTab, content = StatsContent},
        Settings = {btn = SettingsTab, content = SettingsContent},
        Logs = {btn = LogsTab, content = LogsContent},
        Details = {btn = DetailTab, content = DetailContent}
    }
    
    local function SwitchTab(tabName)
        for name, tab in pairs(tabs) do
            if name == tabName then
                tab.btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
                tab.content.Visible = true
                currentTab = name
            else
                tab.btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                tab.content.Visible = false
            end
        end
    end
    
    MonitorTab.MouseButton1Click:Connect(function() SwitchTab("Monitor") end)
    StatsTab.MouseButton1Click:Connect(function() SwitchTab("Stats") end)
    SettingsTab.MouseButton1Click:Connect(function() SwitchTab("Settings") end)
    LogsTab.MouseButton1Click:Connect(function() 
        SwitchTab("Logs") 
        SaveLogs()
    end)
    DetailTab.MouseButton1Click:Connect(function() 
        SwitchTab("Details") 
        UpdateDetailView()
    end)
    
    -- Make frame draggable
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
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
    
    -- Minimize functionality
    local minimized = false
    MinimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            ContentFrame.Visible = false
            TabContainer.Visible = false
            MainFrame.Size = UDim2.new(0, 300, 0, 40)
        else
            ContentFrame.Visible = true
            TabContainer.Visible = true
            MainFrame.Size = UDim2.new(0, 800, 0, 600)
        end
    end)
    
    -- Close functionality
    CloseBtn.MouseButton1Click:Connect(function()
        NetworkMonitorUI:Destroy()
        MONITOR_CONFIG.UIVisible = false
    end)
    
    -- Copy detail button functionality
    CopyDetailBtn.MouseButton1Click:Connect(function()
        if SelectedLog then
            local detailText = FormatLogDetail(SelectedLog)
            if setclipboard then
                setclipboard(detailText)
                
                -- Show confirmation
                local originalText = CopyDetailBtn.Text
                CopyDetailBtn.Text = "Copied!"
                wait(1)
                CopyDetailBtn.Text = originalText
            else
                print("Clipboard not available")
            end
        end
    end)
    
    return {
        UI = NetworkMonitorUI,
        MonitorContent = MonitorContent,
        StatsContent = StatsContent,
        LogsTextBox = LogsTextBox,
        DetailText = DetailText,
        CopyDetailBtn = CopyDetailBtn,
        TotalRemoteEvents = TotalRemoteEvents,
        TotalRemoteFunctions = TotalRemoteFunctions,
        TotalBindableEvents = TotalBindableEvents,
        TotalBindableFunctions = TotalBindableFunctions,
        UniqueRemotes = UniqueRemotes,
        SessionTime = SessionTime,
        LastUpdate = LastUpdate,
        ClearLogsBtn = ClearLogsBtn,
        ExportBtn = ExportBtn,
        StatusIndicator = StatusIndicator,
        StatusLabel = StatusLabel
    }
end

-- Function to add log entry to UI
local function AddLogToUI(logType, remoteName, direction, args, logData)
    if not UI or not UI.MonitorContent then return end
    
    local LogEntry = Instance.new("Frame")
    LogEntry.Size = UDim2.new(1, 0, 0, 60)
    LogEntry.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    LogEntry.Parent = UI.MonitorContent
    
    local EntryCorner = Instance.new("UICorner")
    EntryCorner.CornerRadius = UDim.new(0, 5)
    EntryCorner.Parent = LogEntry
    
    -- Remote name
    local RemoteName = Instance.new("TextLabel")
    RemoteName.Text = string.format("[%s] %s", logType, remoteName:match("([^.]+)$") or remoteName)
    RemoteName.Size = UDim2.new(1, -10, 0, 20)
    RemoteName.Position = UDim2.new(0, 5, 0, 2)
    RemoteName.BackgroundTransparency = 1
    RemoteName.TextColor3 = logType == "RemoteEvent" and Color3.fromRGB(100, 200, 255) or 
                           logType == "RemoteFunction" and Color3.fromRGB(255, 200, 100) or
                           logType == "BindableEvent" and Color3.fromRGB(200, 255, 100) or
                           logType == "BindableFunction" and Color3.fromRGB(200, 100, 255)
    RemoteName.Font = Enum.Font.SourceSansBold
    RemoteName.TextSize = 14
    RemoteName.TextXAlignment = Enum.TextXAlignment.Left
    RemoteName.TextTruncate = Enum.TextTruncate.AtEnd
    RemoteName.Parent = LogEntry
    
    -- Direction
    local DirectionLabel = Instance.new("TextLabel")
    DirectionLabel.Text = direction
    DirectionLabel.Size = UDim2.new(0, 80, 0, 16)
    DirectionLabel.Position = UDim2.new(1, -85, 0, 2)
    DirectionLabel.BackgroundColor3 = direction == "Incoming" and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(120, 0, 0)
    DirectionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    DirectionLabel.Font = Enum.Font.SourceSans
    DirectionLabel.TextSize = 12
    DirectionLabel.Parent = LogEntry
    
    local DirCorner = Instance.new("UICorner")
    DirCorner.CornerRadius = UDim.new(0, 3)
    DirCorner.Parent = DirectionLabel
    
    -- Arguments preview
    local ArgsLabel = Instance.new("TextLabel")
    ArgsLabel.Text = string.format("Args: %d | %s", #args, os.date("%H:%M:%S", logData.Time))
    ArgsLabel.Size = UDim2.new(1, -10, 0, 16)
    ArgsLabel.Position = UDim2.new(0, 5, 0, 22)
    ArgsLabel.BackgroundTransparency = 1
    ArgsLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    ArgsLabel.Font = Enum.Font.Code
    ArgsLabel.TextSize = 12
    ArgsLabel.TextXAlignment = Enum.TextXAlignment.Left
    ArgsLabel.Parent = LogEntry
    
    -- Args detail
    local ArgsDetail = Instance.new("TextLabel")
    local argsText = ""
    for i = 1, math.min(#args, 3) do
        if i > 1 then argsText = argsText .. ", " end
        local arg = tostring(args[i]):sub(1, 20)
        argsText = argsText .. arg
    end
    if #args > 3 then argsText = argsText .. "..." end
    ArgsDetail.Text = argsText
    ArgsDetail.Size = UDim2.new(1, -10, 0, 16)
    ArgsDetail.Position = UDim2.new(0, 5, 0, 40)
    ArgsDetail.BackgroundTransparency = 1
    ArgsDetail.TextColor3 = Color3.fromRGB(180, 180, 180)
    ArgsDetail.Font = Enum.Font.Code
    ArgsDetail.TextSize = 12
    ArgsDetail.TextXAlignment = Enum.TextXAlignment.Left
    ArgsDetail.TextTruncate = Enum.TextTruncate.AtEnd
    ArgsDetail.Parent = LogEntry
    
    -- Click to view details
    LogEntry.MouseButton1Click:Connect(function()
        SelectedLog = logData
        if UI.DetailText then
            UpdateDetailView()
        end
    end)
    
    -- Hover effect
    LogEntry.MouseEnter:Connect(function()
        LogEntry.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    end)
    
    LogEntry.MouseLeave:Connect(function()
        LogEntry.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    end)
    
    -- Update canvas size
    UI.MonitorContent.CanvasSize = UDim2.new(0, 0, 0, UI.MonitorContent.UIListLayout.AbsoluteContentSize.Y)
end

-- Function to format log detail for display
local function FormatLogDetail(logData)
    local detail = ""
    
    detail = detail .. string.format("=== %s DETAIL ===\n", logData.RemoteType:upper())
    detail = detail .. string.format("Remote Name: %s\n", logData.RemoteName)
    detail = detail .. string.format("Direction: %s\n", logData.Direction)
    detail = detail .. string.format("Time: %s\n", os.date("%Y-%m-%d %H:%M:%S", logData.Time))
    detail = detail .. string.format("Tick: %.3f\n", logData.Tick)
    detail = detail .. string.format("Arguments (%d):\n", #logData.Arguments)
    
    for i, arg in ipairs(logData.Arguments) do
        detail = detail .. string.format("  [%d] %s\n", i, arg)
    end
    
    if logData.Traceback then
        detail = detail .. "\nCall Stack:\n"
        detail = detail .. logData.Traceback
    end
    
    return detail
end

-- Update detail view
local function UpdateDetailView()
    if not UI or not UI.DetailText then return end
    
    if SelectedLog then
        local detailText = FormatLogDetail(SelectedLog)
        UI.DetailText.Text = detailText
        UI.CopyDetailBtn.Visible = true
        
        -- Calculate text height and update canvas size
        local textSize = TextService:GetTextSize(
            detailText, 
            UI.DetailText.TextSize, 
            UI.DetailText.Font, 
            Vector2.new(UI.DetailText.AbsoluteSize.X, 10000)
        )
        UI.DetailContent.CanvasSize = UDim2.new(0, 0, 0, textSize.Y + 100)
    else
        UI.DetailText.Text = "Select a log entry to view details"
        UI.CopyDetailBtn.Visible = false
    end
end

-- Update Stats
local function UpdateStats()
    if not UI then return end
    
    local totalRemoteEvents = 0
    local totalRemoteFunctions = 0
    local totalBindableEvents = 0
    local totalBindableFunctions = 0
    local uniqueRemotes = 0
    
    for _, logs in pairs(NetworkLogs.RemoteEvents) do
        totalRemoteEvents = totalRemoteEvents + #logs
        uniqueRemotes = uniqueRemotes + 1
    end
    
    for _, logs in pairs(NetworkLogs.RemoteFunctions) do
        totalRemoteFunctions = totalRemoteFunctions + #logs
        uniqueRemotes = uniqueRemotes + 1
    end
    
    for _, logs in pairs(NetworkLogs.BindableEvents) do
        totalBindableEvents = totalBindableEvents + #logs
        uniqueRemotes = uniqueRemotes + 1
    end
    
    for _, logs in pairs(NetworkLogs.BindableFunctions) do
        totalBindableFunctions = totalBindableFunctions + #logs
        uniqueRemotes = uniqueRemotes + 1
    end
    
    UI.TotalRemoteEvents.Value.Text = tostring(totalRemoteEvents)
    UI.TotalRemoteFunctions.Value.Text = tostring(totalRemoteFunctions)
    UI.TotalBindableEvents.Value.Text = tostring(totalBindableEvents)
    UI.TotalBindableFunctions.Value.Text = tostring(totalBindableFunctions)
    UI.UniqueRemotes.Value.Text = tostring(uniqueRemotes)
    
    local sessionTime = os.time() - NetworkLogs.StartTime
    local hours = math.floor(sessionTime / 3600)
    local minutes = math.floor((sessionTime % 3600) / 60)
    local seconds = sessionTime % 60
    UI.SessionTime.Value.Text = string.format("%02d:%02d:%02d", hours, minutes, seconds)
    
    UI.LastUpdate.Value.Text = os.date("%H:%M:%S")
end

-- Utility function to serialize data
local function SerializeData(data, depth)
    depth = depth or 0
    if depth > 3 then return "[Max Depth Reached]" end
    
    local dataType = typeof(data)
    
    if dataType == "table" then
        local result = {}
        local count = 0
        for k, v in pairs(data) do
            count = count + 1
            if count > 10 then
                result[#result + 1] = "..."
                break
            end
            result[#result + 1] = string.format("%s: %s", tostring(k), SerializeData(v, depth + 1))
        end
        return string.format("Table{%s}", table.concat(result, ", "))
    elseif dataType == "Instance" then
        return string.format("Instance<%s>: %s", data.ClassName, data:GetFullName())
    elseif dataType == "CFrame" then
        return string.format("CFrame: %s", tostring(data))
    elseif dataType == "Vector3" then
        return string.format("Vector3(%f, %f, %f)", data.X, data.Y, data.Z)
    elseif dataType == "Color3" then
        return string.format("Color3(%f, %f, %f)", data.R, data.G, data.B)
    elseif dataType == "EnumItem" then
        return string.format("Enum.%s.%s", tostring(data.EnumType), data.Name)
    elseif dataType == "string" then
        if #data > 100 then
            return string.format("\"%s...\"", data:sub(1, 100))
        else
            return string.format("\"%s\"", data)
        end
    else
        return tostring(data)
    end
end

-- Function to create log entry
local function CreateLogEntry(remoteName, remoteType, args, isIncoming)
    return {
        Time = os.time(),
        Tick = tick(),
        RemoteName = remoteName,
        RemoteType = remoteType,
        Direction = isIncoming and "Incoming" or "Outgoing",
        Arguments = args,
        Traceback = debug.traceback()
    }
end

-- Hook into RemoteEvents
local function HookRemoteEvent(remote)
    if not MONITOR_CONFIG.LogRemoteEvents then return end
    
    local remoteName = remote:GetFullName()
    
    -- Initialize log storage for this remote
    if not NetworkLogs.RemoteEvents[remoteName] then
        NetworkLogs.RemoteEvents[remoteName] = {}
    end
    
    -- Hook OnClientEvent (incoming)
    local connection
    connection = remote.OnClientEvent:Connect(function(...)
        if not MONITOR_CONFIG.LogRemoteEvents then return end
        
        local args = {...}
        local serializedArgs = {}
        
        for i, arg in ipairs(args) do
            serializedArgs[i] = SerializeData(arg)
        end
        
        local logEntry = CreateLogEntry(remoteName, "RemoteEvent", serializedArgs, true)
        
        -- Limit logs per remote
        if #NetworkLogs.RemoteEvents[remoteName] < MONITOR_CONFIG.MaxLogsPerRemote then
            table.insert(NetworkLogs.RemoteEvents[remoteName], logEntry)
        end
        
        -- Add to UI
        AddLogToUI("RemoteEvent", remoteName, "Incoming", serializedArgs, logEntry)
        
        print(string.format("[Network Monitor] RemoteEvent '%s' received with %d args", remoteName, #args))
    end)
    
    -- Hook FireServer (outgoing) - requires metatable manipulation
    pcall(function()
        local mt = getmetatable(remote)
        if mt then
            local oldNamecall = mt.__namecall
            mt.__namecall = function(self, ...)
                local method = getnamecallmethod()
                local args = {...}
                
                if method == "FireServer" and self == remote and MONITOR_CONFIG.LogRemoteEvents then
                    local serializedArgs = {}
                    for i, arg in ipairs(args) do
                        serializedArgs[i] = SerializeData(arg)
                    end
                    
                    local logEntry = CreateLogEntry(remoteName, "RemoteEvent", serializedArgs, false)
                    
                    if #NetworkLogs.RemoteEvents[remoteName] < MONITOR_CONFIG.MaxLogsPerRemote then
                        table.insert(NetworkLogs.RemoteEvents[remoteName], logEntry)
                    end
                    
                    -- Add to UI
                    AddLogToUI("RemoteEvent", remoteName, "Outgoing", serializedArgs, logEntry)
                    
                    print(string.format("[Network Monitor] FireServer called on '%s' with %d args", remoteName, #args))
                end
                
                return oldNamecall(self, ...)
            end
        end
    end)
end

-- Hook into RemoteFunctions
local function HookRemoteFunction(remote)
    if not MONITOR_CONFIG.LogRemoteFunctions then return end
    
    local remoteName = remote:GetFullName()
    
    if not NetworkLogs.RemoteFunctions[remoteName] then
        NetworkLogs.RemoteFunctions[remoteName] = {}
    end
    
    -- Hook OnClientInvoke (incoming)
    local originalInvoke = remote.OnClientInvoke
    remote.OnClientInvoke = function(...)
        if MONITOR_CONFIG.LogRemoteFunctions then
            local args = {...}
            local serializedArgs = {}
            
            for i, arg in ipairs(args) do
                serializedArgs[i] = SerializeData(arg)
            end
            
            local logEntry = CreateLogEntry(remoteName, "RemoteFunction", serializedArgs, true)
            
            if #NetworkLogs.RemoteFunctions[remoteName] < MONITOR_CONFIG.MaxLogsPerRemote then
                table.insert(NetworkLogs.RemoteFunctions[remoteName], logEntry)
            end
            
            -- Add to UI
            AddLogToUI("RemoteFunction", remoteName, "Incoming", serializedArgs, logEntry)
            
            print(string.format("[Network Monitor] RemoteFunction '%s' invoked with %d args", remoteName, #args))
        end
        
        if originalInvoke then
            return originalInvoke(...)
        end
    end
    
    -- Hook InvokeServer (outgoing) - requires metatable manipulation
    pcall(function()
        local mt = getmetatable(remote)
        if mt then
            local oldNamecall = mt.__namecall
            mt.__namecall = function(self, ...)
                local method = getnamecallmethod()
                local args = {...}
                
                if method == "InvokeServer" and self == remote and MONITOR_CONFIG.LogRemoteFunctions then
                    local serializedArgs = {}
                    for i, arg in ipairs(args) do
                        serializedArgs[i] = SerializeData(arg)
                    end
                    
                    local logEntry = CreateLogEntry(remoteName, "RemoteFunction", serializedArgs, false)
                    
                    if #NetworkLogs.RemoteFunctions[remoteName] < MONITOR_CONFIG.MaxLogsPerRemote then
                        table.insert(NetworkLogs.RemoteFunctions[remoteName], logEntry)
                    end
                    
                    -- Add to UI
                    AddLogToUI("RemoteFunction", remoteName, "Outgoing", serializedArgs, logEntry)
                    
                    print(string.format("[Network Monitor] InvokeServer called on '%s' with %d args", remoteName, #args))
                end
                
                return oldNamecall(self, ...)
            end
        end
    end)
end

-- Hook into BindableEvents
local function HookBindableEvent(bindable)
    if not MONITOR_CONFIG.LogBindableEvents then return end
    
    local bindableName = bindable:GetFullName()
    
    -- Initialize log storage for this bindable
    if not NetworkLogs.BindableEvents[bindableName] then
        NetworkLogs.BindableEvents[bindableName] = {}
    end
    
    -- Hook Event (incoming)
    local connection
    connection = bindable.Event:Connect(function(...)
        if not MONITOR_CONFIG.LogBindableEvents then return end
        
        local args = {...}
        local serializedArgs = {}
        
        for i, arg in ipairs(args) do
            serializedArgs[i] = SerializeData(arg)
        end
        
        local logEntry = CreateLogEntry(bindableName, "BindableEvent", serializedArgs, true)
        
        -- Limit logs per bindable
        if #NetworkLogs.BindableEvents[bindableName] < MONITOR_CONFIG.MaxLogsPerRemote then
            table.insert(NetworkLogs.BindableEvents[bindableName], logEntry)
        end
        
        -- Add to UI
        AddLogToUI("BindableEvent", bindableName, "Incoming", serializedArgs, logEntry)
        
        print(string.format("[Network Monitor] BindableEvent '%s' fired with %d args", bindableName, #args))
    end)
    
    -- Hook Fire (outgoing) - requires metatable manipulation
    pcall(function()
        local oldFire = bindable.Fire
        bindable.Fire = function(self, ...)
            if MONITOR_CONFIG.LogBindableEvents then
                local args = {...}
                local serializedArgs = {}
                
                for i, arg in ipairs(args) do
                    serializedArgs[i] = SerializeData(arg)
                end
                
                local logEntry = CreateLogEntry(bindableName, "BindableEvent", serializedArgs, false)
                
                if #NetworkLogs.BindableEvents[bindableName] < MONITOR_CONFIG.MaxLogsPerRemote then
                    table.insert(NetworkLogs.BindableEvents[bindableName], logEntry)
                end
                
                -- Add to UI
                AddLogToUI("BindableEvent", bindableName, "Outgoing", serializedArgs, logEntry)
                
                print(string.format("[Network Monitor] Fire called on BindableEvent '%s' with %d args", bindableName, #args))
            end
            
            return oldFire(self, ...)
        end
    end)
end

-- Hook into BindableFunctions
local function HookBindableFunction(bindable)
    if not MONITOR_CONFIG.LogBindableFunctions then return end
    
    local bindableName = bindable:GetFullName()
    
    if not NetworkLogs.BindableFunctions[bindableName] then
        NetworkLogs.BindableFunctions[bindableName] = {}
    end
    
    -- Hook OnInvoke (incoming)
    local originalInvoke = bindable.OnInvoke
    bindable.OnInvoke = function(...)
        if MONITOR_CONFIG.LogBindableFunctions then
            local args = {...}
            local serializedArgs = {}
            
            for i, arg in ipairs(args) do
                serializedArgs[i] = SerializeData(arg)
            end
            
            local logEntry = CreateLogEntry(bindableName, "BindableFunction", serializedArgs, true)
            
            if #NetworkLogs.BindableFunctions[bindableName] < MONITOR_CONFIG.MaxLogsPerRemote then
                table.insert(NetworkLogs.BindableFunctions[bindableName], logEntry)
            end
            
            -- Add to UI
            AddLogToUI("BindableFunction", bindableName, "Incoming", serializedArgs, logEntry)
            
            print(string.format("[Network Monitor] BindableFunction '%s' invoked with %d args", bindableName, #args))
        end
        
        if originalInvoke then
            return originalInvoke(...)
        end
    end
    
    -- Hook Invoke (outgoing) - requires metatable manipulation
    pcall(function()
        local oldInvoke = bindable.Invoke
        bindable.Invoke = function(self, ...)
            if MONITOR_CONFIG.LogBindableFunctions then
                local args = {...}
                local serializedArgs = {}
                
                for i, arg in ipairs(args) do
                    serializedArgs[i] = SerializeData(arg)
                end
                
                local logEntry = CreateLogEntry(bindableName, "BindableFunction", serializedArgs, false)
                
                if #NetworkLogs.BindableFunctions[bindableName] < MONITOR_CONFIG.MaxLogsPerRemote then
                    table.insert(NetworkLogs.BindableFunctions[bindableName], logEntry)
                end
                
                -- Add to UI
                AddLogToUI("BindableFunction", bindableName, "Outgoing", serializedArgs, logEntry)
                
                print(string.format("[Network Monitor] Invoke called on BindableFunction '%s' with %d args", bindableName, #args))
            end
            
            return oldInvoke(self, ...)
        end
    end)
end

-- Scan for existing remotes
local function ScanForRemotes()
    local remoteCount = 0
    
    -- Scan all descendants of the game
    local function scanDescendants(parent)
        for _, obj in pairs(parent:GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                HookRemoteEvent(obj)
                remoteCount = remoteCount + 1
            elseif obj:IsA("RemoteFunction") then
                HookRemoteFunction(obj)
                remoteCount = remoteCount + 1
            elseif obj:IsA("BindableEvent") then
                HookBindableEvent(obj)
                remoteCount = remoteCount + 1
            elseif obj:IsA("BindableFunction") then
                HookBindableFunction(obj)
                remoteCount = remoteCount + 1
            end
        end
    end
    
    -- Scan ReplicatedStorage first
    scanDescendants(ReplicatedStorage)
    
    -- Scan all other services
    for _, service in pairs(game:GetChildren()) do
        if service ~= ReplicatedStorage then
            pcall(function()
                scanDescendants(service)
            end)
        end
    end
    
    print(string.format("[Network Monitor] Hooked %d remotes and bindables", remoteCount))
    
    -- Update status
    if UI and UI.StatusIndicator and UI.StatusLabel then
        UI.StatusIndicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        UI.StatusLabel.Text = "Running"
    end
end

-- Hook new remotes
local function SetupDescendantAddedHook()
    game.DescendantAdded:Connect(function(obj)
        if obj:IsA("RemoteEvent") then
            HookRemoteEvent(obj)
        elseif obj:IsA("RemoteFunction") then
            HookRemoteFunction(obj)
        elseif obj:IsA("BindableEvent") then
            HookBindableEvent(obj)
        elseif obj:IsA("BindableFunction") then
            HookBindableFunction(obj)
        end
    end)
end

-- Function to export logs to formatted string
local function ExportLogsToString()
    local output = {}
    
    table.insert(output, "=" .. string.rep("=", 50))
    table.insert(output, "ROBLOX NETWORK MONITOR REPORT")
    table.insert(output, "=" .. string.rep("=", 50))
    table.insert(output, string.format("Generated: %s", os.date("%Y-%m-%d %H:%M:%S")))
    table.insert(output, string.format("Player: %s", NetworkLogs.Player))
    table.insert(output, string.format("Session Start: %s", os.date("%Y-%m-%d %H:%M:%S", NetworkLogs.StartTime)))
    table.insert(output, "")
    
    -- Export RemoteEvents
    table.insert(output, "-" .. string.rep("-", 50))
    table.insert(output, "REMOTE EVENTS")
    table.insert(output, "-" .. string.rep("-", 50))
    
    for remoteName, logs in pairs(NetworkLogs.RemoteEvents) do
        if #logs > 0 then
            table.insert(output, string.format("\n[%s] - Total Calls: %d", remoteName, #logs))
            for i, log in ipairs(logs) do
                table.insert(output, string.format("  Call #%d:", i))
                table.insert(output, string.format("    Time: %s", os.date("%H:%M:%S", log.Time)))
                table.insert(output, string.format("    Direction: %s", log.Direction))
                table.insert(output, string.format("    Arguments: %d", #log.Arguments))
                for j, arg in ipairs(log.Arguments) do
                    table.insert(output, string.format("      Arg[%d]: %s", j, arg))
                end
            end
        end
    end
    
    -- Export RemoteFunctions
    table.insert(output, "\n" .. "-" .. string.rep("-", 50))
    table.insert(output, "REMOTE FUNCTIONS")
    table.insert(output, "-" .. string.rep("-", 50))
    
    for remoteName, logs in pairs(NetworkLogs.RemoteFunctions) do
        if #logs > 0 then
            table.insert(output, string.format("\n[%s] - Total Calls: %d", remoteName, #logs))
            for i, log in ipairs(logs) do
                table.insert(output, string.format("  Call #%d:", i))
                table.insert(output, string.format("    Time: %s", os.date("%H:%M:%S", log.Time)))
                table.insert(output, string.format("    Direction: %s", log.Direction))
                table.insert(output, string.format("    Arguments: %d", #log.Arguments))
                for j, arg in ipairs(log.Arguments) do
                    table.insert(output, string.format("      Arg[%d]: %s", j, arg))
                end
            end
        end
    end
    
    -- Export BindableEvents
    table.insert(output, "\n" .. "-" .. string.rep("-", 50))
    table.insert(output, "BINDABLE EVENTS")
    table.insert(output, "-" .. string.rep("-", 50))
    
    for bindableName, logs in pairs(NetworkLogs.BindableEvents) do
        if #logs > 0 then
            table.insert(output, string.format("\n[%s] - Total Calls: %d", bindableName, #logs))
            for i, log in ipairs(logs) do
                table.insert(output, string.format("  Call #%d:", i))
                table.insert(output, string.format("    Time: %s", os.date("%H:%M:%S", log.Time)))
                table.insert(output, string.format("    Direction: %s", log.Direction))
                table.insert(output, string.format("    Arguments: %d", #log.Arguments))
                for j, arg in ipairs(log.Arguments) do
                    table.insert(output, string.format("      Arg[%d]: %s", j, arg))
                end
            end
        end
    end
    
    -- Export BindableFunctions
    table.insert(output, "\n" .. "-" .. string.rep("-", 50))
    table.insert(output, "BINDABLE FUNCTIONS")
    table.insert(output, "-" .. string.rep("-", 50))
    
    for bindableName, logs in pairs(NetworkLogs.BindableFunctions) do
        if #logs > 0 then
            table.insert(output, string.format("\n[%s] - Total Calls: %d", bindableName, #logs))
            for i, log in ipairs(logs) do
                table.insert(output, string.format("  Call #%d:", i))
                table.insert(output, string.format("    Time: %s", os.date("%H:%M:%S", log.Time)))
                table.insert(output, string.format("    Direction: %s", log.Direction))
                table.insert(output, string.format("    Arguments: %d", #log.Arguments))
                for j, arg in ipairs(log.Arguments) do
                    table.insert(output, string.format("      Arg[%d]: %s", j, arg))
                end
            end
        end
    end
    
    -- Summary Statistics
    table.insert(output, "\n" .. "=" .. string.rep("=", 50))
    table.insert(output, "SUMMARY STATISTICS")
    table.insert(output, "=" .. string.rep("=", 50))
    
    local totalRemoteEvents = 0
    local totalRemoteFunctions = 0
    local totalBindableEvents = 0
    local totalBindableFunctions = 0
    
    for _, logs in pairs(NetworkLogs.RemoteEvents) do
        totalRemoteEvents = totalRemoteEvents + #logs
    end
    
    for _, logs in pairs(NetworkLogs.RemoteFunctions) do
        totalRemoteFunctions = totalRemoteFunctions + #logs
    end
    
    for _, logs in pairs(NetworkLogs.BindableEvents) do
        totalBindableEvents = totalBindableEvents + #logs
    end
    
    for _, logs in pairs(NetworkLogs.BindableFunctions) do
        totalBindableFunctions = totalBindableFunctions + #lsogs
    end
    
    table.insert(output, string.format("Total RemoteEvent Calls: %d", totalRemoteEvents))
    table.insert(output, string.format("Total RemoteFunction Calls: %d", totalRemoteFunctions))
    table.insert(output, string.format("Total BindableEvent Calls: %d", totalBindableEvents))
    table.insert(output, string.format("Total BindableFunction Calls: %d", totalBindableFunctions))
    table.insert(output, string.format("Unique RemoteEvents: %d", #NetworkLogs.RemoteEvents))
    table.insert(output, string.format("Unique RemoteFunctions: %d", #NetworkLogs.RemoteFunctions))
    table.insert(output, string.format("Unique BindableEvents: %d", #NetworkLogs.BindableEvents))
    table.insert(output, string.format("Unique BindableFunctions: %d", #NetworkLogs.BindableFunctions))
    
    return table.concat(output, "\n")
end

-- Function to save logs
local function SaveLogs()
    local logString = ExportLogsToString()
    
    -- Update UI Logs tab
    if UI and UI.LogsTextBox then
        UI.LogsTextBox.Text = logString
        
        -- Update canvas size for text
        local textSize = TextService:GetTextSize(
            logString, 
            UI.LogsTextBox.TextSize, 
            UI.LogsTextBox.Font, 
            Vector2.new(UI.LogsTextBox.AbsoluteSize.X, 10000)
        )
        UI.LogsContent.CanvasSize = UDim2.new(0, 0, 0, textSize.Y + 20)
    end
    
    print("\n" .. "=" .. string.rep("=", 50))
    print("NETWORK LOGS (Copy this to save as .txt file):")
    print("=" .. string.rep("=", 50))
    print(logString)
    print("=" .. string.rep("=", 50))
    
    -- Also save to _G for easy access
    _G.NetworkMonitorLogs = logString
    print("\nLogs also saved to _G.NetworkMonitorLogs")
end

-- Create UI
local UI = CreateUI()

-- Button connections
if UI then
    UI.ClearLogsBtn.MouseButton1Click:Connect(function()
        NetworkLogs.RemoteEvents = {}
        NetworkLogs.RemoteFunctions = {}
        NetworkLogs.BindableEvents = {}
        NetworkLogs.BindableFunctions = {}
        
        -- Clear UI monitor content
        for _, child in pairs(UI.MonitorContent:GetChildren()) do
            if not child:IsA("UIListLayout") then
                child:Destroy()
            end
        end
        
        -- Clear logs text
        UI.LogsTextBox.Text = "Logs cleared..."
        
        -- Clear detail view
        SelectedLog = nil
        UpdateDetailView()
        
        print("[Network Monitor] All logs cleared")
    end)
    
    UI.ExportBtn.MouseButton1Click:Connect(function()
        SaveLogs()
    end)
end

-- Auto-save periodically
spawn(function()
    while true do
        wait(MONITOR_CONFIG.SaveInterval)
        SaveLogs()
        UpdateStats()
    end
end)

-- Update stats every second
spawn(function()
    while true do
        wait(1)
        UpdateStats()
    end
end)

-- Commands
_G.NetworkMonitor = {
    Start = function()
        print("[Network Monitor] Starting scan...")
        ScanForRemotes()
        SetupDescendantAddedHook()
        print("[Network Monitor] Scan complete! Monitoring active.")
    end,
    
    Stop = function()
        MONITOR_CONFIG.LogRemoteEvents = false
        MONITOR_CONFIG.LogRemoteFunctions = false
        MONITOR_CONFIG.LogBindableEvents = false
        MONITOR_CONFIG.LogBindableFunctions = false
        
        if UI and UI.StatusIndicator and UI.StatusLabel then
            UI.StatusIndicator.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            UI.StatusLabel.Text = "Stopped"
        end
        
        print("[Network Monitor] Monitoring stopped.")
    end,
    
    Clear = function()
        NetworkLogs.RemoteEvents = {}
        NetworkLogs.RemoteFunctions = {}
        NetworkLogs.BindableEvents = {}
        NetworkLogs.BindableFunctions = {}
        
        if UI then
            for _, child in pairs(UI.MonitorContent:GetChildren()) do
                if not child:IsA("UIListLayout") then
                    child:Destroy()
                end
            end
        end
        
        SelectedLog = nil
        UpdateDetailView()
        
        print("[Network Monitor] Logs cleared.")
    end,
    
    Export = function()
        SaveLogs()
    end,
    
    GetStats = function()
        local totalRemoteEvents = 0
        local totalRemoteFunctions = 0
        local totalBindableEvents = 0
        local totalBindableFunctions = 0
        
        for _, logs in pairs(NetworkLogs.RemoteEvents) do
            totalRemoteEvents = totalRemoteEvents + #logs
        end
        
        for _, logs in pairs(NetworkLogs.RemoteFunctions) do
            totalRemoteFunctions = totalRemoteFunctions + #logs
        end
        
        for _, logs in pairs(NetworkLogs.BindableEvents) do
            totalBindableEvents = totalBindableEvents + #logs
        end
        
        for _, logs in pairs(NetworkLogs.BindableFunctions) do
            totalBindableFunctions = totalBindableFunctions + #logs
        end
        
        print(string.format("[Network Monitor] Stats - RemoteEvents: %d, RemoteFunctions: %d, BindableEvents: %d, BindableFunctions: %d", 
            totalRemoteEvents, totalRemoteFunctions, totalBindableEvents, totalBindableFunctions))
    end,
    
    ShowUI = function()
        if not MONITOR_CONFIG.UIVisible then
            UI = CreateUI()
            MONITOR_CONFIG.UIVisible = true
            print("[Network Monitor] UI reopened")
        end
    end,
    
    HideUI = function()
        if UI and UI.UI then
            UI.UI.Enabled = false
        end
    end,
    
    ShowDetail = function(logIndex, logType)
        -- This function would need to be implemented based on how you want to access logs
        print("[Network Monitor] ShowDetail function not fully implemented yet")
    end
}

-- Auto-start if configured
if MONITOR_CONFIG.AutoStart then
    _G.NetworkMonitor.Start()
end

-- Toggle key (F10)
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.F10 then
        if UI and UI.UI and UI.UI.Parent then
            UI.UI.Enabled = not UI.UI.Enabled
        else
            UI = CreateUI()
        end
    end
end)

print([[
========================================
Enhanced Network Monitor with UI Loaded!
========================================
The UI should be visible on your screen.
You can drag it, minimize it, or close it.

Commands:
  _G.NetworkMonitor.Start()   - Start monitoring
  _G.NetworkMonitor.Stop()    - Stop monitoring
  _G.NetworkMonitor.Clear()   - Clear logs
  _G.NetworkMonitor.Export()  - Export logs
  _G.NetworkMonitor.ShowUI()  - Show UI if closed
  _G.NetworkMonitor.HideUI()  - Hide UI
  _G.NetworkMonitor.GetStats() - Get statistics

Features:
- Real-time network monitoring (RemoteEvents, RemoteFunctions, BindableEvents, BindableFunctions)
- Interactive UI with tabs including new Detail tab
- Click on any log entry to view detailed information
- Copy detailed information to clipboard
- Export logs to console/file
- Statistics tracking
- Settings configuration

Press F10 to toggle UI visibility.
Logs auto-save every 30 seconds.
========================================
]])