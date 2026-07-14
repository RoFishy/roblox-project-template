#!/bin/sh

set -e

if command -v python3 >/dev/null 2>&1 && python3 --version >/dev/null 2>&1; then
    python=python3
elif command -v python >/dev/null 2>&1 && python --version >/dev/null 2>&1; then
    python=python
else
    echo "Python 3 is required to validate JSON and project isolation." >&2
    exit 1
fi

temporary_directory=$(mktemp -d)
created_packages=false
created_global_types=false

mkdir -p "$temporary_directory/original"

if [ -e "dist" ]; then
    mv dist "$temporary_directory/original/dist"
fi

if [ -e "sourcemap.json" ]; then
    mv sourcemap.json "$temporary_directory/original/sourcemap.json"
fi

if [ -e ".active-place.project.json" ]; then
    mv .active-place.project.json "$temporary_directory/original/active-place.project.json"
fi

if [ ! -f "globalTypes.d.lua" ]; then
    created_global_types=true
fi

cleanup() {
    rm -rf dist
    rm -f sourcemap.json .active-place.project.json

    if [ -e "$temporary_directory/original/dist" ]; then
        mv "$temporary_directory/original/dist" dist
    fi

    if [ -e "$temporary_directory/original/sourcemap.json" ]; then
        mv "$temporary_directory/original/sourcemap.json" sourcemap.json
    fi

    if [ -e "$temporary_directory/original/active-place.project.json" ]; then
        mv "$temporary_directory/original/active-place.project.json" .active-place.project.json
    fi

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

echo "Validating tracked JSON and project mappings..."
"$python" <<'PY'
import json
import subprocess
from pathlib import Path


def fail(message):
    errors.append(message)


def load(path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as error:
        fail(f"{path.as_posix()}: {error}")
        return None


def mapped_paths(project):
    found = []

    def visit(value):
        if isinstance(value, dict):
            for key, child in value.items():
                if key == "$path" and isinstance(child, str):
                    found.append(child.replace("\\", "/"))
                else:
                    visit(child)
        elif isinstance(value, list):
            for child in value:
                visit(child)

    visit(project)
    return found


errors = []
tracked_json = subprocess.check_output(
    ["git", "-c", f"safe.directory={Path.cwd().as_posix()}", "ls-files", "-z", "--", "*.json"],
    text=True,
).split("\0")

for filename in filter(None, tracked_json):
    load(Path(filename))

root_development = load(Path("default.project.json"))
root_build = load(Path("build.project.json"))
root_source_paths = {
    "src/Core",
    "src/Client/Source",
    "src/Client/Runtime",
    "src/Server/Source",
    "src/Server/Runtime",
}
root_build_paths = {path.replace("src/", "dist/") for path in root_source_paths}

if root_development is not None:
    root_paths = set(mapped_paths(root_development))
    for path in root_source_paths:
        if path not in root_paths:
            fail(f"default.project.json: missing mapping {path}")
    if any("src/Places/" in path or "dist/Places/" in path for path in root_paths):
        fail("default.project.json: root project must not map place-specific code")
    if any("dist/" in path for path in root_paths):
        fail("default.project.json: development projects must map src, not dist")

if root_build is not None:
    root_paths = set(mapped_paths(root_build))
    for path in root_build_paths:
        if path not in root_paths:
            fail(f"build.project.json: missing mapping {path}")
    if any("src/Places/" in path or "dist/Places/" in path for path in root_paths):
        fail("build.project.json: root project must not map place-specific code")
    if any("src/" in path for path in root_paths):
        fail("build.project.json: build projects must map dist, not src")

places_root = Path("places")
place_directories = sorted(
    (path for path in places_root.iterdir() if path.is_dir()),
    key=lambda path: path.name.casefold(),
) if places_root.is_dir() else []
place_names = [path.name for path in place_directories]

shared_source_paths = {
    "../../src/Core",
    "../../src/Client/Source",
    "../../src/Client/Runtime",
    "../../src/Server/Source",
    "../../src/Server/Runtime",
}
shared_build_paths = {path.replace("../../src/", "../../dist/") for path in shared_source_paths}

for directory in place_directories:
    name = directory.name
    development_path = directory / "default.project.json"
    build_path = directory / "build.project.json"

    for path in (development_path, build_path):
        if not path.is_file():
            fail(f"{directory.as_posix()}: missing {path.name}")

    source_root = Path("src") / "Places" / name
    if not source_root.is_dir():
        fail(f"{directory.as_posix()}: missing matching source tree {source_root.as_posix()}")

    for relative_path in (
        "Core",
        "Client/Systems",
        "Client/Modules",
        "Server/Systems",
        "Server/Modules",
    ):
        source_path = source_root / relative_path
        if not source_path.is_dir():
            fail(f"{directory.as_posix()}: missing source directory {source_path.as_posix()}")

    if not development_path.is_file() or not build_path.is_file():
        continue

    development = load(development_path)
    build = load(build_path)
    if development is None or build is None:
        continue

    development_paths = set(mapped_paths(development))
    build_paths = set(mapped_paths(build))
    expected_source_paths = {
        f"../../src/Places/{name}/Core",
        f"../../src/Places/{name}/Client/Systems",
        f"../../src/Places/{name}/Client/Modules",
        f"../../src/Places/{name}/Server/Systems",
        f"../../src/Places/{name}/Server/Modules",
    }
    expected_build_paths = {path.replace("../../src/", "../../dist/") for path in expected_source_paths}

    for path in shared_source_paths | expected_source_paths:
        if path not in development_paths:
            fail(f"{development_path.as_posix()}: missing mapping {path}")

    for path in shared_build_paths | expected_build_paths:
        if path not in build_paths:
            fail(f"{build_path.as_posix()}: missing mapping {path}")

    if any("dist/" in path for path in development_paths):
        fail(f"{development_path.as_posix()}: development projects must map src, not dist")
    if any("src/" in path for path in build_paths):
        fail(f"{build_path.as_posix()}: build projects must map dist, not src")

    for other_name in place_names:
        if other_name == name:
            continue
        if any(f"src/Places/{other_name}/" in path for path in development_paths):
            fail(f"{development_path.as_posix()}: maps another place ({other_name})")
        if any(f"dist/Places/{other_name}/" in path for path in build_paths):
            fail(f"{build_path.as_posix()}: maps another place ({other_name})")

    if "servePort" in development and "servePort" in build:
        if development["servePort"] != build["servePort"]:
            fail(f"{directory.as_posix()}: development and build ports differ")

if errors:
    raise SystemExit("\n".join(f"ERROR: {message}" for message in errors))

print(f"Discovered {len(place_directories)} place project(s).")
PY

for script in scripts/*.sh; do
    sh -n "$script"
done

echo "Checking Windows entry points statically..."
"$python" <<'PY'
from pathlib import Path

required = {
    "scripts/dev.bat": ("default.project.json", "build.project.json", "DEV_DRY_RUN", "Available places:"),
    "scripts/build.bat": ("default.project.json", "build.project.json", "ROBLOX_DEV=false", "builds\\Game.rbxl"),
}

for filename, fragments in required.items():
    text = Path(filename).read_text(encoding="utf-8")
    missing = [fragment for fragment in fragments if fragment not in text]
    if missing:
        raise SystemExit(f"{filename}: missing expected content: {', '.join(missing)}")
PY

validate_project() {
    name="$1"
    development_project="$2"

    echo "Validating $name..."
    rojo build "$development_project" -o "$temporary_directory/$name-development.rbxl"
    BUILD_OUTPUT="$temporary_directory/$name-build.rbxl" sh scripts/build.sh "${3:-}"
    [ -s "$temporary_directory/$name-build.rbxl" ]
    sh scripts/analyze.sh "${3:-}"
    DEV_DRY_RUN=1 sh scripts/dev.sh "${3:-}" >/dev/null
}

validate_project root default.project.json

for place_directory in places/*; do
    [ -d "$place_directory" ] || continue
    place_name=${place_directory##*/}
    validate_project "$place_name" "$place_directory/default.project.json" "$place_name"
done

missing_place="DoesNotExist"
while [ -d "places/$missing_place" ]; do
    missing_place="${missing_place}X"
done

echo "Checking invalid place handling..."
for script in dev analyze build; do
    if sh "scripts/$script.sh" "$missing_place" >"$temporary_directory/$script-invalid.log" 2>&1; then
        echo "scripts/$script.sh accepted unknown place $missing_place" >&2
        exit 1
    fi
done

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
