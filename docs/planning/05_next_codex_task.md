# Phase 2.2 — Move joined NPC to player outpost as first camp worker

Continue the GoldenLand Roblox/Rojo project.

This is the next step of Phase 2 (automation through NPCs) from the master plan
in `docs/planning/16_assessment_and_master_plan.md`. It is a **visual/state
foundation only**. Keep the MVP step small.

---

## 1. Current context

Phase 2.1 is implemented, tested, merged into `main`, and pushed. It lives in
`src/ServerScriptService/Services/CombatService.lua` and uses the profile field
`JoinedNPCs` in `src/ServerScriptService/Services/PlayerDataService.lua`.

Implemented Phase 2.1 behavior:

- after `BanditCamp_01` is captured, a `RescuedNPC` appears near the captured camp;
- the rescued NPC carries a `ProximityPrompt`
  (`ObjectText = "Спасённый житель"`, `ActionText = "Поговорить"`,
  `HoldDuration = 0.5`, `MaxActivationDistance = 10`, `RequiresLineOfSight = false`);
- talking to it marks the NPC joined in the player profile (`profile.JoinedNPCs[campId] = true`),
  saves the profile, and sends `"Житель присоединился к вашему лагерю"`;
- once joined, the NPC recolors to green, the tag becomes `"Житель лагеря"`, and the
  talkable prompt is removed;
- on Stop -> Play the state restores: captured-but-not-joined → talkable rescued NPC;
  joined → joined visual with no talkable prompt;
- everything is server-authoritative; there is no passive income and no worker automation.

Relevant existing patterns to reuse (do not reinvent):

- `HOSTILE_CAMP` defines `Id = "BanditCamp_01"`, `Center` (`Vector3.new(0, 0, -95)`),
  and `OutpostOffset` (`Vector3.new(0, 0, 6)`); the outpost is built at
  `camp.Center + camp.OutpostOffset` and parented to the camp model as `Outpost`;
- `CombatService` helpers: `getGroundY(x, z, fallbackY)`, `createPart(...)`,
  `getCampsFolder()`, `sendPlayerMessage(player, text)`,
  `setRescuedNPCNameTag(model, text)`, `setRescuedNPCColor(model, color)`,
  `createRescuedNPCModel(camp)`, `applyTalkableNPCVisual(model, camp)`,
  `applyJoinedNPCVisual(model)`, `showRescuedNPCForProfile(camp, profile, player)`,
  `onCampCleared(campId, attacker)`, `RestoreCampsForPlayer(player)`;
- duplication is guarded with `FindFirstChild` before creating models/prompts;
- profile fields are added in `PlayerDataService` in three places (default, load,
  save) — but this task should reuse `JoinedNPCs` and **not** add a new field
  unless clearly necessary.

---

## 2. Goal

After a rescued NPC joins the player, it should no longer remain only as a generic
joined NPC standing at the hostile camp. Instead, the joined NPC should appear as a
friendly **`CampWorker`** near the player's **built outpost** if the outpost exists.
If the outpost does not exist yet, use a safe **fallback position near the captured
camp**.

This is a visual/state foundation only.

- Do **not** implement passive income yet.
- Do **not** implement full worker automation yet.
- Do **not** implement jobs/professions yet.

---

## 3. Files to inspect

Read before changing code:

- `docs/00_codex_context.md`
- `docs/05_current_state.md`
- `docs/06_development_rules.md`
- `docs/planning/05_next_codex_task.md` (this file)
- `docs/planning/16_assessment_and_master_plan.md`
- `src/ServerScriptService/Services/CombatService.lua`
- `src/ServerScriptService/Services/PlayerDataService.lua`
- `src/ServerScriptService/ServerMain.server.lua`

Inspect the real code as needed to keep field names, helper calls, and offsets accurate.

---

## 4. Detailed implementation requirements

Implement this inside the existing `CombatService` (preferred, since the worker is
tied to capture/join). Do not create a new top-level service unless clearly necessary.

