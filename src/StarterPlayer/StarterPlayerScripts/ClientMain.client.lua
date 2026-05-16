-- ClientMain.client.lua
-- Точка входа клиентской логики проекта «Златоземье: Своя Земля».
-- На старте здесь нет игровой логики: только безопасный маркер запуска клиента.

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

print(string.format("[GoldenLand] Клиент MVP 0.1 запущен для игрока: %s", localPlayer.Name))
