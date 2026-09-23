-- Still vibecoded

-- ============ LOAD LIBRARY ============
local repo = "https://raw.githubusercontent.com/yenkgg/UE-Linoria-Lib/main/"

local Library       = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager  = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager   = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = getgenv().Options
local Toggles = getgenv().Toggles

-- ============ SERVICES ============
local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local UserInputService    = game:GetService("UserInputService")
local Lighting            = game:GetService("Lighting")
local Workspace           = game:GetService("Workspace")
local SoundService        = game:GetService("SoundService")
local TweenService        = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

-- ============ STATE ============
local espDrawings    = {}
local chamsOriginal  = {}
local weatherObj     = nil
local flyBodyVel     = nil
local flyBodyGyro    = nil
local colorCorrection = nil
local currentSound    = nil
local musicQueue      = {}
local aimState        = { target = nil, start = 0 }

-- ============ PRESERVE ORIGINALS ============
local orig = {
    ClockTime      = Lighting.ClockTime,
    FogColor       = Lighting.FogColor,
    FogStart       = Lighting.FogStart,
    FogEnd         = Lighting.FogEnd,
    Ambient        = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Brightness     = Lighting.Brightness,
}

-- ============ WINDOW ============
local Window = Library:CreateWindow({
    Title     = "customflow",
    Center    = true,
    AutoShow  = true,
    Resizable = true,
    NotifySide = "Left",
})

local Tabs = {
    Main   = Window:AddTab("main"),
    Visual = Window:AddTab("visual"),
    Misc   = Window:AddTab("misc"),
    Music  = Window:AddTab("music"),
    Scripts = Window:AddTab("scripts"),
    UISet  = Window:AddTab("ui settings"),
}

-- ============================================================
--                        MAIN TAB
-- ============================================================

-- ---------- AIMBOT ----------
local AimBox = Tabs.Main:AddLeftGroupbox("aimbot")

AimBox:AddToggle("AimbotToggle",        { Text = "aimbot",             Default = false })
AimBox:AddToggle("AimbotFovCheck",      { Text = "fov check",          Default = true  })
AimBox:AddSlider("AimbotFov",           { Text = "fov",                Default = 120, Min = 10, Max = 800, Rounding = 0 })
AimBox:AddSlider("AimbotSmoothness",    { Text = "smoothness (%)",     Default = 50,  Min = 0,  Max = 100, Rounding = 0 })
AimBox:AddToggle("AimbotTeamCheck",     { Text = "team check",         Default = true  })
AimBox:AddToggle("AimbotVisibleCheck",  { Text = "visible check",      Default = true  })
AimBox:AddSlider("AimbotReaction",      { Text = "reaction time (ms)", Default = 0,   Min = 0,  Max = 500, Rounding = 0 })
AimBox:AddLabel("bind"):AddKeyPicker("AimbotBind", { Default = "MB2", Mode = "Hold", Text = "aim keybind" })
AimBox:AddSlider("AimbotJitter",        { Text = "jitter",             Default = 0,   Min = 0,  Max = 10,  Rounding = 1 })
AimBox:AddSlider("AimbotJitterMs",      { Text = "jitter ms",          Default = 50,  Min = 0,  Max = 500, Rounding = 0 })
AimBox:AddLabel("fov color"):AddColorPicker("AimbotFovColor", { Default = Color3.fromRGB(215, 166, 176) })
AimBox:AddToggle("AimbotDistanceCheck", { Text = "distance check",     Default = false })
AimBox:AddSlider("AimbotDistance",      { Text = "distance (studs)",   Default = 300, Min = 10, Max = 2500, Rounding = 0 })
AimBox:AddDropdown("AimbotPart", {
    Text = "target part",
    Values = { "head", "uppertorso", "lowertorso", "humanoidrootpart" },
    Default = 1,
})

-- ---------- TRIGGERBOT ----------
local TbBox = Tabs.Main:AddRightGroupbox("triggerbot")

TbBox:AddToggle("TbToggle",           { Text = "triggerbot",                 Default = false })
TbBox:AddSlider("TbReaction",         { Text = "reaction time (ms)",         Default = 50,  Min = 0,   Max = 500,  Rounding = 0 })
TbBox:AddSlider("TbReactionOffset",   { Text = "reaction time offset (ms)",  Default = 0,   Min = -200, Max = 200, Rounding = 0 })
TbBox:AddToggle("TbDistanceCheck",    { Text = "distance check",             Default = false })
TbBox:AddSlider("TbDistance",         { Text = "distance (studs)",           Default = 300, Min = 10,  Max = 2500, Rounding = 0 })
TbBox:AddDropdown("TbPart", {
    Text = "work only at",
    Values = { "head", "uppertorso", "lowertorso", "humanoidrootpart" },
    Default = 1,
})
TbBox:AddToggle("TbTeamCheck",        { Text = "team check",                 Default = true })
TbBox:AddToggle("TbVisibleCheck",     { Text = "visible check",              Default = true })

-- ============================================================
--                       VISUAL TAB
-- ============================================================

-- ---------- ESP ----------
local EspBox = Tabs.Visual:AddLeftGroupbox("esp")

EspBox:AddToggle("EspToggle",     { Text = "esp",         Default = false })
EspBox:AddLabel("global color"):AddColorPicker("EspColor", { Default = Color3.fromRGB(255, 255, 255) })
EspBox:AddToggle("EspBox",        { Text = "box",         Default = true  })
EspBox:AddToggle("EspHealth",     { Text = "health bar",  Default = true  })
EspBox:AddToggle("EspDistance",   { Text = "distance",    Default = true  })
EspBox:AddToggle("EspTeamCheck",  { Text = "team check",  Default = false })
EspBox:AddToggle("EspEquipped",   { Text = "equipped",    Default = false })
EspBox:AddToggle("EspSkeleton",   { Text = "skeleton",    Default = false })
EspBox:AddToggle("EspFill",       { Text = "fill",        Default = false })