Keep the Phase 2.1 behavior **before** the rescued NPC joins:

- if the camp is **captured but the NPC is not joined**:
  - show the existing talkable rescued NPC near the captured camp (unchanged Phase 2.1 visual + prompt);
- if the NPC **is joined**:
  - do **not** show the generic joined NPC at the camp anymore;
  - instead create a friendly worker visual named **`CampWorker_BanditCamp_01`**;
  - place it near the player's outpost **if the outpost exists**
    (`getCampsFolder():FindFirstChild(camp.Id):FindFirstChild("Outpost")`),
    with a small side offset so it does not overlap the outpost structure;
  - otherwise place it near the **captured camp fallback position**
    (reuse a safe offset from `camp.Center`, e.g. the rescued-NPC area);
  - use the existing ground placement/raycast helper (`getGroundY`) for the Y, not a hardcoded `Y`;
  - build it from primitive parts (body + head), the same no-external-asset style as the rescued NPC;
  - show a visible name tag `"Житель лагеря"` (reuse `setRescuedNPCNameTag` or an equivalent helper);
  - add a `ProximityPrompt` with exactly:

```text
Name                  = "CampWorkerStatusPrompt"
ObjectText            = "Житель лагеря"
ActionText            = "Поговорить"
HoldDuration          = 0.5
MaxActivationDistance = 10
RequiresLineOfSight   = false
```

When the worker prompt is triggered:

- send the message `"Житель ждёт поручений. Автоматизация будет доступна позже."`
  via `sendPlayerMessage`;
- do **not** add or spend any resources from this prompt;
- do **not** change any save state from this prompt (it is informational only).

When the NPC becomes joined (in the talk/join path), the old camp-side joined
`RescuedNPC` visual should be replaced/removed so the same villager is not shown
twice. The single source of truth for the joined villager after this step is the
`CampWorker_BanditCamp_01` model.

---

## 5. Restore behavior

On Stop -> Play (via `RestoreCampsForPlayer` / `showRescuedNPCForProfile` path):

- if the camp is **not captured**:
  - no rescued NPC;
  - no camp worker;
- if the camp is **captured but the NPC is not joined**:
  - restore the talkable rescued NPC (Phase 2.1 behavior);
  - no camp worker;
- if the NPC **is joined**:
  - restore the camp worker near the outpost if the outpost exists;
  - otherwise restore near the captured camp fallback position;
  - do **not** restore the talkable rescued NPC or its prompt;
  - ensure the generic joined `RescuedNPC` visual is not left behind alongside the worker.

---

## 6. Outpost interaction

- The worker placement reads whether the outpost exists from the world
  (`camp` model child `Outpost`), which already mirrors `profile.CampOutposts[camp.Id]`.
- If the player builds the outpost **after** joining, the worker may continue to use
  its current position for this step (no live re-parenting is required), but the
  **restore path must place the worker near the outpost when the outpost exists**.
  Keeping placement correct on restore is sufficient for this MVP step.
- The worker prompt must not build, upgrade, or modify the outpost in any way.

---

## 7. Duplication protection

- At most **one** `RescuedNPC` per camp (existing guard stays).
- At most **one** `CampWorker_BanditCamp_01` per camp — guard with `FindFirstChild`
  before creating.
- No duplicate prompts: at most one `CampWorkerStatusPrompt` on the worker, and the
  talkable rescued prompt must not coexist with the worker.
- Repeated capture, repeated `RestoreCampsForPlayer`, profile reload, admin refresh,
  or Play restart must not create a second NPC, a second worker, or a second prompt.

---

## 8. Server-authoritative rules

- All state changes happen on the server. The client only triggers the
  `ProximityPrompt`; it never decides join or worker state.
- The server owns NPC/worker creation, placement, the join flag, the profile save,
  and the player message.
- The server validates the capture precondition before treating the camp as joined.
- Do not trust any client-sent value for join/capture/worker status.

