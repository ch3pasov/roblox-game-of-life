local GuiService = game:GetService("GuiService")
local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local UI_VERSION = "Life v1.2"

local ROWS = 28
local COLUMNS = 42
local BOARD_MARGIN = 14
local CELL_GAP = 1
local RANDOM_FILL_CHANCE = 0.25

local WIDE_BAR_HEIGHT = 118
local COMPACT_BAR_HEIGHT = 184
local COMPACT_WIDTH = 760

local SPEEDS = {
	{ key = "slow", seconds = 0.36 },
	{ key = "normal", seconds = 0.18 },
	{ key = "fast", seconds = 0.08 },
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
		next = "Next",
		clear = "Clear",
		random = "Random",
		generation = "Generation %d",
		speed = "Speed: %s",
		slow = "Slow",
		normal = "Normal",
		fast = "Fast",
	},
	ru = {
		start = "Старт",
		stop = "Стоп",
		next = "Шаг",
		clear = "Очистить",
		random = "Случайно",
		generation = "Поколение %d",
		speed = "Скорость: %s",
		slow = "Медленно",
		normal = "Нормально",
		fast = "Быстро",
	},
}

RunService:UnbindFromRenderStep("BoardCamera")

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
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
local currentCellSize = 8
local currentBoardWidth = 0
local currentBoardHeight = 0
local painting = false
local paintState = false
local paintedThisGesture = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
removeOldGui(playerGui)

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

local boardOuter = Instance.new("Frame")
boardOuter.Name = "BoardOuter"
boardOuter.BackgroundColor3 = COLORS.background
boardOuter.BorderSizePixel = 0
boardOuter.Parent = root

local board = Instance.new("Frame")
board.Name = "Board"
board.AnchorPoint = Vector2.new(0.5, 0.5)
board.BackgroundColor3 = COLORS.gridLine
board.BorderSizePixel = 0
board.Position = UDim2.fromScale(0.5, 0.5)
board.Parent = boardOuter

local bottomBar = Instance.new("Frame")
bottomBar.Name = "BottomBar"
bottomBar.BackgroundColor3 = COLORS.bar
bottomBar.BorderSizePixel = 0
bottomBar.Parent = root

local versionLabel = Instance.new("TextLabel")
versionLabel.Name = "VersionLabel"
versionLabel.AnchorPoint = Vector2.new(1, 0)
versionLabel.BackgroundTransparency = 0.25
versionLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
versionLabel.BorderSizePixel = 0
versionLabel.Position = UDim2.new(1, -12, 0, 12)
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

local function makeButton(name)
	local button = Instance.new("TextButton")
	button.Name = name
	button.AutoButtonColor = true
	button.BackgroundColor3 = COLORS.button
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.TextColor3 = COLORS.buttonText
	button.TextScaled = true
	button.Parent = controls

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
local speedButton = makeButton("SpeedButton")
local buttons = { startButton, nextButton, clearButton, randomButton, speedButton }

local function updateLabels()
	generationLabel.Text = string.format(t.generation, generation)
	speedLabel.Text = string.format(t.speed, t[SPEEDS[speedIndex].key])
	startButton.Text = if running then t.stop else t.start
	startButton.BackgroundColor3 = if running then COLORS.buttonActive else COLORS.button
	nextButton.Text = t.next
	clearButton.Text = t.clear
	randomButton.Text = t.random
	speedButton.Text = t[SPEEDS[speedIndex].key]
end

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
	setRunning(false)
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

local function cellFromScreenPosition(position)
	local localX = position.X - board.AbsolutePosition.X
	local localY = position.Y - board.AbsolutePosition.Y
	if localX < 0 or localY < 0 or localX > currentBoardWidth or localY > currentBoardHeight then
		return nil, nil
	end

	local column = math.floor(localX / (currentCellSize + CELL_GAP)) + 1
	local row = math.floor(localY / (currentCellSize + CELL_GAP)) + 1
	if row < 1 or row > ROWS or column < 1 or column > COLUMNS then
		return nil, nil
	end

	return row, column
end

local function paintAtPosition(position)
	local row, column = cellFromScreenPosition(position)
	if not row or not column then
		return
	end

	local key = string.format("%d:%d", row, column)
	if paintedThisGesture[key] then
		return
	end

	paintedThisGesture[key] = true
	setCell(row, column, paintState)
end

local function beginPaint(row, column, input)
	painting = true
	paintedThisGesture = {}
	paintState = not grid[row][column]
	setCell(row, column, paintState)
	paintedThisGesture[string.format("%d:%d", row, column)] = true

	if input then
		paintAtPosition(input.Position)
	end
end

local function endPaint()
	painting = false
	paintedThisGesture = {}
end

