-- CampNPCService
-- Извлечено из CombatService (шаг 5 декомпозиции сервис-ядра, см.
-- docs/planning/17_service_ownership_map.md). Владеет НЕ-боевым слоем лагеря:
--   - спасённый житель (RescuedNPC): модель, говорящий ProximityPrompt, вербовка;
--   - работник лагеря (CampWorker): модель, статус-промпт, placeholder назначения;
--   - восстановление RescuedNPC / CampWorker по профилю игрока.
--
-- Зависимости только вниз: CampNPCService -> PlayerDataService, RemoteService.
-- CampNPCService НЕ требует CombatService — зависимость односторонняя
-- (CombatService -> CampNPCService). Поэтому маленькие чистые хелперы
-- (createPart, getEnemiesFolder, getCampsFolder, getGroundY) дублируются здесь без
-- изменения поведения: они лишь ищут/создают папки Workspace по имени и кастят луч.
--
-- Профиль: сервис ПИШЕТ JoinedNPCs (вербовка) и WorkerAssignments (placeholder
-- назначения), ЧИТАЕТ CapturedCamps и CampOutposts. Схема профиля и имена полей не
-- меняются. CombatService остаётся владельцем записи CapturedCamps и CampOutposts.

local Workspace = game:GetService("Workspace")

local PlayerDataService = require(script.Parent.PlayerDataService)
local RemoteService = require(script.Parent.RemoteService)

local CampNPCService = {}

local ENEMIES_FOLDER_NAME = "Enemies"
local CAMPS_FOLDER_NAME = "Camps"

-- Спасённый житель (NPC). Появляется только на захваченной земле; после разговора
-- присоединяется к лагерю игрока. Это фундамент для будущих NPC-работников.
local RESCUED_NPC_NAME = "RescuedNPC"
local RESCUED_NPC_PROMPT_NAME = "TalkToRescuedNPCPrompt"
-- Смещение от центра лагеря, в стороне от аванпоста/маркера (OutpostOffset = (0,0,6)),
-- чтобы NPC не перекрывал постройку.
local RESCUED_NPC_OFFSET = Vector3.new(-8, 0, 6)
local RESCUED_NPC_TALKABLE_COLOR = Color3.fromRGB(70, 130, 200) -- дружелюбный синий

-- Работник лагеря (CampWorker). Появляется после того, как спасённый житель
-- присоединился: спасённый NPC больше не остаётся обычным NPC у лагеря, а становится
-- дружелюбным работником рядом с аванпостом игрока (или у захваченного лагеря, если
-- аванпоста ещё нет). Это визуальный фундамент будущей автоматизации работников
-- (без пассивного дохода, профессий и реальной автоматизации).
local CAMP_WORKER_NAME_PREFIX = "CampWorker_"
local CAMP_WORKER_STATUS_PROMPT_NAME = "CampWorkerStatusPrompt"
local CAMP_WORKER_COLOR = Color3.fromRGB(70, 170, 90) -- дружелюбный зелёный, отличается от синего спасённого NPC и красных врагов
-- Смещение работника от построенного аванпоста (в стороне от платформы 9x9 и домика).
local CAMP_WORKER_OUTPOST_OFFSET = Vector3.new(7, 0, 3)
-- Запасная позиция у захваченного лагеря, если аванпост ещё не построен
-- (симметрично спасённому NPC по другую сторону от маркера стройки).
local CAMP_WORKER_FALLBACK_OFFSET = Vector3.new(8, 0, 6)

-- Имя модели работника лагеря: уникально по id лагеря (CampWorker_BanditCamp_01).
local function getCampWorkerName(camp)
	return CAMP_WORKER_NAME_PREFIX .. camp.Id
end

-- Чистый хелпер постройки части (дублируется из CombatService без изменения поведения).
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

