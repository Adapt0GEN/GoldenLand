# 02. Idea Backlog

---

# IDEA-004 — ForestZone должна иметь состояния

## Статус

Done / Testing passed

## Модель MVP

```text
Locked
Active
Empty
```

На будущее:

```text
Overgrown
Cleared
```

---

# IDEA-005 — Визуальное изменение острова

## Статус

Next

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

# IDEA-008 — Разделить ресурсы на обычные и зональные

## Статус

Done / базовая архитектура принята

## Типы

```text
GlobalResourceNode
ZoneClearObject
ZoneResourceNode
ZoneOneTimeReward
DecorOnly
```

---

# IDEA-010 — Empty-состояние должно визуально отличаться

## Статус

Next

## Категория

Visual Progression / Zone State

## Суть

Если ForestZone стала Empty, игрок должен визуально понять, что зона очищена.

## Возможные элементы

```text
меньше густого леса
очищенная площадка
тропинка
табличка "Лесная зона очищена"
несколько пней вместо деревьев
убранные каменные кучи
```

## Этап

MVP 0.2.6

---

# IDEA-011 — Подготовка Cleared-состояния

## Статус

Accepted

## Категория

Zone State / Future Progression

## Суть

После Empty в будущем появится Cleared — состояние полностью освоенной зоны.

## Сейчас нужно

Подготовить архитектурную возможность:

```text
ForestZoneState = "Cleared"
отдельный визуал Cleared
без автоматического перехода, если рано
```

## Этап

MVP 0.2.6+
