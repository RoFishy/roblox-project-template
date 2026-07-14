#!/bin/sh

set -e

if [ "$#" -gt 1 ]; then
    echo "Usage: sh scripts/dev.sh [PlaceName]" >&2
    exit 1
fi

. scripts/project.sh
resolve_project "${1:-}"

development_project="$DEVELOPMENT_PROJECT"

if [ -n "$PLACE_NAME" ]; then
    write_active_project
    development_project=".active-place.project.json"
fi

prepare_place_dist

if [ "${DEV_DRY_RUN:-}" = "1" ]; then
    printf 'rojo serve %s\n' "$BUILD_PROJECT"
    printf 'rojo sourcemap %s -o sourcemap.json --watch\n' "$development_project"
    printf 'ROBLOX_DEV=true darklua process --config .darklua.json --watch src/ dist/\n'
    exit 0
fi

# If Packages aren't installed, install them.
if [ ! -d "Packages" ]; then
    sh scripts/install-packages.sh
fi

rojo serve "$BUILD_PROJECT" \
    & rojo sourcemap "$development_project" -o sourcemap.json --watch \
    & ROBLOX_DEV=true darklua process --config .darklua.json --watch src/ dist/
