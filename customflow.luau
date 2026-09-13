-- CustomFlow is fully vibecoded!!!111!!
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library      = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local SoundService = game:GetService("SoundService")
local RunService   = game:GetService("RunService")
local Stats        = game:GetService("Stats")
local Lighting     = game:GetService("Lighting")

local Options = Library.Options

local SCRIPT_NAME = "CustomFlow"
local ROOT        = "CustomFlow"
local MUSIC_DIR   = ROOT .. "/music"

if not isfolder(ROOT)      then makefolder(ROOT) end
if not isfolder(MUSIC_DIR) then makefolder(MUSIC_DIR) end

-- ============================================================
-- Sound engine
-- ============================================================
local Player = Instance.new("Sound")
Player.Name   = "CustomFlowPlayer"
Player.Volume = 0.5
Player.Looped = false
Player.Parent = SoundService

local State = {
    Current   = "None",
    Queue     = {},
    IsPlaying = false,
    HasTrack  = false,
    Unloaded  = false,
}

-- ============================================================
-- Helpers
-- ============================================================
local function Notify(text, time)
    if State.Unloaded then return end
    pcall(function()
        Library:Notify({
            Title       = SCRIPT_NAME,
            Description = tostring(text),
            Time        = tonumber(time) or 4,
        })
    end)
end

local function CleanName(name)
    if type(name) ~= "string" then return "Unknown" end
    local base = name:match("[^/\\]+$") or name
    base = base:gsub("%.[%w]+$", "")
    return base
end

local function ListLocal()
    if not isfolder(MUSIC_DIR) then return {} end
    local files = listfiles(MUSIC_DIR)
    local out = {}
    for _, f in ipairs(files) do
        local name = f:match("[^/\\]+$") or f
        if name:match("%.[mM][pP]3$")
            or name:match("%.[oO][gG][gG]$")
            or name:match("%.[wW][aA][vV]$") then
            table.insert(out, name)
        end
    end
    table.sort(out)
    return out
end

local function SetAsset(asset, label)
    Player.SoundId = asset
    Player:Play()
    State.Current   = CleanName(label)
    State.IsPlaying = true
    State.HasTrack  = true
    Notify("Playing: " .. State.Current, 3)
end

local function PlayLocal(name)
    local full = MUSIC_DIR .. "/" .. name
    if not isfile(full) then
        Notify("File not found: " .. name)
        return
    end
    local ok, asset = pcall(getcustomasset, full)
    if not ok then
        Notify("Failed to load asset")
        return
    end
    SetAsset(asset, name)
end

-- ============================================================
-- Post-processing instances (Bloom / Atmosphere / ColorCorrection)
-- ============================================================
local function EnsureInstance(ClassName, Name)
    local inst = Lighting:FindFirstChild(Name) or Lighting:FindFirstChildOfClass(ClassName)
    if not inst then
        inst = Instance.new(ClassName)
        inst.Name = Name
        inst.Parent = Lighting
    end
    return inst
end

local BloomEffect = EnsureInstance("BloomEffect", "CustomFlow_Bloom")
local Atmosphere  = Lighting:FindFirstChildOfClass("Atmosphere")

-- ============================================================
-- Window
-- ============================================================
local Window = Library:CreateWindow({
    Title            = SCRIPT_NAME,
    Footer           = "music + visuals",
    Icon             = 95897006870,
    NotifySide       = "Right",
    ShowCustomCursor = true,
    Center           = true,
    AutoShow         = true,
    Resizable        = true,
})

local Tabs = {
    Player = Window:AddTab("Player", "music"),
    Visual = Window:AddTab("Visual", "sun"),
    UI     = Window:AddTab("UI Settings", "settings"),
}

-- ============================================================
-- Player tab
-- ============================================================
local NowBox = Tabs.Player:AddGroupbox({ Side = "Left", Name = "Now Playing", IconName = "disc-3" })

local NowPlayingLabel = NowBox:AddLabel("Nothing playing", true)

