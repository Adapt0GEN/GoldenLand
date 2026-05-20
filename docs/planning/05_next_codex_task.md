# MVP 0.4.0-step-5 — Dev/admin support for forge resources and StorageLevel

## Goal

Make the existing dev/admin tool useful for testing the forge and storage progression.

The player/tester should be able to quickly inspect and set:

- `MetalIngot`;
- `MetalParts`;
- `StorageLevel`.

This is a testing/support step only. Do not add new gameplay systems.

## Current context

Already implemented:
- Gold, Wood, Stone, Metal;
- MetalIngot;
- MetalParts;
- resource UI;
- profile saving/loading;
- house;
- storage;
- `StorageLevel`;
- storage upgrade from level 1 to level 2;
- workshop;
- ToolKitLevel;
- ForestZone;
- RockZone;
- forge building foundation;
- ForgeLevel = 1 after construction;
- forge restores after restart;
- forge smelting:
  Metal 5 -> MetalIngot 1;
- forge metal parts production:
  MetalIngot 2 -> MetalParts 1;
- storage level 2 upgrade cost:
  Wood 40, Stone 40, Metal 15, MetalIngot 3, MetalParts 2, Gold 20.

## Scope

Implement only dev/admin support for testing the existing forge/storage chain.

Do not implement:
- new buildings;
- new zones;
- automation;
- workers;
- combat;
- classes;
- backpack;
- food/fatigue;
- new resource types;
- storage capacity limits;
- unrelated commands.

## Files to inspect

- docs/00_codex_context.md
- docs/05_current_state.md
- docs/06_development_rules.md
- src/ServerScriptService/Services/AdminService.lua
- src/ServerScriptService/Services/PlayerDataService.lua
- src/ServerScriptService/Services/CurrencyService.lua
- src/ServerScriptService/Services/PlotService.lua

## Required changes

### 1. Inspect existing admin commands

Find how the current dev/admin tool handles:

- `/gl status`;
- `/gl add`;
- `/gl set`;
- `/gl tools`;
- `/gl house`.

Use the existing command style and validation pattern.

### 2. Add processed resources to admin resource commands

Extend existing admin resource support so these work:

```text
/gl add MetalIngot 10
/gl add MetalParts 10
/gl set MetalIngot 10
/gl set MetalParts 10
```

If `/gl set all amount` exists, include `MetalIngot` and `MetalParts` in that command too.

Do not rename internal resource fields.

### 3. Show processed resources in status

Extend `/gl status` so it includes:

```text
MetalIngot
MetalParts
StorageLevel
```

Keep the status output concise.

### 4. Add minimal StorageLevel admin helper

Add a small command for testing storage level, following existing admin command style:

```text
/gl storage 0
/gl storage 1
/gl storage 2
```

Expected behavior:
- level 0 means storage not built;
- level 1 means storage built at level 1;
- level 2 means storage built at level 2;
- values outside 0..2 are rejected;
- after changing storage level, mark profile dirty, send profile update, save if existing admin patterns do that, and refresh plot visuals if an existing service method allows it safely.

Do not add storage capacity mechanics.

### 5. Safety checks

After changes:
- check that no Git conflict markers remain;
- keep edits inside `src/`;
- do not touch `default.project.json`;
- do not create `src/Workspace`.

## Roblox Studio test checklist

1. Start Play with Rojo sync active.
2. Run `/gl status`.
3. Confirm status includes `MetalIngot`, `MetalParts`, and `StorageLevel`.
4. Run `/gl add MetalIngot 10`.
5. Run `/gl add MetalParts 10`.
6. Confirm UI updates.
7. Run `/gl set all 500`.
8. Confirm `MetalIngot` and `MetalParts` are also set.
9. Run `/gl storage 0`, `/gl storage 1`, `/gl storage 2`.
10. Confirm storage visual and UI update correctly for each valid level.
11. Try `/gl storage 3` and confirm it is rejected.
12. Check Output for errors.
