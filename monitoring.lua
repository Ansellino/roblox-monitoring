-- Roblox Network Monitor Script
-- Script ini untuk tujuan debugging dan pembelajaran saja
-- Gunakan dengan bijak dan sesuai ToS Roblox

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- Configuration
local MONITOR_CONFIG = {
    LogRemoteEvents = true,
    LogRemoteFunctions = true,
    LogBindableEvents = true,
    LogBindableFunctions = true,
    MaxLogsPerRemote = 100,
    SaveInterval = 30, -- Save every 30 seconds
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

-- Utility function to serialize data
local function SerializeData(data)
    local dataType = typeof(data)
    
    if dataType == "table" then
        local result = {}
        for k, v in pairs(data) do
            result[tostring(k)] = SerializeData(v)
        end
        return HttpService:JSONEncode(result)
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
    local originalOnClientEvent = remote.OnClientEvent
    remote.OnClientEvent:Connect(function(...)
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
        
        print(string.format("[Network Monitor] RemoteEvent '%s' received with %d args", remoteName, #args))
    end)
    
    -- Hook FireServer (outgoing) - requires metatable manipulation
    local mt = getmetatable(remote)
    if mt then
        local oldNamecall = mt.__namecall
        mt.__namecall = function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            
            if method == "FireServer" and self == remote then
                local serializedArgs = {}
                for i, arg in ipairs(args) do
                    serializedArgs[i] = SerializeData(arg)
                end
                
                local logEntry = CreateLogEntry(remoteName, "RemoteEvent", serializedArgs, false)
                
                if #NetworkLogs.RemoteEvents[remoteName] < MONITOR_CONFIG.MaxLogsPerRemote then
                    table.insert(NetworkLogs.RemoteEvents[remoteName], logEntry)
                end
                
                print(string.format("[Network Monitor] FireServer called on '%s' with %d args", remoteName, #args))
            end
            
            return oldNamecall(self, ...)
        end
    end
end

-- Hook into RemoteFunctions
local function HookRemoteFunction(remote)
    if not MONITOR_CONFIG.LogRemoteFunctions then return end
    
    local remoteName = remote:GetFullName()
    
    if not NetworkLogs.RemoteFunctions[remoteName] then
        NetworkLogs.RemoteFunctions[remoteName] = {}
    end
    
    -- Hook InvokeServer (if possible)
    local mt = getmetatable(remote)
    if mt then
        local oldNamecall = mt.__namecall
        mt.__namecall = function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            
            if method == "InvokeServer" and self == remote then
                local serializedArgs = {}
                for i, arg in ipairs(args) do
                    serializedArgs[i] = SerializeData(arg)
                end
                
                local logEntry = CreateLogEntry(remoteName, "RemoteFunction", serializedArgs, false)
                
                if #NetworkLogs.RemoteFunctions[remoteName] < MONITOR_CONFIG.MaxLogsPerRemote then
                    table.insert(NetworkLogs.RemoteFunctions[remoteName], logEntry)
                end
                
                print(string.format("[Network Monitor] InvokeServer called on '%s' with %d args", remoteName, #args))
            end
            
            return oldNamecall(self, ...)
        end
    end
end

-- Scan for existing remotes
local function ScanForRemotes()
    -- Scan ReplicatedStorage
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            HookRemoteEvent(obj)
        elseif obj:IsA("RemoteFunction") then
            HookRemoteFunction(obj)
        end
    end
    
    -- Scan all services
    for _, service in pairs(game:GetChildren()) do
        if service ~= ReplicatedStorage then
            pcall(function()
                for _, obj in pairs(service:GetDescendants()) do
                    if obj:IsA("RemoteEvent") then
                        HookRemoteEvent(obj)
                    elseif obj:IsA("RemoteFunction") then
                        HookRemoteFunction(obj)
                    end
                end
            end)
        end
    end
end

-- Hook new remotes
ReplicatedStorage.DescendantAdded:Connect(function(obj)
    if obj:IsA("RemoteEvent") then
        HookRemoteEvent(obj)
    elseif obj:IsA("RemoteFunction") then
        HookRemoteFunction(obj)
    end
end)

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
    
    -- Summary Statistics
    table.insert(output, "\n" .. "=" .. string.rep("=", 50))
    table.insert(output, "SUMMARY STATISTICS")
    table.insert(output, "=" .. string.rep("=", 50))
    
    local totalRemoteEvents = 0
    local totalRemoteFunctions = 0
    
    for _, logs in pairs(NetworkLogs.RemoteEvents) do
        totalRemoteEvents = totalRemoteEvents + #logs
    end
    
    for _, logs in pairs(NetworkLogs.RemoteFunctions) do
        totalRemoteFunctions = totalRemoteFunctions + #logs
    end
    
    table.insert(output, string.format("Total RemoteEvent Calls: %d", totalRemoteEvents))
    table.insert(output, string.format("Total RemoteFunction Calls: %d", totalRemoteFunctions))
    table.insert(output, string.format("Unique RemoteEvents: %d", #NetworkLogs.RemoteEvents))
    table.insert(output, string.format("Unique RemoteFunctions: %d", #NetworkLogs.RemoteFunctions))
    
    return table.concat(output, "\n")
end

-- Function to save logs (prints to console, can be copied)
local function SaveLogs()
    local logString = ExportLogsToString()
    
    print("\n" .. "=" .. string.rep("=", 50))
    print("NETWORK LOGS (Copy this to save as .txt file):")
    print("=" .. string.rep("=", 50))
    print(logString)
    print("=" .. string.rep("=", 50))
    
    -- Also save to _G for easy access
    _G.NetworkMonitorLogs = logString
    print("\nLogs also saved to _G.NetworkMonitorLogs")
end

-- Auto-save periodically
spawn(function()
    while true do
        wait(MONITOR_CONFIG.SaveInterval)
        SaveLogs()
    end
end)

-- Commands
_G.NetworkMonitor = {
    Start = function()
        print("[Network Monitor] Starting scan...")
        ScanForRemotes()
        print("[Network Monitor] Scan complete! Monitoring active.")
    end,
    
    Stop = function()
        MONITOR_CONFIG.LogRemoteEvents = false
        MONITOR_CONFIG.LogRemoteFunctions = false
        print("[Network Monitor] Monitoring stopped.")
    end,
    
    Clear = function()
        NetworkLogs.RemoteEvents = {}
        NetworkLogs.RemoteFunctions = {}
        print("[Network Monitor] Logs cleared.")
    end,
    
    Export = function()
        SaveLogs()
    end,
    
    GetStats = function()
        local totalRemoteEvents = 0
        local totalRemoteFunctions = 0
        
        for _, logs in pairs(NetworkLogs.RemoteEvents) do
            totalRemoteEvents = totalRemoteEvents + #logs
        end
        
        for _, logs in pairs(NetworkLogs.RemoteFunctions) do
            totalRemoteFunctions = totalRemoteFunctions + #logs
        end
        
        print(string.format("[Network Monitor] Stats - RemoteEvents: %d, RemoteFunctions: %d", 
            totalRemoteEvents, totalRemoteFunctions))
    end
}

-- Auto-start
_G.NetworkMonitor.Start()

print([[
========================================
Network Monitor Loaded Successfully!
========================================
Commands:
  _G.NetworkMonitor.Start()   - Start monitoring
  _G.NetworkMonitor.Stop()    - Stop monitoring
  _G.NetworkMonitor.Clear()   - Clear logs
  _G.NetworkMonitor.Export()  - Export logs to console
  _G.NetworkMonitor.GetStats() - Show statistics

Logs are auto-saved every 30 seconds.
Access saved logs: _G.NetworkMonitorLogs
========================================
]])