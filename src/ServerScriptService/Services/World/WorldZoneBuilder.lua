-- WorldZoneBuilder
-- Помощники построения визуала зон: декор ForestZone, состояния её визуала и RockZone.
-- Чистая визуальная сборка: модуль не пишет игровое состояние и не знает про профиль.
-- Логи сохранены в исходном виде ("[WorldService] ..."), чтобы вывод не менялся.

local Config = require(script.Parent.WorldLayoutConfig)
local PartFactory = require(script.Parent.WorldPartFactory)
local SignBuilder = require(script.Parent.WorldSignBuilder)

local createPart = PartFactory.createPart
local createFlatMarker = PartFactory.createFlatMarker
local createAreaMarker = PartFactory.createAreaMarker
local ensureChildFolder = PartFactory.ensureChildFolder
local createTextSign = SignBuilder.createTextSign

local FOREST_ZONE_DECOR_FOLDER_NAME = Config.FOREST_ZONE_DECOR_FOLDER_NAME
local FOREST_ZONE_INTERACTIVES_FOLDER_NAME = Config.FOREST_ZONE_INTERACTIVES_FOLDER_NAME
local FOREST_ZONE_VISUAL_STATE_FOLDER_NAME = Config.FOREST_ZONE_VISUAL_STATE_FOLDER_NAME
local LEGACY_FOREST_ZONE_VISUAL_STATE_FOLDER_NAME = Config.LEGACY_FOREST_ZONE_VISUAL_STATE_FOLDER_NAME
local FOREST_AREA_ID = Config.FOREST_AREA_ID
local FOREST_ZONE_POSITION = Config.FOREST_ZONE_POSITION
local FOREST_AREA_POSITION = Config.FOREST_AREA_POSITION
local FOREST_AREA_TREE_POSITIONS = Config.FOREST_AREA_TREE_POSITIONS
local ROCK_ZONE_NAME = Config.ROCK_ZONE_NAME
local ROCK_ZONE_POSITION = Config.ROCK_ZONE_POSITION

local WorldZoneBuilder = {}

local function createDecorativeTree(name, position, parent)
	local tree = Instance.new("Model")
	tree.Name = name
	tree.Parent = parent

	local trunk = createPart(
		"Trunk",
		Vector3.new(1.2, 4.5, 1.2),
		position + Vector3.new(0, 2.25, 0),
		Color3.fromRGB(95, 60, 35),
		tree
	)

	local leaves = createPart(
		"Leaves",
		Vector3.new(5.5, 5.5, 5.5),
		position + Vector3.new(0, 5.2, 0),
		Color3.fromRGB(35, 115, 65),
		tree
	)
	leaves.Shape = Enum.PartType.Ball

	tree.PrimaryPart = trunk
	return tree
end

local function createDecorativeStone(name, position, parent)
	local stone = createPart(
		name,
		Vector3.new(3.5, 1.8, 2.8),
		position,
		Color3.fromRGB(110, 115, 120),
		parent
	)
	stone.Shape = Enum.PartType.Ball
	stone.Material = Enum.Material.Slate

	return stone
end

local function createStump(name, position, parent)
	local stump = createPart(
		name,
		Vector3.new(1.5, 1, 1.5),
		position + Vector3.new(0, 0.65, 0),
		Color3.fromRGB(95, 60, 35),
		parent
	)
	stump.Shape = Enum.PartType.Cylinder

	return stump
end

local function createLog(name, position, parent)
	local log = createPart(
		name,
		Vector3.new(3, 0.7, 0.7),
		position + Vector3.new(0, 0.55, 0),
		Color3.fromRGB(95, 60, 35),
		parent
	)
	log.Rotation = Vector3.new(0, 0, 12)

	return log
end

local function createBush(name, position, parent)
	local bush = createPart(
		name,
		Vector3.new(3.2, 1.6, 3.2),
		position + Vector3.new(0, 0.8, 0),
		Color3.fromRGB(45, 125, 55),
		parent
	)
	bush.Shape = Enum.PartType.Ball
	bush.Material = Enum.Material.Grass

	return bush
end

