# MVP gameplay - use MetalParts to upgrade the Forge

Continue the GoldenLand Roblox/Rojo project.

## Goal

Add the first meaningful use for `MetalParts` by allowing the player to upgrade the Forge from level 1 to level 2.

The task should stay small: Forge level 1 already exists and must keep working. Forge level 2 should be a saved progression step, not a new production system.

## Required focus

- Add Forge level 2 as a saved building level using the existing `Buildings` profile flow.
- Add a Forge upgrade prompt when `ForgeLevel == 1`.
- Upgrade cost:

```text
Gold 25
Wood 20
Stone 20
Metal 15
MetalIngot 5
MetalParts 3
```

- After upgrade:
  - profile `ForgeLevel` becomes 2;
  - UI updates;
  - Forge visual updates or at least shows a clear level 2 sign/marker;
  - save/restore keeps `ForgeLevel == 2`;
  - no duplicate prompts appear after plot refresh, admin refresh, profile reload, or Play restart.

## Existing behavior to preserve

- Forge level 1 construction still works.
- Level 1 smelting still spends `Metal 5` and produces `MetalIngot 1`.
- Level 1 parts crafting still spends `MetalIngot 2` and produces `MetalParts 1`.
- Forge, storage, workshop, house, and plot visuals still restore on the MVP near-start plot.
- All resource changes must happen on the server.

## Optional small benefit

If it stays low-risk, Forge level 2 smelting may produce `MetalIngot 2` for `Metal 8` instead of `MetalIngot 1` for `Metal 5`.

If that touches too much or risks destabilizing the loop, document it as a future step and only implement the Forge level 2 upgrade.

## Scope restrictions

- Do not add combat.
- Do not add classes.
- Do not add backpack/inventory UI.
- Do not add food, fatigue, survival needs, pets, automation, workers, raids, or unrelated systems.
- Do not change Rojo mappings or create `src/Workspace`.
- Do not edit `default.project.json` unless this task explicitly becomes impossible without it.
- Do not touch R15/R6/avatar/player rig/avatar settings.
- Do not make broad refactors.
- Keep the MVP step small.

## Before changes

1. Run:

```powershell
git status --short
```

2. If the working tree is not clean, stop and report the status.
3. Read:
   - `docs/00_codex_context.md`
   - `docs/05_current_state.md`
   - `docs/06_development_rules.md`
   - `docs/planning/05_next_codex_task.md`
   - `src/ServerScriptService/Services/PlotService.lua`
   - `src/ServerScriptService/Services/PlayerDataService.lua`
   - `src/ServerScriptService/Services/CurrencyService.lua`
   - `src/StarterPlayer/StarterPlayerScripts/ClientMain.client.lua`

## Expected result

- `MetalParts` have a clear first progression use.
- Forge can be upgraded from level 1 to level 2.
- Forge level 2 is visible, saved, restored, and shown in UI.
- Repeated restore paths do not duplicate Forge prompts or visuals.
