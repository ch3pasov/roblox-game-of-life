local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local UI_VERSION = "Life v1.1"
local ROWS = 28
local COLUMNS = 42
local BOTTOM_BAR_HEIGHT = 118
local BOARD_MARGIN = 18
local CELL_GAP = 1
local STEP_SECONDS = 0.18

local BACKGROUND = Color3.fromRGB(28, 30, 35)
local BOARD_BACKGROUND = Color3.fromRGB(73, 75, 78)
local GRID_LINE = Color3.fromRGB(104, 106, 109)
local DEAD = Color3.fromRGB(132, 134, 136)
local ALIVE = Color3.fromRGB(255, 232, 32)
local BAR = Color3.fromRGB(188, 188, 188)
local BUTTON = Color3.fromRGB(45, 86, 166)
local BUTTON_ACTIVE = Color3.fromRGB(30, 132, 93)
local BUTTON_TEXT = Color3.fromRGB(255, 255, 255)

RunService:UnbindFromRenderStep("BoardCamera")

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
end)

for _, instance in Workspace:GetDescendants() do
	if instance:IsA("BasePart") then
		instance.LocalTransparencyModifier = 1
		instance.CanQuery = false
	end
end

Workspace.DescendantAdded:Connect(function(instance)
	if instance:IsA("BasePart") then
		instance.LocalTransparencyModifier = 1
		instance.CanQuery = false
	end
end)

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
root.BackgroundColor3 = BACKGROUND
root.BorderSizePixel = 0
root.Size = UDim2.fromScale(1, 1)
root.Parent = screenGui

local boardOuter = Instance.new("Frame")
boardOuter.Name = "BoardOuter"
boardOuter.BackgroundColor3 = BACKGROUND
boardOuter.BorderSizePixel = 0
boardOuter.Position = UDim2.fromOffset(0, 0)
boardOuter.Size = UDim2.new(1, 0, 1, -BOTTOM_BAR_HEIGHT)
boardOuter.Parent = root

local board = Instance.new("Frame")
board.Name = "Board"
board.AnchorPoint = Vector2.new(0.5, 0.5)
board.BackgroundColor3 = GRID_LINE
board.BorderSizePixel = 0
board.Position = UDim2.fromScale(0.5, 0.5)
board.Parent = boardOuter

local bottomBar = Instance.new("Frame")
bottomBar.Name = "BottomBar"
bottomBar.AnchorPoint = Vector2.new(0, 1)
bottomBar.BackgroundColor3 = BAR
bottomBar.BorderSizePixel = 0
bottomBar.Position = UDim2.fromScale(0, 1)
bottomBar.Size = UDim2.new(1, 0, 0, BOTTOM_BAR_HEIGHT)
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
versionLabel.TextColor3 = BUTTON_TEXT
versionLabel.TextSize = 12
versionLabel.Parent = root

local generationLabel = Instance.new("TextLabel")
generationLabel.Name = "GenerationLabel"
generationLabel.AnchorPoint = Vector2.new(0, 0.5)
generationLabel.BackgroundTransparency = 1
generationLabel.Position = UDim2.new(0, 28, 0.5, 0)
generationLabel.Size = UDim2.fromOffset(180, 42)
generationLabel.Font = Enum.Font.GothamMedium
generationLabel.Text = "Generation 0"
generationLabel.TextColor3 = Color3.fromRGB(52, 54, 58)
generationLabel.TextSize = 20
generationLabel.TextXAlignment = Enum.TextXAlignment.Left
generationLabel.Parent = bottomBar

local controls = Instance.new("Frame")
controls.Name = "Controls"
controls.AnchorPoint = Vector2.new(0.5, 0.5)
controls.BackgroundTransparency = 1
controls.Position = UDim2.fromScale(0.58, 0.5)
controls.Size = UDim2.fromOffset(720, 68)
controls.Parent = bottomBar

local controlsLayout = Instance.new("UIListLayout")
controlsLayout.FillDirection = Enum.FillDirection.Horizontal
controlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
controlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
controlsLayout.Padding = UDim.new(0, 18)
controlsLayout.Parent = controls

local function makeButton(name, text, width)
	local button = Instance.new("TextButton")
	button.Name = name
	button.AutoButtonColor = true
	button.BackgroundColor3 = BUTTON
	button.BorderSizePixel = 0
	button.Size = UDim2.fromOffset(width, 54)
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.TextColor3 = BUTTON_TEXT
	button.TextSize = 24
	button.Parent = controls

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 18)
	corner.Parent = button

	return button
end

local startButton = makeButton("StartButton", "Start", 190)
local nextButton = makeButton("NextButton", "Next", 160)
local clearButton = makeButton("ClearButton", "Clear", 170)

local function updateGenerationLabel()
	generationLabel.Text = string.format("Generation %d", generation)
end

local function renderCell(row, column)
	local cell = cells[row][column]
	cell.BackgroundColor3 = if grid[row][column] then ALIVE else DEAD
end

local function renderGrid()
	for row = 1, ROWS do
		for column = 1, COLUMNS do
			renderCell(row, column)
		end
	end
	updateGenerationLabel()
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
	startButton.Text = if running then "Stop" else "Start"
	startButton.BackgroundColor3 = if running then BUTTON_ACTIVE else BUTTON
end

local function clearGrid()
	grid = makeGrid()
	generation = 0
	setRunning(false)
	renderGrid()
end

local function layoutBoard()
	local availableWidth = math.max(1, boardOuter.AbsoluteSize.X - (BOARD_MARGIN * 2))
	local availableHeight = math.max(1, boardOuter.AbsoluteSize.Y - (BOARD_MARGIN * 2))
	local cellSize = math.floor(math.min(availableWidth / COLUMNS, availableHeight / ROWS))
	cellSize = math.max(8, cellSize)

	local boardWidth = (cellSize * COLUMNS) + (CELL_GAP * (COLUMNS - 1))
	local boardHeight = (cellSize * ROWS) + (CELL_GAP * (ROWS - 1))
	board.Size = UDim2.fromOffset(boardWidth, boardHeight)

	for row = 1, ROWS do
		for column = 1, COLUMNS do
			local cell = cells[row][column]
			cell.Position = UDim2.fromOffset((column - 1) * (cellSize + CELL_GAP), (row - 1) * (cellSize + CELL_GAP))
			cell.Size = UDim2.fromOffset(cellSize, cellSize)
		end
	end
end

for row = 1, ROWS do
	cells[row] = {}
	for column = 1, COLUMNS do
		local cell = Instance.new("TextButton")
		cell.Name = string.format("Cell_%02d_%02d", row, column)
		cell.AutoButtonColor = false
		cell.BackgroundColor3 = DEAD
		cell.BorderSizePixel = 0
		cell.Text = ""
		cell.Parent = board
		cells[row][column] = cell

		cell.Activated:Connect(function()
			grid[row][column] = not grid[row][column]
			renderCell(row, column)
		end)
	end
end

startButton.Activated:Connect(function()
	setRunning(not running)
end)

nextButton.Activated:Connect(function()
	stepSimulation()
end)

clearButton.Activated:Connect(clearGrid)

boardOuter:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutBoard)

layoutBoard()
renderGrid()

task.spawn(function()
	while screenGui.Parent do
		if running then
			stepSimulation()
		end
		task.wait(STEP_SECONDS)
	end
end)

task.spawn(function()
	for _ = 1, 40 do
		RunService:UnbindFromRenderStep("BoardCamera")
		hideWorkspaceParts()
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