local function layoutControls(isCompact, rootWidth)
	local gap = if isCompact then 10 else 16
	local buttonHeight = if isCompact then 44 else 54
	local leftPadding = if isCompact then 14 else 28
	local labelWidth = if isCompact then math.floor((rootWidth - 42) / 2) else 190

	generationLabel.Position = UDim2.fromOffset(leftPadding, if isCompact then 10 else 38)
	generationLabel.Size = UDim2.fromOffset(labelWidth, 28)
	speedLabel.Position = UDim2.fromOffset(if isCompact then leftPadding + labelWidth + 14 else leftPadding, if isCompact then 40 else 64)
	speedLabel.Size = UDim2.fromOffset(labelWidth, 28)

	if isCompact then
		controls.AnchorPoint = Vector2.new(0, 0)
		controls.Position = UDim2.fromOffset(14, 74)
		controls.Size = UDim2.new(1, -28, 0, 98)
		local controlsWidth = rootWidth - 28
		local buttonWidth = math.floor((controlsWidth - (gap * 2)) / 3)
		local secondRowWidth = math.floor((controlsWidth - gap) / 2)
		local positions = {
			{ 0, 0, buttonWidth },
			{ buttonWidth + gap, 0, buttonWidth },
			{ (buttonWidth + gap) * 2, 0, buttonWidth },
			{ 0, buttonHeight + gap, secondRowWidth },
			{ secondRowWidth + gap, buttonHeight + gap, secondRowWidth },
		}

		for index, button in buttons do
			local item = positions[index]
			button.Position = UDim2.fromOffset(item[1], item[2])
			button.Size = UDim2.fromOffset(item[3], buttonHeight)
		end
	else
		local controlsWidth = 790
		controls.AnchorPoint = Vector2.new(0.5, 0.5)
		controls.Position = UDim2.fromScale(0.6, 0.5)
		controls.Size = UDim2.fromOffset(controlsWidth, buttonHeight)
		local widths = { 160, 130, 150, 165, 145 }
		local x = 0
		for index, button in buttons do
			button.Position = UDim2.fromOffset(x, 0)
			button.Size = UDim2.fromOffset(widths[index], buttonHeight)
			x += widths[index] + gap
		end
	end
end

local function layoutBoard()
	local rootSize = root.AbsoluteSize
	if rootSize.X < 100 or rootSize.Y < 100 then
		return
	end

	local isCompact = rootSize.X < COMPACT_WIDTH or rootSize.Y > rootSize.X
	local bottomHeight = if isCompact then COMPACT_BAR_HEIGHT else WIDE_BAR_HEIGHT
	local inset = GuiService:GetGuiInset()

	boardOuter.Position = UDim2.fromOffset(0, inset.Y)
	boardOuter.Size = UDim2.new(1, 0, 1, -(bottomHeight + inset.Y))
	bottomBar.Position = UDim2.new(0, 0, 1, -bottomHeight)
	bottomBar.Size = UDim2.new(1, 0, 0, bottomHeight)

	local availableWidth = math.max(1, boardOuter.AbsoluteSize.X - (BOARD_MARGIN * 2))
	local availableHeight = math.max(1, boardOuter.AbsoluteSize.Y - (BOARD_MARGIN * 2))
	currentCellSize = math.floor(math.min(availableWidth / COLUMNS, availableHeight / ROWS))
	currentCellSize = math.max(if isCompact then 7 else 8, currentCellSize)

	currentBoardWidth = (currentCellSize * COLUMNS) + (CELL_GAP * (COLUMNS - 1))
	currentBoardHeight = (currentCellSize * ROWS) + (CELL_GAP * (ROWS - 1))
	board.Size = UDim2.fromOffset(currentBoardWidth, currentBoardHeight)

	for row = 1, ROWS do
		for column = 1, COLUMNS do
			local cell = cells[row][column]
			cell.Position = UDim2.fromOffset((column - 1) * (currentCellSize + CELL_GAP), (row - 1) * (currentCellSize + CELL_GAP))
			cell.Size = UDim2.fromOffset(currentCellSize, currentCellSize)
		end
	end

	layoutControls(isCompact, rootSize.X)
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

		cell.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				beginPaint(row, column, input)
			end
		end)
	end
end

UserInputService.InputChanged:Connect(function(input)
	if not painting then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		paintAtPosition(input.Position)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		endPaint()
	end
end)

startButton.Activated:Connect(function()
	setRunning(not running)
end)

nextButton.Activated:Connect(function()
	stepSimulation()
end)

clearButton.Activated:Connect(clearGrid)
randomButton.Activated:Connect(randomizeGrid)
speedButton.Activated:Connect(cycleSpeed)

root:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutBoard)
boardOuter:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutBoard)

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
	for _ = 1, 40 do
		RunService:UnbindFromRenderStep("BoardCamera")
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
		task.wait(0.25)
	end
end)
