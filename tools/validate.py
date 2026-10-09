#!/usr/bin/env python3
"""Run pinned Godot checks with deadlines and fail on logged engine errors."""
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
LOGS = ROOT / "logs"
ERROR = re.compile(r"(?:SCRIPT ERROR:|(?:^|\n)ERROR:|Parse Error:|FAIL:)")


def run(name, args, timeout=120):
    command = ["sh", str(ROOT / "tools/godot.sh"), *args]
    try:
        result = subprocess.run(command, cwd=ROOT, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, text=True, timeout=timeout)
    except subprocess.TimeoutExpired as exc:
        output = exc.stdout or b""
        if isinstance(output, bytes):
            output = output.decode(errors="replace")
        (LOGS / f"{name}.log").write_text(output)
        sys.exit(f"FAIL {name}: timed out; see logs/{name}.log")
    (LOGS / f"{name}.log").write_text(result.stdout)
    if result.returncode or ERROR.search(result.stdout):
        print(result.stdout)
        sys.exit(f"FAIL {name}: see logs/{name}.log")
    print(f"PASS {name}")


if __name__ == "__main__":
    LOGS.mkdir(exist_ok=True)
    run("import", ["--headless", "--path", ".", "--import"])
    for script in sorted([*ROOT.glob("game/**/*.gd"), *ROOT.glob("tests/**/*.gd"), *ROOT.glob("tools/*.gd")]):
        relative = script.relative_to(ROOT).as_posix()
        run(relative.replace("/", "_"), ["--headless", "--path", ".", "--check-only", "--script", relative])
    run("movement", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/run_tests.gd"])
    run("combat", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/combat_tests.gd"])
    run("alpha", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/alpha_tests.gd"])
    run("office", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/office_tests.gd"])
    run("incident", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/incident_tests.gd"])
    run("presentation", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/presentation_tests.gd"])
    run("progression", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/progression_tests.gd"])
    print("All checks passed. Graphical review and human playtesting remain separate.")
