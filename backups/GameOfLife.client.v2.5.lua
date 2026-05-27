local GuiService = game:GetService("GuiService")
local LocalizationService = game:GetService("LocalizationService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")
local VoiceChatService = game:GetService("VoiceChatService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local UI_VERSION = "Life v2.5"

local ROWS = 64
local COLUMNS = 64
local BOARD_MARGIN = 14
local CELL_GAP = 1
local RANDOM_FILL_CHANCE = 0.25
local DEFAULT_ZOOM_INDEX = 3
local ZOOM_LEVELS = { 9, 13, 17, 23, 31 }
local DONATION_NET_TARGET_ROBUX = 1000
local DONATION_CREATOR_SHARE = 0.7
local DONATION_GOAL_ROBUX = math.ceil(DONATION_NET_TARGET_ROBUX / DONATION_CREATOR_SHARE)
local DONATION_PRODUCTS = {
	{ amount = 10, productId = 3598501584 },
	{ amount = 50, productId = 3598501592 },
	{ amount = 100, productId = 3598501597 },
	{ amount = 250, productId = 3598501604 },
	{ amount = 1000, productId = 3598443222 },
}

local WIDE_BAR_HEIGHT = 150
local COMPACT_BAR_HEIGHT = 250
local COMPACT_LANDSCAPE_BAR_HEIGHT = 120
local COMPACT_WIDTH = 1100

local SPEEDS = {
	{ key = "slow", seconds = 0.36 },
	{ key = "normal", seconds = 0.18 },
	{ key = "fast", seconds = 0.08 },
}

local PATTERNS = {
	{
		key = "glider",
		cells = {
			{ 0, 1 },
			{ 1, 2 },
			{ 2, 0 },
			{ 2, 1 },
			{ 2, 2 },
		},
	},
	{
		key = "blinker",
		cells = {
			{ 0, 0 },
			{ 0, 1 },
			{ 0, 2 },
		},
	},
	{
		key = "toad",
		cells = {
			{ 0, 1 },
			{ 0, 2 },
			{ 0, 3 },
			{ 1, 0 },
			{ 1, 1 },
			{ 1, 2 },
		},
	},
	{
		key = "beacon",
		cells = {
			{ 0, 0 },
			{ 0, 1 },
			{ 1, 0 },
			{ 2, 3 },
			{ 3, 2 },
			{ 3, 3 },
		},
	},
	{
		key = "spaceship",
		cells = {
			{ 0, 1 },
			{ 0, 4 },
			{ 1, 0 },
			{ 2, 0 },
			{ 2, 4 },
			{ 3, 0 },
			{ 3, 1 },
			{ 3, 2 },
			{ 3, 3 },
		},
	},
}

local COLORS = {
	background = Color3.fromRGB(28, 30, 35),
	boardBackground = Color3.fromRGB(73, 75, 78),
	gridLine = Color3.fromRGB(104, 106, 109),
	dead = Color3.fromRGB(132, 134, 136),
	alive = Color3.fromRGB(255, 232, 32),
	bar = Color3.fromRGB(188, 188, 188),
	button = Color3.fromRGB(45, 86, 166),
	buttonActive = Color3.fromRGB(30, 132, 93),
	buttonText = Color3.fromRGB(255, 255, 255),
	labelText = Color3.fromRGB(52, 54, 58),
}

local TEXT = {
	en = {
		start = "Start",
		stop = "Stop",
		gameTab = "Game",
		donateTab = "Donate",
		next = "Next",
		clear = "Clear",
		random = "Random",
		pattern = "Pattern",
		modeMove = "Move",
		modeDraw = "Draw",
		zoomIn = "+",
		zoomOut = "-",
		generation = "Generation %d",
		speed = "Speed: %s · Zoom: %dx",
		slow = "Slow",
		normal = "Normal",
		fast = "Fast",
		glider = "Glider",
		blinker = "Blinker",
		toad = "Toad",
		beacon = "Beacon",
		spaceship = "Ship",
		donateTitle = "Open for everyone",
		donateBody = "Goal: 1429 Robux donated. After Roblox's 30% fee, that is about 1000 Robux for the release fee to make this place available beyond the current 16+ limit.",
		donateProgress = "%d / %d Robux",
		donateButton = "%d R$",
		donateSetup = "Donation product is not connected yet.",
		donateReady = "Choose any amount to support the release goal.",
	},
	ru = {
		start = "Старт",
		stop = "Стоп",
		gameTab = "Игра",
		donateTab = "Донат",
		next = "Шаг",
		clear = "Очистить",
		random = "Случайно",
		pattern = "Паттерн",
		modeMove = "Двигать",
		modeDraw = "Рисовать",
		zoomIn = "+",
		zoomOut = "-",
		generation = "Поколение %d",
		speed = "Скорость: %s · Масштаб: %dx",
		slow = "Медленно",
		normal = "Нормально",
		fast = "Быстро",
		glider = "Глайдер",
		blinker = "Мигалка",
		toad = "Жаба",
		beacon = "Маяк",
		spaceship = "Корабль",
		donateTitle = "Открыть для всех",
		donateBody = "Цель: 1429 Robux донатов. После комиссии Roblox 30% это примерно 1000 Robux на комиссию релиза, чтобы открыть плейс не только для 16+.",
		donateProgress = "%d / %d Robux",
		donateButton = "%d R$",
		donateSetup = "Донат-продукт пока не подключен.",
		donateReady = "Выбери любую сумму для поддержки цели.",
	},
}

RunService:UnbindFromRenderStep("BoardCamera")

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
end)

pcall(function()
	TextChatService.CreateDefaultCommands = false
	TextChatService.CreateDefaultTextChannels = false
	TextChatService.ChatWindowConfiguration.Enabled = false
	TextChatService.ChatInputBarConfiguration.Enabled = false
end)

