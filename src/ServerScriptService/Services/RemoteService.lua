-- RemoteService
-- Общий серверный помощник для доступа к RemoteEvents и отправки сообщений игроку.
-- RemoteEvents хранятся в ReplicatedStorage/Remotes. Папка Remotes и нужное событие
-- создаются, если их ещё нет. Поведение совпадает с прежними локальными помощниками
-- сервисов (getRemoteEvent / ensureRemoteEvent / sendPlayerMessage), чтобы рефактор
-- не менял игровое поведение.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteService = {}

local REMOTES_FOLDER_NAME = "Remotes"

local function getRemotesFolder()
	local remotes = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER_NAME)

	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = REMOTES_FOLDER_NAME
		remotes.Parent = ReplicatedStorage
	end

	return remotes
end

local function ensureRemoteEvent(eventName)
	local remotes = getRemotesFolder()
	local remoteEvent = remotes:FindFirstChild(eventName)

	if not remoteEvent then
		remoteEvent = Instance.new("RemoteEvent")
		remoteEvent.Name = eventName
		remoteEvent.Parent = remotes
	end

	return remoteEvent
end

-- Возвращает RemoteEvent по имени, создавая его при отсутствии.
-- Совпадает с прежним поведением локальных getRemoteEvent в сервисах.
function RemoteService.GetRemoteEvent(eventName)
	return ensureRemoteEvent(eventName)
end

-- Гарантирует наличие RemoteEvent (создаёт при отсутствии) и возвращает его.
-- Используется при старте сервера для предсоздания событий.
function RemoteService.EnsureRemoteEvent(eventName)
	return ensureRemoteEvent(eventName)
end

-- Отправляет сообщение игроку через PlayerMessageEvent. Текст сообщения не меняется.
function RemoteService.SendPlayerMessage(player, message)
	RemoteService.GetRemoteEvent("PlayerMessageEvent"):FireClient(player, message)
end

return RemoteService
