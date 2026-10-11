#!/bin/sh
# Double-click in Finder to watch the revised midnight street ending shot.
set -eu
cd "$(dirname "$0")"
exec sh tools/godot.sh --path . --script tests/nightlife_preview.gd
