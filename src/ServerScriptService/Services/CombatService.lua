-- CombatService
-- Фаза 1: бой и враги.
--   Шаг 1.1: меч-Tool + серверный hitbox + враг-манекен с HP.
--   Шаг 1.2: враждебный лагерь — кластер врагов + структура лагеря, детект зачистки.
-- Бой серверный: Tool.Activated обрабатывается на сервере, поэтому урон и попадания
-- нельзя подделать с клиента. Враги используют собственную систему HP (атрибуты +
-- самодельная полоска здоровья), без Humanoid — так надёжнее для статичных целей
-- и проще управлять лагерями и захватом.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local CurrencyService = require(script.Parent.CurrencyService)
local PlayerDataService = require(script.Parent.PlayerDataService)
local RemoteService = require(script.Parent.RemoteService)
-- Не-боевой слой лагеря (спасённый NPC / работник / placeholder назначения) вынесен
-- в CampNPCService. Зависимость односторонняя: CombatService -> CampNPCService.
local CampNPCService = require(script.Parent.CampNPCService)

local CombatService = {}

local ENEMIES_FOLDER_NAME = "Enemies"
local CAMPS_FOLDER_NAME = "Camps"

-- Оружие.
local WEAPON_NAME = "Меч"
local SWING_COOLDOWN = 0.55
local SWING_RANGE = 9
local SWING_ARC_DOT = 0.2 -- враг должен быть в передней дуге игрока
local SWING_DAMAGE = 25

-- Тренировочный манекен (первая цель для проверки боя).
local TRAINING_DUMMY_NAME = "TrainingDummy"
-- Позиция на земле (Y = 0): тело поднимается в createEnemy.
local TRAINING_DUMMY_POSITION = Vector3.new(0, 0, 34)
local DUMMY_MAX_HEALTH = 100
local DUMMY_RESPAWN_DELAY = 5
local DUMMY_GOLD_REWARD = 10

-- Враждебный лагерь.
local HOSTILE_CAMP = {
	Id = "BanditCamp_01",
	DisplayName = "Враждебный лагерь",
	CapturedName = "Освобождённая земля",
	-- Центр на земле (Y = 0) и далеко от личного участка игрока, чтобы не перекрываться.
	Center = Vector3.new(0, 0, -95),
	Enemies = {
		{ Suffix = "Guard_1", Offset = Vector3.new(-7, 0, -5), MaxHealth = 80, GoldReward = 15 },
		{ Suffix = "Guard_2", Offset = Vector3.new(7, 0, -6), MaxHealth = 80, GoldReward = 15 },
		{ Suffix = "Guard_3", Offset = Vector3.new(-5, 0, 7), MaxHealth = 100, GoldReward = 20 },
		{ Suffix = "Leader", Offset = Vector3.new(6, 0, 6), MaxHealth = 140, GoldReward = 35, Color = Color3.fromRGB(90, 40, 70) },
	},
	ClearBonusGold = 40,
	OutpostOffset = Vector3.new(0, 0, 6),
}

-- Не-боевой слой лагеря (спасённый житель RescuedNPC и работник CampWorker) вместе с
-- их константами вынесен в CampNPCService. CombatService обращается к нему через
-- публичный API (см. ниже onBuildOutpost / onCampCleared / RestoreCampsForPlayer).

-- Стоимость постройки аванпоста на захваченной земле.
local OUTPOST_COST = {
	Wood = 30,
	Stone = 30,
	Metal = 10,
	Gold = 20,
}

local swingCooldownByUserId = {}
local respawnSpecs = {}
local campClearedFlags = {}
local weaponTemplate = nil

