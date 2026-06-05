# 05. Current State - GoldenLand

## Идентификация проекта

- Рабочее название: **«Золотая земля» / GoldenLand**.
- Roblox-проект: **GoldenLand**.
- Текущий рабочий стек: **Codex Desktop + Rojo + Roblox Studio**.
- Исходный код живет в папке `src/`.
- Roblox Studio получает код через Rojo.

## Важные ограничения окружения

- `Workspace` не синхронизируется через Rojo.
- `Baseplate` и `SpawnLocation` остаются внутри `.rbxl`.
- Rojo-конфиг не должен мапить `Workspace`.
- Нельзя создавать `src/Workspace`.
- Нельзя допускать дублей `ServerMain`, `Services`, `StarterPlayerScripts`.
- Игровую карту и объекты `Workspace` можно править в Roblox Studio, но кодовые сервисы правятся в `src`.

## Текущий рабочий игровой цикл

1. Игрок появляется в стартовой зоне.
2. Игрок говорит со старостой и получает стартовый квест `first_steps`.
3. Игрок добывает базовые ресурсы через `ProximityPrompt`.
4. UI ресурсов показывает текущие значения `Gold`, `Wood`, `Stone`, `Metal`, уровень дома и уровень инструментов.
5. После выполнения стартового квеста открывается личный участок.
6. На участке работают дом, склад и мастерская.
7. Игрок улучшает дом за ресурсы.
8. Игрок создает в мастерской `Набор инструментов I`, повышает `ToolKitLevel` и открывает ForestZone.
9. В ForestZone игрок добывает ресурсы и постепенно переводит зону через состояния `Active`, `Medium`, `Low`, `Empty`.
10. Состояние `ForestArea_01` и `Empty`-состояние ForestZone сохраняются между запусками.
11. Игрок создает `Набор инструментов II`, повышает `ToolKitLevel` до уровня, достаточного для RockZone.
12. При `ToolKitLevel >= 2` открывается RockZone, флаг `RockZoneUnlocked` сохраняется в профиле.
13. RockZone восстанавливается после перезапуска.
14. В RockZone игрок добывает усиленные источники камня и металла: `RichStoneNode` и `MetalVein`.
15. После добычи UI ресурсов обновляется, а ресурсные точки RockZone уходят на cooldown и затем respawn.
16. Игрок строит кузницу, переплавляет `Metal` в `MetalIngot`, затем делает `MetalParts`.
17. Игрок улучшает склад с уровня 1 до уровня 2 за базовые и обработанные ресурсы кузницы.
18. Игрок получает меч в `Backpack` при спавне.
19. Игрок бьёт левой кнопкой мыши; серверный hitbox по передней дуге наносит урон врагам.
20. Игрок убивает тренировочный манекен и получает Gold; манекен респавнится.
21. Игрок находит враждебный лагерь `BanditCamp_01` с кластером врагов.
22. После зачистки всех врагов лагеря земля помечается захваченной, игрок получает бонус Gold и сообщение; захват сохраняется в профиль.
23. На захваченной земле появляется маркер с `ProximityPrompt` для постройки аванпоста.
24. Постройка аванпоста списывает ресурсы через серверный `SpendResources`; аванпост сохраняется и восстанавливается после перезапуска.

MVP 0.4.0-step-4 завершен: кузница теперь связана с прогрессией склада. Производственная цепочка `RockZone -> Metal -> Forge -> MetalIngot -> MetalParts -> StorageLevel 2` работает как первый полезный потребитель обработанных ресурсов.

Фаза 1 (бой и захват острова) завершена и протестирована: ядро `бой -> захват -> стройка` замкнуто. Подробности ниже в разделе «Фаза 1: бой и захват территории».

## Ресурсы

Сейчас в игре работают базовые ресурсы:

```text
Gold
Wood
Stone
Metal
MetalIngot
MetalParts
```

Игрок может добывать стартовые ресурсы, ресурсы ForestZone и ресурсы RockZone. `CurrencyService` отвечает за выдачу ресурсов, списание ресурсов, обновление данных игрока и отображение значений в UI.

Системные сообщения стоимости и нехватки ресурсов работают: игрок получает понятную обратную связь, когда ему не хватает ресурсов для действия или когда действие требует конкретной цены.

## Дом, склад и мастерская

### Дом

- Дом создается на личном участке игрока.
- Дом имеет уровень `HouseLevel`.
- Уровень дома отображается в UI.
- Улучшение дома выполняется через `ProximityPrompt` за ресурсы.
- `HouseLevel` сохраняется через данные игрока.
- Action Preview UI работает для действий дома.