-- Чистые помощники инспекции леса (используются будущей логикой карты/состояний).
local function hasVisibleGreenTree(model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart")
			and descendant.Name == "Leaves"
			and descendant.Transparency < 1
		then
			return true
		end
	end

	return false
end

local function countVisibleActiveForestParts(model)
	local treeCount = 0
	local rockCount = 0

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("Model") and string.match(descendant.Name, "^Tree_%d+$") then
			treeCount += 1
		elseif descendant:IsA("BasePart")
			and string.find(descendant.Name, "Rock", 1, true)
			and descendant.Transparency < 1
		then
			rockCount += 1
		end
	end

	return treeCount, rockCount
end

WorldZoneBuilder.hasVisibleGreenTree = hasVisibleGreenTree
WorldZoneBuilder.countVisibleActiveForestParts = countVisibleActiveForestParts

-- Удаляет устаревшие деревья ForestZone (старые имена).
function WorldZoneBuilder.removeLegacyForestZoneTrees(forestZone)
	for _, child in ipairs(forestZone:GetChildren()) do
		if string.match(child.Name, "^ForestDecorTree_%d+$") or string.match(child.Name, "^ForestTree_%d+$") then
			child:Destroy()
		end
	end
end

-- Удаляет устаревшие декоративные объекты/папки ForestZone.
function WorldZoneBuilder.removeLegacyForestZoneVisualObjects(forestZone)
	for _, child in ipairs(forestZone:GetChildren()) do
		if child.Name == "ForestZoneSign"
			or child.Name == "ForestDecorStone_1"
			or child.Name == "ForestDecorStone_2"
			or child.Name == FOREST_ZONE_DECOR_FOLDER_NAME
			or child.Name == FOREST_ZONE_INTERACTIVES_FOLDER_NAME
			or child.Name == LEGACY_FOREST_ZONE_VISUAL_STATE_FOLDER_NAME
		then
			child:Destroy()
		end
	end
end

local function clearForestZoneVisualState(forestZone)
	local legacyVisualState = forestZone:FindFirstChild(LEGACY_FOREST_ZONE_VISUAL_STATE_FOLDER_NAME)

	if legacyVisualState then
		legacyVisualState:Destroy()
	end

	local oldVisualState = forestZone:FindFirstChild(FOREST_ZONE_VISUAL_STATE_FOLDER_NAME)

	if oldVisualState then
		oldVisualState:Destroy()
		print("[WorldService] Destroyed old ForestZone VisualStateObjects")
	end

	local visualState = Instance.new("Folder")
	visualState.Name = FOREST_ZONE_VISUAL_STATE_FOLDER_NAME
	visualState.Parent = forestZone

	return visualState
end

local function createForestAreaStageVisual(parent, stageName, treeCount)
	local stage = Instance.new("Model")
	stage.Name = string.format("%s_%s", FOREST_AREA_ID, stageName)
	stage.Parent = parent

	for index = 1, treeCount do
		createDecorativeTree(string.format("Tree_%d", index), FOREST_AREA_TREE_POSITIONS[index], stage)
	end

	if stageName == "Low" or stageName == "TreeEmpty" then
		createStump("Stump_1", FOREST_AREA_POSITION + Vector3.new(-8, 0, -5), stage)
		createStump("Stump_2", FOREST_AREA_POSITION + Vector3.new(-4, 0, 4), stage)
	end

	return stage
end

local function createActiveForestZoneVisual(visualState, visualStage, treeCount)
	local decor = ensureChildFolder(visualState, FOREST_ZONE_DECOR_FOLDER_NAME)
	local interactives = ensureChildFolder(visualState, FOREST_ZONE_INTERACTIVES_FOLDER_NAME)
	local stageName = visualStage or "Full"
	local visualTreeCount = treeCount or 6

	createFlatMarker(
		"ActiveForestOvergrowth",
		Vector3.new(30, 0.12, 20),
		FOREST_ZONE_POSITION + Vector3.new(0, 0.25, 1),
		Color3.fromRGB(45, 115, 55),
		decor
	)

	createForestAreaStageVisual(decor, stageName, visualTreeCount)
	createBush("ActiveBush_1", FOREST_ZONE_POSITION + Vector3.new(-6, 0, -9), decor)
	createBush("ActiveBush_2", FOREST_ZONE_POSITION + Vector3.new(6, 0, -8), decor)
	createBush("ActiveBush_3", FOREST_ZONE_POSITION + Vector3.new(-2, 0, 9), decor)
	createBush("ActiveBush_4", FOREST_ZONE_POSITION + Vector3.new(8, 0, 0), decor)
	createDecorativeStone("ActiveDecorStone_1", FOREST_ZONE_POSITION + Vector3.new(-12, 1.1, 5), decor)
	createDecorativeStone("ActiveDecorStone_2", FOREST_ZONE_POSITION + Vector3.new(12, 1.1, -6), decor)
	createLog("ActiveBlockedLog_1", FOREST_ZONE_POSITION + Vector3.new(-5, 0, 3), interactives)
	createLog("ActiveBlockedLog_2", FOREST_ZONE_POSITION + Vector3.new(5, 0, -2), interactives)
	createTextSign("ForestZoneActiveSign", "Лесная зона", FOREST_ZONE_POSITION + Vector3.new(0, 2.5, -13), visualState)

	if stageName == "Medium" then
		print(string.format("[WorldService] Medium visual created with %d trees", visualTreeCount))
	elseif stageName == "Low" or stageName == "TreeEmpty" then
		print(string.format("[WorldService] Low visual created with %d trees", visualTreeCount))
	else
		print(string.format("[WorldService] Active visual created with %d trees", visualTreeCount))
	end
end

local function createEmptyForestZoneVisual(visualState)
	local decor = ensureChildFolder(visualState, FOREST_ZONE_DECOR_FOLDER_NAME)

	createFlatMarker(
		"ClearedForestGround",
		Vector3.new(22, 0.14, 15),
		FOREST_ZONE_POSITION + Vector3.new(0, 0.28, 1),
		Color3.fromRGB(130, 155, 95),
		decor
	)
	createFlatMarker(
		"ClearedForestPath",
		Vector3.new(5, 0.16, 24),
		FOREST_ZONE_POSITION + Vector3.new(0, 0.32, -1),
		Color3.fromRGB(170, 145, 95),
		decor
	)

	createStump("EmptyStump_1", FOREST_ZONE_POSITION + Vector3.new(-6, 0, 4), decor)
	createStump("EmptyStump_2", FOREST_ZONE_POSITION + Vector3.new(4, 0, -3), decor)
	createStump("EmptyStump_3", FOREST_ZONE_POSITION + Vector3.new(8, 0, 6), decor)
	createLog("EmptyFallenLog_1", FOREST_ZONE_POSITION + Vector3.new(-8, 0, -5), decor)
	createTextSign("ForestZoneEmptySign", "Лесная зона очищена", FOREST_ZONE_POSITION + Vector3.new(0, 2.5, -13), visualState)

	print("[WorldService] Empty visual created with 0 trees")
end

local function createClearedForestZoneVisual(visualState)
	local decor = ensureChildFolder(visualState, FOREST_ZONE_DECOR_FOLDER_NAME)

	createFlatMarker(
		"SettledForestGround",
		Vector3.new(24, 0.14, 16),
		FOREST_ZONE_POSITION + Vector3.new(0, 0.3, 1),
		Color3.fromRGB(150, 170, 105),
		decor
	)
	createFlatMarker(
		"FutureForestBuildSpot",
		Vector3.new(8, 0.18, 6),
		FOREST_ZONE_POSITION + Vector3.new(0, 0.36, 3),
		Color3.fromRGB(185, 165, 115),
		decor
	)
	createFlatMarker(
		"ClearedForestPath",
		Vector3.new(5, 0.16, 24),
		FOREST_ZONE_POSITION + Vector3.new(0, 0.34, -1),
		Color3.fromRGB(175, 150, 100),
		decor
	)
	createStump("ClearedStump_1", FOREST_ZONE_POSITION + Vector3.new(-9, 0, 5), decor)
	createStump("ClearedStump_2", FOREST_ZONE_POSITION + Vector3.new(9, 0, -5), decor)
	createTextSign("ForestZoneClearedSign", "Лесная зона освоена", FOREST_ZONE_POSITION + Vector3.new(0, 2.5, -13), visualState)

	print("[WorldService] Created Cleared ForestZone visual")
end

-- Перерисовывает визуал состояния ForestZone (Active/Empty/Cleared) под состояние зоны.
function WorldZoneBuilder.createForestZoneVisualForState(forestZone, state, visualStage, treeCount)
	local visualState = clearForestZoneVisualState(forestZone)
	local visualStateName = state or "Active"

	print(string.format("[WorldService] Rendering ForestZone visual state: %s", visualStateName))

	if visualStateName == "Empty" then
		createEmptyForestZoneVisual(visualState)
	elseif visualStateName == "Cleared" then
		createClearedForestZoneVisual(visualState)
	else
		createActiveForestZoneVisual(visualState, visualStage, treeCount)
	end

	print(string.format("[WorldService] Created ForestZone VisualStateObjects for state: %s", visualStateName))
end

-- Устаревший построитель стадий ForestArea. Сохранён для совместимости и будущей карты.
function WorldZoneBuilder.createLegacyForestAreaStage(parent, stageName, treeCount)
	local stage = Instance.new("Model")
	stage.Name = string.format("%s_%s", FOREST_AREA_ID, stageName)
	stage.Parent = parent

	if type(treeCount) == "number" then
		for index = 1, treeCount do
			createDecorativeTree(string.format("Tree_%d", index), FOREST_AREA_TREE_POSITIONS[index], stage)
		end

		if stageName == "Low" or stageName == "TreeEmpty" or stageName == "Empty" then
			createStump("Stump_1", FOREST_AREA_POSITION + Vector3.new(-8, 0, -5), stage)
			createStump("Stump_2", FOREST_AREA_POSITION + Vector3.new(-4, 0, 4), stage)
		end

		if stageName == "TreeEmpty" or stageName == "Empty" then
			createLog("FallenLog_1", FOREST_AREA_POSITION + Vector3.new(-2, 0, 4), stage)
			createLog("FallenLog_2", FOREST_AREA_POSITION + Vector3.new(6, 0, -1), stage)
		end

		if stageName == "Empty" then
			createTextSign("EmptyForestSign", "Р›РµСЃ РІС‹СЂСѓР±Р»РµРЅ", FOREST_AREA_POSITION + Vector3.new(0, 2.5, 5), stage)
		end

		return stage
	end

	if stageName == "Active" then
		createDecorativeTree("Tree_1", FOREST_AREA_POSITION + Vector3.new(-8, 0.2, -5), stage)
		createDecorativeTree("Tree_2", FOREST_AREA_POSITION + Vector3.new(-4, 0.2, 4), stage)
		createDecorativeTree("Tree_3", FOREST_AREA_POSITION + Vector3.new(0, 0.2, -3), stage)
		createDecorativeTree("Tree_4", FOREST_AREA_POSITION + Vector3.new(4, 0.2, 5), stage)
		createDecorativeTree("Tree_5", FOREST_AREA_POSITION + Vector3.new(8, 0.2, -4), stage)
		createDecorativeTree("Tree_6", FOREST_AREA_POSITION + Vector3.new(10, 0.2, 3), stage)
	else
		createStump("Stump_1", FOREST_AREA_POSITION + Vector3.new(-8, 0, -5), stage)
		createStump("Stump_2", FOREST_AREA_POSITION + Vector3.new(-4, 0, 4), stage)
		createStump("Stump_3", FOREST_AREA_POSITION + Vector3.new(0, 0, -3), stage)
		createStump("Stump_4", FOREST_AREA_POSITION + Vector3.new(4, 0, 5), stage)
		createStump("Stump_5", FOREST_AREA_POSITION + Vector3.new(8, 0, -4), stage)
		createLog("FallenLog_1", FOREST_AREA_POSITION + Vector3.new(-2, 0, 4), stage)
		createLog("FallenLog_2", FOREST_AREA_POSITION + Vector3.new(6, 0, -1), stage)
		createTextSign("EmptyForestSign", "Лес вырублен", FOREST_AREA_POSITION + Vector3.new(0, 2.5, 5), stage)
	end

	return stage
end

-- Создаёт визуал RockZone (один раз) внутри переданного worldRoot.
function WorldZoneBuilder.createRockZone(worldRoot)
	local existingRockZone = worldRoot:FindFirstChild(ROCK_ZONE_NAME)

	if existingRockZone then
		return existingRockZone
	end

	local rockZone = Instance.new("Model")
	rockZone.Name = ROCK_ZONE_NAME
	rockZone.Parent = worldRoot

	local ground = createAreaMarker(
		"RockZoneGround",
		Vector3.new(34, 0.4, 24),
		ROCK_ZONE_POSITION,
		Color3.fromRGB(95, 95, 90),
		rockZone
	)
	ground.Material = Enum.Material.Rock

	local rockPositions = {
		Vector3.new(-10, 0.8, -6),
		Vector3.new(-5, 0.7, 5),
		Vector3.new(2, 0.9, -4),
		Vector3.new(8, 0.7, 6),
		Vector3.new(11, 0.8, -2),
	}

	for index, offset in ipairs(rockPositions) do
		local rock = createPart(
			string.format("DecorRock_%02d", index),
			Vector3.new(3 + (index % 2), 1.4 + (index % 3) * 0.3, 2.5 + (index % 2)),
			ROCK_ZONE_POSITION + offset,
			Color3.fromRGB(105 + index * 4, 105 + index * 3, 110 + index * 2),
			rockZone
		)
		rock.Material = Enum.Material.Slate
		rock.Rotation = Vector3.new(0, index * 17, index * 5)
	end

	local metalPositions = {
		Vector3.new(-7, 0.55, 0),
		Vector3.new(4, 0.55, 3),
		Vector3.new(9, 0.55, -7),
	}

	for index, offset in ipairs(metalPositions) do
		local metal = createPart(
			string.format("MetalDetail_%02d", index),
			Vector3.new(1.4, 0.5, 1.4),
			ROCK_ZONE_POSITION + offset,
			Color3.fromRGB(135, 140, 145),
			rockZone
		)
		metal.Material = Enum.Material.Metal
	end

	createTextSign("RockZoneSign", "Каменистая зона", ROCK_ZONE_POSITION + Vector3.new(0, 2.5, -13), rockZone)

	print("[WorldService] Created RockZone.")
	return rockZone
end

return WorldZoneBuilder
