# Service Ownership Map — GoldenLand

## 1. Purpose

This document defines ownership rules for **profile fields**, **RemoteEvents**,
**world objects**, and **service responsibilities** in the GoldenLand server
service-core. It exists to establish a single source of truth for "who owns
what" *before* any future decomposition work begins.

It is a **planning / architecture document only**. It does not change code,
gameplay behavior, the profile schema, RemoteEvent names, or Rojo mapping.
It records the *current* writers of each piece of state, the *desired* long-term
owner, and the risks that future extract-only refactors must respect.

Use this map as the contract that the decomposition tasks (see section 7)
implement against.

**Status (updated):** all five decomposition steps in section 7 are now
implemented, tested in Roblox Studio, and merged into `main`. The matrices below
reflect the **post-decomposition** ownership: `RemoteService`, `ForgeRules`, and
`CampNPCService` exist; `ForestZoneState` is single-writer at runtime; and the
`ResourceService -> WorldService` lazy require has been replaced by a repaint
callback wired in `ServerMain`.

## 2. Current Architecture Notes

Summary of the relevant findings from the architecture audit:

- **PlayerDataService** is the profile owner: schema, load/save, migration,
  normalization, building levels, and the only sender of player stats to UI.
- **CurrencyService** is the resource mutation API for the six resources
  (Gold, Wood, Stone, Metal, MetalIngot, MetalParts).
- **QuestService** owns quest progress, quest state, and quest UI updates.
- **PlotService** still owns plot/building visuals, prompts, restore, and the
  Action Preview server side (House, Storage, Workshop, Forge). Forge
  constants, costs, recipes, and validation now live in **ForgeRules**, a
  one-way helper that PlotService requires; PlotService keeps Forge visuals,
  prompts, restore, and Action Preview dispatch.
- **ResourceService** is now the single runtime writer of `ForestZoneState`;
  **WorldService** reads that state and renders zone visuals. The previous lazy
  `require(WorldService)` from ResourceService has been replaced by a forest
  visual repaint callback that ResourceService registers and requests, wired by
  **ServerMain** (one-way dependency).
- **CombatService** keeps combat, enemy HP, hitbox, hostile camp spawning, camp
  capture, outpost construction, and the training dummy. The rescued NPC, camp
  worker, worker-assignment placeholder, and their restore logic now live in
  **CampNPCService** (one-way dependency `CombatService -> CampNPCService`).
- **RemoteService** centralizes RemoteEvent access (`ReplicatedStorage/Remotes`)
  and player message sending; services no longer duplicate that boilerplate.
- **ClientMain** is currently a monolithic UI script that builds all GUI inline
  and listens to all four RemoteEvents.

## 3. Profile Field Ownership Matrix