-- ---------- CHAMS ----------
local ChamsBox = Tabs.Visual:AddLeftGroupbox("chams")

ChamsBox:AddToggle("ChamsToggle",  { Text = "chams", Default = false })
ChamsBox:AddDropdown("ChamsMaterial", {
    Text = "material",
    Values = { "ForceField", "Neon", "Glass", "Plastic", "SmoothPlastic", "Metal", "Wood", "Marble", "Granite", "Concrete", "Ice" },
    Default = 1,
})
ChamsBox:AddLabel("color"):AddColorPicker("ChamsColor", { Default = Color3.fromRGB(215, 166, 176) })
ChamsBox:AddSlider("ChamsTransparency", { Text = "transparency", Default = 0, Min = 0, Max = 1, Rounding = 2 })

-- ---------- INFO ----------
local InfoBox = Tabs.Visual:AddLeftGroupbox("info")

InfoBox:AddToggle("InfoPing",    { Text = "ping",    Default = false })
InfoBox:AddToggle("InfoFps",     { Text = "fps",     Default = false })
InfoBox:AddToggle("InfoName",    { Text = "name",    Default = false })
InfoBox:AddLabel("color"):AddColorPicker("InfoColor", { Default = Color3.fromRGB(215, 166, 176) })
InfoBox:AddSlider("InfoX", { Text = "info x", Default = 20, Min = 0, Max = 1920, Rounding = 0 })
InfoBox:AddSlider("InfoY", { Text = "info y", Default = 20, Min = 0, Max = 1080, Rounding = 0 })
InfoBox:AddSlider("InfoSpacing", { Text = "line spacing", Default = 20, Min = 10, Max = 60, Rounding = 0 })

-- ---------- LIGHTING ----------
local LightBox = Tabs.Visual:AddRightGroupbox("lighting")

LightBox:AddToggle("ClockTimeToggle", { Text = "clocktime", Default = false })
LightBox:AddSlider("ClockTime",       { Text = "time (0-24h)", Default = 14, Min = 0, Max = 24, Rounding = 1 })

LightBox:AddToggle("FogToggle",  { Text = "fog", Default = false })
LightBox:AddLabel("fog color"):AddColorPicker("FogColor", { Default = Color3.fromRGB(200, 200, 200) })
LightBox:AddSlider("FogStart",   { Text = "fog start", Default = 0,   Min = 0, Max = 1000, Rounding = 0 })
LightBox:AddSlider("FogEnd",     { Text = "fog end",   Default = 500, Min = 0, Max = 10000, Rounding = 0 })

LightBox:AddToggle("AmbientToggle", { Text = "ambient", Default = false })
LightBox:AddLabel("ambient color"):AddColorPicker("AmbientColor", { Default = Color3.fromRGB(100, 100, 100) })

LightBox:AddSlider("Contrast",   { Text = "contrast",   Default = 0, Min = -1, Max = 1, Rounding = 2 })
LightBox:AddSlider("Saturation", { Text = "saturation", Default = 0, Min = -1, Max = 1, Rounding = 2 })

-- ---------- WEATHER ----------
local WeatherBox = Tabs.Visual:AddRightGroupbox("weather")

WeatherBox:AddDropdown("WeatherType", {
    Text = "weather",
    Values = { "none", "rain", "heavy rain", "snow" },
    Default = 1,
})
WeatherBox:AddSlider("WeatherLifetime",     { Text = "lifetime",     Default = 2,   Min = 0.5, Max = 10, Rounding = 1 })
WeatherBox:AddSlider("WeatherTransparency", { Text = "transparency", Default = 0.5, Min = 0,   Max = 1,  Rounding = 2 })
WeatherBox:AddLabel("color"):AddColorPicker("WeatherColor", { Default = Color3.fromRGB(200, 200, 255) })

-- ============================================================
--                        MISC TAB
-- ============================================================

local Misc1 = Tabs.Misc:AddLeftGroupbox("character")

Misc1:AddToggle("WalkSpeedToggle",  { Text = "walk speed",   Default = false })
Misc1:AddSlider("WalkSpeed",        { Text = "speed",        Default = 16, Min = 1, Max = 300, Rounding = 0 })
Misc1:AddToggle("JumpPowerToggle",  { Text = "jump power",   Default = false })
Misc1:AddSlider("JumpPower",        { Text = "power",        Default = 50, Min = 1, Max = 500, Rounding = 0 })
Misc1:AddToggle("InfiniteJump",     { Text = "infinite jump", Default = false })
Misc1:AddToggle("Noclip",           { Text = "noclip",       Default = false })
Misc1:AddToggle("Bhop",             { Text = "bhop",         Default = false })

local Misc2 = Tabs.Misc:AddRightGroupbox("movement")

Misc2:AddToggle("SpinToggle", { Text = "spin", Default = false })
Misc2:AddSlider("SpinSpeed",  { Text = "spin speed", Default = 10, Min = 1, Max = 100, Rounding = 0 })
Misc2:AddToggle("FlyToggle",  { Text = "fly",  Default = false })
Misc2:AddSlider("FlySpeed",   { Text = "fly speed",  Default = 50, Min = 5, Max = 400, Rounding = 0 })

