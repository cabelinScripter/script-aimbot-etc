--[[
    LEGIT PANEL - ULTIMATE EDITION v3.0
    Enhanced with: Team ESP, Weapon ESP, Chams, Radar, Notification System
    Fully optimized with error handling and clean code structure
]]

--// 1. SERVICES & OPTIMIZATION //--
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Cache global functions for performance
local Vector2_new = Vector2.new
local Vector3_new = Vector3.new
local Color3_fromRGB = Color3.fromRGB
local Color3_new = Color3.new
local CFrame_new = CFrame.new
local math_floor = math.floor
local math_clamp = math.clamp
local math_abs = math.abs
local math_huge = math.huge
local math_atan2 = math.atan2
local math_cos = math.cos
local math_sin = math.sin
local table_insert = table.insert
local table_remove = table.remove
local pairs = pairs
local ipairs = ipairs
local task_wait = task.wait
local task_spawn = task.spawn

-- Safe Drawing check
if not (Drawing and typeof(Drawing) == "table") then
    warn("Drawing API not supported!")
    return
end

--// 2. LIBRARY LOADING //--
local Library, ThemeManager, SaveManager
local Repo = 'https://raw.githubusercontent.com/violnes/LinoriaLib/main/'

local function LoadLibrary()
    local success, err = pcall(function()
        Library = loadstring(game:HttpGet(Repo .. 'Library.lua'))()
        ThemeManager = loadstring(game:HttpGet(Repo .. 'addons/ThemeManager.lua'))()
        SaveManager = loadstring(game:HttpGet(Repo .. 'addons/SaveManager.lua'))()
    end)
    
    if not success then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "LEGIT PANEL",
            Text = "Failed to load library: " .. tostring(err),
            Duration = 5
        })
        return false
    end
    return true
end

if not LoadLibrary() then return end

--// 3. VARIABLES & TABLES //--
local ESP_Cache = {}
local Connections = {}
local HitboxCache = {}
local ChamsCache = {}
local RadarEntries = {}
local Notifications = {}
local ScreenSize = Camera.ViewportSize

-- Dynamic FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3_fromRGB(255, 255, 255)
FOVCircle.Thickness = 1
FOVCircle.NumSides = 64
FOVCircle.Filled = false
FOVCircle.Transparency = 1
FOVCircle.Visible = false
FOVCircle.Radius = 120
FOVCircle.Position = Vector2_new(ScreenSize.X / 2, ScreenSize.Y / 2)

-- Radar Circle
local RadarCircle = Drawing.new("Circle")
RadarCircle.Color = Color3_fromRGB(50, 50, 50)
RadarCircle.Thickness = 2
RadarCircle.NumSides = 64
RadarCircle.Filled = true
RadarCircle.Transparency = 0.3
RadarCircle.Visible = false
RadarCircle.Radius = 100
RadarCircle.Position = Vector2_new(120, 120)

--// 4. WINDOW & MENU SETUP //--
local Window = Library:CreateWindow({
    Title = "LEGIT PANEL | Ultimate v3.0",
    Center = true,
    AutoShow = true,
    Resizable = false,
    ShowCustomCursor = true,
    TabPadding = 8,
    MenuFadeTime = 0.15
})

local Tabs = {
    Legit = Window:AddTab("Legit"),
    Visuals = Window:AddTab("Visuals"),
    Hitboxes = Window:AddTab("Hitboxes"),
    Trigger = Window:AddTab("Trigger"),
    Misc = Window:AddTab("Misc"),
    Settings = Window:AddTab("Settings")
}

--// 5. UI CONSTRUCTION //--

-- [TAB: LEGIT]
local AimGroup = Tabs.Legit:AddLeftGroupbox("Aimbot")
local AimSettings = Tabs.Legit:AddRightGroupbox("Aimbot Settings")

AimGroup:AddToggle("AimbotEnabled", { 
    Text = "Enable Aimbot", 
    Default = false 
}):AddColorPicker("FOVColor", { 
    Default = Color3_fromRGB(255, 255, 255), 
    Title = "FOV Circle Color" 
})

AimGroup:AddToggle("AimbotToggle", {
    Text = "Toggle Mode",
    Default = false,
    Tooltip = "Toggle aimbot instead of hold key"
})

