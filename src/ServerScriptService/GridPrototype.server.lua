local ReplicatedFirst = game:GetService("ReplicatedFirst")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

local namesToDelete = {
	Board2D = true,
	Board2D_v05 = true,
	Board2D_v06 = true,
	BoardCamera = true,
	BoardCameraStatus = true,
	Force2D = true,
	GameOfLifeUI = true,
	GridPrototype = true,
}

local function cleanChildren(parent)
	for _, child in parent:GetChildren() do
		if namesToDelete[child.Name] then
			child:Destroy()
		end
	end
end

cleanChildren(ReplicatedFirst)
cleanChildren(StarterGui)

local starterPlayerScripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
if starterPlayerScripts then
	cleanChildren(starterPlayerScripts)
end

for _, instance in Workspace:GetDescendants() do
	if namesToDelete[instance.Name] or instance:IsA("BasePart") then
		instance:Destroy()
	end
end