pcall(function()
	VoiceChatService.EnableDefaultVoice = false
end)

local function muteSound(instance)
	if instance:IsA("Sound") then
		pcall(function()
			instance.Volume = 0
			instance.PlaybackSpeed = 0
			instance:Stop()
		end)

		instance:GetPropertyChangedSignal("Playing"):Connect(function()
			if instance.Playing then
				pcall(function()
					instance.Volume = 0
					instance.PlaybackSpeed = 0
					instance:Stop()
				end)
			end
		end)
	elseif instance:IsA("SoundGroup") then
		pcall(function()
			instance.Volume = 0
		end)
	end
end

local function muteAllAudio()
	pcall(function()
		SoundService.Volume = 0
		SoundService.AmbientReverb = Enum.ReverbType.NoReverb
	end)

	local success, descendants = pcall(function()
		return game:GetDescendants()
	end)

	if success then
		for _, instance in descendants do
			muteSound(instance)
		end
	end
end

local function removeRobloxCharacterSounds()
	local playerScripts = player:FindFirstChild("PlayerScripts")
	if playerScripts then
		for _, child in playerScripts:GetChildren() do
			if child.Name == "RbxCharacterSounds" or child.Name == "CharacterSounds" then
				child:Destroy()
			end
		end
	end

	local character = player.Character
	if character then
		for _, instance in character:GetDescendants() do
			muteSound(instance)
			if instance:IsA("Sound") then
				pcall(function()
					instance:Destroy()
				end)
			end
		end
	end
end

task.defer(muteAllAudio)
task.defer(removeRobloxCharacterSounds)
game.DescendantAdded:Connect(function(instance)
	task.defer(muteSound, instance)
end)
player.CharacterAdded:Connect(function()
	task.defer(removeRobloxCharacterSounds)
	task.defer(muteAllAudio)
end)

local function hideWorkspacePart(instance)
	if instance:IsA("BasePart") then
		instance.LocalTransparencyModifier = 1
		instance.CanQuery = false
	end
end

for _, instance in Workspace:GetDescendants() do
	hideWorkspacePart(instance)
end

Workspace.DescendantAdded:Connect(hideWorkspacePart)

local function getLanguage()
	local locale = "en"
	pcall(function()
		locale = LocalizationService.RobloxLocaleId
	end)

	if string.sub(string.lower(locale), 1, 2) == "ru" then
		return "ru"
	end

	return "en"
end

local t = TEXT[getLanguage()]

local function removeOldGui(playerGui)
	for _, child in playerGui:GetChildren() do
		if child.Name == "GameOfLifeUI"
			or child.Name == "Board2D"
			or child.Name == "Board2D_v05"
			or child.Name == "Board2D_v06"
			or child.Name == "BoardCameraStatus"
		then
			child:Destroy()
		end
	end
end

local grid = {}
local cells = {}
local running = false
local generation = 0
local speedIndex = 2
local patternIndex = 1
local lastPatternKey = nil
local zoomIndex = DEFAULT_ZOOM_INDEX
local currentCellSize = ZOOM_LEVELS[zoomIndex]
local currentBoardWidth = 0
local currentBoardHeight = 0
local activeTab = "game"
local donationTotalRobux = 0
local inputMode = "draw"
local drawingActive = false
local drawTargetAlive = nil
local drawInput = nil
local lastPaintedCellKey = nil
local panningActive = false
local panStartPosition = nil
local panStartCanvasPosition = nil

local playerGui = player:WaitForChild("PlayerGui")
removeOldGui(playerGui)

pcall(function()
	playerGui.ScreenOrientation = Enum.ScreenOrientation.Portrait
	StarterGui.ScreenOrientation = Enum.ScreenOrientation.Portrait
end)

local function makeGrid()
	local nextGrid = {}
	for row = 1, ROWS do
		nextGrid[row] = {}
		for column = 1, COLUMNS do
			nextGrid[row][column] = false
		end
	end

	return nextGrid
end

grid = makeGrid()

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GameOfLifeUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 1000
screenGui.Parent = playerGui

local root = Instance.new("Frame")
root.Name = "Root"
root.BackgroundColor3 = COLORS.background
root.BorderSizePixel = 0
root.Size = UDim2.fromScale(1, 1)
root.Parent = screenGui

local boardOuter = Instance.new("ScrollingFrame")
boardOuter.Name = "BoardOuter"
boardOuter.BackgroundColor3 = COLORS.background
boardOuter.BorderSizePixel = 0
boardOuter.Active = true
boardOuter.AutomaticCanvasSize = Enum.AutomaticSize.None
boardOuter.CanvasPosition = Vector2.new(0, 0)
boardOuter.ScrollBarImageColor3 = Color3.fromRGB(210, 214, 220)
boardOuter.ScrollBarThickness = 8
boardOuter.ScrollingDirection = Enum.ScrollingDirection.XY
boardOuter.Parent = root

local board = Instance.new("Frame")
board.Name = "Board"
board.AnchorPoint = Vector2.new(0, 0)
board.BackgroundColor3 = COLORS.gridLine
board.BorderSizePixel = 0
board.Position = UDim2.fromOffset(BOARD_MARGIN, BOARD_MARGIN)
board.Parent = boardOuter

local zoomControls = Instance.new("Frame")
zoomControls.Name = "ZoomControls"
zoomControls.AnchorPoint = Vector2.new(1, 0)
zoomControls.BackgroundTransparency = 1
zoomControls.Position = UDim2.new(1, -14, 0, 14)
zoomControls.Size = UDim2.fromOffset(116, 52)
zoomControls.Parent = root

