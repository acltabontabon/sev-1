#!/bin/sh
# Double-click for an immediate playable fight in the expanded production vault.
set -eu
cd "$(dirname "$0")"
exec sh tools/godot.sh --path . --script tests/vault_arena_preview.gd -- --play
