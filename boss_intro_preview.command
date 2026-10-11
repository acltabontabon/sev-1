#!/bin/sh
# Double-click to watch the corporate fire response and Stage One boss entrance, then play the fight.
set -eu
cd "$(dirname "$0")"
exec sh tools/godot.sh --path . --script tests/cutscene_preview.gd -- --vault --play
