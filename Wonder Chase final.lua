local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local Player = Players.LocalPlayer
local ConfigFile = "WulfricHub_BBCWonderChase.json"

-- DATABASE KOORDINAT PORTAL
local PortalDatabase = {
    {"The Next Step", Vector3.new(478.62, 314.44, -1572.88)},
    {"Shaun The Sheep", Vector3.new(-1989.88, 22.97, 904.18)},
    {"Horrible Science", Vector3.new(-75.88, 521.38, 1105.05)},
    {"Super Happy", Vector3.new(-34.47, -0.66, -2940.58)},
    {"Deadly 60", Vector3.new(-544.85, 842.84, -132.27)},
    {"Doctor Who", Vector3.new(-506.64, 579.32, 414.73)},
    {"EastEnders", Vector3.new(633.89, 176.72, -1003.40)},
    {"Match Of The Day", Vector3.new(26.08, 976.59, -458.06)},
    {"Wallace&Gromit", Vector3.new(-857.23, 35.49, 1706.21)},
}

-- DATA PERSISTEN
local PickedItems = {} 
local TouchedStickers = {}
local RemainingTime = 0
local IsAtStart = false
local Farming = false
local AutoReplay = false 
local CountdownFinished = false
local SelectedPortalPos = nil
local SelectedPortalName = "SELECT OBBY"
local ForceStopMove = false

-------------------------------------------------------------------------
-- FUNGSI LOGIKA UTAMA
-------------------------------------------------------------------------

local function GetHRP()
    local char = Player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function ResetInternalLoop()
    RemainingTime = 0
    IsAtStart = false
    CountdownFinished = false
    TouchedStickers = {}
    PickedItems = {}
end

local function GetNearestPortalPos()
    if SelectedPortalPos then return SelectedPortalPos end
    local hrp = GetHRP()
    if not hrp then return PortalDatabase[5][2] end 
    local nearestPos = nil
    local minDistance = math.huge
    for _, data in ipairs(PortalDatabase) do
        local name, pos = data[1], data[2]
        local dist = (hrp.Position - pos).Magnitude
        if dist < minDistance then
            minDistance = dist
            nearestPos = pos
        end
    end
    return nearestPos
end

local function GetNearestGameStart()
    local hrp = GetHRP()
    if not hrp then return nil end
    local targetFolder = Workspace:FindFirstChild("Utility") and Workspace.Utility:FindFirstChild("ObbyColliders")
    if not targetFolder then return nil end
    local nearest = nil
    local minDistance = math.huge
    for _, v in pairs(targetFolder:GetChildren()) do
        if v.Name == "GameStart" and v:IsA("BasePart") then
            local dist = (hrp.Position - v.Position).Magnitude
            if dist < minDistance then
                minDistance = dist
                nearest = v
            end
        end
    end
    return nearest
end

local function InstantTP(pos)
    local hrp = GetHRP()
    if hrp then 
        hrp.Velocity = Vector3.new(0,0,0)
        hrp.CFrame = typeof(pos) == "CFrame" and pos or CFrame.new(pos) 
    end
end

local function PhysicalMove(targetPos)
    local hrp = GetHRP()
    if not hrp then return end
    local walkSpeed = 60
    while Farming and not IsAtStart and not ForceStopMove do
        local currentPos = hrp.Position
        local distXZ = (Vector2.new(currentPos.X, currentPos.Z) - Vector2.new(targetPos.X, targetPos.Z)).Magnitude
        if distXZ <= 4 then break end 
        local direction = (Vector3.new(targetPos.X, currentPos.Y, targetPos.Z) - currentPos).Unit
        hrp.Velocity = Vector3.new(0,0,0)
        hrp.CFrame = CFrame.new(currentPos + (direction * (walkSpeed * task.wait())))
        hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z))
    end
end

-------------------------------------------------------------------------
-- UI SETUP
-------------------------------------------------------------------------

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WulfricHub"
ScreenGui.Parent = game.CoreGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 150, 0, 290)
MainFrame.Position = UDim2.new(0, 45, 0.5, -145)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BackgroundTransparency = 0.3
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 6)
local Stroke = Instance.new("UIStroke", MainFrame)
Stroke.Color = Color3.fromRGB(255, 120, 0)
Stroke.Thickness = 2 