| Profile Field / Area | Current Writer(s) | Desired Owner | Notes / Risk |
|---|---|---|---|
| Gold | CurrencyService | CurrencyService | Only mutation API for resource amounts. Low risk. |
| Wood | CurrencyService | CurrencyService | Same as above. Low risk. |
| Stone | CurrencyService | CurrencyService | Same as above. Low risk. |
| Metal | CurrencyService | CurrencyService | Same as above. Low risk. |
| MetalIngot | CurrencyService | CurrencyService | Forge output; still routed through CurrencyService. Low risk. |
| MetalParts | CurrencyService | CurrencyService | Forge output; still routed through CurrencyService. Low risk. |
| CurrentQuestId | QuestService | QuestService | Quest state. Low risk. |
| CompletedQuests | QuestService | QuestService | Quest state. Low risk. |
| QuestProgress | QuestService | QuestService | Quest state. Low risk. |
| PlotUnlocked | PlotService (and NPCService via `PlotService.UnlockPlot`) | PlotService | Plot lifecycle. NPCService triggers it through PlotService's public API, not direct write. Low–Medium risk. |
| ToolKitLevel | PlotService | PlotService | Set during workshop tool crafting. Low risk. |
| Buildings (House/Storage/Workshop/Forge levels) | PlotService (via `PlayerDataService.SetBuildingLevel`) | PlotService | Building progression. Persistence helpers live in PlayerDataService; building *policy* stays in PlotService. Medium risk (large file). |
| ForestUnlocked | WorldService | WorldService | Zone gate flag. Low–Medium risk. |
| RockZoneUnlocked | WorldService | WorldService | Zone gate flag. Low–Medium risk. |
| ForestZoneState | **ResourceService** (runtime); PlayerDataService (load-time normalization) | ResourceService (single writer) | **RESOLVED:** single-writer at runtime. ResourceService is the only runtime writer; WorldService reads it for visuals only; PlayerDataService normalizes it on load/save. |
| ForestZoneClearedObjects | ResourceService (runtime); PlayerDataService (load-time normalization) | ResourceService | Resource-zone data state; follows ForestZoneState. WorldService only reads / defensively initializes. |
| ResourceZones | ResourceService | ResourceService | Resource-zone data state (RemainingActions, Empty, per-object state). Low–Medium risk. |
| CapturedCamps | CombatService | CombatService (combat/capture) | Combat-owned. Capture writes stay in CombatService. Low–Medium risk. |
| CampOutposts | CombatService | CombatService (combat/capture) | Outpost build state. Capture/outpost writes stay in CombatService. Low–Medium risk. |
| JoinedNPCs | **CampNPCService** | CampNPCService (NPC/worker runtime) | NPC recruitment state. Moved out of CombatService; CampNPCService owns runtime recruitment/restore logic. |
| WorkerAssignments | **CampNPCService** | CampNPCService (NPC/worker runtime) | Worker placeholder state. Moved out of CombatService; CampNPCService owns the assignment placeholder. |

**Ownership rules applied above:**

- PlayerDataService owns profile load/save/schema/normalization and the
  building-level get/set helpers; it does **not** own gameplay policy for any
  field.
- CurrencyService is the only mutation API for resource amounts.
- QuestService owns quest state.
- PlotService currently owns plot/building state.
- ResourceService should own resource-zone *data* state (`ResourceZones`,
  `ForestZoneState`, `ForestZoneClearedObjects`).
- WorldService should own world/zone *visuals* and *gates*, but should **not**
  be a long-term owner of resource-zone data state.
- CombatService owns the combat/capture profile fields (`CapturedCamps`,
  `CampOutposts`); the NPC/worker runtime fields (`JoinedNPCs`,
  `WorkerAssignments`) are now owned by **CampNPCService**.
- **`ForestZoneState` overlap is resolved:** ResourceService is the sole runtime
  writer; WorldService reads it for visuals only; PlayerDataService keeps
  load/save normalization.
- **RemoteService** owns shared RemoteEvent access and player message sending;
  **ForgeRules** owns Forge constants/costs/recipes/validation only (no state of
  its own beyond read-only rule tables).

## 4. RemoteEvent Ownership Matrix

| RemoteEvent | Current Sender(s) | Desired Owner | Notes |
|---|---|---|---|
| PlayerStatsUpdateEvent | PlayerDataService (`SendProfileUpdate`) | PlayerDataService | Single sender today and long term. Other services trigger updates by calling PlayerDataService, never by firing directly. Keep as-is. |
| QuestUpdateEvent | QuestService | QuestService | Single sender today and long term. Keep as-is. |
| PlayerMessageEvent | **RemoteService** (`SendPlayerMessage`) | RemoteService (shared helper; event name unchanged) | Centralized: services request messages through `RemoteService.SendPlayerMessage` instead of duplicated local helpers. The event name and message behavior are unchanged. |
| ActionPreviewEvent | PlotService (server side; ClientMain fires show/hide) | PlotService today | Owned by PlotService. Future building decomposition (e.g. extracting Forge) **must preserve the exact same payload contract** so ClientMain keeps working unchanged. |

## 5. World Object Ownership Matrix

