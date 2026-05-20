-- ResourceService
-- Создаёт простые деревья, камни, металлическую руду и золотую жилу, которые можно собирать повторяемо.

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
local METAL_RESPAWN_SECONDS = 10
local ROCK_RESOURCE_RESPAWN_SECONDS = 15
local GOLD_COOLDOWN_SECONDS = 2
local FOREST_ZONE_RESOURCES_FOLDER_NAME = "ForestZoneResources"
local ROCK_ZONE_RESOURCES_FOLDER_NAME = "RockZoneResources"
local FOREST_AREA_ID = "ForestArea_01"
local FOREST_AREA_DEFAULT_REMAINING_ACTIONS = 12
local FOREST_AREA_DEBOUNCE_SECONDS = 0.6
local FOREST_TREE_CLUSTER_ID = "ForestTreeCluster"
local FOREST_STONE_OBJECT_IDS = {
	"ForestStone_01",
	"ForestStone_02",
}

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

local METAL_POSITIONS = {
	Vector3.new(14, 1.2, 28),
	Vector3.new(21, 1.2, 31),
	Vector3.new(28, 1.2, 28),
}

local GOLD_NODE_POSITION = Vector3.new(36, 1.4, 18)
local FOREST_STONE_POSITIONS = {
	Vector3.new(-45, 1.1, 12),
	Vector3.new(-33, 1.1, -2),
}
local ROCK_RICH_STONE_POSITIONS = {
	Vector3.new(-86, 1.2, 2),
	Vector3.new(-72, 1.2, 13),
}
local ROCK_METAL_VEIN_POSITIONS = {
	Vector3.new(-82, 1.2, 14),
	Vector3.new(-68, 1.2, 4),
}
local goldMineCooldownsByUserId = {}
local forestAreaHarvestCooldownsByUserId = {}

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

