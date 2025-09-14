local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- 创建窗口
local Window = Rayfield:CreateWindow({
    Name = "inltree｜M.E.G. Endless Reality",
    Icon = 0,
    LoadingTitle = "inltree｜M.E.G. Endless Reality｜M.E.G.无尽现实",
    LoadingSubtitle = "Loading...",
    Theme = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "inltree｜M.E.G.EndlessRealityScript",
        FileName = "inltree｜M.E.G.EndlessRealityScript"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false,
    KeySettings = {
        Title = "M.E.G.EndlessRealityScript",
        Subtitle = "密钥系统",
        Note = "默认密匙：inltree",
        FileName = "inltree｜M.E.G.EndlessRealityScriptKey",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"inltree"}
    }
})

-- 创建选项卡
local UniversalTab = Window:CreateTab("通用功能", "settings")
local HierarchyTab = Window:CreateTab("层级功能", "layers")
local OtherTab = Window:CreateTab("其它功能", "more-horizontal")

-- 通用功能
local nightVisionEnabled = false
local walkSpeedValue = 16
local disableHoldPrompt = false
local defaultLighting = {
    Ambient = game.Lighting.Ambient,
    Brightness = game.Lighting.Brightness
}
local trackedObjects = {}

-- 夜视功能
UniversalTab:CreateToggle({
    Name = "夜视功能",
    CurrentValue = false,
    Callback = function(Value)
        nightVisionEnabled = Value
        if not Value then
            game.Lighting.Ambient = defaultLighting.Ambient
            game.Lighting.Brightness = defaultLighting.Brightness
        end
    end
})

-- 移动速度
UniversalTab:CreateSlider({
    Name = "移动速度",
    Range = {0, 100},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(Value)
        walkSpeedValue = Value
    end
})

-- 长按取消功能
UniversalTab:CreateToggle({
    Name = "取消按钮长按交互",
    CurrentValue = false,
    Callback = function(Value)
        disableHoldPrompt = Value
    end
})

-- 循环保持设置
local function maintainSettings()
    while task.wait(0.1) do
        -- 保持夜视效果
        if nightVisionEnabled then
            game.Lighting.Ambient = Color3.new(1,1,1)
            game.Lighting.Brightness = 1
        end
        
        -- 保持移动速度
        local character = game.Players.LocalPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            pcall(function()
                character.Humanoid.WalkSpeed = walkSpeedValue
            end)
        end
        
        -- 修复后的长按取消处理
        if disableHoldPrompt then
            pcall(function()
                for _, prompt in ipairs(game:GetService("ProximityPromptService"):GetChildren()) do
                    if prompt:IsA("ProximityPrompt") then
                        prompt.HoldDuration = 0
                    end
                end
            end)
        end
    end
end
spawn(maintainSettings)

-- 长按取消事件监听
game:GetService("ProximityPromptService").PromptButtonHoldBegan:Connect(function(prompt)
    if disableHoldPrompt then
        prompt.HoldDuration = 0
    end
end)

-- 层级功能
HierarchyTab:CreateButton({
    Name = "传送电梯",
    Callback = function()
        local eIconPart = game.Workspace:FindFirstChild("Icons"):FindFirstChild("EIconPart")
        if eIconPart then
            game.Players.LocalPlayer.Character:MoveTo(eIconPart.Position + Vector3.new(0,3,0))
        end
    end
})

