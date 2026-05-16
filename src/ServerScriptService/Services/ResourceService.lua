-- ResourceService
-- Создаёт простые деревья, камни и золотую жилу, которые можно собирать повторяемо.

local Workspace = game:GetService("Workspace")

local PlayerDataService = require(script.Parent.PlayerDataService)
local QuestService = require(script.Parent.QuestService)
local CurrencyService = require(script.Parent.CurrencyService)

local ResourceService = {}

local RESOURCE_FOLDER_NAME = "ResourceNodes"
local QUEST_ID = "first_steps"
local OBJECTIVE_ID = "wood_collected"
local TREE_RESPAWN_SECONDS = 10
local STONE_RESPAWN_SECONDS = 10
local GOLD_COOLDOWN_SECONDS = 2

local TREE_POSITIONS = {
	Vector3.new(20, 2, 8),
	Vector3.new(25, 2, 10),
	Vector3.new(30, 2, 6),
}

local STONE_POSITIONS = {
	Vector3.new(18, 1.2, 18),
	Vector3.new(24, 1.2, 20),
	Vector3.new(30, 1.2, 18),
}

local GOLD_NODE_POSITION = Vector3.new(36, 1.4, 18)
local goldMineCooldownsByUserId = {}

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

local function setTreeAvailable(treeModel, prompt, isAvailable)
	for _, descendant in ipairs(treeModel:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Transparency = if isAvailable then 0 else 1
			descendant.CanCollide = isAvailable
			descendant.CanTouch = isAvailable
			descendant.CanQuery = isAvailable
		end
	end

	prompt.Enabled = isAvailable
end

local function respawnTreeAfterDelay(treeModel, prompt)
	task.delay(TREE_RESPAWN_SECONDS, function()
		if not treeModel.Parent then
			return
		end

		setTreeAvailable(treeModel, prompt, true)
		print("[ResourceService] Tree respawned")
	end)
end

local function setStoneAvailable(stoneModel, prompt, isAvailable)
	for _, descendant in ipairs(stoneModel:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Transparency = if isAvailable then 0 else 1
			descendant.CanCollide = isAvailable
			descendant.CanTouch = isAvailable
			descendant.CanQuery = isAvailable
		end
	end

	prompt.Enabled = isAvailable
end

local function respawnStoneAfterDelay(stoneModel, prompt)
	task.delay(STONE_RESPAWN_SECONDS, function()
		if not stoneModel.Parent then
			return
		end

		setStoneAvailable(stoneModel, prompt, true)
		print("[ResourceService] Stone respawned")
	end)
end

local function updateQuestProgressIfActive(player, profile)
	if profile.CompletedQuests[QUEST_ID] then
		return
	end

	if profile.CurrentQuestId ~= QUEST_ID then
		return
	end

	QuestService.AddQuestProgress(player, QUEST_ID, OBJECTIVE_ID, 1)
end

local function collectTree(player, treeModel, prompt)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[ResourceService] Profile for %s was not found. Tree was not collected.", player.Name))
		return
	end

	if not prompt.Enabled then
		return
	end

	setTreeAvailable(treeModel, prompt, false)

	updateQuestProgressIfActive(player, profile)

	CurrencyService.AddWood(player, 1)
	print("[ResourceService] Sent profile UI update after resource collect")
	print(string.format("[ResourceService] %s collected wood", player.Name))
	respawnTreeAfterDelay(treeModel, prompt)
end

local function mineStone(player, stoneModel, prompt)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[ResourceService] Profile for %s was not found. Stone was not mined.", player.Name))
		return
	end

	if not prompt.Enabled then
		return
	end

	setStoneAvailable(stoneModel, prompt, false)

	CurrencyService.AddStone(player, 1)
	print(string.format("[ResourceService] %s mined stone", player.Name))
	respawnStoneAfterDelay(stoneModel, prompt)
end

local function canMineGold(player)
	local now = os.clock()
	local lastMineAt = goldMineCooldownsByUserId[player.UserId]

	if lastMineAt and now - lastMineAt < GOLD_COOLDOWN_SECONDS then
		return false
	end

	goldMineCooldownsByUserId[player.UserId] = now
	return true
end

local function mineGold(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[ResourceService] Profile for %s was not found. Gold was not mined.", player.Name))
		return
	end

	if not canMineGold(player) then
		print(string.format("[ResourceService] %s tried to mine gold during cooldown", player.Name))
		return
	end

	CurrencyService.AddGold(player, 1)
	print(string.format("[ResourceService] %s mined gold", player.Name))
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

local function createStone(index, position, parent)
	local stoneModel = Instance.new("Model")
	stoneModel.Name = string.format("Stone_%d", index)
	stoneModel.Parent = parent

	local stone = createPart(
		"Stone",
		Vector3.new(4, 2.4, 3.5),
		position,
		Color3.fromRGB(115, 120, 125),
		stoneModel
	)
	stone.Shape = Enum.PartType.Ball
	stone.Material = Enum.Material.Slate

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "MinePrompt"
	prompt.ActionText = "Добыть"
	prompt.ObjectText = "Камень"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = stone

	prompt.Triggered:Connect(function(player)
		mineStone(player, stoneModel, prompt)
	end)

	stoneModel.PrimaryPart = stone

	return stoneModel
end

local function createGoldNode(parent)
	local goldNode = Instance.new("Model")
	goldNode.Name = "GoldNode_01"
	goldNode.Parent = parent

	local vein = createPart(
		"GoldVein",
		Vector3.new(5, 2.8, 3.5),
		GOLD_NODE_POSITION,
		Color3.fromRGB(215, 165, 45),
		goldNode
	)
	vein.Shape = Enum.PartType.Ball
	vein.Material = Enum.Material.Slate

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "MineGoldPrompt"
	prompt.ActionText = "Добывать золото"
	prompt.ObjectText = "Золотая жила"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = vein

	prompt.Triggered:Connect(function(player)
		mineGold(player)
	end)

	goldNode.PrimaryPart = vein

	return goldNode
end

function ResourceService.CreateResourceNodes()
	local resourceNodes = Workspace:FindFirstChild(RESOURCE_FOLDER_NAME)

	if not resourceNodes then
		resourceNodes = Instance.new("Folder")
		resourceNodes.Name = RESOURCE_FOLDER_NAME
		resourceNodes.Parent = Workspace
	end

	for index, position in ipairs(TREE_POSITIONS) do
		local treeName = string.format("Tree_%d", index)

		if not resourceNodes:FindFirstChild(treeName) then
			createTree(index, position, resourceNodes)
		end
	end

	for index, position in ipairs(STONE_POSITIONS) do
		local stoneName = string.format("Stone_%d", index)

		if not resourceNodes:FindFirstChild(stoneName) then
			createStone(index, position, resourceNodes)
		end
	end

	if not resourceNodes:FindFirstChild("GoldNode_01") then
		createGoldNode(resourceNodes)
	end

	print("[ResourceService] Resource nodes are ready: 3 trees, 3 stones and 1 gold node.")
	return resourceNodes
end

return ResourceService
