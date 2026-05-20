# MVP 0.4.0-step-3 — Forge metal parts / Металлические детали

## Goal

Add the second forge production action:

MetalIngot -> MetalParts

The player should be able to use the built forge to convert MetalIngot into MetalParts. MetalParts must be saved, restored, shown in UI, and updated through the server-side profile/resource flow.

## Current context

Already implemented:
- Gold, Wood, Stone, Metal;
- MetalIngot;
- UI resources;
- profile saving/loading;
- house;
- storage;
- workshop;
- ToolKitLevel;
- ForestZone;
- RockZone;
- Forge building foundation;
- ForgeLevel = 1 after construction;
- forge restores after restart;
- forge smelting:
  Metal 5 -> MetalIngot 1;
- player-visible forge smelting strings are Russian.

## Scope

Implement only:
- MetalParts as a new processed resource;
- forge production action:
  - cost: MetalIngot = 2;
  - result: MetalParts +1;
- UI display for MetalParts;
- saving/loading MetalParts.

Do not implement:
- using MetalParts in house upgrades;
- using MetalParts in tool upgrades;
- weapons;
- armor;
- automation;
- workers;
- combat;
- classes;
- backpack;
- food/fatigue.

## Files to inspect

- docs/00_codex_context.md
- docs/05_current_state.md
- docs/06_development_rules.md
- src/ServerScriptService/Services/PlayerDataService.lua
- src/ServerScriptService/Services/CurrencyService.lua
- src/ServerScriptService/Services/PlotService.lua
- src/StarterPlayer/StarterPlayerScripts/ClientMain.client.lua

## Required changes

### 1. PlayerDataService.lua

Add new profile field:

```lua
MetalParts = 0