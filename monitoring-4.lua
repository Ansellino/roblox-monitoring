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
    local success, err = pcall(function()
        NetworkMonitorUI.Parent = CoreGui
    end)
    
    if not success or not NetworkMonitorUI.Parent then
        NetworkMonitorUI.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- [Rest of UI creation code remains the same...]
    -- ... (kode UI yang sudah ada tetap dipertahankan)
    
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
    if not UI or not UI.MonitorContent then 
        warn("UI not initialized, cannot add log")
        return 
    end
    
    -- [Rest of AddLogToUI code remains the same...]
    -- ... (kode AddLogToUI yang sudah ada tetap dipertahankan)
end

-- Function to format log detail for display
local function FormatLogDetail(logData)
    if not logData then return "No log data selected" end
    
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
    
    -- [Rest of UpdateStats code remains the same...]
    -- ... (kode UpdateStats yang sudah ada tetap dipertahankan)
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
    elseif dataType == "number" then
        return tostring(data)
    elseif dataType == "boolean" then
        return tostring(data)
    elseif dataType == "nil" then
        return "nil"
    else
        return string.format("[%s]", dataType)
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
        local mt = getrawmetatable(remote)
        if mt then
            local oldNamecall
            if mt.__namecall then
                oldNamecall = mt.__namecall
            end
            
            mt.__namecall = newcclosure(function(self, ...)
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
                
                if oldNamecall then
                    return oldNamecall(self, ...)
                else
                    return self[method](self, ...)
                end
            end)
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
        local mt = getrawmetatable(remote)
        if mt then
            local oldNamecall
            if mt.__namecall then
                oldNamecall = mt.__namecall
            end
            
            mt.__namecall = newcclosure(function(self, ...)
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
                
                if oldNamecall then
                    return oldNamecall(self, ...)
                else
                    return self[method](self, ...)
                end
            end)
        end
    end)
end

-- [Rest of the code remains the same...]
-- ... (kode untuk BindableEvents, BindableFunctions, dan fungsi lainnya tetap dipertahankan)

-- Scan for existing remotes
local function ScanForRemotes()
    local remoteCount = 0
    
    -- Scan all descendants of the game
    local function scanDescendants(parent)
        for _, obj in pairs(parent:GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                pcall(function() HookRemoteEvent(obj) end)
                remoteCount = remoteCount + 1
            elseif obj:IsA("RemoteFunction") then
                pcall(function() HookRemoteFunction(obj) end)
                remoteCount = remoteCount + 1
            elseif obj:IsA("BindableEvent") then
                pcall(function() HookBindableEvent(obj) end)
                remoteCount = remoteCount + 1
            elseif obj:IsA("BindableFunction") then
                pcall(function() HookBindableFunction(obj) end)
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

-- [Rest of the code remains the same...]
-- ... (kode untuk SetupDescendantAddedHook, ExportLogsToString, SaveLogs, dll tetap dipertahankan)

-- Create UI
local UI = CreateUI()

-- Auto-start if configured
if MONITOR_CONFIG.AutoStart then
    -- Delay start to ensure UI is fully initialized
    task.spawn(function()
        task.wait(1)
        _G.NetworkMonitor.Start()
    end)
end

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