local function createPart(name, size, position, color, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Color = color
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent

	return part
end

local function sendPlayerMessage(player, message)
	RemoteService.SendPlayerMessage(player, message)
end

local function getEnemiesFolder()
	local folder = Workspace:FindFirstChild(ENEMIES_FOLDER_NAME)

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = ENEMIES_FOLDER_NAME
		folder.Parent = Workspace
	end

	return folder
end

local function getCampsFolder()
	local folder = Workspace:FindFirstChild(CAMPS_FOLDER_NAME)

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = CAMPS_FOLDER_NAME
		folder.Parent = Workspace
	end

	return folder
end

-- Находит высоту земли в точке (x, z) лучом сверху вниз, не полагаясь на хардкод Y.
-- Это map-agnostic: работает с baseplate, террейном и склонами.
local function getGroundY(x, z, fallbackY)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { getEnemiesFolder(), getCampsFolder() }
	params.IgnoreWater = true

	local result = Workspace:Raycast(Vector3.new(x, 500, z), Vector3.new(0, -1000, 0), params)

	if result then
		return result.Position.Y
	end

	return fallbackY or 0
end

-- Полоска здоровья над врагом, собранная без внешних ассетов.
local function createHealthBar(headPart)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "HealthBar"
	billboard.Size = UDim2.fromOffset(110, 14)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.2, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = headPart
	billboard.Parent = headPart

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.fromScale(1, 1)
	background.BackgroundColor3 = Color3.fromRGB(25, 20, 20)
	background.BorderSizePixel = 0
	background.Parent = billboard

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(180, 60, 55)
	fill.BorderSizePixel = 0
	fill.Parent = background
end

local function updateHealthBar(enemyModel)
	local head = enemyModel:FindFirstChild("Head")
	local billboard = head and head:FindFirstChild("HealthBar")
	local background = billboard and billboard:FindFirstChild("Background")
	local fill = background and background:FindFirstChild("Fill")

	if not fill then
		return
	end

	local maxHealth = enemyModel:GetAttribute("MaxHealth") or 1
	local health = enemyModel:GetAttribute("Health") or 0
	local fraction = math.clamp(health / math.max(maxHealth, 1), 0, 1)

	fill.Size = UDim2.fromScale(fraction, 1)
end

-- Короткий визуальный эффект замаха перед игроком (без ассетов).
local function playSwingEffect(rootPart)
	local effect = Instance.new("Part")
	effect.Name = "SwingEffect"
	effect.Anchored = true
	effect.CanCollide = false
	effect.CanQuery = false
	effect.Material = Enum.Material.Neon
	effect.Color = Color3.fromRGB(235, 235, 245)
	effect.Transparency = 0.4
	effect.Size = Vector3.new(6, 0.4, 4)
	effect.CFrame = rootPart.CFrame * CFrame.new(0, 0, -4)
	effect.Parent = Workspace

	Debris:AddItem(effect, 0.15)
end

-- Универсальное создание врага. params:
--   Name, Position, MaxHealth, GoldReward, Color?, CampId?, Respawns?, RespawnDelay?
local function createEnemy(params)
	local folder = getEnemiesFolder()

	if folder:FindFirstChild(params.Name) then
		return folder[params.Name]
	end

	local color = params.Color or Color3.fromRGB(120, 60, 60)

	local model = Instance.new("Model")
	model.Name = params.Name

	-- params.Position задаёт X/Z; реальную высоту земли находим лучом. Затем поднимаем
	-- тело на половину высоты, чтобы враг стоял на земле, а не висел в воздухе.
	local groundY = getGroundY(params.Position.X, params.Position.Z, params.Position.Y)
	local feet = Vector3.new(params.Position.X, groundY, params.Position.Z)
	local bodyCenter = feet + Vector3.new(0, 2, 0)
	local body = createPart("Body", Vector3.new(2.4, 4, 1.6), bodyCenter, color, model)

	createPart(
		"Head",
		Vector3.new(1.6, 1.6, 1.6),
		bodyCenter + Vector3.new(0, 2.8, 0),
		color:Lerp(Color3.fromRGB(255, 255, 255), 0.25),
		model
	)

	model.PrimaryPart = body
	model:SetAttribute("IsEnemy", true)
	model:SetAttribute("MaxHealth", params.MaxHealth)
	model:SetAttribute("Health", params.MaxHealth)
	model:SetAttribute("GoldReward", params.GoldReward or 0)

	if params.CampId then
		model:SetAttribute("CampId", params.CampId)
	end

	if params.Respawns then
		model:SetAttribute("Respawns", true)
		respawnSpecs[params.Name] = params
	end

	createHealthBar(model:FindFirstChild("Head"))
	model.Parent = folder

	return model
end

local function spawnTrainingDummy()
	return createEnemy({
		Name = TRAINING_DUMMY_NAME,
		Position = TRAINING_DUMMY_POSITION,
		MaxHealth = DUMMY_MAX_HEALTH,
		GoldReward = DUMMY_GOLD_REWARD,
		Respawns = true,
	})
end

local function isCampCleared(campId)
	for _, enemyModel in ipairs(getEnemiesFolder():GetChildren()) do
		if enemyModel:GetAttribute("CampId") == campId and (enemyModel:GetAttribute("Health") or 0) > 0 then
			return false
		end
	end

	return true
end

local function removeCampEnemies(campId)
	for _, enemyModel in ipairs(getEnemiesFolder():GetChildren()) do
		if enemyModel:GetAttribute("CampId") == campId then
			enemyModel:Destroy()
		end
	end
end

-- Превращает враждебный лагерь в захваченную (твою) территорию: знамя становится
-- дружественным, костёр гаснет, знак меняет текст.
local function applyCapturedVisual(camp)
	local campModel = getCampsFolder():FindFirstChild(camp.Id)

	if not campModel then
		return
	end

	campModel:SetAttribute("Cleared", true)
	campModel:SetAttribute("Captured", true)

	local flag = campModel:FindFirstChild("BannerFlag")

	if flag then
		flag.Color = Color3.fromRGB(70, 170, 90)
	end

	local campfire = campModel:FindFirstChild("Campfire")

	if campfire then
		campfire.Color = Color3.fromRGB(120, 120, 130)
		campfire.Material = Enum.Material.Slate

		local light = campfire:FindFirstChildOfClass("PointLight")

		if light then
			light:Destroy()
		end
	end

	local sign = campModel:FindFirstChild(camp.Id .. "_Sign")
	local surface = sign and sign:FindFirstChild("TextSurface")
	local label = surface and surface:FindFirstChildWhichIsA("TextLabel")

	if label then
		label.Text = camp.CapturedName
	end
end

-- Простой текстовый знак (доска + SurfaceGui), без внешних ассетов.
local function createTextSign(name, text, position, parent)
	local board = createPart("SignBoard", Vector3.new(6, 1.6, 0.3), position, Color3.fromRGB(60, 45, 35), parent)
	board.Name = name

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "TextSurface"
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 50
	surfaceGui.Parent = board

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.TextColor3 = Color3.fromRGB(255, 220, 200)
	label.Parent = surfaceGui

	return board
end

-- Строит аванпост (постройку игрока) на захваченной земле.
local function buildOutpostStructure(camp)
	local campModel = getCampsFolder():FindFirstChild(camp.Id)

	if not campModel then
		return
	end

	if campModel:FindFirstChild("Outpost") then
		return campModel.Outpost
	end

	local spot = camp.Center + camp.OutpostOffset
	local groundY = getGroundY(spot.X, spot.Z, spot.Y)
	local base = Vector3.new(spot.X, groundY, spot.Z)

	local outpost = Instance.new("Model")
	outpost.Name = "Outpost"

	createPart("Platform", Vector3.new(9, 1, 9), base + Vector3.new(0, 0.5, 0), Color3.fromRGB(120, 110, 95), outpost)
	createPart("Cabin", Vector3.new(6, 4, 6), base + Vector3.new(0, 3, 0), Color3.fromRGB(150, 120, 80), outpost)
	createPart("Roof", Vector3.new(7, 1, 7), base + Vector3.new(0, 5.5, 0), Color3.fromRGB(90, 70, 50), outpost)
	createPart("FlagPole", Vector3.new(0.3, 5, 0.3), base + Vector3.new(0, 8, 0), Color3.fromRGB(80, 60, 40), outpost)
	createPart("Flag", Vector3.new(0.2, 1.6, 2.4), base + Vector3.new(0, 9.2, 1.2), Color3.fromRGB(70, 170, 90), outpost)
	createTextSign(camp.Id .. "_OutpostSign", "Аванпост", base + Vector3.new(0, 1.6, 6), outpost)

	outpost.Parent = campModel
	return outpost
end

local function removeBuildSpot(camp)
	local campModel = getCampsFolder():FindFirstChild(camp.Id)
	local marker = campModel and campModel:FindFirstChild("OutpostBuildSpot")

	if marker then
		marker:Destroy()
	end
end

local function onBuildOutpost(player, camp)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		return
	end

	if not (type(profile.CapturedCamps) == "table" and profile.CapturedCamps[camp.Id]) then
		sendPlayerMessage(player, "Сначала зачисти лагерь")
		return
	end

	if type(profile.CampOutposts) == "table" and profile.CampOutposts[camp.Id] then
		return
	end

	local ok, message = CurrencyService.SpendResources(player, OUTPOST_COST)

	if not ok then
		sendPlayerMessage(player, message or "Не хватает ресурсов")
		return
	end

	profile.CampOutposts = profile.CampOutposts or {}
	profile.CampOutposts[camp.Id] = true
	PlayerDataService.MarkDirty(player)

	if PlayerDataService.SaveProfile then
		PlayerDataService.SaveProfile(player)
	end

	removeBuildSpot(camp)
	buildOutpostStructure(camp)

	-- Если житель уже присоединился, переносим работника к построенному аванпосту.
	-- Простой перенос: убираем старую модель и ставим заново у аванпоста (без системы
	-- перемещения). CampNPCService.PlaceCampWorker сам выбирает позицию у аванпоста,
	-- т.к. он теперь есть.
	if type(profile.JoinedNPCs) == "table" and profile.JoinedNPCs[camp.Id] then
		CampNPCService.RemoveCampWorker(camp)

		if CampNPCService.PlaceCampWorker(camp, profile) == "outpost" then
			print(string.format("[CombatService] Camp worker placed near outpost at %s for %s.", camp.Id, player.Name))
		end
	end

	sendPlayerMessage(player, "Аванпост построен!")
	print(string.format("[CombatService] %s built outpost at %s.", player.Name, camp.Id))
end

-- Маркер с ProximityPrompt для постройки аванпоста на захваченной земле.
local function buildBuildSpot(camp)
	local campModel = getCampsFolder():FindFirstChild(camp.Id)

	if not campModel or campModel:FindFirstChild("OutpostBuildSpot") then
		return
	end

	local spot = camp.Center + camp.OutpostOffset
	local groundY = getGroundY(spot.X, spot.Z, spot.Y)
	local marker = createPart(
		"OutpostBuildSpot",
		Vector3.new(5, 0.4, 5),
		Vector3.new(spot.X, groundY + 0.2, spot.Z),
		Color3.fromRGB(70, 170, 90),
		campModel
	)
	marker.Material = Enum.Material.Neon
	marker.Transparency = 0.35

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuildOutpostPrompt"
	prompt.ObjectText = "Захваченная земля"
	prompt.ActionText = "Построить аванпост"
	prompt.HoldDuration = 0.6
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = marker

	prompt.Triggered:Connect(function(player)
		onBuildOutpost(player, camp)
	end)
end

-- По профилю игрока: если аванпост построен — ставим постройку; иначе — маркер стройки.
local function showOutpostForProfile(camp, profile)
	if not profile then
		return
	end

	if type(profile.CampOutposts) == "table" and profile.CampOutposts[camp.Id] then
		removeBuildSpot(camp)
		buildOutpostStructure(camp)
	else
		buildBuildSpot(camp)
	end
end

-- Слой спасённого NPC / работника лагеря (создание моделей, промпты, вербовка,
-- placeholder назначения и их восстановление по профилю) вынесен в CampNPCService.
-- CombatService вызывает его через публичный API: CampNPCService.ShowRescuedNPCForProfile,
-- CampNPCService.PlaceCampWorker, CampNPCService.RemoveCampWorker.
local function onCampCleared(campId, attacker)
	print(string.format("[CombatService] Camp %s cleared.", campId))

	applyCapturedVisual(HOSTILE_CAMP)

	if attacker then
		if HOSTILE_CAMP.Id == campId and HOSTILE_CAMP.ClearBonusGold > 0 then
			CurrencyService.AddGold(attacker, HOSTILE_CAMP.ClearBonusGold)
		end

		-- Сохраняем захват в профиль игрока, чтобы лагерь остался твоим после перезахода.
		local profile = PlayerDataService.GetProfile(attacker)

		if profile then
			profile.CapturedCamps = profile.CapturedCamps or {}
			profile.CapturedCamps[campId] = true
			PlayerDataService.MarkDirty(attacker)

			if PlayerDataService.SaveProfile then
				PlayerDataService.SaveProfile(attacker)
			end

			showOutpostForProfile(HOSTILE_CAMP, profile)
			CampNPCService.ShowRescuedNPCForProfile(HOSTILE_CAMP, profile, attacker)
		end

		sendPlayerMessage(attacker, "Лагерь зачищен! Земля теперь твоя.")
	end
end

local function killEnemy(enemyModel)
	local attackerUserId = enemyModel:GetAttribute("LastAttackerUserId")
	local reward = enemyModel:GetAttribute("GoldReward") or 0
	local campId = enemyModel:GetAttribute("CampId")
	local respawns = enemyModel:GetAttribute("Respawns")
	local enemyName = enemyModel.Name
	local attacker = if attackerUserId then Players:GetPlayerByUserId(attackerUserId) else nil

	if attacker and reward > 0 then
		CurrencyService.AddGold(attacker, reward)
		print(string.format("[CombatService] %s defeated %s (+%d Gold).", attacker.Name, enemyName, reward))
	end

	enemyModel:Destroy()

	if respawns and respawnSpecs[enemyName] then
		task.delay(DUMMY_RESPAWN_DELAY, function()
			createEnemy(respawnSpecs[enemyName])
		end)
	end

	if campId and not campClearedFlags[campId] and isCampCleared(campId) then
		campClearedFlags[campId] = true
		onCampCleared(campId, attacker)
	end
end

local function damageEnemy(enemyModel, amount, attacker)
	local health = enemyModel:GetAttribute("Health") or 0

	if health <= 0 then
		return
	end

	if attacker then
		enemyModel:SetAttribute("LastAttackerUserId", attacker.UserId)
	end

	health = math.max(0, health - amount)
	enemyModel:SetAttribute("Health", health)
	updateHealthBar(enemyModel)

	if health <= 0 then
		killEnemy(enemyModel)
	end
end

local function onSwing(player)
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")

	if not rootPart then
		return
	end

	local now = os.clock()
	local lastSwingAt = swingCooldownByUserId[player.UserId]

	if lastSwingAt and now - lastSwingAt < SWING_COOLDOWN then
		return
	end

	swingCooldownByUserId[player.UserId] = now

	playSwingEffect(rootPart)

	local origin = rootPart.Position
	local lookVector = rootPart.CFrame.LookVector

	for _, enemyModel in ipairs(getEnemiesFolder():GetChildren()) do
		if enemyModel:IsA("Model") and enemyModel:GetAttribute("IsEnemy") and enemyModel.PrimaryPart then
			local toEnemy = enemyModel.PrimaryPart.Position - origin
			local distance = toEnemy.Magnitude

			if distance <= SWING_RANGE and distance > 0 then
				local inFront = lookVector:Dot(toEnemy.Unit) >= SWING_ARC_DOT

				if inFront then
					damageEnemy(enemyModel, SWING_DAMAGE, player)
				end
			end
		end
	end
end

-- Простой текстовый знак (доска + SurfaceGui), без внешних ассетов.
local function createCampStructures(camp)
	local folder = getCampsFolder()

	if folder:FindFirstChild(camp.Id) then
		return folder[camp.Id]
	end

	-- Высоту лагеря привязываем к реальной земле под его центром.
	local groundY = getGroundY(camp.Center.X, camp.Center.Z, camp.Center.Y)
	local center = Vector3.new(camp.Center.X, groundY, camp.Center.Z)
	local campModel = Instance.new("Model")
	campModel.Name = camp.Id
	campModel:SetAttribute("CampId", camp.Id)

	-- Кострище (center.Y = 0 — уровень земли, детали приподняты на половину высоты).
	createPart("Firewood_1", Vector3.new(2.6, 0.5, 0.6), center + Vector3.new(0, 0.25, 0.7), Color3.fromRGB(70, 45, 30), campModel)
	createPart("Firewood_2", Vector3.new(0.6, 0.5, 2.6), center + Vector3.new(0.7, 0.25, 0), Color3.fromRGB(70, 45, 30), campModel)
	local flame = createPart("Campfire", Vector3.new(1.4, 1.6, 1.4), center + Vector3.new(0, 0.8, 0), Color3.fromRGB(235, 130, 40), campModel)
	flame.Material = Enum.Material.Neon
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 150, 60)
	light.Range = 18
	light.Brightness = 2
	light.Parent = flame

	-- Палатки (короб + клиновидная крыша). tentGround — точка на земле.
	local function createTent(name, tentGround)
		createPart(name .. "_Body", Vector3.new(6, 2.4, 5), tentGround + Vector3.new(0, 1.2, 0), Color3.fromRGB(70, 60, 50), campModel)

		local roof = Instance.new("WedgePart")
		roof.Name = name .. "_Roof"
		roof.Size = Vector3.new(5, 2, 6)
		roof.Anchored = true
		roof.CanCollide = false
		roof.Color = Color3.fromRGB(90, 35, 35)
		roof.CFrame = CFrame.new(tentGround + Vector3.new(0, 3.4, 0)) * CFrame.Angles(0, math.rad(90), 0)
		roof.Parent = campModel
	end

	createTent("Tent_1", center + Vector3.new(-14, 0, -8))
	createTent("Tent_2", center + Vector3.new(13, 0, -9))

	-- Знамя лагеря (столб высотой 8, центр на Y = 4).
	createPart("BannerPole", Vector3.new(0.4, 8, 0.4), center + Vector3.new(0, 4, -12), Color3.fromRGB(60, 45, 30), campModel)
	createPart("BannerFlag", Vector3.new(0.2, 2.6, 3.4), center + Vector3.new(0, 6.2, -10.3), Color3.fromRGB(120, 30, 40), campModel)

	createTextSign(camp.Id .. "_Sign", camp.DisplayName, center + Vector3.new(0, 1.5, 14), campModel)

	campModel.Parent = folder
	return campModel
