-- PlotService
-- Тестовый участок, визуальное развитие дома и платное улучшение.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local PlayerDataService = require(script.Parent.PlayerDataService)
local CurrencyService = require(script.Parent.CurrencyService)
local QuestService = require(script.Parent.QuestService)

local PlotService = {}

local PLAYER_PLOTS_CONTAINER_NAME = "PlayerPlots"
local USE_MVP_NEAR_START_PLOT = true
local MVP_PLOT_POSITION = Vector3.new(80, 0, 0)
local GRID_START_POSITION = Vector3.new(-200, 0, -200)
local PLOT_SPACING = 1500
local PLOT_SIZE = Vector3.new(40, 1, 40)
local MAX_HOUSE_LEVEL = 3
local MAX_STORAGE_LEVEL = 2
local STORAGE_QUEST_ID = "build_storage"
local STORAGE_OBJECTIVE_ID = "storage_built"
local STORAGE_BUILD_COST = {
	Gold = 15,
	Wood = 10,
	Stone = 5,
}

local STORAGE_LEVEL_2_COST = {
	Wood = 40,
	Stone = 40,
	Metal = 15,
	MetalIngot = 3,
	MetalParts = 2,
	Gold = 20,
}

local WORKSHOP_BUILD_COST = {
	Gold = 25,
	Wood = 15,
	Stone = 10,
}

local FORGE_BUILD_COST = {
	Gold = 10,
	Wood = 20,
	Stone = 30,
	Metal = 15,
}

local FORGE_SMELT_COST = {
	Metal = 5,
}

local FORGE_PARTS_COST = {
	MetalIngot = 2,
}

local TOOL_KIT_I_COST = {
	Gold = 3,
	Wood = 10,
	Stone = 5,
	Metal = 5,
}

local TOOL_KIT_II_COST = {
	Gold = 10,
	Wood = 25,
	Stone = 20,
	Metal = 15,
}

local HOUSE_UPGRADE_COSTS = {
	[1] = {
		Gold = 25,
		Wood = 5,
		Stone = 3,
	},
	[2] = {
		Gold = 50,
		Wood = 10,
		Stone = 6,
	},
}

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

local function sendActionPreview(player, previewData)
	getRemoteEvent("ActionPreviewEvent"):FireClient(player, previewData)
end

local function getPlotName(player)
	return string.format("Plot_%d", player.UserId)
end

local function getPlayerPlotsContainer(createIfMissing)
	local playerPlots = Workspace:FindFirstChild(PLAYER_PLOTS_CONTAINER_NAME)

	if not playerPlots and createIfMissing then
		playerPlots = Instance.new("Folder")
		playerPlots.Name = PLAYER_PLOTS_CONTAINER_NAME
		playerPlots.Parent = Workspace
		print("[PlotService] Created PlayerPlots container.")
	end

	return playerPlots
end

local function getPlotGridPosition(player)
	local userId = player.UserId
	local index = math.abs(userId) % 10000
	local gridX = index % 100
	local gridZ = math.floor(index / 100)

	if USE_MVP_NEAR_START_PLOT then
		print(string.format(
			"[PlotService] Assigned MVP near-start plot for %s: gridX=%d, gridZ=%d, position=%s",
			player.Name,
			gridX,
			gridZ,
			tostring(MVP_PLOT_POSITION)
		))

		return MVP_PLOT_POSITION, gridX, gridZ
	end

	local position = GRID_START_POSITION + Vector3.new(
		gridX * PLOT_SPACING,
		0,
		gridZ * PLOT_SPACING
	)

	print(string.format(
		"[PlotService] Assigned plot grid for %s: gridX=%d, gridZ=%d, position=%s",
		player.Name,
		gridX,
		gridZ,
		tostring(position)
	))

	return position, gridX, gridZ
end

local function getPlot(player)
	local plotName = getPlotName(player)
	local playerPlots = getPlayerPlotsContainer(false)
	local plotModel = if playerPlots then playerPlots:FindFirstChild(plotName) else nil

	return plotModel or Workspace:FindFirstChild(plotName)
end

local function setPlotOwnershipAttributes(plotModel, player, gridX, gridZ)
	plotModel:SetAttribute("OwnerUserId", player.UserId)
	plotModel:SetAttribute("OwnerName", player.Name)
	plotModel:SetAttribute("GridX", gridX)
	plotModel:SetAttribute("GridZ", gridZ)
end

local function setPlotBaseAttributes(plotBase, player, gridX, gridZ)
	if not plotBase then
		return
	end

	plotBase:SetAttribute("OwnerUserId", player.UserId)
	plotBase:SetAttribute("OwnerName", player.Name)
	plotBase:SetAttribute("GridX", gridX)
	plotBase:SetAttribute("GridZ", gridZ)
end

local function getPlotBase(plotModel)
	return plotModel:FindFirstChild("PlotBase")
		or plotModel:FindFirstChild("Plot")
		or plotModel.PrimaryPart
end

local function plotOffsetCFrame(plotBase, offset)
	return plotBase.CFrame * CFrame.new(offset.X, offset.Y, offset.Z)
end

