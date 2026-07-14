#!/bin/sh

set -e

if [ "$#" -gt 1 ]; then
    echo "Usage: sh scripts/build.sh [PlaceName]" >&2
    exit 1
fi

. scripts/project.sh
resolve_project "${1:-}"

sourcemap_project="$DEVELOPMENT_PROJECT"

if [ -n "$PLACE_NAME" ]; then
    write_active_project
    sourcemap_project=".active-place.project.json"
    trap 'rm -f .active-place.project.json' EXIT HUP INT TERM
fi

if [ ! -d "Packages" ]; then
    sh scripts/install-packages.sh
fi

prepare_place_dist

if [ -n "${BUILD_OUTPUT:-}" ]; then
    output_path="$BUILD_OUTPUT"
elif [ -n "$PLACE_NAME" ]; then
    output_path="builds/$PLACE_NAME.rbxl"
else
    output_path="builds/Game.rbxl"
fi

mkdir -p "$(dirname "$output_path")"
rojo sourcemap "$sourcemap_project" -o sourcemap.json
ROBLOX_DEV=false darklua process --config .darklua.json src/ dist/
rojo build "$BUILD_PROJECT" -o "$output_path"
printf 'Built %s\n' "$output_path"