local bottomBar = Instance.new("Frame")
bottomBar.Name = "BottomBar"
bottomBar.BackgroundColor3 = COLORS.bar
bottomBar.BorderSizePixel = 0
bottomBar.Parent = root

local versionLabel = Instance.new("TextLabel")
versionLabel.Name = "VersionLabel"
versionLabel.AnchorPoint = Vector2.new(1, 1)
versionLabel.BackgroundTransparency = 0.25
versionLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
versionLabel.BorderSizePixel = 0
versionLabel.Position = UDim2.new(1, -12, 1, -12)
versionLabel.Size = UDim2.fromOffset(92, 24)
versionLabel.Font = Enum.Font.GothamMedium
versionLabel.Text = UI_VERSION
versionLabel.TextColor3 = COLORS.buttonText
versionLabel.TextSize = 12
versionLabel.Parent = root

local generationLabel = Instance.new("TextLabel")
generationLabel.Name = "GenerationLabel"
generationLabel.BackgroundTransparency = 1
generationLabel.Font = Enum.Font.GothamMedium
generationLabel.TextColor3 = COLORS.labelText
generationLabel.TextSize = 18
generationLabel.TextXAlignment = Enum.TextXAlignment.Left
generationLabel.Parent = bottomBar

local speedLabel = Instance.new("TextLabel")
speedLabel.Name = "SpeedLabel"
speedLabel.BackgroundTransparency = 1
speedLabel.Font = Enum.Font.GothamMedium
speedLabel.TextColor3 = COLORS.labelText
speedLabel.TextSize = 18
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = bottomBar

local controls = Instance.new("Frame")
controls.Name = "Controls"
controls.BackgroundTransparency = 1
controls.Parent = bottomBar

local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.BackgroundTransparency = 1
tabBar.Parent = bottomBar

local function makeButton(name, parent)
	local button = Instance.new("TextButton")
	button.Name = name
	button.AutoButtonColor = true
	button.BackgroundColor3 = COLORS.button
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.TextColor3 = COLORS.buttonText
	button.TextScaled = true
	button.Parent = parent or controls

	local textSizeLimit = Instance.new("UITextSizeConstraint")
	textSizeLimit.MinTextSize = 12
	textSizeLimit.MaxTextSize = 24
	textSizeLimit.Parent = button

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = button

	return button
end

local startButton = makeButton("StartButton")
local nextButton = makeButton("NextButton")
local clearButton = makeButton("ClearButton")
local randomButton = makeButton("RandomButton")
local patternButton = makeButton("PatternButton")
local speedButton = makeButton("SpeedButton")
local modeButton = makeButton("ModeButton")
local buttons = { startButton, nextButton, clearButton, randomButton, patternButton, speedButton, modeButton }

local zoomOutButton = makeButton("ZoomOutButton", zoomControls)
zoomOutButton.Position = UDim2.fromOffset(0, 0)
zoomOutButton.Size = UDim2.fromOffset(52, 52)

local zoomInButton = makeButton("ZoomInButton", zoomControls)
zoomInButton.Position = UDim2.fromOffset(64, 0)
zoomInButton.Size = UDim2.fromOffset(52, 52)

local gameTabButton = makeButton("GameTabButton", tabBar)
local donateTabButton = makeButton("DonateTabButton", tabBar)

local donationPanel = Instance.new("Frame")
donationPanel.Name = "DonationPanel"
donationPanel.BackgroundTransparency = 1
donationPanel.Visible = false
donationPanel.Parent = bottomBar

local donateTitleLabel = Instance.new("TextLabel")
donateTitleLabel.Name = "DonateTitleLabel"
donateTitleLabel.BackgroundTransparency = 1
donateTitleLabel.Font = Enum.Font.GothamBold
donateTitleLabel.TextColor3 = COLORS.labelText
donateTitleLabel.TextSize = 20
donateTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
donateTitleLabel.Parent = donationPanel

local donateBodyLabel = Instance.new("TextLabel")
donateBodyLabel.Name = "DonateBodyLabel"
donateBodyLabel.BackgroundTransparency = 1
donateBodyLabel.Font = Enum.Font.GothamMedium
donateBodyLabel.TextColor3 = COLORS.labelText
donateBodyLabel.TextSize = 14
donateBodyLabel.TextWrapped = true
donateBodyLabel.TextXAlignment = Enum.TextXAlignment.Left
donateBodyLabel.TextYAlignment = Enum.TextYAlignment.Top
donateBodyLabel.Parent = donationPanel

local donateProgressBack = Instance.new("Frame")
donateProgressBack.Name = "DonateProgressBack"
donateProgressBack.BackgroundColor3 = Color3.fromRGB(122, 126, 134)
donateProgressBack.BorderSizePixel = 0
donateProgressBack.Parent = donationPanel

local donateProgressCorner = Instance.new("UICorner")
donateProgressCorner.CornerRadius = UDim.new(0, 10)
donateProgressCorner.Parent = donateProgressBack

local donateProgressFill = Instance.new("Frame")
donateProgressFill.Name = "DonateProgressFill"
donateProgressFill.BackgroundColor3 = COLORS.buttonActive
donateProgressFill.BorderSizePixel = 0
donateProgressFill.Size = UDim2.fromScale(0, 1)
donateProgressFill.Parent = donateProgressBack

local donateProgressFillCorner = Instance.new("UICorner")
donateProgressFillCorner.CornerRadius = UDim.new(0, 10)
donateProgressFillCorner.Parent = donateProgressFill

local donateProgressLabel = Instance.new("TextLabel")
donateProgressLabel.Name = "DonateProgressLabel"
donateProgressLabel.BackgroundTransparency = 1
donateProgressLabel.Font = Enum.Font.GothamBold
donateProgressLabel.Position = UDim2.fromScale(0, 0)
donateProgressLabel.Size = UDim2.fromScale(1, 1)
donateProgressLabel.TextColor3 = COLORS.buttonText
donateProgressLabel.TextScaled = true
donateProgressLabel.TextXAlignment = Enum.TextXAlignment.Center
donateProgressLabel.TextYAlignment = Enum.TextYAlignment.Center
donateProgressLabel.Parent = donateProgressBack