-- ============================================================
--                        MUSIC TAB
-- ============================================================

local MUSIC_FOLDER = "CustomFlow music"

if not isfolder(MUSIC_FOLDER) then
    makefolder(MUSIC_FOLDER)
end

currentSound = Instance.new("Sound")
currentSound.Name   = "CustomFlow_Music"
currentSound.Volume = 1
currentSound.Looped = false
currentSound.Parent = Workspace

local musicFiles = {} -- name -> full path

local function refreshMusicMap()
    musicFiles = {}
    local out = {}
    local ok, files = pcall(function() return listfiles(MUSIC_FOLDER) end)
    if not ok or not files then return out end
    for _, path in ipairs(files) do
        local isDir = false
        pcall(function() isDir = isfolder(path) end)
        if not isDir then
            local name = path:match("([^/\\]+)$") or path
            musicFiles[name] = path
            table.insert(out, name)
        end
    end
    table.sort(out)
    return out
end

local function resolveAsset(fileName)
    if not fileName or fileName == "" then return nil end
    local path = musicFiles[fileName] or (MUSIC_FOLDER .. "/" .. fileName)
    local ok, id = pcall(getcustomasset, path)
    if ok and id then return id end
    return nil
end

local function playFileName(fileName)
    local id = resolveAsset(fileName)
    if not id then
        Library:Notify("не удалось загрузить: " .. tostring(fileName), 4)
        return
    end
    currentSound:Stop()
    currentSound.SoundId = id
    currentSound:Play()
end

local MusicPlayer = Tabs.Music:AddLeftGroupbox("player")

MusicPlayer:AddDropdown("MusicList", {
    Text = "track",
    Values = refreshMusicMap(),
    AllowNull = true,
})

MusicPlayer:AddButton({ Text = "refresh list", Func = function()
    Options.MusicList:SetValues(refreshMusicMap())
    Options.MusicList:SetValue(nil)
    Library:Notify("list refreshed", 3)
end })

MusicPlayer:AddButton({ Text = "play / pause", Func = function()
    if currentSound.IsPlaying then
        currentSound:Pause()
    elseif currentSound.TimePosition > 0 and currentSound.SoundId ~= "" then
        currentSound:Resume()
    elseif Options.MusicList.Value then
        playFileName(Options.MusicList.Value)
    end
end })

MusicPlayer:AddButton({ Text = "stop", Func = function()
    currentSound:Stop()
end })

MusicPlayer:AddButton({ Text = "play selected", Func = function()
    playFileName(Options.MusicList.Value)
end })

MusicPlayer:AddLabel("folder: workspace/" .. MUSIC_FOLDER, true)

local MusicSettings = Tabs.Music:AddRightGroupbox("settings")

MusicSettings:AddSlider("MusicVolume", { Text = "volume (db)", Default = 1, Min = 0.1, Max = 24, Rounding = 1 })
MusicSettings:AddToggle("MusicLoop",   { Text = "loop", Default = false })

MusicSettings:AddButton({ Text = "add current to queue", Func = function()
    local name = Options.MusicList.Value
    if name and name ~= "" then
        table.insert(musicQueue, name)
        Library:Notify("queued: " .. name, 3)
    end
end })

MusicSettings:AddButton({ Text = "clear queue", Func = function()
    musicQueue = {}
    Library:Notify("queue cleared", 3)
end })

MusicSettings:AddButton({ Text = "skip", Func = function()
    if #musicQueue > 0 then
        local nextName = table.remove(musicQueue, 1)
        playFileName(nextName)
    end
end })

MusicSettings:AddSlider("MusicSpeed", { Text = "speed", Default = 1, Min = 0.2, Max = 5, Rounding = 1 })
MusicSettings:AddSlider("MusicPitch", { Text = "pitch", Default = 1, Min = 0.2, Max = 5, Rounding = 1 })
MusicSettings:AddToggle("MusicWorkspaceColor", { Text = "color from workspace", Default = false })

Options.MusicVolume:OnChanged(function(v) currentSound.Volume = v end)
Toggles.MusicLoop:OnChanged(function(v) currentSound.Looped = v end)
Options.MusicSpeed:OnChanged(function(v) currentSound.PlaybackSpeed = v end)
Options.MusicPitch:OnChanged(function(v) currentSound.Pitch = v end)

currentSound.Ended:Connect(function()
    if #musicQueue > 0 then
        local nextName = table.remove(musicQueue, 1)
        playFileName(nextName)
    end
end)

Toggles.MusicWorkspaceColor:OnChanged(function(v)
    if v then
        local base = Lighting.Ambient
        if base == Color3.new(0, 0, 0) then base = Color3.fromRGB(80, 80, 80) end
        Library.AccentColor     = base
        Library.AccentColorDark = Library:GetDarkerColor(base)
        Library:UpdateColorsUsingRegistry()
    else
        if ThemeManager.Library then
            ThemeManager:ApplyTheme("Primordial")
        end
    end
end)

-- ============================================================
--                        SCRIPTS TAB
-- ============================================================

local ScriptsBox = Tabs.Scripts:AddLeftGroupbox("scripts")

local scriptsList = {
    {
        name = "infinite yield",
        url  = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",
        type = "loadstring",
    },
}

for _, entry in ipairs(scriptsList) do
    ScriptsBox:AddButton({
        Text = "load: " .. entry.name,
        Func = function()
            local ok, err = pcall(function()
                loadstring(game:HttpGet(entry.url))()
            end)
            if ok then
                Library:Notify("loaded " .. entry.name, 3)
            else
                Library:Notify("failed to load " .. entry.name .. ": " .. tostring(err), 5)
            end
        end,
        Tooltip = entry.url,
    })