### Склад

- Склад реализован как часть инфраструктуры личного участка.
- Склад работает вместе с текущей ресурсной экономикой.
- Склад имеет `StorageLevel`, который сохраняется в профиле игрока и отображается в UI.
- Построенный склад считается уровнем 1.
- Старые сохранения с `StorageBuilt == true` безопасно восстанавливаются как `StorageLevel = 1`.
- Склад можно улучшить с уровня 1 до уровня 2 через `ProximityPrompt`.
- Стоимость улучшения склада до уровня 2:

```text
Wood 40
Stone 40
Metal 15
MetalIngot 3
MetalParts 2
Gold 20
```

- Эффект уровня 2 на текущем этапе: прогрессия склада сохраняется, отображается в UI и визуально усиливает модель склада. Лимиты вместимости склада пока не добавлялись.
- Action Preview UI работает для улучшения склада.

### Мастерская

- Мастерская реализована на личном участке.
- В мастерской создаются `Набор инструментов I` и `Набор инструментов II`.
- Мастерская связана с прогрессией `ToolKitLevel`.
- Первый набор инструментов открывает ForestZone.
- Второй набор инструментов открывает RockZone.
- Action Preview UI работает для действий мастерской.

## ToolKitLevel и инструменты

- `ToolKitLevel` реализован и сохраняется в данных игрока.
- UI отображает уровень инструментов.
- `Набор инструментов I` повышает `ToolKitLevel` до уровня, достаточного для входа в ForestZone.
- `Набор инструментов II` повышает `ToolKitLevel` до уровня, достаточного для входа в RockZone.

Условия открытия зон:

```text
ForestZone: ToolKitLevel >= 1
RockZone: ToolKitLevel >= 2
```

## ForestZone

ForestZone завершена как первый расширенный участок прогрессии после стартовой базы.

Сейчас работает:

- открытие прохода в ForestZone при `ToolKitLevel >= 1`;
- сохранение `ForestUnlocked`;
- сохранение `ForestZoneState`;
- состояния `ForestZoneState`: `Active`, `Medium`, `Low`, `Empty`;
- сохранение состояния `ForestArea_01`;
- добыча объектов внутри лесной зоны;
- переход зоны до устойчивого `Empty`;
- восстановление `Empty`-состояния после перезапуска Play;
- отсутствие повторного наполнения очищенной ForestZone активными ресурсами.

`ForestZoneState` хранит общее состояние лесной зоны. Когда ресурсы зоны полностью выработаны, `ForestZoneState` становится `Empty` и сохраняется. После перезапуска Play зона не возвращается в густой лес, а восстанавливается как очищенная.

## RockZone

RockZone реализована как следующий слой добычи после ForestZone.

Сейчас работает:

- открытие RockZone при `ToolKitLevel >= 2`;
- сохранение `RockZoneUnlocked`;
- восстановление RockZone после перезапуска;
- создание ресурсных точек только при `RockZoneUnlocked == true`;
- защита от дублей ресурсных точек при повторных вызовах создания зоны;
- добыча ресурсов через `ProximityPrompt`;
- обновление UI после добычи;
- cooldown/respawn ресурсных точек RockZone.

RockZone теперь не просто открывается как новая область, а содержит полезные ресурсные точки. Она стала источником усиленной добычи `Stone` и `Metal`, что создает основу для следующего этапа экономики: строительства кузницы и дальнейшей переработки металла.

## Объекты RockZone

### RichStoneNode

- Богатый камень в RockZone.
- При добыче дает:

```text
+4 Stone
```

- Появляется только если `RockZoneUnlocked == true`.
- Не создает дублей при повторном создании/обновлении зоны.
- После добычи уходит на cooldown и возвращается через respawn.

### MetalVein

- Металлическая жила в RockZone.
- При добыче дает:

```text
+3 Metal
```

- Появляется только если `RockZoneUnlocked == true`.
- Не создает дублей при повторном создании/обновлении зоны.
- После добычи уходит на cooldown и возвращается через respawn.

## Action Preview UI

Action Preview UI работает и показывает игроку предварительную информацию по доступным действиям.

Сейчас он используется для:

- дома;
- мастерской.

UI помогает заранее понять, что произойдет при использовании `ProximityPrompt`, и делает действия строительства/улучшения читаемыми.

## Dev/Admin tool

Dev/admin tool работает и используется для проверки прогресса и ускорения тестирования.

Доступные команды:

```text
/gl status
/gl add Gold 100
/gl set all 500
/gl tools 2
/gl house 2
```