local donateProgressTextLimit = Instance.new("UITextSizeConstraint")
donateProgressTextLimit.MinTextSize = 10
donateProgressTextLimit.MaxTextSize = 14
donateProgressTextLimit.Parent = donateProgressLabel

local donateButtonsFrame = Instance.new("Frame")
donateButtonsFrame.Name = "DonateButtonsFrame"
donateButtonsFrame.BackgroundTransparency = 1
donateButtonsFrame.Parent = donationPanel

local donateButtons = {}
for _, donationProduct in DONATION_PRODUCTS do
	local button = makeButton(string.format("Donate%dButton", donationProduct.amount), donateButtonsFrame)
	table.insert(donateButtons, {
		button = button,
		amount = donationProduct.amount,
		productId = donationProduct.productId,
	})
end

local donateStatusLabel = Instance.new("TextLabel")
donateStatusLabel.Name = "DonateStatusLabel"
donateStatusLabel.BackgroundTransparency = 1
donateStatusLabel.Font = Enum.Font.GothamMedium
donateStatusLabel.TextColor3 = COLORS.labelText
donateStatusLabel.TextSize = 13
donateStatusLabel.TextWrapped = true
donateStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
donateStatusLabel.TextYAlignment = Enum.TextYAlignment.Top
donateStatusLabel.Parent = donationPanel

local function updateLabels()
	generationLabel.Text = string.format(t.generation, generation)
	speedLabel.Text = string.format(t.speed, t[SPEEDS[speedIndex].key], zoomIndex)
	startButton.Text = if running then t.stop else t.start
	startButton.BackgroundColor3 = if running then COLORS.buttonActive else COLORS.button
	nextButton.Text = t.next
	clearButton.Text = t.clear
	randomButton.Text = t.random
	patternButton.Text = if lastPatternKey then t[lastPatternKey] else t.pattern
	speedButton.Text = t[SPEEDS[speedIndex].key]
	modeButton.Text = if inputMode == "draw" then t.modeDraw else t.modeMove
	modeButton.BackgroundColor3 = if inputMode == "draw" then COLORS.buttonActive else COLORS.button
	zoomOutButton.Text = t.zoomOut
	zoomInButton.Text = t.zoomIn
	gameTabButton.Text = t.gameTab
	donateTabButton.Text = t.donateTab
	gameTabButton.BackgroundColor3 = if activeTab == "game" then COLORS.buttonActive else COLORS.button
	donateTabButton.BackgroundColor3 = if activeTab == "donate" then COLORS.buttonActive else COLORS.button

	local progress = math.clamp(donationTotalRobux / DONATION_GOAL_ROBUX, 0, 1)
	donateTitleLabel.Text = t.donateTitle
	donateBodyLabel.Text = t.donateBody
	donateProgressFill.Size = UDim2.fromScale(progress, 1)
	donateProgressLabel.Text = string.format(t.donateProgress, donationTotalRobux, DONATION_GOAL_ROBUX)
	local hasDonationProducts = #DONATION_PRODUCTS > 0
	for _, item in donateButtons do
		item.button.Text = string.format(t.donateButton, item.amount)
		item.button.BackgroundColor3 = if item.productId > 0 then COLORS.buttonActive else COLORS.button
	end
	donateStatusLabel.Text = if hasDonationProducts then t.donateReady else t.donateSetup
end

local function setActiveTab(tabName)
	activeTab = tabName
	local gameVisible = activeTab == "game"
	generationLabel.Visible = gameVisible
	speedLabel.Visible = gameVisible
	controls.Visible = gameVisible
	donationPanel.Visible = not gameVisible
	updateLabels()
end

local function bindDonationTotal()
	task.spawn(function()
		local donationTotalValue = ReplicatedStorage:WaitForChild("DonationTotalRobux", 15)
		if not donationTotalValue then
			return
		end

		donationTotalRobux = donationTotalValue.Value
		updateLabels()
		donationTotalValue:GetPropertyChangedSignal("Value"):Connect(function()
			donationTotalRobux = donationTotalValue.Value
			updateLabels()
		end)
	end)
end

local function pollDonationTotal()
	task.spawn(function()
		while screenGui.Parent do
			local donationTotalValue = ReplicatedStorage:FindFirstChild("DonationTotalRobux")
			if donationTotalValue then
				donationTotalRobux = donationTotalValue.Value
				updateLabels()
			end
			task.wait(10)
		end
	end)
end

local function syncDonationTotalFromServer()
	local donationTotalValue = ReplicatedStorage:FindFirstChild("DonationTotalRobux")
	if donationTotalValue then
		donationTotalRobux = donationTotalValue.Value
		updateLabels()
	end
end

local function syncDonationTotalAfterPurchase()
	task.spawn(function()
		for _ = 1, 20 do
			syncDonationTotalFromServer()
			task.wait(0.5)
		end
	end)
end

local function markDonationPurchasePending()
	task.delay(2, function()
		local donationTotalValue = ReplicatedStorage:FindFirstChild("DonationTotalRobux")
		if donationTotalValue then
			donationTotalRobux = donationTotalValue.Value
			updateLabels()
		end
	end)
end

MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, wasPurchased)
	if not wasPurchased or userId ~= player.UserId then
		return
	end

	for _, donationProduct in DONATION_PRODUCTS do
		if donationProduct.productId == productId then
			markDonationPurchasePending()
			syncDonationTotalAfterPurchase()
			return
		end
	end