end

ScriptsBox:AddDivider()

ScriptsBox:AddInput("ScriptsCustomUrl", {
    Text = "custom script url",
    Default = "",
    Placeholder = "https://...",
})

ScriptsBox:AddButton({
    Text = "load custom",
    Func = function()
        local url = Options.ScriptsCustomUrl.Value
        if not url or url == "" then
            Library:Notify("empty url", 3)
            return
        end
        local ok, err = pcall(function()
            loadstring(game:HttpGet(url))()
        end)
        if ok then
            Library:Notify("custom script loaded", 3)
        else
            Library:Notify("failed: " .. tostring(err), 5)
        end
        return
    end
})

-- ============================================================
--                     UI SETTINGS TAB
-- ============================================================

local MenuGroup = Tabs.UISet:AddLeftGroupbox("menu")

MenuGroup:AddButton({ Text = "unload", Func = function() Library:Unload() end })

local MenuGroupRight = Tabs.UISet:AddRightGroupbox("keybinds")
MenuGroupRight:AddLabel("menu keybind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "menu keybind" })

Library.ToggleKeybind = Options.MenuKeybind

-- ============ THEME & SAVE ============
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("CustomFlow")
SaveManager:SetFolder("CustomFlow")

ThemeManager:ApplyToTab(Tabs.UISet)
SaveManager:BuildConfigSection(Tabs.UISet)

SaveManager:LoadAutoloadConfig()

-- apply primordial
ThemeManager:ApplyTheme("Primordial")

-- ============================================================
--                        LOGIC
-- ============================================================

-- ---------- HELPERS ----------
local partMap = {
    ["head"]             = "Head",
    ["uppertorso"]       = "UpperTorso",
    ["lowertorso"]       = "LowerTorso",
    ["humanoidrootpart"] = "HumanoidRootPart",
}

local function getPartName(key)
    return partMap[string.lower(key)] or "HumanoidRootPart"
end

local function isVisible(targetPart)
    local origin = Camera.CFrame.Position
    local dir    = targetPart.Position - origin
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LocalPlayer.Character, targetPart.Parent }
    local hit = Workspace:Raycast(origin, dir, params)
    return hit == nil
end

local function getTarget(partName, fov, teamCheck, visCheck, distCheck, maxDist)
    local best, bestDist = nil, fov
    local mouse  = UserInputService:GetMouseLocation()
    local myTeam = LocalPlayer.Team

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        if teamCheck and plr.Team == myTeam then continue end
        local char = plr.Character
        if not char then continue end
        local part = char:FindFirstChild(partName)
        if not part then continue end

        local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end

        local d = (Vector2.new(mouse.X, mouse.Y) - Vector2.new(pos.X, pos.Y)).Magnitude
        if d > bestDist then continue end

        if distCheck then
            local studs = (part.Position - Camera.CFrame.Position).Magnitude
            if studs > maxDist then continue end
        end

        if visCheck and not isVisible(part) then continue end

        best, bestDist = part, d
    end
    return best
end

-- ---------- FOV CIRCLE ----------
local FovCircle = Drawing.new("Circle")
FovCircle.Thickness    = 1.5
FovCircle.NumSides     = 120
FovCircle.Filled       = false
FovCircle.Transparency = 1
FovCircle.Visible      = false

-- ---------- AIMBOT LOOP ----------
RunService.RenderStepped:Connect(function()
    -- fov circle
    if Toggles.AimbotFovCheck.Value and Toggles.AimbotToggle.Value then
        FovCircle.Visible  = true
        FovCircle.Position = UserInputService:GetMouseLocation()
        FovCircle.Radius   = Options.AimbotFov.Value
        FovCircle.Color    = Options.AimbotFovColor.Value
    else
        FovCircle.Visible = false
    end

    if not Toggles.AimbotToggle.Value then
        aimState.target = nil
        return
    end

    local holding = Options.AimbotBind:GetState()
    if not holding then
        aimState.target = nil
        aimState.start  = 0
        return
    end

    -- acquire target
    if not aimState.target or not aimState.target.Parent then
        aimState.target = getTarget(
            getPartName(Options.AimbotPart.Value),
            Options.AimbotFov.Value,
            Toggles.AimbotTeamCheck.Value,
            Toggles.AimbotVisibleCheck.Value,
            Toggles.AimbotDistanceCheck.Value,
            Options.AimbotDistance.Value
        )
        aimState.start = tick()
        return
    end

    -- reaction time
    if (tick() - aimState.start) < (Options.AimbotReaction.Value / 1000) then return end

    -- compute aim
    local targetPos = aimState.target.Position

    -- jitter
    if Options.AimbotJitter.Value > 0 then
        local j = Options.AimbotJitter.Value * 0.1
        targetPos = targetPos + Vector3.new(
            (math.random() - 0.5) * j,
            (math.random() - 0.5) * j,
            (math.random() - 0.5) * j
        )
    end

    local desired = CFrame.new(Camera.CFrame.Position, targetPos)
    local smooth  = Options.AimbotSmoothness.Value / 100
    Camera.CFrame = Camera.CFrame:Lerp(desired, 1 - smooth)
end)

-- ---------- TRIGGERBOT ----------
local trigBusy = false