---

## 9. Save / profile requirements

- Reuse the existing `JoinedNPCs` field; the worker is derived from
  `profile.JoinedNPCs[camp.Id] == true`.
- Do **not** add a new profile field unless clearly necessary. If a new field turns
  out to be unavoidable, add it in all three `PlayerDataService` places (default,
  load, save) and keep old saves safe with a default empty state.
- Old saves must remain safe: a missing `JoinedNPCs` loads as an empty table, never
  `nil`-indexed.
- The state must round-trip: capture → talk → join → worker shown → Stop → Play →
  worker restored (near outpost if it exists, else fallback).

---

## 10. Diagnostic logs

Add concise server `print` logs consistent with existing `[CombatService]` logs, e.g.:

```text
[CombatService] Camp worker placed at <campId> near outpost for <player>.
[CombatService] Camp worker placed at <campId> (fallback, no outpost) for <player>.
[CombatService] Restored camp worker at <campId> for <player>.
```

Logs must make it obvious whether the worker was created near the outpost, created
at the fallback, or restored.

---

## 11. Do-not-touch list

- Do **not** implement passive resource income.
- Do **not** implement full worker automation / building-to-NPC assignment.
- Do **not** implement jobs/professions.
- Do **not** add classes, backpack/inventory, food, fatigue, survival needs, pets,
  advanced combat, raids, or town systems.
- Do **not** change resource gathering, forge/storage/workshop/house logic, or any
  unrelated service.
- Do **not** change Rojo mappings or create `src/Workspace`.
- Do **not** map `Workspace` through Rojo.
- Do **not** edit `default.project.json` unless this task explicitly becomes
  impossible without it.
- Do **not** touch R15/R6/avatar/player rig settings.
- Do **not** make broad refactors.
- Keep the MVP step small; prefer extending `CombatService` and reusing the existing
  `JoinedNPCs` flow.

---

## 12. Expected final response format

At the end of the implementation task, provide:

1. `git status --short` result from **before** changes.
2. Files changed.
3. Short summary of what was implemented (joined NPC → `CampWorker` near outpost / fallback).
4. Diff summary.
5. Confirmation that the existing `JoinedNPCs` field was reused (or, if a new field
   was unavoidable, its name and how old saves stay safe).
6. Confirmation that all state changes are server-authoritative.
7. Confirmation that duplication is prevented (one rescued NPC, one camp worker, no
   duplicate prompts) on repeated capture/restore.

---

## 13. Roblox Studio test checklist

1. On a profile where `BanditCamp_01` is captured but the NPC is not joined yet,
   confirm the talkable `RescuedNPC` still appears (Phase 2.1 unchanged).
2. Talk to the rescued NPC; confirm it joins and a `CampWorker_BanditCamp_01`
   appears with the tag `Житель лагеря` and a `CampWorkerStatusPrompt`
   (`Житель лагеря` / `Поговорить`).
3. With an outpost built, confirm the worker stands near the outpost (not inside it).
4. Trigger the worker prompt; confirm the message
   `"Житель ждёт поручений. Автоматизация будет доступна позже."` appears and that
   no resources change.
5. Stop -> Play; confirm the worker is restored (near outpost if it exists, else the
   camp fallback), with no talkable rescued prompt and no duplicate NPC/worker.
6. On a clean profile (camp not captured), confirm there is no rescued NPC and no
   camp worker before capture.
7. Re-run capture/restore paths (rejoin, admin refresh if available); confirm no
   duplicate `RescuedNPC`, no duplicate `CampWorker_BanditCamp_01`, and no duplicate prompts.
8. Confirm DataStore errors in Studio do not break startup, and the rest of the
   Phase 1 loop (combat, capture, outpost) and Phase 2.1 (rescue/join) still work.

## Before changes

1. Run:

```powershell
git status --short
```

2. If the working tree is not clean, stop and report the status.
3. Read the files listed in section 3.
