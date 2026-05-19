# 07. Zone Architecture

## Базовые состояния зоны

```text
Locked
Overgrown
Active
Empty
Cleared
```

## Паспорт ForestZone

```text
ZoneId: ForestZone
DisplayName: Лесная зона
UnlockCondition: ForestUnlocked == true
StateField: ForestZoneState
ClearedObjectsField: ForestZoneClearedObjects
DefaultState: Locked
```

## Состояния MVP

```text
Locked
Active
Empty
```

## Будущие состояния

```text
Overgrown
Cleared
```

## Типы объектов

```text
DecorOnly
GlobalResourceNode
ZoneClearObject
ZoneResourceNode
ZoneOneTimeReward
```

## Правило перехода в Empty

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
