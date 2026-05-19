# 05. Next Codex Task

# MVP 0.2.5 — Архитектура ForestZone: состояния зоны и ресурсы внутри зоны

## Контекст

Продолжаем Roblox/Rojo проект GoldenLand / «Златоземье: Своя Земля».

В проекте уже есть или находится в тестировании:

```text
базовые ресурсы
металл
Набор инструментов I
ToolKitLevel
BlockedPathToForest
ForestUnlocked
ForestZone
```

Игрок может открыть лесную зону через Набор инструментов I.

---

## Проблема

По итогам тестирования ForestZone работает не так, как нужно для долгосрочной механики освоения острова.

Сейчас наблюдается:

```text
1. С зоной есть взаимодействие.
2. Есть добыча материалов.
3. Объекты исчезают за одно действие.
4. Некоторые объекты появляются снова спустя несколько секунд.
5. После состояния Empty остаются декоративные деревья, с которыми нельзя взаимодействовать.
6. Камни на территории респавнятся по cooldown.
```

Главная проблема:

```text
ForestZone смешивает обычные ресурсные точки, декор и объекты освоения зоны.
```

---

## Цель задачи

Сделать MVP-архитектуру ForestZone как зоны с состоянием.

ForestZone должна стать первой зоной-шаблоном для будущих зон.

---

## Главные правила

### Правило 1

Обычные ресурсы и объекты освоения зоны — разные сущности.

```text
Обычный ресурс:
добывается → временно исчезает → респавнится

Объект освоения зоны:
очищается → сохраняется как очищенный → не респавнится
```

### Правило 2

Если объект влияет на состояние зоны, он не должен респавниться как обычный ресурс.

### Правило 3

Если зона стала Empty, она не должна выглядеть как нетронутая густая зона.

---

## Минимальная модель состояний

```text
Locked — зона закрыта, ForestUnlocked = false
Overgrown — зона открыта, но заросшая
Active — зона содержит интерактивные объекты освоения
Empty — интерактивные объекты зоны очищены
Cleared — зона визуально освоена / преобразована
```

Для MVP можно использовать:

```text
Locked
Active
Empty
```

---

## Типы объектов зоны

Ввести хотя бы на уровне кода/таблиц следующие типы:

```text
DecorOnly
ZoneClearObject
ZoneResourceNode
ZoneOneTimeReward
```

Пример:

```lua
local FOREST_ZONE_OBJECTS = {
    {
        id = "ForestBlockage_1",
        type = "ZoneClearObject",
        reward = { Wood = 2 },
    },
    {
        id = "ForestStonePile_1",
        type = "ZoneClearObject",
        reward = { Stone = 2 },
    },
    {
        id = "ForestDecorTree_1",
        type = "DecorOnly",
    },
}
```

---

## Файлы для изучения

Перед изменениями изучи:

```text
docs/05_current_state.md
docs/06_development_rules.md
docs/planning/00_current_state.md
docs/planning/01_roadmap.md
docs/planning/02_idea_backlog.md
docs/planning/03_decisions_log.md
docs/planning/07_zone_architecture.md
docs/planning/08_resource_rules.md
src/ServerScriptService/Services/PlayerDataService.lua
src/ServerScriptService/Services/WorldService.lua
src/ServerScriptService/Services/ResourceService.lua
src/ServerScriptService/Services/CurrencyService.lua
src/ServerScriptService/ServerMain.server.lua
```

---

## Что сделать

### 1. PlayerDataService.lua

Добавить или проверить поля профиля:

```lua
ForestUnlocked = false
ForestZoneState = "Locked"
ForestZoneClearedObjects = {}
```

Требования:

```text
старые сохранения должны нормально нормализоваться
если ForestUnlocked == false, ForestZoneState должен быть "Locked"
если ForestUnlocked == true, но ForestZoneState отсутствует, поставить "Active"
ForestZoneClearedObjects должен быть таблицей
```

Добавить эти поля в:

```text
default profile
normalizeLoadedProfile
createSaveData
GetPublicProfile, если полезно для диагностики
```

---

### 2. WorldService.lua

Сделать ForestZone управляемой зоной.

Нужно:

```text
не создавать дубли ForestZone
создавать зону в зависимости от ForestZoneState
создавать декоративные объекты отдельно
создавать интерактивные объекты отдельно
создавать ресурсные/наградные объекты отдельно, если они нужны
уметь обновить визуальное состояние зоны
```

