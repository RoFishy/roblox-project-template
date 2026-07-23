#!/bin/sh

set -e

if command -v python3 >/dev/null 2>&1 && python3 --version >/dev/null 2>&1; then
    python=python3
elif command -v python >/dev/null 2>&1 && python --version >/dev/null 2>&1; then
    python=python
else
    echo "Python 3 is required to run validation." >&2
    exit 1
fi

temporary_directory=$(mktemp -d)
created_packages=false
created_global_types=false
cleaned_up=false
validation_places="ValidationPlaceA ValidationPlaceB ValidationPlaceC ValidationPortDuplicate ValidationFailed ValidationIncomplete"

mkdir -p "$temporary_directory/original"

for path in dist sourcemap.json .active-place.project.json; do
    if [ -e "$path" ]; then
        mv "$path" "$temporary_directory/original/$(printf '%s' "$path" | tr '/.' '__')"
    fi
done

if [ ! -f "globalTypes.d.lua" ]; then
    created_global_types=true
fi

cleanup() {
    [ "$cleaned_up" = false ] || return
    cleaned_up=true
    set +e

    for name in $validation_places; do
        rm -rf "places/$name" "src/Places/$name"
    done

    rm -rf dist
    rm -f sourcemap.json .active-place.project.json

    for path in dist sourcemap.json .active-place.project.json; do
        saved_path="$temporary_directory/original/$(printf '%s' "$path" | tr '/.' '__')"
        if [ -e "$saved_path" ]; then
            mv "$saved_path" "$path"
        fi
    done

    if [ "$created_global_types" = true ]; then
        rm -f globalTypes.d.lua
    fi

    if [ "$created_packages" = true ]; then
        rm -rf Packages ServerPackages
        rm -f wally.lock

        if [ -e "$temporary_directory/original/wally.lock" ]; then
            mv "$temporary_directory/original/wally.lock" wally.lock
        fi
    fi

    rm -rf "$temporary_directory"
}

trap cleanup EXIT HUP INT TERM

if [ ! -d "Packages" ]; then
    created_packages=true

    if [ -e "wally.lock" ]; then
        mv wally.lock "$temporary_directory/original/wally.lock"
    fi

    sh scripts/install-packages.sh
fi

echo "Checking the zero-place repository state..."
"$python" <<'PY'
import json
from pathlib import Path

assert Path("places/.gitkeep").is_file()
assert Path("src/Places/.gitkeep").is_file()
assert not [path for path in Path("places").iterdir() if path.is_dir()], "repository must ship with zero places"
assert not [path for path in Path("src/Places").iterdir() if path.is_dir()], "repository must ship with zero place source trees"

for filename in ("default.project.json", "build.project.json"):
    project = json.loads(Path(filename).read_text(encoding="utf-8"))
    text = json.dumps(project)
    assert "src/Places/" not in text and "dist/Places/" not in text
PY