RunService.Heartbeat:Connect(function()
    if not Toggles.TbToggle.Value or trigBusy then return end

    -- raycast from mouse
    local mouse = UserInputService:GetMouseLocation()
    local unit  = Camera:ViewportPointToRay(mouse.X, mouse.Y)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LocalPlayer.Character, Camera }
    local hit = Workspace:Raycast(unit.Origin, unit.Direction * 1000, params)

    if not hit or not hit.Instance then return end

    local model = hit.Instance:FindFirstAncestorOfClass("Model")
    if not model then return end

    local plr = Players:GetPlayerFromCharacter(model)
    if not plr or plr == LocalPlayer then return end

    if Toggles.TbTeamCheck.Value and plr.Team == LocalPlayer.Team then return end

    local hrp = model:FindFirstChild("HumanoidRootPart")
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid or humanoid.Health <= 0 then return end

    if Toggles.TbDistanceCheck.Value then
        local d = (hrp.Position - Camera.CFrame.Position).Magnitude
        if d > Options.TbDistance.Value then return end
    end

    if Toggles.TbVisibleCheck.Value and not isVisible(hit.Instance) then return end

    local partName = getPartName(Options.TbPart.Value)
    if hit.Instance.Name ~= partName then return end

    trigBusy = true
    local delay = (Options.TbReaction.Value + Options.TbReactionOffset.Value) / 1000
    if delay > 0 then task.wait(delay) end

    VirtualInputManager:SendMouseButtonEvent(mouse.X, mouse.Y, 0, true,  game, 1)
    task.wait(0.01)
    VirtualInputManager:SendMouseButtonEvent(mouse.X, mouse.Y, 0, false, game, 1)

    task.wait(0.05)
    trigBusy = false
end)

-- ============================================================
--                           ESP
-- ============================================================

local function createEsp(plr)
    local d = {
        box      = Drawing.new("Square"),
        fill     = Drawing.new("Square"),
        hpBg     = Drawing.new("Square"),
        hpBar    = Drawing.new("Square"),
        nameTag  = Drawing.new("Text"),
        distTag  = Drawing.new("Text"),
        skel     = {},
    }

    d.box.Thickness    = 1
    d.box.Filled       = false
    d.box.Transparency = 1

    d.fill.Filled       = true
    d.fill.Transparency = 0.7

    d.hpBg.Filled       = true
    d.hpBg.Transparency = 0.5

    d.hpBar.Filled       = true
    d.hpBar.Transparency = 0

    d.nameTag.Size    = 14
    d.nameTag.Center  = true
    d.nameTag.Outline = true

    d.distTag.Size    = 13
    d.distTag.Center  = true
    d.distTag.Outline = true

    for i = 1, 12 do
        local line = Drawing.new("Line")
        line.Thickness    = 1
        line.Transparency = 1
        table.insert(d.skel, line)
    end

    espDrawings[plr] = d
    return d
end

local function destroyEsp(plr)
    local d = espDrawings[plr]
    if not d then return end
    pcall(function() d.box:Remove() end)
    pcall(function() d.fill:Remove() end)
    pcall(function() d.hpBg:Remove() end)
    pcall(function() d.hpBar:Remove() end)
    pcall(function() d.nameTag:Remove() end)
    pcall(function() d.distTag:Remove() end)
    for _, l in ipairs(d.skel) do pcall(function() l:Remove() end) end
    espDrawings[plr] = nil
end

local function hideEsp(d)
    d.box.Visible     = false
    d.fill.Visible    = false
    d.hpBg.Visible    = false
    d.hpBar.Visible   = false
    d.nameTag.Visible = false
    d.distTag.Visible = false
    for _, l in ipairs(d.skel) do l.Visible = false end
end

local function updateEsp(plr, d)
    local char = plr.Character
    if not char then hideEsp(d); return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then hideEsp(d); return end

    if Toggles.EspTeamCheck.Value and plr.Team == LocalPlayer.Team then
        hideEsp(d); return
    end

    if Toggles.EspEquipped.Value then
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then hideEsp(d); return end
    end

    local top, bottom = hrp, hrp
    local head = char:FindFirstChild("Head")
    if head then top = head end

    local topPos    = Camera:WorldToViewportPoint(top.Position + Vector3.new(0, top.Size.Y * 0.5 + 0.4, 0))
    local bottomPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))

    if topPos.Z < 0 or bottomPos.Z < 0 then hideEsp(d); return end

    local h = math.abs(bottomPos.Y - topPos.Y)
    local w = h / 1.8
    local x = topPos.X - w / 2
    local y = topPos.Y

    local col = Options.EspColor.Value

    -- box
    if Toggles.EspBox.Value then
        d.box.Visible     = true
        d.box.Color       = col
        d.box.Position    = Vector2.new(x, y)
        d.box.Size        = Vector2.new(w, h)
    else
        d.box.Visible = false
    end

    -- fill
    if Toggles.EspFill.Value then
        d.fill.Visible     = true
        d.fill.Color       = col
        d.fill.Position    = Vector2.new(x, y)
        d.fill.Size        = Vector2.new(w, h)
        d.fill.Transparency = 0.75
    else
        d.fill.Visible = false
    end

    -- health bar
    if Toggles.EspHealth.Value then
        local hpFrac = hum.Health / hum.MaxHealth
        d.hpBg.Visible     = true
        d.hpBg.Color       = Color3.new(0, 0, 0)
        d.hpBg.Position    = Vector2.new(x - 5, y)
        d.hpBg.Size        = Vector2.new(3, h)

        d.hpBar.Visible     = true
        d.hpBar.Color       = Color3.fromRGB(50, 255, 50):Lerp(Color3.fromRGB(255, 50, 50), 1 - hpFrac)
        d.hpBar.Position    = Vector2.new(x - 5, y + h * (1 - hpFrac))
        d.hpBar.Size        = Vector2.new(3, h * hpFrac)
    else
        d.hpBg.Visible  = false
        d.hpBar.Visible = false
    end

    -- name
    d.nameTag.Visible  = true
    d.nameTag.Color    = col
    d.nameTag.Position = Vector2.new(x + w / 2, y - 16)
    d.nameTag.Text     = plr.Name

    -- distance
    if Toggles.EspDistance.Value then
        local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
        d.distTag.Visible  = true
        d.distTag.Color    = col
        d.distTag.Position = Vector2.new(x + w / 2, y + h + 2)
        d.distTag.Text     = string.format("%d studs", math.floor(dist))
    else
        d.distTag.Visible = false
    end

    -- skeleton
    if Toggles.EspSkeleton.Value then
        local parts = {
            char:FindFirstChild("Head"),
            char:FindFirstChild("HumanoidRootPart"),
            char:FindFirstChild("LeftHand") or char:FindFirstChild("Left Arm"),
            char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm"),
            char:FindFirstChild("LeftFoot") or char:FindFirstChild("Left Leg"),
            char:FindFirstChild("RightFoot") or char:FindFirstChild("Right Leg"),
        }
        local bones = {
            {1, 2}, {2, 3}, {2, 4}, {2, 5}, {2, 6}
        }
        for i, line in ipairs(d.skel) do
            local bone = bones[i]
            if bone then
                local a, b = parts[bone[1]], parts[bone[2]]
                if a and b then
                    local aP = Camera:WorldToViewportPoint(a.Position)
                    local bP = Camera:WorldToViewportPoint(b.Position)
                    line.Visible = true
                    line.Color   = col
                    line.From    = Vector2.new(aP.X, aP.Y)
                    line.To      = Vector2.new(bP.X, bP.Y)
                else
                    line.Visible = false
                end
            else
                line.Visible = false
            end
        end
    else
        for _, l in ipairs(d.skel) do l.Visible = false end
    end
