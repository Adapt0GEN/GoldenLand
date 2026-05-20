# MVP 0.4.0-step-2 — Forge smelting / Плавка металла

## Goal

Add the first forge production action:

Metal -> MetalIngot

The player should be able to use the built forge to smelt raw Metal into MetalIngot. MetalIngot must be saved, restored, shown in UI, and updated through the server-side profile/resource flow.

## Current context

Already implemented:
- Gold, Wood, Stone, Metal;
- UI resources;
- profile saving/loading;
- house;
- storage;
- workshop;
- ToolKitLevel;
- ForestZone;
- RockZone;
- RichStoneNode gives +4 Stone;
- MetalVein gives +3 Metal;
- Forge building foundation;
- ForgeLevel = 1 after construction;
- forge restores after restart.

## Scope

Implement only:
- MetalIngot as a new processed resource;
- forge smelting action:
  - cost: Metal = 5;
  - result: MetalIngot +1;
- UI display for MetalIngot;
- saving/loading MetalIngot.

Do not implement:
- MetalParts;
- weapons;
- armor;
- house upgrades using ingots;
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
MetalIngot = 0