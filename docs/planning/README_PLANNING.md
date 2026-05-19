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
MVP 0.2.6-fix — добить визуальную очистку ForestZone в Empty.
```

После теста было видно:

```text
ForestZoneState стал Empty
Empty-визуал создаётся
но зона визуально очищается не полностью
ResourceService всё ещё создаёт ForestZone resources
```

Поэтому текущая ближайшая задача — фикс конфликта WorldService и ResourceService в ForestZone.
