# GoldenLand architecture step 1 — document migration to personal islands

Continue the GoldenLand Roblox/Rojo project.

## Goal

Create a clear architecture migration plan for moving from the current compact single-player MVP world to a future structure with personal player islands and shared locations.

This task must not change gameplay code.

## Context

The current MVP intentionally uses a compact single-player layout:
- start world, elder, starter resources, personal plot, ForestZone, RockZone, house, storage, workshop, and forge are close together;
- this is good for fast MVP testing;
- however, future development needs personal islands per player and shared locations for all players.

Current MVP-only issues:
- PlotService uses a near-start plot mode;
- WorldService creates global ForestZone/RockZone objects;
- WorldService.UpdateForestAccessForPlayer(player) changes global world objects based on one player's profile;
- ResourceService.CreateResourceNodes() creates global starter resources;
- PlotService currently owns too many responsibilities: plot, buildings, forge, production, visuals, prompts, and upgrades.

## Before changes

1. Run:

    git status --short

2. If the working tree is not clean, stop and report the status.

3. Read:
- docs/00_codex_context.md
- docs/05_current_state.md
- docs/06_development_rules.md
- docs/planning/05_next_codex_task.md
- src/ServerScriptService/ServerMain.server.lua
- src/ServerScriptService/Services/WorldService.lua
- src/ServerScriptService/Services/PlotService.lua
- src/ServerScriptService/Services/ResourceService.lua
- src/ServerScriptService/Services/PlayerDataService.lua

## Task

Create a new documentation file:

    docs/planning/06_architecture_migration_personal_islands.md

The document must describe the migration from the current compact MVP world to a future architecture with personal player islands and shared locations.

## Required document content

### 1. Current MVP architecture

Document the current state:
- compact single-player test island;
- global WorldRoot;
- MVP near-start plot;
- global ForestZone/RockZone;
- global starter resource nodes;
- PlotService currently creates and restores the player's plot and buildings;
- WorldService currently owns start world, ForestZone, RockZone, blocked paths and zone access visuals;
- ResourceService currently creates starter resource nodes and zone resource nodes.

### 2. Known MVP-only limitations

Document these limitations clearly:
- one player's zone access can affect global world objects;
- personal plot is not a true personal island yet;
- ForestZone/RockZone are not scoped under a player island;
- global starter resources are not separated from personal island resources;
- PlotService is too broad and mixes plot, buildings, forge, production, visuals, prompts and upgrades;
- future multiplayer or shared locations will be hard to implement if player progress continues to mutate global world objects.

### 3. Target architecture

Document the intended target:
- SharedWorld / common start world and future common town;
- PlayerIslands / one island container per player;
- SharedLocations / future shared areas such as town, market, raids, guild zones;
- personal progress must modify only the player's own island;
- shared locations must not depend on one player's saved profile;
- player island systems and shared location systems must be separated.

### 4. Proposed future Workspace structure

Include this structure as plain text in the document:

    Workspace
    ├─ WorldRoot
    ├─ PlayerIslands
    │  └─ Island_<UserId>
    │     ├─ IslandBase
    │     ├─ Buildings
    │     ├─ Zones
    │     ├─ Resources
    │     └─ Markers
    └─ SharedLocations
       ├─ CommonTown
       └─ ExpeditionGates

Explain that:
- WorldRoot may stay temporarily for MVP compatibility;
- PlayerIslands should become the root for personal progression;
- SharedLocations should later hold shared areas available to all players.

### 5. Migration roadmap

Document the roadmap:

1. Add this architecture document.
2. Add safe world container helpers without changing gameplay.
3. Introduce PersonalIslandService while keeping PlotService.CreateTestPlot as a compatibility wrapper.
4. Move personal plot generation under Workspace.PlayerIslands.Island_<UserId>.
5. Move ForestZone/RockZone under the player island.
6. Split PlotService responsibilities gradually:
   - PersonalIslandService for island container and island placement;
   - BuildingService for building levels, build checks and upgrades;
   - BuildingVisualService for temporary generated building models;
   - ProductionService for forge recipes, smelting and parts production;
   - keep PlotService as a temporary compatibility wrapper until migration is complete.
7. Add the first shared location only after personal islands are stable.

### 6. Non-goals

Document that this migration plan does not implement:
- combat;
- classes;
- inventory/backpack;
- food/fatigue;
- pets;
- automation/workers;
- raids;
- guild wars;
- TeleportService;
- large map generation;
- broad code refactors.

### 7. Architectural rules

Add these rules clearly:

    Any state that depends on a player's profile must mutate only that player's own island/container, not global shared world objects.

    Shared locations must be driven by server-wide/shared state, not by one player's personal profile.

## Restrictions

- Do not change any .lua files.
- Do not change gameplay.
- Do not edit default.project.json.
- Do not create src/Workspace.
- Do not touch R15/R6/avatar/player rig settings.
- Do not make broad refactors.
- Documentation only.

## Expected result

At the end, provide:
1. git status result from before changes;
2. created file path;
3. short summary of the document;
4. diff summary;
5. note that no gameplay code was changed.

## After successful review by the user

If the document is correct and the user confirms it, the commit should be:

    git add docs/planning/06_architecture_migration_personal_islands.md
    git commit -m "Document personal islands architecture migration"
    git push
    git status --short