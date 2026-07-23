#!/bin/sh

set -e

if [ "$#" -gt 1 ]; then
    echo "Usage: sh scripts/analyze.sh [PlaceName]" >&2
    exit 1
fi

. scripts/project.sh
resolve_project "${1:-}"

development_project="$DEVELOPMENT_PROJECT"

if [ -n "$PLACE_NAME" ]; then
    write_active_project
    development_project=".active-place.project.json"
    trap 'rm -f .active-place.project.json' EXIT HUP INT TERM
fi

# If Packages aren't installed, install them.
if [ ! -d "Packages" ]; then
    sh scripts/install-packages.sh
fi

rojo sourcemap "$development_project" -o sourcemap.json
if [ ! -f "globalTypes.d.lua" ]; then
    curl -L -o globalTypes.d.lua https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.lua
fi

set -- src/Core src/Client src/Server
if [ -n "$PLACE_NAME" ]; then
    set -- "$@" "src/Places/$PLACE_NAME"
fi

luau-lsp analyze --definitions=globalTypes.d.lua --base-luaurc=.luaurc \
    --sourcemap=sourcemap.json --settings=.vscode/settings.json \
    --no-strict-dm-types --ignore Packages/**/*.lua --ignore Packages/**/*.luau \
    "$@"
