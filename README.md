# Roblox Project Template

A Rojo template that works as either a traditional single-place game or a multi-place Roblox universe. The root workflow remains the default; place projects are opt-in and discovered automatically.

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

```bat
scripts\install-packages.bat
```

The dev, analyze, build, and validation scripts install packages automatically when `Packages` is missing.

## Development

Serve the backward-compatible root project:

```bash
sh scripts/dev.sh
```

```bat
scripts\dev.bat
```

Pass any directory name found under `places/` to select that place. For example:

```bash
sh scripts/dev.sh Lobby
sh scripts/dev.sh Gameplay
```

```bat
scripts\dev.bat Lobby
scripts\dev.bat Gameplay
```

An unknown name exits with a nonzero status and lists every valid place. The selected dev command serves its build project, creates its sourcemap, and watches the shared source plus only the selected place source through Darklua.

## Directory structure

```text
src/
|-- Core/                         shared client/server modules
|-- Client/                       shared client runtime, systems, and modules
|-- Server/                       shared server runtime, systems, and modules
`-- Places/
    |-- Lobby/                    example place source
    `-- Gameplay/                 example place source

places/
|-- Lobby/{default,build}.project.json
`-- Gameplay/{default,build}.project.json
```

The names are examples, not a fixed list. Every immediate directory under `places/` is a place and must contain both project files plus a matching `src/Places/<PlaceName>` source tree.

Shared Services and Controllers stay under `src/Server/Source/Systems` and `src/Client/Source/Systems`. A selected place's systems are mounted beneath those runtime containers in a `Place` folder, so the existing recursive bootstrap lifecycle loads both. Every active Service or Controller must have a unique module name.

Place-specific `Core` modules are available to both client and server under `ReplicatedStorage.Place.Core`. Place client modules live under `ReplicatedStorage.Client.Place.Modules`; place server modules live under `ServerStorage.Place.Modules`. Use the global `@Places` source alias for place code; the existing aliases remain unchanged.

## Adding a place

1. Copy an existing directory such as `places/Lobby` to `places/Tutorial`.
2. Copy its source tree from `src/Places/Lobby` to `src/Places/Tutorial`.
3. Replace the old place name in both new project files, including names, paths, and any development port.
4. Run `sh scripts/validate.sh`.
5. Start it with `sh scripts/dev.sh Tutorial` or `scripts\dev.bat Tutorial`.

No dev, analyze, build, validation, CI, package, or bootstrapper edits are required. Validation fails clearly when a directory under `places/` is missing either project file or its matching source tree.

## Building

Build the root project in production mode:

```bash
sh scripts/build.sh
```

```bat
scripts\build.bat
```

The output is `builds/Game.rbxl`.

Build any discovered place by name:

```bash
sh scripts/build.sh Lobby
sh scripts/build.sh Tutorial
```

```bat
scripts\build.bat Lobby
scripts\build.bat Tutorial
```

Place outputs are written to `builds/<PlaceName>.rbxl`. The scripts install packages when needed, generate the correct sourcemap, run Darklua with `ROBLOX_DEV=false`, and invoke the matching build project. `builds/`, `dist/`, `sourcemap.json`, and `.active-place.project.json` are generated and ignored by Git.

## Analysis and validation

Analyze the root or any discovered place:

```bash
sh scripts/analyze.sh
sh scripts/analyze.sh Lobby
sh scripts/analyze.sh Tutorial
```

Unknown names fail and list the available places. Run the complete repository check with:

```bash
sh scripts/validate.sh
```

Validation discovers every immediate directory under `places/` and checks tracked JSON, root/place isolation, both Rojo projects, production Darklua builds, Luau analysis with the selected sourcemap, Selene, StyLua, shell syntax, invalid-name handling, and the Windows entry points. Zero place directories is valid; an incomplete place directory is not. CI runs the same command.

## Roblox IDs and teleport testing

This public template intentionally contains no `gameId`, `placeId`, `servePlaceIds`, or teleport destination IDs. Add the first three as top-level fields in the appropriate project after creating your Roblox experience. Configure teleport destination IDs explicitly in your own game configuration; do not treat placeholder values as valid.

Rojo and static analysis can validate project structure, but actual teleport behavior must be tested in a published Roblox experience.

## Git expectations

Commit source, project files, scripts, and documentation. Do not commit generated `dist`, `builds`, package directories, sourcemaps, downloaded Luau global types, lock files, or built Roblox place/model files; they are ignored by Git.