NowBox:AddSlider("Volume", {
    Text = "Volume",
    Default = 50, Min = 0, Max = 100, Rounding = 0,
    Suffix = "%",
    Callback = function(v) Player.Volume = v / 100 end,
})

NowBox:AddDivider()

NowBox:AddButton({ Text = "Play / Pause", Func = function()
    if not State.HasTrack then Notify("Nothing loaded") return end
    if Player.IsPlaying then
        Player:Pause()
        State.IsPlaying = false
    else
        Player:Resume()
        State.IsPlaying = true
    end
end })

NowBox:AddButton({ Text = "Stop", Func = function()
    Player:Stop()
    State.IsPlaying = false
end })

local LibraryBox = Tabs.Player:AddGroupbox({ Side = "Right", Name = "Library", IconName = "library" })

LibraryBox:AddDropdown("LocalList", {
    Text       = "Music folder (" .. MUSIC_DIR .. ")",
    Values     = ListLocal(),
    Multi      = false,
    AllowNull  = true,
    Searchable = true,
    FormatDisplayValue = function(v) return CleanName(v) end,
    FormatListValue    = function(v) return CleanName(v) end,
})

LibraryBox:AddButton({ Text = "Refresh list", Func = function()
    Options.LocalList:SetValues(ListLocal())
    Notify("Refreshed local library")
end })

LibraryBox:AddButton({ Text = "Play selected", Func = function()
    local v = Options.LocalList.Value
    if not v then Notify("Select a track first") return end
    PlayLocal(v)
end })

LibraryBox:AddButton({ Text = "Add to queue", Func = function()
    local v = Options.LocalList.Value
    if not v then Notify("Select a track first") return end
    table.insert(State.Queue, v)
    RefreshQueue()
end })

LibraryBox:AddDivider()

local QueueLabel = LibraryBox:AddLabel("Queue is empty", true)

function RefreshQueue()
    if #State.Queue == 0 then
        QueueLabel:SetText("Queue is empty")
        return
    end
    local lines = {}
    for i, item in ipairs(State.Queue) do
        table.insert(lines, string.format("%d. %s", i, CleanName(item)))
    end
    QueueLabel:SetText(table.concat(lines, "\n"))
end

LibraryBox:AddButton({ Text = "Skip current", Func = function()
    if #State.Queue == 0 then Notify("Queue is empty") return end
    Player:Stop()
end })

LibraryBox:AddButton({ Text = "Clear queue", Func = function()
    State.Queue = {}
    RefreshQueue()
    Notify("Queue cleared")
end })

Player.Ended:Connect(function()
    State.IsPlaying = false
    if State.Unloaded then return end
    if #State.Queue > 0 then
        local next_item = table.remove(State.Queue, 1)
        RefreshQueue()
        PlayLocal(next_item)
    end
end)

-- ============================================================
-- Visual tab — captured defaults
-- ============================================================
local VisualDefaults = {
    ClockTime     = Lighting.ClockTime,
    Brightness    = Lighting.Brightness,
    Ambient       = Lighting.Ambient,
    OutdoorAmb    = Lighting.OutdoorAmbient,
    FogStart      = Lighting.FogStart,
    FogEnd        = Lighting.FogEnd,
    FogColor      = Lighting.FogColor,
    BloomInt      = BloomEffect.Intensity,
    BloomSize     = BloomEffect.Size,
    BloomThresh   = BloomEffect.Threshold,
    BloomEnabled  = BloomEffect.Enabled,
    AtmoDensity   = Atmosphere and Atmosphere.Density or 0,
    AtmoColor     = Atmosphere and Atmosphere.Color or Color3.new(0,0,0),
}

