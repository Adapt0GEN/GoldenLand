# 05. Next Codex Task

# MVP 0.2.6-fix — ForestZone Empty должен полностью очищать визуал и не получать ресурсы от ResourceService

## Контекст

После выполнения MVP 0.2.6 тест показал частичный успех.

Фактический результат:

```text
ForestZoneState стал Empty.
В Output есть:
[WorldService] Rendering ForestZone visual state: Empty
[WorldService] Cleared old ForestZone visual state objects
[WorldService] Created Empty ForestZone visual
[WorldService] ForestZone state for AstartesPro: Empty
Табличка "Лесная зона очищена" появилась.
```

Проблема:

```text
визуально лесная зона очищается не полностью
в Empty остаются лишние деревья/объекты
в Output есть [ResourceService] Created ForestZone resources
```

Вывод:

```text
WorldService создаёт Empty-визуал,
но ResourceService всё ещё создаёт ресурсы/деревья внутри ForestZone.
```

---

## Цель задачи

Исправить MVP 0.2.6 так, чтобы ForestZone в состоянии Empty визуально очищалась полностью и не получала лишние ресурсы/деревья от ResourceService.

---

## Что проверить и исправить

### 1. ResourceService.lua

Найти место, где создаются `ForestZone resources`.

Если `ForestZoneState == "Empty"`, ResourceService не должен создавать обычные ForestZone resources внутри этой зоны.

Если ResourceService не имеет доступа к профилю/состоянию зоны, лучше убрать создание ForestZone resources из ResourceService для ForestZone и оставить управление ForestZone за WorldService.

Обычные стартовые ресурсы не должны сломаться.

---

### 2. WorldService.lua

Проверить, что при Empty очищаются не только `ForestZoneVisualState`, но и старые группы:

```text
ForestZoneDecor
ForestZoneInteractives
ForestZoneResources
```

или любые старые объекты, созданные для Active-состояния.

Empty-визуал должен создавать только:

```text
очищенную площадку
тропинку
пни / минимальный декор
табличку "Лесная зона очищена"
```

В Empty не должно оставаться:

```text
крупных зелёных деревьев Active-состояния
зарослей Active-состояния
интерактивных завалов
старых каменных куч
респавнящихся ForestZone resources
```

---

### 3. Защита от дублей

Повторный вызов UpdateForestZoneVisual / createForestZone не должен создавать дубли.

При переходе Active -> Empty старые визуальные группы должны удаляться перед созданием Empty-визуала.

---

### 4. Логи

Добавить/уточнить логи:

```text
[ResourceService] Skipped ForestZone resources because ForestZoneState is Empty
```

или:

```text
[ResourceService] ForestZone resources are managed by WorldService; skipping
```

Также желательно:

```text
[WorldService] Removed ForestZoneDecor
[WorldService] Removed ForestZoneInteractives
[WorldService] Removed ForestZoneResources
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
ToolKitLevel
квест first_steps
обычные стартовые ресурсы
системы сытости и усталости
систему Мрака
питомцев
гильдии
боевые классы
```

---

## Ожидаемый ответ Codex

В конце покажи:

```text
1. список изменённых файлов
2. почему ResourceService создавал лишние объекты
3. как теперь Empty очищает старый визуал
4. как тестировать
5. какие строки должны быть в Output
```

---

## Тест

1. Запустить Play.
2. Перейти к ForestZone.
3. Добиться `ForestZoneState = Empty`.
4. Проверить, что визуально зона очищена полностью.
5. Убедиться, что нет крупных зелёных деревьев/зарослей Active-состояния.
6. Убедиться, что нет интерактивных объектов Active-состояния.
7. Подождать 10–20 секунд.
8. Убедиться, что лишние ForestZone resources не появляются.
9. Перезапустить Play.
10. Проверить, что Empty-визуал восстановился.
11. Проверить, что стартовые дерево/камень/металл/золото работают.
12. Проверить, что дом, склад, мастерская и ToolKitLevel не сломались.