for script in scripts/*.sh; do
    sh -n "$script"
done

echo "Checking Windows entry points statically..."
"$python" <<'PY'
from pathlib import Path

required = {
    "scripts/create-place.bat": ("create-place.ps1", "%*"),
    "scripts/create-place.ps1": ("34872", "65535", "default.project.json", "build.project.json", "does not create a Roblox cloud place"),
    "scripts/write-active-project.ps1": ('"\\$path"', "\\.\\./\\.\\./", ".active-place.project.json"),
    "scripts/dev.bat": ("default.project.json", "build.project.json", "src\\Places", "src/Core", "DEV_DRY_RUN"),
    "scripts/build.bat": ("default.project.json", "build.project.json", "src\\Places", "src/%%D", "ROBLOX_DEV=false", "builds\\Game.rbxl"),
}

for filename, fragments in required.items():
    text = Path(filename).read_text(encoding="utf-8")
    missing = [fragment for fragment in fragments if fragment not in text]
    if missing:
        raise SystemExit(f"{filename}: missing expected content: {', '.join(missing)}")
PY

echo "Validating root projects with zero optional places..."
rojo build default.project.json -o "$temporary_directory/root-development.rbxl"
BUILD_OUTPUT="$temporary_directory/root-build.rbxl" sh scripts/build.sh
[ -s "$temporary_directory/root-build.rbxl" ]
[ ! -e "dist/Places" ]
sh scripts/analyze.sh
DEV_DRY_RUN=1 sh scripts/dev.sh >"$temporary_directory/root-dev.log"

for script in dev analyze build; do
    if sh "scripts/$script.sh" DoesNotExist >"$temporary_directory/$script-zero-places.log" 2>&1; then
        echo "scripts/$script.sh accepted an unknown place while zero places exist" >&2
        exit 1
    fi
    grep "no optional places currently exist" "$temporary_directory/$script-zero-places.log" >/dev/null
done

echo "Exercising place creation and port assignment..."
sh scripts/create-place.sh ValidationPlaceA >"$temporary_directory/create-a.log"
sh scripts/create-place.sh ValidationPlaceB >"$temporary_directory/create-b.log"
sh scripts/create-place.sh ValidationPlaceC 34900 >"$temporary_directory/create-c.log"

sh -c '. scripts/project.sh; resolve_project ValidationPlaceA; write_active_project'
"$python" <<'PY'
import json
from pathlib import Path

project = json.loads(Path(".active-place.project.json").read_text(encoding="utf-8"))


def visit(value):
    if isinstance(value, dict):
        for key, child in value.items():
            if key == "$path":
                assert not child.startswith("../../")
            else:
                visit(child)
    elif isinstance(value, list):
        for child in value:
            visit(child)


visit(project)
PY
rm .active-place.project.json

"$python" <<'PY'
import json
from pathlib import Path


def mapped_paths(value):
    found = []
    if isinstance(value, dict):
        for key, child in value.items():
            if key == "$path" and isinstance(child, str):
                found.append(child.replace("\\", "/"))
            else:
                found.extend(mapped_paths(child))
    elif isinstance(value, list):
        for child in value:
            found.extend(mapped_paths(child))
    return found


ports = {
    "ValidationPlaceA": 34872,
    "ValidationPlaceB": 34873,
    "ValidationPlaceC": 34900,
}
shared_source = {
    "../../src/Core",
    "../../src/Client/Source",
    "../../src/Client/Runtime",
    "../../src/Server/Source",
    "../../src/Server/Runtime",
}

for name, port in ports.items():
    source_root = Path("src/Places") / name
    for relative in ("Core", "Client/Systems", "Client/Modules", "Server/Systems", "Server/Modules"):
        assert (source_root / relative / ".gitkeep").is_file()

    development = json.loads((Path("places") / name / "default.project.json").read_text(encoding="utf-8"))
    build = json.loads((Path("places") / name / "build.project.json").read_text(encoding="utf-8"))
    assert development["servePort"] == build["servePort"] == port
    assert name in development["name"] and name in build["name"]

    source_paths = set(mapped_paths(development))
    build_paths = set(mapped_paths(build))
    place_source = {
        f"../../src/Places/{name}/Core",
        f"../../src/Places/{name}/Client/Systems",
        f"../../src/Places/{name}/Client/Modules",
        f"../../src/Places/{name}/Server/Systems",
        f"../../src/Places/{name}/Server/Modules",
    }
    assert shared_source | place_source <= source_paths
    assert {path.replace("../../src/", "../../dist/") for path in shared_source | place_source} <= build_paths
    assert not any(other != name and f"/Places/{other}/" in path for other in ports for path in source_paths | build_paths)
    assert not ({"gameId", "placeId", "servePlaceIds"} & development.keys())
    assert not ({"gameId", "placeId", "servePlaceIds"} & build.keys())
PY

echo "Checking rejected creation inputs and cleanup..."
if sh scripts/create-place.sh "" >"$temporary_directory/empty-name.log" 2>&1; then
    echo "create-place accepted an empty name" >&2
    exit 1
fi

if sh scripts/create-place.sh ValidationPlaceA >"$temporary_directory/duplicate-name.log" 2>&1; then
    echo "create-place accepted a duplicate name" >&2
    exit 1
fi
[ -f "places/ValidationPlaceA/default.project.json" ]

if sh scripts/create-place.sh ValidationPortDuplicate 34872 >"$temporary_directory/duplicate-port.log" 2>&1; then
    echo "create-place accepted a duplicate port" >&2
    exit 1
fi
[ ! -e "places/ValidationPortDuplicate" ] && [ ! -e "src/Places/ValidationPortDuplicate" ]

mkdir "src/Places/ValidationFailed"
: >"src/Places/ValidationFailed/existing-user-content"
if sh scripts/create-place.sh ValidationFailed >"$temporary_directory/source-conflict.log" 2>&1; then
    echo "create-place accepted a pre-existing source tree" >&2
    exit 1
fi
[ -f "src/Places/ValidationFailed/existing-user-content" ]
rm -rf "src/Places/ValidationFailed"

for invalid_name in "123Invalid" "Invalid Place" "../Invalid" "Invalid/Test" "Invalid\Test" "." ".." "Bad..Name"; do
    if sh scripts/create-place.sh "$invalid_name" >"$temporary_directory/invalid-name.log" 2>&1; then
        echo "create-place accepted invalid name: $invalid_name" >&2
        exit 1
    fi
done

for invalid_port in -1 0 65536 abc 12x 99999999999999999999; do
    if sh scripts/create-place.sh ValidationFailed "$invalid_port" >"$temporary_directory/invalid-port.log" 2>&1; then
        echo "create-place accepted invalid port: $invalid_port" >&2
        exit 1
    fi
    [ ! -e "places/ValidationFailed" ] && [ ! -e "src/Places/ValidationFailed" ]
done

printf 'return "selected"\n' >src/Places/ValidationPlaceA/Core/Selected.luau
printf 'return "unselected"\n' >src/Places/ValidationPlaceB/Core/Unselected.luau

echo "Validating generated place projects and selected-place isolation..."
rojo build places/ValidationPlaceA/default.project.json -o "$temporary_directory/place-development.rbxl"
BUILD_OUTPUT="$temporary_directory/place-build.rbxl" sh scripts/build.sh ValidationPlaceA \
    >"$temporary_directory/place-build.log" 2>&1
[ -s "$temporary_directory/place-build.rbxl" ]
[ -f "dist/Places/ValidationPlaceA/Core/Selected.luau" ]
[ ! -e "dist/Places/ValidationPlaceB" ]

if grep -i "unable to find source path.*ValidationPlaceB" "$temporary_directory/place-build.log" >/dev/null; then
    echo "selected build emitted an unrelated-place sourcemap warning" >&2
    exit 1
fi

sh scripts/analyze.sh ValidationPlaceA >"$temporary_directory/place-analyze.log" 2>&1
if grep -i "unable to find source path.*ValidationPlaceB" "$temporary_directory/place-analyze.log" >/dev/null; then
    echo "selected analysis emitted an unrelated-place sourcemap warning" >&2
    exit 1
fi
DEV_DRY_RUN=1 sh scripts/dev.sh ValidationPlaceA >"$temporary_directory/place-dev.log"

echo "Rechecking root isolation while optional places exist..."
rm -rf dist/Places
BUILD_OUTPUT="$temporary_directory/root-after-places.rbxl" sh scripts/build.sh \
    >"$temporary_directory/root-after-places.log" 2>&1
[ -s "$temporary_directory/root-after-places.rbxl" ]
[ ! -e "dist/Places" ]
sh scripts/analyze.sh >"$temporary_directory/root-after-places-analyze.log" 2>&1
DEV_DRY_RUN=1 sh scripts/dev.sh >"$temporary_directory/root-after-places-dev.log"

echo "Checking unknown and incomplete place handling..."
for script in dev analyze build; do
    if sh "scripts/$script.sh" DoesNotExist >"$temporary_directory/$script-unknown.log" 2>&1; then
        echo "scripts/$script.sh accepted an unknown place" >&2
        exit 1
    fi
    grep "ValidationPlaceA" "$temporary_directory/$script-unknown.log" >/dev/null
done

mkdir "places/ValidationIncomplete"
for script in dev analyze build; do
    if sh "scripts/$script.sh" ValidationIncomplete >"$temporary_directory/$script-incomplete.log" 2>&1; then
        echo "scripts/$script.sh accepted an incomplete place" >&2
        exit 1
    fi
    grep "Invalid place" "$temporary_directory/$script-incomplete.log" >/dev/null
done

echo "Running lint and format checks..."
selene src/

format_source="$temporary_directory/stylua-src"
cp -R src "$format_source"
"$python" - "$format_source" <<'PY'
import sys
from pathlib import Path

for path in Path(sys.argv[1]).rglob("*"):
    if path.suffix in {".lua", ".luau"}:
        path.write_bytes(path.read_bytes().replace(b"\r\n", b"\n"))
PY
stylua --config-path stylua.toml --check "$format_source"

echo "Validation passed."
