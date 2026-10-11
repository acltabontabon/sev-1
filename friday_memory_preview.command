#!/bin/sh
# Direct memorial review with one explicitly staged lunch promise to Morgan.
set -eu
cd "$(dirname "$0")"
exec sh tools/godot.sh --path . --script tests/finale_preview.gd -- --play-memorial --promise
