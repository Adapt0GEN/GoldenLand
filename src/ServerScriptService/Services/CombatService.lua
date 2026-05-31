-- CombatService
-- Шаг 1.1 Фазы 1: меч-Tool + серверный hitbox + враг-манекен с HP.
-- Бой серверный: Tool.Activated обрабатывается на сервере, поэтому урон и попадания
-- нельзя подделать с клиента. Враги используют собственную систему HP (атрибуты +
-- самодельная полоска здоровья), без Humanoid — так надёжнее для статичных целей
-- и проще расширять до враждебного лагеря в следующих шагах.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local CurrencyService = require(script.Parent.CurrencyService)

local CombatService = {}

local ENEMIES_FOLDER_NAME = "Enemies"

-- Оружие.
local WEAPON_NAME = "Меч"
local SWING_COOLDOWN = 0.55
local SWING_RANGE = 9
local SWING_ARC_DOT = 0.2 -- враг должен быть в передней дуге игрока
local SWING_DAMAGE = 25

-- Тренировочный манекен (первая цель для проверки боя).
local TRAINING_DUMMY_NAME = "TrainingDummy"
local TRAINING_DUMMY_POSITION = Vector3.new(0, 3, 34)
local DUMMY_MAX_HEALTH = 100
local DUMMY_RESPAWN_DELAY = 5
local DUMMY_GOLD_REWARD = 10

local swingCooldownByUserId = {}
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

local function getEnemiesFolder()
	local folder = Workspace:FindFirstChild(ENEMIES_FOLDER_NAME)

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = ENEMIES_FOLDER_NAME
		folder.Parent = Workspace
	end

	return folder
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
	local fill = billboard and billboard:FindFirstChild("Background") and billboard.Background:FindFirstChild("Fill")

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

local function spawnTrainingDummy()
	local folder = getEnemiesFolder()

	if folder:FindFirstChild(TRAINING_DUMMY_NAME) then
		return folder[TRAINING_DUMMY_NAME]
	end

	local model = Instance.new("Model")
	model.Name = TRAINING_DUMMY_NAME

	local body = createPart(
		"Body",
		Vector3.new(2.4, 4, 1.6),
		TRAINING_DUMMY_POSITION,
		Color3.fromRGB(120, 60, 60),
		model
	)

	local head = createPart(
		"Head",
		Vector3.new(1.6, 1.6, 1.6),
		TRAINING_DUMMY_POSITION + Vector3.new(0, 2.8, 0),
		Color3.fromRGB(150, 95, 95),
		model
	)

	model.PrimaryPart = body
	model:SetAttribute("IsEnemy", true)
	model:SetAttribute("MaxHealth", DUMMY_MAX_HEALTH)
	model:SetAttribute("Health", DUMMY_MAX_HEALTH)
	model:SetAttribute("GoldReward", DUMMY_GOLD_REWARD)

	createHealthBar(head)
	model.Parent = folder

	print("[CombatService] Training dummy spawned.")
	return model
end

local function killEnemy(enemyModel)
	local attackerUserId = enemyModel:GetAttribute("LastAttackerUserId")
	local reward = enemyModel:GetAttribute("GoldReward") or 0
	local isTrainingDummy = enemyModel.Name == TRAINING_DUMMY_NAME

	if attackerUserId and reward > 0 then
		local attacker = Players:GetPlayerByUserId(attackerUserId)

		if attacker then
			CurrencyService.AddGold(attacker, reward)
			print(string.format("[CombatService] %s defeated %s (+%d Gold).", attacker.Name, enemyModel.Name, reward))
		end
	end

	enemyModel:Destroy()

	if isTrainingDummy then
		task.delay(DUMMY_RESPAWN_DELAY, function()
			spawnTrainingDummy()
		end)
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

	Players.PlayerAdded:Connect(setupPlayer)

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		swingCooldownByUserId[player.UserId] = nil
	end)

	print("[CombatService] Combat service started.")
end

return CombatService