end)

local function renderCell(row, column)
	local cell = cells[row][column]
	cell.BackgroundColor3 = if grid[row][column] then COLORS.alive else COLORS.dead
end

local function renderGrid()
	for row = 1, ROWS do
		for column = 1, COLUMNS do
			renderCell(row, column)
		end
	end
	updateLabels()
end

local function countNeighbors(row, column)
	local count = 0
	for rowOffset = -1, 1 do
		for columnOffset = -1, 1 do
			if rowOffset ~= 0 or columnOffset ~= 0 then
				local neighborRow = row + rowOffset
				local neighborColumn = column + columnOffset
				if neighborRow >= 1 and neighborRow <= ROWS and neighborColumn >= 1 and neighborColumn <= COLUMNS then
					if grid[neighborRow][neighborColumn] then
						count += 1
					end
				end
			end
		end
	end

	return count
end

local function stepSimulation()
	local nextGrid = makeGrid()
	for row = 1, ROWS do
		for column = 1, COLUMNS do
			local alive = grid[row][column]
			local neighbors = countNeighbors(row, column)
			nextGrid[row][column] = neighbors == 3 or (alive and neighbors == 2)
		end
	end

	grid = nextGrid
	generation += 1
	renderGrid()
end

local function setRunning(value)
	running = value
	updateLabels()
end

local function clearGrid()
	grid = makeGrid()
	generation = 0
	lastPatternKey = nil
	setRunning(false)
	renderGrid()
end

local function randomizeGrid()
	grid = makeGrid()
	for row = 1, ROWS do
		for column = 1, COLUMNS do
			grid[row][column] = math.random() < RANDOM_FILL_CHANCE
		end
	end
	generation = 0
	lastPatternKey = nil
	setRunning(false)
	renderGrid()
end

local function placePattern()
	local pattern = PATTERNS[patternIndex]
	grid = makeGrid()

	local maxRow = 0
	local maxColumn = 0
	for _, cell in pattern.cells do
		maxRow = math.max(maxRow, cell[1])
		maxColumn = math.max(maxColumn, cell[2])
	end

	local startRow = math.floor((ROWS - maxRow) / 2)
	local startColumn = math.floor((COLUMNS - maxColumn) / 2)
	for _, cell in pattern.cells do
		local row = startRow + cell[1]
		local column = startColumn + cell[2]
		if row >= 1 and row <= ROWS and column >= 1 and column <= COLUMNS then
			grid[row][column] = true
		end
	end

	generation = 0
	lastPatternKey = pattern.key
	setRunning(false)
	patternIndex += 1
	if patternIndex > #PATTERNS then
		patternIndex = 1
	end
	renderGrid()
end

local function cycleSpeed()
	speedIndex += 1
	if speedIndex > #SPEEDS then
		speedIndex = 1
	end
	updateLabels()
end

local function setCell(row, column, alive)
	if row < 1 or row > ROWS or column < 1 or column > COLUMNS then
		return
	end

	grid[row][column] = alive
	renderCell(row, column)
end

local function toggleCell(row, column)
	setCell(row, column, not grid[row][column])
end

local function isTouchDevice()
	return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

local function syncBoardScrolling()
	boardOuter.ScrollingEnabled = inputMode == "move" or not isTouchDevice()
end

local function isBoardInputPosition(screenPosition)
	local guiObjects = playerGui:GetGuiObjectsAtPosition(screenPosition.X, screenPosition.Y)
	for _, guiObject in guiObjects do
		if guiObject == board or guiObject:IsDescendantOf(board) then
			return true
		end

		if guiObject == boardOuter then
			return true
		end

		if guiObject == root or guiObject:IsDescendantOf(root) then
			return false
		end
	end

	return false
end

local function cellAtScreenPosition(screenPosition)
	if not isBoardInputPosition(screenPosition) then
		return nil, nil
	end

	local boardPosition = board.AbsolutePosition
	local localX = screenPosition.X - boardPosition.X
	local localY = screenPosition.Y - boardPosition.Y

	if localX < 0 or localY < 0 or localX >= currentBoardWidth or localY >= currentBoardHeight then
		return nil, nil
	end

	local stepSize = currentCellSize + CELL_GAP
	local column = math.floor(localX / stepSize) + 1
	local row = math.floor(localY / stepSize) + 1
	if row < 1 or row > ROWS or column < 1 or column > COLUMNS then
		return nil, nil
	end

	return row, column
end

local function paintCellAt(screenPosition)
	if inputMode ~= "draw" then
		return false
	end

	local row, column = cellAtScreenPosition(screenPosition)
	if not row then
		return false
	end

	local cellKey = row .. ":" .. column
	if cellKey == lastPaintedCellKey then
		return true
	end

	if drawTargetAlive == nil then
		drawTargetAlive = not grid[row][column]
	end

	setCell(row, column, drawTargetAlive)
	lastPaintedCellKey = cellKey
	return true
end

local function beginDrawing(input)
	if inputMode ~= "draw" then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	local row, column = cellAtScreenPosition(input.Position)
	if not row then
		return
	end

	drawingActive = true
	drawInput = input
	drawTargetAlive = not grid[row][column]
	lastPaintedCellKey = row .. ":" .. column
	setCell(row, column, drawTargetAlive)
end

local function continueDrawing(input)
	if not drawingActive or inputMode ~= "draw" then
		return
	end

	if drawInput and input.UserInputType == Enum.UserInputType.Touch and input ~= drawInput then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		paintCellAt(input.Position)
	end
end