Желательная структура имён:

```text
ForestZone
ForestZoneDecor
ForestZoneInteractives
ForestZoneResources
ForestZoneSigns
```

---

### 3. Конфигурация объектов ForestZone

Создать в WorldService локальную конфигурацию объектов ForestZone.

Минимальный набор:

```text
ForestBlockage_1 — ZoneClearObject, награда Wood
ForestBlockage_2 — ZoneClearObject, награда Wood
ForestOldTree_1 — ZoneClearObject, награда Wood
ForestStonePile_1 — ZoneClearObject, награда Stone
ForestStonePile_2 — ZoneClearObject, награда Stone
несколько DecorOnly деревьев/кустов
```

Каждый интерактивный объект должен иметь стабильный ID.

---

### 4. Логика очистки объекта зоны

При взаимодействии с ZoneClearObject:

```text
проверить профиль
проверить ForestUnlocked
проверить, не очищен ли objectId
выдать reward через CurrencyService
добавить objectId в ForestZoneClearedObjects
скрыть/удалить объект
проверить, остались ли интерактивные объекты
если все очищены, поставить ForestZoneState = "Empty"
отправить PlayerDataService.SendProfileUpdate(player)
сохранить профиль, если есть безопасный метод SaveProfile
```

Важно:

```text
не менять ресурсы напрямую через profile.Wood/profile.Stone
использовать CurrencyService
```

---

### 5. Поведение Empty

Если ForestZoneState == "Empty":

```text
не создавать очищенные ZoneClearObject
не запускать для них cooldown
не создавать густой декор в прежнем виде
создать визуал очищенной зоны
```

Для MVP достаточно:

```text
меньше деревьев
табличка "Лесная зона очищена"
простая тропинка или площадка
```

---

### 6. ResourceService.lua

Проверить, не создаёт ли ResourceService обычные респавнящиеся камни/деревья внутри ForestZone.

Если создаёт — исправить.

Правило:

```text
ResourceService может создавать обычные стартовые ресурсы.
WorldService управляет объектами освоения ForestZone.
```

---

### 7. Логи

Добавить диагностические логи:

```text
[WorldService] ForestZone state for PlayerName: <state>
[WorldService] Created ForestZone with state <state>
[WorldService] Created ForestZone object <objectId> type <type>
[WorldService] PlayerName cleared forest object <objectId>
[WorldService] ForestZone object already cleared: <objectId>
[WorldService] ForestZone is now Empty for PlayerName
[WorldService] Skipped cleared forest object <objectId>
[WorldService] Created Empty ForestZone visual
```

---

## Не трогать

```text
default.project.json
src/Workspace
Rojo mapping
настройки персонажа/R15/R6
дом
склад
мастерскую
ToolKitLevel без необходимости
квест first_steps без необходимости
NPCService без необходимости
```

---

## Проверить отсутствие Git conflict markers

Перед ответом проверить, что в изменённых файлах нет:

```text
<<<<<<<
=======
>>>>>>>
```

---

## Ожидаемый ответ Codex

В конце ответа показать:

```text
1. Список изменённых файлов.
2. Краткое объяснение архитектуры ForestZoneState.
3. Как разделены обычные ресурсы и объекты освоения зоны.
4. Diff или полный код изменённых файлов.
5. Инструкцию тестирования в Roblox Studio.
6. Какие строки должны быть в Output.
```

---

## Тест в Roblox Studio

1. Запустить Play.
2. Убедиться, что ForestUnlocked уже true или открыть лес через проход.
3. Войти в ForestZone.
4. Найти интерактивные объекты зоны.
5. Взаимодействовать с одним объектом.
6. Проверить, что ресурс начислен через UI.
7. Проверить, что объект исчез.
8. Подождать 10–20 секунд.
9. Проверить, что очищенный объект не появился снова.
10. Очистить все интерактивные объекты зоны.
11. Проверить, что ForestZoneState стал `Empty`.
12. Проверить, что густой декор не остался в старом виде.
13. Перезапустить Play.
14. Проверить, что очищенные объекты не появились снова.
15. Проверить, что Empty-визуал восстановился.
16. Проверить, что стартовые дерево/камень/металл/золото продолжают работать.
17. Проверить, что дом, склад, мастерская и ToolKitLevel не сломались.
18. Проверить Output на ошибки.