Инструмент не является частью обычного пользовательского игрового цикла, но важен для быстрой проверки экономики, ресурсов, дома и `ToolKitLevel`.

## Фаза 1: бой и захват территории

Фаза 1 реализована в новом сервисе `CombatService` и протестирована. Это первый
игровой «крючок»: бой -> захват земли -> постройка аванпоста.

### Бой

- Игроку при спавне выдаётся базовый меч-`Tool` в `Backpack` (без внешних ассетов).
- Бой полностью серверный: `Tool.Activated` обрабатывается на сервере, поэтому урон
  и попадания нельзя подделать с клиента.
- Удар проверяет hitbox по передней дуге игрока (дальность и угол) и наносит урон
  врагам в зоне поражения; у удара есть cooldown.
- Враги используют собственную систему HP (атрибуты `Health`/`MaxHealth` + полоска
  `BillboardGui`), без `Humanoid` — так надёжнее для статичных целей и проще
  управлять лагерями и захватом.
- При смерти врага атакующий получает Gold; награда начисляется на сервере.

### Тренировочный манекен

- `TrainingDummy` — первая цель для проверки боя.
- При смерти даёт Gold и респавнится через заданную задержку.

### Враждебный лагерь и захват

- В мире существует враждебный лагерь `BanditCamp_01`: кострище, палатки, знамя,
  знак и кластер врагов (стражи с разным HP и усиленный «Leader»).
- Враги лагеря не респавнятся (в отличие от тренировочного манекена).
- После зачистки всех врагов лагеря срабатывает детект полной зачистки
  (`isCampCleared`): земля помечается захваченной, игрок получает бонус Gold и
  сообщение «Лагерь зачищен! Земля теперь твоя».
- Визуал захвата: знамя становится дружественным (зелёным), костёр гаснет, знак
  меняет текст на «Освобождённая земля».
- Захват сохраняется в профиле игрока в поле `CapturedCamps` и восстанавливается
  при перезаходе через `CombatService.RestoreCampsForPlayer` (вызов из `ServerMain`
  после загрузки профиля): враги не возвращаются, визуал захвата применяется заново.

### Аванпост на захваченной земле

- На захваченной земле появляется маркер `OutpostBuildSpot` с `ProximityPrompt`
  «Построить аванпост».
- Постройка списывает ресурсы (`Wood 30`, `Stone 30`, `Metal 10`, `Gold 20`) через
  серверный `CurrencyService.SpendResources`; при нехватке игрок получает сообщение.
- Факт постройки сохраняется в профиле в поле `CampOutposts`.
- Построенный аванпост (платформа, домик, крыша, флаг, знак) сохраняется и
  восстанавливается при перезаходе; маркер стройки исчезает после постройки.

### Привязка к земле через raycast

- Враги, структуры лагеря и аванпост ставятся на реальную высоту земли через
  нисходящий луч (`getGroundY`), а не через хардкод `Y`. Это работает с baseplate,
  террейном и склонами.

### Известные ограничения и риски Фазы 1

- У замаха меча пока нет настоящей анимации — только простой визуальный эффект
  перед игроком; анимация R15 — отдельный шаг полировки (нужен загруженный assetId).
- Лагерь — общий объект `Workspace` (`Workspace.Camps`), а захват хранится в профиле
  конкретного игрока. Для мультиплеера (Фаза 3) поведение захвата/владения лагерем и
  аванпостом потребует пересмотра.
- Новое размещение (бой/лагерь/аванпост) использует raycast `getGroundY`, но часть
  старых сервисов мира всё ещё может опираться на хардкод `Y`. Тот же подход стоит
  постепенно применить к остальным сервисам.

## Текущие работающие системы

- `PlayerDataService` - профиль игрока, загрузка/сохранение через DataStore, публичные данные для UI; хранит `CapturedCamps` и `CampOutposts`.
- `CurrencyService` - выдача и списание ресурсов игрока, обновление UI ресурсов, системные сообщения стоимости/нехватки.
- `QuestService` - квест `first_steps`, прогресс сбора дерева, награды и UI квеста.
- `NPCService` - NPC `VillageElder`, выдача и сдача стартового квеста.
- `ResourceService` - стартовые ресурсы с `ProximityPrompt`, ресурсные точки RockZone и их cooldown/respawn.
- `PlotService` - личный участок, дом, склад, мастерская, визуальные уровни дома и улучшение дома за ресурсы.
- `WorldService` - стартовая сцена, зоны старосты, ресурсов, указатель к личной земле, ForestZone, RockZone и визуальные состояния зон.
- `CombatService` - меч-`Tool`, серверный hitbox, враги с HP, тренировочный манекен, враждебный лагерь, захват территории, маркер и постройка аванпоста, восстановление захвата по профилю.
- `ClientMain UI` - клиентский UI квеста, ресурсов, уровня дома, уровня инструментов, коротких сообщений и Action Preview UI.