local function endDrawing(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input ~= drawInput then
		return
	end

	drawingActive = false
	drawInput = nil
	drawTargetAlive = nil
	lastPaintedCellKey = nil
end

local function beginPanning(input)
	if inputMode ~= "move" then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end

	if not isBoardInputPosition(input.Position) then
		return
	end

	panningActive = true
	panStartPosition = input.Position
	panStartCanvasPosition = boardOuter.CanvasPosition
end

local function continuePanning(input)
	if not panningActive or input.UserInputType ~= Enum.UserInputType.MouseMovement then
		return
	end

	local delta = input.Position - panStartPosition
	local canvasSize = boardOuter.AbsoluteCanvasSize
	local viewSize = boardOuter.AbsoluteSize
	local maxX = math.max(0, canvasSize.X - viewSize.X)
	local maxY = math.max(0, canvasSize.Y - viewSize.Y)
	boardOuter.CanvasPosition = Vector2.new(
		math.clamp(panStartCanvasPosition.X - delta.X, 0, maxX),
		math.clamp(panStartCanvasPosition.Y - delta.Y, 0, maxY)
	)
end

local function endPanning(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end

	panningActive = false
	panStartPosition = nil
	panStartCanvasPosition = nil
end

local function setInputMode(nextMode)
	inputMode = nextMode
	drawingActive = false
	drawInput = nil
	drawTargetAlive = nil
	lastPaintedCellKey = nil
	panningActive = false
	panStartPosition = nil
	panStartCanvasPosition = nil
	syncBoardScrolling()
	updateLabels()
end

local function layoutControls(isCompact, isLandscapeCompact, rootWidth)
	local gap = if isCompact then 10 else 16
	local buttonHeight = if isLandscapeCompact then 34 else if isCompact then 44 else 54
	local leftPadding = if isCompact then 14 else 28
	local labelWidth = if isCompact then rootWidth - 28 else 190
	local tabHeight = if isLandscapeCompact then 30 else if isCompact then 36 else 38
	local tabWidth = if isLandscapeCompact then 112 else if isCompact then math.floor((rootWidth - 38) / 2) else 132

	tabBar.Position = UDim2.fromOffset(leftPadding, if isCompact then 10 else 16)
	tabBar.Size = UDim2.fromOffset((tabWidth * 2) + gap, tabHeight)
	gameTabButton.Position = UDim2.fromOffset(0, 0)
	gameTabButton.Size = UDim2.fromOffset(tabWidth, tabHeight)
	donateTabButton.Position = UDim2.fromOffset(tabWidth + gap, 0)
	donateTabButton.Size = UDim2.fromOffset(tabWidth, tabHeight)

	generationLabel.Position = UDim2.fromOffset(leftPadding, if isLandscapeCompact then 50 else if isCompact then 54 else 62)
	generationLabel.Size = UDim2.fromOffset(labelWidth, 28)
	speedLabel.Position = UDim2.fromOffset(leftPadding, if isLandscapeCompact then 76 else if isCompact then 82 else 90)
	speedLabel.Size = UDim2.fromOffset(labelWidth, 28)

	if isLandscapeCompact then
		controls.AnchorPoint = Vector2.new(0, 0)
		controls.Position = UDim2.fromOffset(270, 12)
		controls.Size = UDim2.new(1, -284, 0, 92)
		local controlsWidth = rootWidth - 284
		local buttonWidth = math.floor((controlsWidth - (gap * 3)) / 4)
		local positions = {
			{ 0, 0, buttonWidth },
			{ buttonWidth + gap, 0, buttonWidth },
			{ (buttonWidth + gap) * 2, 0, buttonWidth },
			{ (buttonWidth + gap) * 3, 0, buttonWidth },
			{ 0, buttonHeight + gap, buttonWidth },
			{ buttonWidth + gap, buttonHeight + gap, buttonWidth },
			{ (buttonWidth + gap) * 2, buttonHeight + gap, buttonWidth },
		}

		for index, button in buttons do
			local item = positions[index]
			button.Position = UDim2.fromOffset(item[1], item[2])
			button.Size = UDim2.fromOffset(item[3], buttonHeight)
		end

		donationPanel.Position = UDim2.fromOffset(270, 10)
		donationPanel.Size = UDim2.new(1, -284, 0, 100)
		donateTitleLabel.Position = UDim2.fromOffset(0, 0)
		donateTitleLabel.Size = UDim2.new(0.28, -8, 0, 24)
		donateBodyLabel.Position = UDim2.fromOffset(0, 28)
		donateBodyLabel.Size = UDim2.new(0.28, -8, 0, 64)
		donateProgressBack.Position = UDim2.new(0.28, 0, 0, 4)
		donateProgressBack.Size = UDim2.new(0.32, -12, 0, 24)
		donateButtonsFrame.Position = UDim2.new(0.6, 0, 0, 0)
		donateButtonsFrame.Size = UDim2.new(0.4, 0, 0, 76)
		local compactButtonGap = 7
		local compactButtonWidth = math.floor((donateButtonsFrame.AbsoluteSize.X - compactButtonGap) / 2)
		for index, item in donateButtons do
			local zeroIndex = index - 1
			local column = zeroIndex % 2
			local row = math.floor(zeroIndex / 2)
			item.button.Position = UDim2.fromOffset(column * (compactButtonWidth + compactButtonGap), row * 25)
			item.button.Size = UDim2.fromOffset(compactButtonWidth, 22)
		end
		donateStatusLabel.Position = UDim2.new(0.28, 0, 0, 36)
		donateStatusLabel.Size = UDim2.new(0.32, -12, 0, 56)
	elseif isCompact then
		controls.AnchorPoint = Vector2.new(0, 0)
		controls.Position = UDim2.fromOffset(14, 120)
		controls.Size = UDim2.new(1, -28, 0, 98)
		local controlsWidth = rootWidth - 28
		local buttonWidth = math.floor((controlsWidth - (gap * 3)) / 4)
		local positions = {
			{ 0, 0, buttonWidth },
			{ buttonWidth + gap, 0, buttonWidth },
			{ (buttonWidth + gap) * 2, 0, buttonWidth },
			{ (buttonWidth + gap) * 3, 0, buttonWidth },
			{ 0, buttonHeight + gap, buttonWidth },
			{ buttonWidth + gap, buttonHeight + gap, buttonWidth },
			{ (buttonWidth + gap) * 2, buttonHeight + gap, buttonWidth },
		}

		for index, button in buttons do
			local item = positions[index]
			button.Position = UDim2.fromOffset(item[1], item[2])
			button.Size = UDim2.fromOffset(item[3], buttonHeight)
		end

		donationPanel.Position = UDim2.fromOffset(14, 56)
		donationPanel.Size = UDim2.new(1, -28, 0, 160)
		donateTitleLabel.Position = UDim2.fromOffset(0, 0)
		donateTitleLabel.Size = UDim2.new(1, 0, 0, 24)
		donateBodyLabel.Position = UDim2.fromOffset(0, 28)
		donateBodyLabel.Size = UDim2.new(1, 0, 0, 48)
		donateProgressBack.Position = UDim2.fromOffset(0, 82)
		donateProgressBack.Size = UDim2.new(1, 0, 0, 24)
		donateButtonsFrame.Position = UDim2.fromOffset(0, 116)
		donateButtonsFrame.Size = UDim2.new(1, 0, 0, 42)
		local smallButtonGap = 7
		local smallButtonWidth = math.floor((rootWidth - 28 - (smallButtonGap * (#donateButtons - 1))) / #donateButtons)
		for index, item in donateButtons do
			item.button.Position = UDim2.fromOffset((index - 1) * (smallButtonWidth + smallButtonGap), 0)
			item.button.Size = UDim2.fromOffset(smallButtonWidth, 42)
		end
		donateStatusLabel.Position = UDim2.fromOffset(0, 162)
		donateStatusLabel.Size = UDim2.new(1, 0, 0, 34)
	else
		local controlsWidth = 1008
		controls.AnchorPoint = Vector2.new(0.5, 0.5)
		controls.Position = UDim2.fromScale(0.61, 0.62)
		controls.Size = UDim2.fromOffset(controlsWidth, buttonHeight)
		local widths = { 136, 112, 132, 150, 140, 142, 140 }
		local x = 0
		for index, button in buttons do
			button.Position = UDim2.fromOffset(x, 0)
			button.Size = UDim2.fromOffset(widths[index], buttonHeight)
			x += widths[index] + gap
		end

		donationPanel.Position = UDim2.fromOffset(300, 20)
		donationPanel.Size = UDim2.new(1, -328, 1, -36)
		donateTitleLabel.Position = UDim2.fromOffset(0, 0)
		donateTitleLabel.Size = UDim2.fromOffset(260, 28)
		donateBodyLabel.Position = UDim2.fromOffset(0, 34)
		donateBodyLabel.Size = UDim2.new(0.46, -12, 0, 64)
		donateProgressBack.Position = UDim2.new(0.46, 12, 0, 14)
		donateProgressBack.Size = UDim2.new(0.32, -24, 0, 28)
		donateButtonsFrame.Position = UDim2.new(0.78, 0, 0, 0)
		donateButtonsFrame.Size = UDim2.new(0.22, 0, 0, 88)
		local buttonGap = 8
		local buttonWidth = math.floor((donateButtonsFrame.AbsoluteSize.X - buttonGap) / 2)
		for index, item in donateButtons do
			local zeroIndex = index - 1
			local column = zeroIndex % 2
			local row = math.floor(zeroIndex / 2)
			item.button.Position = UDim2.fromOffset(column * (buttonWidth + buttonGap), row * 30)
			item.button.Size = UDim2.fromOffset(buttonWidth, 26)
		end
		donateStatusLabel.Position = UDim2.new(0.46, 12, 0, 52)
		donateStatusLabel.Size = UDim2.new(0.32, -24, 0, 48)
	end
end

local function layoutBoard()
	local rootSize = root.AbsoluteSize
	if rootSize.X < 100 or rootSize.Y < 100 then
		return
	end

	local isPortrait = rootSize.Y >= rootSize.X
	local isCompact = rootSize.X < COMPACT_WIDTH or isPortrait
	local isLandscapeCompact = isCompact and not isPortrait
	local bottomHeight = if isLandscapeCompact then COMPACT_LANDSCAPE_BAR_HEIGHT else if isCompact then COMPACT_BAR_HEIGHT else WIDE_BAR_HEIGHT
	local inset = GuiService:GetGuiInset()

	boardOuter.Position = UDim2.fromOffset(0, inset.Y)
	boardOuter.Size = UDim2.new(1, 0, 1, -(bottomHeight + inset.Y))
	bottomBar.Position = UDim2.new(0, 0, 1, -bottomHeight)
	bottomBar.Size = UDim2.new(1, 0, 0, bottomHeight)
	versionLabel.Position = UDim2.new(1, -12, 1, -(bottomHeight + 12))
	zoomControls.Position = UDim2.new(1, -14, 0, inset.Y + 14)
	zoomControls.Size = if isLandscapeCompact then UDim2.fromOffset(92, 42) else UDim2.fromOffset(116, 52)
	zoomOutButton.Position = UDim2.fromOffset(0, 0)
	zoomOutButton.Size = if isLandscapeCompact then UDim2.fromOffset(42, 42) else UDim2.fromOffset(52, 52)
	zoomInButton.Position = if isLandscapeCompact then UDim2.fromOffset(50, 0) else UDim2.fromOffset(64, 0)
	zoomInButton.Size = if isLandscapeCompact then UDim2.fromOffset(42, 42) else UDim2.fromOffset(52, 52)

	currentCellSize = ZOOM_LEVELS[zoomIndex]
	currentBoardWidth = (currentCellSize * COLUMNS) + (CELL_GAP * (COLUMNS - 1))
	currentBoardHeight = (currentCellSize * ROWS) + (CELL_GAP * (ROWS - 1))
	board.Size = UDim2.fromOffset(currentBoardWidth, currentBoardHeight)

	local canvasWidth = math.max(boardOuter.AbsoluteSize.X, currentBoardWidth + (BOARD_MARGIN * 2))
	local canvasHeight = math.max(boardOuter.AbsoluteSize.Y, currentBoardHeight + (BOARD_MARGIN * 2))
	local boardX = math.floor((canvasWidth - currentBoardWidth) / 2)
	local boardY = math.floor((canvasHeight - currentBoardHeight) / 2)
	board.Position = UDim2.fromOffset(boardX, boardY)
	boardOuter.CanvasSize = UDim2.fromOffset(canvasWidth, canvasHeight)

	for row = 1, ROWS do
		for column = 1, COLUMNS do
			local cell = cells[row][column]
			cell.Position = UDim2.fromOffset((column - 1) * (currentCellSize + CELL_GAP), (row - 1) * (currentCellSize + CELL_GAP))
			cell.Size = UDim2.fromOffset(currentCellSize, currentCellSize)
		end
	end

	layoutControls(isCompact, isLandscapeCompact, rootSize.X)
end

local function setZoom(nextZoomIndex)
	if nextZoomIndex < 1 or nextZoomIndex > #ZOOM_LEVELS or nextZoomIndex == zoomIndex then
		return
	end

	local oldCanvasSize = boardOuter.AbsoluteCanvasSize
	local oldViewSize = boardOuter.AbsoluteSize
	local oldCenter = boardOuter.CanvasPosition + Vector2.new(oldViewSize.X / 2, oldViewSize.Y / 2)
	local oldRatioX = if oldCanvasSize.X > 0 then oldCenter.X / oldCanvasSize.X else 0.5
	local oldRatioY = if oldCanvasSize.Y > 0 then oldCenter.Y / oldCanvasSize.Y else 0.5

	zoomIndex = nextZoomIndex
	layoutBoard()
	updateLabels()

	task.defer(function()
		local newCanvasSize = boardOuter.AbsoluteCanvasSize
		local newViewSize = boardOuter.AbsoluteSize
		local targetX = (newCanvasSize.X * oldRatioX) - (newViewSize.X / 2)
		local targetY = (newCanvasSize.Y * oldRatioY) - (newViewSize.Y / 2)
		local maxX = math.max(0, newCanvasSize.X - newViewSize.X)
		local maxY = math.max(0, newCanvasSize.Y - newViewSize.Y)
		boardOuter.CanvasPosition = Vector2.new(math.clamp(targetX, 0, maxX), math.clamp(targetY, 0, maxY))
	end)
end

for row = 1, ROWS do
	cells[row] = {}
	for column = 1, COLUMNS do
		local cell = Instance.new("TextButton")
		cell.Name = string.format("Cell_%02d_%02d", row, column)
		cell.AutoButtonColor = false
		cell.BackgroundColor3 = COLORS.dead
		cell.BorderSizePixel = 0
		cell.Text = ""
		cell.Parent = board
		cells[row][column] = cell
	end
end

gameTabButton.Activated:Connect(function()
	setActiveTab("game")
end)

donateTabButton.Activated:Connect(function()
	setActiveTab("donate")
end)

for _, item in donateButtons do
	item.button.Activated:Connect(function()
		if item.productId <= 0 then
			return
		end

		MarketplaceService:PromptProductPurchase(player, item.productId)
	end)
end

startButton.Activated:Connect(function()
	setRunning(not running)
end)

nextButton.Activated:Connect(function()
	stepSimulation()
end)

clearButton.Activated:Connect(clearGrid)
randomButton.Activated:Connect(randomizeGrid)
patternButton.Activated:Connect(placePattern)
speedButton.Activated:Connect(cycleSpeed)
modeButton.Activated:Connect(function()
	setInputMode(if inputMode == "draw" then "move" else "draw")
end)
zoomOutButton.Activated:Connect(function()
	setZoom(zoomIndex - 1)
end)
zoomInButton.Activated:Connect(function()
	setZoom(zoomIndex + 1)
end)

UserInputService.InputBegan:Connect(beginDrawing)
UserInputService.InputBegan:Connect(beginPanning)
UserInputService.InputChanged:Connect(continueDrawing)
UserInputService.InputChanged:Connect(continuePanning)
UserInputService.InputEnded:Connect(endDrawing)
UserInputService.InputEnded:Connect(endPanning)
UserInputService.LastInputTypeChanged:Connect(syncBoardScrolling)

root:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutBoard)
boardOuter:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutBoard)

bindDonationTotal()
pollDonationTotal()
setActiveTab("game")
syncBoardScrolling()
layoutBoard()
renderGrid()

task.spawn(function()
	while screenGui.Parent do
		if running then
			stepSimulation()
		end
		task.wait(SPEEDS[speedIndex].seconds)
	end
end)

task.spawn(function()
	while screenGui.Parent do
		RunService:UnbindFromRenderStep("BoardCamera")
		muteAllAudio()
		removeRobloxCharacterSounds()
		for _, instance in Workspace:GetDescendants() do
			hideWorkspacePart(instance)
		end
		for _, child in playerGui:GetChildren() do
			if child ~= screenGui and (
				child.Name == "Board2D"
				or child.Name == "Board2D_v05"
				or child.Name == "Board2D_v06"
				or child.Name == "BoardCameraStatus"
			) then
				child:Destroy()
			end
		end
		task.wait(1)
	end
end)
