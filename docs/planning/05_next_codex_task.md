# MVP 0.4.x — Protect saves from temporary profile overwrite

Continue the GoldenLand Roblox/Rojo project.

## Problem

Sometimes Roblox Studio/DataStore fails to load saved player data because of network/DataStore errors.

Current behavior:
- `PlayerDataService` creates a temporary default profile when `GetAsync` fails.
- The player can continue playing with default values.
- This is dangerous because a temporary default profile may later be saved over the real saved profile.

## Goal

Make temporary profiles read-only and impossible to save.

If saved data fails to load, the game may create a temporary fallback profile for UI/world initialization, but it must never overwrite the real DataStore profile.

## Before changes

1. Run:

```powershell
git status --short