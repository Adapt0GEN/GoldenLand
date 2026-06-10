-- WorldService
-- Создаёт простую стартовую сцену и визуальные ориентиры мира.
-- Generic-помощники построения мира вынесены в src/.../Services/World/:
--   WorldLayoutConfig  — карта-константы и координаты;
--   WorldPartFactory   — базовые Part/Folder и визуальные свойства;
--   WorldSignBuilder   — знаки/таблички;
--   WorldZoneBuilder   — визуал ForestZone/RockZone и их состояния;
--   WorldPathBuilder   — заблокированный путь в лес и каменистый проход.
-- WorldService остаётся публичной точкой входа и владеет интеграцией с
-- ResourceService, гейтами зон и состояниями ForestZone.

local Workspace = game:GetService("Workspace")

local PlayerDataService = require(script.Parent.PlayerDataService)
local ResourceService = require(script.Parent.ResourceService)
local RemoteService = require(script.Parent.RemoteService)

local Config = require(script.Parent.World.WorldLayoutConfig)
local PartFactory = require(script.Parent.World.WorldPartFactory)
local SignBuilder = require(script.Parent.World.WorldSignBuilder)
local ZoneBuilder = require(script.Parent.World.WorldZoneBuilder)
local PathBuilder = require(script.Parent.World.WorldPathBuilder)

local WorldService = {}

-- Имена/координаты раскладки берём из общего конфига.
local WORLD_ROOT_NAME = Config.WORLD_ROOT_NAME
local BLOCKED_PATH_NAME = Config.BLOCKED_PATH_NAME
local ROCK_PASS_NAME = Config.ROCK_PASS_NAME
local ROCK_ZONE_NAME = Config.ROCK_ZONE_NAME
local FOREST_ZONE_NAME = Config.FOREST_ZONE_NAME
local FOREST_ZONE_RESOURCES_FOLDER_NAME = Config.FOREST_ZONE_RESOURCES_FOLDER_NAME
local FOREST_AREA_ID = Config.FOREST_AREA_ID
local FOREST_ZONE_POSITION = Config.FOREST_ZONE_POSITION
local FOREST_AREA_POSITION = Config.FOREST_AREA_POSITION
local FOREST_STONE_OBJECT_IDS = Config.FOREST_STONE_OBJECT_IDS

-- Generic-фабрики и построители (call sites остаются прежними).
local createPart = PartFactory.createPart
local createAreaMarker = PartFactory.createAreaMarker
local getWorldRoot = PartFactory.getWorldRoot
local createTextSign = SignBuilder.createTextSign
local createForestZoneVisualForState = ZoneBuilder.createForestZoneVisualForState

local function sendPlayerMessage(player, message)
	RemoteService.SendPlayerMessage(player, message)
end

local function removeBlockedPath()
	local blockedPath = getWorldRoot():FindFirstChild(BLOCKED_PATH_NAME)

	if blockedPath then
		blockedPath:Destroy()
	end
end

local function removeRockPass()
	local rockPass = getWorldRoot():FindFirstChild(ROCK_PASS_NAME)

	if rockPass then
		rockPass:Destroy()
	end
end

local function removeRockZone()
	local rockZone = getWorldRoot():FindFirstChild(ROCK_ZONE_NAME)

	if rockZone then
		rockZone:Destroy()
	end
end

local function ensureForestZoneResourcesFolder(forestZone)
	return PartFactory.ensureChildFolder(forestZone, FOREST_ZONE_RESOURCES_FOLDER_NAME)
end

local function setForestResourceModelAvailable(model, isAvailable)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Transparency = if isAvailable then 0 else 1
			descendant.CanCollide = isAvailable
			descendant.CanTouch = isAvailable
			descendant.CanQuery = isAvailable
		elseif descendant:IsA("ProximityPrompt") then
			descendant.Enabled = isAvailable
		end
	end
end

-- Тонкие обёртки над построителями путей/зоны: сохраняют прежние call sites и
-- передают серверные обработчики расчистки.
local function createBlockedPathToForest()
	return PathBuilder.createBlockedPathToForest(getWorldRoot(), function(player)
		WorldService.TryClearForestPath(player)
	end)
end

local function createRockPass()
	return PathBuilder.createRockPass(getWorldRoot(), function(player)
		WorldService.TryClearRockPass(player)
	end)
end

local function createRockZone()
	return ZoneBuilder.createRockZone(getWorldRoot())
end

