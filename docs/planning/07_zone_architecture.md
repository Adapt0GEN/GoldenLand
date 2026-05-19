# 07. Zone Architecture

Этот файл описывает правила зон в GoldenLand.

---

## 1. Зачем нужна архитектура зон

Игра строится вокруг освоения острова.

Зона должна иметь:

```text
условие открытия
состояние
визуальное представление
интерактивные объекты
правила ресурсов
сохранение прогресса
возможность дальнейшего развития
```

---

## 2. Базовые состояния зоны

```text
Locked
Overgrown
Active
Empty
Cleared
```

### Locked

Зона закрыта.

```text
игрок не может попасть внутрь
проход заблокирован
объекты зоны не активны
```

### Overgrown

Зона открыта, но выглядит дикой и заросшей.

### Active

Зона активна и содержит интерактивные объекты.

### Empty

Зона очищена от интерактивных объектов.

```text
объекты очистки не респавнятся
зона не должна выглядеть нетронутой
```

### Cleared

Зона освоена.

```text
может появиться тропинка
может появиться площадка
может появиться NPC
может открыться следующий проход
```

---

## 3. Типы объектов зоны

### DecorOnly

Только визуал.

Примеры:

```text
деревья без prompt
кусты
трава
камни без взаимодействия
```

---

### GlobalResourceNode

Обычная ресурсная точка.

Поведение:

```text
добывается
даёт ресурс
временно исчезает
респавнится по cooldown
```

Обычно обслуживается ResourceService.

---

### ZoneClearObject

Объект освоения зоны.

Поведение:

```text
очищается один раз
может дать ресурс
сохраняется как очищенный
не респавнится
влияет на состояние зоны
```

Обслуживается WorldService или будущим ZoneService.

---

### ZoneResourceNode

Ресурс внутри зоны, который может респавниться, если так задумано.

Важно: такой ресурс должен быть явно описан как респавнящийся ресурс зоны.

---

### ZoneOneTimeReward

Одноразовая награда.

Поведение:

```text
получается один раз
сохраняется как полученная
не респавнится
```

---

## 4. Паспорт зоны

Шаблон:

```text
ZoneId:
DisplayName:
UnlockCondition:
StateField:
ClearedObjectsField:
DefaultState:
ObjectTypes:
ResourceRules:
VisualStates:
ExitRules:
```

---

## 5. Паспорт ForestZone

```text
ZoneId: ForestZone
DisplayName: Лесная зона
UnlockCondition: ForestUnlocked == true
StateField: ForestZoneState
ClearedObjectsField: ForestZoneClearedObjects
DefaultState: Locked
```

### Состояния MVP

```text
Locked
Active
Empty
```

### Будущие состояния

```text
Overgrown
Cleared
```

### Объекты MVP

```text
ForestBlockage_1 — ZoneClearObject
ForestBlockage_2 — ZoneClearObject
ForestOldTree_1 — ZoneClearObject
ForestStonePile_1 — ZoneClearObject
ForestStonePile_2 — ZoneClearObject
ForestDecorTree_1 — DecorOnly
ForestDecorTree_2 — DecorOnly
ForestSign_1 — DecorOnly
```

### Ресурсные правила

```text
ZoneClearObject может дать Wood/Stone как награду за очистку.
ZoneClearObject не респавнится.
Обычные ResourceNode не должны случайно создаваться внутри ForestZone.
ZoneResourceNode можно добавить позже отдельной задачей.
```

---

## 6. Правило сохранения

Для каждого очищенного объекта зоны нужно хранить ID.

```lua
ForestZoneClearedObjects = {
    ForestBlockage_1 = true,
    ForestOldTree_1 = true,
    ForestStonePile_1 = true,
}
```

Если objectId уже есть в таблице:

```text
объект не создавать
prompt не показывать
награду повторно не выдавать
```

---

## 7. Правило перехода в Empty

Если все `ZoneClearObject` в зоне очищены:

```lua
ForestZoneState = "Empty"
```

После этого:

```text
не создавать очищенные объекты
не запускать cooldown для очищенных объектов
изменить визуал зоны
```

---

## 8. На будущее: ZoneService

Пока можно реализовать логику в WorldService.

Если зон станет больше, можно выделить:

```text
ZoneService
ZoneConfig
ZoneObjectFactory
ZoneStateService
```
