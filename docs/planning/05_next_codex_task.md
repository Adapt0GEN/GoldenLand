# Phase 2.1 — Rescued NPC joins the camp

Continue the GoldenLand Roblox/Rojo project.

This is the first step of Phase 2 (automation through NPCs) from the master plan
in `docs/planning/16_assessment_and_master_plan.md`. It only lays the **foundation**
for future NPC workers. Keep the MVP step small.

---

## 1. Current context

Phase 1 (island capture loop) is implemented and tested. It lives mostly in
`src/ServerScriptService/Services/CombatService.lua`:

- player receives a basic sword `Tool` in `Backpack` on spawn;
- left mouse attack (`Tool.Activated`) runs a server-side hitbox and damages enemies;
- enemies use their own HP system (attributes `Health`/`MaxHealth` + `BillboardGui` bar);
- killing an enemy rewards Gold from the server;
- hostile camp `BanditCamp_01` exists in the world (folder `Workspace.Camps`);
- after all camp enemies are defeated, the camp is captured: friendly visual,
  bonus Gold, player message;
- capture persists in the player profile field `CapturedCamps` and is restored on
  rejoin via `CombatService.RestoreCampsForPlayer` (called from `ServerMain`);
- on captured land an `OutpostBuildSpot` marker with a `ProximityPrompt` appears;
- building an outpost spends resources server-side through
  `CurrencyService.SpendResources` and persists via the profile field `CampOutposts`;
- the built outpost is restored on rejoin.

Relevant existing patterns to reuse (do not reinvent):

- profile fields are added in `PlayerDataService` in three places: the default
  profile table, the saved-profile load path, and the public/save serialization
  (the same way `CapturedCamps` and `CampOutposts` were added);
- `CombatService` already has helpers: `getGroundY(x, z, fallbackY)` (downward
  raycast placement), `createPart(...)`, `createTextSign(...)`, `sendPlayerMessage(player, text)`
  (fires `ReplicatedStorage.Remotes.PlayerMessageEvent`), `getCampsFolder()`,
  `showOutpostForProfile(camp, profile)`, `onCampCleared(campId, attacker)`,
  `RestoreCampsForPlayer(player)`;
- `HOSTILE_CAMP` defines `Id = "BanditCamp_01"`, `Center`, and `OutpostOffset`.

---

## 2. Goal

After the hostile camp is captured, a **rescued NPC** appears near the captured
camp or outpost. The player can talk to this NPC through a `ProximityPrompt`.
After the interaction the NPC **joins the player's camp**. This joined state must
be **saved and restored** across Stop -> Play.

This is the foundation for future NPC workers — nothing more.

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
- `src/ServerScriptService/Services/CurrencyService.lua`
- `src/ServerScriptService/ServerMain.server.lua`

Inspect the real code as needed to keep field names and helper calls accurate.

---

## 4. Detailed implementation requirements

Implement this inside the existing `CombatService` (preferred, since rescue is
tied to capture) — do not create a new top-level service unless clearly necessary.

### NPC creation

- After a camp is captured (in the capture path `onCampCleared`, and in the
  restore path `RestoreCampsForPlayer` / `showOutpostForProfile`), create a
  `RescuedNPC` model near the captured camp or its outpost.
- Place the NPC on the ground using the existing `getGroundY` raycast, not a
  hardcoded `Y`. A small offset from `camp.Center` / `camp.OutpostOffset` is fine
  (place it so it does not overlap the outpost or build spot).
- Build the NPC from primitive parts (body + head), the same no-external-asset
  style as enemies and signs. Give it an obvious friendly color and a name tag
  (`BillboardGui` or `createTextSign`) is optional but helpful.
- **Availability gate:** if the player has **not** captured the camp yet, the
  rescued NPC must **not** be available/created. Capture is the precondition.

### ProximityPrompt

The NPC must carry a `ProximityPrompt` with exactly:

```text
ObjectText          = "Спасённый житель"
ActionText          = "Поговорить"
HoldDuration        = 0.5
MaxActivationDistance = 10
RequiresLineOfSight = false
```

### Talk / join interaction

When the player triggers the prompt:

- verify on the server that the player has captured the relevant camp
  (`profile.CapturedCamps[campId]`); if not, ignore or send a short refusal message;
- mark the NPC as joined in the player profile (see section 6);
- save/update the profile (mark dirty + save, same pattern as capture/outpost);
- send a player message: `"Житель присоединился к вашему лагерю"` via `sendPlayerMessage`;
- update or remove the NPC visual so it is clearly joined — e.g. remove the
  `ProximityPrompt`, recolor the NPC, change/remove the tag, or move it to an
  "assigned" pose. The key requirement: it must be visually clear he has joined
  and he must not be re-talkable.

