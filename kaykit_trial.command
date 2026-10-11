#!/bin/sh
# Double-click in Finder to review one free skeleton beside the engineer.
set -eu
cd "$(dirname "$0")"
exec sh tools/godot.sh --path . game/art_trials/kaykit_comparison.tscn "$@"
