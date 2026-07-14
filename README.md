# Roblox Project Template

A Rojo template that works as either a traditional single-place game or a multi-place Roblox universe. The root workflow remains the default; multi-place projects are opt-in.

## Requirements

- Roblox Studio with the Rojo plugin
- [Aftman](https://github.com/LPGhatguy/aftman) for the pinned Rojo, Wally, Darklua, Luau LSP, Selene, and StyLua tools
- Git and `curl`
- Python 3 for the complete validation script

Install the pinned tools with `aftman install`.

## Package installation

Dependencies are shared by every place. Install them once from the repository root:

```bash
sh scripts/install-packages.sh
```

On Windows:

```bat
scripts\install-packages.bat
```

The development and analysis scripts install packages automatically when `Packages` is missing.

## Single-place quick start

The root project files preserve the original workflow:

```bash
sh scripts/dev.sh
```

```bat
scripts\dev.bat
```

These commands serve `build.project.json`, generate `sourcemap.json` from `default.project.json`, and watch the complete `src` tree with Darklua.

## Multi-place quick start

Select one of the example places by name:

```bash
sh scripts/dev.sh Lobby
sh scripts/dev.sh Gameplay
```

```bat
scripts\dev.bat Lobby
scripts\dev.bat Gameplay
```

Lobby uses port `34872`; Gameplay uses port `34873`. An unknown name exits with an error and lists the available places.

## Directory structure

```text
src/
|-- Core/                  shared client/server modules
|-- Client/                shared client runtime, systems, and modules
|-- Server/                shared server runtime, systems, and modules
`-- Places/
    |-- Lobby/
    |   |-- Core/          place modules shared by client and server
    |   |-- Client/{Systems,Modules}/
    |   `-- Server/{Systems,Modules}/
    `-- Gameplay/          same place-specific layout

places/
|-- Lobby/{default,build}.project.json
`-- Gameplay/{default,build}.project.json
```

Shared Services and Controllers stay under `src/Server/Source/Systems` and `src/Client/Source/Systems`. A selected place's systems are mounted beneath those same runtime containers in a `Place` folder, so the existing recursive bootstrap lifecycle loads both. Every active Service or Controller must have a unique module name.

Place-specific `Core` modules are available to both client and server under `ReplicatedStorage.Place.Core`. Place client modules live under `ReplicatedStorage.Client.Place.Modules`; place server modules live under `ServerStorage.Place.Modules`. Use the global `@Places` source alias for place code; existing `@Core`, `@Client`, `@Server`, `@Packages`, and `@ServerPackages` aliases are unchanged.

## Adding a place

1. Copy `places/Lobby` to `places/<PlaceName>`.
2. Copy `src/Places/Lobby` to `src/Places/<PlaceName>`.
3. Replace `Lobby` in both copied project files, including names, paths, and the development port.
4. Add real place code only where needed and run `sh scripts/dev.sh <PlaceName>`.

No additional package installation or bootstrapper is required.

## Building

First generate `dist` using the sourcemap for the project being built:

```bash
rojo sourcemap default.project.json -o sourcemap.json
ROBLOX_DEV=false darklua process --config .darklua.json src/ dist/
rojo build build.project.json -o Game.rbxl
```

For a selected place, use its development sourcemap and build project:

```bash
mkdir -p \
    dist/Places/Lobby/Core \
    dist/Places/Lobby/Client/Systems \
    dist/Places/Lobby/Client/Modules \
    dist/Places/Lobby/Server/Systems \
    dist/Places/Lobby/Server/Modules
sed 's#\.\./\.\./##g' places/Lobby/default.project.json >.active-place.project.json
rojo sourcemap .active-place.project.json -o sourcemap.json
ROBLOX_DEV=false darklua process --config .darklua.json src/ dist/
rojo build places/Lobby/build.project.json -o Lobby.rbxl
```

Replace `Lobby` with another place name as needed.

The selected development scripts generate the ignored `.active-place.project.json` with paths rebased to the repository root. This keeps Rojo 7.5.1 sourcemaps compatible with Darklua while the tracked project under `places/<PlaceName>` remains the source of truth.

## Analysis and validation

Analyze the root or one selected place:

```bash
sh scripts/analyze.sh
sh scripts/analyze.sh Lobby
sh scripts/analyze.sh Gameplay
```

Run every project, JSON, Darklua, Luau, Selene, and StyLua check with:

```bash
sh scripts/validate.sh
```

CI runs the same complete validation without Roblox Studio.

## Roblox IDs and teleport testing

This public template intentionally contains no `gameId`, `placeId`, `servePlaceIds`, or teleport destination IDs. Add the first three as top-level fields in the appropriate place project after creating your Roblox experience. Configure teleport destination IDs explicitly in your own game configuration; do not treat placeholder values as valid.

Rojo and static analysis can validate project structure, but actual teleport behavior must be tested in a published Roblox experience.

## Git expectations

Commit source, project files, and documentation. Do not commit generated `dist`, package directories, sourcemaps, downloaded Luau global types, lock files, or built Roblox place/model files; they are ignored by Git.
