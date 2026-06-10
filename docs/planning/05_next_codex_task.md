# MVP 0.4.x — Initial Island Route Layout

> **STATUS: PLANNED (not implemented).** This is planning text only. Do not
> implement it as part of the documentation pass. The previous task
> (extract-only split of `WorldService` into `Services/World/` helper modules)
> is complete, tested, and merged. See `docs/05_current_state.md`
> ("Декомпозиция WorldService") and `docs/planning/17_service_ownership_map.md`
> (section 8) for the helper-module ownership.

## Current context

GoldenLand is a Roblox/Rojo single-player MVP. `WorldService.lua` is now a thin
public world entry point, and world-building helpers live under
`src/ServerScriptService/Services/World/`:

* `WorldLayoutConfig.lua` — static layout constants/coordinates;
* `WorldPartFactory.lua` — generic Part/Model/Folder helpers;
* `WorldSignBuilder.lua` — signs/labels/boards;
* `WorldZoneBuilder.lua` — ForestZone/RockZone visuals and forest visual states;
* `WorldPathBuilder.lua` — blocked paths and pass objects.

The current world still looks and behaves as before. The next step is the first
readable island route skeleton, built **through these helper modules**.

## Goal

Create a first readable island route skeleton that connects the existing world
landmarks into a clear walkable layout. This is a **visual/layout** step, built
with the new `World/` helper modules — not a gameplay systems step.

Planned route nodes (left-to-right / start-to-frontier reading order):

* `SpawnBeach` — spawn / beach start area;
* `StarterPath` — starter path leading inland;
* `PlayerCampArea` — player camp / plot approach area;
* `ForestGate` / forest access — entry toward the forest;
* `ForestZone` — existing forest zone (reuse current builders);
* `RockPass` / `RockZone` — existing pass and rock zone (reuse current builders);
* `BanditCampPath` — path toward the hostile camp;
* `BanditCamp_01` — existing hostile camp / captured outpost (do not move its
  ownership out of `CombatService`).

## Files to inspect before editing

* `docs/00_codex_context.md`
* `docs/05_current_state.md`
* `docs/06_development_rules.md`
* `docs/planning/17_service_ownership_map.md`
* `src/ServerScriptService/Services/WorldService.lua`
* `src/ServerScriptService/Services/World/WorldLayoutConfig.lua`
* `src/ServerScriptService/Services/World/WorldPartFactory.lua`
* `src/ServerScriptService/Services/World/WorldSignBuilder.lua`
* `src/ServerScriptService/Services/World/WorldZoneBuilder.lua`
* `src/ServerScriptService/Services/World/WorldPathBuilder.lua`

## Likely files to edit (when implemented)

* `src/ServerScriptService/Services/World/WorldLayoutConfig.lua` — add route node
  positions/names/sizes.
* `src/ServerScriptService/Services/World/WorldPathBuilder.lua` — add a simple
  trail/road builder for `StarterPath` and `BanditCampPath`.
* `src/ServerScriptService/Services/World/WorldZoneBuilder.lua` — add
  `SpawnBeach` / `PlayerCampArea` / `ForestGate` visual pieces if needed.
* `src/ServerScriptService/Services/WorldService.lua` — only thin orchestration
  calls into the builders (do not bloat it again).

## Implementation requirements (for the future task)

* Build the route nodes through the `World/` helper modules; keep
  `WorldService.lua` as a thin coordinator.
* Add new positions/names/sizes to `WorldLayoutConfig.lua` rather than hardcoding
  them inline in builders.
* Reuse the existing ForestZone, RockZone, `RockPass`, and `BlockedPathToForest`
  builders — do not duplicate them.
* Keep object names stable where save restoration or existing visuals depend on
  them (`ForestZone`, `RockZone`, `RockPass`, `BlockedPathToForest`,
  `BanditCamp_01`).
* Add clear logs in the existing style if helpful.
* Protect against duplicates on repeated world init (find-or-create pattern).

## Important constraints

* Use the new `World/` helper modules.
* Do **not** bloat `WorldService.lua` again.
* Do **not** add combat changes.
* Do **not** add new resources.
* Do **not** change save data unless absolutely necessary.
* Keep the task visual/layout-focused.
* Preserve current gameplay behavior (quests, economy, combat, NPCs, plot).
* Do not touch `default.project.json`, Rojo mapping, `src/Workspace`, or
  R15/R6/avatar settings.

## Conflict marker check

Before finishing, verify there are no Git conflict markers:

```text
<<<<<<<
=======
>>>>>>>
```

## Expected final response (for the future task)

1. git status result from before changes;
2. files changed;
3. short explanation of what changed;
4. diff summary;
5. Roblox Studio test checklist;
6. risks or things to verify manually.

Do not create a PR unless explicitly asked.

## Roblox Studio test checklist (for the future task)

1. Start Play with Rojo sync active.
2. Confirm the start world is created and the spawn/beach area appears.
3. Confirm the starter path and player camp area read as a connected route.
4. Confirm ForestZone access (gate + blocked path) still behaves correctly when
   locked and when unlocked.
5. Confirm `RockPass` / `RockZone` behavior is unchanged.
6. Confirm `BanditCamp_01` / captured outpost visuals are not broken.
7. Confirm resource nodes and NPCs still appear and remain usable.
8. Confirm no duplicate world objects after repeated world initialization.
9. Confirm Output has no errors.
