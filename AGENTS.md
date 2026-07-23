# Repository guidance

- This template ships with zero optional places. Zero places is valid; do not add example places by default.
- Keep the root no-argument development, build, and analysis commands backward-compatible.
- Create places with `scripts/create-place.sh` or `scripts/create-place.bat`.
- Places are discovered dynamically. Never hardcode place names into scripts or CI.
- Every place requires `places/<PlaceName>/default.project.json`, `places/<PlaceName>/build.project.json`, and `src/Places/<PlaceName>`.
- Shared source belongs in `src/Core`, `src/Client`, and `src/Server`. Place-only source belongs in `src/Places/<PlaceName>`.
- Process shared source plus only the selected place. Never process unselected place source against a selected sourcemap.
- Keep place development and build ports equal. Do not invent `gameId`, `placeId`, `servePlaceIds`, or teleport IDs.
- Put place-only Services and Controllers in their place `Systems` directories. Active bootstrap module names must be unique.
- Do not commit generated `dist`, `builds`, packages, sourcemaps, active projects, global types, or temporary processing layouts.
- Run `sh scripts/validate.sh` after changing project architecture or scripts.
