# Phase 2.3 — Camp worker job assignment placeholder

## Current context

GoldenLand is a Roblox/Rojo single-player MVP.

Phase 2.1 is implemented and tested:

* after `BanditCamp_01` is captured, a rescued NPC appears;
* the player can talk to the rescued NPC;
* the NPC joins the player’s camp;
* joined state is saved in `profile.JoinedNPCs`;
* after Stop -> Play, the joined NPC restores correctly.

Phase 2.2 is implemented and tested:

* the joined NPC is represented as `CampWorker_BanditCamp_01`;
* the worker has a visible name tag `Житель лагеря`;
* the worker has a `CampWorkerStatusPrompt`;
* talking to the worker currently only shows an informational message;
* the worker restores after Stop -> Play;
* no passive income exists yet;
* no timed production exists yet;
* no full worker automation exists yet;
* no jobs/professions system exists yet.

## Goal

Add the first minimal saved worker assignment state.

The player should be able to talk to `CampWorker_BanditCamp_01` and assign a simple saved placeholder role to the worker.

This is still a foundation step before passive automation.

Do **not** implement passive income.
Do **not** implement timed production.
Do **not** implement full worker automation.
Do **not** implement a job/profession system beyond this placeholder.
Do **not** implement a UI menu unless absolutely necessary.
Do **not** implement town systems, classes, backpack, food/fatigue, or advanced combat.

## Files to inspect

Before editing, inspect:

* `docs/00_codex_context.md`
* `docs/05_current_state.md`
* `docs/06_development_rules.md`
* `src/ServerScriptService/Services/CombatService.lua`
* `src/ServerScriptService/Services/PlayerDataService.lua`
* `src/ServerScriptService/ServerMain.server.lua`

## Likely files to edit

Expected edits are likely limited to:

* `src/ServerScriptService/Services/PlayerDataService.lua`
* `src/ServerScriptService/Services/CombatService.lua`

Do not edit docs in this implementation task unless the task requires a tiny clarification.

## Implementation requirements

### 1. Add saved worker assignment state

Add a new saved profile field:

```lua
WorkerAssignments = {}
```

Use it to store worker assignment state by camp id.

Example:

```lua
profile.WorkerAssignments["BanditCamp_01"] = "Idle"
```

Old saves must remain safe:

* missing `WorkerAssignments` should load as an empty table;
* no nil-index errors;
* existing saves with `JoinedNPCs`, `CapturedCamps`, and `CampOutposts` must continue to work.

Update `PlayerDataService.lua` consistently in all required profile places:

* default profile;
* loaded profile normalization;
* save serialization;
* public profile only if it matches existing diagnostic patterns and is useful.

### 2. Update camp worker prompt behavior

`CampWorker_BanditCamp_01` already exists from Phase 2.2 and has `CampWorkerStatusPrompt`.

Update the worker prompt behavior:

When the player talks to `CampWorker_BanditCamp_01`:

#### If no assignment exists for `BanditCamp_01`

Set:

```lua
profile.WorkerAssignments["BanditCamp_01"] = "Idle"
```

Then:

* mark the profile dirty using the existing project pattern;
* save/update profile using the existing project pattern if appropriate;
* send message:

```text
Житель назначен в лагерь. Задания появятся позже.
```

#### If assignment already exists

Do not duplicate state.

Send message:

```text
Житель лагеря: текущее задание — ожидание.
```

### 3. No economy changes

This task must not change resources.

Talking to the worker must not:

* add Gold;
* add Wood;
* add Stone;
* add Metal;
* add MetalIngot;
* add MetalParts;
* spend any resources;
* start any production;
* start timers;
* create loops;
* generate passive income.

### 4. Restore behavior

On Stop -> Play:

* `WorkerAssignments` should persist;
* `CampWorker_BanditCamp_01` should restore as before;
* talking to the worker after restart should show the already-assigned message if assignment exists:

```text
Житель лагеря: текущее задание — ожидание.
```

### 5. Visual/status behavior

Keep the worker visual simple:

* worker remains visible as `Житель лагеря`;
* no complex UI;
* no job selection menu;
* no production visuals;
* optional: update internal attributes or comments if useful, but do not add large systems.

### 6. Server-authoritative rules

All state must remain server-authoritative:

* the client only triggers `ProximityPrompt`;
* the server validates the player profile;
* the server writes `WorkerAssignments`;
* the server sends player messages;
* no client-provided state should be trusted.

### 7. Duplication protection

Ensure:

* no duplicate workers;
* no duplicate prompts;
* repeated prompt use does not duplicate state;
* repeated restore calls do not duplicate visuals;
* repeated assignment attempts do not rewrite or multiply state unnecessarily.

## Diagnostic logs

Add clear logs similar to existing style:

* `[CombatService] PlayerName assigned camp worker at BanditCamp_01 to Idle.`
* `[CombatService] PlayerName checked camp worker assignment at BanditCamp_01: Idle.`

Avoid noisy logs on every frame or repeated harmless restore.

## Do not touch

Do not change:

* `default.project.json`
* Rojo mapping
* `src/Workspace`
* R15/R6/avatar/player rig/avatar settings
* unrelated services
* forge logic
* storage logic
* workshop logic
* house logic
* resource gathering logic
* combat balance
* passive income
* timed production
* full worker automation
* jobs/professions beyond this placeholder
* town systems
* classes
* backpack
* food/fatigue
* advanced combat

## Conflict marker check

Before finishing, verify there are no Git conflict markers:

```text
<<<<<<<
=======
>>>>>>>
```

## Expected final response

At the end, provide:

1. git status result from before changes;
2. files changed;
3. short explanation of what changed;
4. diff summary;
5. Roblox Studio test checklist;
6. risks or things to verify manually.

Do not create a PR unless explicitly asked.

## Roblox Studio test checklist

1. Start Play with a profile where `CampWorker_BanditCamp_01` exists.

2. Record current resources:

   * Gold
   * Wood
   * Stone
   * Metal
   * MetalIngot
   * MetalParts

3. Talk to the worker.

4. Confirm message appears:

   `Житель назначен в лагерь. Задания появятся позже.`

5. Confirm resources did not change.

6. Talk to the worker again.

7. Confirm message appears:

   `Житель лагеря: текущее задание — ожидание.`

8. Confirm resources still did not change.

9. Stop -> Play.

10. Talk to the worker again.

11. Confirm assignment persisted and the already-assigned message appears:

`Житель лагеря: текущее задание — ожидание.`

12. Confirm no duplicate workers or prompts.
13. Confirm no passive resources are generated over time.
14. Confirm no Output errors.
