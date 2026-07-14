# Repository guidance

- This template supports both a backward-compatible root single-place project and opt-in multi-place projects.
- Keep `default.project.json` and `build.project.json` as the root single-place defaults.
- `src/Core`, `src/Client`, and `src/Server` are shared by every place. Do not duplicate them under place folders.
- Put place-specific code in `src/Places/<PlaceName>` and its Rojo projects in `places/<PlaceName>`.
- Development projects map `src`; build projects map generated `dist` output.
- Never manually edit or commit `dist`.
- `.active-place.project.json` is an ignored, generated sourcemap project; do not commit it.
- Put place-only Services and Controllers in their place's `Systems` directories, not shared folders. Active bootstrap module names must be unique.
- Do not invent `gameId`, `placeId`, `servePlaceIds`, or teleport destination IDs.
- Follow existing architecture and conventions before adding abstractions or dependencies.
- After project or script changes, run `sh scripts/validate.sh`. At minimum, validate all Rojo projects, Darklua, Luau analysis, Selene, StyLua, and JSON.
