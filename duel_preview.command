#!/bin/sh
# Double-click in Finder to watch the Stage One boss duel in the real application.
set -eu
cd "$(dirname "$0")"
exec sh tools/godot.sh --path . --script tests/ending_preview.gd -- --duel-only
