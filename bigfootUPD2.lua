--[[
    QuantumReach TPS & MPS Edition
]]


local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")


local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()


local config = {
    reach = 10,
    transparency = 0.7,
    autoCollect = true,
    showVisual = true
}


local balls = {}
local reachCircle = nil
local gui = nil
local lastRefresh = 0
local connections = {}
local isEnabled = true
local isGUIVisible = true

-- tcs e saml sow viaja n
local ballTypes = {
    "TPS",
    "Ball2",
}


local function notify(title, message)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = message,
        Duration = 1,
        Icon = "rbxassetid://4483345998"
    })
end


local function refreshBalls(force)
    if not force and os.time() - lastRefresh < 2 then
        return
    end
    
    lastRefresh = os.time()
    table.clear(balls)
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        local name = obj.Name
        if (name == "TPS" or name == "Ball2") and obj:IsA("BasePart") then
            table.insert(balls, obj)
        end
    end
    
    
    print("[Quantum] TPS encontrados: " .. #balls)
end


local function createReachCircle()
    if reachCircle then
        reachCircle:Destroy()
    end
    
    reachCircle = Instance.new("Part")
    reachCircle.Name = "QuantumReachCircle"
    reachCircle.Shape = Enum.PartType.Ball
    reachCircle.Size = Vector3.new(config.reach * 2, config.reach * 2, config.reach * 2)
    reachCircle.Transparency = config.transparency
    reachCircle.Color = Color3.fromRGB(0, 255, 0) -- VERDE
    reachCircle.Material = Enum.Material.ForceField
    reachCircle.Anchored = true
    reachCircle.CanCollide = false
    reachCircle.CastShadow = false
    reachCircle.Parent = Workspace
    
    
    local followConn = RunService.RenderStepped:Connect(function()
        if not config.showVisual or not isEnabled then
            reachCircle.Transparency = 1
            return
        end
        
        if character and character:FindFirstChild("HumanoidRootPart") then
            reachCircle.Transparency = config.transparency
            reachCircle.Position = character.HumanoidRootPart.Position
        end
    end)
    
    table.insert(connections, followConn)
end

-- Coletar TPS e SAML
local function collectBalls()
    if not character or not isEnabled then return end
    
    local leg = character:FindFirstChild("Right Leg") or character:FindFirstChild("Left Leg")
    if not leg then return end
    
    for _, ball in pairs(balls) do
        if ball and ball.Parent then
            local distance = (ball.Position - leg.Position).Magnitude
            
            if distance <= config.reach then
                firetouchinterest(ball, leg, 0)
                task.wait(0.01)
                firetouchinterest(ball, leg, 1)
            end
        end
    end
end

-- GUI
local function createGUI()
    if gui then
        gui.Enabled = isGUIVisible
        return gui
    end
    
    gui = Instance.new("ScreenGui")
    gui.Name = "QuantumReachGUI"
    gui.ResetOnSpawn = false
    gui.Parent = player:WaitForChild("PlayerGui")
    
    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0.2, 0, 0.1, 0)
    frame.Position = UDim2.new(0.01, 0, 0.01, 0)
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.BackgroundTransparency = 0.5
    frame.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0.1, 0)
    
    local textLabel = Instance.new("TextLabel", frame)
    textLabel.Size = UDim2.new(1, 0, 0.5, 0)
    textLabel.Text = "Quantum Reach: " .. string.format("%.1f", config.reach)
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextScaled = true
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.BackgroundTransparency = 1
    
    local decrementButton = Instance.new("TextButton", frame)
    decrementButton.Size = UDim2.new(0.5, 0, 0.5, 0)
    decrementButton.Position = UDim2.new(0, 0, 0.5, 0)
    decrementButton.Text = "-"
    decrementButton.Font = Enum.Font.SourceSansBold
    decrementButton.TextScaled = true
    decrementButton.TextColor3 = Color3.new(1, 1, 1)
    decrementButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    
    local incrementButton = Instance.new("TextButton", frame)
    incrementButton.Size = UDim2.new(0.5, 0, 0.5, 0)
    incrementButton.Position = UDim2.new(0.5, 0, 0.5, 0)
    incrementButton.Text = "+"
    incrementButton.Font = Enum.Font.SourceSansBold
    incrementButton.TextScaled = true
    incrementButton.TextColor3 = Color3.new(1, 1, 1)
    incrementButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    
    decrementButton.MouseButton1Click:Connect(function()
        config.reach = math.max(0.1, config.reach - 1)
        textLabel.Text = "Quantum Reach: " .. string.format("%.1f", config.reach)
        createReachCircle()
        notify("QuantumReach", "Alcance: " .. string.format("%.1f", config.reach))
    end)
    
    incrementButton.MouseButton1Click:Connect(function()
        config.reach = config.reach + 1
        textLabel.Text = "Quantum Reach: " .. string.format("%.1f", config.reach)
        createReachCircle()
        notify("QuantumReach", "Alcance: " .. string.format("%.1f", config.reach))
    end)
    
    -- Atualizar texto periodicamente
    task.spawn(function()
        while task.wait(0.5) do
            if gui and gui.Parent then
                textLabel.Text = "Quantum Reach: " .. string.format("%.1f", config.reach)
                frame.Visible = isGUIVisible
            end
        end
    end)
    
    return gui
