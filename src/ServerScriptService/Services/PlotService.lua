-- PlotService
-- Тестовый участок, визуальное развитие дома и платное улучшение.

local Workspace = game:GetService("Workspace")
local PlayerDataService = require(script.Parent.PlayerDataService)

local PlotService = {}

local PLOT_POSITION = Vector3.new(0, 0, 80)
local PLOT_SIZE = Vector3.new(40, 1, 40)
local MAX_HOUSE_LEVEL = 3

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

	print(string.format("[PlotService] Created test plot for %s.", player.Name))
	return plotModel
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
		if reason == "дом уже улучшен до максимума" then
			print(string.format("[PlotService] %s tried to upgrade house, but %s.", player.Name, reason))
		else
			warn(string.format("[PlotService] %s cannot upgrade house: %s.", player.Name, reason))
		end

		return false
	end

	local profile = PlayerDataService.GetProfile(player)
	local oldLevel = profile.HouseLevel

	profile.Gold -= cost.Gold
	profile.Wood -= cost.Wood
	profile.Stone -= cost.Stone
	profile.HouseLevel += 1
	updateHouseVisual(player, profile.HouseLevel)

	if PlayerDataService.SaveProfile then
		PlayerDataService.SaveProfile(player)
	end

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