local function createForestAreaVisual(forestResources)
	local forestArea = forestResources:FindFirstChild(FOREST_AREA_ID)

	if not forestArea then
		forestArea = Instance.new("Model")
		forestArea.Name = FOREST_AREA_ID
		forestArea.Parent = forestResources
	end

	for _, stageName in ipairs(Config.FOREST_AREA_STAGE_NAMES) do
		local existingStage = forestArea:FindFirstChild(string.format("%s_%s", FOREST_AREA_ID, stageName))

		if existingStage then
			existingStage:Destroy()
		end
	end

	local promptPart = forestArea:FindFirstChild("GatherForestAreaPromptPart")

	if not promptPart then
		promptPart = createPart(
			"GatherForestAreaPromptPart",
			Vector3.new(5, 1, 5),
			FOREST_AREA_POSITION + Vector3.new(0, 1.2, 0),
			Color3.fromRGB(70, 120, 55),
			forestArea
		)
		promptPart.Transparency = 0.65
		promptPart.CanCollide = false
		promptPart.CanTouch = false
	end

	local legacyPromptPart = forestArea:FindFirstChild("HarvestForestAreaPromptPart")

	if legacyPromptPart and legacyPromptPart ~= promptPart then
		legacyPromptPart:Destroy()
	end

	local legacyPrompt = promptPart:FindFirstChild("HarvestForestAreaPrompt")

	if legacyPrompt then
		legacyPrompt:Destroy()
	end

	local prompt = promptPart:FindFirstChild("GatherForestAreaPrompt")

	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "GatherForestAreaPrompt"
		prompt.ObjectText = "Лесная область"
		prompt.ActionText = "Рубить лес"
		prompt.HoldDuration = 0.7
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt.Parent = promptPart

		prompt.Triggered:Connect(function(player)
			ResourceService.HarvestForestArea(player)
		end)
	end

	prompt.ObjectText = "Лесная зона"
	prompt.ActionText = "Осваивать"
	prompt.HoldDuration = 0.7
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false

	local debugPromptPart = forestArea:FindFirstChild("DebugResetForestPromptPart")

	if debugPromptPart then
		debugPromptPart:Destroy()
	end

	local legacyDebugPromptPart = forestArea:FindFirstChild("DebugResetForestAreaPromptPart")

	if legacyDebugPromptPart then
		legacyDebugPromptPart:Destroy()
	end

	return forestArea
end

local function createForestZone(state)
	local worldRoot = getWorldRoot()
	local existingForestZone = worldRoot:FindFirstChild(FOREST_ZONE_NAME)

	if existingForestZone then
		ZoneBuilder.removeLegacyForestZoneTrees(existingForestZone)
		ZoneBuilder.removeLegacyForestZoneVisualObjects(existingForestZone)
		createForestAreaVisual(ensureForestZoneResourcesFolder(existingForestZone))
		createForestZoneVisualForState(existingForestZone, state or "Active")
		print(string.format("[WorldService] Created ForestZone with state %s", state or "Active"))
		return existingForestZone
	end

	local forestZone = Instance.new("Model")
	forestZone.Name = FOREST_ZONE_NAME
	forestZone.Parent = worldRoot

	createAreaMarker(
		"ForestGround",
		Vector3.new(32, 0.35, 24),
		FOREST_ZONE_POSITION,
		Color3.fromRGB(55, 125, 70),
		forestZone
	)

	createForestAreaVisual(ensureForestZoneResourcesFolder(forestZone))
	createForestZoneVisualForState(forestZone, state or "Active")

	print(string.format("[WorldService] Created ForestZone with state %s", state or "Active"))
	return forestZone
end

local function updateRockAccessForProfile(player, profile)
	if profile.RockZoneUnlocked == true then
		removeRockPass()
		ResourceService.CreateRockZoneResources(createRockZone(), true)
	else
		removeRockZone()
		createRockPass()
	end
end

