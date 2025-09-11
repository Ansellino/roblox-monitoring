-- ROBLOX NETWORK SPY REMOTE - ENHANCED VERSION
-- Monitor semua aktivitas network dengan detail lengkap dan fitur tambahan

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Storage untuk data network
local NetworkData = {}
local ConnectionList = {}
local IsMonitoring = false
local MaxLogEntries = 1000
local SelectedLogIndex = 0
local SearchFilter = ""
local TypeFilter = "All"
local DirectionFilter = "All"
local LogHistory = {}
local HistoryIndex = 0

-- Theme colors
local Theme = {
    Background = Color3.fromRGB(30, 30, 30),
    Secondary = Color3.fromRGB(40, 40, 40),
    Item = Color3.fromRGB(35, 35, 35),
    ItemHover = Color3.fromRGB(45, 45, 45),
    Text = Color3.fromRGB(255, 255, 255),
    SubText = Color3.fromRGB(200, 200, 200),
    Accent = Color3.fromRGB(0, 162, 255),
    Success = Color3.fromRGB(60, 200, 60),
    Warning = Color3.fromRGB(255, 165, 0),
    Error = Color3.fromRGB(255, 60, 60),
    RemoteEvent = Color3.fromRGB(100, 200, 255),
    RemoteFunction = Color3.fromRGB(255, 200, 100),
    BindableEvent = Color3.fromRGB(200, 255, 100),
    BindableFunction = Color3.fromRGB(200, 100, 255)
}

-- Fungsi untuk mendapatkan timestamp
local function GetTimeStamp()
    return os.date("%H:%M:%S", os.time())
end

-- Fungsi untuk mendapatkan timestamp lengkap
local function GetFullTimeStamp()
    return os.date("%Y-%m-%d %H:%M:%S", os.time())
end

-- Fungsi untuk deep copy table
local function DeepCopy(original)
    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = DeepCopy(value)
        else
            if type(value) == "userdata" then
                copy[key] = tostring(value)
            else
                copy[key] = value
            end
        end
    end
    return copy
end

