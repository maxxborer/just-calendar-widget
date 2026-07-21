#!/bin/sh
set -eu

usage() {
    printf '%s\n' "Usage: scripts/version.sh {major|minor|patch}" >&2
    exit 64
}

[ "$#" -eq 1 ] || usage
release_type=$1

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repository_dir=$(CDPATH= cd -- "$script_dir/.." && pwd)
version_file="$repository_dir/Config/Version.xcconfig"

current_version=$(awk -F ' = ' '/^MARKETING_VERSION = / { print $2; exit }' "$version_file")
current_build=$(awk -F ' = ' '/^CURRENT_PROJECT_VERSION = / { print $2; exit }' "$version_file")

IFS=.
set -- $current_version
[ "$#" -eq 3 ] || {
    printf '%s\n' "Invalid MARKETING_VERSION: $current_version" >&2
    exit 65
}

major=$1
minor=$2
patch=$3

for component in "$major" "$minor" "$patch" "$current_build"; do
    case "$component" in
        ''|*[!0-9]*)
            printf '%s\n' "Version components must be non-negative integers." >&2
            exit 65
            ;;
    esac
done

case "$release_type" in
    major)
        next_version="$((major + 1)).0.0"
        ;;
    minor)
        next_version="$major.$((minor + 1)).0"
        ;;
    patch)
        next_version="$major.$minor.$((patch + 1))"
        ;;
    *)
        usage
        ;;
esac

next_build=$((current_build + 1))
temporary_file=$(mktemp "${version_file}.XXXXXX")
trap 'rm -f "$temporary_file"' EXIT HUP INT TERM

awk \
    -v marketing_version="$next_version" \
    -v build_number="$next_build" \
    '/^MARKETING_VERSION = / { print "MARKETING_VERSION = " marketing_version; next } /^CURRENT_PROJECT_VERSION = / { print "CURRENT_PROJECT_VERSION = " build_number; next } { print }' \
    "$version_file" > "$temporary_file"

mv "$temporary_file" "$version_file"
trap - EXIT HUP INT TERM

printf '%s\n' "$next_version"