local WeatherPresets = {
    Default   = { ClockTime = 14.5, Brightness = 2, Ambient = Color3.fromRGB(70,70,70),  Outdoor = Color3.fromRGB(128,128,128), FogStart = 0, FogEnd = 100000, FogColor = Color3.fromRGB(192,192,192), Bloom = 0.5 },
    Morning   = { ClockTime = 7,    Brightness = 3, Ambient = Color3.fromRGB(90,85,80),  Outdoor = Color3.fromRGB(160,145,130), FogStart = 0, FogEnd = 800,    FogColor = Color3.fromRGB(215,195,170), Bloom = 0.9 },
    Afternoon = { ClockTime = 14,   Brightness = 2, Ambient = Color3.fromRGB(85,85,85),  Outdoor = Color3.fromRGB(150,150,150), FogStart = 0, FogEnd = 1500,   FogColor = Color3.fromRGB(200,210,220), Bloom = 0.7 },
    Evening   = { ClockTime = 18,   Brightness = 2, Ambient = Color3.fromRGB(80,60,50),  Outdoor = Color3.fromRGB(140,100,80),  FogStart = 0, FogEnd = 900,    FogColor = Color3.fromRGB(230,150,100), Bloom = 1.1 },
    Night     = { ClockTime = 0,    Brightness = 1, Ambient = Color3.fromRGB(20,25,40),  Outdoor = Color3.fromRGB(40,50,70),    FogStart = 0, FogEnd = 600,    FogColor = Color3.fromRGB(20,25,45),   Bloom = 1.4 },
}

local function SetFogEnabled(enabled)
    if Atmosphere then
        pcall(function()
            Atmosphere.Density = enabled and 0 or VisualDefaults.AtmoDensity
        end)
    end
end

local function ApplyWeather(name)
    local p = WeatherPresets[name]
    if not p then return end

    Lighting.ClockTime      = p.ClockTime
    Lighting.Brightness     = p.Brightness
    Lighting.Ambient        = p.Ambient
    Lighting.OutdoorAmbient = p.Outdoor
    Lighting.FogStart       = p.FogStart
    Lighting.FogEnd         = p.FogEnd
    Lighting.FogColor       = p.FogColor
    BloomEffect.Intensity   = p.Bloom

    if Atmosphere and p.FogEnd <= 5000 then
        pcall(function() Atmosphere.Density = 0 end)
    end

    if Options.VisualAmbient        then Options.VisualAmbient:SetValueRGB(p.Ambient) end
    if Options.VisualOutdoorAmbient then Options.VisualOutdoorAmbient:SetValueRGB(p.Outdoor) end
    if Options.VisualFogColor       then Options.VisualFogColor:SetValueRGB(p.FogColor) end
    if Options.VisualFogStart       then Options.VisualFogStart:SetValue(p.FogStart) end
    if Options.VisualFogEnd         then Options.VisualFogEnd:SetValue(p.FogEnd) end
    if Options.VisualBloomIntensity then Options.VisualBloomIntensity:SetValue(p.Bloom) end

    Notify("Weather: " .. name, 3)
end

local WeatherBox = Tabs.Visual:AddGroupbox({ Side = "Left", Name = "Weather", IconName = "cloud-sun" })

WeatherBox:AddDropdown("VisualWeather", {
    Text      = "Preset",
    Values    = { "Default", "Morning", "Afternoon", "Evening", "Night", "Custom" },
    Default   = "Default",
    Multi     = false,
    AllowNull = false,
    Callback  = function(value)
        if value ~= "Custom" then ApplyWeather(value) end
    end,
})

WeatherBox:AddDivider()

WeatherBox:AddLabel("Ambient"):AddColorPicker("VisualAmbient", {
    Default  = Lighting.Ambient,
    Title    = "Ambient color",
    Callback = function(color)
        Lighting.Ambient = color
        if Options.VisualWeather then Options.VisualWeather:SetValue("Custom") end
    end,
})

WeatherBox:AddLabel("Outdoor Ambient"):AddColorPicker("VisualOutdoorAmbient", {
    Default  = Lighting.OutdoorAmbient,
    Title    = "Outdoor ambient color",
    Callback = function(color)
        Lighting.OutdoorAmbient = color
        if Options.VisualWeather then Options.VisualWeather:SetValue("Custom") end
    end,
})

local FogBox = Tabs.Visual:AddGroupbox({ Side = "Right", Name = "Fog", IconName = "cloud-fog" })

FogBox:AddToggle("VisualFogEnabled", {
    Text    = "Enable Fog",
    Default = true,
    Callback = function(state)
        SetFogEnabled(state)
        if not state then
            Lighting.FogStart = 0
            Lighting.FogEnd   = 100000
        end
    end,
})