local Title = Instance.new("TextLabel", MainFrame)
Title.Text = "Wulfric Hub"
Title.Size = UDim2.new(0, 100, 0, 25)
Title.Position = UDim2.new(0, 10, 0, 5) 
Title.TextColor3 = Color3.fromRGB(255, 120, 0)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 20, 0, 20)
CloseBtn.Position = UDim2.new(1, -29, 0, 7) 
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 4)

local MinBtn = Instance.new("TextButton", MainFrame)
MinBtn.Size = UDim2.new(0, 20, 0, 20)
MinBtn.Position = UDim2.new(1, -53, 0, 7) 
MinBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.new(1, 1, 1)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 8
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 4)

local Container = Instance.new("Frame", MainFrame)
Container.Size = UDim2.new(1, 0, 1, -40)
Container.Position = UDim2.new(0, 0, 0, 35)
Container.BackgroundTransparency = 1

local UIList = Instance.new("UIListLayout", Container)
UIList.Padding = UDim.new(0, 6)
UIList.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIList.SortOrder = Enum.SortOrder.LayoutOrder

-------------------------------------------------------------------------
-- WIDGETS
-------------------------------------------------------------------------

local SelectBtn = Instance.new("TextButton", Container)
SelectBtn.LayoutOrder = 1
SelectBtn.Text = "SELECT OBBY"
SelectBtn.Size = UDim2.new(0, 130, 0, 28)
SelectBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
SelectBtn.BackgroundTransparency = 0.7
SelectBtn.TextColor3 = Color3.new(1, 1, 1)
SelectBtn.Font = Enum.Font.GothamBold
SelectBtn.TextSize = 11
Instance.new("UICorner", SelectBtn).CornerRadius = UDim.new(0, 4)
local ss = Instance.new("UIStroke", SelectBtn)
ss.Color = Color3.fromRGB(255, 120, 0)
ss.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local ArrowLabel = Instance.new("TextLabel", SelectBtn)
ArrowLabel.Name = "Arrow"
ArrowLabel.Text = "▼"
ArrowLabel.Size = UDim2.new(0, 20, 1, 0)
ArrowLabel.Position = UDim2.new(1, -22, 0, 0) 
ArrowLabel.BackgroundTransparency = 1
ArrowLabel.TextColor3 = Color3.new(1, 1, 1) 
ArrowLabel.Font = Enum.Font.GothamBold
ArrowLabel.TextSize = 14
ArrowLabel.ZIndex = 5

local Row1 = Instance.new("Frame", Container)
Row1.LayoutOrder = 2
Row1.Size = UDim2.new(0, 130, 0, 24)
Row1.BackgroundTransparency = 1
local RowList1 = Instance.new("UIListLayout", Row1)
RowList1.FillDirection = Enum.FillDirection.Horizontal
RowList1.Padding = UDim.new(0, 5)

local function SaveConfig(minV, maxV, speedV, selectedObby, replayStatus)
    local data = {min = minV, max = maxV, speed = speedV, lastObby = selectedObby, autoReplay = replayStatus}
    local success, encoded = pcall(function() return HttpService:JSONEncode(data) end)
    if success then writefile(ConfigFile, encoded) end
end

local function LoadConfig()
    if isfile(ConfigFile) then
        local success, decoded = pcall(function() return HttpService:JSONDecode(readfile(ConfigFile)) end)
        if success then return decoded end
    end
    return nil
end

local function UpdateCurrentConfig()
    local currentName = nil
    for _, d in ipairs(PortalDatabase) do if d[2] == SelectedPortalPos then currentName = d[1] break end end
    SaveConfig(MinIn.Text, MaxIn.Text, SpeedIn.Text, currentName, AutoReplay)
end

