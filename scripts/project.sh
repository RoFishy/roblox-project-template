#!/bin/sh

list_places() {
    found_place=false

    for directory in places/*; do
        if [ -d "$directory" ] \
            && [ -f "$directory/default.project.json" ] \
            && [ -f "$directory/build.project.json" ]; then
            printf '  %s\n' "${directory##*/}" >&2
            found_place=true
        fi
    done

    if [ "$found_place" = false ]; then
        echo "  (none)" >&2
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
    elif [ ! -f "$place_directory/default.project.json" ] \
        || [ ! -f "$place_directory/build.project.json" ]; then
        echo "Invalid place: $PLACE_NAME requires default.project.json and build.project.json" >&2
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
    sed 's#\.\./\.\./##g' "$DEVELOPMENT_PROJECT" >.active-place.project.json
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
