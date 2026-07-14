#!/bin/sh

set -e

development_project="default.project.json"
build_project="build.project.json"
place=""

if [ -n "${1:-}" ]; then
    place_directory="places/$1"

    if [ ! -f "$place_directory/default.project.json" ] || [ ! -f "$place_directory/build.project.json" ]; then
        echo "Unknown place: $1" >&2
        echo "Available places:" >&2
        for directory in places/*; do
            [ -f "$directory/default.project.json" ] && echo "  ${directory##*/}" >&2
        done
        exit 1
    fi

    sed 's#\.\./\.\./##g' "$place_directory/default.project.json" >.active-place.project.json
    development_project=".active-place.project.json"
    build_project="$place_directory/build.project.json"
    place="$1"
fi

# If Packages aren't installed, install them.
if [ ! -d "Packages" ]; then
    sh scripts/install-packages.sh
fi

if [ -n "$place" ]; then
    mkdir -p \
        "dist/Places/$place/Core" \
        "dist/Places/$place/Client/Systems" \
        "dist/Places/$place/Client/Modules" \
        "dist/Places/$place/Server/Systems" \
        "dist/Places/$place/Server/Modules"
fi

rojo serve "$build_project" \
    & rojo sourcemap "$development_project" -o sourcemap.json --watch \
    & ROBLOX_DEV=true darklua process --config .darklua.json --watch src/ dist/
