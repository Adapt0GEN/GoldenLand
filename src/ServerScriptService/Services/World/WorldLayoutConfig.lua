-- WorldLayoutConfig
-- Карта-константы и координаты стартового мира GoldenLand.
-- Чисто данные: имена объектов/папок, позиции зон и точек, общие наборы.
-- Здесь не хранится игровое состояние, только статическая раскладка карты.

local WorldLayoutConfig = {}

-- Имена корневых объектов и зон мира.
WorldLayoutConfig.WORLD_ROOT_NAME = "WorldRoot"
WorldLayoutConfig.BLOCKED_PATH_NAME = "BlockedPathToForest"
WorldLayoutConfig.ROCK_PASS_NAME = "RockPass"
WorldLayoutConfig.ROCK_ZONE_NAME = "RockZone"
WorldLayoutConfig.FOREST_ZONE_NAME = "ForestZone"

-- Имена папок внутри ForestZone.
WorldLayoutConfig.FOREST_ZONE_DECOR_FOLDER_NAME = "ForestZoneDecor"
WorldLayoutConfig.FOREST_ZONE_INTERACTIVES_FOLDER_NAME = "ForestZoneInteractives"
WorldLayoutConfig.FOREST_ZONE_RESOURCES_FOLDER_NAME = "ForestZoneResources"
WorldLayoutConfig.FOREST_ZONE_VISUAL_STATE_FOLDER_NAME = "VisualStateObjects"
WorldLayoutConfig.LEGACY_FOREST_ZONE_VISUAL_STATE_FOLDER_NAME = "ForestZoneVisualState"

WorldLayoutConfig.FOREST_AREA_ID = "ForestArea_01"

-- Позиции зон и проходов.
WorldLayoutConfig.BLOCKED_PATH_POSITION = Vector3.new(-14, 1.1, 8)
WorldLayoutConfig.FOREST_ZONE_POSITION = Vector3.new(-38, 0.05, 8)
WorldLayoutConfig.ROCK_PASS_POSITION = Vector3.new(-58, 1.1, 8)
WorldLayoutConfig.ROCK_ZONE_POSITION = Vector3.new(-78, 0.05, 8)
WorldLayoutConfig.FOREST_AREA_POSITION = WorldLayoutConfig.FOREST_ZONE_POSITION + Vector3.new(0, 0, 2)

WorldLayoutConfig.FOREST_AREA_STAGE_NAMES = {
	"Active",
	"Full",
	"Medium",
	"Low",
	"TreeEmpty",
	"Empty",
}

WorldLayoutConfig.FOREST_AREA_TREE_POSITIONS = {
	WorldLayoutConfig.FOREST_AREA_POSITION + Vector3.new(-8, 0.2, -5),
	WorldLayoutConfig.FOREST_AREA_POSITION + Vector3.new(-4, 0.2, 4),
	WorldLayoutConfig.FOREST_AREA_POSITION + Vector3.new(0, 0.2, -3),
	WorldLayoutConfig.FOREST_AREA_POSITION + Vector3.new(4, 0.2, 5),
	WorldLayoutConfig.FOREST_AREA_POSITION + Vector3.new(8, 0.2, -4),
	WorldLayoutConfig.FOREST_AREA_POSITION + Vector3.new(10, 0.2, 3),
}

WorldLayoutConfig.FOREST_STONE_OBJECT_IDS = {
	"ForestStone_01",
	"ForestStone_02",
}

return WorldLayoutConfig