-- Fungsi untuk format arguments
local function FormatArgs(args, depth, maxDepth)
    depth = depth or 1
    maxDepth = maxDepth or 3
    
    if depth > maxDepth then
        return "[Max Depth Reached]"
    end
    
    local formatted = {}
    for i, arg in ipairs(args) do
        if type(arg) == "table" then
            formatted[i] = "Table: " .. tostring(#arg) .. " items"
            -- Add table content for shallow tables
            if depth < maxDepth and #arg > 0 and #arg <= 10 then
                formatted[i] = formatted[i] .. " {"
                for k, v in pairs(arg) do
                    if type(v) == "table" then
                        formatted[i] = formatted[i] .. tostring(k) .. " = [Table], "
                    else
                        formatted[i] = formatted[i] .. tostring(k) .. " = " .. tostring(v) .. ", "
                    end
                end
                formatted[i] = formatted[i]:sub(1, -3) .. "}"
            end
        elseif type(arg) == "userdata" then
            formatted[i] = tostring(arg)
        elseif type(arg) == "string" then
            if #arg > 100 then
                formatted[i] = "\"" .. arg:sub(1, 100) .. "...\""
            else
                formatted[i] = "\"" .. arg .. "\""
            end
        else
            formatted[i] = tostring(arg)
        end
    end
    return formatted
end

-- Fungsi untuk memeriksa apakah teks mengandung filter
local function MatchesFilter(data, filter, typeFilter, directionFilter)
    if filter == "" and typeFilter == "All" and directionFilter == "All" then
        return true
    end
    
    local filterMatch = filter == "" or 
        string.find(data.Name:lower(), filter:lower()) or
        string.find(data.FullName:lower(), filter:lower()) or
        string.find(data.Type:lower(), filter:lower()) or
        string.find(data.Direction:lower(), filter:lower())
    
    local typeMatch = typeFilter == "All" or data.Type == typeFilter
    local directionMatch = directionFilter == "All" or data.Direction == directionFilter
    
    return filterMatch and typeMatch and directionMatch
end

-- Network Spy Class
local NetworkSpy = {}
NetworkSpy.__index = NetworkSpy

function NetworkSpy.new()
    local self = setmetatable({}, NetworkSpy)
    self.GUI = nil
    self.LogFrame = nil
    self.DetailFrame = nil
    self.CurrentPage = 1
    self.ItemsPerPage = 20
    self.FilterType = "All"
    self.FilterDirection = "All"
    self.SearchText = ""
    return self
end

-- Membuat GUI Interface
function NetworkSpy:CreateGUI()
    -- Destroy existing GUI if it exists
    if self.GUI then
        self.GUI:Destroy()
    end
    
    -- Main ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NetworkSpyGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Try CoreGui first, then PlayerGui as fallback
    local success = pcall(function()
        screenGui.Parent = CoreGui
    end)
    
    if not success or not screenGui.Parent then
        pcall(function()
            screenGui.Parent = PlayerGui
        end)
    end
    
    -- If still no parent, create in workspace as last resort
    if not screenGui.Parent then
        local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            screenGui.Parent = playerGui
            print("📍 GUI dibuat di PlayerGui")
        else
            warn("Could not find suitable parent for GUI")
            return
        end
    else
        print("📍 GUI dibuat di " .. screenGui.Parent.Name)
    end
    
    -- Send notification
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Network Spy Remote",
            Text = "GUI berhasil dimuat! Tekan F10 untuk toggle.",
            Duration = 5
        })
    end)
    
    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 900, 0, 650)
    mainFrame.Position = UDim2.new(0.5, -450, 0.5, -325)
    mainFrame.BackgroundColor3 = Theme.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui
    
    -- Corner untuk rounded
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    -- Drop Shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 10, 1, 10)
    shadow.Position = UDim2.new(0, -5, 0, -5)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.8
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.ZIndex = -1
    shadow.Parent = mainFrame
    
    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -100, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🔍 Network Spy Remote - Advanced Activity Monitor"
    titleLabel.TextColor3 = Theme.Text
    titleLabel.TextSize = 16
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = titleBar
    
    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundColor3 = Theme.Error
    closeBtn.Text = "×"
    closeBtn.TextSize = 18
    closeBtn.TextColor3 = Theme.Text
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = titleBar
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 4)
    closeBtnCorner.Parent = closeBtn
    
    -- Minimize Button
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
    minimizeBtn.Position = UDim2.new(1, -70, 0, 5)
    minimizeBtn.BackgroundColor3 = Theme.Warning
    minimizeBtn.Text = "−"
    minimizeBtn.TextSize = 18
    minimizeBtn.TextColor3 = Theme.Text
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.BorderSizePixel = 0
    minimizeBtn.Parent = titleBar
    
    local minimizeBtnCorner = Instance.new("UICorner")
    minimizeBtnCorner.CornerRadius = UDim.new(0, 4)
    minimizeBtnCorner.Parent = minimizeBtn
    
    -- Control Panel
    local controlPanel = Instance.new("Frame")
    controlPanel.Name = "ControlPanel"
    controlPanel.Size = UDim2.new(1, -20, 0, 50)
    controlPanel.Position = UDim2.new(0, 10, 0, 50)
    controlPanel.BackgroundColor3 = Theme.Secondary
    controlPanel.BorderSizePixel = 0
    controlPanel.Parent = mainFrame
    
    local controlCorner = Instance.new("UICorner")
    controlCorner.CornerRadius = UDim.new(0, 6)
    controlCorner.Parent = controlPanel
    
    -- Start/Stop Button
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "ToggleBtn"
    toggleBtn.Size = UDim2.new(0, 100, 0, 30)
    toggleBtn.Position = UDim2.new(0, 10, 0, 10)
    toggleBtn.BackgroundColor3 = Theme.Success
    toggleBtn.Text = "▶ START"
    toggleBtn.TextSize = 12
    toggleBtn.TextColor3 = Theme.Text
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = controlPanel
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 4)
    toggleCorner.Parent = toggleBtn
    
    -- Clear Button
    local clearBtn = Instance.new("TextButton")
    clearBtn.Size = UDim2.new(0, 80, 0, 30)
    clearBtn.Position = UDim2.new(0, 120, 0, 10)
    clearBtn.BackgroundColor3 = Theme.Warning
    clearBtn.Text = "🗑 CLEAR"
    clearBtn.TextSize = 11
    clearBtn.TextColor3 = Theme.Text
    clearBtn.Font = Enum.Font.GothamBold
    clearBtn.BorderSizePixel = 0
    clearBtn.Parent = controlPanel
    
    local clearCorner = Instance.new("UICorner")
    clearCorner.CornerRadius = UDim.new(0, 4)
    clearCorner.Parent = clearBtn
    
    -- Save Button
    local saveBtn = Instance.new("TextButton")
    saveBtn.Size = UDim2.new(0, 80, 0, 30)
    saveBtn.Position = UDim2.new(0, 210, 0, 10)
    saveBtn.BackgroundColor3 = Theme.Accent
    saveBtn.Text = "💾 SAVE"
    saveBtn.TextSize = 11
    saveBtn.TextColor3 = Theme.Text
    saveBtn.Font = Enum.Font.GothamBold
    saveBtn.BorderSizePixel = 0
    saveBtn.Parent = controlPanel
    
    local saveCorner = Instance.new("UICorner")
    saveCorner.CornerRadius = UDim.new(0, 4)
    saveCorner.Parent = saveBtn
    
    -- Search Box
    local searchBox = Instance.new("TextBox")
    searchBox.Name = "SearchBox"
    searchBox.Size = UDim2.new(0, 150, 0, 30)
    searchBox.Position = UDim2.new(0, 300, 0, 10)
    searchBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    searchBox.TextColor3 = Theme.Text
    searchBox.Text = ""
    searchBox.PlaceholderText = "Search..."
    searchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    searchBox.TextSize = 12
    searchBox.Font = Enum.Font.Gotham
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = controlPanel
    
    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 4)
    searchCorner.Parent = searchBox
    
    -- Filter Dropdown (Type)
    local filterTypeBtn = Instance.new("TextButton")
    filterTypeBtn.Name = "FilterTypeBtn"
    filterTypeBtn.Size = UDim2.new(0, 120, 0, 30)
    filterTypeBtn.Position = UDim2.new(0, 460, 0, 10)
    filterTypeBtn.BackgroundColor3 = Theme.Accent
    filterTypeBtn.Text = "Type: All ▼"
    filterTypeBtn.TextSize = 11
    filterTypeBtn.TextColor3 = Theme.Text
    filterTypeBtn.Font = Enum.Font.GothamBold
    filterTypeBtn.BorderSizePixel = 0
    filterTypeBtn.Parent = controlPanel
    
    local filterTypeCorner = Instance.new("UICorner")
    filterTypeCorner.CornerRadius = UDim.new(0, 4)
    filterTypeCorner.Parent = filterTypeBtn
    
    -- Filter Dropdown (Direction)
    local filterDirBtn = Instance.new("TextButton")
    filterDirBtn.Name = "FilterDirBtn"
    filterDirBtn.Size = UDim2.new(0, 120, 0, 30)
    filterDirBtn.Position = UDim2.new(0, 590, 0, 10)
    filterDirBtn.BackgroundColor3 = Theme.Accent
    filterDirBtn.Text = "Direction: All ▼"
    filterDirBtn.TextSize = 11
    filterDirBtn.TextColor3 = Theme.Text
    filterDirBtn.Font = Enum.Font.GothamBold
    filterDirBtn.BorderSizePixel = 0
    filterDirBtn.Parent = controlPanel
    
    local filterDirCorner = Instance.new("UICorner")
    filterDirCorner.CornerRadius = UDim.new(0, 4)
    filterDirCorner.Parent = filterDirBtn
    
    -- Status Label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(0, 200, 0, 30)
    statusLabel.Position = UDim2.new(1, -210, 0, 10)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: Stopped | Logs: 0"
    statusLabel.TextColor3 = Theme.SubText
    statusLabel.TextSize = 11
    statusLabel.TextXAlignment = Enum.TextXAlignment.Right
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.Parent = controlPanel
    
    -- Main Content Frame
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -20, 1, -120)
    contentFrame.Position = UDim2.new(0, 10, 0, 110)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame
    
    -- Log Frame (Left Side)
    local logFrame = Instance.new("ScrollingFrame")
    logFrame.Name = "LogFrame"
    logFrame.Size = UDim2.new(0.6, -10, 1, 0)
    logFrame.Position = UDim2.new(0, 0, 0, 0)
    logFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    logFrame.BorderSizePixel = 0
    logFrame.ScrollBarThickness = 8
    logFrame.ScrollBarImageColor3 = Theme.Accent
    logFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    logFrame.Parent = contentFrame
    
    local logCorner = Instance.new("UICorner")
    logCorner.CornerRadius = UDim.new(0, 6)
    logCorner.Parent = logFrame
    
    -- Detail Frame (Right Side)
    local detailFrame = Instance.new("ScrollingFrame")
    detailFrame.Name = "DetailFrame"
    detailFrame.Size = UDim2.new(0.4, -10, 1, 0)
    detailFrame.Position = UDim2.new(0.6, 10, 0, 0)
    detailFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    detailFrame.BorderSizePixel = 0
    detailFrame.ScrollBarThickness = 8
    detailFrame.ScrollBarImageColor3 = Theme.Accent
    detailFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    detailFrame.Parent = contentFrame
    
    local detailCorner = Instance.new("UICorner")
    detailCorner.CornerRadius = UDim.new(0, 6)
    detailCorner.Parent = detailFrame
    
    -- Detail Title
    local detailTitle = Instance.new("TextLabel")
    detailTitle.Size = UDim2.new(1, -20, 0, 30)
    detailTitle.Position = UDim2.new(0, 10, 0, 5)
    detailTitle.BackgroundTransparency = 1
    detailTitle.Text = "📋 Activity Details"
    detailTitle.TextColor3 = Theme.SubText
    detailTitle.TextSize = 14
    detailTitle.TextXAlignment = Enum.TextXAlignment.Left
    detailTitle.Font = Enum.Font.GothamBold
    detailTitle.Parent = detailFrame
    
    -- Copy Button
    local copyBtn = Instance.new("TextButton")
    copyBtn.Size = UDim2.new(0, 80, 0, 25)
    copyBtn.Position = UDim2.new(1, -90, 0, 5)
    copyBtn.BackgroundColor3 = Theme.Accent
    copyBtn.Text = "📋 Copy"
    copyBtn.TextSize = 11
    copyBtn.TextColor3 = Theme.Text
    copyBtn.Font = Enum.Font.GothamBold
    copyBtn.BorderSizePixel = 0
    copyBtn.Parent = detailFrame
    
    local copyCorner = Instance.new("UICorner")
    copyCorner.CornerRadius = UDim.new(0, 4)
    copyCorner.Parent = copyBtn
    
    -- Layout untuk log frame
    local logLayout = Instance.new("UIListLayout")
    logLayout.SortOrder = Enum.SortOrder.LayoutOrder
    logLayout.Padding = UDim.new(0, 2)
    logLayout.Parent = logFrame
    
    -- Layout untuk detail frame
    local detailLayout = Instance.new("UIListLayout")
    detailLayout.SortOrder = Enum.SortOrder.LayoutOrder
    detailLayout.Padding = UDim.new(0, 5)
    detailLayout.Parent = detailFrame
    
    -- Filter Dropdown Menu (Type)
    local filterTypeMenu = Instance.new("Frame")
    filterTypeMenu.Name = "FilterTypeMenu"
    filterTypeMenu.Size = UDim2.new(0, 120, 0, 150)
    filterTypeMenu.Position = UDim2.new(0, 460, 0, 45)
    filterTypeMenu.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    filterTypeMenu.BorderSizePixel = 0
    filterTypeMenu.Visible = false
    filterTypeMenu.ZIndex = 10
    filterTypeMenu.Parent = controlPanel
    
    local filterTypeMenuCorner = Instance.new("UICorner")
    filterTypeMenuCorner.CornerRadius = UDim.new(0, 4)
    filterTypeMenuCorner.Parent = filterTypeMenu
    
    local filterTypeLayout = Instance.new("UIListLayout")
    filterTypeLayout.Parent = filterTypeMenu
    
    local typeFilters = {"All", "RemoteEvent", "RemoteFunction", "BindableEvent", "BindableFunction"}
    for _, filter in ipairs(typeFilters) do
        local filterBtn = Instance.new("TextButton")
        filterBtn.Size = UDim2.new(1, 0, 0, 30)
        filterBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        filterBtn.BorderSizePixel = 0
        filterBtn.Text = filter
        filterBtn.TextColor3 = Theme.Text
        filterBtn.TextSize = 11
        filterBtn.Font = Enum.Font.Gotham
        filterBtn.Parent = filterTypeMenu
        
        filterBtn.MouseButton1Click:Connect(function()
            TypeFilter = filter
            filterTypeBtn.Text = "Type: " .. filter .. " ▼"
            filterTypeMenu.Visible = false
            self:UpdateLogDisplay()
        end)
    end
    
    -- Filter Dropdown Menu (Direction)
    local filterDirMenu = Instance.new("Frame")
    filterDirMenu.Name = "FilterDirMenu"
    filterDirMenu.Size = UDim2.new(0, 120, 0, 100)
    filterDirMenu.Position = UDim2.new(0, 590, 0, 45)
    filterDirMenu.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    filterDirMenu.BorderSizePixel = 0
    filterDirMenu.Visible = false
    filterDirMenu.ZIndex = 10
    filterDirMenu.Parent = controlPanel
    
    local filterDirMenuCorner = Instance.new("UICorner")
    filterDirMenuCorner.CornerRadius = UDim.new(0, 4)
    filterDirMenuCorner.Parent = filterDirMenu
    
    local filterDirLayout = Instance.new("UIListLayout")
    filterDirLayout.Parent = filterDirMenu
    
    local dirFilters = {"All", "Incoming", "Outgoing"}
    for _, filter in ipairs(dirFilters) do
        local filterBtn = Instance.new("TextButton")
        filterBtn.Size = UDim2.new(1, 0, 0, 30)
        filterBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        filterBtn.BorderSizePixel = 0
        filterBtn.Text = filter
        filterBtn.TextColor3 = Theme.Text
        filterBtn.TextSize = 11
        filterBtn.Font = Enum.Font.Gotham
        filterBtn.Parent = filterDirMenu
        
        filterBtn.MouseButton1Click:Connect(function()
            DirectionFilter = filter
            filterDirBtn.Text = "Direction: " .. filter .. " ▼"
            filterDirMenu.Visible = false
            self:UpdateLogDisplay()
        end)
    end
    
    self.GUI = screenGui
    self.LogFrame = logFrame
    self.DetailFrame = detailFrame
    
    -- Debug: Check if GUI is visible
    print("🔧 GUI Created, Parent:", screenGui.Parent and screenGui.Parent.Name or "None")
    print("🔧 MainFrame visible:", mainFrame.Visible)
    
    -- Force visibility
    mainFrame.Visible = true
    screenGui.Enabled = true
    
    -- Event Handlers
    closeBtn.MouseButton1Click:Connect(function()
        self:ToggleGUI()
    end)
    
    minimizeBtn.MouseButton1Click:Connect(function()
        self:MinimizeGUI()
    end)
    
    toggleBtn.MouseButton1Click:Connect(function()
        self:ToggleMonitoring()
    end)
    
    clearBtn.MouseButton1Click:Connect(function()
        self:ClearLogs()
    end)
    
    saveBtn.MouseButton1Click:Connect(function()
        self:SaveLogs()
    end)
    
    copyBtn.MouseButton1Click:Connect(function()
        self:CopyDetails()
    end)
    
    filterTypeBtn.MouseButton1Click:Connect(function()
        filterTypeMenu.Visible = not filterTypeMenu.Visible
        filterDirMenu.Visible = false
    end)
    
    filterDirBtn.MouseButton1Click:Connect(function()
        filterDirMenu.Visible = not filterDirMenu.Visible
        filterTypeMenu.Visible = false
    end)
    
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        SearchFilter = searchBox.Text
        self:UpdateLogDisplay()
    end)
    
    -- Close dropdowns when clicking elsewhere
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if filterTypeMenu.Visible then
                filterTypeMenu.Visible = false
            end
            if filterDirMenu.Visible then
                filterDirMenu.Visible = false
            end
        end
    end)
    
    return screenGui