## Текущий результат MVP

На текущем этапе проект имеет рабочий вертикальный срез:

- стартовая сцена;
- NPC и стартовый квест;
- добыча базовых ресурсов;
- UI ресурсов и прогресса;
- сохранение профиля игрока;
- личная земля;
- дом;
- склад;
- мастерская;
- `ToolKitLevel`;
- создание `Набор инструментов I`;
- создание `Набор инструментов II`;
- открытие ForestZone;
- состояния ForestZone `Active`, `Medium`, `Low`, `Empty`;
- сохранение `ForestArea_01` и `Empty`-состояния ForestZone;
- открытие RockZone;
- сохранение `RockZoneUnlocked`;
- восстановление RockZone после перезапуска;
- добыча `Stone` из `RichStoneNode`;
- добыча `Metal` из `MetalVein`;
- усиленная добыча камня и металла в RockZone;
- системные сообщения стоимости/нехватки ресурсов;
- dev/admin tool;
- Action Preview UI для дома, мастерской и склада.
- кузница;
- `MetalIngot`;
- `MetalParts`;
- плавка `Metal 5 -> MetalIngot 1`;
- производство `MetalIngot 2 -> MetalParts 1`;
- `StorageLevel`;
- улучшение склада до уровня 2 за ресурсы кузницы;
- меч-`Tool`, выдаваемый при спавне;
- серверный бой (hitbox по передней дуге) и урон врагам;
- враги с HP/смертью (тренировочный манекен + лагерь);
- награда Gold за убийство врага с сервера;
- враждебный лагерь `BanditCamp_01`;
- захват лагеря после зачистки врагов и его сохранение;
- маркер/`ProximityPrompt` аванпоста на захваченной земле;
- постройка аванпоста за ресурсы через серверный `SpendResources`;
- сохранение и восстановление построенного аванпоста после перезапуска.

MVP 0.4.0-step-4 завершен. Forge production loop is now documented as verified.
Фаза 1 (бой и захват острова) завершена и протестирована; ядро `бой -> захват -> стройка`
замкнуто. Следующий шаг развития — по мастер-плану в `docs/planning/16_assessment_and_master_plan.md`
(Фаза 2: автоматизация через NPC). Отложенный мелкий шаг кузницы (Forge level 2 за
`MetalParts`) остаётся как опциональная полировка экономики.

## Current Forge state

- `ForgeLevel` is part of saved player progress through the shared `Buildings` profile data.
- `MetalIngot` and `MetalParts` are saved player resources.
- UI shows Forge level, MetalIngots, and MetalParts.
- The Forge visual restores on the MVP near-start player plot together with house, storage, and workshop.
- Forge production is server-side:
  - smelting spends `Metal 5` and produces `MetalIngot 1`;
  - parts crafting spends `MetalIngot 2` and produces `MetalParts 1`.
- Forge prompts should not duplicate after plot restore, admin refresh, repeated `CreateTestPlot(player)`, profile reload, or Play restart.
- `PlotService` restore cleanup removes generated storage/workshop/Forge visuals, build spots, and signs before rebuilding them. This prevents stale or duplicated building visuals/prompts after repeated plot refresh.

## MVP compact world layout

The current MVP uses a compact single-player layout for fast testing:

- `WorldService` creates the start world.
- `NPCService` creates the village elder.
- `ResourceService` creates starter resource nodes.
- ForestZone and RockZone are created/restored by the existing world and resource services.
- `PlotService` creates `Workspace.PlayerPlots.Plot_<UserId>` near the start world in MVP mode instead of huge grid coordinates such as `110800, 0, 16300`.
- House, `StorageBuilding`, `WorkshopBuilding`, and `Forge` visuals restore on the nearby personal plot.
- The start world, elder, starter resources, ForestZone, RockZone, personal plot, house, storage, workshop, and forge are visible or quickly reachable in one playable area.
- UI shows Gold, Wood, Stone, Metal, MetalIngot, MetalParts, House level, Storage level, ToolKitLevel, and Forge level.
- Plot restore cleans generated storage/workshop/Forge visuals and build spots before rebuilding them, so repeated refreshes should not leave stale visuals or duplicate prompts.

Previous issue fixed: the personal plot was created extremely far from the start world. For the current single-player MVP, near-start plot placement is intentional. Future multiplayer plot grid support may return later, but the current priority is a compact testable island layout.
