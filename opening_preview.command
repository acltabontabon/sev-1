#!/bin/sh
# Double-click to replay the full opening, then explore the office.
set -eu
cd "$(dirname "$0")"
exec sh tools/godot.sh --path . --script tests/cutscene_preview.gd -- --opening --play