end

-- Toggle GUI visibility
function NetworkSpy:ToggleGUI()
    if self.GUI then
        self.GUI:Destroy()
        self.GUI = nil
        print("🔍 Network Spy GUI ditutup")
    else
        local gui = self:CreateGUI()
        if gui and gui.Parent then
            print("🔍 Network Spy GUI berhasil dimuat di " .. gui.Parent.Name)
            self:UpdateLogDisplay()
            self:UpdateStatus()
        else
            warn("❌ Gagal membuat Network Spy GUI")
        end
    end
end

-- Minimize GUI
function NetworkSpy:MinimizeGUI()
    if not self.GUI then return end
    
    local mainFrame = self.GUI.MainFrame
    local contentFrame = mainFrame.ContentFrame
    local isMinimized = contentFrame.Visible
    
    if isMinimized then
        -- Restore
        contentFrame.Visible = true
        mainFrame.Size = UDim2.new(0, 900, 0, 650)
        self.GUI.MainFrame.TitleBar.MinimizeButton.Text = "−"
    else
        -- Minimize
        contentFrame.Visible = false
        mainFrame.Size = UDim2.new(0, 900, 0, 100)
        self.GUI.MainFrame.TitleBar.MinimizeButton.Text = "+"
    end
end

-- Toggle monitoring
function NetworkSpy:ToggleMonitoring()
    if IsMonitoring then
        self:StopMonitoring()
    else
        self:StartMonitoring()
    end