### Restore on rejoin

- On Stop -> Play, the joined NPC state must persist.
- In the restore path, reconstruct the world to match the saved state:
  - if the NPC has **not** joined yet but the camp is captured → show the
    talkable rescued NPC with its prompt;
  - if the NPC **has** joined → show the joined/assigned visual and do **not**
    create a talkable prompt.

---

## 5. Save / profile requirements

- Add a new saved profile field for rescued/joined NPC state, for example
  `JoinedNPCs` or `RescuedWorkers` (a table keyed by camp id or npc id, e.g.
  `profile.JoinedNPCs[campId] = true`, mirroring `CapturedCamps`/`CampOutposts`).
- Add it in all three `PlayerDataService` places: default profile, saved-profile
  load, and public/save serialization (use the existing `copyTable`/deepCopy helper).
- **Old saves must work safely** with a default empty state: missing field loads
  as an empty table, never `nil`-indexed.
- The joined state must round-trip: capture → talk → join → Stop → Play → still joined.

---

## 6. Server-authoritative rules

- All state changes happen on the server. The client only triggers the
  `ProximityPrompt`; it never decides join state.
- The server validates the capture precondition before allowing a join.
- The server owns NPC creation, the join flag, profile save, and the player message.
- Do not trust any client-sent value for join/capture status.

---

## 7. Duplication protection

- Do not create duplicate `RescuedNPC` models on repeated capture, repeated
  `RestoreCampsForPlayer`, profile reload, admin refresh, or Play restart
  (guard with `FindFirstChild` before creating, like the existing camp/outpost code).
- If already joined (`profile.JoinedNPCs[campId] == true`), do **not** allow a
  second join and do **not** spawn a second NPC or a second prompt.
- The talkable prompt must exist at most once per rescued NPC.

---

## 8. Diagnostic logs

Add concise server `print` logs consistent with existing `[CombatService]` logs, e.g.:

```text
[CombatService] Rescued NPC available at <campId> for <player>.
[CombatService] <player> recruited rescued NPC at <campId>.
[CombatService] Restored joined NPC at <campId> for <player>.
```

Logs must make it obvious whether the NPC was created, joined, or restored.

---

## 9. Do-not-touch list

- Do **not** implement passive resource income yet.
- Do **not** implement full worker automation / building-to-NPC assignment yet.
- Do **not** add classes, backpack/inventory UI, food, fatigue, survival needs,
  pets, advanced combat, raids, or town systems.
- Do **not** change Rojo mappings or create `src/Workspace`.
- Do **not** map `Workspace` through Rojo.
- Do **not** edit `default.project.json` unless this task explicitly becomes
  impossible without it.
- Do **not** touch R15/R6/avatar/player rig settings.
- Do **not** make broad refactors or change unrelated systems.
- Keep the MVP step small; prefer extending `CombatService` and the existing
  profile flow.

---

## 10. Expected final response format

At the end of the implementation task, provide:

1. `git status --short` result from **before** changes.
2. Files changed.
3. Short summary of what was implemented (rescued NPC + join + persistence).
4. Diff summary.
5. New/changed profile field name and how old saves stay safe.
6. Confirmation that all state changes are server-authoritative.
7. Confirmation that duplication is prevented on repeated capture/restore.

---

## 11. Roblox Studio test checklist

1. Capture `BanditCamp_01` by defeating all camp enemies.
2. Confirm a `RescuedNPC` appears near the captured camp/outpost with a
   `ProximityPrompt` showing `Спасённый житель` / `Поговорить`.
3. Confirm the NPC does **not** appear before the camp is captured.
4. Trigger the prompt; confirm:
   - the message `"Житель присоединился к вашему лагерю"` appears;
   - the NPC visual updates/removes so it is clearly joined;
   - the prompt can no longer be triggered again.
5. Stop -> Play; confirm the joined NPC state persists (NPC shown as joined,
   no talkable prompt, no duplicate NPC).
6. Re-run capture/restore paths (rejoin, admin refresh if available); confirm no
   duplicate `RescuedNPC` and no duplicate prompt.
7. Confirm DataStore errors in Studio do not break startup, and the rest of the
   Phase 1 loop (combat, capture, outpost) still works.

## Before changes

1. Run:

```powershell
git status --short
```

2. If the working tree is not clean, stop and report the status.
3. Read the files listed in section 3.
