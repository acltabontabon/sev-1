#!/bin/sh
# Charged Force Rollback, one durable practice target, and the living night shift.
set -eu
cd "$(dirname "$0")"
exec sh tools/godot.sh --path . --script tests/heart_preview.gd
