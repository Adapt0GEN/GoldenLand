# 02. Idea Backlog

---

## Статусы

```text
New — новая идея
Accepted — идея принята
Roadmap — идея добавлена в дорожную карту
Next — идея готовится стать ближайшей задачей
In Progress — в работе
Done — реализовано
Not Now — хорошая идея, но рано
Rejected — отклонено
```

---

# IDEA-001 — Металл как базовый ресурс

## Статус

Done / частично реализовано

## Категория

Resources / Progression

## Суть

Металл должен быть базовым ресурсом наряду с деревом, камнем и золотом.

## Этап

MVP 0.2.1

---

# IDEA-002 — Набор инструментов I как технологический уровень

## Статус

Accepted / Roadmap

## Категория

Progression / Crafting / World Access

## Суть

Набор инструментов I не должен быть одноразовым предметом.

## Решение

```lua
ToolKitLevel = 0
ToolKitLevel = 1
```

## Этап

MVP 0.2.2

---

# IDEA-003 — Расчистка прохода в ForestZone

## Статус

In Progress / Testing

## Категория

World Progression / Zone Unlock

## Механика

```text
ToolKitLevel >= 1
↓
ClearForestPathPrompt
↓
ForestUnlocked = true
↓
BlockedPathToForest исчезает
↓
ForestZone появляется
```

## Этап

MVP 0.2.4

---

# IDEA-004 — ForestZone должна иметь состояния

## Статус

Next

## Категория

World State / Zone System / Visual Progression

## Проблема

```text
объекты исчезают за одно действие
объекты респавнятся через cooldown
декоративные деревья остаются после Empty
камни продолжают появляться
```

## Модель

```text
Locked
Overgrown
Active
Empty
Cleared
```

## Этап

MVP 0.2.5

---

# IDEA-005 — Визуальное изменение острова

## Статус

Accepted

## Категория

Visual Progression / World Progression

## Суть

Остров должен визуально меняться от действий игрока.

Пример:

```text
заросший проход
↓
расчищенная тропинка
↓
частично освоенный лес
↓
освоенная зона
```

## Этап

MVP 0.2.6+

---

# IDEA-006 — Первый спасаемый NPC в лесу

## Статус

Not Now

## Причина

Сначала нужны:

```text
стабильная ForestZone
состояния зоны
минимальная система NPC-союзников
понимание пользы NPC в лагере
```

## Этап

MVP 0.3.x

---

# IDEA-007 — Атаки на лагерь

## Статус

Not Now

## Причина

Сначала нужны:

```text
здоровье построек
система врагов
система урона
смысл защиты
возможность подготовиться
минимальная боёвка
```

## Этап

MVP 0.5.x

---

# IDEA-008 — Разделить ресурсы на обычные и зональные

## Статус

Next

## Категория

Resources / Zone Architecture

## Суть

Ресурсы внутри зоны должны иметь тип поведения.

Типы:

```text
GlobalResourceNode — обычная ресурсная точка, респавнится по cooldown.
ZoneClearObject — объект освоения зоны, очищается один раз и сохраняется.
ZoneResourceNode — ресурс зоны, может респавниться, но только если так задумано.
ZoneOneTimeReward — одноразовая находка или награда.
DecorOnly — декор без взаимодействия.
```

## Этап

MVP 0.2.5

---

# IDEA-009 — У каждой зоны должен быть паспорт

## Статус

Accepted

## Категория

Zone Architecture / Design Documentation

## Пример

```text
ZoneId: ForestZone
UnlockCondition: ForestUnlocked == true
StateField: ForestZoneState
ClearedObjectsField: ForestZoneClearedObjects
AllowedObjectTypes:
- DecorOnly
- ZoneClearObject
- ZoneResourceNode
```

## Этап

MVP 0.2.5+