local function CreateBox(parent, placeholder, sizeX, order)
    local box = Instance.new("TextBox", parent)
    box.LayoutOrder = order
    box.Size = sizeX
    box.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    box.BackgroundTransparency = 0.7
    box.TextColor3 = Color3.new(1, 1, 1)
    box.PlaceholderText = placeholder
    box.Font = Enum.Font.GothamSemibold
    box.TextSize = 11
    box.Text = ""
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    local s = Instance.new("UIStroke", box) 
    s.Color = Color3.fromRGB(255, 120, 0)
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border 
    box.FocusLost:Connect(function() UpdateCurrentConfig() end)
    return box
end

MinIn = CreateBox(Row1, "Min(s)", UDim2.new(0, 62.5, 1, 0), 1)
MaxIn = CreateBox(Row1, "Max(s)", UDim2.new(0, 62.5, 1, 0), 2)
SpeedIn = CreateBox(Container, "TP Speed (s)", UDim2.new(0, 130, 0, 24), 3)

local Row2 = Instance.new("Frame", Container)
Row2.LayoutOrder = 4
Row2.Size = UDim2.new(0, 130, 0, 28)
Row2.BackgroundTransparency = 1
local RowList2 = Instance.new("UIListLayout", Row2)
RowList2.FillDirection = Enum.FillDirection.Horizontal
RowList2.Padding = UDim.new(0, 5)

local StartBtn = Instance.new("TextButton", Row2)
StartBtn.Text = "START"
StartBtn.Size = UDim2.new(0, 93, 1, 0)
StartBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
StartBtn.BackgroundTransparency = 0.7
StartBtn.TextColor3 = Color3.new(1, 1, 1)
StartBtn.Font = Enum.Font.GothamBold
StartBtn.TextSize = 11
Instance.new("UICorner", StartBtn).CornerRadius = UDim.new(0, 4)
local s1 = Instance.new("UIStroke", StartBtn)
s1.Color = Color3.fromRGB(255, 120, 0)
s1.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local RestartBtn = Instance.new("TextButton", Row2)
RestartBtn.Text = "RST"
RestartBtn.Size = UDim2.new(0, 32, 1, 0)
RestartBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
RestartBtn.BackgroundTransparency = 0.7
RestartBtn.TextColor3 = Color3.new(1, 1, 1)
RestartBtn.Font = Enum.Font.GothamBold
RestartBtn.TextSize = 10
Instance.new("UICorner", RestartBtn).CornerRadius = UDim.new(0, 4)
local srst = Instance.new("UIStroke", RestartBtn)
srst.Color = Color3.fromRGB(255, 120, 0)
srst.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local ReplayBtn = Instance.new("TextButton", Container)
ReplayBtn.LayoutOrder = 5
ReplayBtn.Text = "AUTO REPLAY: OFF"
ReplayBtn.Size = UDim2.new(0, 130, 0, 28)
ReplayBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ReplayBtn.BackgroundTransparency = 0.7
ReplayBtn.TextColor3 = Color3.new(1, 1, 1)
ReplayBtn.Font = Enum.Font.GothamBold
ReplayBtn.TextSize = 11
Instance.new("UICorner", ReplayBtn).CornerRadius = UDim.new(0, 4)
local sr = Instance.new("UIStroke", ReplayBtn)
sr.Color = Color3.fromRGB(255, 120, 0)
sr.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local PortalBtn = Instance.new("TextButton", Container)
PortalBtn.LayoutOrder = 6
PortalBtn.Text = "TP TO PORTAL"
PortalBtn.Size = UDim2.new(0, 130, 0, 28)
PortalBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
PortalBtn.BackgroundTransparency = 0.7
PortalBtn.TextColor3 = Color3.new(1, 1, 1)
PortalBtn.Font = Enum.Font.GothamBold
PortalBtn.TextSize = 11
Instance.new("UICorner", PortalBtn).CornerRadius = UDim.new(0, 4)
local s2 = Instance.new("UIStroke", PortalBtn)
s2.Color = Color3.fromRGB(255, 120, 0)
s2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local LBoardBtn = Instance.new("TextButton", Container)
LBoardBtn.LayoutOrder = 7
LBoardBtn.Text = "LEADERBOARD"
LBoardBtn.Size = UDim2.new(0, 130, 0, 28)
LBoardBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
LBoardBtn.BackgroundTransparency = 0.7
LBoardBtn.TextColor3 = Color3.new(1, 1, 1)
LBoardBtn.Font = Enum.Font.GothamBold
LBoardBtn.TextSize = 11
Instance.new("UICorner", LBoardBtn).CornerRadius = UDim.new(0, 4)
local slb = Instance.new("UIStroke", LBoardBtn)
slb.Color = Color3.fromRGB(255, 120, 0)
slb.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local DurationLabel = Instance.new("TextLabel", Container)
DurationLabel.LayoutOrder = 8
DurationLabel.Text = "Idle"
DurationLabel.Size = UDim2.new(0, 130, 0, 18)
DurationLabel.BackgroundTransparency = 1
DurationLabel.TextColor3 = Color3.fromRGB(255, 120, 0)
DurationLabel.Font = Enum.Font.GothamBold
DurationLabel.TextSize = 10

