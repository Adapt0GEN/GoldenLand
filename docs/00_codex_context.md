# GoldenLand Codex Context

## Project
GoldenLand / "Золотая земля" is a Roblox/Rojo single-player RPG/survival/island development game.

The player starts as a survivor on a small personal plot, manually gathers resources, builds early structures, unlocks new zones, and later develops a camp/town with production chains and automation.

## Workflow
- Roblox Studio + VS Code + Rojo.
- Edit code only in src/.
- Do not create src/Workspace.
- Do not map Workspace through Rojo.
- Do not change default.project.json unless explicitly required by the current task.
- Do not touch R15/R6/avatar/player rig settings.
- Use small MVP steps.
- Before changes, run git status --short.
- If unexpected uncommitted changes exist, stop and report.

## Source of truth
Before planning or changing code, read:
- docs/05_current_state.md
- docs/06_development_rules.md
- docs/planning/05_next_codex_task.md

## Game direction
Early game:
- player = survivor.

Mid game:
- player = hero + camp builder.

Late game:
- player = town ruler.

Future combat classes:
- Warrior
- Mage

Gathering and production professions are not player classes.
They develop through buildings, workers, city systems, production chains and automation.

## Current economic direction
Resource and production progression:

ForestZone -> Wood
RockZone -> Stone / Metal
Forge -> Ingots / Parts
Upgrades -> Camp / Town / Automation

Do not jump to combat, classes, backpack, food/fatigue, pets, raids, or automation unless the current task explicitly says so.

## Current coding discipline
- Keep tasks small.
- Prefer extending existing services and patterns.
- All resource changes must happen on the server.
- Do not make broad refactors.
- Do not change unrelated systems.
- Check for Git conflict markers before finishing:
  <<<<<<<
  =======
  >>>>>>>
