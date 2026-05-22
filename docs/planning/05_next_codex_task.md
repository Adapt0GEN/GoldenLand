# MVP 0.4.x — Add quest step for building Storage

Continue the GoldenLand Roblox/Rojo project.

## Goal

Add a simple guided quest step that teaches the player to build Storage after they already have a house.

This is the beginning of the camp development quest chain.

## Current context

The project already has:
- player profile save/load;
- resources: Gold, Wood, Stone, Metal;
- processed resources: MetalIngot, MetalParts;
- HouseLevel;
- StorageLevel;
- ToolKitLevel;
- ForgeLevel;
- workshop/forge systems;
- admin commands;
- temporary profile save protection;
- pending save flush for rapid profile changes.

## Design direction

The early game should guide the player through camp development:

1. basic resources;
2. house;
3. storage;
4. tools;
5. forest unlock;
6. rock zone;
7. forge.

This task only adds the Storage quest step. Do not implement the full chain yet.

## Before changes

1. Run:

```powershell
git status --short