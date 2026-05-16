-- WorldService
-- Создаёт простую стартовую сцену и визуальные ориентиры мира.

local Workspace = game:GetService("Workspace")

local WorldService = {}

local WORLD_ROOT_NAME = "WorldRoot"

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

function WorldService.CreateStartWorld()
	local existingWorld = Workspace:FindFirstChild(WORLD_ROOT_NAME)

	if existingWorld then
		print("[WorldService] Start world already exists.")
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

	print("[WorldService] Start world created.")
	return worldRoot
end

return WorldService