end

-- Start monitoring
function NetworkSpy:StartMonitoring()
    if IsMonitoring then return end
    
    IsMonitoring = true
    print("🔍 Network Spy Started - Monitoring all network activity...")
    
    -- Update button text
    if self.GUI then
        local toggleBtn = self.GUI.MainFrame.ControlPanel.ToggleBtn
        toggleBtn.Text = "⏹ STOP"
        toggleBtn.BackgroundColor3 = Theme.Error
    end
    
    -- Hook RemoteEvents
    self:HookRemoteEvents()
    
    -- Hook RemoteFunctions
    self:HookRemoteFunctions()
    
    -- Hook BindableEvents
    self:HookBindableEvents()
    
    -- Hook BindableFunctions
    self:HookBindableFunctions()
    
    -- Monitor existing remotes
    self:MonitorExistingRemotes()
    
    self:UpdateStatus()
end

-- Stop monitoring
function NetworkSpy:StopMonitoring()
    if not IsMonitoring then return end
    
    IsMonitoring = false
    print("⏹ Network Spy Stopped")
    
    -- Update button text
    if self.GUI then
        local toggleBtn = self.GUI.MainFrame.ControlPanel.ToggleBtn
        toggleBtn.Text = "▶ START"
        toggleBtn.BackgroundColor3 = Theme.Success
    end
    
    -- Disconnect all connections
    for _, connection in ipairs(ConnectionList) do
        if connection and connection.Disconnect then
            connection:Disconnect()
        end
    end
    ConnectionList = {}
    
    self:UpdateStatus()
end

