-- PlotService
-- Тестовый участок и визуальное развитие дома без DataStore.

local Workspace = game:GetService("Workspace")
local PlayerDataService = require(script.Parent.PlayerDataService)

local PlotService = {}

local PLOT_POSITION = Vector3.new(0, 0, 80)
local PLOT_SIZE = Vector3.new(40, 1, 40)

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

local function createLevelOneHouse(house)
	-- Уровень 1: маленькая хижина.
	createPart(
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
end

local function createLevelTwoHouse(house)
	-- Уровень 2: дом крупнее, светлее и с боковой пристройкой.
	createPart(
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
	else
		createLevelTwoHouse(house)
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
	rebuildHouse(plotModel, profile.HouseLevel)

	print(string.format("[PlotService] Created test plot for %s.", player.Name))
	return plotModel
end

function PlotService.UpgradeHouse(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		warn(string.format("[PlotService] Profile for %s was not found. House was not upgraded.", player.Name))
		return false
	end

	profile.HouseLevel += 1
	updateHouseVisual(player, profile.HouseLevel)
	print(string.format("[PlotService] %s upgraded house to level %d.", player.Name, profile.HouseLevel))

	return true
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