function WorldService.TryClearForestPath(player)
	print(string.format("[WorldService] %s tried to clear forest path.", player.Name))

	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[WorldService] Profile for %s was not found. Forest path was not cleared.", player.Name))
		return false
	end

	if profile.ForestUnlocked == true then
		ResourceService.UpdateForestAreaLocationState(player)
		print(string.format("[WorldService] ForestZone state for %s: %s", player.Name, profile.ForestZoneState))
		removeBlockedPath()
		ResourceService.CreateForestZoneResources(createForestZone(profile.ForestZoneState), true, profile)
		WorldService.UpdateForestAreaVisual(player)
		return true
	end

	if (profile.ToolKitLevel or 0) < 1 then
		warn(string.format("[WorldService] %s cannot clear forest path: ToolKitLevel 1 required.", player.Name))
		sendPlayerMessage(player, "Нужен набор инструментов I")
		return false
	end

	profile.ForestUnlocked = true
	profile.ForestZoneClearedObjects = profile.ForestZoneClearedObjects or {}
	-- Состояние зоны пишет только ResourceService; здесь оно выводится после установки ForestUnlocked.
	ResourceService.UpdateForestAreaLocationState(player)
	PlayerDataService.MarkDirty(player)
	removeBlockedPath()
	print(string.format("[WorldService] ForestZone state for %s: %s", player.Name, profile.ForestZoneState))
	ResourceService.CreateForestZoneResources(createForestZone(profile.ForestZoneState), true, profile)
	WorldService.UpdateForestAreaVisual(player)

	if PlayerDataService.SendProfileUpdate then
		PlayerDataService.SendProfileUpdate(player)
	end

	if PlayerDataService.SaveProfile then
		PlayerDataService.SaveProfile(player)
	end

	sendPlayerMessage(player, "Путь в лесную зону открыт")
	print(string.format("[WorldService] %s unlocked forest zone.", player.Name))

	return true
end

function WorldService.TryClearRockPass(player)
	print(string.format("[WorldService] %s tried to clear rock pass.", player.Name))

	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[WorldService] Profile for %s was not found. Rock pass was not cleared.", player.Name))
		return false
	end

	if profile.RockZoneUnlocked == true then
		removeRockPass()
		ResourceService.CreateRockZoneResources(createRockZone(), true)
		return true
	end

	if (profile.ToolKitLevel or 0) < 2 then
		warn(string.format("[WorldService] %s cannot clear rock pass: ToolKitLevel 2 required.", player.Name))
		sendPlayerMessage(player, "Нужен набор инструментов II")
		return false
	end

	profile.RockZoneUnlocked = true
	PlayerDataService.MarkDirty(player)
	removeRockPass()
	ResourceService.CreateRockZoneResources(createRockZone(), true)

	if PlayerDataService.SendProfileUpdate then
		PlayerDataService.SendProfileUpdate(player)
	end

	if PlayerDataService.SaveProfile then
		PlayerDataService.SaveProfile(player)
	end

	sendPlayerMessage(player, "Каменистая зона открыта")
	print(string.format("[WorldService] %s unlocked rock zone.", player.Name))

	return true
end

