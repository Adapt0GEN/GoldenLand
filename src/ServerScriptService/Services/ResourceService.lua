-- ResourceService
-- Создаёт простые деревья и добавляет прогресс квеста при сборе.

local Workspace = game:GetService("Workspace")

local PlayerDataService = require(script.Parent.PlayerDataService)
local QuestService = require(script.Parent.QuestService)
local CurrencyService = require(script.Parent.CurrencyService)

local ResourceService = {}

local RESOURCE_FOLDER_NAME = "ResourceNodes"
local QUEST_ID = "first_steps"
local OBJECTIVE_ID = "wood_collected"

local TREE_POSITIONS = {
	Vector3.new(20, 2, 8),
	Vector3.new(25, 2, 10),
	Vector3.new(30, 2, 6),
}

local function createPart(name, size, position, color, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.Color = color
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent

	return part
end

local function getWoodTarget()
	return QuestService.Quests[QUEST_ID].Objectives[OBJECTIVE_ID].TargetAmount
end

local function collectTree(player, treeModel, prompt)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[ResourceService] Profile for %s was not found. Tree was not collected.", player.Name))
		return
	end

	if profile.CompletedQuests[QUEST_ID] then
		print(string.format("[ResourceService] %s already completed the wood quest.", player.Name))
		return
	end

	if profile.CurrentQuestId ~= QUEST_ID then
		print(string.format("[ResourceService] %s must talk to the village elder before collecting quest wood.", player.Name))
		return
	end

	prompt.Enabled = false

	local newProgress = QuestService.AddQuestProgress(player, QUEST_ID, OBJECTIVE_ID, 1)

	if newProgress == nil then
		prompt.Enabled = true
		return
	end

	CurrencyService.AddWood(player, 1)
	treeModel:Destroy()

	print(string.format(
		"[ResourceService] %s collected a tree. Wood progress: %d/%d.",
		player.Name,
		newProgress,
		getWoodTarget()
	))
end

local function createTree(index, position, parent)
	local treeModel = Instance.new("Model")
	treeModel.Name = string.format("Tree_%d", index)
	treeModel.Parent = parent

	-- Простое дерево из ствола и кроны, без внешних ассетов.
	local trunk = createPart(
		"Trunk",
		Vector3.new(1.2, 4, 1.2),
		position,
		Color3.fromRGB(110, 70, 35),
		treeModel
	)

	local leaves = createPart(
		"Leaves",
		Vector3.new(5, 5, 5),
		position + Vector3.new(0, 3, 0),
		Color3.fromRGB(50, 135, 65),
		treeModel
	)
	leaves.Shape = Enum.PartType.Ball

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "CollectPrompt"
	prompt.ActionText = "Собрать"
	prompt.ObjectText = "Дерево"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = trunk

	prompt.Triggered:Connect(function(player)
		collectTree(player, treeModel, prompt)
	end)

	treeModel.PrimaryPart = trunk

	return treeModel
end

function ResourceService.CreateResourceNodes()
	local existingNodes = Workspace:FindFirstChild(RESOURCE_FOLDER_NAME)

	if existingNodes then
		print("[ResourceService] Resource nodes already exist.")
		return existingNodes
	end

	local resourceNodes = Instance.new("Folder")
	resourceNodes.Name = RESOURCE_FOLDER_NAME
	resourceNodes.Parent = Workspace

	for index, position in ipairs(TREE_POSITIONS) do
		createTree(index, position, resourceNodes)
	end

	print("[ResourceService] Created 3 tree resource nodes.")
	return resourceNodes
end

return ResourceService
