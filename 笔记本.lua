-- 本地脚本 (LocalScript) - 放在StarterPlayerScripts中
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- 等待玩家角色
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- 创建UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AdminPanel"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 280, 0, 350)
MainFrame.Position = UDim2.new(0, 10, 0, 10)
MainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
MainFrame.BorderSizePixel = 0
MainFrame.BorderColor3 = Color3.fromRGB(80, 80, 80)
MainFrame.Parent = ScreenGui

-- 标题栏
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0.7, 0, 1, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "管理员面板"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 14
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Parent = TitleBar

-- 关闭按钮
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -30, 0, 0)
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 14
CloseButton.Parent = TitleBar

-- 内容区域
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, 0, 1, -30)
ContentFrame.Position = UDim2.new(0, 0, 0, 30)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

-- 使UI可移动
local dragging = false
local dragInput
local dragStart
local startPos

local function updateInput(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateInput(input)
    end
end)

-- 关闭按钮功能
CloseButton.MouseButton1Click:Connect(function()
    ScreenGui.Enabled = not ScreenGui.Enabled
end)

-- 飞行功能
local flying = false
local bodyVelocity, bodyGyro

local function toggleFlight()
    flying = not flying
    
    if flying then
        -- 确保角色有HumanoidRootPart
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then
            warn("没有找到HumanoidRootPart")
            flying = false
            return
        end
        
        -- 创建飞行物理组件
        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.MaxForce = Vector3.new(40000, 40000, 40000)
        bodyVelocity.Parent = rootPart
        
        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(40000, 40000, 40000)
        bodyGyro.P = 1000
        bodyGyro.D = 50
        bodyGyro.Parent = rootPart
        
        humanoid.PlatformStand = true
        
        -- 飞行控制
        local connection
        connection = RunService.Heartbeat:Connect(function()
            if not flying or not bodyVelocity or not bodyGyro then
                connection:Disconnect()
                return
            end
            
            local camera = workspace.CurrentCamera
            if camera then
                bodyGyro.CFrame = camera.CFrame
                
                local moveDirection = Vector3.new(0, 0, 0)
                local speed = 50 -- 飞行速度
                
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    moveDirection = moveDirection + camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    moveDirection = moveDirection - camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    moveDirection = moveDirection - camera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    moveDirection = moveDirection + camera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    moveDirection = moveDirection + Vector3.new(0, 1, 0)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                    moveDirection = moveDirection - Vector3.new(0, 1, 0)
                end
                
                if moveDirection.Magnitude > 0 then
                    bodyVelocity.Velocity = moveDirection.Unit * speed
                else
                    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
                end
            end
        end)
        
    else
        -- 停止飞行
        if bodyVelocity then 
            bodyVelocity:Destroy() 
            bodyVelocity = nil
        end
        if bodyGyro then 
            bodyGyro:Destroy() 
            bodyGyro = nil
        end
        humanoid.PlatformStand = false
    end
end

-- 创建UI元素的函数
local function createButton(text, position, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 240, 0, 35)
    button.Position = position
    button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    button.BorderSizePixel = 0
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = text
    button.TextSize = 12
    button.Font = Enum.Font.Gotham
    button.Parent = ContentFrame
    
    -- 按钮悬停效果
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end)
    
    button.MouseButton1Click:Connect(callback)
    return button
end

local function createLabel(text, position)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 240, 0, 20)
    label.Position = position
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = text
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.Parent = ContentFrame
    return label
end

-- 创建控制按钮和标签
createButton("飞行开关 (F)", UDim2.new(0, 20, 0, 10), toggleFlight)

createLabel("移动速度: " .. humanoid.WalkSpeed, UDim2.new(0, 20, 0, 55))
local walkSpeedButton = createButton("更改移动速度", UDim2.new(0, 20, 0, 75), function()
    humanoid.WalkSpeed = 50
end)

createLabel("跳跃高度: " .. humanoid.JumpPower, UDim2.new(0, 20, 0, 120))
local jumpPowerButton = createButton("更改跳跃高度", UDim2.new(0, 20, 0, 140), function()
    humanoid.JumpPower = 100
end)

createButton("重置飞行速度", UDim2.new(0, 20, 0, 185), function()
    if bodyVelocity then
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    end
end)

createButton("重置移动速度", UDim2.new(0, 20, 0, 230), function()
    humanoid.WalkSpeed = 16
end)

createButton("重置跳跃高度", UDim2.new(0, 20, 0, 275), function()
    humanoid.JumpPower = 50
end)

-- 键盘快捷键
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F then
        toggleFlight()
    end
end)

-- 角色重生处理
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    
    -- 重置飞行状态
    flying = false
    if bodyVelocity then bodyVelocity:Destroy() end
    if bodyGyro then bodyGyro:Destroy() end
end)

-- 将UI添加到玩家界面
ScreenGui.Parent = player:WaitForChild("PlayerGui")

print("管理员面板加载完成！使用F键快速切换飞行模式")