AimGroup:AddToggle("StickyAim", { 
    Text = "Sticky Aim", 
    Default = false,
    Tooltip = "Maintains lock on target" 
})

AimGroup:AddToggle("VisibleCheck", { 
    Text = "Wall Check", 
    Default = true,
    Tooltip = "Only aim at visible enemies" 
})

AimGroup:AddToggle("AliveCheck", { 
    Text = "Alive Check", 
    Default = true 
})

AimGroup:AddToggle("TeamCheck", { 
    Text = "Team Check", 
    Default = true 
})

AimGroup:AddDropdown("AimPart", { 
    Text = "Aim Part", 
    Values = {"Head", "UpperTorso", "HumanoidRootPart", "Random"}, 
    Default = 1
})

AimGroup:AddKeyPicker("AimKey", { 
    Text = "Aim Key", 
    Default = "MouseButton2", 
    Mode = "Toggle" 
})

AimSettings:AddToggle("ShowFOV", { 
    Text = "Show FOV", 
    Default = true 
})

AimSettings:AddSlider("FOVSize", { 
    Text = "FOV Radius", 
    Min = 10, 
    Max = 600, 
    Default = 120, 
    Rounding = 0 
})

AimSettings:AddSlider("Smoothness", { 
    Text = "Smoothness", 
    Min = 1, 
    Max = 30, 
    Default = 8, 
    Rounding = 1,
    Tooltip = "Higher = smoother movement" 
})

AimSettings:AddSlider("Prediction", { 
    Text = "Prediction", 
    Min = 0, 
    Max = 2, 
    Default = 0.165, 
    Rounding = 3,
    Tooltip = "Movement prediction" 
})

-- [TAB: VISUALS]
local ESPMain = Tabs.Visuals:AddLeftGroupbox("ESP Settings")
local ESPOptions = Tabs.Visuals:AddRightGroupbox("ESP Options")

ESPMain:AddToggle("ESPEnabled", { 
    Text = "Enable ESP", 
    Default = true 
})

ESPMain:AddToggle("ESP_Teammates", { 
    Text = "Show Teammates", 
    Default = false 
})

ESPMain:AddToggle("ESP_Box", { 
    Text = "Box ESP", 
    Default = true 
}):AddColorPicker("BoxColor", { 
    Default = Color3_fromRGB(255, 0, 0), 
    Title = "Box Color" 
})

ESPMain:AddToggle("ESP_Skeleton", { 
    Text = "Skeleton", 
    Default = false 
}):AddColorPicker("SkelColor", { 
    Default = Color3_fromRGB(255, 255, 255), 
    Title = "Skeleton Color" 
})

ESPMain:AddToggle("ESP_Name", { 
    Text = "Player Name", 
    Default = true 
})

ESPMain:AddToggle("ESP_Health", { 
    Text = "Health Bar", 
    Default = true 
})

ESPMain:AddToggle("ESP_Distance", { 
    Text = "Distance", 
    Default = true 
})

ESPMain:AddToggle("ESP_Weapon", { 
    Text = "Weapon ESP", 
    Default = false 
})

ESPMain:AddToggle("ESP_Tracer", { 
    Text = "Line Tracer", 
    Default = false 
})

ESPOptions:AddToggle("ChamsEnabled", {
    Text = "Enable Chams",
    Default = false
}):AddColorPicker("ChamsColor", {
    Default = Color3_fromRGB(255, 0, 0),
    Title = "Chams Color"
})

ESPOptions:AddSlider("ChamsTransparency", {
    Text = "Chams Transparency",
    Min = 0,
    Max = 1,
    Default = 0.5,
    Rounding = 2
})

ESPOptions:AddSlider("ESP_TextSize", {
    Text = "Text Size",
    Min = 8,
    Max = 20,
    Default = 13,
    Rounding = 0
})

ESPOptions:AddToggle("ESP_TextOutline", {
    Text = "Text Outline",
    Default = true
})

-- [TAB: HITBOXES]
local HitGroup = Tabs.Hitboxes:AddLeftGroupbox("Hitbox Expander")

HitGroup:AddToggle("HitboxEnabled", { 
    Text = "Enable Hitbox Expander", 
    Default = false 
})