local function setForestResourceAvailable(resourceModel, prompt, isAvailable)
	for _, descendant in ipairs(resourceModel:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Transparency = if isAvailable then 0 else 1
			descendant.CanCollide = isAvailable
			descendant.CanTouch = isAvailable
			descendant.CanQuery = isAvailable
		end
	end

	prompt.Enabled = isAvailable
end

local function setMetalAvailable(metalModel, prompt, isAvailable)
	for _, descendant in ipairs(metalModel:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Transparency = if isAvailable then 0 else 1
			descendant.CanCollide = isAvailable
			descendant.CanTouch = isAvailable
			descendant.CanQuery = isAvailable
		end
	end

	prompt.Enabled = isAvailable
end

local function respawnMetalAfterDelay(metalModel, prompt)
	task.delay(METAL_RESPAWN_SECONDS, function()
		if not metalModel.Parent then
			return
		end

		setMetalAvailable(metalModel, prompt, true)
		print("[ResourceService] Metal node respawned")
	end)
end

local function setRockResourceAvailable(resourceModel, prompt, isAvailable)
	for _, descendant in ipairs(resourceModel:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Transparency = if isAvailable then 0 else 1
			descendant.CanCollide = isAvailable
			descendant.CanTouch = isAvailable
			descendant.CanQuery = isAvailable
		end
	end

	prompt.Enabled = isAvailable
end

local function respawnRockResourceAfterDelay(resourceModel, prompt, logMessage)
	task.delay(ROCK_RESOURCE_RESPAWN_SECONDS, function()
		if not resourceModel.Parent then
			return
		end

		setRockResourceAvailable(resourceModel, prompt, true)
		print(logMessage)
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

local function mineMetal(player, metalModel, prompt)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[ResourceService] Profile for %s was not found. Metal was not mined.", player.Name))
		return
	end

	if not prompt.Enabled then
		return
	end

	setMetalAvailable(metalModel, prompt, false)

	CurrencyService.AddMetal(player, 1)
	print(string.format("[ResourceService] %s mined metal", player.Name))
	respawnMetalAfterDelay(metalModel, prompt)
end

local function mineRichStone(player, richStoneModel, prompt)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[ResourceService] Profile for %s was not found. Rich stone was not mined.", player.Name))
		return
	end

	if profile.RockZoneUnlocked ~= true then
		warn(string.format("[ResourceService] %s cannot mine rich stone: RockZone is locked.", player.Name))
		return
	end

	if not prompt.Enabled then
		return
	end

	setRockResourceAvailable(richStoneModel, prompt, false)
	CurrencyService.AddStone(player, 4)
	print(string.format("[ResourceService] %s mined rich stone", player.Name))
	respawnRockResourceAfterDelay(richStoneModel, prompt, "[ResourceService] RichStoneNode respawned")
end

local function mineMetalVein(player, metalVeinModel, prompt)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[ResourceService] Profile for %s was not found. Metal vein was not mined.", player.Name))
		return
	end

	if profile.RockZoneUnlocked ~= true then
		warn(string.format("[ResourceService] %s cannot mine metal vein: RockZone is locked.", player.Name))
		return
	end

	if not prompt.Enabled then
		return
	end

	setRockResourceAvailable(metalVeinModel, prompt, false)
	CurrencyService.AddMetal(player, 3)
	print(string.format("[ResourceService] %s mined metal vein", player.Name))
	respawnRockResourceAfterDelay(metalVeinModel, prompt, "[ResourceService] MetalVein respawned")
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

local function canUseForestResources(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[ResourceService] Profile for %s was not found. Forest resource was not collected.", player.Name))
		return false
	end

	return profile.ForestUnlocked == true
end

local function createDefaultForestAreaZone()
	return {
		Type = "ForestArea",
		State = "Active",
		RemainingActions = FOREST_AREA_DEFAULT_REMAINING_ACTIONS,
		Objects = {
			ForestTreeCluster = {
				Type = "TreeCluster",
				State = "Active",
				Resource = "Wood",
				RemainingActions = FOREST_AREA_DEFAULT_REMAINING_ACTIONS,
				AmountPerAction = 1,
			},
			ForestStone_01 = {
				Type = "StoneNode",
				State = "Active",
				Resource = "Stone",
				RemainingActions = 1,
				AmountPerAction = 2,
			},
			ForestStone_02 = {
				Type = "StoneNode",
				State = "Active",
				Resource = "Stone",
				RemainingActions = 1,
				AmountPerAction = 2,
			},
		},
	}
end

local function ensureForestObject(forestZone, objectId, defaultObject, maxRemainingActions)
	forestZone.Objects[objectId] = forestZone.Objects[objectId] or {}

	local resourceObject = forestZone.Objects[objectId]
	resourceObject.Type = resourceObject.Type or defaultObject.Type
	resourceObject.State = resourceObject.State or defaultObject.State
	resourceObject.Resource = resourceObject.Resource or defaultObject.Resource
	resourceObject.AmountPerAction = resourceObject.AmountPerAction or defaultObject.AmountPerAction
	resourceObject.RemainingActions = math.clamp(
		resourceObject.RemainingActions or defaultObject.RemainingActions,
		0,
		maxRemainingActions
	)
	resourceObject.State = if resourceObject.State == "Empty" or resourceObject.RemainingActions <= 0 then "Empty" else "Active"

	return resourceObject
end

local function isForestObjectActive(resourceObject)
	return type(resourceObject) == "table"
		and resourceObject.State ~= "Empty"
		and (resourceObject.RemainingActions or 0) > 0
end

local function syncForestZoneClearedObject(profile, objectId, resourceObject)
	profile.ForestZoneClearedObjects = profile.ForestZoneClearedObjects or {}

	if type(resourceObject) == "table"
		and (resourceObject.State == "Empty" or (resourceObject.RemainingActions or 0) <= 0)
	then
		profile.ForestZoneClearedObjects[objectId] = true
	end
end

local function syncForestZoneClearedObjects(profile, forestZone)
	for objectId, resourceObject in pairs(forestZone.Objects or {}) do
		syncForestZoneClearedObject(profile, objectId, resourceObject)
	end
end

local function ensureForestAreaZone(profile)
	profile.ResourceZones = profile.ResourceZones or {}

	if type(profile.ResourceZones[FOREST_AREA_ID]) ~= "table" then
		profile.ResourceZones[FOREST_AREA_ID] = createDefaultForestAreaZone()
	end

	local forestZone = profile.ResourceZones[FOREST_AREA_ID]
	local defaults = createDefaultForestAreaZone()
	forestZone.Type = forestZone.Type or "ForestArea"
	forestZone.Objects = forestZone.Objects or {}

	local treeCluster = ensureForestObject(
		forestZone,
		FOREST_TREE_CLUSTER_ID,
		defaults.Objects.ForestTreeCluster,
		FOREST_AREA_DEFAULT_REMAINING_ACTIONS
	)

	if type(forestZone.RemainingActions) == "number"
		and (forestZone.Objects.ForestTreeCluster.RemainingActions == nil or forestZone.Objects.ForestTreeCluster.RemainingActions == defaults.Objects.ForestTreeCluster.RemainingActions)
	then
		treeCluster.RemainingActions = math.clamp(forestZone.RemainingActions, 0, FOREST_AREA_DEFAULT_REMAINING_ACTIONS)
		treeCluster.State = if treeCluster.RemainingActions <= 0 then "Empty" else "Active"
	end

	ensureForestObject(forestZone, "ForestStone_01", defaults.Objects.ForestStone_01, 1)
	ensureForestObject(forestZone, "ForestStone_02", defaults.Objects.ForestStone_02, 1)
	forestZone.RemainingActions = treeCluster.RemainingActions

	return forestZone
end

local function updateForestAreaLocationState(player, profile)
	profile = profile or PlayerDataService.GetProfile(player)

	if not profile then
		return nil
	end

	local forestZone = ensureForestAreaZone(profile)
	local previousState = forestZone.State
	local previousForestZoneState = profile.ForestZoneState
	local hasActiveObject = false

	for _, resourceObject in pairs(forestZone.Objects) do
		if isForestObjectActive(resourceObject) then
			hasActiveObject = true
			break
		end
	end

	forestZone.State = if hasActiveObject then "Active" else "Empty"
	forestZone.RemainingActions = forestZone.Objects.ForestTreeCluster.RemainingActions or 0
	syncForestZoneClearedObjects(profile, forestZone)
	profile.ForestZoneState = if profile.ForestUnlocked == true then forestZone.State else "Locked"

	if forestZone.State ~= previousState or profile.ForestZoneState ~= previousForestZoneState then
		PlayerDataService.MarkDirty(player)
	end

	print(string.format("[ResourceService] ForestArea_01 state after update: %s", forestZone.State))

	if profile.ForestZoneState == "Empty" and previousForestZoneState ~= "Empty" then
		print(string.format("[WorldService] ForestZone is now Empty for %s", player.Name))
	end

	return forestZone.State
end

local function canHarvestForestArea(player)
	local now = os.clock()
	local lastHarvestAt = forestAreaHarvestCooldownsByUserId[player.UserId]

	if lastHarvestAt and now - lastHarvestAt < FOREST_AREA_DEBOUNCE_SECONDS then
		return false
	end

	forestAreaHarvestCooldownsByUserId[player.UserId] = now
	return true
end

local function mineForestStone(player, stoneModel, prompt)
	if not canUseForestResources(player) then
		return
	end

	if not prompt.Enabled then
		return
	end

	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[ResourceService] Profile for %s was not found. Forest stone was not mined.", player.Name))
		return
	end

	local forestZone = ensureForestAreaZone(profile)
	updateForestAreaLocationState(player, profile)
	local objectId = stoneModel:GetAttribute("ForestObjectId") or stoneModel.Name
	local stoneObject = forestZone.Objects[objectId]

	if forestZone.State == "Empty" then
		setForestResourceAvailable(stoneModel, prompt, false)
		print(string.format("[ResourceService] ForestArea_01 is Empty; forest stone blocked for %s", player.Name))
		return
	end

	if type(stoneObject) ~= "table" or stoneObject.State == "Empty" or (stoneObject.RemainingActions or 0) <= 0 then
		setForestResourceAvailable(stoneModel, prompt, false)
		updateForestAreaLocationState(player, profile)

		local WorldService = require(script.Parent.WorldService)
		WorldService.UpdateForestAreaVisual(player)
		return
	end

	CurrencyService.AddStone(player, stoneObject.AmountPerAction or 2)
	stoneObject.RemainingActions = math.max((stoneObject.RemainingActions or 1) - 1, 0)

	print(string.format("[ResourceService] %s mined %s in ForestArea_01", player.Name, objectId))

	if stoneObject.RemainingActions <= 0 then
		stoneObject.RemainingActions = 0
		stoneObject.State = "Empty"
		syncForestZoneClearedObject(profile, objectId, stoneObject)
		setForestResourceAvailable(stoneModel, prompt, false)
		print(string.format("[ResourceService] %s is now Empty", objectId))
	else
		stoneObject.State = "Active"
	end

	PlayerDataService.MarkDirty(player)
	updateForestAreaLocationState(player, profile)

	local WorldService = require(script.Parent.WorldService)
	WorldService.UpdateForestAreaVisual(player)
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

local function createMetalNode(index, position, parent)
	local metalModel = Instance.new("Model")
	metalModel.Name = string.format("MetalNode_%d", index)
	metalModel.Parent = parent

	local ore = createPart(
		"MetalOre",
		Vector3.new(4.2, 2.2, 3.2),
		position,
		Color3.fromRGB(105, 115, 130),
		metalModel
	)
	ore.Shape = Enum.PartType.Ball
	ore.Material = Enum.Material.Metal

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "MineMetalPrompt"
	prompt.ObjectText = "Металлическая руда"
	prompt.ActionText = "Добыть металл"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = ore

	prompt.Triggered:Connect(function(player)
		mineMetal(player, metalModel, prompt)
	end)

	metalModel.PrimaryPart = ore

	return metalModel
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

local function createForestStone(index, position, parent)
	local stoneModel = Instance.new("Model")
	local objectId = FOREST_STONE_OBJECT_IDS[index]
	stoneModel.Name = objectId
	stoneModel:SetAttribute("ForestObjectId", objectId)
	stoneModel.Parent = parent

	local stone = createPart(
		"Stone",
		Vector3.new(4, 2.2, 3.2),
		position,
		Color3.fromRGB(105, 115, 110),
		stoneModel
	)
	stone.Shape = Enum.PartType.Ball
	stone.Material = Enum.Material.Slate

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "MineForestStonePrompt"
	prompt.ObjectText = "Лесной камень"
	prompt.ActionText = "Добыть камень"
	prompt.HoldDuration = 0.6
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = stone

	prompt.Triggered:Connect(function(player)
		mineForestStone(player, stoneModel, prompt)
	end)

	stoneModel.PrimaryPart = stone

	return stoneModel
end

local function createRichStoneNode(index, position, parent)
	local richStoneModel = Instance.new("Model")
	richStoneModel.Name = string.format("RichStoneNode_%d", index)
	richStoneModel.Parent = parent

	local stone = createPart(
		"RichStone",
		Vector3.new(5.2, 2.8, 4.4),
		position,
		Color3.fromRGB(130, 135, 140),
		richStoneModel
	)
	stone.Shape = Enum.PartType.Ball
	stone.Material = Enum.Material.Slate

	local highlight = createPart(
		"PaleStoneCore",
		Vector3.new(2.2, 1.1, 1.4),
		position + Vector3.new(0.4, 0.4, -1.6),
		Color3.fromRGB(175, 180, 175),
		richStoneModel
	)
	highlight.Material = Enum.Material.Rock

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "MineRichStonePrompt"
	prompt.ObjectText = "Богатый камень"
	prompt.ActionText = "Добыть камень"
	prompt.HoldDuration = 0.6
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = stone

	prompt.Triggered:Connect(function(player)
		mineRichStone(player, richStoneModel, prompt)
	end)

	richStoneModel.PrimaryPart = stone

	return richStoneModel
end

local function createMetalVein(index, position, parent)
	local metalVeinModel = Instance.new("Model")
	metalVeinModel.Name = string.format("MetalVein_%d", index)
	metalVeinModel.Parent = parent

	local rock = createPart(
		"VeinRock",
		Vector3.new(4.8, 2.5, 3.8),
		position,
		Color3.fromRGB(85, 95, 105),
		metalVeinModel
	)
	rock.Shape = Enum.PartType.Ball
	rock.Material = Enum.Material.Slate

	local vein = createPart(
		"MetalVein",
		Vector3.new(1.4, 1.6, 3.9),
		position + Vector3.new(0.4, 0.3, 0),
		Color3.fromRGB(115, 135, 155),
		metalVeinModel
	)
	vein.Material = Enum.Material.Metal

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "MineMetalVeinPrompt"
	prompt.ObjectText = "Металлическая жила"
	prompt.ActionText = "Добыть металл"
	prompt.HoldDuration = 0.7
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = rock

	prompt.Triggered:Connect(function(player)
		mineMetalVein(player, metalVeinModel, prompt)
	end)

	metalVeinModel.PrimaryPart = rock

	return metalVeinModel
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

	for index, position in ipairs(METAL_POSITIONS) do
		local metalName = string.format("MetalNode_%d", index)

		if not resourceNodes:FindFirstChild(metalName) then
			createMetalNode(index, position, resourceNodes)
		end
	end

	if not resourceNodes:FindFirstChild("GoldNode_01") then
		createGoldNode(resourceNodes)
	end

	print("[ResourceService] Resource nodes are ready: 3 trees, 3 stones, 3 metal nodes and 1 gold node.")
	return resourceNodes
end

function ResourceService.CreateForestZoneResources(forestZone, forestUnlocked)
	if forestUnlocked ~= true then
		return nil
	end

	if not forestZone then
		warn("[ResourceService] ForestZone was not found. Forest resources were not created.")
		return nil
	end

	local forestResources = forestZone:FindFirstChild(FOREST_ZONE_RESOURCES_FOLDER_NAME)

	if not forestResources then
		forestResources = Instance.new("Folder")
		forestResources.Name = FOREST_ZONE_RESOURCES_FOLDER_NAME
		forestResources.Parent = forestZone
	end

	for _, oldForestTree in ipairs(forestResources:GetChildren()) do
		if string.match(oldForestTree.Name, "^ForestTree_%d+$") then
			oldForestTree:Destroy()
		elseif string.match(oldForestTree.Name, "^ForestStone_%d$") then
			oldForestTree:Destroy()
		end
	end

	if not forestResources:FindFirstChild(FOREST_AREA_ID) then
		warn("[ResourceService] ForestArea_01 visual was not found. Forest area harvesting prompt may be unavailable.")
	end

	for index, position in ipairs(FOREST_STONE_POSITIONS) do
		local stoneName = FOREST_STONE_OBJECT_IDS[index]

		if not forestResources:FindFirstChild(stoneName) then
			createForestStone(index, position, forestResources)
		end
	end

	print("[ResourceService] Created ForestZone resources")
	return forestResources
end

function ResourceService.CreateRockZoneResources(rockZone, rockZoneUnlocked)
	if rockZoneUnlocked ~= true then
		return nil
	end

	if not rockZone then
		warn("[ResourceService] RockZone was not found. RockZone resources were not created.")
		return nil
	end

	local rockResources = rockZone:FindFirstChild(ROCK_ZONE_RESOURCES_FOLDER_NAME)

	if not rockResources then
		rockResources = Instance.new("Folder")
		rockResources.Name = ROCK_ZONE_RESOURCES_FOLDER_NAME
		rockResources.Parent = rockZone
	end

	for index, position in ipairs(ROCK_RICH_STONE_POSITIONS) do
		local nodeName = string.format("RichStoneNode_%d", index)

		if not rockResources:FindFirstChild(nodeName) then
			createRichStoneNode(index, position, rockResources)
		end
	end

	for index, position in ipairs(ROCK_METAL_VEIN_POSITIONS) do
		local veinName = string.format("MetalVein_%d", index)

		if not rockResources:FindFirstChild(veinName) then
			createMetalVein(index, position, rockResources)
		end
	end

	print("[ResourceService] Created RockZone resources")
	return rockResources
end

function ResourceService.HarvestForestArea(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[ResourceService] Profile for %s was not found. ForestArea_01 was not harvested.", player.Name))
		return false
	end

	if profile.ForestUnlocked ~= true then
		warn(string.format("[ResourceService] %s cannot harvest ForestArea_01: forest is locked.", player.Name))
		return false
	end

	if not canHarvestForestArea(player) then
		return false
	end

	local forestZone = ensureForestAreaZone(profile)
	updateForestAreaLocationState(player, profile)
	local treeCluster = forestZone.Objects.ForestTreeCluster

	if forestZone.State == "Empty" then
		print(string.format("[ResourceService] ForestArea_01 is Empty; gather blocked for %s", player.Name))

		local WorldService = require(script.Parent.WorldService)
		WorldService.UpdateForestAreaVisual(player)
		return false
	end

	if treeCluster.State == "Empty" or (treeCluster.RemainingActions or 0) <= 0 then
		treeCluster.State = "Empty"
		treeCluster.RemainingActions = 0
		forestZone.RemainingActions = 0
		PlayerDataService.MarkDirty(player)
		updateForestAreaLocationState(player, profile)

		local WorldService = require(script.Parent.WorldService)
		WorldService.UpdateForestAreaVisual(player)
		return false
	end

	CurrencyService.AddWood(player, treeCluster.AmountPerAction or 1)
	treeCluster.RemainingActions = math.max((treeCluster.RemainingActions or FOREST_AREA_DEFAULT_REMAINING_ACTIONS) - 1, 0)
	forestZone.RemainingActions = treeCluster.RemainingActions

	print(string.format("[ResourceService] %s gathered ForestTreeCluster in ForestArea_01", player.Name))
	print(string.format("[ResourceService] ForestTreeCluster remaining actions: %d", treeCluster.RemainingActions))

	if treeCluster.RemainingActions <= 0 then
		treeCluster.RemainingActions = 0
		treeCluster.State = "Empty"
		forestZone.RemainingActions = 0
		syncForestZoneClearedObject(profile, FOREST_TREE_CLUSTER_ID, treeCluster)
		print("[ResourceService] ForestTreeCluster is now Empty")
	else
		treeCluster.State = "Active"
	end

	PlayerDataService.MarkDirty(player)
	updateForestAreaLocationState(player, profile)

	local WorldService = require(script.Parent.WorldService)
	WorldService.UpdateForestAreaVisual(player)

	if PlayerDataService.SendProfileUpdate then
		PlayerDataService.SendProfileUpdate(player)
	end

	return true
end

function ResourceService.UpdateForestAreaLocationState(player)
	return updateForestAreaLocationState(player)
end

return ResourceService
