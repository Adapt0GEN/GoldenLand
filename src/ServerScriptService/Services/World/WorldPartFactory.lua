-- WorldPartFactory
-- Базовые помощники создания Part/Folder и применения простых визуальных свойств.
-- Здесь только общая геометрия мира: без зон, путей и игрового состояния.

local Workspace = game:GetService("Workspace")

local Config = require(script.Parent.WorldLayoutConfig)

local WorldPartFactory = {}

-- Создаёт заякоренную часть с базовыми визуальными настройками.
function WorldPartFactory.createPart(name, size, position, color, parent)
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

-- Полупрозрачный маркер площадки/зоны.
function WorldPartFactory.createAreaMarker(name, size, position, color, parent)
	local marker = WorldPartFactory.createPart(name, size, position, color, parent)
	marker.Material = Enum.Material.SmoothPlastic
	marker.Transparency = 0.15

	return marker
end

-- Плоский декоративный маркер земли/пути без коллизий.
function WorldPartFactory.createFlatMarker(name, size, position, color, parent)
	local marker = WorldPartFactory.createPart(name, size, position, color, parent)
	marker.Material = Enum.Material.Ground
	marker.CanCollide = false
	marker.CanTouch = false

	return marker
end

-- Находит или создаёт дочернюю папку с заданным именем.
function WorldPartFactory.ensureChildFolder(parent, folderName)
	local folder = parent:FindFirstChild(folderName)

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = folderName
		folder.Parent = parent
	end

	return folder
end

-- Находит или создаёт корневую папку мира в Workspace.
function WorldPartFactory.getWorldRoot()
	local worldRoot = Workspace:FindFirstChild(Config.WORLD_ROOT_NAME)

	if not worldRoot then
		worldRoot = Instance.new("Folder")
		worldRoot.Name = Config.WORLD_ROOT_NAME
		worldRoot.Parent = Workspace
	end

	return worldRoot
end

-- Переключает видимость модели целиком (части, SurfaceGui, ProximityPrompt).
function WorldPartFactory.setModelVisible(model, isVisible)
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

return WorldPartFactory
