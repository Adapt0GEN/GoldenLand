# MVP 0.4.x - Verify Forge production loop

Continue the GoldenLand Roblox/Rojo project.

## Goal

Verify and clean up the Forge production loop without adding new systems.

The current MVP already has RockZone resources, Forge construction, MetalIngot production, MetalParts production, StorageLevel, and ForgeLevel. The next task is to make sure this loop is reliable and easy to test.

## Required focus

- Verify `Metal` is spent correctly to produce `MetalIngot`.
- Verify `MetalIngot` is spent correctly to produce `MetalParts`.
- Verify `ForgeLevel` is displayed in UI data and saved/restored through the existing profile flow.
- Verify Forge prompts do not duplicate after plot restore, admin refresh, or repeated `CreateTestPlot(player)` calls.
- Verify Forge, workshop, storage, and plot visuals still restore on the current near-start MVP plot.
- Verify no duplicate resources or prompts are created during Play restart or profile reload.

## Scope restrictions

- Do not add combat.
- Do not add classes.
- Do not add backpack/inventory UI.
- Do not add food, fatigue, survival needs, pets, automation, raids, or unrelated systems.
- Do not change DataStore schema unless strictly required by an existing bug.
- Do not change Rojo mappings or create `src/Workspace`.
- Keep the task small and focused on the Forge production loop.

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
   - `src/ServerScriptService/Services/PlotService.lua`
   - `src/ServerScriptService/Services/PlayerDataService.lua`
   - `src/ServerScriptService/Services/CurrencyService.lua`
   - `src/StarterPlayer/StarterPlayerScripts/ClientMain.client.lua`

## Expected result

The Forge loop should be stable and testable:

- RockZone provides Metal.
- Forge turns Metal into MetalIngot.
- Forge turns MetalIngot into MetalParts.
- UI/profile data show the correct Forge and processed-resource state.
- Repeated restore paths do not duplicate prompts or resources.
