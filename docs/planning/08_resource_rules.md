# 08. Resource Rules

## Главный принцип

Не все объекты, которые дают ресурсы, являются обычными ресурсными точками.

Нужно различать:

```text
обычный фарм
освоение зоны
одноразовую награду
декор
```

## Таблица типов

| Тип | Респавн | Даёт ресурс | Влияет на состояние зоны | Сохраняется |
|---|---:|---:|---:|---:|
| DecorOnly | Нет | Нет | Нет | Обычно нет |
| GlobalResourceNode | Да | Да | Нет | Обычно нет |
| ZoneClearObject | Нет | Может | Да | Да |
| ZoneResourceNode | Может | Да | Может зависеть от дизайна | Да/нет |
| ZoneOneTimeReward | Нет | Да/предмет | Может | Да |

## Начисление ресурсов

Ресурсы нельзя менять напрямую.

Нужно использовать CurrencyService:

```lua
CurrencyService.AddWood(player, 1)
CurrencyService.AddStone(player, 1)
CurrencyService.AddMetal(player, 1)
CurrencyService.AddGold(player, 1)
```

## ForestZone

ForestZone не должна одновременно управляться WorldService и ResourceService без явного правила.

Если ForestZoneState == Empty, ResourceService не должен создавать там обычные ресурсы Active-состояния.
