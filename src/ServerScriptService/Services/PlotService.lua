-- PlotService
-- Тестовый участок, визуальное развитие дома и платное улучшение.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local PlayerDataService = require(script.Parent.PlayerDataService)
local CurrencyService = require(script.Parent.CurrencyService)

local PlotService = {}

local PLOT_POSITION = Vector3.new(0, 0, 80)
local PLOT_SIZE = Vector3.new(40, 1, 40)
local MAX_HOUSE_LEVEL = 3
local STORAGE_POSITION = PLOT_POSITION + Vector3.new(-12, 0, 14)
local WORKSHOP_POSITION = PLOT_POSITION + Vector3.new(13, 0.8, 11)

local STORAGE_BUILD_COST = {
	Gold = 15,
	Wood = 10,
	Stone = 5,
}

local WORKSHOP_BUILD_COST = {
	Gold = 25,
	Wood = 15,
	Stone = 10,
}

local TOOL_KIT_I_COST = {
	Gold = 3,
	Wood = 10,
	Stone = 5,
	Metal = 5,
}

local TOOL_KIT_RESOURCE_LABELS = {
	Gold = "золото",
	Wood = "дерево",
	Stone = "камень",
	Metal = "металл",
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

local function getPlotName(player)
	return string.format("Plot_%d", player.UserId)
end

local function getPlot(player)
	return Workspace:FindFirstChild(getPlotName(player))
end

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

local function getUpgradeCost(houseLevel)
	return HOUSE_UPGRADE_COSTS[houseLevel]
end

local function formatCost(cost)
	if not cost then
		return "нет стоимости"
	end

	return string.format("%d Gold, %d Wood, %d Stone", cost.Gold, cost.Wood, cost.Stone)
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

local function removeToolKitCraftPrompt(workshop)
	local craftPrompt = workshop:FindFirstChild("CraftToolKitPrompt", true)

	if craftPrompt then
		craftPrompt:Destroy()
	end
end

local function addToolKitCraftPrompt(player, workshop)
	local promptPart = workshop:FindFirstChild("WorkshopBody")

	if not promptPart then
		warn(string.format("[PlotService] WorkshopBody was not found for %s. Tool kit prompt was not created.", player.Name))
		return nil
	end

	local existingPrompt = promptPart:FindFirstChild("CraftToolKitPrompt")

	if existingPrompt then
		return existingPrompt
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "CraftToolKitPrompt"
	prompt.ObjectText = "Мастерская"
	prompt.ActionText = "Изготовить инструменты"
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

local function createPlayerSign(player, plotModel)
	-- Простая табличка с именем игрока у входа на участок.
	local leftPost = createPart(
		"SignLeftPost",
		Vector3.new(0.4, 3, 0.4),
		PLOT_POSITION + Vector3.new(-16, 2, -17),
		Color3.fromRGB(95, 65, 40),
		plotModel
	)

	local rightPost = createPart(
		"SignRightPost",
		Vector3.new(0.4, 3, 0.4),
		PLOT_POSITION + Vector3.new(-10, 2, -17),
		Color3.fromRGB(95, 65, 40),
		plotModel
	)

	local sign = createPart(
		"PlayerNameSign",
		Vector3.new(8, 2, 0.4),
		PLOT_POSITION + Vector3.new(-13, 4, -17),
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

local function createPlotAreaSign(plotModel)
	-- Общая табличка, чтобы участок читался как личная земля игрока.
	createPart(
		"LandSignLeftPost",
		Vector3.new(0.4, 3, 0.4),
		PLOT_POSITION + Vector3.new(9, 2, -17),
		Color3.fromRGB(95, 65, 40),
		plotModel
	)

	createPart(
		"LandSignRightPost",
		Vector3.new(0.4, 3, 0.4),
		PLOT_POSITION + Vector3.new(17, 2, -17),
		Color3.fromRGB(95, 65, 40),
		plotModel
	)

	local sign = createPart(
		"PersonalLandSign",
		Vector3.new(10, 2, 0.4),
		PLOT_POSITION + Vector3.new(13, 4, -17),
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

local function createLevelOneHouse(house)
	-- Уровень 1: маленькая хижина.
	local body = createPart(
		"HouseBody",
		Vector3.new(10, 6, 10),
		PLOT_POSITION + Vector3.new(0, 3.5, 0),
		Color3.fromRGB(145, 95, 55),
		house
	)

	createPart(
		"HouseRoof",
		Vector3.new(12, 2, 12),
		PLOT_POSITION + Vector3.new(0, 7.5, 0),
		Color3.fromRGB(105, 55, 45),
		house
	)

	createPart(
		"HouseDoor",
		Vector3.new(2.5, 4, 0.3),
		PLOT_POSITION + Vector3.new(0, 2.5, -5.15),
		Color3.fromRGB(70, 45, 30),
		house
	)

	createPart(
		"HouseWindow",
		Vector3.new(2, 2, 0.3),
		PLOT_POSITION + Vector3.new(3.2, 4, -5.15),
		Color3.fromRGB(170, 220, 255),
		house
	)

	addHouseUpgradePrompt(body)
end

local function createLevelTwoHouse(house)
	-- Уровень 2: дом крупнее, светлее и с боковой пристройкой.
	local body = createPart(
		"HouseBody",
		Vector3.new(14, 8, 12),
		PLOT_POSITION + Vector3.new(0, 4.5, 0),
		Color3.fromRGB(190, 135, 75),
		house
	)

	createPart(
		"HouseExtension",
		Vector3.new(6, 5, 8),
		PLOT_POSITION + Vector3.new(10, 3, 1),
		Color3.fromRGB(175, 120, 65),
		house
	)

	createPart(
		"HouseRoof",
		Vector3.new(16, 2, 14),
		PLOT_POSITION + Vector3.new(0, 9.5, 0),
		Color3.fromRGB(135, 45, 45),
		house
	)

	createPart(
		"ExtensionRoof",
		Vector3.new(7, 1.5, 9),
		PLOT_POSITION + Vector3.new(10, 6.25, 1),
		Color3.fromRGB(135, 45, 45),
		house
	)

	createPart(
		"HouseDoor",
		Vector3.new(3, 4.5, 0.3),
		PLOT_POSITION + Vector3.new(-2, 2.75, -6.15),
		Color3.fromRGB(80, 45, 25),
		house
	)

	createPart(
		"HouseWindowLeft",
		Vector3.new(2, 2, 0.3),
		PLOT_POSITION + Vector3.new(3, 5, -6.15),
		Color3.fromRGB(175, 225, 255),
		house
	)

	createPart(
		"HouseWindowRight",
		Vector3.new(2, 2, 0.3),
		PLOT_POSITION + Vector3.new(10, 3.5, -3.15),
		Color3.fromRGB(175, 225, 255),
		house
	)

	addHouseUpgradePrompt(body)
end

local function createLevelThreeHouse(house)
	-- Уровень 3: большой укреплённый дом с высокой крышей и вторым крылом.
	local body = createPart(
		"HouseBody",
		Vector3.new(18, 10, 14),
		PLOT_POSITION + Vector3.new(0, 5.5, 0),
		Color3.fromRGB(205, 155, 90),
		house
	)

	createPart(
		"HouseLeftWing",
		Vector3.new(7, 7, 10),
		PLOT_POSITION + Vector3.new(-12, 4, 1),
		Color3.fromRGB(185, 130, 75),
		house
	)

	createPart(
		"HouseRightWing",
		Vector3.new(7, 7, 10),
		PLOT_POSITION + Vector3.new(12, 4, 1),
		Color3.fromRGB(185, 130, 75),
		house
	)

	createPart(
		"HouseRoof",
		Vector3.new(20, 2.5, 16),
		PLOT_POSITION + Vector3.new(0, 11.75, 0),
		Color3.fromRGB(115, 35, 35),
		house
	)

	createPart(
		"LeftWingRoof",
		Vector3.new(8, 2, 11),
		PLOT_POSITION + Vector3.new(-12, 8.5, 1),
		Color3.fromRGB(115, 35, 35),
		house
	)

	createPart(
		"RightWingRoof",
		Vector3.new(8, 2, 11),
		PLOT_POSITION + Vector3.new(12, 8.5, 1),
		Color3.fromRGB(115, 35, 35),
		house
	)

	createPart(
		"HouseDoor",
		Vector3.new(3.5, 5, 0.3),
		PLOT_POSITION + Vector3.new(0, 3, -7.15),
		Color3.fromRGB(75, 45, 25),
		house
	)

	createPart(
		"HouseWindowLeft",
		Vector3.new(2.2, 2.2, 0.3),
		PLOT_POSITION + Vector3.new(-5, 6, -7.15),
		Color3.fromRGB(180, 230, 255),
		house
	)

	createPart(
		"HouseWindowRight",
		Vector3.new(2.2, 2.2, 0.3),
		PLOT_POSITION + Vector3.new(5, 6, -7.15),
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

local function createStorageBuildSpot(plotModel)
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
		STORAGE_POSITION + Vector3.new(0, 0.45, 0),
		Color3.fromRGB(210, 185, 95),
		plotModel
	)
	buildSpot.Material = Enum.Material.SmoothPlastic
	buildSpot.Transparency = 0.25

	addStorageBuildPrompt(buildSpot)

	return buildSpot
end

local function createStorageBuilding(plotModel)
	removeStorageBuildSpot(plotModel)

	local existingStorage = plotModel:FindFirstChild("StorageBuilding")

	if existingStorage then
		return existingStorage
	end

	local storage = Instance.new("Model")
	storage.Name = "StorageBuilding"
	storage.Parent = plotModel

	createPart(
		"StorageBody",
		Vector3.new(8, 5, 6),
		STORAGE_POSITION + Vector3.new(0, 3, 0),
		Color3.fromRGB(130, 85, 45),
		storage
	)

	createPart(
		"StorageRoof",
		Vector3.new(9, 1.5, 7),
		STORAGE_POSITION + Vector3.new(0, 6.25, 0),
		Color3.fromRGB(95, 50, 35),
		storage
	)

	createPart(
		"StorageDoor",
		Vector3.new(2.2, 3, 0.3),
		STORAGE_POSITION + Vector3.new(0, 2.25, -3.15),
		Color3.fromRGB(65, 40, 25),
		storage
	)

	createPart(
		"StorageCrate",
		Vector3.new(2.5, 1.5, 2),
		STORAGE_POSITION + Vector3.new(3, 1.15, 1.5),
		Color3.fromRGB(160, 105, 55),
		storage
	)

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

local function createWorkshopBuildSign(plotModel)
	local existingSign = plotModel:FindFirstChild("WorkshopBuildSign")

	if existingSign then
		return existingSign
	end

	local signModel = Instance.new("Model")
	signModel.Name = "WorkshopBuildSign"
	signModel.Parent = plotModel

	local signPosition = WORKSHOP_POSITION + Vector3.new(0, 1.4, -5.5)

	createPart(
		"WorkshopBuildSignLeftPost",
		Vector3.new(0.35, 2.4, 0.35),
		signPosition + Vector3.new(-2.4, 0, 0),
		Color3.fromRGB(90, 60, 35),
		signModel
	)

	createPart(
		"WorkshopBuildSignRightPost",
		Vector3.new(0.35, 2.4, 0.35),
		signPosition + Vector3.new(2.4, 0, 0),
		Color3.fromRGB(90, 60, 35),
		signModel
	)

	local board = createPart(
		"WorkshopBuildSignBoard",
		Vector3.new(5.8, 1.8, 0.35),
		signPosition + Vector3.new(0, 1.05, 0),
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

local function createWorkshopBuildSpot(player, plotModel)
	if plotModel:FindFirstChild("WorkshopBuilding") then
		removeWorkshopBuildSpot(plotModel)
		return nil
	end

	local existingBuildSpot = plotModel:FindFirstChild("WorkshopBuildSpot")

	if existingBuildSpot then
		addWorkshopBuildPrompt(existingBuildSpot)
		createWorkshopBuildSign(plotModel)
		return existingBuildSpot
	end

	local buildSpot = createPart(
		"WorkshopBuildSpot",
		Vector3.new(9, 0.35, 9),
		WORKSHOP_POSITION,
		Color3.fromRGB(160, 120, 220),
		plotModel
	)
	buildSpot.Material = Enum.Material.SmoothPlastic
	buildSpot.Transparency = 0.12
	buildSpot.CanCollide = false

	addWorkshopBuildPrompt(buildSpot)
	createWorkshopBuildSign(plotModel)

	print(string.format("[PlotService] Created workshop build spot for %s.", player.Name))
	return buildSpot
end

local function createWorkshopBuilding(player, plotModel)
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
		WORKSHOP_POSITION + Vector3.new(0, 0.05, 0),
		Color3.fromRGB(95, 90, 100),
		workshop
	)

	createPart(
		"WorkshopBody",
		Vector3.new(8, 5, 7),
		WORKSHOP_POSITION + Vector3.new(0, 2.85, 0),
		Color3.fromRGB(115, 95, 135),
		workshop
	)

	createPart(
		"WorkshopRoof",
		Vector3.new(9.5, 1.4, 8.5),
		WORKSHOP_POSITION + Vector3.new(0, 5.95, 0),
		Color3.fromRGB(65, 55, 85),
		workshop
	)

	createPart(
		"WorkshopDoor",
		Vector3.new(2.2, 3, 0.3),
		WORKSHOP_POSITION + Vector3.new(-2.3, 1.95, -3.65),
		Color3.fromRGB(55, 38, 35),
		workshop
	)

	createPart(
		"WorkshopWindow",
		Vector3.new(2.2, 1.6, 0.3),
		WORKSHOP_POSITION + Vector3.new(2.2, 3.2, -3.65),
		Color3.fromRGB(180, 225, 240),
		workshop
	)

	createPart(
		"Workbench",
		Vector3.new(3, 1.2, 1.6),
		WORKSHOP_POSITION + Vector3.new(3.4, 1.25, 1.7),
		Color3.fromRGB(145, 90, 50),
		workshop
	)

	createPart(
		"WorkshopAnvil",
		Vector3.new(1.8, 0.8, 1),
		WORKSHOP_POSITION + Vector3.new(-3.2, 1.05, 1.8),
		Color3.fromRGB(70, 75, 80),
		workshop
	)

	print(string.format("[PlotService] %s built workshop visual.", player.Name))
	return workshop
end

local function updateStorageVisual(player, profile)
	local plotModel = getPlot(player)

	if not plotModel then
		return false
	end

	if profile.StorageBuilt then
		createStorageBuilding(plotModel)
	else
		createStorageBuildSpot(plotModel)
	end

	return true
end

local function updateWorkshopVisual(player, profile)
	local plotModel = getPlot(player)

	if not plotModel then
		return false
	end

	if profile.WorkshopBuilt then
		print(string.format("[PlotService] Workshop already built for %s. Restoring visual.", player.Name))
		local workshop = createWorkshopBuilding(player, plotModel)

		if (profile.ToolKitLevel or 0) < 1 then
			addToolKitCraftPrompt(player, workshop)
		else
			removeToolKitCraftPrompt(workshop)
		end
	elseif profile.StorageBuilt then
		createWorkshopBuildSpot(player, plotModel)
	else
		removeWorkshopBuildSpot(plotModel)
	end

	return true
end

local function rebuildHouse(plotModel, houseLevel)
	local oldHouse = plotModel:FindFirstChild("House")

	if oldHouse then
		oldHouse:Destroy()
	end

	local house = Instance.new("Model")
	house.Name = "House"
	house.Parent = plotModel

	if houseLevel <= 1 then
		createLevelOneHouse(house)
	elseif houseLevel == 2 then
		createLevelTwoHouse(house)
	else
		createLevelThreeHouse(house)
	end

	return house
end

local function updateHouseVisual(player, houseLevel)
	local plotModel = getPlot(player)

	if not plotModel then
		return false
	end

	rebuildHouse(plotModel, houseLevel)
	return true
end

function PlotService.UnlockPlot(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[PlotService] Profile for %s was not found. Plot was not unlocked.", player.Name))
		return false
	end

	profile.PlotUnlocked = true
	print(string.format("[PlotService] %s unlocked a plot.", player.Name))

	if PlayerDataService.SendProfileUpdate then
		PlayerDataService.SendProfileUpdate(player)
	end

	return true
end

function PlotService.CreateTestPlot(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[PlotService] Profile for %s was not found. Test plot was not created.", player.Name))
		return nil
	end

	local existingPlot = getPlot(player)

	if existingPlot then
		print(string.format("[PlotService] Test plot for %s already exists.", player.Name))
		updateStorageVisual(player, profile)
		updateWorkshopVisual(player, profile)
		return existingPlot
	end

	local plotModel = Instance.new("Model")
	plotModel.Name = getPlotName(player)
	plotModel.Parent = Workspace

	-- Основание личного участка.
	local base = createPart(
		"PlotBase",
		PLOT_SIZE,
		PLOT_POSITION,
		Color3.fromRGB(80, 155, 85),
		plotModel
	)
	base.Material = Enum.Material.Grass

	createPlayerSign(player, plotModel)
	createPlotAreaSign(plotModel)
	rebuildHouse(plotModel, profile.HouseLevel)
	updateStorageVisual(player, profile)
	updateWorkshopVisual(player, profile)

	print(string.format("[PlotService] Created test plot for %s.", player.Name))
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

	if profile.StorageBuilt then
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

	profile.StorageBuilt = true
	updateStorageVisual(player, profile)
	updateWorkshopVisual(player, profile)

	if PlayerDataService.SendProfileUpdate then
		PlayerDataService.SendProfileUpdate(player)
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

function PlotService.CanBuildWorkshop(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		return false, "профиль не найден"
	end

	if not profile.PlotUnlocked then
		return false, "участок ещё не открыт"
	end

	if profile.StorageBuilt ~= true then
		return false, "склад не построен"
	end

	if profile.WorkshopBuilt then
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

	profile.WorkshopBuilt = true
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

	if profile.WorkshopBuilt ~= true then
		return false, "мастерская не построена"
	end

	if (profile.ToolKitLevel or 0) >= 1 then
		return false, "набор инструментов уже изготовлен"
	end

	local missingResources = {}
	local missingResourceMessages = {}

	if profile.Gold < TOOL_KIT_I_COST.Gold then
		table.insert(missingResources, string.format("Gold %d/%d", profile.Gold, TOOL_KIT_I_COST.Gold))
		table.insert(missingResourceMessages, string.format("%s %d/%d", TOOL_KIT_RESOURCE_LABELS.Gold, profile.Gold, TOOL_KIT_I_COST.Gold))
	end

	if profile.Wood < TOOL_KIT_I_COST.Wood then
		table.insert(missingResources, string.format("Wood %d/%d", profile.Wood, TOOL_KIT_I_COST.Wood))
		table.insert(missingResourceMessages, string.format("%s %d/%d", TOOL_KIT_RESOURCE_LABELS.Wood, profile.Wood, TOOL_KIT_I_COST.Wood))
	end

	if profile.Stone < TOOL_KIT_I_COST.Stone then
		table.insert(missingResources, string.format("Stone %d/%d", profile.Stone, TOOL_KIT_I_COST.Stone))
		table.insert(missingResourceMessages, string.format("%s %d/%d", TOOL_KIT_RESOURCE_LABELS.Stone, profile.Stone, TOOL_KIT_I_COST.Stone))
	end

	if profile.Metal < TOOL_KIT_I_COST.Metal then
		table.insert(missingResources, string.format("Metal %d/%d", profile.Metal, TOOL_KIT_I_COST.Metal))
		table.insert(missingResourceMessages, string.format("%s %d/%d", TOOL_KIT_RESOURCE_LABELS.Metal, profile.Metal, TOOL_KIT_I_COST.Metal))
	end

	if #missingResources > 0 then
		return false, "не хватает ресурсов: " .. table.concat(missingResources, ", "), TOOL_KIT_I_COST, "Не хватает: " .. table.concat(missingResourceMessages, ", ")
	end

	return true, "можно изготовить", TOOL_KIT_I_COST
end

function PlotService.TryCraftToolKit(player)
	print(string.format("[PlotService] %s tried to craft tool kit.", player.Name))

	local canCraft, reason, cost, playerMessage = PlotService.CanCraftToolKit(player)

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

	if not CurrencyService.SpendResources(player, cost) then
		sendPlayerMessage(player, "Не удалось списать ресурсы для набора инструментов")
		return false
	end

	profile.ToolKitLevel = 1
	updateWorkshopVisual(player, profile)

	if PlayerDataService.SendProfileUpdate then
		PlayerDataService.SendProfileUpdate(player)
	end

	if PlayerDataService.SaveProfile then
		PlayerDataService.SaveProfile(player)
	end

	sendPlayerMessage(player, "Набор инструментов I изготовлен")
	print(string.format("[PlotService] %s crafted ToolKitLevel 1.", player.Name))

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

	local currentLevel = profile.HouseLevel or 1

	if currentLevel >= MAX_HOUSE_LEVEL then
		return false, "дом уже улучшен до максимума"
	end

	local cost = getUpgradeCost(currentLevel)

	if not cost then
		return false, "стоимость улучшения не найдена"
	end

	local missingResources = {}

	if profile.Gold < cost.Gold then
		table.insert(missingResources, string.format("Gold %d/%d", profile.Gold, cost.Gold))
	end

	if profile.Wood < cost.Wood then
		table.insert(missingResources, string.format("Wood %d/%d", profile.Wood, cost.Wood))
	end

	if profile.Stone < cost.Stone then
		table.insert(missingResources, string.format("Stone %d/%d", profile.Stone, cost.Stone))
	end

	if #missingResources > 0 then
		return false, "не хватает ресурсов: " .. table.concat(missingResources, ", "), cost
	end

	return true, "можно улучшить", cost
end

function PlotService.TryUpgradeHouse(player)
	local canUpgrade, reason, cost = PlotService.CanUpgradeHouse(player)

	if not canUpgrade then
		local playerMessage = "Дом нельзя улучшить"

		if reason == "дом уже улучшен до максимума" then
			playerMessage = "Дом уже улучшен до максимума"
			print(string.format("[PlotService] %s tried to upgrade house, but %s.", player.Name, reason))
		elseif string.find(reason, "не хватает ресурсов", 1, true) then
			playerMessage = "Недостаточно ресурсов для улучшения дома"
			warn(string.format("[PlotService] %s cannot upgrade house: %s.", player.Name, reason))
		else
			warn(string.format("[PlotService] %s cannot upgrade house: %s.", player.Name, reason))
		end

		sendPlayerMessage(player, playerMessage)
		return false
	end

	local profile = PlayerDataService.GetProfile(player)
	local oldLevel = profile.HouseLevel

	if not CurrencyService.SpendResources(player, cost) then
		sendPlayerMessage(player, "Не удалось списать ресурсы для улучшения дома")
		return false
	end

	profile.HouseLevel += 1
	updateHouseVisual(player, profile.HouseLevel)

	if PlayerDataService.SendProfileUpdate then
		PlayerDataService.SendProfileUpdate(player)
	end

	if PlayerDataService.SaveProfile then
		PlayerDataService.SaveProfile(player)
	end

	sendPlayerMessage(player, string.format("Дом улучшен до уровня %d", profile.HouseLevel))

	print(string.format(
		"[PlotService] %s upgraded house from level %d to %d. Cost: %s.",
		player.Name,
		oldLevel,
		profile.HouseLevel,
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

return PlotService
