-- Simple Roblox Remote Spy
-- Fokus pada Events Remote, Function Remote, dan detail parameter lengkap

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

-- Configuration
local Config = {
    LogEvents = true,
    LogFunctions = true,
    MaxLogs = 500,
    ShowUI = true
}

-- Storage
local RemoteLogs = {
    Events = {},
    Functions = {},
    Count = 0
}

-- Utility Functions
local function DeepSerialize(obj, depth)
    depth = depth or 0
    if depth > 5 then return "..." end
    
    local objType = typeof(obj)
    
    if objType == "table" then
        local result = "{"
        local count = 0
        for k, v in pairs(obj) do
            if count > 10 then
                result = result .. ", ..."
                break
            end
            if count > 0 then result = result .. ", " end
            result = result .. "[" .. DeepSerialize(k, depth + 1) .. "] = " .. DeepSerialize(v, depth + 1)
            count = count + 1
        end
        return result .. "}"
    elseif objType == "Instance" then
        return string.format("Instance{%s: %s}", obj.ClassName, obj.Name)
    elseif objType == "Vector3" then
        return string.format("Vector3(%.2f, %.2f, %.2f)", obj.X, obj.Y, obj.Z)
    elseif objType == "CFrame" then
        local pos = obj.Position
        return string.format("CFrame(%.2f, %.2f, %.2f, ...)", pos.X, pos.Y, pos.Z)
    elseif objType == "Color3" then
        return string.format("Color3(%.2f, %.2f, %.2f)", obj.R, obj.G, obj.B)
    elseif objType == "EnumItem" then
        return string.format("Enum.%s.%s", tostring(obj.EnumType), obj.Name)
    elseif objType == "string" then
        return string.format('"%s"', obj:sub(1, 100))
    elseif objType == "number" then
        return string.format("%.4f", obj)
    elseif objType == "boolean" then
        return tostring(obj)
    elseif objType == "nil" then
        return "nil"
    else
        return string.format("%s: %s", objType, tostring(obj):sub(1, 50))
    end
end

local function CreateLogEntry(remoteName, remoteType, direction, args, result)
    local entry = {
        ID = RemoteLogs.Count + 1,
        Time = os.date("%H:%M:%S"),
        Timestamp = tick(),
        RemoteName = remoteName,
        RemoteType = remoteType,
        Direction = direction,
        Arguments = {},
        Result = result,
        Traceback = debug.traceback():match("(.-)%s*\n.*NetworkMonitor") or "Unknown"
    }
    
    -- Serialize arguments with detailed info
    for i, arg in ipairs(args) do
        entry.Arguments[i] = {
            Type = typeof(arg),
            Value = DeepSerialize(arg),
            Raw = arg
        }
    end
    
    RemoteLogs.Count = RemoteLogs.Count + 1
    return entry
end

