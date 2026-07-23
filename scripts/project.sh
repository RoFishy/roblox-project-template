#!/bin/sh

is_complete_place() {
    directory="$1"

    [ -d "$directory" ] \
        && [ -f "$directory/default.project.json" ] \
        && [ -f "$directory/build.project.json" ] \
        && [ -d "src/Places/${directory##*/}" ]
}

list_places() {
    found_place=false

    for directory in places/*; do
        if is_complete_place "$directory"; then
            printf '  %s\n' "${directory##*/}" >&2
            found_place=true
        fi
    done

    if [ "$found_place" = false ]; then
        echo "  (no optional places currently exist)" >&2
    fi
}

resolve_project() {
    PLACE_NAME="${1:-}"
    DEVELOPMENT_PROJECT="default.project.json"
    BUILD_PROJECT="build.project.json"

    if [ -z "$PLACE_NAME" ]; then
        return 0
    fi

    place_directory="places/$PLACE_NAME"

    if [ ! -d "$place_directory" ]; then
        echo "Unknown place: $PLACE_NAME" >&2
    elif ! is_complete_place "$place_directory"; then
        echo "Invalid place: $PLACE_NAME requires both project files and src/Places/$PLACE_NAME" >&2
    else
        DEVELOPMENT_PROJECT="$place_directory/default.project.json"
        BUILD_PROJECT="$place_directory/build.project.json"
        return 0
    fi

    echo "Available places:" >&2
    list_places
    return 1
}

write_active_project() {
    sed 's#\("$path"[[:space:]]*:[[:space:]]*"\)\.\./\.\./#\1#' \
        "$DEVELOPMENT_PROJECT" >.active-place.project.json
}

prepare_place_dist() {
    [ -n "$PLACE_NAME" ] || return 0

    mkdir -p \
        "dist/Places/$PLACE_NAME/Core" \
        "dist/Places/$PLACE_NAME/Client/Systems" \
        "dist/Places/$PLACE_NAME/Client/Modules" \
        "dist/Places/$PLACE_NAME/Server/Systems" \
        "dist/Places/$PLACE_NAME/Server/Modules"
}

process_sources() {
    development="$1"

    for source_root in Core Client Server; do
        ROBLOX_DEV="$development" darklua process --config .darklua.json \
            "src/$source_root" "dist/$source_root"
    done

    if [ -n "$PLACE_NAME" ]; then
        ROBLOX_DEV="$development" darklua process --config .darklua.json \
            "src/Places/$PLACE_NAME" "dist/Places/$PLACE_NAME"
    fi
}

print_watch_commands() {
    for source_root in Core Client Server; do
        printf 'ROBLOX_DEV=true darklua process --config .darklua.json --watch src/%s dist/%s\n' \
            "$source_root" "$source_root"
    done

    if [ -n "$PLACE_NAME" ]; then
        printf 'ROBLOX_DEV=true darklua process --config .darklua.json --watch src/Places/%s dist/Places/%s\n' \
            "$PLACE_NAME" "$PLACE_NAME"
    fi
}

watch_sources() {
    ROBLOX_DEV=true darklua process --config .darklua.json --watch src/Core dist/Core &
    ROBLOX_DEV=true darklua process --config .darklua.json --watch src/Client dist/Client &

    if [ -n "$PLACE_NAME" ]; then
        ROBLOX_DEV=true darklua process --config .darklua.json --watch src/Server dist/Server &
        ROBLOX_DEV=true darklua process --config .darklua.json --watch \
            "src/Places/$PLACE_NAME" "dist/Places/$PLACE_NAME"
    else
        ROBLOX_DEV=true darklua process --config .darklua.json --watch src/Server dist/Server
    fi
}
