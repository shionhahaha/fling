local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService") -- 追加

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- UI構築
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ModernControlPanel"
screenGui.ResetOnSpawn = false 
screenGui.Parent = player:WaitForChild("PlayerGui")

-- メインフレーム
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 220, 0, 250)
mainFrame.Position = UDim2.new(0, 20, 0.5, -125)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
mainFrame.BackgroundTransparency = 0.2
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", mainFrame)
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Transparency = 0.8

-- タイトル
local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, 0, 0, 40)
title.Text = "MENU"
title.TextColor3 = Color3.new(1, 1, 1)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 14

-- スクロールフレーム
local scroll = Instance.new("ScrollingFrame", mainFrame)
scroll.Size = UDim2.new(1, -10, 1, -50)
scroll.Position = UDim2.new(0, 5, 0, 45)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.CanvasSize = UDim2.new(0, 0, 0, 320)
scroll.ScrollBarThickness = 2
scroll.ScrollBarImageColor3 = Color3.new(1, 1, 1)

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0, 8)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- 変数管理
local active = false
local wallCheckActive = true
local espActive = false
local fovVisible = true
local isJapanese = true
local currentTarget = nil

-- テキストデータ
local langData = {
    JP = {
        lang = "言語: 日本語",
        aim = "エイムシステム: ",
        wall = "壁チェック: ",
        esp = "ネームタグ: ",
        fov = "円の表示: ",
        ready = "待機中",
        scanning = "スキャン中...",
        locked = "ロック: ",
        released = "右クリ解除中" -- PC用ステータス
    },
    EN = {
        lang = "LANG: ENGLISH",
        aim = "AIM SYSTEM: ",
        wall = "WALL CHECK: ",
        esp = "NAME TAG: ",
        fov = "FOV CIRCLE: ",
        ready = "READY",
        scanning = "SCANNING...",
        locked = "LOCKED: ",
        released = "RMB RELEASE"
    }
}

-- ボタン作成関数
local function createButton(defaultText, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 180, 0, 35)
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 11
    btn.Text = defaultText
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.Parent = scroll
    return btn
end

local langBtn = createButton("", Color3.fromRGB(60, 60, 60))
local aimBtn = createButton("", Color3.fromRGB(80, 30, 30))
local wallBtn = createButton("", Color3.fromRGB(40, 40, 80))
local espBtn = createButton("", Color3.fromRGB(40, 80, 40))
local fovVisibleBtn = createButton("", Color3.fromRGB(80, 80, 30))

local statusLabel = Instance.new("TextLabel", scroll)
statusLabel.Size = UDim2.new(0, 180, 0, 30)
statusLabel.TextColor3 = Color3.new(0.6, 0.6, 0.6)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 10

local function updateTexts()
    local t = isJapanese and langData.JP or langData.EN
    langBtn.Text = t.lang
    aimBtn.Text = t.aim .. (active and "ON" or "OFF")
    wallBtn.Text = t.wall .. (wallCheckActive and "ON" or "OFF")
    espBtn.Text = t.esp .. (espActive and "ON" or "OFF")
    fovVisibleBtn.Text = t.fov .. (fovVisible and "ON" or "OFF")
end

updateTexts()

-- FOV円
local fovCircle = Instance.new("Frame", screenGui)
fovCircle.BackgroundColor3 = Color3.new(1, 1, 1)
fovCircle.BackgroundTransparency = 0.8
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
local FOV_RADIUS = 150 
fovCircle.Size = UDim2.new(0, FOV_RADIUS * 2, 0, FOV_RADIUS * 2)
Instance.new("UICorner", fovCircle).CornerRadius = UDim.new(1, 0)

