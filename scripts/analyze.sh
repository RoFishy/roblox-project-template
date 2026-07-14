#!/bin/sh

set -e

development_project="default.project.json"

if [ -n "${1:-}" ]; then
    selected_project="places/$1/default.project.json"

    if [ ! -f "$selected_project" ]; then
        echo "Unknown place: $1" >&2
        exit 1
    fi

    sed 's#\.\./\.\./##g' "$selected_project" >.active-place.project.json
    development_project=".active-place.project.json"
fi

# If Packages aren't installed, install them.
if [ ! -d "Packages" ]; then
    sh scripts/install-packages.sh
fi

rojo sourcemap "$development_project" -o sourcemap.json
if [ ! -f "globalTypes.d.lua" ]; then
    curl -L -o globalTypes.d.lua https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.lua
fi

luau-lsp analyze --definitions=globalTypes.d.lua --base-luaurc=.luaurc \
    --sourcemap=sourcemap.json --settings=.vscode/settings.json \
    --no-strict-dm-types --ignore Packages/**/*.lua --ignore Packages/**/*.luau \
    src/