HitGroup:AddDropdown("HitboxPart", { 
    Text = "Target Part", 
    Values = {"Head", "HumanoidRootPart", "UpperTorso"}, 
    Default = 1 
})

HitGroup:AddSlider("HitboxSize", { 
    Text = "Expand Size", 
    Min = 0.1, 
    Max = 10, 
    Default = 1.5, 
    Rounding = 1 
})

HitGroup:AddSlider("HitboxTrans", { 
    Text = "Transparency", 
    Min = 0, 
    Max = 1, 
    Default = 0.7, 
    Rounding = 2 
})

-- [TAB: TRIGGER]
local TrigGroup = Tabs.Trigger:AddLeftGroupbox("Triggerbot")

TrigGroup:AddToggle("TriggerEnabled", { 
    Text = "Enable Triggerbot", 
    Default = false 
})

TrigGroup:AddKeyPicker("TriggerKey", { 
    Text = "Trigger Key", 
    Default = "MouseButton1", 
    Mode = "Hold" 
})

TrigGroup:AddSlider("TriggerDelay", { 
    Text = "Reaction Delay (ms)", 
    Min = 0, 
    Max = 500, 
    Default = 50, 
    Rounding = 0 
})

TrigGroup:AddSlider("TriggerRange", { 
    Text = "Max Distance", 
    Min = 10, 
    Max = 2000, 
    Default = 500, 
    Rounding = 0 
})

-- [TAB: MISC]
local MiscGroup = Tabs.Misc:AddLeftGroupbox("Miscellaneous")
local RadarGroup = Tabs.Misc:AddRightGroupbox("Radar")

MiscGroup:AddToggle("NoRecoil", {
    Text = "No Recoil",
    Default = false,
    Tooltip = "Reduces weapon recoil"
})

MiscGroup:AddToggle("NoSpread", {
    Text = "No Spread",
    Default = false,
    Tooltip = "Reduces weapon spread"
})

MiscGroup:AddToggle("FastReload", {
    Text = "Fast Reload",
    Default = false
})

MiscGroup:AddToggle("SpeedHack", {
    Text = "Speed Hack",
    Default = false
}):AddSlider("SpeedMultiplier", {
    Text = "Speed Multiplier",
    Min = 1,
    Max = 5,
    Default = 1.5,
    Rounding = 1
})

RadarGroup:AddToggle("RadarEnabled", {
    Text = "Enable Radar",
    Default = false
})

RadarGroup:AddSlider("RadarSize", {
    Text = "Radar Size",
    Min = 50,
    Max = 300,
    Default = 100,
    Rounding = 0
})

RadarGroup:AddSlider("RadarRange", {
    Text = "Radar Range",
    Min = 50,
    Max = 500,
    Default = 200,
    Rounding = 0
})

RadarGroup:AddToggle("RadarShowNames", {
    Text = "Show Names",
    Default = true
})

-- [TAB: SETTINGS]
local MenuSettings = Tabs.Settings:AddLeftGroupbox("Menu Configuration")
MenuSettings:AddButton("Unload Cheat", function() 
    Library:Unload() 
end)

MenuSettings:AddLabel("Menu Toggle Key"):AddKeyPicker("MenuKey", { 
    Default = "RightShift", 
    NoUI = false, 
    Text = "Menu Key",
    Mode = "Toggle"
})

ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("LegitPanel")
ThemeManager:ApplyToTab(Tabs.Settings)

SaveManager:SetLibrary(Library)
SaveManager:SetFolder("LegitPanel")
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

--// 6. HELPER FUNCTIONS //--

local function Notify(title, text, duration)
    duration = duration or 3
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration
    })
end

local function IsAlive(player)
    if not player or not player.Character then return false end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    local root = player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then return false end
    return humanoid.Health > 0
end

local function IsTeammate(player)
    if not Toggles.TeamCheck.Value then return false end
    return player.Team == LocalPlayer.Team
end

local function GetScreenPosition(position)
    local screenPos, visible = Camera:WorldToViewportPoint(position)
    return Vector2_new(screenPos.X, screenPos.Y), visible, screenPos.Z
end