-------------------------------------------------------------------------
-- FARMING LOGIC RESTRUCTURED
-------------------------------------------------------------------------

local function StartFarmingLoop()
    if not Farming then return end
    task.spawn(function()
        while Farming do
            -- TAHAP 1: PERGI KE START GAME
            if not IsAtStart then
                local StartPart = GetNearestGameStart()
                if StartPart then 
                    DurationLabel.Text = "Moving to Start"
                    PhysicalMove(StartPart.Position) 
                end
                if Farming and not ForceStopMove then 
                    IsAtStart = true 
                    RemainingTime = math.random(tonumber(MinIn.Text) or 90, tonumber(MaxIn.Text) or 95)
                    CountdownFinished = false
                    TouchedStickers = {} 
                    DurationLabel.Text = "Countdown: "..RemainingTime.."s"
                end
            end
            
            -- TAHAP 2: PENGAMBILAN ITEM
            local tpS = tonumber(SpeedIn.Text) or 0.1
            while Farming and not CountdownFinished and not ForceStopMove do
                local targets = {}
                local folders = {Workspace:FindFirstChild("Pickups"), Workspace:FindFirstChild("ActiveStickers"), Workspace:FindFirstChild("Stickers")}
                for _, f in pairs(folders) do
                    if f then
                        for _, v in pairs(f:GetDescendants()) do
                            if v:IsA("BasePart") and (v.Name == "Default" or v.Name == "Touch") then
                                if not TouchedStickers[v] and not PickedItems[v] then table.insert(targets, v) end
                            end
                        end
                    end
                end
                
                if #targets > 0 then
                    local hrp = GetHRP()
                    if hrp then
                        table.sort(targets, function(a, b) return (hrp.Position - a.Position).Magnitude < (hrp.Position - b.Position).Magnitude end)
                        local target = targets[1]
                        InstantTP(target.Position)
                        if target:IsDescendantOf(Workspace:FindFirstChild("Pickups")) then
                            PickedItems[target] = true; task.delay(3, function() PickedItems[target] = nil end)
                        else TouchedStickers[target] = true end
                        task.wait(tpS)
                    end
                else task.wait(0.5) end
                task.wait()
            end
            
            -- TAHAP 3: SELESAI & KE PORTAL
            if CountdownFinished and Farming and not ForceStopMove then
                DurationLabel.Text = "Reaching Portal"
                local pPos = GetNearestPortalPos()
                for i=1, 5 do InstantTP(pPos) task.wait(0.1) end
                
                if not AutoReplay then
                    Farming = false
                    StartBtn.Text = "START"
                    StartBtn.TextColor3 = Color3.new(1, 1, 1)
                    ResetInternalLoop()
                    break
                else
                    -- Jeda 5 Detik Sebelum Ronde Berikutnya
                    for i = 5, 1, -1 do
                        DurationLabel.Text = "Restarting in "..i.."s"
                        task.wait(1)
                    end
                    ResetInternalLoop()
                end
            end
            task.wait(0.1)
            if ForceStopMove then break end
        end
    end)
end

-------------------------------------------------------------------------
-- UI INTERACTIONS
-------------------------------------------------------------------------