end

Players.PlayerAdded:Connect(function(plr)
    if not espDrawings[plr] then createEsp(plr) end
end)
Players.PlayerRemoving:Connect(function(plr) destroyEsp(plr) end)

for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then createEsp(plr) end
end

RunService.RenderStepped:Connect(function()
    for plr, d in pairs(espDrawings) do
        if Toggles.EspToggle.Value and plr ~= LocalPlayer then
            updateEsp(plr, d)
        else
            hideEsp(d)
        end
    end
end)

-- ============================================================
--                        CHAMS
-- ============================================================

local function applyChams(plr)
    local char = plr.Character
    if not char or plr == LocalPlayer then return end

    chamsOriginal[plr] = {}
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            chamsOriginal[plr][p] = {
                Material     = p.Material,
                Color        = p.Color,
                Transparency = p.Transparency,
            }
            p.Material     = Enum.Material[Options.ChamsMaterial.Value]
            p.Color        = Options.ChamsColor.Value
            p.Transparency = Options.ChamsTransparency.Value
        end
    end
end

local function removeChams(plr)
    local char = plr and plr.Character
    if not char or not chamsOriginal[plr] then return end
    for p, data in pairs(chamsOriginal[plr]) do
        if p and p.Parent then
            p.Material     = data.Material
            p.Color        = data.Color
            p.Transparency = data.Transparency
        end
    end
    chamsOriginal[plr] = nil
end

local function refreshChamsAll()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            removeChams(plr)
            if Toggles.ChamsToggle.Value then applyChams(plr) end
        end
    end
    if LocalPlayer.Character and Toggles.ChamsToggle.Value then
        applyChams(LocalPlayer)
    end
end

Toggles.ChamsToggle:OnChanged(function(v)
    refreshChamsAll()
end)
Options.ChamsMaterial:OnChanged(function() refreshChamsAll() end)
Options.ChamsColor:OnChanged(function() refreshChamsAll() end)
Options.ChamsTransparency:OnChanged(function() refreshChamsAll() end)

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(1)
        if Toggles.ChamsToggle.Value then applyChams(plr) end
    end)
end)

-- ============================================================
--                        LIGHTING
-- ============================================================

colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Name    = "CustomFlow_CC"
colorCorrection.Enabled = false
colorCorrection.Parent  = Lighting

Toggles.ClockTimeToggle:OnChanged(function()
    if Toggles.ClockTimeToggle.Value then
        Lighting.ClockTime = Options.ClockTime.Value
    else
        Lighting.ClockTime = orig.ClockTime
    end
end)

Options.ClockTime:OnChanged(function(v)
    if Toggles.ClockTimeToggle.Value then
        Lighting.ClockTime = v
    end
end)

Toggles.FogToggle:OnChanged(function()
    if Toggles.FogToggle.Value then
        Lighting.FogColor = Options.FogColor.Value
        Lighting.FogStart = Options.FogStart.Value
        Lighting.FogEnd   = Options.FogEnd.Value
    else
        Lighting.FogColor = orig.FogColor
        Lighting.FogStart = orig.FogStart
        Lighting.FogEnd   = orig.FogEnd
    end
end)

Options.FogColor:OnChanged(function(v)
    if Toggles.FogToggle.Value then Lighting.FogColor = v end
end)
Options.FogStart:OnChanged(function(v)
    if Toggles.FogToggle.Value then Lighting.FogStart = v end
end)
Options.FogEnd:OnChanged(function(v)
    if Toggles.FogToggle.Value then Lighting.FogEnd = v end
end)