-- Перекрашивает тело и голову NPC (голова чуть светлее тела).
local function setRescuedNPCColor(model, color)
	local body = model:FindFirstChild("Body")

	if body then
		body.Color = color
	end

	local head = model:FindFirstChild("Head")

	if head then
		head.Color = color:Lerp(Color3.fromRGB(255, 255, 255), 0.3)
	end
end

-- Имя-тег над NPC (BillboardGui + TextLabel), без внешних ассетов. Создаёт тег один
-- раз и обновляет текст при повторных вызовах.
local function setRescuedNPCNameTag(model, text)
	local head = model:FindFirstChild("Head")

	if not head then
		return
	end

	local billboard = head:FindFirstChild("NameTag")

	if not billboard then
		billboard = Instance.new("BillboardGui")
		billboard.Name = "NameTag"
		billboard.Size = UDim2.fromOffset(150, 24)
		billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.4, 0)
		billboard.AlwaysOnTop = true
		billboard.Adornee = head
		billboard.Parent = head

		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextScaled = true
		label.Font = Enum.Font.SourceSansBold
		label.TextColor3 = Color3.fromRGB(230, 240, 255)
		label.Parent = billboard
	end

	local label = billboard:FindFirstChild("Label")

	if label then
		label.Text = text
	end
end

-- Создаёт модель спасённого NPC (тело + голова) на земле через getGroundY.
-- Защита от дублей: при наличии модели возвращает существующую.
local function createRescuedNPCModel(camp)
	local campModel = getCampsFolder():FindFirstChild(camp.Id)

	if not campModel then
		return nil
	end

	local existing = campModel:FindFirstChild(RESCUED_NPC_NAME)

	if existing then
		return existing
	end

	local spot = camp.Center + RESCUED_NPC_OFFSET
	local groundY = getGroundY(spot.X, spot.Z, spot.Y)
	local feet = Vector3.new(spot.X, groundY, spot.Z)
	local bodyCenter = feet + Vector3.new(0, 2, 0)

	local model = Instance.new("Model")
	model.Name = RESCUED_NPC_NAME
	model:SetAttribute("RescuedNPC", true)

	local body = createPart("Body", Vector3.new(2.2, 4, 1.4), bodyCenter, RESCUED_NPC_TALKABLE_COLOR, model)
	createPart(
		"Head",
		Vector3.new(1.5, 1.5, 1.5),
		bodyCenter + Vector3.new(0, 2.7, 0),
		RESCUED_NPC_TALKABLE_COLOR:Lerp(Color3.fromRGB(255, 255, 255), 0.3),
		model
	)
	model.PrimaryPart = body

	model.Parent = campModel
	return model
end

-- Разговор с работником лагеря: назначает простое сохранённое placeholder-задание
-- ("Idle") по id лагеря. Ничего не начисляет, не списывает и не меняет экономику,
-- не запускает производство, таймеры или циклы — это только заглушка состояния под
-- будущую автоматизацию. Server-authoritative: сервер проверяет профиль, пишет
-- WorkerAssignments и шлёт сообщение; клиент только триггерит ProximityPrompt.
local function onTalkToCampWorker(player, camp)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		return
	end

	profile.WorkerAssignments = profile.WorkerAssignments or {}

	-- Задание уже есть: не дублируем состояние, только сообщаем текущий статус.
	if profile.WorkerAssignments[camp.Id] then
		sendPlayerMessage(player, "Житель лагеря: текущее задание — ожидание.")
		print(string.format(
			"[CampNPCService] %s checked camp worker assignment at %s: %s.",
			player.Name,
			camp.Id,
			tostring(profile.WorkerAssignments[camp.Id])
		))
		return
	end

	-- Первое назначение: ставим placeholder-роль, помечаем профиль грязным и сохраняем.
	profile.WorkerAssignments[camp.Id] = "Idle"
	PlayerDataService.MarkDirty(player)

	if PlayerDataService.SaveProfile then
		PlayerDataService.SaveProfile(player)
	end

	sendPlayerMessage(player, "Житель назначен в лагерь. Задания появятся позже.")
	print(string.format("[CampNPCService] %s assigned camp worker at %s to Idle.", player.Name, camp.Id))