-- Hook RemoteEvents
function NetworkSpy:HookRemoteEvents()
    -- Monitor existing RemoteEvents
    for _, child in ipairs(ReplicatedStorage:GetDescendants()) do
        if child:IsA("RemoteEvent") then
            self:HookRemoteEvent(child)
        end
    end
    
    -- Monitor new RemoteEvents
    local connection = ReplicatedStorage.DescendantAdded:Connect(function(child)
        if child:IsA("RemoteEvent") then
            self:HookRemoteEvent(child)
        end
    end)
    table.insert(ConnectionList, connection)
end

-- Hook individual RemoteEvent
function NetworkSpy:HookRemoteEvent(remote)
    if not remote or not remote.Parent then return end
    
    local connection = remote.OnClientEvent:Connect(function(...)
        if not IsMonitoring then return end
        
        local args = {...}
        local data = {
            Type = "RemoteEvent",
            Name = remote.Name,
            FullName = remote:GetFullName(),
            Direction = "Incoming",
            Arguments = FormatArgs(args),
            ArgumentCount = #args,
            TimeStamp = GetTimeStamp(),
            RawArgs = args,
            Remote = remote
        }
        
        self:LogNetworkActivity(data)
    end)
    
    table.insert(ConnectionList, connection)
    
    -- Hook outgoing FireServer calls
    local oldFireServer = remote.FireServer
    remote.FireServer = function(self, ...)
        if IsMonitoring then
            local args = {...}
            local data = {
                Type = "RemoteEvent",
                Name = remote.Name,
                FullName = remote:GetFullName(),
                Direction = "Outgoing",
                Arguments = FormatArgs(args),
                ArgumentCount = #args,
                TimeStamp = GetTimeStamp(),
                RawArgs = args,
                Remote = remote
            }
            
            self:LogNetworkActivity(data)
        end
        
        return oldFireServer(self, ...)
    end
end

-- Hook RemoteFunctions
function NetworkSpy:HookRemoteFunctions()
    -- Monitor existing RemoteFunctions
    for _, child in ipairs(ReplicatedStorage:GetDescendants()) do
        if child:IsA("RemoteFunction") then
            self:HookRemoteFunction(child)
        end
    end
    
    -- Monitor new RemoteFunctions
    local connection = ReplicatedStorage.DescendantAdded:Connect(function(child)
        if child:IsA("RemoteFunction") then
            self:HookRemoteFunction(child)
        end
    end)
    table.insert(ConnectionList, connection)
end

-- Hook individual RemoteFunction
function NetworkSpy:HookRemoteFunction(remote)
    if not remote or not remote.Parent then return end
    
    -- Store original function if exists
    local originalFunction = remote.OnClientInvoke
    
    remote.OnClientInvoke = function(...)
        if IsMonitoring then
            local args = {...}
            local data = {
                Type = "RemoteFunction",
                Name = remote.Name,
                FullName = remote:GetFullName(),
                Direction = "Incoming",
                Arguments = FormatArgs(args),
                ArgumentCount = #args,
                TimeStamp = GetTimeStamp(),
                RawArgs = args,
                Remote = remote
            }
            
            self:LogNetworkActivity(data)
        end
        
        -- Call original function if it exists
        if originalFunction then
            return originalFunction(...)
        end
    end
    
    -- Hook outgoing InvokeServer calls
    local oldInvokeServer = remote.InvokeServer
    remote.InvokeServer = function(self, ...)
        if IsMonitoring then
            local args = {...}
            local data = {
                Type = "RemoteFunction",
                Name = remote.Name,
                FullName = remote:GetFullName(),
                Direction = "Outgoing",
                Arguments = FormatArgs(args),
                ArgumentCount = #args,
                TimeStamp = GetTimeStamp(),
                RawArgs = args,
                Remote = remote
            }
            
            self:LogNetworkActivity(data)
        end
        
        return oldInvokeServer(self, ...)
    end
end

-- Hook BindableEvents
function NetworkSpy:HookBindableEvents()
    -- Monitor existing BindableEvents
    for _, child in ipairs(game:GetDescendants()) do
        if child:IsA("BindableEvent") and child.Parent and child.Parent ~= script then
            self:HookBindableEvent(child)
        end
    end
    
    -- Monitor new BindableEvents
    local connection = game.DescendantAdded:Connect(function(child)
        if child:IsA("BindableEvent") and child.Parent and child.Parent ~= script then
            self:HookBindableEvent(child)
        end
    end)
    table.insert(ConnectionList, connection)
end

-- Hook individual BindableEvent
function NetworkSpy:HookBindableEvent(bindable)
    if not bindable or not bindable.Parent then return end
    
    local connection = bindable.Event:Connect(function(...)
        if not IsMonitoring then return end
        
        local args = {...}
        local data = {
            Type = "BindableEvent",
            Name = bindable.Name,
            FullName = bindable:GetFullName(),
            Direction = "Incoming",
            Arguments = FormatArgs(args),
            ArgumentCount = #args,
            TimeStamp = GetTimeStamp(),
            RawArgs = args,
            Remote = bindable
        }
        
        self:LogNetworkActivity(data)
    end)
    
    table.insert(ConnectionList, connection)
    
    -- Hook outgoing Fire calls
    local oldFire = bindable.Fire
    bindable.Fire = function(self, ...)
        if IsMonitoring then
            local args = {...}
            local data = {
                Type = "BindableEvent",
                Name = bindable.Name,
                FullName = bindable:GetFullName(),
                Direction = "Outgoing",
                Arguments = FormatArgs(args),
                ArgumentCount = #args,
                TimeStamp = GetTimeStamp(),
                RawArgs = args,
                Remote = bindable
            }
            
            self:LogNetworkActivity(data)
        end
        
        return oldFire(self, ...)
    end
end

-- Hook BindableFunctions
function NetworkSpy:HookBindableFunctions()
    -- Monitor existing BindableFunctions
    for _, child in ipairs(game:GetDescendants()) do
        if child:IsA("BindableFunction") and child.Parent and child.Parent ~= script then
            self:HookBindableFunction(child)
        end
    end
    
    -- Monitor new BindableFunctions
    local connection = game.DescendantAdded:Connect(function(child)
        if child:IsA("BindableFunction") and child.Parent and child.Parent ~= script then
            self:HookBindableFunction(child)
        end
    end)
    table.insert(ConnectionList, connection)
