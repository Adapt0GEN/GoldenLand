-- ResourceService
-- Создаёт простые деревья, камни, металлическую руду и золотую жилу, которые можно собирать повторяемо.

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

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
local GOLD_COOLDOWN_SECONDS = 2
local FOREST_ZONE_RESOURCES_FOLDER_NAME = "ForestZoneResources"
local FOREST_AREA_ID = "ForestArea_01"
local FOREST_AREA_DEFAULT_REMAINING_ACTIONS = 12
local FOREST_AREA_DEBOUNCE_SECONDS = 0.6
local FOREST_AREA_DEBUG_RESET_DEBOUNCE_SECONDS = 1
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
local goldMineCooldownsByUserId = {}
local forestAreaHarvestCooldownsByUserId = {}
local forestAreaDebugResetCooldownsByUserId = {}

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
	local hasActiveObject = false

	for _, resourceObject in pairs(forestZone.Objects) do
		if isForestObjectActive(resourceObject) then
			hasActiveObject = true
			break
		end
	end

	forestZone.State = if hasActiveObject then "Active" else "Empty"
	forestZone.RemainingActions = forestZone.Objects.ForestTreeCluster.RemainingActions or 0

	if forestZone.State ~= previousState then
		PlayerDataService.MarkDirty(player)
	end

	print(string.format("[ResourceService] ForestArea_01 state after update: %s", forestZone.State))
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

local function canDebugResetForestArea(player)
	local now = os.clock()
	local lastResetAt = forestAreaDebugResetCooldownsByUserId[player.UserId]

	if lastResetAt and now - lastResetAt < FOREST_AREA_DEBUG_RESET_DEBOUNCE_SECONDS then
		return false
	end

	forestAreaDebugResetCooldownsByUserId[player.UserId] = now
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

function ResourceService.ResetResourceZoneForDebug(player, resourceZoneId)
	if not RunService:IsStudio() then
		return false
	end

	if resourceZoneId ~= FOREST_AREA_ID then
		warn(string.format("[ResourceService] DEBUG reset rejected for unknown resource zone: %s", tostring(resourceZoneId)))
		return false
	end

	if not canDebugResetForestArea(player) then
		return false
	end

	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[ResourceService] Profile for %s was not found. Debug reset was not applied.", player.Name))
		return false
	end

	profile.ResourceZones = profile.ResourceZones or {}
	profile.ResourceZones[FOREST_AREA_ID] = createDefaultForestAreaZone()
	PlayerDataService.MarkDirty(player)
	forestAreaHarvestCooldownsByUserId[player.UserId] = nil

	print(string.format("[ResourceService] DEBUG reset ForestArea_01 location for %s", player.Name))

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
