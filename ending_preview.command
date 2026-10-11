#!/bin/sh
# Double-click in Finder to watch the ending, departure, and Monday postmortem.
set -eu
cd "$(dirname "$0")"
exec sh tools/godot.sh --path . --script tests/finale_preview.gd -- --play-ending
