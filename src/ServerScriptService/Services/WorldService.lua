-- WorldService
-- Создаёт простую стартовую сцену и визуальные ориентиры мира.

local Workspace = game:GetService("Workspace")

local PlayerDataService = require(script.Parent.PlayerDataService)
local ResourceService = require(script.Parent.ResourceService)
local RemoteService = require(script.Parent.RemoteService)

local WorldService = {}

local WORLD_ROOT_NAME = "WorldRoot"
local BLOCKED_PATH_NAME = "BlockedPathToForest"
local ROCK_PASS_NAME = "RockPass"
local ROCK_ZONE_NAME = "RockZone"
local FOREST_ZONE_NAME = "ForestZone"
local FOREST_ZONE_DECOR_FOLDER_NAME = "ForestZoneDecor"
local FOREST_ZONE_INTERACTIVES_FOLDER_NAME = "ForestZoneInteractives"
local FOREST_ZONE_RESOURCES_FOLDER_NAME = "ForestZoneResources"
local FOREST_ZONE_VISUAL_STATE_FOLDER_NAME = "VisualStateObjects"
local LEGACY_FOREST_ZONE_VISUAL_STATE_FOLDER_NAME = "ForestZoneVisualState"
local FOREST_AREA_ID = "ForestArea_01"
local BLOCKED_PATH_POSITION = Vector3.new(-14, 1.1, 8)
local FOREST_ZONE_POSITION = Vector3.new(-38, 0.05, 8)
local ROCK_PASS_POSITION = Vector3.new(-58, 1.1, 8)
local ROCK_ZONE_POSITION = Vector3.new(-78, 0.05, 8)
local FOREST_AREA_POSITION = FOREST_ZONE_POSITION + Vector3.new(0, 0, 2)
local FOREST_AREA_STAGE_NAMES = {
	"Active",
	"Full",
	"Medium",
	"Low",
	"TreeEmpty",
	"Empty",
}
local FOREST_AREA_TREE_POSITIONS = {
	FOREST_AREA_POSITION + Vector3.new(-8, 0.2, -5),
	FOREST_AREA_POSITION + Vector3.new(-4, 0.2, 4),
	FOREST_AREA_POSITION + Vector3.new(0, 0.2, -3),
	FOREST_AREA_POSITION + Vector3.new(4, 0.2, 5),
	FOREST_AREA_POSITION + Vector3.new(8, 0.2, -4),
	FOREST_AREA_POSITION + Vector3.new(10, 0.2, 3),
}
local FOREST_STONE_OBJECT_IDS = {
	"ForestStone_01",
	"ForestStone_02",
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

local function createTextSign(name, text, position, parent)
	local signModel = Instance.new("Model")
	signModel.Name = name
	signModel.Parent = parent

	createPart(
		"LeftPost",
		Vector3.new(0.35, 3, 0.35),
		position + Vector3.new(-2.2, -1, 0),
		Color3.fromRGB(90, 60, 35),
		signModel
	)

	createPart(
		"RightPost",
		Vector3.new(0.35, 3, 0.35),
		position + Vector3.new(2.2, -1, 0),
		Color3.fromRGB(90, 60, 35),
		signModel
	)

	local board = createPart(
		"Board",
		Vector3.new(5.5, 1.8, 0.4),
		position + Vector3.new(0, 0.8, 0),
		Color3.fromRGB(230, 195, 115),
		signModel
	)

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "TextSurface"
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 50
	surfaceGui.Parent = board

	local label = Instance.new("TextLabel")
	label.Name = "TextLabel"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.TextColor3 = Color3.fromRGB(55, 35, 20)
	label.Parent = surfaceGui

	return signModel
end

local function createAreaMarker(name, size, position, color, parent)
	local marker = createPart(name, size, position, color, parent)
	marker.Material = Enum.Material.SmoothPlastic
	marker.Transparency = 0.15

	return marker
end

local function getWorldRoot()
	local worldRoot = Workspace:FindFirstChild(WORLD_ROOT_NAME)

	if not worldRoot then
		worldRoot = Instance.new("Folder")
		worldRoot.Name = WORLD_ROOT_NAME
		worldRoot.Parent = Workspace
	end

	return worldRoot
end

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

local function removeLegacyForestZoneTrees(forestZone)
	for _, child in ipairs(forestZone:GetChildren()) do
		if string.match(child.Name, "^ForestDecorTree_%d+$") or string.match(child.Name, "^ForestTree_%d+$") then
			child:Destroy()
		end
	end
end

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

local function setModelVisible(model, isVisible)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Transparency = if isVisible then 0 else 1
			descendant.CanCollide = isVisible
			descendant.CanTouch = isVisible
			descendant.CanQuery = isVisible
		elseif descendant:IsA("SurfaceGui") then
			descendant.Enabled = isVisible
		elseif descendant:IsA("ProximityPrompt") then
			descendant.Enabled = isVisible
		end
	end
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

local function ensureForestZoneResourcesFolder(forestZone)
	local forestResources = forestZone:FindFirstChild(FOREST_ZONE_RESOURCES_FOLDER_NAME)

	if not forestResources then
		forestResources = Instance.new("Folder")
		forestResources.Name = FOREST_ZONE_RESOURCES_FOLDER_NAME
		forestResources.Parent = forestZone
	end

	return forestResources
end

local function ensureChildFolder(parent, folderName)
	local folder = parent:FindFirstChild(folderName)

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = folderName
		folder.Parent = parent
	end

	return folder
end

local function removeLegacyForestZoneVisualObjects(forestZone)
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

local function createFlatMarker(name, size, position, color, parent)
	local marker = createPart(name, size, position, color, parent)
	marker.Material = Enum.Material.Ground
	marker.CanCollide = false
	marker.CanTouch = false

	return marker
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

local function createForestZoneVisualForState(forestZone, state, visualStage, treeCount)
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

local function createLegacyForestAreaStage(parent, stageName, treeCount)
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

local function createForestAreaVisual(forestResources)
	local forestArea = forestResources:FindFirstChild(FOREST_AREA_ID)

	if not forestArea then
		forestArea = Instance.new("Model")
		forestArea.Name = FOREST_AREA_ID
		forestArea.Parent = forestResources
	end

	for _, stageName in ipairs(FOREST_AREA_STAGE_NAMES) do
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
		removeLegacyForestZoneTrees(existingForestZone)
		removeLegacyForestZoneVisualObjects(existingForestZone)
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

local function createBlockedPathToForest()
	local worldRoot = getWorldRoot()
	local existingBlockedPath = worldRoot:FindFirstChild(BLOCKED_PATH_NAME)

	if existingBlockedPath then
		return existingBlockedPath
	end

	local blockedPath = Instance.new("Model")
	blockedPath.Name = BLOCKED_PATH_NAME
	blockedPath.Parent = worldRoot

	local log = createPart(
		"FallenLog",
		Vector3.new(9, 1.4, 1.4),
		BLOCKED_PATH_POSITION,
		Color3.fromRGB(105, 65, 35),
		blockedPath
	)
	log.Rotation = Vector3.new(0, 0, 10)

	createPart(
		"BranchPile",
		Vector3.new(7, 2.6, 2.4),
		BLOCKED_PATH_POSITION + Vector3.new(0, 0.8, 0.2),
		Color3.fromRGB(55, 120, 50),
		blockedPath
	)

	createPart(
		"LeftRock",
		Vector3.new(2.5, 2.2, 2.5),
		BLOCKED_PATH_POSITION + Vector3.new(-4.5, 0.2, 0),
		Color3.fromRGB(105, 110, 110),
		blockedPath
	)

	createPart(
		"RightRock",
		Vector3.new(2.7, 2.1, 2.7),
		BLOCKED_PATH_POSITION + Vector3.new(4.5, 0.2, 0),
		Color3.fromRGB(100, 105, 105),
		blockedPath
	)

	createTextSign("BlockedPathSign", "Заросший проход", BLOCKED_PATH_POSITION + Vector3.new(0, 2.4, -3), blockedPath)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ClearForestPathPrompt"
	prompt.ObjectText = "Заросший проход"
	prompt.ActionText = "Расчистить путь"
	prompt.HoldDuration = 0.7
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Enabled = true
	prompt.Parent = log

	prompt.Triggered:Connect(function(player)
		WorldService.TryClearForestPath(player)
	end)

	blockedPath.PrimaryPart = log

	print("[WorldService] Created blocked path to forest.")
	return blockedPath
end

local function createRockZone()
	local worldRoot = getWorldRoot()
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

local function createRockPass()
	local worldRoot = getWorldRoot()
	local existingRockPass = worldRoot:FindFirstChild(ROCK_PASS_NAME)

	if existingRockPass then
		return existingRockPass
	end

	local rockPass = Instance.new("Model")
	rockPass.Name = ROCK_PASS_NAME
	rockPass.Parent = worldRoot

	local blocker = createPart(
		"RockPassBlocker",
		Vector3.new(9, 3.4, 3),
		ROCK_PASS_POSITION,
		Color3.fromRGB(100, 100, 100),
		rockPass
	)
	blocker.Material = Enum.Material.Rock

	local leftPile = createPart(
		"LeftRockPile",
		Vector3.new(3.5, 2.3, 3.5),
		ROCK_PASS_POSITION + Vector3.new(-5.2, -0.2, 0.3),
		Color3.fromRGB(90, 95, 95),
		rockPass
	)
	leftPile.Material = Enum.Material.Slate

	local rightPile = createPart(
		"RightRockPile",
		Vector3.new(3.8, 2.5, 3.2),
		ROCK_PASS_POSITION + Vector3.new(5.2, -0.1, -0.2),
		Color3.fromRGB(95, 100, 100),
		rockPass
	)
	rightPile.Material = Enum.Material.Slate

	createPart(
		"SmallMetalShard",
		Vector3.new(1.2, 0.35, 1.8),
		ROCK_PASS_POSITION + Vector3.new(0, -1.25, -2.2),
		Color3.fromRGB(140, 145, 150),
		rockPass
	).Material = Enum.Material.Metal

	createTextSign("RockPassSign", "Каменистый проход", ROCK_PASS_POSITION + Vector3.new(0, 2.9, -3.4), rockPass)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ClearRockPassPrompt"
	prompt.ObjectText = "Каменистый проход"
	prompt.ActionText = "Разобрать проход"
	prompt.HoldDuration = 0.8
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Enabled = true
	prompt.Parent = blocker

	prompt.Triggered:Connect(function(player)
		WorldService.TryClearRockPass(player)
	end)

	rockPass.PrimaryPart = blocker

	print("[WorldService] Created RockPass.")
	return rockPass
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
