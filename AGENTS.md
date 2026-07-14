# Repository guidance

- This template supports both a backward-compatible root single-place project and opt-in multi-place projects.
- Keep `default.project.json` and `build.project.json` as the root single-place defaults.
- `src/Core`, `src/Client`, and `src/Server` are shared by every place. Do not duplicate them under place folders.
- Put place-specific code in `src/Places/<PlaceName>` and its Rojo projects in `places/<PlaceName>`.
- Every immediate directory under `places/` is discovered automatically and must contain both `default.project.json` and `build.project.json` plus a matching `src/Places/<PlaceName>` tree.
- Development projects map `src`; build projects map generated `dist` output.
- Keep each place isolated: map shared source plus only that place's source, and keep development/build ports equal when both projects declare one.
- Never manually edit or commit `dist`.
- Build with `sh scripts/build.sh [PlaceName]`; generated Roblox files belong in the ignored `builds/` directory.
- `.active-place.project.json` is an ignored, generated sourcemap project; do not commit it.
- Put place-only Services and Controllers in their place's `Systems` directories, not shared folders. Active bootstrap module names must be unique.
- Do not invent `gameId`, `placeId`, `servePlaceIds`, or teleport destination IDs.
- Follow existing architecture and conventions before adding abstractions or dependencies.
- Adding a place must not require edits to dev, analyze, build, validation, or CI scripts.
- After project or script changes, run `sh scripts/validate.sh`. It must cover the root and every discovered place with JSON, Rojo, Darklua, Luau, Selene, and StyLua checks.
