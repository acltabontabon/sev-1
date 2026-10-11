#!/bin/sh
set -eu
cd "$(dirname "$0")"
exec sh tools/godot.sh --path . --script tests/variance_vault_preview.gd