StartBtn.MouseButton1Click:Connect(function()
    Farming = not Farming
    StartBtn.Text = Farming and "PAUSE" or "RESUME"
    StartBtn.TextColor3 = Farming and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(255, 180, 0)
    if Farming then
        ForceStopMove = false
        UpdateCurrentConfig()
        StartFarmingLoop()
    end
end)

PortalBtn.MouseButton1Click:Connect(function() 
    ForceStopMove = true 
    Farming = false 
    ResetInternalLoop()
    CountdownFinished = true 
    
    DurationLabel.Text = "Teleporting..."
    
    local pPos = GetNearestPortalPos()
    for i=1, 5 do InstantTP(pPos) task.wait(0.05) end
    
    if AutoReplay then
        task.spawn(function()
            for i = 5, 1, -1 do
                DurationLabel.Text = "Restarting in " .. i .. "S"
                task.wait(1)
            end
            Farming = true
            ForceStopMove = false
            StartBtn.Text = "PAUSE"
            StartBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
            StartFarmingLoop()
        end)
    else
        StartBtn.Text = "START"
        StartBtn.TextColor3 = Color3.new(1, 1, 1)
        DurationLabel.Text = "IDLE"
    end
end)

RestartBtn.MouseButton1Click:Connect(function()
    Farming = false
    ForceStopMove = true
    ResetInternalLoop()
    StartBtn.Text = "START"
    StartBtn.TextColor3 = Color3.new(1, 1, 1)
    DurationLabel.Text = "IDLE"
end)

ReplayBtn.MouseButton1Click:Connect(function()
    AutoReplay = not AutoReplay
    ReplayBtn.Text = AutoReplay and "AUTO REPLAY: ON" or "AUTO REPLAY: OFF"
    ReplayBtn.TextColor3 = AutoReplay and Color3.fromRGB(255, 120, 0) or Color3.new(1, 1, 1)
    UpdateCurrentConfig()
end)

-------------------------------------------------------------------------
-- DROPDOWN MENU
-------------------------------------------------------------------------
local DropdownFrame = Instance.new("ScrollingFrame", MainFrame)
DropdownFrame.Visible = false
DropdownFrame.Size = UDim2.new(0, 130, 0, 0) 
DropdownFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
DropdownFrame.ScrollBarThickness = 2
DropdownFrame.ZIndex = 15
DropdownFrame.CanvasSize = UDim2.new(0,0,0,0)
DropdownFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
local DropList = Instance.new("UIListLayout", DropdownFrame)
Instance.new("UICorner", DropdownFrame).CornerRadius = UDim.new(0, 4)
local drs = Instance.new("UIStroke", DropdownFrame)
drs.Color = Color3.fromRGB(255, 120, 0)
drs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

SelectBtn.MouseButton1Click:Connect(function()
    DropdownFrame.Visible = not DropdownFrame.Visible
    local relativeY = SelectBtn.AbsolutePosition.Y - MainFrame.AbsolutePosition.Y
    local relativeX = SelectBtn.AbsolutePosition.X - MainFrame.AbsolutePosition.X
    DropdownFrame.Position = UDim2.new(0, relativeX, 0, relativeY + SelectBtn.AbsoluteSize.Y + 2)
    ArrowLabel.Text = DropdownFrame.Visible and "▲" or "▼"
end)

for i, data in ipairs(PortalDatabase) do
    local name, pos = data[1], data[2]
    local b = Instance.new("TextButton", DropdownFrame)
    b.Size = UDim2.new(1, 0, 0, 25)
    b.BackgroundTransparency = 1
    b.Text = name
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 10
    b.ZIndex = 16
    b.MouseButton1Click:Connect(function()
        SelectedPortalPos = pos
        SelectedPortalName = name:upper()
        SelectBtn.Text = SelectedPortalName
        SelectBtn.TextColor3 = Color3.fromRGB(255, 120, 0)
        ArrowLabel.Text = "▼"
        DropdownFrame.Visible = false
        UpdateCurrentConfig()
    end)
