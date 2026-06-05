# Phase 2.2 — Move joined NPC to player outpost as first camp worker

## Current context

GoldenLand is a Roblox/Rojo single-player MVP.

Phase 1 is implemented and tested:

* player receives a basic sword on spawn;
* left mouse attack damages enemies;
* hostile camp `BanditCamp_01` exists;
* camp can be captured after enemies are defeated;
* captured camp state persists;
* outpost marker/prompt appears on captured land;
* built outpost persists and restores.

Phase 2.1 is implemented and tested:

* after `BanditCamp_01` is captured, a rescued NPC appears;
* the rescued NPC has a ProximityPrompt:

  * ObjectText = `Спасённый житель`
  * ActionText = `Поговорить`
* talking to the NPC marks him as joined in the player profile;
* joined state is saved in `profile.JoinedNPCs`;
* after Stop -> Play, the NPC is restored as already joined;
* no passive income or full worker automation exists yet.

## Goal

Implement the next small foundation step for future worker automation.

After a rescued NPC joins the player, the NPC should no longer remain only as a generic joined NPC at the hostile camp. Instead, the joined NPC should appear as a friendly **CampWorker** near the player’s built outpost if the outpost exists.

If the outpost does not exist yet, use a safe fallback position near the captured camp.

This task is visual/state foundation only.

Do **not** implement passive income yet.
Do **not** implement full worker automation yet.
Do **not** implement jobs, professions, town systems, classes, backpack, food/fatigue, or advanced combat.

## Files to inspect

Before editing, inspect:

* `docs/00_codex_context.md`
* `docs/05_current_state.md`
* `docs/06_development_rules.md`
* `src/ServerScriptService/Services/CombatService.lua`
* `src/ServerScriptService/Services/PlayerDataService.lua`
* `src/ServerScriptService/Services/PlotService.lua`
* `src/ServerScriptService/ServerMain.server.lua`

## Implementation requirements

### 1. Keep Phase 2.1 behavior before the NPC joins

If `BanditCamp_01` is captured but the rescued NPC has not joined yet:

* keep the existing talkable rescued NPC near the captured camp;
* keep the existing prompt:

  * ObjectText = `Спасённый житель`
  * ActionText = `Поговорить`
* do not break existing recruitment behavior.

### 2. Add CampWorker visual after joining

If the rescued NPC is already joined, create a friendly worker visual:

* Name = `CampWorker_BanditCamp_01`
* visible name tag = `Житель лагеря`
* friendly color/appearance, visually distinct from enemies and from the unjoined rescued NPC;
* place the worker near the player’s outpost if the outpost exists;
* if the outpost does not exist, place the worker near the captured camp fallback position;
* use existing ground placement/raycast helper patterns where possible.

### 3. Add CampWorker ProximityPrompt

The joined worker should have a simple status prompt:

* Name = `CampWorkerStatusPrompt`
* ObjectText = `Житель лагеря`
* ActionText = `Поговорить`
* HoldDuration = `0.5`
* MaxActivationDistance = `10`
* RequiresLineOfSight = `false`

When the player talks to the worker, send this message:

`Житель ждёт поручений. Автоматизация будет доступна позже.`

This interaction must not add resources, spend resources, start production, or change economy state.

## Restore behavior

On Stop -> Play:

### If the camp is not captured

* no rescued NPC;
* no camp worker.

### If the camp is captured but the NPC is not joined

* restore the existing talkable rescued NPC near the captured camp;
* do not create the camp worker.

### If the NPC is joined

* restore `CampWorker_BanditCamp_01`;
* place it near the outpost if possible;
* otherwise place it near the captured camp fallback position;
* do not restore the talkable rescued NPC prompt.

## Outpost interaction

If the player joined the rescued NPC before building an outpost:

* the worker may appear near the captured camp fallback position.

If the player later builds the outpost:

* after outpost build or after Stop -> Play, the worker should appear near the outpost if this can be done safely with the current architecture.

Keep this simple. Do not introduce a large relocation system unless absolutely necessary.

## Duplication protection

Prevent duplicates:

* at most one `RescuedNPC` per camp;
* at most one `CampWorker_BanditCamp_01` per camp;
* no duplicate prompts;
* repeated restore calls must not create multiple workers;
* repeated prompt triggers must not duplicate visuals or state.

## Server-authoritative rules

All state and progression must remain server-authoritative:

* the client may only trigger ProximityPrompt interaction;
* the server validates profile state;
* the server creates/removes/updates NPC visuals;
* the server sends player messages;
* no client-provided state should be trusted.

## Save/profile requirements

Use the existing `JoinedNPCs` field from Phase 2.1.

Do not add a new profile field unless it is clearly necessary.

Old saves must remain safe:

* missing `JoinedNPCs` must still load as an empty table;
* existing captured camp and outpost saves must continue to work.

## Diagnostic logs

Add clear logs similar to existing style:

* `[CombatService] Camp worker restored at BanditCamp_01 for PlayerName.`
* `[CombatService] Camp worker placed near outpost at BanditCamp_01 for PlayerName.`
* `[CombatService] Camp worker placed near captured camp fallback at BanditCamp_01 for PlayerName.`
* `[CombatService] PlayerName talked to camp worker at BanditCamp_01.`

Avoid noisy logs on every frame or repeated harmless restore.

## Do not touch

Do not change:

* `default.project.json`
* Rojo mapping
* `src/Workspace`
* R15/R6/avatar/player rig/avatar settings
* unrelated services
* unrelated economy numbers
* forge logic
* storage logic
* workshop logic
* house logic
* resource gathering logic
* advanced combat
* classes
* backpack
* food/fatigue
* passive income
* full worker automation
* jobs/professions
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
6. risks or things to verify manually.

Do not create a PR unless explicitly asked.

## Roblox Studio test checklist

1. Start Play with an existing profile where `BanditCamp_01` is captured and the rescued NPC is already joined.

2. Confirm `CampWorker_BanditCamp_01` appears.

3. Confirm the worker has the visible name tag `Житель лагеря`.

4. Confirm the worker appears near the outpost if the outpost exists.

5. Confirm there is no duplicate rescued NPC near the hostile camp.

6. Confirm there is no duplicate camp worker.

7. Talk to the worker.

8. Confirm the message appears:

   `Житель ждёт поручений. Автоматизация будет доступна позже.`

9. Confirm no resources are added or spent by this interaction.

10. Stop -> Play.

11. Confirm the worker restores correctly.

12. Confirm there are still no duplicate workers or prompts.

13. Confirm the existing combat/capture/outpost loop still works.

14. Check Output for errors.
