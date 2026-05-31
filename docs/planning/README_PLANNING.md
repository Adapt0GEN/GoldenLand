# Planning README

Актуальный комплект planning-файлов проекта GoldenLand.

## Как использовать

Папку `docs/planning/` можно скопировать в:

```text
C:\Users\tim90\Documents\GoldenLand\docs\planning
```

## Главный принцип

Идеи не должны сразу превращаться в задачи для Codex.

Порядок:

```text
идея
↓
02_idea_backlog.md
↓
03_decisions_log.md, если это архитектурное решение
↓
01_roadmap.md, если идея принята в долгосрочный план
↓
05_next_codex_task.md, только когда это ближайшая задача
```

## В Codex отправляется только одна ближайшая задача

Текущая ближайшая задача хранится в:

```text
05_next_codex_task.md
```

Не нужно давать Codex весь backlog как задачу.

## Актуальный фокус

```text
Фаза 0 (фундамент) — выполнена в коде, требует проверки в Roblox Studio.
Далее — Фаза 1: игровой «крючок» (захват земли у враждебных NPC).
```

Полный план: `16_assessment_and_master_plan.md`.

Фикс ForestZone Empty (бывший MVP 0.2.6-fix) сделан 2026-05-31:

```text
причина: регэксп очистки ^ForestStone_%d$ не совпадал с ID ForestStone_01/02,
поэтому очищенные камни не удалялись и пересоздавались при refresh.
исправление: учёт per-object состояния в CreateForestZoneResources.
осталось: подтвердить визуальную очистку Empty в Roblox Studio.
```