end

-- Hook individual BindableFunction
function NetworkSpy:HookBindableFunction(bindable)
    if not bindable or not bindable.Parent then return end
    
    -- Store original function if exists
    local originalFunction = bindable.OnInvoke
    
    bindable.OnInvoke = function(...)
        if IsMonitoring then
            local args = {...}
            local data = {
                Type = "BindableFunction",
                Name = bindable.Name,
                FullName = bindable:GetFullName(),
                Direction = "Incoming",
                Arguments = FormatArgs(args),
                ArgumentCount = #args,
                TimeStamp = GetTimeStamp(),
                RawArgs = args,
                Remote = bindable
            }
            
            self:LogNetworkActivity(data)
        end
        
        -- Call original function if it exists
        if originalFunction then
            return originalFunction(...)
        end
    end
    
    -- Hook outgoing Invoke calls
    local oldInvoke = bindable.Invoke
    bindable.Invoke = function(self, ...)
        if IsMonitoring then
            local args = {...}
            local data = {
                Type = "BindableFunction",
                Name = bindable.Name,
                FullName = bindable:GetFullName(),
                Direction = "Outgoing",
                Arguments = FormatArgs(args),
                ArgumentCount = #args,
                TimeStamp = GetTimeStamp(),
                RawArgs = args,
                Remote = bindable
            }
            
            self:LogNetworkActivity(data)
        end
        
        return oldInvoke(self, ...)
    end
end

-- Monitor existing remotes for outgoing calls
function NetworkSpy:MonitorExistingRemotes()
    -- This would require hooking into the actual fire/invoke methods
    -- which is more complex and may require additional techniques
end

-- Log network activity
function NetworkSpy:LogNetworkActivity(data)
    table.insert(NetworkData, data)
    
    -- Limit log entries
    if #NetworkData > MaxLogEntries then
        table.remove(NetworkData, 1)
    end
    
    self:UpdateLogDisplay()
    self:UpdateStatus()
end

-- Update log display
function NetworkSpy:UpdateLogDisplay()
    if not self.GUI or not self.LogFrame then return end
    
    -- Clear existing entries
    for _, child in ipairs(self.LogFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Apply filters and add log entries
    local displayIndex = 1
    for i, data in ipairs(NetworkData) do
        if MatchesFilter(data, SearchFilter, TypeFilter, DirectionFilter) then
            local logEntry = self:CreateLogEntry(data, i, displayIndex)
            logEntry.Parent = self.LogFrame
            displayIndex = displayIndex + 1
        end
    end
    
    -- Update canvas size
    self.LogFrame.CanvasSize = UDim2.new(0, 0, 0, displayIndex * 52)
end

-- Create log entry
function NetworkSpy:CreateLogEntry(data, index, displayIndex)
    local entry = Instance.new("Frame")
    entry.Size = UDim2.new(1, -10, 0, 50)
    entry.BackgroundColor3 = Theme.Item
    entry.BorderSizePixel = 0
    entry.LayoutOrder = displayIndex
    entry.Name = "LogEntry_" .. index
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = entry
    
    -- Type indicator
    local typeColor = Theme.SubText
    if data.Type == "RemoteEvent" then
        typeColor = Theme.RemoteEvent
    elseif data.Type == "RemoteFunction" then
        typeColor = Theme.RemoteFunction
    elseif data.Type == "BindableEvent" then
        typeColor = Theme.BindableEvent
    elseif data.Type == "BindableFunction" then
        typeColor = Theme.BindableFunction
    end
    
    local typeLabel = Instance.new("TextLabel")
    typeLabel.Size = UDim2.new(0, 80, 1, 0)
    typeLabel.Position = UDim2.new(0, 5, 0, 0)
    typeLabel.BackgroundTransparency = 1
    typeLabel.Text = data.Type
    typeLabel.TextColor3 = typeColor
    typeLabel.TextSize = 10
    typeLabel.TextXAlignment = Enum.TextXAlignment.Left
    typeLabel.Font = Enum.Font.GothamBold
    typeLabel.Parent = entry
    
    -- Name label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0, 150, 0, 20)
    nameLabel.Position = UDim2.new(0, 90, 0, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = data.Name
    nameLabel.TextColor3 = Theme.Text
    nameLabel.TextSize = 12
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.Parent = entry
    
    -- Direction label
    local directionLabel = Instance.new("TextLabel")
    directionLabel.Size = UDim2.new(0, 80, 0, 15)
    directionLabel.Position = UDim2.new(0, 90, 0, 25)
    directionLabel.BackgroundTransparency = 1
    directionLabel.Text = data.Direction
    directionLabel.TextColor3 = Theme.SubText
    directionLabel.TextSize = 10
    directionLabel.TextXAlignment = Enum.TextXAlignment.Left
    directionLabel.Font = Enum.Font.Gotham
    directionLabel.Parent = entry
    
    -- Argument count
    local argLabel = Instance.new("TextLabel")
    argLabel.Size = UDim2.new(0, 100, 0, 15)
    argLabel.Position = UDim2.new(0, 250, 0, 5)
    argLabel.BackgroundTransparency = 1
    argLabel.Text = "Args: " .. data.ArgumentCount
    argLabel.TextColor3 = Theme.SubText
    argLabel.TextSize = 10
    argLabel.TextXAlignment = Enum.TextXAlignment.Left
    argLabel.Font = Enum.Font.Gotham
    argLabel.Parent = entry
    
    -- Time stamp
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Size = UDim2.new(0, 100, 0, 15)
    timeLabel.Position = UDim2.new(0, 250, 0, 25)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = data.TimeStamp
    timeLabel.TextColor3 = Theme.SubText
    timeLabel.TextSize = 9
    timeLabel.TextXAlignment = Enum.TextXAlignment.Left
    timeLabel.Font = Enum.Font.Gotham
    timeLabel.Parent = entry
    
    -- Click handler for details
    local clickButton = Instance.new("TextButton")
    clickButton.Size = UDim2.new(1, 0, 1, 0)
    clickButton.BackgroundTransparency = 1
    clickButton.Text = ""
    clickButton.Parent = entry
    
    clickButton.MouseButton1Click:Connect(function()
        SelectedLogIndex = index
        self:ShowDetails(data)
        
        -- Highlight selected entry
        for _, child in ipairs(self.LogFrame:GetChildren()) do
            if child:IsA("Frame") then
                if child.Name == "LogEntry_" .. index then
                    child.BackgroundColor3 = Theme.Accent
                    local tween = TweenService:Create(child, TweenInfo.new(0.2), {
                        BackgroundColor3 = Theme.ItemHover
                    })
                    tween:Play()
                else
                    child.BackgroundColor3 = Theme.Item
                end
            end
        end
    end)
    
    -- Hover effect
    clickButton.MouseEnter:Connect(function()
        if entry.Name ~= "LogEntry_" .. SelectedLogIndex then
            entry.BackgroundColor3 = Theme.ItemHover
        end
    end)
    
    clickButton.MouseLeave:Connect(function()
        if entry.Name ~= "LogEntry_" .. SelectedLogIndex then
            entry.BackgroundColor3 = Theme.Item
        end
    end)
    
    return entry
end

-- Show detailed information
function NetworkSpy:ShowDetails(data)
    if not self.GUI or not self.DetailFrame then return end
    
    -- Clear existing details
    for _, child in ipairs(self.DetailFrame:GetChildren()) do
        if child:IsA("TextLabel") and child.Name ~= "DetailTitle" then
            child:Destroy()
        elseif child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    local yOffset = 40
    
    -- Create detail sections
    local details = {
        {"🏷️ Name:", data.Name},
        {"📍 Full Path:", data.FullName},
        {"📊 Type:", data.Type},
        {"↗️ Direction:", data.Direction},
        {"🕒 Time:", data.TimeStamp},
        {"📦 Argument Count:", tostring(data.ArgumentCount)}
    }
    
    for i, detail in ipairs(details) do
        local label = self:CreateDetailLabel(detail[1], detail[2], yOffset)
        label.Parent = self.DetailFrame
        yOffset = yOffset + 25
    end
    
    -- Arguments section
    if data.Arguments and #data.Arguments > 0 then
        yOffset = yOffset + 10
        
        local argTitle = self:CreateDetailTitle("📝 Arguments:", yOffset)
        argTitle.Parent = self.DetailFrame
        yOffset = yOffset + 25
        
        for i, arg in ipairs(data.Arguments) do
            local argLabel = self:CreateDetailLabel("  Arg " .. i .. ":", tostring(arg), yOffset)
            argLabel.Parent = self.DetailFrame
            yOffset = yOffset + 20
        end
    end
    
    -- Raw data section (if available)
    if data.RawArgs then
        yOffset = yOffset + 10
        
        local rawTitle = self:CreateDetailTitle("🔧 Raw Data:", yOffset)
        rawTitle.Parent = self.DetailFrame
        yOffset = yOffset + 25
        
        for i, arg in ipairs(data.RawArgs) do
            local rawLabel = self:CreateDetailLabel("  Raw " .. i .. ":", 
                "Type: " .. type(arg) .. " | Value: " .. tostring(arg), yOffset)
            rawLabel.Parent = self.DetailFrame
            yOffset = yOffset + 20
        end
    end
    
    -- Update canvas size
    self.DetailFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + 20)