end

local function spawnHostileCamp(camp)
	createCampStructures(camp)

	for _, enemyInfo in ipairs(camp.Enemies) do
		createEnemy({
			Name = camp.Id .. "_" .. enemyInfo.Suffix,
			Position = camp.Center + enemyInfo.Offset,
			MaxHealth = enemyInfo.MaxHealth,
			GoldReward = enemyInfo.GoldReward,
			Color = enemyInfo.Color,
			CampId = camp.Id,
		})
	end

	print(string.format("[CombatService] Hostile camp %s spawned.", camp.Id))
end

local function createWeaponTemplate()
	local tool = Instance.new("Tool")
	tool.Name = WEAPON_NAME
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool.ToolTip = "Атаковать (ЛКМ)"

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.4, 1.4, 0.4)
	handle.Color = Color3.fromRGB(80, 55, 35)
	handle.Material = Enum.Material.Wood
	handle.TopSurface = Enum.SurfaceType.Smooth
	handle.BottomSurface = Enum.SurfaceType.Smooth
	handle.Parent = tool

	local blade = Instance.new("Part")
	blade.Name = "Blade"
	blade.Size = Vector3.new(0.25, 3.4, 0.7)
	blade.Color = Color3.fromRGB(200, 205, 215)
	blade.Material = Enum.Material.Metal
	blade.CanCollide = false
	blade.Massless = true
	blade.TopSurface = Enum.SurfaceType.Smooth
	blade.BottomSurface = Enum.SurfaceType.Smooth
	blade.Parent = tool

	-- Клинок жёстко крепится к рукояти и смещён вверх над ней.
	local weld = Instance.new("Weld")
	weld.Part0 = handle
	weld.Part1 = blade
	weld.C0 = CFrame.new(0, 2.4, 0)
	weld.Parent = handle

	return tool