end

-- Создаёт дружелюбного работника лагеря (тело + голова + тег + статус-промпт) у
-- аванпоста, если он построен, иначе — у захваченного лагеря (fallback).
-- Защита от дублей: если работник уже есть, возвращает nil и ничего не создаёт.
-- Возвращает "outpost" или "fallback" в зависимости от выбранной позиции.
local function placeCampWorker(camp, profile)
	local campModel = getCampsFolder():FindFirstChild(camp.Id)

	if not campModel then
		return nil
	end

	if campModel:FindFirstChild(getCampWorkerName(camp)) then
		return nil
	end

	local nearOutpost = type(profile.CampOutposts) == "table" and profile.CampOutposts[camp.Id] == true
	local spot

	if nearOutpost then
		spot = camp.Center + camp.OutpostOffset + CAMP_WORKER_OUTPOST_OFFSET
	else
		spot = camp.Center + CAMP_WORKER_FALLBACK_OFFSET
	end

	local groundY = getGroundY(spot.X, spot.Z, spot.Y)
	local feet = Vector3.new(spot.X, groundY, spot.Z)
	local bodyCenter = feet + Vector3.new(0, 2, 0)

	local model = Instance.new("Model")
	model.Name = getCampWorkerName(camp)
	model:SetAttribute("CampWorker", true)
	model:SetAttribute("CampId", camp.Id)

	local body = createPart("Body", Vector3.new(2.2, 4, 1.4), bodyCenter, CAMP_WORKER_COLOR, model)
	createPart(
		"Head",
		Vector3.new(1.5, 1.5, 1.5),
		bodyCenter + Vector3.new(0, 2.7, 0),
		CAMP_WORKER_COLOR:Lerp(Color3.fromRGB(255, 255, 255), 0.3),
		model
	)
	model.PrimaryPart = body

	setRescuedNPCNameTag(model, "Житель лагеря")

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = CAMP_WORKER_STATUS_PROMPT_NAME
	prompt.ObjectText = "Житель лагеря"
	prompt.ActionText = "Поговорить"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = body

	prompt.Triggered:Connect(function(triggeringPlayer)
		onTalkToCampWorker(triggeringPlayer, camp)
	end)

	model.Parent = campModel

	return if nearOutpost then "outpost" else "fallback"
end

-- Убирает модель работника лагеря (для контролируемого переноса к аванпосту).
local function removeCampWorker(camp)
	local campModel = getCampsFolder():FindFirstChild(camp.Id)
	local worker = campModel and campModel:FindFirstChild(getCampWorkerName(camp))

	if worker then
		worker:Destroy()
	end
end

-- Обработка разговора: только сервер решает join. Проверяет захват, ставит флаг,
-- сохраняет профиль, шлёт сообщение и обновляет визуал NPC на "присоединился".
local function onTalkToRescuedNPC(player, camp)
	local profile = PlayerDataService.GetProfile(player)

	if not profile then
		return
	end

	if not (type(profile.CapturedCamps) == "table" and profile.CapturedCamps[camp.Id]) then
		sendPlayerMessage(player, "Сначала зачисти лагерь")
		return
	end

	if type(profile.JoinedNPCs) == "table" and profile.JoinedNPCs[camp.Id] then
		return
	end

	profile.JoinedNPCs = profile.JoinedNPCs or {}
	profile.JoinedNPCs[camp.Id] = true
	PlayerDataService.MarkDirty(player)

	if PlayerDataService.SaveProfile then
		PlayerDataService.SaveProfile(player)
	end

	-- Спасённый NPC больше не остаётся обычным NPC у лагеря: убираем говорящую модель
	-- и ставим работника лагеря (у аванпоста, если он есть, иначе — у захваченного лагеря).
	local campModel = getCampsFolder():FindFirstChild(camp.Id)
	local rescued = campModel and campModel:FindFirstChild(RESCUED_NPC_NAME)

	if rescued then
		rescued:Destroy()
	end

	local placement = placeCampWorker(camp, profile)

	if placement == "outpost" then
		print(string.format("[CampNPCService] Camp worker placed near outpost at %s for %s.", camp.Id, player.Name))
	elseif placement == "fallback" then
		print(string.format("[CampNPCService] Camp worker placed near captured camp fallback at %s for %s.", camp.Id, player.Name))
	end

	sendPlayerMessage(player, "Житель присоединился к вашему лагерю")
	print(string.format("[CampNPCService] %s recruited rescued NPC at %s.", player.Name, camp.Id))