| World Object / System | Current Creator | Desired Owner | Notes |
|---|---|---|---|
| Start world / ground / signs | WorldService | WorldService | Built once at boot via `CreateStartWorld`. |
| Village Elder | NPCService | NPCService | Elder model + talk prompt; orchestrates quest handoff. |
| Starter resource nodes | ResourceService | ResourceService | Created via `CreateResourceNodes` at boot. |
| ForestZone visuals | WorldService | WorldService | Zone scene + state visuals (Active/Medium/Low/Empty). |
| ForestZone resource nodes | ResourceService | ResourceService | Created via `CreateForestZoneResources`; data state in `ResourceZones`. |
| RockZone visuals | WorldService | WorldService | Zone scene + access pass. |
| RockZone resource nodes | ResourceService | ResourceService | `RichStoneNode` / `MetalVein` via `CreateRockZoneResources`. |
| Player plot | PlotService | PlotService | `CreateTestPlot`, restore/cleanup. |
| House | PlotService | PlotService | Build/upgrade + visuals + prompts. |
| Storage | PlotService | PlotService | Build/upgrade + visuals + prompts. |
| Workshop | PlotService | PlotService | Build + tool crafting + visuals + prompts. |
| Forge | PlotService (visuals/prompts/restore) + ForgeRules (rules) | PlotService (visuals/prompts/restore/ActionPreview); ForgeRules (costs/recipes/validation) | Build/upgrade/smelt/parts. Forge economy rules extracted to **ForgeRules**; PlotService keeps the visual model, prompts, restore, and the ActionPreview payload contract. |
| BanditCamp_01 | CombatService | CombatService | Hostile camp structures + enemy cluster + capture. |
| Training dummy | CombatService | CombatService | First combat target; respawns. |
| Rescued NPC | **CampNPCService** | CampNPCService | Recruitment NPC creation/restore/prompt; tied to `JoinedNPCs`. Moved out of CombatService. |
| Camp worker | **CampNPCService** | CampNPCService | `CampWorker_BanditCamp_01` creation/restore + status prompt + assignment placeholder; tied to `JoinedNPCs` / `WorkerAssignments`. Moved out of CombatService. |
| Camp outpost | CombatService | CombatService | Built on captured land; tied to `CampOutposts`. Capture/outpost remain in CombatService. |

## 6. Decomposition Guardrails

Rules every future refactoring task must follow:

- Keep MVP behavior unchanged.
- Do not change profile field names unless explicitly planned (with migration).
- Do not change RemoteEvent names.
- Do not change the ActionPreviewEvent payload shape.
- Do not change save/load behavior.
- Do not move multiple systems in one task.
- Prefer extract-only refactors (move code without altering logic).
- Each decomposition task must have a Roblox Studio test checklist.
- Keep PlayerDataService stable (no changes to persistence internals or schema).
- Keep CurrencyService as the resource mutation API.

## 7. Decomposition Order (completed)

All five steps below are implemented, tested in Roblox Studio, and merged.

1. **[DONE] Centralize remote/message helper** — duplicated
   `getRemoteEvent` / `sendPlayerMessage` boilerplate extracted into
   `RemoteService.lua`; services use it instead of local copies.
2. **[DONE] Make ForestZoneState ownership single-writer** — ResourceService is
   the sole runtime writer of `ForestZoneState`; WorldService reads it for
   visuals only.
3. **[DONE] Remove the ResourceService → WorldService lazy `require`** — replaced
   by a forest visual repaint callback. ResourceService exposes
   `SetForestVisualUpdateCallback` and requests repaint; **ServerMain** wires it
   to `WorldService.UpdateForestAreaVisual`, making the dependency one-way.
4. **[DONE] Extract Forge logic from PlotService** into `ForgeRules.lua`,
   preserving recipes, costs, prompt names, and the ActionPreviewEvent payload
   contract; PlotService keeps Forge visuals/prompts/restore/dispatch.
5. **[DONE] Extract rescued NPC / worker placeholder logic from CombatService**
   into `CampNPCService.lua`, moving runtime ownership of `JoinedNPCs` and
   `WorkerAssignments` while leaving combat/capture/outpost in CombatService.

**Note:** Steps 2 and 3 must **not** be done in the same task — consolidating
the `ForestZoneState` writer and removing the lazy-require cycle are separate
concerns and combining them would make the change hard to test and review.