-- UI Creation
local function CreateSimpleUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "RemoteSpyUI"
    ScreenGui.ResetOnSpawn = false
    
    pcall(function()
        ScreenGui.Parent = CoreGui
    end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Main Frame
    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 600, 0, 400)
    Main.Position = UDim2.new(0.5, -300, 0.5, -200)
    Main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Main.BorderSizePixel = 0
    Main.Parent = ScreenGui
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Main
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -100, 0, 30)
    Title.Position = UDim2.new(0, 10, 0, 5)
    Title.BackgroundTransparency = 1
    Title.Text = "🔍 Remote Spy - Simple"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextScaled = true
    Title.Font = Enum.Font.SourceSansBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Main
    
    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 25, 0, 25)
    CloseBtn.Position = UDim2.new(1, -30, 0, 5)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.Font = Enum.Font.SourceSansBold
    CloseBtn.TextScaled = true
    CloseBtn.Parent = Main
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 4)
    CloseCorner.Parent = CloseBtn
    
    -- Control Panel
    local Controls = Instance.new("Frame")
    Controls.Size = UDim2.new(1, -20, 0, 40)
    Controls.Position = UDim2.new(0, 10, 0, 40)
    Controls.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    Controls.Parent = Main
    
    local ControlsCorner = Instance.new("UICorner")
    ControlsCorner.CornerRadius = UDim.new(0, 5)
    ControlsCorner.Parent = Controls
    
    -- Filter Buttons
    local EventsBtn = Instance.new("TextButton")
    EventsBtn.Size = UDim2.new(0, 80, 0, 30)
    EventsBtn.Position = UDim2.new(0, 5, 0, 5)
    EventsBtn.BackgroundColor3 = Config.LogEvents and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(100, 100, 100)
    EventsBtn.Text = "Events"
    EventsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    EventsBtn.Font = Enum.Font.SourceSans
    EventsBtn.TextScaled = true
    EventsBtn.Parent = Controls
    
    local FunctionsBtn = Instance.new("TextButton")
    FunctionsBtn.Size = UDim2.new(0, 80, 0, 30)
    FunctionsBtn.Position = UDim2.new(0, 90, 0, 5)
    FunctionsBtn.BackgroundColor3 = Config.LogFunctions and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(100, 100, 100)
    FunctionsBtn.Text = "Functions"
    FunctionsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    FunctionsBtn.Font = Enum.Font.SourceSans
    FunctionsBtn.TextScaled = true
    FunctionsBtn.Parent = Controls
    
    local ClearBtn = Instance.new("TextButton")
    ClearBtn.Size = UDim2.new(0, 60, 0, 30)
    ClearBtn.Position = UDim2.new(0, 180, 0, 5)
    ClearBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 0)
    ClearBtn.Text = "Clear"
    ClearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ClearBtn.Font = Enum.Font.SourceSans
    ClearBtn.TextScaled = true
    ClearBtn.Parent = Controls
    
    local ExportBtn = Instance.new("TextButton")
    ExportBtn.Size = UDim2.new(0, 60, 0, 30)
    ExportBtn.Position = UDim2.new(0, 245, 0, 5)
    ExportBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
    ExportBtn.Text = "Export"
    ExportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ExportBtn.Font = Enum.Font.SourceSans
    ExportBtn.TextScaled = true
    ExportBtn.Parent = Controls
    
    -- Logs Display
    local LogsFrame = Instance.new("ScrollingFrame")
    LogsFrame.Size = UDim2.new(1, -20, 1, -90)
    LogsFrame.Position = UDim2.new(0, 10, 0, 85)
    LogsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    LogsFrame.BorderSizePixel = 0
    LogsFrame.ScrollBarThickness = 8
    LogsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    LogsFrame.Parent = Main
    
    local LogsCorner = Instance.new("UICorner")
    LogsCorner.CornerRadius = UDim.new(0, 5)
    LogsCorner.Parent = LogsFrame
    
    local LogsLayout = Instance.new("UIListLayout")
    LogsLayout.Padding = UDim.new(0, 2)
    LogsLayout.Parent = LogsFrame
    
    -- Make draggable
    local dragging = false
    local dragStart, startPos
    
    Title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(
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
    
    return {
        Main = Main,
        LogsFrame = LogsFrame,
        EventsBtn = EventsBtn,
        FunctionsBtn = FunctionsBtn,
        ClearBtn = ClearBtn,
        ExportBtn = ExportBtn,
        CloseBtn = CloseBtn
    }
end

local UI = CreateSimpleUI()

-- Function to add log to UI
local function AddLogToUI(logEntry)
    if not UI or not UI.LogsFrame then return end
    
    local LogItem = Instance.new("Frame")
    LogItem.Size = UDim2.new(1, -10, 0, 0) -- Height will be determined by content
    LogItem.BackgroundColor3 = logEntry.RemoteType == "RemoteEvent" and Color3.fromRGB(40, 40, 60) or Color3.fromRGB(60, 40, 40)
    LogItem.BorderSizePixel = 0
    LogItem.Parent = UI.LogsFrame
    
    local ItemCorner = Instance.new("UICorner")
    ItemCorner.CornerRadius = UDim.new(0, 3)
    ItemCorner.Parent = LogItem
    
    -- Header with remote info
    local Header = Instance.new("TextLabel")
    Header.Size = UDim2.new(1, -10, 0, 25)
    Header.Position = UDim2.new(0, 5, 0, 2)
    Header.BackgroundTransparency = 1
    Header.Text = string.format("[%s] %s - %s (%s)", 
        logEntry.Time, 
        logEntry.RemoteType, 
        logEntry.RemoteName:match("([^%.]+)$") or logEntry.RemoteName,
        logEntry.Direction
    )
    Header.TextColor3 = Color3.fromRGB(255, 255, 255)
    Header.Font = Enum.Font.SourceSansBold
    Header.TextSize = 14
    Header.TextXAlignment = Enum.TextXAlignment.Left
    Header.TextTruncate = Enum.TextTruncate.AtEnd
    Header.Parent = LogItem
    
    -- Arguments section
    local ArgsText = "Arguments (" .. #logEntry.Arguments .. "):\n"
    for i, arg in ipairs(logEntry.Arguments) do
        ArgsText = ArgsText .. string.format("  [%d] %s: %s\n", i, arg.Type, arg.Value)
    end
    
    if logEntry.Result then
        ArgsText = ArgsText .. "Result: " .. DeepSerialize(logEntry.Result) .. "\n"
    end
    
    local ArgsLabel = Instance.new("TextLabel")
    ArgsLabel.Size = UDim2.new(1, -10, 0, 0)
    ArgsLabel.Position = UDim2.new(0, 5, 0, 27)
    ArgsLabel.BackgroundTransparency = 1
    ArgsLabel.Text = ArgsText
    ArgsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    ArgsLabel.Font = Enum.Font.Code
    ArgsLabel.TextSize = 12
    ArgsLabel.TextXAlignment = Enum.TextXAlignment.Left
    ArgsLabel.TextYAlignment = Enum.TextYAlignment.Top
    ArgsLabel.TextWrapped = true
    ArgsLabel.Parent = LogItem
    
    -- Calculate text height
    local textHeight = ArgsLabel.TextBounds.Y
    ArgsLabel.Size = UDim2.new(1, -10, 0, textHeight)
    LogItem.Size = UDim2.new(1, -10, 0, textHeight + 35)
    
    -- Update canvas size
    UI.LogsFrame.CanvasSize = UDim2.new(0, 0, 0, UI.LogsFrame.UIListLayout.AbsoluteContentSize.Y + 10)
    UI.LogsFrame.CanvasPosition = Vector2.new(0, UI.LogsFrame.CanvasSize.Y.Offset)
end

-- Hook RemoteEvent
local function HookRemoteEvent(remote)
    local remoteName = remote:GetFullName()
    
    -- Hook incoming (OnClientEvent)
    remote.OnClientEvent:Connect(function(...)
        if not Config.LogEvents then return end
        
        local args = {...}
        local logEntry = CreateLogEntry(remoteName, "RemoteEvent", "Incoming", args)
        
        table.insert(RemoteLogs.Events, logEntry)
        AddLogToUI(logEntry)
        
        -- Keep only last MaxLogs entries
        if #RemoteLogs.Events > Config.MaxLogs then
            table.remove(RemoteLogs.Events, 1)
        end
    end)
    
    -- Hook outgoing (FireServer) using metatable
    pcall(function()
        local oldFireServer = remote.FireServer
        remote.FireServer = function(self, ...)
            if Config.LogEvents then
                local args = {...}
                local logEntry = CreateLogEntry(remoteName, "RemoteEvent", "Outgoing", args)
                
                table.insert(RemoteLogs.Events, logEntry)
                AddLogToUI(logEntry)
                
                if #RemoteLogs.Events > Config.MaxLogs then
                    table.remove(RemoteLogs.Events, 1)
                end
            end
            
            return oldFireServer(self, ...)
        end
    end)
end

-- Hook RemoteFunction
local function HookRemoteFunction(remote)
    local remoteName = remote:GetFullName()
    
    -- Hook InvokeServer
    pcall(function()
        local oldInvokeServer = remote.InvokeServer
        remote.InvokeServer = function(self, ...)
            if Config.LogFunctions then
                local args = {...}
                local success, result = pcall(oldInvokeServer, self, ...)
                
                local logEntry = CreateLogEntry(remoteName, "RemoteFunction", "Invoke", args, result)
                
                table.insert(RemoteLogs.Functions, logEntry)
                AddLogToUI(logEntry)
                
                if #RemoteLogs.Functions > Config.MaxLogs then
                    table.remove(RemoteLogs.Functions, 1)
                end
                
                if success then
                    return result
                else
                    error(result)
                end
            else
                return oldInvokeServer(self, ...)
            end
        end
    end)
end

-- Scan and hook all remotes
local function ScanAllRemotes()
    local count = 0
    
    local function scanContainer(container)
        for _, obj in pairs(container:GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                HookRemoteEvent(obj)
                count = count + 1
            elseif obj:IsA("RemoteFunction") then
                HookRemoteFunction(obj)
                count = count + 1
            end
        end
    end
    
    -- Scan ReplicatedStorage
    scanContainer(ReplicatedStorage)
    
    -- Scan other services
    for _, service in pairs(game:GetChildren()) do
        if service ~= ReplicatedStorage then
            pcall(function()
                scanContainer(service)
            end)
        end
    end
    
    print(string.format("[Remote Spy] Hooked %d remotes", count))
end

-- Hook new remotes automatically
game.DescendantAdded:Connect(function(obj)
    if obj:IsA("RemoteEvent") then
        HookRemoteEvent(obj)
    elseif obj:IsA("RemoteFunction") then
        HookRemoteFunction(obj)
    end
end)

-- UI Event Handlers
if UI then
    UI.EventsBtn.MouseButton1Click:Connect(function()
        Config.LogEvents = not Config.LogEvents
        UI.EventsBtn.BackgroundColor3 = Config.LogEvents and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(100, 100, 100)
    end)
    
    UI.FunctionsBtn.MouseButton1Click:Connect(function()
        Config.LogFunctions = not Config.LogFunctions
        UI.FunctionsBtn.BackgroundColor3 = Config.LogFunctions and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(100, 100, 100)
    end)
    
    UI.ClearBtn.MouseButton1Click:Connect(function()
        RemoteLogs.Events = {}
        RemoteLogs.Functions = {}
        RemoteLogs.Count = 0
        
        for _, child in pairs(UI.LogsFrame:GetChildren()) do
            if not child:IsA("UIListLayout") then
                child:Destroy()
            end
        end
        
        UI.LogsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    end)
    
    UI.ExportBtn.MouseButton1Click:Connect(function()
        local export = {
            Timestamp = os.date("%Y-%m-%d %H:%M:%S"),
            Events = RemoteLogs.Events,
            Functions = RemoteLogs.Functions
        }
        
        local json = HttpService:JSONEncode(export)
        print("=== REMOTE SPY EXPORT ===")
        print(json)
        print("========================")
        
        _G.RemoteSpyData = export
        print("Data saved to _G.RemoteSpyData")
    end)
    
    UI.CloseBtn.MouseButton1Click:Connect(function()
        UI.Main.Parent:Destroy()
        Config.ShowUI = false
    end)
end

-- Global commands
_G.RemoteSpy = {
    Start = function()
        ScanAllRemotes()
        print("[Remote Spy] Started monitoring all remotes")
    end,
    
    Stop = function()
        Config.LogEvents = false
        Config.LogFunctions = false
        print("[Remote Spy] Stopped monitoring")
    end,
    
    Clear = function()
        RemoteLogs.Events = {}
        RemoteLogs.Functions = {}
        RemoteLogs.Count = 0
        if UI then
            for _, child in pairs(UI.LogsFrame:GetChildren()) do
                if not child:IsA("UIListLayout") then
                    child:Destroy()
                end
            end
        end
        print("[Remote Spy] Logs cleared")
    end,
    
    Export = function()
        local export = {
            Events = RemoteLogs.Events,
            Functions = RemoteLogs.Functions
        }
        _G.RemoteSpyData = export
        print("[Remote Spy] Data exported to _G.RemoteSpyData")
        return export
    end,
    
    GetLogs = function()
        return RemoteLogs
    end
}

-- Auto start
_G.RemoteSpy.Start()

print([[
================================
🔍 Simple Remote Spy Loaded!
================================

Features:
✅ Events Remote monitoring
✅ Function Remote monitoring  
✅ Detailed parameter logging
✅ Real-time UI display
✅ Export functionality

Commands:
_G.RemoteSpy.Start()   - Start monitoring
_G.RemoteSpy.Stop()    - Stop monitoring
_G.RemoteSpy.Clear()   - Clear all logs
_G.RemoteSpy.Export()  - Export data
_G.RemoteSpy.ShowUI()  - Show/Recreate UI
_G.RemoteSpy.HideUI()  - Hide UI
_G.RemoteSpy.CheckUI() - Check UI status

If UI not visible, try:
_G.RemoteSpy.CheckUI()
_G.RemoteSpy.ShowUI()

UI Controls:
- Events/Functions buttons: Toggle logging
- Clear: Clear all displayed logs
- Export: Export to console
- Drag title to move window

Ready to spy! 🕵️
================================
]])