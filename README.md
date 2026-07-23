# Roblox Project Template

A Rojo template that works as a traditional single-place game or an opt-in multi-place Roblox universe. It ships with zero optional places; the root workflow remains the default.

## Requirements

- Roblox Studio with the Rojo plugin
- [Aftman](https://github.com/LPGhatguy/aftman) for the pinned tools
- Git and `curl`
- Python 3 for the complete validation script

Install the tools with `aftman install`. Development, analysis, build, and validation install Wally packages automatically when needed.

## Root single-place development

```bat
scripts\dev.bat
```

```bash
sh scripts/dev.sh
```

This uses the root `default.project.json` and `build.project.json` and processes only shared source in `src/Core`, `src/Client`, and `src/Server`.

## Create a local place project

```bat
scripts\create-place.bat Gameplay
```

```bash
sh scripts/create-place.sh Gameplay
```

The command creates the complete `src/Places/Gameplay` source tree, both Rojo project files under `places/Gameplay`, and assigns the first available development port starting at `34872`.

An explicit unused port is optional:

```bat
scripts\create-place.bat Gameplay 34900
```

```bash
sh scripts/create-place.sh Gameplay 34900
```

Places are discovered dynamically. No development, build, analysis, validation, or CI file needs editing after adding one.

## Develop a place

```bat
scripts\dev.bat Gameplay
```

```bash
sh scripts/dev.sh Gameplay
```

The selected workflow processes shared source plus only `src/Places/Gameplay`.

## Build

Build the root project:

```bat
scripts\build.bat
```

```bash
sh scripts/build.sh
```

Output: `builds/Game.rbxl`

Build a place:

```bat
scripts\build.bat Gameplay
```

```bash
sh scripts/build.sh Gameplay
```

Output: `builds/Gameplay.rbxl`

## Analyze

```bash
sh scripts/analyze.sh
sh scripts/analyze.sh Gameplay
```

## Validate everything

```bash
sh scripts/validate.sh
```

Validation starts from zero optional places, exercises place creation and port assignment, checks root/place isolation, builds and analyzes the root and generated places, and runs JSON, Rojo, Darklua, Luau, Selene, StyLua, shell, and Windows entry-point checks.

## Source layout

```text
src/
|-- Core/                         shared client/server modules
|-- Client/                       shared client runtime, systems, and modules
|-- Server/                       shared server runtime, systems, and modules
`-- Places/                       optional place-only source

places/                           optional place Rojo projects
```

Shared Services and Controllers stay under `src/Server/Source/Systems` and `src/Client/Source/Systems`. Place-only systems are mounted beneath those shared `Systems` containers, so the existing recursive Bootstrapper loads both. Active Service and Controller module names must be unique.

Place-specific Core modules are mounted at `ReplicatedStorage.Place.Core`, client modules at `ReplicatedStorage.Client.Place.Modules`, and server modules at `ServerStorage.Place.Modules`. The `@Places` alias is available to place code.

## Roblox cloud places

`create-place` creates local repository structure only. It does not create a Roblox cloud place.

Create the real place inside the same Roblox experience through Studio or Creator Dashboard. You may then add the real `gameId`, `placeId`, and `servePlaceIds` to its generated project files. Configure real teleport destinations in your game and test teleport behavior in a published experience.

Generated `dist`, `builds`, package directories, sourcemaps, active projects, and global types are ignored and must not be committed.
