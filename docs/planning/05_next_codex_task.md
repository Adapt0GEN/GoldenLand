# Phase 2.3 — Camp worker job assignment placeholder

## Current context

GoldenLand is a Roblox/Rojo single-player MVP.

Phase 2.1 is implemented and tested:

* after `BanditCamp_01` is captured, a rescued NPC appears;
* talking to the NPC marks him as joined in the player profile;
* joined state is saved in `profile.JoinedNPCs`.

Phase 2.2 is implemented and tested:

* after the rescued NPC joins, its final form is the camp worker
  `CampWorker_BanditCamp_01`;
* the worker has a visible name tag `Житель лагеря`;
* the worker has a status prompt `CampWorkerStatusPrompt`
  (ObjectText = `Житель лагеря`, ActionText = `Поговорить`,
  HoldDuration = `0.5`, MaxActivationDistance = `10`,
  RequiresLineOfSight = `false`);
* talking to the worker only shows an informational message
  (`Житель ждёт поручений. Автоматизация будет доступна позже.`);
* the worker interaction does not add/spend resources or change economy;
* `CampWorker_BanditCamp_01` restores after Stop -> Play;
* the worker currently has only an informational prompt and no job.

So far:

* `JoinedNPCs` exists and is saved;
* no passive income exists yet;
* no full worker automation exists yet;
* no jobs/professions system exists yet.

## Goal

Add a minimal **server-authoritative job assignment placeholder** for the camp
worker. The player should be able to talk to `CampWorker_BanditCamp_01` and
assign a simple saved worker role, but the role must **not** produce resources
yet.

This is still a foundation step before passive automation — add the first saved
worker assignment state only.

Keep the scope very small.

Do **not** implement passive income yet.
Do **not** implement timed production yet.
Do **not** implement full worker automation yet.
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

* `src/ServerScriptService/Services/PlayerDataService.lua`
* `src/ServerScriptService/Services/CombatService.lua`

## Implementation requirements

### Saved profile field

Add a new saved profile field for worker assignments:

* `WorkerAssignments = {}`

Example:

* `profile.WorkerAssignments["BanditCamp_01"] = "Idle"`
* later values can include `"Wood"` or `"Stone"`, but for this task keep it
  simple — only `"Idle"` is used.

Add the field in all three places in `PlayerDataService` (default profile,
loaded/normalized profile, save data), following the existing pattern used for
`JoinedNPCs` / `CampOutposts`.

Old saves must remain safe:

* missing `WorkerAssignments` loads as an empty table `{}`;
* no `nil` indexing on old saves;
* existing `CapturedCamps`, `CampOutposts`, and `JoinedNPCs` saves continue to work.

### Minimal behavior

When the player talks to `CampWorker_BanditCamp_01`:

If no assignment exists for the camp:

* set assignment for `BanditCamp_01` to `"Idle"`;
* mark the profile dirty and save (server-side);
* send message:
  * `Житель назначен в лагерь. Задания появятся позже.`

If an assignment already exists for the camp:

* send message:
  * `Житель лагеря: текущее задание — ожидание.`

Rules:

* no resources should be added or spent;
* no production should start;
* no timers should be created;
* no loop should be introduced.

> Note: this replaces the current Phase 2.2 informational-only talk handler for
> the camp worker. The talk handler now writes/reads the `"Idle"` assignment as
> described above instead of only showing the static informational message.

### Visual/status requirement

If the worker has assignment `"Idle"`:

* the worker should still be visible as `Житель лагеря`;
* optionally update the prompt `ObjectText` or message, but keep it simple;
* do not create a complex UI.

## Restore behavior

On Stop -> Play:

* `WorkerAssignments` should persist;
* the worker should restore as before (Phase 2.2 behavior unchanged);
* talking to the worker should show the already-assigned message
  (`Житель лагеря: текущее задание — ожидание.`).

## Server-authoritative rules

All state must be changed on the server:

* the client may only trigger the `ProximityPrompt`;
* the server validates the profile;
* the server writes the assignment;
* the server sends the player message;
* no client-provided state should be trusted.

## Duplication protection

* no duplicate workers;
* no duplicate prompts;
* repeated prompt use should not duplicate state (idempotent assignment);
* repeated restore should not duplicate visuals.

## Do not touch

Do not change:

* `default.project.json`
* Rojo mapping
* `src/Workspace`
* avatar/R15/R6/player rig settings
* unrelated services
* forge/storage/workshop/house logic
* resource gathering
* combat balance
* passive income
* timed production
* full worker automation
* jobs/professions beyond the placeholder
* classes
* backpack
* food/fatigue
* town systems

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
6. risks / manual verification notes.

Do not create a PR unless explicitly asked.

## Roblox Studio test checklist

1. Start Play with a profile where `CampWorker_BanditCamp_01` exists.
2. Talk to the worker.
3. Confirm message:
   * `Житель назначен в лагерь. Задания появятся позже.`
4. Confirm resources do not change.
5. Talk to the worker again.
6. Confirm message:
   * `Житель лагеря: текущее задание — ожидание.`
7. Stop -> Play.
8. Talk to the worker again.
9. Confirm the assignment persisted and the already-assigned message appears.
10. Confirm no duplicate workers or prompts.
11. Confirm no passive resources are generated.
12. Confirm no Output errors.
