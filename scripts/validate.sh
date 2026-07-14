#!/bin/sh

set -e

if command -v python3 >/dev/null 2>&1 && python3 --version >/dev/null 2>&1; then
    python=python3
elif command -v python >/dev/null 2>&1 && python --version >/dev/null 2>&1; then
    python=python
else
    echo "Python 3 is required to validate JSON and sourcemap isolation." >&2
    exit 1
fi

if [ ! -d "Packages" ]; then
    sh scripts/install-packages.sh
fi

for json_file in \
    .darklua.json \
    .luaurc \
    .vscode/settings.json \
    default.project.json \
    build.project.json \
    src/Server/Source/init.meta.json \
    places/Lobby/default.project.json \
    places/Lobby/build.project.json \
    places/Gameplay/default.project.json \
    places/Gameplay/build.project.json; do
    "$python" -m json.tool "$json_file" >/dev/null
done

temporary_directory=$(mktemp -d)
trap 'rm -rf "$temporary_directory"; rm -f .active-place.project.json' EXIT HUP INT TERM

validate_projects() {
    name="$1"
    development_project="$2"
    build_project="$3"
    sourcemap_project="$development_project"

    if [ "$name" != "root" ]; then
        mkdir -p \
            "dist/Places/$name/Core" \
            "dist/Places/$name/Client/Systems" \
            "dist/Places/$name/Client/Modules" \
            "dist/Places/$name/Server/Systems" \
            "dist/Places/$name/Server/Modules"

        sed 's#\.\./\.\./##g' "$development_project" >.active-place.project.json
        sourcemap_project=".active-place.project.json"
    fi

    rojo sourcemap "$sourcemap_project" -o sourcemap.json
    ROBLOX_DEV=true darklua process --config .darklua.json src/ dist/
    rojo build "$development_project" -o "$temporary_directory/$name-development.rbxlx"
    rojo build "$build_project" -o "$temporary_directory/$name-build.rbxlx"

    "$python" - "$name" "$development_project" "$build_project" <<'PY'
import json
import sys

name, development_path, build_path = sys.argv[1:]
development_project = json.load(open(development_path, encoding="utf-8"))
build_project = json.load(open(build_path, encoding="utf-8"))
paths = json.dumps(development_project).replace("\\\\", "/")

for required in ("src/Core", "src/Client", "src/Server"):
    assert required in paths, f"{name}: missing shared path {required}"

if name == "root":
    assert "src/Places/" not in paths, "root: place-specific code must not be mapped"
else:
    assert f"src/Places/{name}" in paths, f"{name}: selected place code is not mapped"
    other = "Gameplay" if name == "Lobby" else "Lobby"
    assert f"src/Places/{other}" not in paths, f"{name}: {other} code must not be mapped"
    assert development_project["servePort"] == build_project["servePort"], f"{name}: project ports differ"
PY
}

validate_projects root default.project.json build.project.json
validate_projects Lobby places/Lobby/default.project.json places/Lobby/build.project.json
validate_projects Gameplay places/Gameplay/default.project.json places/Gameplay/build.project.json

sh scripts/analyze.sh
sh scripts/analyze.sh Lobby
sh scripts/analyze.sh Gameplay
selene src/
stylua --check src/
