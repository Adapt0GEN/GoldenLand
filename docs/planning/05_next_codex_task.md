# MVP 0.4.x — Add pending save flush for rapid profile changes

Continue the GoldenLand Roblox/Rojo project.

## Problem

Fast repeated player actions can change the profile several times in a short period.

Current behavior seen in logs:
- first action starts saving;
- following actions may print `Skipped duplicate save`;
- profile values are updated in memory and UI, but the latest values must be guaranteed to be saved later.

This is especially important for forge actions:
- smelting MetalIngot several times quickly;
- making MetalParts several times quickly.

## Goal

Improve `PlayerDataService` save behavior so rapid profile changes are not lost.

If `SaveProfile(player)` is called while a save for that player is already in progress, the service should not start another immediate DataStore write. Instead, it should mark that player as needing another save after the current save finishes.

## Before changes

1. Run:

```powershell
git status --short