local function RaycastCheck(targetPart)
    if not Toggles.VisibleCheck.Value then return true end
    if not LocalPlayer.Character then return false end
    
    local origin = Camera.CFrame.Position
    local targetPos = targetPart.Position
    local direction = (targetPos - origin).Unit * (targetPos - origin).Magnitude
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true
    
    local result = Workspace:Raycast(origin, direction, raycastParams)
    
    if not result then return true end
    return result.Instance:IsDescendantOf(targetPart.Parent)
end

local function GetPlayerWeapon(player)
    if not player.Character then return "None" end
    local tool = player.Character:FindFirstChildOfClass("Tool")
    return tool and tool.Name or "None"
end

--// 7. AIMBOT ENGINE //--

local CurrentTarget = nil
local IsAimbotToggled = false

local function GetClosestTarget()
    if not Toggles.AimbotEnabled.Value then return nil end
    
    -- Check if aimbot should be active
    local shouldAim = false
    if Toggles.AimbotToggle.Value then
        shouldAim = IsAimbotToggled
    else
        shouldAim = Options.AimKey:GetState()
    end
    
    if not shouldAim then return nil end
    
    local bestTarget = nil
    local shortestDistance = math_huge
    local mousePosition = UserInputService:GetMouseLocation()
    local fovRadius = Options.FOVSize.Value
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if Toggles.AliveCheck.Value and not IsAlive(player) then continue end
        if Toggles.TeamCheck.Value and IsTeammate(player) then continue end
        
        local character = player.Character
        if not character then continue end
        
        -- Select aim part
        local aimPartName = Options.AimPart.Value
        if aimPartName == "Random" then
            local parts = {"Head", "UpperTorso", "HumanoidRootPart"}
            aimPartName = parts[math.random(1, 3)]
        end
        
        local targetPart = character:FindFirstChild(aimPartName)
        if not targetPart then continue end
        
        local screenPosition, onScreen = GetScreenPosition(targetPart.Position)
        if not onScreen then continue end
        
        local distance = (screenPosition - mousePosition).Magnitude
        if distance > fovRadius then continue end
        
        if Toggles.VisibleCheck.Value and not RaycastCheck(targetPart) then continue end
        
        if distance < shortestDistance then
            shortestDistance = distance
            bestTarget = player
        end
    end
    
    return bestTarget
end

-- Toggle aimbot with key
Options.AimKey:OnClick(function()
    if Toggles.AimbotToggle.Value then
        IsAimbotToggled = not IsAimbotToggled
    end
end)

local function UpdateAimbot()
    FOVCircle.Visible = Toggles.ShowFOV.Value and Toggles.AimbotEnabled.Value
    FOVCircle.Radius = Options.FOVSize.Value
    FOVCircle.Position = UserInputService:GetMouseLocation()
    FOVCircle.Color = Options.FOVColor.Value
    
    if not Toggles.AimbotEnabled.Value then
        CurrentTarget = nil
        return
    end
    
    CurrentTarget = GetClosestTarget()
    
    if CurrentTarget and CurrentTarget.Character then
        local aimPartName = Options.AimPart.Value
        if aimPartName == "Random" then
            local parts = {"Head", "UpperTorso", "HumanoidRootPart"}
            aimPartName = parts[math.random(1, 3)]
        end
        
        local targetPart = CurrentTarget.Character:FindFirstChild(aimPartName)
        if targetPart then
            -- Calculate prediction
            local velocity = targetPart.AssemblyLinearVelocity or Vector3_new(0, 0, 0)
            local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
            local predictionMultiplier = Options.Prediction.Value + (ping * 0.5)
            local predictedPosition = targetPart.Position + (velocity * predictionMultiplier)
            
            -- Create target CFrame
            local cameraPosition = Camera.CFrame.Position
            local goalCFrame = CFrame_new(cameraPosition, predictedPosition)
            
            -- Apply smoothness
            local smoothFactor = math_clamp(Options.Smoothness.Value, 1, 30)
            local newCFrame = Camera.CFrame:Lerp(goalCFrame, 1 / smoothFactor)
            
            -- Update camera
            Camera.CFrame = newCFrame
        end
    end
end

--// 8. ESP ENGINE //--

local ESPFunctions = {}