FogBox:AddSlider("VisualFogStart", {
    Text = "Fog Start",
    Default = math.floor(Lighting.FogStart),
    Min = 0, Max = 5000, Rounding = 0,
    Callback = function(v)
        Lighting.FogStart = v
        if Lighting.FogEnd <= v then
            Lighting.FogEnd = v + 100
        end
        if Options.VisualWeather then Options.VisualWeather:SetValue("Custom") end
    end,
})

FogBox:AddSlider("VisualFogEnd", {
    Text = "Fog End",
    Default = math.floor(math.min(Lighting.FogEnd, 5000)),
    Min = 10, Max = 5000, Rounding = 0,
    Callback = function(v)
        if v <= Lighting.FogStart then
            v = Lighting.FogStart + 10
        end
        Lighting.FogEnd = v
        if Atmosphere then pcall(function() Atmosphere.Density = 0 end) end
        if Options.VisualWeather then Options.VisualWeather:SetValue("Custom") end
    end,
})

FogBox:AddLabel("Fog Color"):AddColorPicker("VisualFogColor", {
    Default  = Lighting.FogColor,
    Title    = "Fog color",
    Callback = function(color)
        Lighting.FogColor = color
        if Options.VisualWeather then Options.VisualWeather:SetValue("Custom") end
    end,
})

local BloomBox = Tabs.Visual:AddGroupbox({ Side = "Right", Name = "Bloom", IconName = "sparkles" })

BloomBox:AddToggle("VisualBloomEnabled", {
    Text    = "Enable Bloom",
    Default = BloomEffect.Enabled,
    Callback = function(state) BloomEffect.Enabled = state end,
})

BloomBox:AddSlider("VisualBloomIntensity", {
    Text = "Intensity",
    Default = BloomEffect.Intensity,
    Min = 0, Max = 10, Rounding = 1,
    Callback = function(v) BloomEffect.Intensity = v end,
})

BloomBox:AddSlider("VisualBloomSize", {
    Text = "Size",
    Default = math.floor(BloomEffect.Size),
    Min = 0, Max = 100, Rounding = 0,
    Callback = function(v) BloomEffect.Size = v end,
})

BloomBox:AddSlider("VisualBloomThreshold", {
    Text = "Threshold",
    Default = BloomEffect.Threshold,
    Min = 0, Max = 5, Rounding = 1,
    Callback = function(v) BloomEffect.Threshold = v end,
})

local ResetBox = Tabs.Visual:AddGroupbox({ Side = "Left", Name = "Reset", IconName = "rotate-ccw" })

ResetBox:AddButton({ Text = "Reset visuals to default", Func = function()
    Lighting.ClockTime            = VisualDefaults.ClockTime
    Lighting.Brightness           = VisualDefaults.Brightness
    Lighting.Ambient              = VisualDefaults.Ambient
    Lighting.OutdoorAmbient       = VisualDefaults.OutdoorAmb
    Lighting.FogStart             = VisualDefaults.FogStart
    Lighting.FogEnd               = VisualDefaults.FogEnd
    Lighting.FogColor             = VisualDefaults.FogColor
    BloomEffect.Intensity         = VisualDefaults.BloomInt
    BloomEffect.Size              = VisualDefaults.BloomSize
    BloomEffect.Threshold         = VisualDefaults.BloomThresh
    BloomEffect.Enabled           = VisualDefaults.BloomEnabled

    if Atmosphere then
        pcall(function()
            Atmosphere.Density = VisualDefaults.AtmoDensity
            Atmosphere.Color   = VisualDefaults.AtmoColor
        end)
    end

    Options.VisualAmbient:SetValueRGB(VisualDefaults.Ambient)
    Options.VisualOutdoorAmbient:SetValueRGB(VisualDefaults.OutdoorAmb)
    Options.VisualFogColor:SetValueRGB(VisualDefaults.FogColor)
    Options.VisualFogStart:SetValue(math.floor(VisualDefaults.FogStart))
    Options.VisualFogEnd:SetValue(math.floor(math.min(VisualDefaults.FogEnd, 5000)))
    Options.VisualBloomIntensity:SetValue(VisualDefaults.BloomInt)
    Options.VisualBloomSize:SetValue(math.floor(VisualDefaults.BloomSize))
    Options.VisualBloomThreshold:SetValue(VisualDefaults.BloomThresh)
    Options.VisualBloomEnabled:SetValue(VisualDefaults.BloomEnabled)

    Notify("Visuals reset", 3)
end })

