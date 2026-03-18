local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera 
local SpawnRemote = ReplicatedStorage:WaitForChild("MenuToys"):WaitForChild("SpawnToyRemoteFunction")

-- 設定
local CONFIG = {
    CurrentKey = Enum.KeyCode.E, -- 初期キー
    SpawnDistance = 5,
    ItemName = "PalletLightBrown",
    MainColor = Color3.fromRGB(30, 30, 30),
    TouchColor = Color3.fromRGB(0, 170, 255),  -- タッチボタンの色
    KeyColor = Color3.fromRGB(150, 0, 255),    -- キーボードボタンの色
    SuccessColor = Color3.fromRGB(0, 255, 150),
    ErrorColor = Color3.fromRGB(255, 60, 60)
}

local isChangingKey = false

-- UI作成
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SplitSpawnerUI"
ScreenGui.Parent = CoreGui

-- ボタンをまとめる枠
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 310, 0, 60)
MainFrame.Position = UDim2.new(0.05, 0, 0.4, 0)
MainFrame.BackgroundTransparency = 1
MainFrame.Parent = ScreenGui

-- 1. タッチ専用ボタン (左側)
local TouchButton = Instance.new("TextButton")
TouchButton.Name = "TouchButton"
TouchButton.Parent = MainFrame
TouchButton.Size = UDim2.new(0, 150, 0, 50)
TouchButton.BackgroundColor3 = CONFIG.MainColor
TouchButton.Font = Enum.Font.GothamBold
TouchButton.Text = "TOUCH 生成"
TouchButton.TextColor3 = Color3.new(1, 1, 1)
TouchButton.TextSize = 14

local TouchStroke = Instance.new("UIStroke", TouchButton)
TouchStroke.Color = CONFIG.TouchColor
TouchStroke.Thickness = 2
Instance.new("UICorner", TouchButton).CornerRadius = UDim.new(0, 8)

-- 2. キーボード専用ボタン (右側)
local KeyButton = Instance.new("TextButton")
KeyButton.Name = "KeyButton"
KeyButton.Parent = MainFrame
KeyButton.Position = UDim2.new(0, 160, 0, 0)
KeyButton.Size = UDim2.new(0, 150, 0, 50)
KeyButton.BackgroundColor3 = CONFIG.MainColor
KeyButton.Font = Enum.Font.GothamBold
KeyButton.Text = "KEY: ["..CONFIG.CurrentKey.Name.."]"
KeyButton.TextColor3 = Color3.new(1, 1, 1)
KeyButton.TextSize = 14

local KeyStroke = Instance.new("UIStroke", KeyButton)
KeyStroke.Color = CONFIG.KeyColor
KeyStroke.Thickness = 2
Instance.new("UICorner", KeyButton).CornerRadius = UDim.new(0, 8)

-- ドラッグ機能
local dragging, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- 生成関数
local function doSpawn(button, stroke, originalColor)
    local Character = LocalPlayer.Character
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end

    local spawnCFrame = Camera.CFrame * CFrame.new(0, 0, -CONFIG.SpawnDistance) 
    local success, _ = pcall(function()
        return SpawnRemote:InvokeServer(CONFIG.ItemName, spawnCFrame, Vector3.new(0, 0, 0))
    end)

    if success then
        stroke.Color = CONFIG.SuccessColor
        task.delay(0.5, function() stroke.Color = originalColor end)
    else
        stroke.Color = CONFIG.ErrorColor
        task.delay(0.5, function() stroke.Color = originalColor end)
    end
end

-- タッチボタンの動作
TouchButton.MouseButton1Click:Connect(function()
    if isChangingKey then return end
    doSpawn(TouchButton, TouchStroke, CONFIG.TouchColor)
end)

-- キーボード設定の動作 (右ボタンをクリックで変更モード)
KeyButton.MouseButton1Click:Connect(function()
    if isChangingKey then return end
    
    isChangingKey = true
    KeyButton.Text = "キー入力待ち..."
    KeyStroke.Color = Color3.new(1, 1, 1)
    
    local connection
    connection = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            CONFIG.CurrentKey = input.KeyCode
            KeyButton.Text = "KEY: ["..CONFIG.CurrentKey.Name.."]"
            KeyStroke.Color = CONFIG.KeyColor
            
            connection:Disconnect()
            task.wait(0.2)
            isChangingKey = false
        end
    end)
end)

-- キー入力での生成
UserInputService.InputBegan:Connect(function(input, processed)
    if processed or isChangingKey then return end
    if input.KeyCode == CONFIG.CurrentKey then
        doSpawn(KeyButton, KeyStroke, CONFIG.KeyColor)
    end
end)

print("Split Spawner Ready: Left for Touch / Right for Keyboard Settings")
