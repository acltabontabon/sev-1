#!/bin/sh
# Double-click in Finder to play, or run `sh play.command` from a terminal.
set -eu
cd "$(dirname "$0")"
exec sh tools/godot.sh --path . "$@"
