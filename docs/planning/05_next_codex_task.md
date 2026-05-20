# MVP 0.4.0-step-4 — Storage upgrade uses forge products

## Goal

Make the forge production chain useful by applying MetalIngot and MetalParts to the storage system.

Add the next storage upgrade step so the player can improve storage using processed forge resources.

Production chain:

RockZone -> Metal -> Forge -> MetalIngot -> MetalParts -> Storage upgrade

## Current context

Already implemented:
- Gold, Wood, Stone, Metal;
- MetalIngot;
- MetalParts;
- resource UI;
- profile saving/loading;
- house;
- storage;
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
- player-visible forge strings are Russian.

## Scope

Implement only the next storage progression step.

Codex must first inspect how storage is currently implemented.

If the project already has `StorageLevel`, extend it safely.

If the project only has a built/not-built storage flag, add a minimal `StorageLevel` progression in the same existing storage system without creating a parallel storage system.

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
- storage capacity limits unless the existing project already has capacity logic.

## Files to inspect

- docs/00_codex_context.md
- docs/05_current_state.md
- docs/06_development_rules.md
- src/ServerScriptService/Services/PlayerDataService.lua
- src/ServerScriptService/Services/CurrencyService.lua
- src/ServerScriptService/Services/PlotService.lua
- src/ServerScriptService/Services/BuildingService.lua
- src/StarterPlayer/StarterPlayerScripts/ClientMain.client.lua

## Required changes

### 1. Inspect existing storage logic

Find the current storage implementation.

Use the existing project pattern.

Do not create a second storage system.

Determine whether the project currently uses:
- `StorageLevel`;
- `HasStorage`;
- another storage-related field.

Make the smallest safe change.

### 2. Storage progression

Add or extend storage progression so the player can upgrade storage to the next level.

Preferred target:

- if `StorageLevel` already exists:
  - add upgrade from level 1 to level 2;

- if storage is currently only built/not-built:
  - introduce `StorageLevel`;
  - existing built storage should behave as `StorageLevel = 1`;
  - missing old saves should safely default to `StorageLevel = 0` or the current project equivalent.

### 3. Storage level 2 cost

Use this cost for upgrading storage to level 2:

```lua
{
    Wood = 40,
    Stone = 40,
    Metal = 15,
    MetalIngot = 3,
    MetalParts = 2,
    Gold = 20,
}