Toggles.AmbientToggle:OnChanged(function()
    if Toggles.AmbientToggle.Value then
        Lighting.Ambient        = Options.AmbientColor.Value
        Lighting.OutdoorAmbient = Options.AmbientColor.Value
    else
        Lighting.Ambient        = orig.Ambient
        Lighting.OutdoorAmbient = orig.OutdoorAmbient
    end
end)

Options.AmbientColor:OnChanged(function(v)
    if Toggles.AmbientToggle.Value then
        Lighting.Ambient        = v
        Lighting.OutdoorAmbient = v
    end
end)

Options.Contrast:OnChanged(function(v)
    colorCorrection.Enabled   = (v ~= 0) or (Options.Saturation.Value ~= 0)
    colorCorrection.Contrast  = v
end)
Options.Saturation:OnChanged(function(v)
    colorCorrection.Enabled    = (v ~= 0) or (Options.Contrast.Value ~= 0)
    colorCorrection.Saturation = v
end)

-- ============================================================
--                        WEATHER
-- ============================================================

local function clearWeather()
    if weatherObj then
        pcall(function() weatherObj:Destroy() end)
        weatherObj = nil
    end
end

local function applyWeather()
    clearWeather()
    local mode = Options.WeatherType.Value
    if mode == "none" then return end

    local attachment = Instance.new("Attachment")
    attachment.Name = "CustomFlow_WeatherAttach"
    attachment.Parent = Camera

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name              = "CustomFlow_Weather"
    emitter.LightEmission     = 1
    emitter.LightInfluence    = 0
    emitter.Rate              = 200
    emitter.Lifetime          = NumberRange.new(Options.WeatherLifetime.Value)
    emitter.Speed             = NumberRange.new(60, 90)
    emitter.Rotation          = NumberRange.new(0)
    emitter.RotSpeed          = NumberRange.new(0)
    emitter.Transparency      = NumberSequence.new(Options.WeatherTransparency.Value)
    emitter.Color             = ColorSequence.new(Options.WeatherColor.Value)
    emitter.Size              = NumberSequence.new(0.15)
    emitter.Texture           = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.EmissionDirection = Enum.NormalId.Bottom
    emitter.SpreadAngle       = Vector2.new(0, 0)
    emitter.Parent            = attachment

    if mode == "rain" then
        emitter.Rate = 300
        emitter.Size = NumberSequence.new(0.08)
        emitter.Speed = NumberRange.new(70, 110)
    elseif mode == "heavy rain" then
        emitter.Rate = 900
        emitter.Size = NumberSequence.new(0.1)
        emitter.Speed = NumberRange.new(110, 160)
    elseif mode == "snow" then
        emitter.Rate = 200
        emitter.Size = NumberSequence.new(0.25)
        emitter.Speed = NumberRange.new(5, 15)
        emitter.SpreadAngle = Vector2.new(20, 20)
    end

    weatherObj = attachment
end

Options.WeatherType:OnChanged(function() applyWeather() end)
Options.WeatherLifetime:OnChanged(function()
    if weatherObj then
        local e = weatherObj:FindFirstChild("CustomFlow_Weather")
        if e then e.Lifetime = NumberRange.new(Options.WeatherLifetime.Value) end
    end
end)
Options.WeatherTransparency:OnChanged(function()
    if weatherObj then
        local e = weatherObj:FindFirstChild("CustomFlow_Weather")
        if e then e.Transparency = NumberSequence.new(Options.WeatherTransparency.Value) end
    end
end)
Options.WeatherColor:OnChanged(function(v)
    if weatherObj then
        local e = weatherObj:FindFirstChild("CustomFlow_Weather")
        if e then e.Color = ColorSequence.new(v) end
    end
end)

-- ============================================================
--                         MISC
-- ============================================================

local function getChar()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHum()
    local char = getChar()
    return char:WaitForChild("Humanoid")
end

-- walk speed
Toggles.WalkSpeedToggle:OnChanged(function()
    if Toggles.WalkSpeedToggle.Value then
        local hum = getHum()
        hum.WalkSpeed = Options.WalkSpeed.Value
    else
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end)
Options.WalkSpeed:OnChanged(function(v)
    if Toggles.WalkSpeedToggle.Value then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
    end
end)

-- jump power
Toggles.JumpPowerToggle:OnChanged(function()
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if Toggles.JumpPowerToggle.Value then
        hum.UseJumpPower = true
        hum.JumpPower    = Options.JumpPower.Value
    else
        hum.UseJumpPower = false
        hum.JumpPower    = 50
    end
end)
Options.JumpPower:OnChanged(function(v)
    if Toggles.JumpPowerToggle.Value then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = v end
    end
end)