function WorldService.UpdateForestAccessForPlayer(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[WorldService] Profile for %s was not found. Forest access was not updated.", player.Name))
		return false
	end

	if profile.ForestUnlocked == true then
		ResourceService.UpdateForestAreaLocationState(player)
		print(string.format("[WorldService] ForestZone state for %s: %s", player.Name, profile.ForestZoneState))
		removeBlockedPath()
		ResourceService.CreateForestZoneResources(createForestZone(profile.ForestZoneState), true, profile)
		WorldService.UpdateForestAreaVisual(player)
	else
		print(string.format("[WorldService] ForestZone state for %s: %s", player.Name, ResourceService.GetForestZoneState(profile)))
		createBlockedPathToForest()
	end

	updateRockAccessForProfile(player, profile)

	return true
end

local function getForestAreaVisualStage(forestAreaData)
	local objects = forestAreaData.Objects or {}
	local treeCluster = objects.ForestTreeCluster or {}
	local treeRemainingActions = treeCluster.RemainingActions or forestAreaData.RemainingActions or 0

	if forestAreaData.State == "Empty" then
		return "Empty", 0
	elseif treeRemainingActions >= 9 then
		return "Full", 6
	elseif treeRemainingActions >= 5 then
		return "Medium", 4
	elseif treeRemainingActions >= 1 then
		return "Low", 2
	end

	return "TreeEmpty", 0
end

local function updateForestStoneVisuals(forestResources, forestAreaData)
	local objects = forestAreaData.Objects or {}
	local locationIsActive = forestAreaData.State ~= "Empty"

	for _, objectId in ipairs(FOREST_STONE_OBJECT_IDS) do
		local stoneModel = forestResources:FindFirstChild(objectId)
		local stoneObject = objects[objectId]
		local isAvailable = locationIsActive
			and type(stoneObject) == "table"
			and stoneObject.State == "Active"
			and (stoneObject.RemainingActions or 0) > 0

		if stoneModel then
			setForestResourceModelAvailable(stoneModel, isAvailable)
		end
	end
end

function WorldService.UpdateForestAreaVisual(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[WorldService] Profile for %s was not found. ForestArea_01 visual was not updated.", player.Name))
		return false
	end

	local worldRoot = getWorldRoot()
	local forestZone = worldRoot:FindFirstChild(FOREST_ZONE_NAME)

	if not forestZone then
		return false
	end

	local forestResources = ensureForestZoneResourcesFolder(forestZone)
	-- Только чтение состояния; запись принадлежит ResourceService.
	local forestZoneState = ResourceService.GetForestZoneState(profile)
	print(string.format("[WorldService] ForestZone state for %s: %s", player.Name, forestZoneState))

	local resourceZones = profile.ResourceZones or {}
	local forestAreaData = resourceZones[FOREST_AREA_ID] or {}
	local visualStage, treeCount = getForestAreaVisualStage(forestAreaData)
	createForestZoneVisualForState(forestZone, forestZoneState, visualStage, treeCount)

	local forestArea = createForestAreaVisual(forestResources)
	local objects = forestAreaData.Objects or {}
	local treeCluster = objects.ForestTreeCluster or {}

	local prompt = forestArea:FindFirstChild("GatherForestAreaPrompt", true)

	if prompt then
		prompt.Enabled = forestAreaData.State == "Active"
			and treeCluster.State == "Active"
			and (treeCluster.RemainingActions or 0) > 0

		local promptPart = prompt.Parent

		if promptPart and promptPart:IsA("BasePart") then
			promptPart.Transparency = if prompt.Enabled then 0.65 else 1
			promptPart.CanQuery = prompt.Enabled
		end
	end

	updateForestStoneVisuals(forestResources, forestAreaData)
	print(string.format("[WorldService] ForestArea_01 visual stage: %s, trees=%d", visualStage, treeCount))

	return true
end

function WorldService.CreateStartWorld()
	local existingWorld = Workspace:FindFirstChild(WORLD_ROOT_NAME)

	if existingWorld then
		print("[WorldService] Start world already exists.")
		createBlockedPathToForest()
		createRockPass()
		return existingWorld
	end

	local worldRoot = Instance.new("Folder")
	worldRoot.Name = WORLD_ROOT_NAME
	worldRoot.Parent = Workspace

	-- Площадка появления игрока.
	createAreaMarker(
		"StartArea",
		Vector3.new(18, 0.4, 18),
		Vector3.new(0, 0, 0),
		Color3.fromRGB(120, 160, 120),
		worldRoot
	)

	-- Место старосты рядом со стартовой площадкой.
	createAreaMarker(
		"ElderArea",
		Vector3.new(12, 0.35, 10),
		Vector3.new(12, 0.05, 0),
		Color3.fromRGB(155, 130, 95),
		worldRoot
	)
	createTextSign("ElderAreaSign", "Староста", Vector3.new(12, 2.5, -6), worldRoot)

	-- Ресурсная поляна для первых деревьев.
	createAreaMarker(
		"ResourceArea",
		Vector3.new(18, 0.35, 12),
		Vector3.new(25, 0.05, 8),
		Color3.fromRGB(80, 140, 80),
		worldRoot
	)
	createTextSign("ResourceAreaSign", "Лес", Vector3.new(25, 2.5, 1), worldRoot)

	-- Небольшая каменная зона рядом с лесом для повторяемой добычи Stone.
	createAreaMarker(
		"StoneArea",
		Vector3.new(18, 0.35, 10),
		Vector3.new(24, 0.05, 19),
		Color3.fromRGB(105, 110, 115),
		worldRoot
	)
	createTextSign("StoneAreaSign", "Камни", Vector3.new(24, 2.5, 13), worldRoot)

	-- Маркер направления к личной земле игрока.
	local plotMarker = Instance.new("Model")
	plotMarker.Name = "PlotAreaMarker"
	plotMarker.Parent = worldRoot

	createPart(
		"ArrowBase",
		Vector3.new(7, 0.25, 1.5),
		Vector3.new(0, 0.35, 34),
		Color3.fromRGB(210, 180, 90),
		plotMarker
	)

	createPart(
		"ArrowHead",
		Vector3.new(3, 0.25, 3),
		Vector3.new(0, 0.35, 39),
		Color3.fromRGB(210, 180, 90),
		plotMarker
	)

	createTextSign("PlotDirectionSign", "К личной земле", Vector3.new(0, 2.5, 28), plotMarker)

	createBlockedPathToForest()
	createRockPass()

	print("[WorldService] Start world created.")
	return worldRoot
end

return WorldService