-- ============================================================
-- Draggable HUD
-- ============================================================
local HudLabel = Library:AddDraggableLabel({
    Text         = SCRIPT_NAME .. " | starting...",
    Icon         = "audio-lines",
    IconPosition = "left",
})

local FrameTimer, FrameCounter, FPS = tick(), 0, 60
local RenderConn = RunService.RenderStepped:Connect(function()
    FrameCounter += 1
    if tick() - FrameTimer >= 1 then
        FPS = FrameCounter
        FrameTimer = tick()
        FrameCounter = 0
    end
end)

local HudThread = task.spawn(function()
    while task.wait(1) do
        if State.Unloaded then break end

        local ping = 0
        pcall(function()
            ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)

        local track = CleanName(State.Current)
        if #track > 28 then track = track:sub(1, 25) .. "..." end

        HudLabel:SetText(string.format(
            "%s | %d FPS | %d ms | %s",
            SCRIPT_NAME, FPS, ping, track
        ))

        if NowPlayingLabel then
            NowPlayingLabel:SetText("Now playing: " .. track)
        end
    end
end)

-- ============================================================
-- Unload
-- ============================================================
local function Unload()
    if State.Unloaded then return end
    State.Unloaded = true

    pcall(function() Player:Stop() end)
    pcall(function() Player:Destroy() end)
    State.Queue = {}

    pcall(function() RenderConn:Disconnect() end)
    pcall(function() task.cancel(HudThread) end)
    pcall(function() HudLabel:Destroy() end)

    pcall(function()
        Lighting.ClockTime      = VisualDefaults.ClockTime
        Lighting.Brightness     = VisualDefaults.Brightness
        Lighting.Ambient        = VisualDefaults.Ambient
        Lighting.OutdoorAmbient = VisualDefaults.OutdoorAmb
        Lighting.FogStart       = VisualDefaults.FogStart
        Lighting.FogEnd         = VisualDefaults.FogEnd
        Lighting.FogColor       = VisualDefaults.FogColor
    end)

    pcall(function()
        BloomEffect.Intensity = VisualDefaults.BloomInt
        BloomEffect.Size      = VisualDefaults.BloomSize
        BloomEffect.Threshold = VisualDefaults.BloomThresh
        BloomEffect.Enabled   = VisualDefaults.BloomEnabled
    end)

    if Atmosphere then
        pcall(function()
            Atmosphere.Density = VisualDefaults.AtmoDensity
            Atmosphere.Color   = VisualDefaults.AtmoColor
        end)
    end

    pcall(function() Library:Unload() end)
end

local UIControlsBox = Tabs.UI:AddGroupbox({ Side = "Left", Name = "Controls", IconName = "power" })

UIControlsBox:AddButton({
    Text = "Unload CustomFlow",
    Risky = true,
    Func = Unload,
})

Library:OnUnload(function()
    if not State.Unloaded then
        State.Unloaded = true
        pcall(function() Player:Stop() end)
        pcall(function() Player:Destroy() end)
        pcall(function() RenderConn:Disconnect() end)
    end
end)

-- ============================================================
-- Addons
-- ============================================================
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()

ThemeManager:SetFolder(SCRIPT_NAME)
SaveManager:SetFolder(SCRIPT_NAME)

SaveManager:BuildConfigSection(Tabs.UI)
ThemeManager:ApplyToTab(Tabs.UI)

SaveManager:LoadAutoloadConfig()

Notify(SCRIPT_NAME .. " loaded. Music folder: " .. MUSIC_DIR, 5)
