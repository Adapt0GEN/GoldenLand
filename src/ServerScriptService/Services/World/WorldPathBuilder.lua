-- WorldPathBuilder
-- Помощники построения проходов и заблокированных путей мира.
-- Заблокированный путь в лес и каменистый проход создаются здесь; обработчик
-- расчистки передаётся колбэком, чтобы построитель не зависел от WorldService.
-- Логи сохранены в исходном виде ("[WorldService] ..."), чтобы вывод не менялся.

local Config = require(script.Parent.WorldLayoutConfig)
local PartFactory = require(script.Parent.WorldPartFactory)
local SignBuilder = require(script.Parent.WorldSignBuilder)

local createPart = PartFactory.createPart
local createTextSign = SignBuilder.createTextSign

local BLOCKED_PATH_NAME = Config.BLOCKED_PATH_NAME
local BLOCKED_PATH_POSITION = Config.BLOCKED_PATH_POSITION
local ROCK_PASS_NAME = Config.ROCK_PASS_NAME
local ROCK_PASS_POSITION = Config.ROCK_PASS_POSITION

local WorldPathBuilder = {}

-- Создаёт (один раз) заблокированный путь в лес с промптом расчистки.
-- onClearTriggered(player) вызывается при срабатывании промпта.
function WorldPathBuilder.createBlockedPathToForest(worldRoot, onClearTriggered)
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
		onClearTriggered(player)
	end)

	blockedPath.PrimaryPart = log

	print("[WorldService] Created blocked path to forest.")
	return blockedPath
end

-- Создаёт (один раз) каменистый проход с промптом разбора.
-- onClearTriggered(player) вызывается при срабатывании промпта.
function WorldPathBuilder.createRockPass(worldRoot, onClearTriggered)
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
		onClearTriggered(player)
	end)

	rockPass.PrimaryPart = blocker

	print("[WorldService] Created RockPass.")
	return rockPass
end

return WorldPathBuilder
