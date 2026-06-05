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

## 2. Current Architecture Notes

Summary of the relevant findings from the architecture audit:

- **PlayerDataService** is the profile owner: schema, load/save, migration,
  normalization, building levels, and the only sender of player stats to UI.
- **CurrencyService** is the resource mutation API for the six resources
  (Gold, Wood, Stone, Metal, MetalIngot, MetalParts).
- **QuestService** owns quest progress, quest state, and quest UI updates.
- **PlotService** is currently too large (~2683 lines) and owns all
  plot/building logic (House, Storage, Workshop, Forge) plus the Action Preview
  server side.
- **WorldService** and **ResourceService** are currently coupled around zone
  state and zone visuals, including a deliberate lazy `require` from
  ResourceService back into WorldService to avoid a load-order cycle.
- **CombatService** currently mixes combat, camp capture, rescued NPC, outpost
  building, and the worker-assignment placeholder in one file.
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
| ForestZoneState | **WorldService AND ResourceService** | **ResourceService (single writer)** | **RISK: overlapping ownership.** Currently written by both services. Must become single-writer (ResourceService as zone-data owner; WorldService reads it for visuals only). High risk for save/restore drift until consolidated. |
| ForestZoneClearedObjects | WorldService, ResourceService | ResourceService | Resource-zone data state. Should follow ForestZoneState to ResourceService. Medium risk. |
| ResourceZones | ResourceService | ResourceService | Resource-zone data state (RemainingActions, Empty, per-object state). Low–Medium risk. |
| CapturedCamps | CombatService | CombatService (combat/capture) | Combat-owned today. Low–Medium risk. |
| CampOutposts | CombatService | CombatService (combat/capture) | Outpost build state. Low–Medium risk. |
| JoinedNPCs | CombatService | CombatService today; **candidate to move to a future NPC/worker service** | NPC recruitment state. Marked for future decomposition. Medium risk. |
| WorkerAssignments | CombatService | CombatService today; **candidate to move to a future NPC/worker service** | Worker placeholder state. Marked for future decomposition. Medium risk. |

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
- CombatService currently owns combat/camp profile fields; future decomposition
  may move `JoinedNPCs` / `WorkerAssignments` (NPC/worker) ownership to a
  separate service.
- **`ForestZoneState` is explicitly flagged as currently risky** because it has
  overlapping ownership between WorldService and ResourceService.

## 4. RemoteEvent Ownership Matrix

| RemoteEvent | Current Sender(s) | Desired Owner | Notes |
|---|---|---|---|
| PlayerStatsUpdateEvent | PlayerDataService (`SendProfileUpdate`) | PlayerDataService | Single sender today and long term. Other services trigger updates by calling PlayerDataService, never by firing directly. Keep as-is. |
| QuestUpdateEvent | QuestService | QuestService | Single sender today and long term. Keep as-is. |
| PlayerMessageEvent | PlotService, WorldService, CombatService, AdminService | Shared message helper (event name unchanged) | Currently fired from multiple services via duplicated local helpers. Future decomposition may centralize sending through one shared helper module **without** changing the event name or message behavior. |
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
| Forge | PlotService | PlotService today; **Forge extract candidate** | Build/upgrade/smelt/parts. Marked for extraction (see section 7, step 4). Must preserve recipes, costs, prompt names, and ActionPreview payload. |
| BanditCamp_01 | CombatService | CombatService | Hostile camp structures + enemy cluster + capture. |
| Training dummy | CombatService | CombatService | First combat target; respawns. |
| Rescued NPC | CombatService | CombatService today; **NPC/worker extract candidate** | Recruitment NPC; tied to `JoinedNPCs`. |
| Camp worker | CombatService | CombatService today; **NPC/worker extract candidate** | `CampWorker_BanditCamp_01`; tied to `JoinedNPCs` / `WorkerAssignments`. |
| Camp outpost | CombatService | CombatService | Built on captured land; tied to `CampOutposts`. |

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

## 7. Recommended Decomposition Order

1. **Centralize remote/message helper** — extract the duplicated
   `getRemoteEvent` / `sendPlayerMessage` boilerplate into one shared module.
   Lowest risk; touches no gameplay state.
2. **Make ForestZoneState ownership single-writer** — give ResourceService sole
   ownership of `ForestZoneState`; WorldService reads it for visuals only.
3. **Remove the ResourceService → WorldService lazy `require`** by using an
   explicit repaint hook (WorldService registers a forest-visual callback;
   ResourceService no longer reaches back up), making the dependency one-way.
4. **Extract Forge logic from PlotService** into a focused module, preserving
   recipes, costs, prompt names, and the ActionPreviewEvent payload contract.
5. **Extract rescued NPC / worker placeholder logic from CombatService** into a
   separate NPC/worker service, moving ownership of `JoinedNPCs` and
   `WorkerAssignments` while leaving combat/capture in CombatService.

**Note:** Steps 2 and 3 must **not** be done in the same task — consolidating
the `ForestZoneState` writer and removing the lazy-require cycle are separate
concerns and combining them would make the change hard to test and review.
