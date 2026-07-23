#!/bin/sh

set -e

usage() {
    echo "Usage: sh scripts/create-place.sh <PlaceName> [ServePort]" >&2
    exit 1
}

fail() {
    echo "Error: $1" >&2
    exit 1
}

[ "$#" -ge 1 ] && [ "$#" -le 2 ] || usage

place_name="$1"
explicit_port="${2:-}"

case "$place_name" in
    "" | [!A-Za-z]* | *[!A-Za-z0-9_-]* | *..*)
        fail "place name must start with an ASCII letter and contain only letters, numbers, underscores, and hyphens"
        ;;
esac

place_directory="places/$place_name"
source_directory="src/Places/$place_name"

[ ! -e "$place_directory" ] || fail "$place_directory already exists"
[ ! -e "$source_directory" ] || fail "$source_directory already exists"

. scripts/project.sh

normalize_port() {
    normalized=$(printf '%s' "$1" | sed 's/^0*//')
    printf '%s\n' "${normalized:-0}"
}

port_is_used() {
    requested_port="$1"

    for directory in places/*; do
        is_complete_place "$directory" || continue
        used_port=$(sed -n 's/.*"servePort"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p' \
            "$directory/default.project.json" | sed -n '1p')

        case "$used_port" in
            "" | *[!0-9]*) continue ;;
        esac

        used_port=$(normalize_port "$used_port")
        [ "${#used_port}" -le 5 ] || continue
        [ "$used_port" -ge 1 ] && [ "$used_port" -le 65535 ] || continue
        [ "$used_port" -ne "$requested_port" ] || return 0
    done

    return 1
}

if [ -n "$explicit_port" ]; then
    case "$explicit_port" in
        *[!0-9]*) fail "port must contain only digits" ;;
    esac

    serve_port=$(normalize_port "$explicit_port")
    [ "${#serve_port}" -le 5 ] \
        && [ "$serve_port" -ge 1 ] \
        && [ "$serve_port" -le 65535 ] \
        || fail "port must be between 1 and 65535"
    port_is_used "$serve_port" && fail "port $serve_port is already used by another place"
else
    serve_port=34872
    while port_is_used "$serve_port"; do
        serve_port=$((serve_port + 1))
        [ "$serve_port" -le 65535 ] || fail "no available development port exists from 34872 through 65535"
    done
fi

creation_complete=false
cleanup() {
    if [ "$creation_complete" = false ]; then
        [ ! -e "$place_directory" ] || rm -rf "$place_directory"
        [ ! -e "$source_directory" ] || rm -rf "$source_directory"
    fi
}
trap cleanup EXIT HUP INT TERM

mkdir -p \
    "$place_directory" \
    "$source_directory/Core" \
    "$source_directory/Client/Systems" \
    "$source_directory/Client/Modules" \
    "$source_directory/Server/Systems" \
    "$source_directory/Server/Modules"

for directory in \
    "$source_directory/Core" \
    "$source_directory/Client/Systems" \
    "$source_directory/Client/Modules" \
    "$source_directory/Server/Systems" \
    "$source_directory/Server/Modules"; do
    : >"$directory/.gitkeep"
done

for project_type in default build; do
    sed \
        -e "s/__PLACE_NAME__/$place_name/g" \
        -e "s/__SERVE_PORT__/$serve_port/g" \
        "scripts/place.$project_type.project.json.template" \
        >"$place_directory/$project_type.project.json"
done

creation_complete=true

printf 'Created place "%s"\n' "$place_name"
printf 'Port: %s\n\n' "$serve_port"
printf 'Local files:\n  %s\n  %s\n\n' "$place_directory" "$source_directory"
printf 'Develop:\n  sh scripts/dev.sh %s\n\n' "$place_name"
printf 'Build:\n  sh scripts/build.sh %s\n\n' "$place_name"
printf 'Analyze:\n  sh scripts/analyze.sh %s\n\n' "$place_name"
printf 'This creates local project structure only; it does not create a Roblox cloud place.\n'