end

local function giveWeapon(player)
	local backpack = player:FindFirstChildOfClass("Backpack")

	if not backpack then
		return
	end

	local character = player.Character
	local alreadyHasWeapon = backpack:FindFirstChild(WEAPON_NAME)
		or (character and character:FindFirstChild(WEAPON_NAME))

	if alreadyHasWeapon then
		return
	end

	local tool = weaponTemplate:Clone()
	tool.Activated:Connect(function()
		onSwing(player)
	end)
	tool.Parent = backpack
end

local function setupPlayer(player)
	player.CharacterAdded:Connect(function()
		-- Небольшая задержка, чтобы Backpack успел пересоздаться после спавна.
		task.wait(0.4)
		giveWeapon(player)
	end)

	if player.Character then
		giveWeapon(player)
	end
end

function CombatService.Start()
	weaponTemplate = createWeaponTemplate()
	spawnTrainingDummy()
	spawnHostileCamp(HOSTILE_CAMP)

	Players.PlayerAdded:Connect(setupPlayer)

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		swingCooldownByUserId[player.UserId] = nil
	end)

	print("[CombatService] Combat service started.")
end

-- Восстанавливает захваченные лагеря по профилю игрока: убирает врагов и
-- применяет визуал захвата. Вызывается из ServerMain после загрузки профиля.
function CombatService.RestoreCampsForPlayer(player)
	local profile = PlayerDataService.GetProfile(player)

	if not profile or type(profile.CapturedCamps) ~= "table" then
		return
	end

	if profile.CapturedCamps[HOSTILE_CAMP.Id] then
		campClearedFlags[HOSTILE_CAMP.Id] = true
		removeCampEnemies(HOSTILE_CAMP.Id)
		applyCapturedVisual(HOSTILE_CAMP)
		showOutpostForProfile(HOSTILE_CAMP, profile)
		CampNPCService.ShowRescuedNPCForProfile(HOSTILE_CAMP, profile, player)
		print(string.format("[CombatService] Restored captured camp %s for %s.", HOSTILE_CAMP.Id, player.Name))
	end
end

return CombatService
