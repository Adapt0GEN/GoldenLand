-- WorldService
-- Создаёт простую стартовую сцену и визуальные ориентиры мира.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PlayerDataService = require(script.Parent.PlayerDataService)
local ResourceService = require(script.Parent.ResourceService)

local WorldService = {}

local WORLD_ROOT_NAME = "WorldRoot"
local BLOCKED_PATH_NAME = "BlockedPathToForest"
local FOREST_ZONE_NAME = "ForestZone"
local FOREST_ZONE_RESOURCES_FOLDER_NAME = "ForestZoneResources"
local FOREST_AREA_ID = "ForestArea_01"
local BLOCKED_PATH_POSITION = Vector3.new(-14, 1.1, 8)
local FOREST_ZONE_POSITION = Vector3.new(-38, 0.05, 8)
local FOREST_AREA_POSITION = FOREST_ZONE_POSITION + Vector3.new(0, 0, 2)
local FOREST_AREA_STAGE_NAMES = {
	"Active",
	"Empty",
}
local FOREST_AREA_STAGE_LOOKUP = {
	Active = true,
	Empty = true,
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

local function getRemoteEvent(eventName)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")

	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = ReplicatedStorage
	end

	local remoteEvent = remotes:FindFirstChild(eventName)

	if not remoteEvent then
		remoteEvent = Instance.new("RemoteEvent")
		remoteEvent.Name = eventName
		remoteEvent.Parent = remotes
	end

	return remoteEvent
end

local function sendPlayerMessage(player, message)
	getRemoteEvent("PlayerMessageEvent"):FireClient(player, message)
end

local function removeBlockedPath()
	local blockedPath = getWorldRoot():FindFirstChild(BLOCKED_PATH_NAME)

	if blockedPath then
		blockedPath:Destroy()
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

local function createForestAreaStage(parent, stageName)
	local stage = parent:FindFirstChild(string.format("%s_%s", FOREST_AREA_ID, stageName))

	if stage then
		return stage
	end

	stage = Instance.new("Model")
	stage.Name = string.format("%s_%s", FOREST_AREA_ID, stageName)
	stage.Parent = parent

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
		createForestAreaStage(forestArea, stageName)
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

	if RunService:IsStudio() then
		local debugPromptPart = forestArea:FindFirstChild("DebugResetForestPromptPart")

		if not debugPromptPart then
			debugPromptPart = createPart(
				"DebugResetForestPromptPart",
				Vector3.new(3, 1.5, 0.5),
				FOREST_AREA_POSITION + Vector3.new(9, 1.4, 8),
				Color3.fromRGB(180, 80, 80),
				forestArea
			)
			debugPromptPart.Transparency = 0.35
			debugPromptPart.CanCollide = false
			debugPromptPart.CanTouch = false
		end

		local legacyDebugPromptPart = forestArea:FindFirstChild("DebugResetForestAreaPromptPart")

		if legacyDebugPromptPart and legacyDebugPromptPart ~= debugPromptPart then
			legacyDebugPromptPart:Destroy()
		end

		local legacyDebugPrompt = debugPromptPart:FindFirstChild("DebugResetForestAreaPrompt")

		if legacyDebugPrompt then
			legacyDebugPrompt:Destroy()
		end

		local debugPrompt = debugPromptPart:FindFirstChild("DebugResetForestPrompt")

		if not debugPrompt then
			debugPrompt = Instance.new("ProximityPrompt")
			debugPrompt.Name = "DebugResetForestPrompt"
			debugPrompt.ObjectText = "DEBUG ForestArea_01"
			debugPrompt.ActionText = "Reset Forest"
			debugPrompt.HoldDuration = 0.3
			debugPrompt.MaxActivationDistance = 10
			debugPrompt.RequiresLineOfSight = false
			debugPrompt.Parent = debugPromptPart

			debugPrompt.Triggered:Connect(function(player)
				ResourceService.ResetResourceZoneForDebug(player, FOREST_AREA_ID)
			end)
		end

		debugPrompt.ObjectText = "DEBUG ForestArea_01"
		debugPrompt.ActionText = "Reset Forest"
		debugPrompt.HoldDuration = 0.3
		debugPrompt.MaxActivationDistance = 10
		debugPrompt.RequiresLineOfSight = false
	end

	return forestArea
end

local function createForestZone()
	local worldRoot = getWorldRoot()
	local existingForestZone = worldRoot:FindFirstChild(FOREST_ZONE_NAME)

	if existingForestZone then
		removeLegacyForestZoneTrees(existingForestZone)
		createForestAreaVisual(ensureForestZoneResourcesFolder(existingForestZone))
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

	createDecorativeStone("ForestDecorStone_1", FOREST_ZONE_POSITION + Vector3.new(-12, 1.1, 5), forestZone)
	createDecorativeStone("ForestDecorStone_2", FOREST_ZONE_POSITION + Vector3.new(12, 1.1, -6), forestZone)

	createTextSign("ForestZoneSign", "Лесная зона", FOREST_ZONE_POSITION + Vector3.new(0, 2.5, -13), forestZone)
	createForestAreaVisual(ensureForestZoneResourcesFolder(forestZone))

	print("[WorldService] Created forest zone.")
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

function WorldService.TryClearForestPath(player)
	print(string.format("[WorldService] %s tried to clear forest path.", player.Name))

	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[WorldService] Profile for %s was not found. Forest path was not cleared.", player.Name))
		return false
	end

	if profile.ForestUnlocked == true then
		removeBlockedPath()
		ResourceService.CreateForestZoneResources(createForestZone(), true)
		WorldService.UpdateForestAreaVisual(player)
		return true
	end

	if (profile.ToolKitLevel or 0) < 1 then
		warn(string.format("[WorldService] %s cannot clear forest path: ToolKitLevel 1 required.", player.Name))
		sendPlayerMessage(player, "Нужен набор инструментов I")
		return false
	end

	profile.ForestUnlocked = true
	PlayerDataService.MarkDirty(player)
	removeBlockedPath()
	ResourceService.CreateForestZoneResources(createForestZone(), true)
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

function WorldService.UpdateForestAccessForPlayer(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[WorldService] Profile for %s was not found. Forest access was not updated.", player.Name))
		return false
	end

	if profile.ForestUnlocked == true then
		removeBlockedPath()
		ResourceService.CreateForestZoneResources(createForestZone(), true)
		WorldService.UpdateForestAreaVisual(player)
	else
		createBlockedPathToForest()
	end

	return true
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
	local forestArea = createForestAreaVisual(forestResources)
	local resourceZones = profile.ResourceZones or {}
	local forestAreaData = resourceZones[FOREST_AREA_ID] or {}
	local state = forestAreaData.State or "Active"

	if not FOREST_AREA_STAGE_LOOKUP[state] then
		state = "Active"
	end

	for _, child in ipairs(forestArea:GetChildren()) do
		if child:IsA("Model") and string.match(child.Name, "^" .. FOREST_AREA_ID .. "_") then
			local expectedStageName = string.format("%s_%s", FOREST_AREA_ID, state)
			setModelVisible(child, child.Name == expectedStageName)
		end
	end

	local prompt = forestArea:FindFirstChild("GatherForestAreaPrompt", true)

	if prompt then
		prompt.Enabled = state == "Active" and (forestAreaData.RemainingActions or 12) > 0
	end

	print(string.format("[WorldService] Updated ForestArea_01 visual state: %s", state))

	if state == "Active" then
		local activeStage = forestArea:FindFirstChild(string.format("%s_Active", FOREST_AREA_ID))
		local treeCount, rockCount = 0, 0

		if activeStage then
			treeCount, rockCount = countVisibleActiveForestParts(activeStage)
		end

		print(string.format("[WorldService] ForestArea_01 active visual created: %d trees, %d rocks", treeCount, rockCount))
	elseif state == "Empty" and not hasVisibleGreenTree(forestArea) then
		print("[WorldService] ForestArea_01 empty visual has no active trees")
	end

	return true
end

function WorldService.CreateStartWorld()
	local existingWorld = Workspace:FindFirstChild(WORLD_ROOT_NAME)

	if existingWorld then
		print("[WorldService] Start world already exists.")
		createBlockedPathToForest()
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

	print("[WorldService] Start world created.")
	return worldRoot
end

return WorldService