end

-- Говорящий NPC: синий цвет, тег "Спасённый житель", ровно один ProximityPrompt.
local function applyTalkableNPCVisual(model, camp)
	model:SetAttribute("Joined", false)
	setRescuedNPCColor(model, RESCUED_NPC_TALKABLE_COLOR)
	setRescuedNPCNameTag(model, "Спасённый житель")

	local body = model.PrimaryPart or model:FindFirstChild("Body")

	if body and not body:FindFirstChild(RESCUED_NPC_PROMPT_NAME) then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = RESCUED_NPC_PROMPT_NAME
		prompt.ObjectText = "Спасённый житель"
		prompt.ActionText = "Поговорить"
		prompt.HoldDuration = 0.5
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = body

		prompt.Triggered:Connect(function(player)
			onTalkToRescuedNPC(player, camp)
		end)
	end
end

-- По профилю игрока строит/обновляет NPC у захваченного лагеря.
-- Availability gate: без захвата NPC не создаётся. Если уже присоединился —
-- показываем работника лагеря (CampWorker) без говорящего промпта; иначе — говорящий NPC.
local function showRescuedNPCForProfile(camp, profile, player)
	if not profile then
		return
	end

	if not (type(profile.CapturedCamps) == "table" and profile.CapturedCamps[camp.Id]) then
		return
	end

	local campModel = getCampsFolder():FindFirstChild(camp.Id)

	if not campModel then
		return
	end

	local joined = type(profile.JoinedNPCs) == "table" and profile.JoinedNPCs[camp.Id] == true
	local playerName = if player then player.Name else "unknown"

	if joined then
		-- Присоединившийся: убираем говорящего спасённого NPC (если остался) и
		-- восстанавливаем работника лагеря. placeCampWorker сам выбирает позицию
		-- (у аванпоста, если он есть) и защищает от дублей.
		local rescued = campModel:FindFirstChild(RESCUED_NPC_NAME)

		if rescued then
			rescued:Destroy()
		end

		if placeCampWorker(camp, profile) then
			print(string.format("[CampNPCService] Camp worker restored at %s for %s.", camp.Id, playerName))
		end
	else
		local model = createRescuedNPCModel(camp)

		if not model then
			return
		end

		applyTalkableNPCVisual(model, camp)
		print(string.format("[CampNPCService] Rescued NPC available at %s for %s.", camp.Id, playerName))
	end
end

-- Публичный API (вызывается из CombatService, односторонняя зависимость).

-- Строит/обновляет спасённого NPC или работника лагеря по профилю игрока.
function CampNPCService.ShowRescuedNPCForProfile(camp, profile, player)
	showRescuedNPCForProfile(camp, profile, player)
end

-- Ставит работника лагеря (у аванпоста или fallback). Возвращает "outpost" / "fallback" / nil.
function CampNPCService.PlaceCampWorker(camp, profile)
	return placeCampWorker(camp, profile)
end

-- Убирает модель работника лагеря (для контролируемого переноса к аванпосту).
function CampNPCService.RemoveCampWorker(camp)
	removeCampWorker(camp)
end

return CampNPCService
