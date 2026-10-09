#!/bin/sh
# macOS local test release: validated, ad-hoc signed, not notarized.
set -eu
cd "$(dirname "$0")/.."
exec python3 tools/release.py "$@"
