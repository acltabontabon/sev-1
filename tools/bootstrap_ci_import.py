#!/usr/bin/env python3
"""Import a fresh checkout before enabling its font-dependent startup theme."""
from pathlib import Path
import re

from validate import LOGS, run

ROOT = Path(__file__).resolve().parents[1]


def main():
    LOGS.mkdir(exist_ok=True)
    project = ROOT / "project.godot"
    original = project.read_text()
    # Godot loads the project theme before the first font import. Disable only that
    # startup reference during bootstrap; validation/export always use the original.
    cold = re.sub(r'^theme/custom="[^"\n]+"\n', '', original, count=1, flags=re.M)
    if cold == original:
        raise SystemExit("Expected the project's custom theme startup reference")
    try:
        project.write_text(cold)
        run("ci_bootstrap_import", ["--headless", "--path", ".", "--import"], timeout=600)
    finally:
        project.write_text(original)


if __name__ == "__main__":
    main()