function ESPFunctions:CreateESP(player)
    if ESP_Cache[player] then return end
    
    local espObjects = {
        Box = Drawing.new("Square"),
        BoxOutline = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Weapon = Drawing.new("Text"),
        HealthBar = Drawing.new("Line"),
        HealthBarOutline = Drawing.new("Line"),
        HealthText = Drawing.new("Text"),
        Distance = Drawing.new("Text"),
        Tracer = Drawing.new("Line"),
        Skeleton = {}
    }
    
    -- Configure default properties
    for _, obj in pairs(espObjects) do
        if typeof(obj) == "Drawing" then
            obj.Visible = false
            obj.ZIndex = 2
        end
    end
    
    espObjects.Box.Thickness = 1
    espObjects.Box.Filled = false
    
    espObjects.BoxOutline.Thickness = 3
    espObjects.BoxOutline.Filled = false
    espObjects.BoxOutline.Color = Color3_new(0, 0, 0)
    
    espObjects.Name.Center = true
    espObjects.Name.Outline = true
    espObjects.Name.Size = 13
    
    espObjects.Weapon.Center = true
    espObjects.Weapon.Outline = true
    espObjects.Weapon.Size = 11
    
    espObjects.HealthBar.Thickness = 2
    
    espObjects.HealthBarOutline.Thickness = 4
    espObjects.HealthBarOutline.Color = Color3_new(0, 0, 0)
    
    espObjects.HealthText.Center = true
    espObjects.HealthText.Outline = true
    espObjects.HealthText.Size = 11
    
    espObjects.Distance.Center = true
    espObjects.Distance.Outline = true
    espObjects.Distance.Size = 11
    
    espObjects.Tracer.Thickness = 1
    
    ESP_Cache[player] = espObjects
    return espObjects
end

function ESPFunctions:RemoveESP(player)
    if not ESP_Cache[player] then return end
    
    local esp = ESP_Cache[player]
    for _, obj in pairs(esp) do
        if typeof(obj) == "Drawing" then
            pcall(function() obj:Remove() end)
        elseif type(obj) == "table" then
            for _, line in pairs(obj) do
                pcall(function() line:Remove() end)
            end
        end
    end
    
    ESP_Cache[player] = nil
end

function ESPFunctions:UpdateSkeleton(player, esp, character)
    -- Clear old skeleton
    for _, line in pairs(esp.Skeleton) do
        pcall(function() line:Remove() end)
    end
    esp.Skeleton = {}
    
    -- Skeleton connections for R15
    local connections = {
        {"Head", "UpperTorso"},
        {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"},
        {"LeftUpperArm", "LeftLowerArm"},
        {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"},
        {"RightUpperArm", "RightLowerArm"},
        {"RightLowerArm", "RightHand"},
        {"LowerTorso", "LeftUpperLeg"},
        {"LeftUpperLeg", "LeftLowerLeg"},
        {"LeftLowerLeg", "LeftFoot"},
        {"LowerTorso", "RightUpperLeg"},
        {"RightUpperLeg", "RightLowerLeg"},
        {"RightLowerLeg", "RightFoot"}
    }
    
    for _, connection in ipairs(connections) do
        local part1 = character:FindFirstChild(connection[1])
        local part2 = character:FindFirstChild(connection[2])
        
        if part1 and part2 then
            local pos1, visible1 = GetScreenPosition(part1.Position)
            local pos2, visible2 = GetScreenPosition(part2.Position)
            
            if visible1 and visible2 then
                local line = Drawing.new("Line")
                line.Color = Options.SkelColor.Value
                line.Thickness = 1
                line.From = pos1
                line.To = pos2
                line.Visible = Toggles.ESP_Skeleton.Value
                table.insert(esp.Skeleton, line)
            end
        end
    end
end

function ESPFunctions:UpdateESP()
    if not Toggles.ESPEnabled.Value then
        for _, esp in pairs(ESP_Cache) do
            for _, obj in pairs(esp) do
                if typeof(obj) == "Drawing" then
                    obj.Visible = false
                elseif type(obj) == "table" then
                    for _, line in pairs(obj) do
                        line.Visible = false
                    end
                end
            end
        end
        return
    end
    
    for player, esp in pairs(ESP_Cache) do
        if not player or not player.Parent then
            self:RemoveESP(player)
            continue
        end
        
        local character = player.Character
        if not character or not IsAlive(player) then
            for _, obj in pairs(esp) do
                if typeof(obj) == "Drawing" then
                    obj.Visible = false
                elseif type(obj
