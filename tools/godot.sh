#!/bin/sh
# Usage: sh tools/godot.sh --version (or any Godot arguments).
# GODOT_BIN may override discovery with an absolute executable path.
set -eu

godot_bin=${GODOT_BIN:-}
if [ -z "$godot_bin" ]; then
    for candidate in /Applications/Godot.app/Contents/MacOS/Godot \
        "$HOME/Applications/Godot.app/Contents/MacOS/Godot" \
        "$HOME/Downloads/Godot.app/Contents/MacOS/Godot"; do
        if [ -x "$candidate" ]; then
            godot_bin=$candidate
            break
        fi
    done
fi
if [ -z "$godot_bin" ]; then
    godot_bin=$(command -v godot || command -v godot4 || true)
fi
if [ -z "$godot_bin" ] || [ ! -x "$godot_bin" ]; then
    echo 'Godot not found. Set GODOT_BIN to the Godot 4.7.2 executable.' >&2
    exit 1
fi
godot_version=$("$godot_bin" --version)
case "$godot_version" in
    4.7.2.stable.*) ;;
    *) echo "Expected Godot 4.7.2 stable; found: $godot_version" >&2; exit 1 ;;
esac
exec "$godot_bin" "$@"