end

-- Create detail label
function NetworkSpy:CreateDetailLabel(title, value, yPos)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, 20)
    container.Position = UDim2.new(0, 10, 0, yPos)
    container.BackgroundTransparency = 1
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0, 100, 1, 0)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Theme.SubText
    titleLabel.TextSize = 10
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = container
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(1, -105, 1, 0)
    valueLabel.Position = UDim2.new(0, 105, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(value)
    valueLabel.TextColor3 = Theme.Text
    valueLabel.TextSize = 10
    valueLabel.TextXAlignment = Enum.TextXAlignment.Left
    valueLabel.TextWrapped = true
    valueLabel.Font = Enum.Font.Gotham
    valueLabel.Parent = container
    
    return container
end

-- Create detail title
function NetworkSpy:CreateDetailTitle(title, yPos)
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 20)
    titleLabel.Position = UDim2.new(0, 10, 0, yPos)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Theme.SubText
    titleLabel.TextSize = 12
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = self.DetailFrame
    
    return titleLabel
end

-- Update status label
function NetworkSpy:UpdateStatus()
    if not self.GUI then return end
    
    local statusLabel = self.GUI.MainFrame.ControlPanel.StatusLabel
    local statusText = IsMonitoring and "Monitoring" or "Stopped"
    local filteredCount = 0
    
    for _, data in ipairs(NetworkData) do
        if MatchesFilter(data, SearchFilter, TypeFilter, DirectionFilter) then
            filteredCount = filteredCount + 1
        end
    end
    
    statusLabel.Text = string.format("Status: %s | Logs: %d/%d", statusText, filteredCount, #NetworkData)
end

-- Clear logs
function NetworkSpy:ClearLogs()
    NetworkData = {}
    SelectedLogIndex = 0
    self:UpdateLogDisplay()
    self:UpdateStatus()
    
    -- Clear details
    if self.GUI and self.DetailFrame then
        for _, child in ipairs(self.DetailFrame:GetChildren()) do
            if child:IsA("TextLabel") and child.Name ~= "DetailTitle" then
                child:Destroy()
            elseif child:IsA("Frame") then
                child:Destroy()
            end
        end
    end
end

-- Save logs to file
function NetworkSpy:SaveLogs()
    if #NetworkData == 0 then
        self:ShowNotification("No logs to save")
        return
    end
    
    local logString = "Network Spy Remote Logs\n"
    logString = logString .. "Generated: " .. GetFullTimeStamp() .. "\n"
    logString = logString .. "Total Logs: " .. #NetworkData .. "\n\n"
    
    for i, data in ipairs(NetworkData) do
        logString = logString .. string.format("[%s] %s - %s - %s\n", 
            data.TimeStamp, data.Type, data.Name, data.Direction)
        logString = logString .. "Full Path: " .. data.FullName .. "\n"
        logString = logString .. "Arguments: " .. data.ArgumentCount .. "\n"
        
        for j, arg in ipairs(data.Arguments) do
            logString = logString .. string.format("  Arg %d: %s\n", j, tostring(arg))
        end
        
        if data.RawArgs then
            logString = logString .. "Raw Values:\n"
            for j, arg in ipairs(data.RawArgs) do
                logString = logString .. string.format("  Raw %d: %s (%s)\n", j, tostring(arg), type(arg))
            end
        end
        
        logString = logString .. "\n"
    end
    
    -- Write to file (in studio)
    if RunService:IsStudio() then
        local success, message = pcall(function()
            local filename = "NetworkSpyLogs_" .. os.date("%Y%m%d_%H%M%S") .. ".txt"
            writefile(filename, logString)
            return filename
        end)
        
        if success then
            self:ShowNotification("Logs saved to: " .. message)
        else
            self:ShowNotification("Error saving logs: " .. message)
        end
    else
        -- In game, just print to console
        print("Network Spy Logs:\n" .. logString)
        self:ShowNotification("Logs printed to console (F9)")
    end
end

-- Copy details to clipboard
function NetworkSpy:CopyDetails()
    if SelectedLogIndex == 0 or not NetworkData[SelectedLogIndex] then
        self:ShowNotification("No log selected to copy")
        return
    end
    
    local data = NetworkData[SelectedLogIndex]
    local copyString = string.format("[%s] %s - %s - %s\n", 
        data.TimeStamp, data.Type, data.Name, data.Direction)
    copyString = copyString .. "Full Path: " .. data.FullName .. "\n"
    copyString = copyString .. "Arguments: " .. data.ArgumentCount .. "\n"
    
    for i, arg in ipairs(data.Arguments) do
        copyString = copyString .. string.format("Arg %d: %s\n", i, tostring(arg))
    end
    
    if data.RawArgs then
        copyString = copyString .. "Raw Values:\n"
        for i, arg in ipairs(data.RawArgs) do
            copyString = copyString .. string.format("Raw %d: %s (%s)\n", i, tostring(arg), type(arg))
        end
    end
    
    -- Set clipboard (in studio)
    if RunService:IsStudio() and setclipboard then
        setclipboard(copyString)
        self:ShowNotification("Details copied to clipboard")
    else
        -- In game, just print to console
        print("Network Spy Details:\n" .. copyString)
        self:ShowNotification("Details printed to console (F9)")
    end
end

-- Show notification
function NetworkSpy:ShowNotification(message)
    if not self.GUI then return end
    
    local notification = Instance.new("TextLabel")
    notification.Size = UDim2.new(0, 300, 0, 40)
    notification.Position = UDim2.new(0.5, -150, 0, -50)
    notification.BackgroundColor3 = Theme.Secondary
    notification.TextColor3 = Theme.Text
    notification.Text = message
    notification.TextSize = 14
    notification.Font = Enum.Font.Gotham
    notification.ZIndex = 20
    notification.Parent = self.GUI.MainFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = notification
    
    -- Animate in
    local tweenIn = TweenService:Create(notification, TweenInfo.new(0.3), {
        Position = UDim2.new(0.5, -150, 0, 10)
    })
    tweenIn:Play()
    
    -- Animate out after delay
    delay(3, function()
        if notification and notification.Parent then
            local tweenOut = TweenService:Create(notification, TweenInfo.new(0.3), {
                Position = UDim2.new(0.5, -150, 0, -50)
            })
            tweenOut:Play()
            tweenOut.Completed:Connect(function()
                notification:Destroy()
            end)
        end
    end)
end

-- Initialize Network Spy
local networkSpy = NetworkSpy.new()

-- Create toggle keybinding (F10)
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.F10 then
        networkSpy:ToggleGUI()
    end
end)