end
DropdownFrame.Size = UDim2.new(0, 130, 0, math.min(#PortalDatabase * 25, 100))

-------------------------------------------------------------------------
-- UTILITIES & BACKGROUND TASKS
-------------------------------------------------------------------------

local LogoW = Instance.new("ImageButton", ScreenGui) -- Diubah menjadi ImageButton
LogoW.Name = "WulfricLogo"
LogoW.Size = UDim2.new(0, 40, 0, 40)
LogoW.AnchorPoint = Vector2.new(0.5, 0.5)
LogoW.Position = UDim2.new(
    MainFrame.Position.X.Scale, 
    MainFrame.Position.X.Offset + (MainFrame.Size.X.Offset / 2), 
    MainFrame.Position.Y.Scale, 
    MainFrame.Position.Y.Offset + (MainFrame.Size.Y.Offset / 2)
)
LogoW.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
LogoW.BackgroundTransparency = 0.3
LogoW.Image = "rbxassetid://113804917157039" -- Menggunakan Asset ID Anda
LogoW.Visible = false
LogoW.Draggable = true 
Instance.new("UICorner", LogoW).CornerRadius = UDim.new(0, 6)

local LogoStroke = Instance.new("UIStroke", LogoW)
LogoStroke.Color = Color3.fromRGB(255, 120, 0)
LogoStroke.Thickness = 2
LogoStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

MinBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false LogoW.Visible = true end)
LogoW.MouseButton1Click:Connect(function() MainFrame.Visible = true LogoW.Visible = false end)
CloseBtn.MouseButton1Click:Connect(function() Farming = false ScreenGui:Destroy() end)

LBoardBtn.MouseButton1Click:Connect(function()
    local prompt = nil
    for _, v in pairs(Workspace:GetDescendants()) do
        if v.Name == "ClaimPrompt" and v:IsA("ProximityPrompt") then prompt = v break end
    end
    if prompt then fireproximityprompt(prompt) end
end)

-- TIMER TASK
task.spawn(function()
    while true do
        if Farming and RemainingTime > 0 then
            RemainingTime = RemainingTime - 1
            DurationLabel.Text = "Countdown: "..RemainingTime.."s"
            if RemainingTime <= 0 then CountdownFinished = true end
        end
        task.wait(1)
    end
end)

-- AUTO REPLAY POPUP CLICKER
task.spawn(function()
    while task.wait(1) do
        if AutoReplay then
            pcall(function()
                local resultsUI = Player.PlayerGui.PlayerUi.Popups:FindFirstChild("ObbyResults")
                if resultsUI and resultsUI.Visible == true then
                    local replayBtn = resultsUI:FindFirstChild("ReplayButton")
                    if replayBtn and replayBtn.Visible == true then
                        task.wait(2)
                        local pos = replayBtn.AbsolutePosition
                        local size = replayBtn.AbsoluteSize
                        local x = pos.X + (size.X / 2)
                        local y = pos.Y + (size.Y / 2) + 58 
                        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
                        task.wait(0.1)
                        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
                    end
                end
            end)
        end
    end
end)

-- ANTI IDLE
task.spawn(function()
    local VirtualUser = game:GetService("VirtualUser")
    Player.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
    while task.wait(60) do
        VirtualUser:SetKeyDown(Enum.KeyCode.Space)
        task.wait(0.1)
        VirtualUser:SetKeyUp(Enum.KeyCode.Space)
    end
end)

-- LOAD SAVED DATA
local saved = LoadConfig()
if saved then
    MinIn.Text = tostring(saved.min or "90")
    MaxIn.Text = tostring(saved.max or "100")
    SpeedIn.Text = tostring(saved.speed or "1")
    AutoReplay = saved.autoReplay or false
    ReplayBtn.Text = AutoReplay and "AUTO REPLAY: ON" or "AUTO REPLAY: OFF"
    ReplayBtn.TextColor3 = AutoReplay and Color3.fromRGB(255, 120, 0) or Color3.new(1, 1, 1)
    if saved.lastObby then
        for _, d in ipairs(PortalDatabase) do
            if d[1] == saved.lastObby then
                SelectedPortalPos = d[2]
                SelectedPortalName = d[1]:upper()
                SelectBtn.Text = SelectedPortalName
                SelectBtn.TextColor3 = Color3.fromRGB(255, 120, 0)
                break
            end
        end
    end
end