-- 距离显示功能
local function CreateDistanceDisplay(model, color, labelText)
    if not model or not model:IsA("Model") or trackedObjects[model] then return end
    
    local primaryPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not primaryPart then return end
    
    -- 检查是否已存在距离显示
    if primaryPart:FindFirstChild("Distance_Billboard") then
        return
    end
    
    -- 创建距离显示
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "Distance_Billboard"
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard:SetAttribute("IsDistanceDisplay", true)
    billboard.Parent = primaryPart
    
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Size = UDim2.new(1, 0, 1, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextColor3 = color
    distanceLabel.TextStrokeColor3 = Color3.new(0,0,0)
    distanceLabel.TextStrokeTransparency = 0
    distanceLabel.Font = Enum.Font.SourceSansBold
    distanceLabel.TextSize = 18
    distanceLabel.Text = labelText
    distanceLabel.Parent = billboard
    
    -- 更新距离显示
    spawn(function()
        trackedObjects[model] = true
        while model.Parent and primaryPart.Parent and trackedObjects[model] do
            local player = game.Players.LocalPlayer
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local distance = (player.Character.HumanoidRootPart.Position - primaryPart.Position).Magnitude
                distanceLabel.Text = string.format("%s\n%.1f米", labelText, distance)
            end
            task.wait(0.1)
        end
        -- 清理
        if billboard and billboard.Parent then billboard:Destroy() end
        trackedObjects[model] = nil
    end)
end

-- 清除所有距离显示
local function ClearAllDistanceDisplays()
    -- 清除已跟踪的对象
    for model in pairs(trackedObjects) do
        if model:IsA("Model") then
            local primaryPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
            if primaryPart then
                local billboard = primaryPart:FindFirstChild("Distance_Billboard")
                if billboard then billboard:Destroy() end
            end
        end
    end
    trackedObjects = {}
    
    -- 额外清理工作区中可能遗留的距离显示
    for _, part in ipairs(game.Workspace:GetDescendants()) do
        if part:IsA("BasePart") then
            local billboard = part:FindFirstChild("Distance_Billboard")
            if billboard then billboard:Destroy() end
        end
    end
end

-- 递归查找所有模型
local function FindAllModels(folder)
    local models = {}
    for _, child in ipairs(folder:GetDescendants()) do
        if child:IsA("Model") then
            table.insert(models, child)
        end
    end
    return models
end

-- 实体距离显示[红色]
local entityDistanceEnabled = false
local entityDistanceThread = nil
HierarchyTab:CreateToggle({
    Name = "实体显示[红色]",
    CurrentValue = false,
    Callback = function(Value)
        entityDistanceEnabled = Value
        if not Value then
            if entityDistanceThread then
                entityDistanceThread = nil
            end
            ClearAllDistanceDisplays()
        else
            entityDistanceThread = spawn(function()
                while entityDistanceEnabled do
                    local npcsFolder = game.Workspace:FindFirstChild("NPCS") or game.Workspace:FindFirstChild("NPCS")
                    if npcsFolder then
                        local allModels = FindAllModels(npcsFolder)
                        for _, model in ipairs(allModels) do
                            if model:IsA("Model") and not trackedObjects[model] then
                                CreateDistanceDisplay(model, Color3.new(1,0,0), "实体")
                            end
                        end
                    end
                    task.wait(0.5)
                end
            end)
        end
    end
})

-- 任务目标距离显示[绿色]
local itemDistanceEnabled = false
local itemDistanceThread = nil
HierarchyTab:CreateToggle({
    Name = "任务目标显示[绿色]",
    CurrentValue = false,
    Callback = function(Value)
        itemDistanceEnabled = Value
        if not Value then
            if itemDistanceThread then
                itemDistanceThread = nil
            end
            ClearAllDistanceDisplays()
        else
            itemDistanceThread = spawn(function()
                while itemDistanceEnabled do
                    local puzzlesFolder = game.Workspace:FindFirstChild("Puzzle")
                    if puzzlesFolder then
                        local allPuzzleFolders = puzzlesFolder:GetDescendants()
                        table.insert(allPuzzleFolders, puzzlesFolder)
                        
                        for _, folder in ipairs(allPuzzleFolders) do
                            if folder.Name == "Puzzles" or folder:IsA("Folder") then
                                local allModels = FindAllModels(folder)
                                for _, model in ipairs(allModels) do
                                    if model:IsA("Model") and not trackedObjects[model] then
                                        CreateDistanceDisplay(model, Color3.new(0,1,0), "任务目标")
                                    end
                                end
                            end
                        end
                    end
                    task.wait(0.5)
                end
            end)
        end
    end
})

-- 其它功能
OtherTab:CreateLabel("Waiting for production｜等待制作")

-- 初始化完成
print("M.E.G.EndlessRealityScript 加载完成")