local function createPart(name, size, cframe, color, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.Color = color
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent

	return part
end

local function getUpgradeCost(houseLevel)
	return HOUSE_UPGRADE_COSTS[houseLevel]
end

local function formatCost(cost)
	return CurrencyService.FormatCost(cost)
end

local function buildResourceSnapshot(profile)
	return {
		Gold = profile.Gold or 0,
		Wood = profile.Wood or 0,
		Stone = profile.Stone or 0,
		Metal = profile.Metal or 0,
		MetalIngot = profile.MetalIngot or 0,
		MetalParts = profile.MetalParts or 0,
	}
end

local function buildMissingResourceSnapshot(player, cost)
	local missing = {
		Gold = 0,
		Wood = 0,
		Stone = 0,
		Metal = 0,
		MetalIngot = 0,
		MetalParts = 0,
	}

	for _, missingResource in ipairs(CurrencyService.GetMissingResources(player, cost)) do
		missing[missingResource.Name] = missingResource.Amount
	end

	return missing
end

local function buildActionPreview(player, title, description, cost)
	local profile = PlayerDataService.GetProfile(player)

	if not profile or not cost then
		return nil
	end

	return {
		visible = true,
		title = title,
		description = description,
		cost = cost,
		current = buildResourceSnapshot(profile),
		missing = buildMissingResourceSnapshot(player, cost),
		canAfford = CurrencyService.CanAfford(player, cost),
	}
end

local function buildHouseUpgradePreview(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		return nil
	end

	local currentLevel = PlayerDataService.GetBuildingLevel(profile, "House")
	local cost = getUpgradeCost(currentLevel)

	if currentLevel >= MAX_HOUSE_LEVEL or not cost then
		return nil
	end

	return buildActionPreview(
		player,
		"Улучшение дома",
		string.format("Дом: уровень %d -> %d", currentLevel, currentLevel + 1),
		cost
	)
end

local function buildToolKitPreview(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		return nil
	end

	local toolKitLevel = profile.ToolKitLevel or 0

	if toolKitLevel == 0 then
		return buildActionPreview(
			player,
			"Создание инструментов I",
			"Инструменты: нет -> уровень 1",
			TOOL_KIT_I_COST
		)
	elseif toolKitLevel == 1 then
		return buildActionPreview(
			player,
			"Улучшение инструментов II",
			"Инструменты: уровень 1 -> 2",
			TOOL_KIT_II_COST
		)
	end

	return nil
end

local function buildForgePreview(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile or PlayerDataService.GetBuildingLevel(profile, "Forge") >= 1 then
		return nil
	end

	return buildActionPreview(
		player,
		"Строительство кузницы",
		"Кузница: уровень 0 -> 1",
		FORGE_BUILD_COST
	)
end

local function buildForgeSmeltPreview(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile or PlayerDataService.GetBuildingLevel(profile, "Forge") < 1 then
		return nil
	end

	return buildActionPreview(
		player,
		"Плавка в кузнице",
		"Металл 5 -> слиток 1",
		FORGE_SMELT_COST
	)
end

local function buildForgePartsPreview(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile or PlayerDataService.GetBuildingLevel(profile, "Forge") < 1 then
		return nil
	end

	return buildActionPreview(
		player,
		"Производство деталей",
		"Слитки 2 -> детали 1",
		FORGE_PARTS_COST
	)
end

local function buildStorageUpgradePreview(player)
	local profile = PlayerDataService.GetProfile(player)

	local storageLevel = if profile then PlayerDataService.GetBuildingLevel(profile, "Storage") else 0

	if not profile or storageLevel < 1 then
		return nil
	end

	if storageLevel >= MAX_STORAGE_LEVEL then
		return nil
	end

	return buildActionPreview(
		player,
		"Улучшение склада",
		string.format("Склад: уровень %d -> %d", storageLevel, storageLevel + 1),
		STORAGE_LEVEL_2_COST
	)
end

local function hideActionPreview(player)
	sendActionPreview(player, {
		visible = false,
	})
end

local function addHouseUpgradePrompt(promptPart)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "HouseUpgradePrompt"
	prompt.ObjectText = "Дом"
	prompt.ActionText = "Улучшить"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = promptPart

	prompt.Triggered:Connect(function(player)
		PlotService.TryUpgradeHouse(player)
	end)

	return prompt
end

local function addStorageBuildPrompt(promptPart)
	local existingPrompt = promptPart:FindFirstChild("StorageBuildPrompt")

	if existingPrompt then
		return existingPrompt
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StorageBuildPrompt"
	prompt.ObjectText = "Склад"
	prompt.ActionText = "Построить склад"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = promptPart

	prompt.Triggered:Connect(function(player)
		PlotService.TryBuildStorage(player)
	end)

	return prompt
end

local function addStorageUpgradePrompt(promptPart)
	local existingPrompt = promptPart:FindFirstChild("StorageUpgradePrompt")

	if existingPrompt then
		return existingPrompt
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StorageUpgradePrompt"
	prompt.ObjectText = "Склад"
	prompt.ActionText = "Улучшить склад"
	prompt.HoldDuration = 0.7
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Enabled = true
	prompt.Parent = promptPart

	prompt.Triggered:Connect(function(player)
		PlotService.TryUpgradeStorage(player)
	end)

	return prompt
end

local function removeStorageUpgradePrompt(storage)
	local upgradePrompt = storage:FindFirstChild("StorageUpgradePrompt", true)

	if upgradePrompt then
		upgradePrompt:Destroy()
	end
end

local function addWorkshopBuildPrompt(promptPart)
	local existingPrompt = promptPart:FindFirstChild("WorkshopBuildPrompt")

	if existingPrompt then
		return existingPrompt
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "WorkshopBuildPrompt"
	prompt.ObjectText = "Мастерская"
	prompt.ActionText = "Построить мастерскую"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Enabled = true
	prompt.Parent = promptPart

	prompt.Triggered:Connect(function(player)
		PlotService.TryBuildWorkshop(player)
	end)

	return prompt
end

local function addForgeBuildPrompt(promptPart)
	local existingPrompt = promptPart:FindFirstChild("BuildForgePrompt")

	if existingPrompt then
		return existingPrompt
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuildForgePrompt"
	prompt.ObjectText = "Место для кузницы"
	prompt.ActionText = "Построить кузницу"
	prompt.HoldDuration = 0.7
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Enabled = true
	prompt.Parent = promptPart

	prompt.Triggered:Connect(function(player)
		PlotService.TryBuildForge(player)
	end)

	return prompt
end

local function addForgeSmeltPrompt(forge)
	local promptPart = forge:FindFirstChild("ForgeHearth")

	if not promptPart then
		warn("[Forge] ForgeHearth was not found. Smelt prompt was not created.")
		return nil
	end

	local existingPrompt = promptPart:FindFirstChild("SmeltMetalIngotPrompt")

	if existingPrompt then
		return existingPrompt
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SmeltMetalIngotPrompt"
	prompt.ObjectText = "Кузница"
	prompt.ActionText = "Выплавить слиток"
	prompt.HoldDuration = 0.7
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Enabled = true
	prompt.Parent = promptPart

	prompt.Triggered:Connect(function(player)
		PlotService.TrySmeltMetalIngot(player)
	end)

	return prompt
end

local function addForgePartsPrompt(forge)
	local promptPart = forge:FindFirstChild("ForgeAnvil")

	if not promptPart then
		warn("[Forge] ForgeAnvil was not found. Metal parts prompt was not created.")
		return nil
	end

	local existingPrompt = promptPart:FindFirstChild("MakeMetalPartsPrompt")

	if existingPrompt then
		return existingPrompt
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "MakeMetalPartsPrompt"
	prompt.ObjectText = "Кузница"
	prompt.ActionText = "Сделать детали"
	prompt.HoldDuration = 0.7
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Enabled = true
	prompt.Parent = promptPart

	prompt.Triggered:Connect(function(player)
		PlotService.TryMakeMetalParts(player)
	end)

	return prompt
end

local function removeToolKitCraftPrompt(workshop)
	local craftPrompt = workshop:FindFirstChild("CraftToolKitPrompt", true)

	if craftPrompt then
		craftPrompt:Destroy()
	end
end

local function getToolKitPromptActionText(player)
	local profile = PlayerDataService.GetProfile(player)
	local toolKitLevel = if profile then profile.ToolKitLevel or 0 else 0

	if toolKitLevel == 1 then
		return "Улучшить инструменты II"
	end

	return "Изготовить инструменты I"
end

local function addToolKitCraftPrompt(player, workshop)
	local promptPart = workshop:FindFirstChild("WorkshopBody")

	if not promptPart then
		warn(string.format("[PlotService] WorkshopBody was not found for %s. Tool kit prompt was not created.", player.Name))
		return nil
	end

	local existingPrompt = promptPart:FindFirstChild("CraftToolKitPrompt")

	if existingPrompt then
		existingPrompt.ActionText = getToolKitPromptActionText(player)
		return existingPrompt
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "CraftToolKitPrompt"
	prompt.ObjectText = "Мастерская"
	prompt.ActionText = getToolKitPromptActionText(player)
	prompt.HoldDuration = 0.7
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Enabled = true
	prompt.Parent = promptPart

	prompt.Triggered:Connect(function(triggeringPlayer)
		PlotService.TryCraftToolKit(triggeringPlayer)
	end)

	print(string.format("[PlotService] Created tool kit craft prompt for %s.", player.Name))
	return prompt
end

local function createPlayerSign(player, plotModel, plotBase)
	-- Простая табличка с именем игрока у входа на участок.
	local leftPost = createPart(
		"SignLeftPost",
		Vector3.new(0.4, 3, 0.4),
		plotOffsetCFrame(plotBase, Vector3.new(-16, 2, -17)),
		Color3.fromRGB(95, 65, 40),
		plotModel
	)

	local rightPost = createPart(
		"SignRightPost",
		Vector3.new(0.4, 3, 0.4),
		plotOffsetCFrame(plotBase, Vector3.new(-10, 2, -17)),
		Color3.fromRGB(95, 65, 40),
		plotModel
	)

	local sign = createPart(
		"PlayerNameSign",
		Vector3.new(8, 2, 0.4),
		plotOffsetCFrame(plotBase, Vector3.new(-13, 4, -17)),
		Color3.fromRGB(235, 205, 120),
		plotModel
	)

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "NameSurface"
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 50
	surfaceGui.Parent = sign

	local label = Instance.new("TextLabel")
	label.Name = "PlayerNameLabel"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = player.Name
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.TextColor3 = Color3.fromRGB(55, 35, 20)
	label.Parent = surfaceGui

	return leftPost, rightPost, sign
end

local function createPlotAreaSign(plotModel, plotBase)
	-- Общая табличка, чтобы участок читался как личная земля игрока.
	createPart(
		"LandSignLeftPost",
		Vector3.new(0.4, 3, 0.4),
		plotOffsetCFrame(plotBase, Vector3.new(9, 2, -17)),
		Color3.fromRGB(95, 65, 40),
		plotModel
	)

	createPart(
		"LandSignRightPost",
		Vector3.new(0.4, 3, 0.4),
		plotOffsetCFrame(plotBase, Vector3.new(17, 2, -17)),
		Color3.fromRGB(95, 65, 40),
		plotModel
	)

	local sign = createPart(
		"PersonalLandSign",
		Vector3.new(10, 2, 0.4),
		plotOffsetCFrame(plotBase, Vector3.new(13, 4, -17)),
		Color3.fromRGB(235, 205, 120),
		plotModel
	)

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "LandSurface"
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 50
	surfaceGui.Parent = sign

	local label = Instance.new("TextLabel")
	label.Name = "LandLabel"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "Личная земля"
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.TextColor3 = Color3.fromRGB(55, 35, 20)
	label.Parent = surfaceGui

	return sign
end

local function rebuildPlotSigns(player, plotModel, plotBase)
	local signPartNames = {
		"SignLeftPost",
		"SignRightPost",
		"PlayerNameSign",
		"LandSignLeftPost",
		"LandSignRightPost",
		"PersonalLandSign",
	}

	for _, signPartName in ipairs(signPartNames) do
		local signPart = plotModel:FindFirstChild(signPartName)

		if signPart then
			signPart:Destroy()
		end
	end

	createPlayerSign(player, plotModel, plotBase)
	createPlotAreaSign(plotModel, plotBase)
end

local function createLevelOneHouse(house, plotBase)
	-- Уровень 1: маленькая хижина.
	local body = createPart(
		"HouseBody",
		Vector3.new(10, 6, 10),
		plotOffsetCFrame(plotBase, Vector3.new(0, 3.5, 0)),
		Color3.fromRGB(145, 95, 55),
		house
	)

	createPart(
		"HouseRoof",
		Vector3.new(12, 2, 12),
		plotOffsetCFrame(plotBase, Vector3.new(0, 7.5, 0)),
		Color3.fromRGB(105, 55, 45),
		house
	)

	createPart(
		"HouseDoor",
		Vector3.new(2.5, 4, 0.3),
		plotOffsetCFrame(plotBase, Vector3.new(0, 2.5, -5.15)),
		Color3.fromRGB(70, 45, 30),
		house
	)

	createPart(
		"HouseWindow",
		Vector3.new(2, 2, 0.3),
		plotOffsetCFrame(plotBase, Vector3.new(3.2, 4, -5.15)),
		Color3.fromRGB(170, 220, 255),
		house
	)

	addHouseUpgradePrompt(body)
end

local function createLevelTwoHouse(house, plotBase)
	-- Уровень 2: дом крупнее, светлее и с боковой пристройкой.
	local body = createPart(
		"HouseBody",
		Vector3.new(14, 8, 12),
		plotOffsetCFrame(plotBase, Vector3.new(0, 4.5, 0)),
		Color3.fromRGB(190, 135, 75),
		house
	)

	createPart(
		"HouseExtension",
		Vector3.new(6, 5, 8),
		plotOffsetCFrame(plotBase, Vector3.new(10, 3, 1)),
		Color3.fromRGB(175, 120, 65),
		house
	)

	createPart(
		"HouseRoof",
		Vector3.new(16, 2, 14),
		plotOffsetCFrame(plotBase, Vector3.new(0, 9.5, 0)),
		Color3.fromRGB(135, 45, 45),
		house
	)

	createPart(
		"ExtensionRoof",
		Vector3.new(7, 1.5, 9),
		plotOffsetCFrame(plotBase, Vector3.new(10, 6.25, 1)),
		Color3.fromRGB(135, 45, 45),
		house
	)

	createPart(
		"HouseDoor",
		Vector3.new(3, 4.5, 0.3),
		plotOffsetCFrame(plotBase, Vector3.new(-2, 2.75, -6.15)),
		Color3.fromRGB(80, 45, 25),
		house
	)

	createPart(
		"HouseWindowLeft",
		Vector3.new(2, 2, 0.3),
		plotOffsetCFrame(plotBase, Vector3.new(3, 5, -6.15)),
		Color3.fromRGB(175, 225, 255),
		house
	)

	createPart(
		"HouseWindowRight",
		Vector3.new(2, 2, 0.3),
		plotOffsetCFrame(plotBase, Vector3.new(10, 3.5, -3.15)),
		Color3.fromRGB(175, 225, 255),
		house
	)

	addHouseUpgradePrompt(body)
end

local function createLevelThreeHouse(house, plotBase)
	-- Уровень 3: большой укреплённый дом с высокой крышей и вторым крылом.
	local body = createPart(
		"HouseBody",
		Vector3.new(18, 10, 14),
		plotOffsetCFrame(plotBase, Vector3.new(0, 5.5, 0)),
		Color3.fromRGB(205, 155, 90),
		house
	)

	createPart(
		"HouseLeftWing",
		Vector3.new(7, 7, 10),
		plotOffsetCFrame(plotBase, Vector3.new(-12, 4, 1)),
		Color3.fromRGB(185, 130, 75),
		house
	)

	createPart(
		"HouseRightWing",
		Vector3.new(7, 7, 10),
		plotOffsetCFrame(plotBase, Vector3.new(12, 4, 1)),
		Color3.fromRGB(185, 130, 75),
		house
	)

	createPart(
		"HouseRoof",
		Vector3.new(20, 2.5, 16),
		plotOffsetCFrame(plotBase, Vector3.new(0, 11.75, 0)),
		Color3.fromRGB(115, 35, 35),
		house
	)

	createPart(
		"LeftWingRoof",
		Vector3.new(8, 2, 11),
		plotOffsetCFrame(plotBase, Vector3.new(-12, 8.5, 1)),
		Color3.fromRGB(115, 35, 35),
		house
	)

	createPart(
		"RightWingRoof",
		Vector3.new(8, 2, 11),
		plotOffsetCFrame(plotBase, Vector3.new(12, 8.5, 1)),
		Color3.fromRGB(115, 35, 35),
		house
	)

	createPart(
		"HouseDoor",
		Vector3.new(3.5, 5, 0.3),
		plotOffsetCFrame(plotBase, Vector3.new(0, 3, -7.15)),
		Color3.fromRGB(75, 45, 25),
		house
	)

	createPart(
		"HouseWindowLeft",
		Vector3.new(2.2, 2.2, 0.3),
		plotOffsetCFrame(plotBase, Vector3.new(-5, 6, -7.15)),
		Color3.fromRGB(180, 230, 255),
		house
	)

	createPart(
		"HouseWindowRight",
		Vector3.new(2.2, 2.2, 0.3),
		plotOffsetCFrame(plotBase, Vector3.new(5, 6, -7.15)),
		Color3.fromRGB(180, 230, 255),
		house
	)

	addHouseUpgradePrompt(body)
end

local function removeStorageBuildSpot(plotModel)
	local buildSpot = plotModel:FindFirstChild("StorageBuildSpot")

	if buildSpot then
		buildSpot:Destroy()
	end
end

local function storagePlotCFrame(plotBase, localOffset)
	return plotOffsetCFrame(plotBase, Vector3.new(-12, 0, 14) + localOffset)
end

local function createStorageBuildSpot(plotModel, plotBase)
	if plotModel:FindFirstChild("StorageBuilding") then
		removeStorageBuildSpot(plotModel)
		return nil
	end

	local existingBuildSpot = plotModel:FindFirstChild("StorageBuildSpot")

	if existingBuildSpot then
		return existingBuildSpot
	end

	local buildSpot = createPart(
		"StorageBuildSpot",
		Vector3.new(8, 0.35, 6),
		storagePlotCFrame(plotBase, Vector3.new(0, 0.45, 0)),
		Color3.fromRGB(210, 185, 95),
		plotModel
	)
	buildSpot.Material = Enum.Material.SmoothPlastic
	buildSpot.Transparency = 0.25

	addStorageBuildPrompt(buildSpot)

	return buildSpot
end

local function updateStorageLevelVisual(storage, plotBase, storageLevel)
	local existingReinforcement = storage:FindFirstChild("StorageReinforcement")
	local existingExtraCrate = storage:FindFirstChild("StorageExtraCrate")

	if storageLevel < 2 then
		if existingReinforcement then
			existingReinforcement:Destroy()
		end

		if existingExtraCrate then
			existingExtraCrate:Destroy()
		end

		return
	end

	if not existingReinforcement then
		createPart(
			"StorageReinforcement",
			Vector3.new(8.6, 0.35, 6.6),
			storagePlotCFrame(plotBase, Vector3.new(0, 5.55, 0)),
			Color3.fromRGB(95, 95, 100),
			storage
		).Material = Enum.Material.Metal
	end

	if not existingExtraCrate then
		createPart(
			"StorageExtraCrate",
			Vector3.new(2.2, 1.4, 1.8),
			storagePlotCFrame(plotBase, Vector3.new(-3, 1.1, 1.4)),
			Color3.fromRGB(130, 90, 50),
			storage
		)
	end
end

local function updateStoragePrompt(storage, storageLevel)
	local storageBody = storage:FindFirstChild("StorageBody")

	if not storageBody then
		return
	end

	if storageLevel < MAX_STORAGE_LEVEL then
		addStorageUpgradePrompt(storageBody)
	else
		removeStorageUpgradePrompt(storage)
	end
end

local function createStorageBuilding(plotModel, plotBase, storageLevel)
	removeStorageBuildSpot(plotModel)
	storageLevel = storageLevel or 1

	local existingStorage = plotModel:FindFirstChild("StorageBuilding")

	if existingStorage then
		updateStorageLevelVisual(existingStorage, plotBase, storageLevel)
		updateStoragePrompt(existingStorage, storageLevel)
		return existingStorage
	end

	local storage = Instance.new("Model")
	storage.Name = "StorageBuilding"
	storage.Parent = plotModel

	createPart(
		"StorageBody",
		Vector3.new(8, 5, 6),
		storagePlotCFrame(plotBase, Vector3.new(0, 3, 0)),
		Color3.fromRGB(130, 85, 45),
		storage
	)

	createPart(
		"StorageRoof",
		Vector3.new(9, 1.5, 7),
		storagePlotCFrame(plotBase, Vector3.new(0, 6.25, 0)),
		Color3.fromRGB(95, 50, 35),
		storage
	)

	createPart(
		"StorageDoor",
		Vector3.new(2.2, 3, 0.3),
		storagePlotCFrame(plotBase, Vector3.new(0, 2.25, -3.15)),
		Color3.fromRGB(65, 40, 25),
		storage
	)

	createPart(
		"StorageCrate",
		Vector3.new(2.5, 1.5, 2),
		storagePlotCFrame(plotBase, Vector3.new(3, 1.15, 1.5)),
		Color3.fromRGB(160, 105, 55),
		storage
	)

	updateStorageLevelVisual(storage, plotBase, storageLevel)
	updateStoragePrompt(storage, storageLevel)

	return storage
end

local function removeWorkshopBuildSpot(plotModel)
	local buildSpot = plotModel:FindFirstChild("WorkshopBuildSpot")

	if buildSpot then
		buildSpot:Destroy()
	end

	local buildSign = plotModel:FindFirstChild("WorkshopBuildSign")

	if buildSign then
		buildSign:Destroy()
	end
end

local function workshopPlotCFrame(plotBase, localOffset)
	return plotOffsetCFrame(plotBase, Vector3.new(13, 0.8, 11) + localOffset)
end

local function createWorkshopBuildSign(plotModel, plotBase)
	local existingSign = plotModel:FindFirstChild("WorkshopBuildSign")

	if existingSign then
		return existingSign
	end

	local signModel = Instance.new("Model")
	signModel.Name = "WorkshopBuildSign"
	signModel.Parent = plotModel

	local signCFrame = workshopPlotCFrame(plotBase, Vector3.new(0, 1.4, -5.5))

	createPart(
		"WorkshopBuildSignLeftPost",
		Vector3.new(0.35, 2.4, 0.35),
		signCFrame * CFrame.new(-2.4, 0, 0),
		Color3.fromRGB(90, 60, 35),
		signModel
	)

	createPart(
		"WorkshopBuildSignRightPost",
		Vector3.new(0.35, 2.4, 0.35),
		signCFrame * CFrame.new(2.4, 0, 0),
		Color3.fromRGB(90, 60, 35),
		signModel
	)

	local board = createPart(
		"WorkshopBuildSignBoard",
		Vector3.new(5.8, 1.8, 0.35),
		signCFrame * CFrame.new(0, 1.05, 0),
		Color3.fromRGB(210, 185, 240),
		signModel
	)

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "WorkshopBuildSignSurface"
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 50
	surfaceGui.Parent = board

	local label = Instance.new("TextLabel")
	label.Name = "WorkshopBuildSignLabel"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "Место для мастерской"
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.TextColor3 = Color3.fromRGB(45, 30, 65)
	label.Parent = surfaceGui

	return signModel
end

local function createWorkshopBuildSpot(player, plotModel, plotBase)
	if plotModel:FindFirstChild("WorkshopBuilding") then
		removeWorkshopBuildSpot(plotModel)
		return nil
	end

	local existingBuildSpot = plotModel:FindFirstChild("WorkshopBuildSpot")

	if existingBuildSpot then
		addWorkshopBuildPrompt(existingBuildSpot)
		createWorkshopBuildSign(plotModel, plotBase)
		return existingBuildSpot
	end

	local buildSpot = createPart(
		"WorkshopBuildSpot",
		Vector3.new(9, 0.35, 9),
		workshopPlotCFrame(plotBase, Vector3.new(0, 0, 0)),
		Color3.fromRGB(160, 120, 220),
		plotModel
	)
	buildSpot.Material = Enum.Material.SmoothPlastic
	buildSpot.Transparency = 0.12
	buildSpot.CanCollide = false

	addWorkshopBuildPrompt(buildSpot)
	createWorkshopBuildSign(plotModel, plotBase)

	print(string.format("[PlotService] Created workshop build spot for %s.", player.Name))
	return buildSpot
end

local function createWorkshopBuilding(player, plotModel, plotBase)
	removeWorkshopBuildSpot(plotModel)

	local existingWorkshop = plotModel:FindFirstChild("WorkshopBuilding")

	if existingWorkshop then
		return existingWorkshop
	end

	local workshop = Instance.new("Model")
	workshop.Name = "WorkshopBuilding"
	workshop.Parent = plotModel

	createPart(
		"WorkshopBase",
		Vector3.new(10, 0.5, 9),
		workshopPlotCFrame(plotBase, Vector3.new(0, 0.05, 0)),
		Color3.fromRGB(95, 90, 100),
		workshop
	)

	createPart(
		"WorkshopBody",
		Vector3.new(8, 5, 7),
		workshopPlotCFrame(plotBase, Vector3.new(0, 2.85, 0)),
		Color3.fromRGB(115, 95, 135),
		workshop
	)

	createPart(
		"WorkshopRoof",
		Vector3.new(9.5, 1.4, 8.5),
		workshopPlotCFrame(plotBase, Vector3.new(0, 5.95, 0)),
		Color3.fromRGB(65, 55, 85),
		workshop
	)

	createPart(
		"WorkshopDoor",
		Vector3.new(2.2, 3, 0.3),
		workshopPlotCFrame(plotBase, Vector3.new(-2.3, 1.95, -3.65)),
		Color3.fromRGB(55, 38, 35),
		workshop
	)

	createPart(
		"WorkshopWindow",
		Vector3.new(2.2, 1.6, 0.3),
		workshopPlotCFrame(plotBase, Vector3.new(2.2, 3.2, -3.65)),
		Color3.fromRGB(180, 225, 240),
		workshop
	)

	createPart(
		"Workbench",
		Vector3.new(3, 1.2, 1.6),
		workshopPlotCFrame(plotBase, Vector3.new(3.4, 1.25, 1.7)),
		Color3.fromRGB(145, 90, 50),
		workshop
	)

	createPart(
		"WorkshopAnvil",
		Vector3.new(1.8, 0.8, 1),
		workshopPlotCFrame(plotBase, Vector3.new(-3.2, 1.05, 1.8)),
		Color3.fromRGB(70, 75, 80),
		workshop
	)

	print(string.format("[PlotService] %s built workshop visual.", player.Name))
	return workshop
end

local function removeForgeBuildSite(plotModel)
	local buildSite = plotModel:FindFirstChild("ForgeBuildSite")

	if buildSite then
		buildSite:Destroy()
	end

	local buildSign = plotModel:FindFirstChild("ForgeBuildSign")

	if buildSign then
		buildSign:Destroy()
	end
end

local function forgePlotCFrame(plotBase, localOffset)
	local groundY = (plotBase.Size.Y / 2) + localOffset.Y
	return plotBase.CFrame * CFrame.new(13 + localOffset.X, groundY, -11 + localOffset.Z)
end

local function createForgeBuildSign(plotModel, plotBase)
	local existingSign = plotModel:FindFirstChild("ForgeBuildSign")

	if existingSign then
		return existingSign
	end

	local signModel = Instance.new("Model")
	signModel.Name = "ForgeBuildSign"
	signModel.Parent = plotModel

	local signCFrame = forgePlotCFrame(plotBase, Vector3.new(0, 1.4, -5.4))

	createPart(
		"ForgeBuildSignLeftPost",
		Vector3.new(0.35, 2.4, 0.35),
		signCFrame * CFrame.new(-2.4, 0, 0),
		Color3.fromRGB(90, 60, 35),
		signModel
	)

	createPart(
		"ForgeBuildSignRightPost",
		Vector3.new(0.35, 2.4, 0.35),
		signCFrame * CFrame.new(2.4, 0, 0),
		Color3.fromRGB(90, 60, 35),
		signModel
	)

	local board = createPart(
		"ForgeBuildSignBoard",
		Vector3.new(5.8, 1.8, 0.35),
		signCFrame * CFrame.new(0, 1.05, 0),
		Color3.fromRGB(210, 185, 120),
		signModel
	)

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "ForgeBuildSignSurface"
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 50
	surfaceGui.Parent = board

	local label = Instance.new("TextLabel")
	label.Name = "ForgeBuildSignLabel"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "Место для кузницы"
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.TextColor3 = Color3.fromRGB(55, 35, 20)
	label.Parent = surfaceGui

	return signModel
end

local function createForgeBuildSite(player, plotModel, plotBase)
	local profile = PlayerDataService.GetProfile(player)

	if profile and PlayerDataService.GetBuildingLevel(profile, "Forge") >= 1 then
		removeForgeBuildSite(plotModel)
		return nil
	end

	if plotModel:FindFirstChild("Forge") then
		removeForgeBuildSite(plotModel)
		return nil
	end

	local existingBuildSite = plotModel:FindFirstChild("ForgeBuildSite")

	if existingBuildSite then
		addForgeBuildPrompt(existingBuildSite)
		createForgeBuildSign(plotModel, plotBase)
		return existingBuildSite
	end

	local buildSite = createPart(
		"ForgeBuildSite",
		Vector3.new(9, 0.35, 8),
		forgePlotCFrame(plotBase, Vector3.new(0, 0.35 / 2, 0)),
		Color3.fromRGB(195, 150, 85),
		plotModel
	)
	buildSite.Material = Enum.Material.SmoothPlastic
	buildSite.Transparency = 0.18
	buildSite.CanCollide = false

	addForgeBuildPrompt(buildSite)
	createForgeBuildSign(plotModel, plotBase)

	print("[Forge] Created forge build site")
	return buildSite
end

local function createForge(player, plotModel, plotBase)
	removeForgeBuildSite(plotModel)

	local existingForge = plotModel:FindFirstChild("Forge")

	if existingForge and existingForge:FindFirstChild("ForgeBase") then
		addForgeSmeltPrompt(existingForge)
		addForgePartsPrompt(existingForge)
		return existingForge
	end

	if existingForge then
		existingForge:Destroy()
	end

	plotBase = plotBase or getPlotBase(plotModel)

	if not plotBase then
		print("[PlotService] Error: Plot base not found for forge generation!")
		return nil
	end

	local forge = Instance.new("Model")
	forge.Name = "Forge"
	forge.Parent = plotModel

	local forgeCenterCFrame = forgePlotCFrame(plotBase, Vector3.new(0, 0.75, 0))

	local base = createPart("ForgeBase", Vector3.new(10, 1.5, 8), forgeCenterCFrame, Color3.fromRGB(85, 80, 75), forge)
	base.Material = Enum.Material.Slate
	base.CFrame = forgeCenterCFrame

	local hearth = createPart("ForgeHearth", Vector3.new(5.5, 0.2, 4.5), forgeCenterCFrame * CFrame.new(-1.5, (1.5 / 2) + (0.2 / 2), 0), Color3.fromRGB(55, 50, 48), forge)
	hearth.Material = Enum.Material.Slate
	hearth.CFrame = forgeCenterCFrame * CFrame.new(-1.5, (1.5 / 2) + (0.2 / 2), 0)

	local firebox = createPart("ForgeFirebox", Vector3.new(5.1, 0.2, 4.1), forgeCenterCFrame * CFrame.new(-1.5, (1.5 / 2) + 0.2 + (0.2 / 2), 0), Color3.fromRGB(210, 95, 40), forge)
	firebox.Material = Enum.Material.Neon
	firebox.CFrame = forgeCenterCFrame * CFrame.new(-1.5, (1.5 / 2) + 0.2 + (0.2 / 2), 0)

	local backWall = createPart("ForgeBackWall", Vector3.new(5.5, 5, 1), forgeCenterCFrame * CFrame.new(-1.5, (1.5 / 2) + (5 / 2), 1.75), Color3.fromRGB(55, 50, 48), forge)
	backWall.Material = Enum.Material.Slate
	backWall.CFrame = forgeCenterCFrame * CFrame.new(-1.5, (1.5 / 2) + (5 / 2), 1.75)

	local hood = createPart("ForgeHood", Vector3.new(5.5, 1.5, 1), forgeCenterCFrame * CFrame.new(-1.5, (1.5 / 2) + 5 - (1.5 / 2), -1.75), Color3.fromRGB(55, 50, 48), forge)
	hood.Material = Enum.Material.Slate
	hood.CFrame = forgeCenterCFrame * CFrame.new(-1.5, (1.5 / 2) + 5 - (1.5 / 2), -1.75)

	local chimney = createPart("ForgeChimney", Vector3.new(2, 6, 2), forgeCenterCFrame * CFrame.new(-1.5, (1.5 / 2) + 5 + (6 / 2), 0), Color3.fromRGB(45, 45, 45), forge)
	chimney.Material = Enum.Material.Brick
	chimney.CFrame = forgeCenterCFrame * CFrame.new(-1.5, (1.5 / 2) + 5 + (6 / 2), 0)

	local anvil = createPart("ForgeAnvil", Vector3.new(2.5, 1, 1.5), forgeCenterCFrame * CFrame.new(3.2, -(1.5 / 2) + (1 / 2), 1.7), Color3.fromRGB(70, 75, 80), forge)
	anvil.Material = Enum.Material.Metal
	anvil.CFrame = forgeCenterCFrame * CFrame.new(3.2, -(1.5 / 2) + (1 / 2), 1.7)

	local sign = createPart("ForgeSignBoard", Vector3.new(5, 1.4, 0.35), forgeCenterCFrame * CFrame.new(0, 2.45, -4.2), Color3.fromRGB(230, 195, 115), forge)
	sign.CFrame = forgeCenterCFrame * CFrame.new(0, 2.45, -4.2)

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "ForgeSignSurface"
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Name = "ForgeSignLabel"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "Кузница"
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.TextColor3 = Color3.fromRGB(55, 35, 20)
	label.Parent = surfaceGui

	addForgeSmeltPrompt(forge)
	addForgePartsPrompt(forge)
	return forge
end

local function updateStorageVisual(player, profile)
	local plotModel = getPlot(player)

	if not plotModel then
		return false
	end

	local plotBase = getPlotBase(plotModel)

	if not plotBase then
		return false
	end

	local storageLevel = PlayerDataService.GetBuildingLevel(profile, "Storage")

	if storageLevel >= 1 then
		createStorageBuilding(plotModel, plotBase, storageLevel)
	else
		createStorageBuildSpot(plotModel, plotBase)
	end

	return true
end

local function updateWorkshopVisual(player, profile)
	local plotModel = getPlot(player)

	if not plotModel then
		return false
	end

	local plotBase = getPlotBase(plotModel)

	if not plotBase then
		return false
	end

	local workshopLevel = PlayerDataService.GetBuildingLevel(profile, "Workshop")
	local storageLevel = PlayerDataService.GetBuildingLevel(profile, "Storage")

	if workshopLevel >= 1 then
		print(string.format("[PlotService] Workshop already built for %s. Restoring visual.", player.Name))
		local workshop = createWorkshopBuilding(player, plotModel, plotBase)

		if (profile.ToolKitLevel or 0) < 2 then
			addToolKitCraftPrompt(player, workshop)
		else
			removeToolKitCraftPrompt(workshop)
		end
	elseif storageLevel >= 1 then
		createWorkshopBuildSpot(player, plotModel, plotBase)
	else
		removeWorkshopBuildSpot(plotModel)
	end

	return true
end

local function updateForgeVisual(player, profile)
	local plotModel = getPlot(player)

	if not plotModel then
		return false
	end

	local plotBase = getPlotBase(plotModel)

	if not plotBase then
		return false
	end

	if PlayerDataService.GetBuildingLevel(profile, "Forge") >= 1 then
		createForge(player, plotModel, plotBase)
	else
		removeForgeBuildSite(plotModel)

		local existingForge = plotModel:FindFirstChild("Forge")

		if existingForge then
			existingForge:Destroy()
		end

		createForgeBuildSite(player, plotModel, plotBase)
	end

	return true
end

local function rebuildHouse(plotModel, plotBase, houseLevel)
	local oldHouse = plotModel:FindFirstChild("House")

	if oldHouse then
		oldHouse:Destroy()
	end

	local house = Instance.new("Model")
	house.Name = "House"
	house.Parent = plotModel

	if houseLevel <= 1 then
		createLevelOneHouse(house, plotBase)
	elseif houseLevel == 2 then
		createLevelTwoHouse(house, plotBase)
	else
		createLevelThreeHouse(house, plotBase)
	end

	return house
end

local function updateHouseVisual(player, houseLevel)
	local plotModel = getPlot(player)

	if not plotModel then
		return false
	end

	local plotBase = getPlotBase(plotModel)

	if not plotBase then
		return false
	end

	rebuildHouse(plotModel, plotBase, houseLevel)
	return true
end

function PlotService.UnlockPlot(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[PlotService] Profile for %s was not found. Plot was not unlocked.", player.Name))
		return false
	end

	profile.PlotUnlocked = true
	PlayerDataService.MarkDirty(player)
	print(string.format("[PlotService] %s unlocked a plot.", player.Name))

	if PlayerDataService.SendProfileUpdate then
		PlayerDataService.SendProfileUpdate(player)
	end

	return true
end

local function restorePlotBuildingVisuals(player, plotModel, profile)
	local plotBase = getPlotBase(plotModel)

	if not plotBase then
		warn(string.format("[PlotService] Plot base not found while restoring buildings for %s.", player.Name))
		return
	end

	local houseLevel = PlayerDataService.GetBuildingLevel(profile, "House")
	local storageLevel = PlayerDataService.GetBuildingLevel(profile, "Storage")
	local workshopLevel = PlayerDataService.GetBuildingLevel(profile, "Workshop")
	local forgeLevel = PlayerDataService.GetBuildingLevel(profile, "Forge")

	rebuildHouse(plotModel, plotBase, houseLevel)

	if storageLevel >= 1 then
		createStorageBuilding(plotModel, plotBase, storageLevel)
	else
		createStorageBuildSpot(plotModel, plotBase)
	end

	if workshopLevel >= 1 then
		print(string.format("[PlotService] Workshop already built for %s. Restoring visual.", player.Name))
		local workshop = createWorkshopBuilding(player, plotModel, plotBase)

		if (profile.ToolKitLevel or 0) < 2 then
			addToolKitCraftPrompt(player, workshop)
		else
			removeToolKitCraftPrompt(workshop)
		end
	elseif storageLevel >= 1 then
		createWorkshopBuildSpot(player, plotModel, plotBase)
	else
		removeWorkshopBuildSpot(plotModel)
	end

	if forgeLevel >= 1 then
		createForge(player, plotModel, plotBase)
		print(string.format("[PlotService] %s built forge visual.", player.Name))
	else
		removeForgeBuildSite(plotModel)

		local staleForge = plotModel:FindFirstChild("Forge")

		if staleForge then
			staleForge:Destroy()
		end

		createForgeBuildSite(player, plotModel, plotBase)
	end
end

function PlotService.CreateTestPlot(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[PlotService] Profile for %s was not found. Test plot was not created.", player.Name))
		return nil
	end

	local plotPosition, gridX, gridZ = getPlotGridPosition(player)
	local playerPlots = getPlayerPlotsContainer(true)
	local existingPlot = getPlot(player)

	if existingPlot then
		print(string.format("[PlotService] Reusing existing plot for %s.", player.Name))
		existingPlot.Parent = playerPlots
		setPlotOwnershipAttributes(existingPlot, player, gridX, gridZ)

		local existingBase = getPlotBase(existingPlot)

		if existingBase then
			existingBase.CFrame = CFrame.new(plotPosition)
			setPlotBaseAttributes(existingBase, player, gridX, gridZ)
			rebuildPlotSigns(player, existingPlot, existingBase)
		end

		restorePlotBuildingVisuals(player, existingPlot, profile)
		return existingPlot
	end

	local plotModel = Instance.new("Model")
	plotModel.Name = getPlotName(player)
	setPlotOwnershipAttributes(plotModel, player, gridX, gridZ)
	plotModel.Parent = playerPlots

	local base = createPart(
		"PlotBase",
		PLOT_SIZE,
		CFrame.new(plotPosition),
		Color3.fromRGB(80, 155, 85),
		plotModel
	)
	base.Material = Enum.Material.Grass
	setPlotBaseAttributes(base, player, gridX, gridZ)
	plotModel.PrimaryPart = base

	createPlayerSign(player, plotModel, base)
	createPlotAreaSign(plotModel, base)
	restorePlotBuildingVisuals(player, plotModel, profile)

	print(string.format("[PlotService] Created plot for %s at %s.", player.Name, tostring(plotPosition)))
	return plotModel
end

function PlotService.CanBuildStorage(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		return false, "профиль не найден"
	end

	if not profile.PlotUnlocked then
		return false, "участок ещё не открыт"
	end

	if PlayerDataService.GetBuildingLevel(profile, "Storage") >= 1 then
		return false, "склад уже построен"
	end

	local missingResources = {}

	if profile.Gold < STORAGE_BUILD_COST.Gold then
		table.insert(missingResources, string.format("Gold %d/%d", profile.Gold, STORAGE_BUILD_COST.Gold))
	end

	if profile.Wood < STORAGE_BUILD_COST.Wood then
		table.insert(missingResources, string.format("Wood %d/%d", profile.Wood, STORAGE_BUILD_COST.Wood))
	end

	if profile.Stone < STORAGE_BUILD_COST.Stone then
		table.insert(missingResources, string.format("Stone %d/%d", profile.Stone, STORAGE_BUILD_COST.Stone))
	end

	if #missingResources > 0 then
		return false, "не хватает ресурсов: " .. table.concat(missingResources, ", "), STORAGE_BUILD_COST
	end

	return true, "можно построить", STORAGE_BUILD_COST
end

function PlotService.TryBuildStorage(player)
	local canBuild, reason, cost = PlotService.CanBuildStorage(player)

	if not canBuild then
		if reason == "склад уже построен" then
			print(string.format("[PlotService] %s tried to build storage, but storage already exists.", player.Name))
		elseif string.find(reason, "не хватает ресурсов", 1, true) then
			warn(string.format("[PlotService] %s cannot build storage: %s.", player.Name, reason))
			sendPlayerMessage(player, "Недостаточно ресурсов для строительства склада")
		else
			warn(string.format("[PlotService] %s cannot build storage: %s.", player.Name, reason))
			sendPlayerMessage(player, "Склад нельзя построить")
		end

		return false
	end

	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		sendPlayerMessage(player, "Склад нельзя построить")
		return false
	end

	if not CurrencyService.SpendResources(player, cost) then
		sendPlayerMessage(player, "Не удалось списать ресурсы для строительства склада")
		return false
	end

	PlayerDataService.SetBuildingLevel(profile, "Storage", math.max(PlayerDataService.GetBuildingLevel(profile, "Storage"), 1))
	PlayerDataService.MarkDirty(player)
	updateStorageVisual(player, profile)
	updateWorkshopVisual(player, profile)

	if PlayerDataService.SendProfileUpdate then
		PlayerDataService.SendProfileUpdate(player)
	end

	if profile.CurrentQuestId == STORAGE_QUEST_ID and not profile.CompletedQuests[STORAGE_QUEST_ID] then
		QuestService.AddQuestProgress(player, STORAGE_QUEST_ID, STORAGE_OBJECTIVE_ID, 1)
		QuestService.CompleteQuest(player, STORAGE_QUEST_ID)
	end

	if PlayerDataService.SaveProfile then
		PlayerDataService.SaveProfile(player)
	end

	sendPlayerMessage(player, "Склад построен")

	print(string.format(
		"[PlotService] %s built storage. Cost: %s.",
		player.Name,
		formatCost(STORAGE_BUILD_COST)
	))

	return true
end

function PlotService.CanUpgradeStorage(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		return false, "профиль не найден"
	end

	local storageLevel = PlayerDataService.GetBuildingLevel(profile, "Storage")

	if storageLevel < 1 then
		return false, "склад не построен"
	end

	if storageLevel >= MAX_STORAGE_LEVEL then
		return false, "склад уже улучшен до максимума"
	end

	if not CurrencyService.CanAfford(player, STORAGE_LEVEL_2_COST) then
		return false, "не хватает ресурсов", STORAGE_LEVEL_2_COST, CurrencyService.FormatMissingResources(player, STORAGE_LEVEL_2_COST)
	end

	return true, "можно улучшить", STORAGE_LEVEL_2_COST, nil, storageLevel + 1
end

function PlotService.TryUpgradeStorage(player)
	print(string.format("[PlotService] %s tried to upgrade storage.", player.Name))

	local canUpgrade, reason, cost, missingResourcesMessage, nextStorageLevel = PlotService.CanUpgradeStorage(player)

	if not canUpgrade then
		if reason == "склад не построен" then
			warn(string.format("[PlotService] %s cannot upgrade storage: storage is not built.", player.Name))
			sendPlayerMessage(player, "Сначала постройте склад")
		elseif reason == "склад уже улучшен до максимума" then
			print(string.format("[PlotService] %s tried to upgrade storage, but storage is already max level.", player.Name))
			sendPlayerMessage(player, "Склад уже улучшен")
		elseif reason == "не хватает ресурсов" then
			warn(string.format("[PlotService] %s cannot upgrade storage: not enough resources.", player.Name))
			sendPlayerMessage(player, string.format(
				"Недостаточно ресурсов для улучшения склада. %s. %s",
				formatCost(cost),
				missingResourcesMessage or CurrencyService.FormatMissingResources(player, cost)
			))
		else
			warn(string.format("[PlotService] %s cannot upgrade storage: %s.", player.Name, reason))
			sendPlayerMessage(player, "Склад нельзя улучшить")
		end

		return false
	end

	local resourcesSpent, spendMissingResourcesMessage = CurrencyService.SpendResources(player, cost)

	if not resourcesSpent then
		sendPlayerMessage(player, string.format(
			"Недостаточно ресурсов для улучшения склада. %s",
			spendMissingResourcesMessage or CurrencyService.FormatMissingResources(player, cost)
		))
		return false
	end

	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		return false
	end

	PlayerDataService.SetBuildingLevel(profile, "Storage", nextStorageLevel)
	PlayerDataService.MarkDirty(player)
	updateStorageVisual(player, profile)

	if PlayerDataService.SendProfileUpdate then
		PlayerDataService.SendProfileUpdate(player)
	end

	if PlayerDataService.SaveProfile then
		PlayerDataService.SaveProfile(player)
	end

	local upgradedStorageLevel = PlayerDataService.GetBuildingLevel(profile, "Storage")
	sendPlayerMessage(player, string.format("Склад улучшен до уровня %d", upgradedStorageLevel))
	hideActionPreview(player)
	print(string.format("[PlotService] %s upgraded storage to level %d.", player.Name, upgradedStorageLevel))

	return true
end

function PlotService.CanBuildForge(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		return false, "профиль не найден"
	end

	if not profile.PlotUnlocked then
		return false, "участок еще не открыт"
	end

	if PlayerDataService.GetBuildingLevel(profile, "Forge") >= 1 then
		return false, "кузница уже построена"
	end

	if not CurrencyService.CanAfford(player, FORGE_BUILD_COST) then
		return false, "не хватает ресурсов", FORGE_BUILD_COST, CurrencyService.FormatMissingResources(player, FORGE_BUILD_COST)
	end

	return true, "можно построить", FORGE_BUILD_COST
end

function PlotService.TryBuildForge(player)
	print(string.format("[Forge] %s tried to build forge", player.Name))

	local canBuild, reason, cost, missingResourcesMessage = PlotService.CanBuildForge(player)

	if not canBuild then
		if reason == "кузница уже построена" then
			print(string.format("[Forge] %s tried to build forge, but forge already exists", player.Name))
		elseif reason == "не хватает ресурсов" then
			warn(string.format("[Forge] %s cannot build forge: not enough resources", player.Name))
			sendPlayerMessage(player, string.format(
				"Недостаточно ресурсов для строительства кузницы. %s. %s",
				formatCost(cost),
				missingResourcesMessage or CurrencyService.FormatMissingResources(player, cost)
			))
		else
			warn(string.format("[Forge] %s cannot build forge: %s", player.Name, reason))
			sendPlayerMessage(player, "Кузницу нельзя построить")
		end

		return false
	end

	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[Forge] Profile for %s was not found. Forge was not built.", player.Name))
		return false
	end

	local resourcesSpent, spendMissingResourcesMessage = CurrencyService.SpendResources(player, cost)

	if not resourcesSpent then
		warn(string.format("[Forge] %s cannot build forge: not enough resources", player.Name))
		sendPlayerMessage(player, string.format(
			"Недостаточно ресурсов для строительства кузницы. %s. %s",
			formatCost(cost),
			spendMissingResourcesMessage or CurrencyService.FormatMissingResources(player, cost)
		))
		return false
	end

	PlayerDataService.SetBuildingLevel(profile, "Forge", 1)
	PlayerDataService.MarkDirty(player)
	updateForgeVisual(player, profile)

	if PlayerDataService.SendProfileUpdate then
		PlayerDataService.SendProfileUpdate(player)
	end

	if PlayerDataService.SaveProfile then
		PlayerDataService.SaveProfile(player, { Force = true })
	end

	sendPlayerMessage(player, "Кузница построена")
	hideActionPreview(player)
	print(string.format("[Forge] %s built forge", player.Name))

	return true
end

function PlotService.CanSmeltMetalIngot(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		return false, "profile not found"
	end

	if PlayerDataService.GetBuildingLevel(profile, "Forge") < 1 then
		return false, "forge not built"
	end

	if not CurrencyService.CanAfford(player, FORGE_SMELT_COST) then
		return false, "not enough resources", FORGE_SMELT_COST, CurrencyService.FormatMissingResources(player, FORGE_SMELT_COST)
	end

	return true, "can smelt", FORGE_SMELT_COST
end

function PlotService.TrySmeltMetalIngot(player)
	print(string.format("[Forge] %s tried to smelt MetalIngot", player.Name))

	local canSmelt, reason, cost, missingResourcesMessage = PlotService.CanSmeltMetalIngot(player)

	if not canSmelt then
		if reason == "forge not built" then
			warn(string.format("[Forge] %s cannot smelt MetalIngot: forge is not built", player.Name))
			sendPlayerMessage(player, "Кузница не построена")
		elseif reason == "not enough resources" then
			warn(string.format("[Forge] %s cannot smelt MetalIngot: not enough resources", player.Name))
			sendPlayerMessage(player, string.format(
				"Недостаточно ресурсов для плавки. %s. %s",
				formatCost(cost),
				missingResourcesMessage or CurrencyService.FormatMissingResources(player, cost)
			))
		else
			warn(string.format("[Forge] %s cannot smelt MetalIngot: %s", player.Name, reason))
			sendPlayerMessage(player, "Слиток нельзя выплавить")
		end

		return false
	end

	local resourcesSpent, spendMissingResourcesMessage = CurrencyService.SpendResources(player, cost)

	if not resourcesSpent then
		sendPlayerMessage(player, string.format(
			"Недостаточно ресурсов для плавки. %s",
			spendMissingResourcesMessage or CurrencyService.FormatMissingResources(player, cost)
		))
		return false
	end

	CurrencyService.AddMetalIngot(player, 1)

	if PlayerDataService.SaveProfile then
		PlayerDataService.SaveProfile(player)
	end

	sendPlayerMessage(player, "Слиток выплавлен")
	hideActionPreview(player)
	print(string.format("[Forge] %s smelted MetalIngot", player.Name))

	return true
end

function PlotService.CanMakeMetalParts(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		return false, "profile not found"
	end

	if PlayerDataService.GetBuildingLevel(profile, "Forge") < 1 then
		return false, "forge not built"
	end

	if not CurrencyService.CanAfford(player, FORGE_PARTS_COST) then
		return false, "not enough resources", FORGE_PARTS_COST, CurrencyService.FormatMissingResources(player, FORGE_PARTS_COST)
	end

	return true, "can make parts", FORGE_PARTS_COST
end

function PlotService.TryMakeMetalParts(player)
	print(string.format("[Forge] %s tried to make MetalParts", player.Name))

	local canMake, reason, cost, missingResourcesMessage = PlotService.CanMakeMetalParts(player)

	if not canMake then
		if reason == "forge not built" then
			warn(string.format("[Forge] %s cannot make MetalParts: forge is not built", player.Name))
			sendPlayerMessage(player, "Кузница не построена")
		elseif reason == "not enough resources" then
			warn(string.format("[Forge] %s cannot make MetalParts: not enough resources", player.Name))
			sendPlayerMessage(player, string.format(
				"Недостаточно ресурсов для деталей. %s. %s",
				formatCost(cost),
				missingResourcesMessage or CurrencyService.FormatMissingResources(player, cost)
			))
		else
			warn(string.format("[Forge] %s cannot make MetalParts: %s", player.Name, reason))
			sendPlayerMessage(player, "Детали нельзя сделать")
		end

		return false
	end

	local resourcesSpent, spendMissingResourcesMessage = CurrencyService.SpendResources(player, cost)

	if not resourcesSpent then
		sendPlayerMessage(player, string.format(
			"Недостаточно ресурсов для деталей. %s",
			spendMissingResourcesMessage or CurrencyService.FormatMissingResources(player, cost)
		))
		return false
	end

	CurrencyService.AddMetalParts(player, 1)

	if PlayerDataService.SaveProfile then
		PlayerDataService.SaveProfile(player)
	end

	sendPlayerMessage(player, "Детали сделаны")
	hideActionPreview(player)
	print(string.format("[Forge] %s made MetalParts", player.Name))

	return true
end

function PlotService.CanBuildWorkshop(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		return false, "профиль не найден"
	end

	if not profile.PlotUnlocked then
		return false, "участок ещё не открыт"
	end

	if PlayerDataService.GetBuildingLevel(profile, "Storage") < 1 then
		return false, "склад не построен"
	end

	if PlayerDataService.GetBuildingLevel(profile, "Workshop") >= 1 then
		return false, "мастерская уже построена"
	end

	local missingResources = {}

	if profile.Gold < WORKSHOP_BUILD_COST.Gold then
		table.insert(missingResources, string.format("Gold %d/%d", profile.Gold, WORKSHOP_BUILD_COST.Gold))
	end

	if profile.Wood < WORKSHOP_BUILD_COST.Wood then
		table.insert(missingResources, string.format("Wood %d/%d", profile.Wood, WORKSHOP_BUILD_COST.Wood))
	end

	if profile.Stone < WORKSHOP_BUILD_COST.Stone then
		table.insert(missingResources, string.format("Stone %d/%d", profile.Stone, WORKSHOP_BUILD_COST.Stone))
	end

	if #missingResources > 0 then
		return false, "не хватает ресурсов: " .. table.concat(missingResources, ", "), WORKSHOP_BUILD_COST
	end

	return true, "можно построить", WORKSHOP_BUILD_COST
end

function PlotService.TryBuildWorkshop(player)
	print(string.format("[PlotService] %s tried to build workshop.", player.Name))

	local canBuild, reason, cost = PlotService.CanBuildWorkshop(player)

	if not canBuild then
		if reason == "склад не построен" then
			warn(string.format("[PlotService] %s cannot build workshop: storage is not built.", player.Name))
			sendPlayerMessage(player, "Сначала постройте склад")
		elseif reason == "мастерская уже построена" then
			print(string.format("[PlotService] %s tried to build workshop, but workshop already exists.", player.Name))
		elseif string.find(reason, "не хватает ресурсов", 1, true) then
			warn(string.format("[PlotService] %s cannot build workshop: not enough resources.", player.Name))
			sendPlayerMessage(player, "Недостаточно ресурсов для строительства мастерской")
		else
			warn(string.format("[PlotService] %s cannot build workshop: %s.", player.Name, reason))
			sendPlayerMessage(player, "Мастерскую нельзя построить")
		end

		return false
	end

	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[PlotService] Profile for %s was not found. Workshop was not built.", player.Name))
		return false
	end

	if not CurrencyService.SpendResources(player, cost) then
		sendPlayerMessage(player, "Не удалось списать ресурсы для строительства мастерской")
		return false
	end

	PlayerDataService.SetBuildingLevel(profile, "Workshop", 1)
	PlayerDataService.MarkDirty(player)
	updateWorkshopVisual(player, profile)

	if PlayerDataService.SendProfileUpdate then
		PlayerDataService.SendProfileUpdate(player)
	end

	if PlayerDataService.SaveProfile then
		PlayerDataService.SaveProfile(player)
	end

	sendPlayerMessage(player, "Мастерская построена")
	print(string.format("[PlotService] %s built workshop.", player.Name))

	return true
end

function PlotService.CanCraftToolKit(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		return false, "профиль не найден"
	end

	if PlayerDataService.GetBuildingLevel(profile, "Workshop") < 1 then
		return false, "мастерская не построена"
	end

	local currentToolKitLevel = profile.ToolKitLevel or 0
	local nextToolKitLevel = currentToolKitLevel + 1
	local cost = nil

	if currentToolKitLevel == 0 then
		cost = TOOL_KIT_I_COST
	elseif currentToolKitLevel == 1 then
		cost = TOOL_KIT_II_COST
	else
		return false, "набор инструментов уже изготовлен"
	end

	if not CurrencyService.CanAfford(player, cost) then
		local actionText = if nextToolKitLevel == 2 then "улучшения инструментов II" else "создания инструментов I"
		local missingResourcesMessage = CurrencyService.FormatMissingResources(player, cost)
		local message = string.format("Недостаточно ресурсов для %s. %s", actionText, missingResourcesMessage)

		return false, "не хватает ресурсов", cost, message
	end

	return true, "можно изготовить", cost, nil, nextToolKitLevel
end

function PlotService.TryCraftToolKit(player)
	print(string.format("[PlotService] %s tried to craft tool kit.", player.Name))

	local canCraft, reason, cost, playerMessage, nextToolKitLevel = PlotService.CanCraftToolKit(player)

	if not canCraft then
		if reason == "профиль не найден" then
			warn(string.format("[PlotService] Profile for %s was not found. Tool kit was not crafted.", player.Name))
		elseif reason == "мастерская не построена" then
			warn(string.format("[PlotService] %s cannot craft tool kit: workshop is not built.", player.Name))
			sendPlayerMessage(player, "Сначала постройте мастерскую")
		elseif reason == "набор инструментов уже изготовлен" then
			print(string.format("[PlotService] %s already has tool kit.", player.Name))
			sendPlayerMessage(player, "Набор инструментов уже изготовлен")
		elseif string.find(reason, "не хватает ресурсов", 1, true) then
			warn(string.format("[PlotService] %s cannot craft tool kit: missing %s.", player.Name, string.gsub(reason, "не хватает ресурсов: ", "")))
			sendPlayerMessage(player, playerMessage or "Недостаточно ресурсов для набора инструментов")
		else
			warn(string.format("[PlotService] %s cannot craft tool kit: %s.", player.Name, reason))
			sendPlayerMessage(player, "Набор инструментов нельзя изготовить")
		end

		return false
	end

	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[PlotService] Profile for %s was not found. Tool kit was not crafted.", player.Name))
		return false
	end

	local resourcesSpent, missingResourcesMessage = CurrencyService.SpendResources(player, cost)

	if not resourcesSpent then
		local actionText = if nextToolKitLevel == 2 then "улучшения инструментов II" else "создания инструментов I"
		local message = if missingResourcesMessage
			then string.format("Недостаточно ресурсов для %s. %s", actionText, missingResourcesMessage)
			else "Не удалось списать ресурсы для набора инструментов"

		sendPlayerMessage(player, message)
		return false
	end

	profile.ToolKitLevel = nextToolKitLevel
	PlayerDataService.MarkDirty(player)
	updateWorkshopVisual(player, profile)

	if PlayerDataService.SendProfileUpdate then
		PlayerDataService.SendProfileUpdate(player)
	end

	if PlayerDataService.SaveProfile then
		PlayerDataService.SaveProfile(player)
	end

	if nextToolKitLevel == 2 then
		sendPlayerMessage(player, "Набор инструментов II создан")
	else
		sendPlayerMessage(player, "Набор инструментов I изготовлен")
	end

	hideActionPreview(player)
	print(string.format("[PlotService] %s crafted ToolKitLevel %d.", player.Name, nextToolKitLevel))

	return true
end

function PlotService.CanUpgradeHouse(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		return false, "профиль не найден"
	end

	if not profile.PlotUnlocked then
		return false, "участок ещё не открыт"
	end

	local currentLevel = PlayerDataService.GetBuildingLevel(profile, "House")

	if currentLevel >= MAX_HOUSE_LEVEL then
		return false, "дом уже улучшен до максимума"
	end

	local cost = getUpgradeCost(currentLevel)

	if not cost then
		return false, "стоимость улучшения не найдена"
	end

	if not CurrencyService.CanAfford(player, cost) then
		local missingResourcesMessage = CurrencyService.FormatMissingResources(player, cost)
		return false, "не хватает ресурсов", cost, missingResourcesMessage
	end

	return true, "можно улучшить", cost
end

function PlotService.TryUpgradeHouse(player)
	local canUpgrade, reason, cost, missingResourcesMessage = PlotService.CanUpgradeHouse(player)

	if not canUpgrade then
		local playerMessage = "Дом нельзя улучшить"

		if reason == "дом уже улучшен до максимума" then
			playerMessage = "Дом уже улучшен до максимума"
			print(string.format("[PlotService] %s tried to upgrade house, but %s.", player.Name, reason))
		elseif string.find(reason, "не хватает ресурсов", 1, true) then
			playerMessage = string.format(
				"Недостаточно ресурсов для улучшения дома. %s",
				missingResourcesMessage or CurrencyService.FormatMissingResources(player, cost)
			)
			warn(string.format("[PlotService] %s cannot upgrade house: %s.", player.Name, reason))
		else
			warn(string.format("[PlotService] %s cannot upgrade house: %s.", player.Name, reason))
		end

		sendPlayerMessage(player, playerMessage)
		return false
	end

	local profile = PlayerDataService.GetProfile(player)
	local oldLevel = PlayerDataService.GetBuildingLevel(profile, "House")

	local resourcesSpent, spendMissingResourcesMessage = CurrencyService.SpendResources(player, cost)

	if not resourcesSpent then
		local message = if spendMissingResourcesMessage
			then string.format("Недостаточно ресурсов для улучшения дома. %s", spendMissingResourcesMessage)
			else "Не удалось списать ресурсы для улучшения дома"

		sendPlayerMessage(player, message)
		return false
	end

	local newHouseLevel = oldLevel + 1
	PlayerDataService.SetBuildingLevel(profile, "House", newHouseLevel)
	PlayerDataService.MarkDirty(player)
	updateHouseVisual(player, newHouseLevel)

	if PlayerDataService.SendProfileUpdate then
		PlayerDataService.SendProfileUpdate(player)
	end

	if PlayerDataService.SaveProfile then
		PlayerDataService.SaveProfile(player)
	end

	sendPlayerMessage(player, string.format("Дом улучшен до уровня %d", newHouseLevel))
	hideActionPreview(player)

	print(string.format(
		"[PlotService] %s upgraded house from level %d to %d. Cost: %s.",
		player.Name,
		oldLevel,
		newHouseLevel,
		formatCost(cost)
	))

	return true
end

function PlotService.UpgradeHouse(player)
	-- Старый публичный метод оставлен как совместимый путь к платному улучшению.
	return PlotService.TryUpgradeHouse(player)
end

function PlotService.RemovePlot(player)
	local plotModel = getPlot(player)

	if not plotModel then
		print(string.format("[PlotService] No test plot to remove for %s.", player.Name))
		return false
	end

	plotModel:Destroy()
	print(string.format("[PlotService] Removed test plot for %s.", player.Name))

	return true
end

local function handleActionPreviewRequest(player, request)
	if type(request) ~= "table" then
		return
	end

	if request.action == "hide" then
		hideActionPreview(player)
		return
	end

	if request.action ~= "show" then
		return
	end

	local previewData = nil

	if request.promptName == "HouseUpgradePrompt" then
		previewData = buildHouseUpgradePreview(player)
	elseif request.promptName == "CraftToolKitPrompt" then
		previewData = buildToolKitPreview(player)
	elseif request.promptName == "BuildForgePrompt" then
		previewData = buildForgePreview(player)
	elseif request.promptName == "SmeltMetalIngotPrompt" then
		previewData = buildForgeSmeltPreview(player)
	elseif request.promptName == "MakeMetalPartsPrompt" then
		previewData = buildForgePartsPreview(player)
	elseif request.promptName == "StorageUpgradePrompt" then
		previewData = buildStorageUpgradePreview(player)
	else
		return
	end

	if previewData then
		sendActionPreview(player, previewData)
	else
		hideActionPreview(player)
	end
end

getRemoteEvent("ActionPreviewEvent").OnServerEvent:Connect(handleActionPreviewRequest)

return PlotService
