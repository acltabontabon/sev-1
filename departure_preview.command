#!/bin/sh
# Double-click to watch the continuous memory walk, opening doors and nightlife ending.
set -eu
cd "$(dirname "$0")"
exec sh tools/godot.sh --path . --script tests/ending_preview.gd -- --departure