end

-- Sistema de teclas
local function setupKeybinds()
    UIS.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Comma then
            config.reach = math.max(0.1, config.reach - 1)
            createReachCircle()
            notify("QuantumReach", "Alcance: " .. string.format("%.1f", config.reach))
            
        elseif input.KeyCode == Enum.KeyCode.Period then
            config.reach = config.reach + 1
            createReachCircle()
            notify("QuantumReach", "Alcance: " .. string.format("%.1f", config.reach))
            
        elseif input.KeyCode == Enum.KeyCode.K then
            config.reach = math.max(0.1, config.reach - 0.1)
            createReachCircle()
            notify("QuantumReach", "Alcance: " .. string.format("%.1f", config.reach))
            
        elseif input.KeyCode == Enum.KeyCode.L then
            config.reach = config.reach + 0.1
            createReachCircle()
            notify("QuantumReach", "Alcance: " .. string.format("%.1f", config.reach))
            
        elseif input.KeyCode == Enum.KeyCode.I then
            config.transparency = math.clamp(config.transparency + 0.1, 0, 1)
            if reachCircle then
                reachCircle.Transparency = config.transparency
            end
            notify("Transparência", string.format("%.1f", config.transparency))
            
        elseif input.KeyCode == Enum.KeyCode.O then
            config.transparency = math.clamp(config.transparency - 0.1, 0, 1)
            if reachCircle then
                reachCircle.Transparency = config.transparency
            end
            notify("Transparência", string.format("%.1f", config.transparency))
            
        elseif input.KeyCode == Enum.KeyCode.F1 then
            isEnabled = not isEnabled
            notify("Status", isEnabled and "ATIVADO" or "DESATIVADO")
            
        elseif input.KeyCode == Enum.KeyCode.F2 then
            config.reach = 3.4
            createReachCircle()
            notify("Modo Legit", "Alcance: 3.4")
            
        elseif input.KeyCode == Enum.KeyCode.P then
            isGUIVisible = not isGUIVisible
            if gui then
                gui.Enabled = isGUIVisible
            end
            notify("GUI", isGUIVisible and "Visível" or "Oculta")
            
        else
            -- Qualquer outra tecla coleta TPS/MPS
            refreshBalls(false)
            collectBalls()
        end
    end)
end

-- Auto-coleta
local function autoCollectLoop()
    while task.wait(0.1) do
        if isEnabled and config.autoCollect then
            collectBalls()
        end
    end
end

-- Limpar conexões
local function cleanup()
    for _, conn in pairs(connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    
    if reachCircle then
        reachCircle:Destroy()
    end
    
    table.clear(connections)
    table.clear(balls)
end

-- Inicialização
local function initialize()
    if not character then
        character = player.CharacterAdded:Wait()
    end
    
    cleanup()
    
    refreshBalls(true)
    createReachCircle()
    createGUI()
    setupKeybinds()
    
    task.spawn(autoCollectLoop)
    
    task.spawn(function()
        while task.wait(5) do
            if isEnabled then
                refreshBalls(false)
            end
        end
    end)
    
    notify("QuantumReach", "cabelo é chicleteira? pl0shzucr", 2)
end


player.CharacterAdded:Connect(function(char)
    character = char
    task.wait(1)
    initialize()
end)


if player.Character then
    task.spawn(initialize)
end

print("=====================")
print("QuantumReach TPS & SAML made by cab")
print("=====================")