-- Auto-start GUI dan monitoring
spawn(function()
    wait(1) -- Wait a bit for game to load
    print("🔧 Memulai inisialisasi Network Spy...")
    
    local success, error_msg = pcall(function()
        print("🔧 Membuat GUI...")
        networkSpy:CreateGUI()
        
        print("🔧 Memulai monitoring...")
        networkSpy:StartMonitoring()
        
        print("🔧 Checking GUI status...")
        if networkSpy.GUI and networkSpy.GUI.Parent then
            print("✅ GUI berhasil dibuat dan ter-parent ke " .. networkSpy.GUI.Parent.Name)
            print("✅ MainFrame visible:", networkSpy.GUI.MainFrame.Visible)
        else
            error("GUI tidak berhasil dibuat atau tidak ter-parent")
        end
    end)
    
    if success then
        print("🔍 Network Spy Remote berhasil dimuat!")
        print("📝 Tekan F10 untuk toggle GUI")
        print("🚀 Monitoring telah dimulai secara otomatis")
        print("🔧 Gunakan _G.ShowNetworkSpy() untuk debug GUI")
    else
        warn("❌ Error loading Network Spy: " .. tostring(error_msg))
        warn("🔄 Mencoba ulang dalam 2 detik...")
        wait(2)
        pcall(function()
            networkSpy:CreateGUI()
            networkSpy:StartMonitoring()
        end)
    end
end)

-- Buat command global untuk akses mudah
_G.NetworkSpy = networkSpy
_G.ToggleNetworkSpy = function()
    networkSpy:ToggleGUI()
end
_G.ShowNetworkSpy = function()
    if not networkSpy.GUI then
        networkSpy:CreateGUI()
        print("🔍 Network Spy GUI dibuat manual")
    else
        print("🔍 Network Spy GUI sudah aktif")
    end
end

return networkSpy