-- infinite jump
UserInputService.JumpRequest:Connect(function()
    if not Toggles.InfiniteJump.Value then return end
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

-- noclip
RunService.Stepped:Connect(function()
    if not Toggles.Noclip.Value then return end
    local char = LocalPlayer.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide then
            p.CanCollide = false
        end
    end
end)

-- bhop
RunService.Heartbeat:Connect(function()
    if not Toggles.Bhop.Value then return end
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if hum.MoveDirection.Magnitude > 0 and hum:GetState() == Enum.HumanoidStateType.Running then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- spin
RunService.RenderStepped:Connect(function(dt)
    if not Toggles.SpinToggle.Value then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(Options.SpinSpeed.Value) * dt * 60, 0)
    end
end)

-- fly
local flyConn = nil
local flyBV   = nil
local flyBG   = nil

local function stopFly()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local vel = hrp:FindFirstChild("CustomFlow_FlyVel"); if vel then vel:Destroy() end
            local gyro = hrp:FindFirstChild("CustomFlow_FlyGyro"); if gyro then gyro:Destroy() end
        end
    end
end

local function startFly()
    stopFly()
    local char = getChar()
    local hrp  = char:WaitForChild("HumanoidRootPart")

    local bv = Instance.new("BodyVelocity")
    bv.Name       = "CustomFlow_FlyVel"
    bv.MaxForce   = Vector3.new(1e5, 1e5, 1e5)
    bv.Velocity   = Vector3.zero
    bv.Parent     = hrp

    local bg = Instance.new("BodyGyro")
    bg.Name       = "CustomFlow_FlyGyro"
    bg.MaxTorque  = Vector3.new(1e5, 1e5, 1e5)
    bg.P           = 1000
    bg.D           = 50
    bg.CFrame      = hrp.CFrame
    bg.Parent      = hrp

    flyBV = bv
    flyBG = bg

    flyConn = RunService.RenderStepped:Connect(function()
        if not Toggles.FlyToggle.Value then return end
        local cam = Camera
        local dir = Vector3.zero

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0, 1, 0) end

        bv.Velocity = dir.Magnitude > 0 and dir.Unit * Options.FlySpeed.Value or Vector3.zero
        bg.CFrame   = CFrame.new(hrp.Position, hrp.Position + cam.CFrame.LookVector)
    end)
end

Toggles.FlyToggle:OnChanged(function()
    if Toggles.FlyToggle.Value then startFly() else stopFly() end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if Toggles.FlyToggle.Value then startFly() end
end)

-- ============================================================
--                        MUSIC
-- ============================================================

Options.MusicVolume:OnChanged(function(v) currentSound.Volume = v end)
Toggles.MusicLoop:OnChanged(function(v) currentSound.Looped = v end)
Options.MusicSpeed:OnChanged(function(v) currentSound.PlaybackSpeed = v end)
Options.MusicPitch:OnChanged(function(v) currentSound.Pitch = v end)

currentSound.Ended:Connect(function()
    if #musicQueue > 0 then
        local nextId = table.remove(musicQueue, 1)
        currentSound.SoundId = "rbxassetid://" .. nextId
        currentSound:Play()
    end
end)

-- ============================================================
--                      INFO OVERLAY
-- ============================================================

local infoPing = Drawing.new("Text")
infoPing.Size    = 16
infoPing.Outline = true
infoPing.Color   = Options.InfoColor.Value

local infoFps = Drawing.new("Text")
infoFps.Size    = 16
infoFps.Outline = true
infoFps.Color   = Options.InfoColor.Value

local infoName = Drawing.new("Text")
infoName.Size    = 16
infoName.Outline = true
infoName.Color   = Options.InfoColor.Value

local infoFpsTimer = tick()
local infoFpsCount = 0
local infoFpsValue = 0

local infoConn = RunService.RenderStepped:Connect(function()
    infoFpsCount += 1
    if (tick() - infoFpsTimer) >= 1 then
        infoFpsValue = infoFpsCount
        infoFpsTimer = tick()
        infoFpsCount = 0
    end

    local col = Options.InfoColor.Value
    local x   = Options.InfoX.Value
    local y   = Options.InfoY.Value
    local sp  = Options.InfoSpacing.Value

    infoPing.Visible = false
    infoFps.Visible  = false
    infoName.Visible = false

    local row = 0

    if Toggles.InfoPing.Value then
        local ok, ping = pcall(function()
            return math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        infoPing.Color    = col
        infoPing.Position = Vector2.new(x, y + row * sp)
        infoPing.Text     = "ping: " .. (ok and ping or 0)
        infoPing.Visible  = true
        row += 1
    end

    if Toggles.InfoFps.Value then
        infoFps.Color    = col
        infoFps.Position = Vector2.new(x, y + row * sp)
        infoFps.Text     = "fps: " .. infoFpsValue
        infoFps.Visible  = true
        row += 1
    end

    if Toggles.InfoName.Value then
        infoName.Color    = col
        infoName.Position = Vector2.new(x, y + row * sp)
        infoName.Text     = "name: " .. LocalPlayer.Name
        infoName.Visible  = true
    end
end)

Toggles.MusicWorkspaceColor:OnChanged(function(v)
    if v then
        local ambient = Lighting.Ambient
        Library.AccentColor = ambient
        Library.AccentColorDark = Library:GetDarkerColor(ambient)
        Library:UpdateColorsUsingRegistry()
    else
        ThemeManager:ApplyTheme("Primordial")
    end
end)

-- ============================================================
--                    CLEANUP ON UNLOAD
-- ============================================================

Library:OnUnload(function()
    if infoConn then infoConn:Disconnect() end
    pcall(function() infoPing:Remove() end)
    pcall(function() infoFps:Remove()  end)
    pcall(function() infoName:Remove() end)
    -- restore lighting
    Lighting.ClockTime      = orig.ClockTime
    Lighting.FogColor       = orig.FogColor
    Lighting.FogStart       = orig.FogStart
    Lighting.FogEnd         = orig.FogEnd
    Lighting.Ambient        = orig.Ambient
    Lighting.OutdoorAmbient = orig.OutdoorAmbient

    if colorCorrection then colorCorrection:Destroy() end
    clearWeather()
    stopFly()
    refreshChamsAll()

    for _, plr in ipairs(Players:GetPlayers()) do
        destroyEsp(plr)
    end

    if currentSound then currentSound:Destroy() end
    FovCircle:Remove()
end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
Library:Notify("customflow loaded", 3)