-- ロジック
local function refreshTag(targetPlayer)
    if targetPlayer == player then return end
    local char = targetPlayer.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    local tag = head:FindFirstChild("CustomTag")
    if not tag then
        tag = Instance.new("BillboardGui", head)
        tag.Name = "CustomTag"
        tag.Size = UDim2.new(0, 100, 0, 20)
        tag.StudsOffset = Vector3.new(0, 2, 0)
        tag.AlwaysOnTop = true
        local l = Instance.new("TextLabel", tag)
        l.Size = UDim2.new(1, 0, 1, 0); l.BackgroundTransparency = 1
        l.Text = targetPlayer.Name; l.TextColor3 = Color3.new(1, 1, 1)
        l.TextSize = 10; l.Font = Enum.Font.GothamBold; l.TextStrokeTransparency = 0.5
    end
    tag.Enabled = espActive
end

local function isVisible(targetPart)
    if not wallCheckActive then return true end
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances = {player.Character, camera}
    local res = workspace:Raycast(camera.CFrame.Position, (targetPart.Position - camera.CFrame.Position), rp)
    return (not res or res.Instance:IsDescendantOf(targetPart.Parent))
end

local function getClosestPlayer()
    local target = nil
    local dist = FOV_RADIUS
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local pos, on = camera:WorldToViewportPoint(root.Position)
                if on then
                    local mag = (Vector2.new(pos.X, pos.Y) - Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)).Magnitude
                    if mag < dist and isVisible(root) then
                        target = p
                        dist = mag
                    end
                end
            end
        end
    end
    return target
end

-- イベント
langBtn.MouseButton1Click:Connect(function() isJapanese = not isJapanese updateTexts() end)
aimBtn.MouseButton1Click:Connect(function()
    active = not active
    aimBtn.BackgroundColor3 = active and Color3.fromRGB(30, 80, 30) or Color3.fromRGB(80, 30, 30)
    if not active then camera.CameraType = Enum.CameraType.Custom end
    updateTexts()
end)
wallBtn.MouseButton1Click:Connect(function()
    wallCheckActive = not wallCheckActive
    wallBtn.BackgroundColor3 = wallCheckActive and Color3.fromRGB(40, 40, 80) or Color3.fromRGB(80, 40, 40)
    updateTexts()
end)
espBtn.MouseButton1Click:Connect(function()
    espActive = not espActive
    espBtn.BackgroundColor3 = espActive and Color3.fromRGB(40, 100, 40) or Color3.fromRGB(40, 80, 40)
    updateTexts()
end)
fovVisibleBtn.MouseButton1Click:Connect(function()
    fovVisible = not fovVisible
    fovVisibleBtn.BackgroundColor3 = fovVisible and Color3.fromRGB(80, 80, 30) or Color3.fromRGB(50, 50, 50)
    fovCircle.Visible = fovVisible
    updateTexts()
end)

task.spawn(function()
    while true do
        for _, p in pairs(Players:GetPlayers()) do refreshTag(p) end
        task.wait(3)
    end
end)

-- メイン実行 (PC対応: 右クリ解除)
RunService.RenderStepped:Connect(function()
    local t = isJapanese and langData.JP or langData.EN
    
    -- ★ 右クリックが押されているか判定
    local isRightClicking = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)

    if active then
        if isRightClicking then
            -- 右クリック中はエイムを解除して自由視点にする
            statusLabel.Text = t.released
            camera.CameraType = Enum.CameraType.Custom
            return 
        end

        local valid = false
        if currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild("Humanoid") and currentTarget.Character.Humanoid.Health > 0 then
            local root = currentTarget.Character:FindFirstChild("HumanoidRootPart")
            if root and isVisible(root) then valid = true end
        end
        
        if not valid then currentTarget = getClosestPlayer() end
        
        if currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild("HumanoidRootPart") then
            statusLabel.Text = t.locked .. currentTarget.Name:upper()
            camera.CameraType = Enum.CameraType.Scriptable
            local aimPart = currentTarget.Character:FindFirstChild("Head") or currentTarget.Character.HumanoidRootPart
            camera.CFrame = CFrame.new(camera.CFrame.Position, aimPart.Position)
        else
            statusLabel.Text = t.scanning
            camera.CameraType = Enum.CameraType.Custom
        end
    else
        statusLabel.Text = t.ready
    end
end)
