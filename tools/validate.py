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
    subprocess.run([sys.executable, "tools/voices.py", "validate"], cwd=ROOT, check=True)
    subprocess.run([sys.executable, "tools/voices.py", "talk-validate"], cwd=ROOT, check=True)
    subprocess.run([sys.executable, "tests/voice_pipeline_tests.py"], cwd=ROOT, check=True)
    run("import", ["--headless", "--path", ".", "--import"])
    for script in sorted([*ROOT.glob("game/**/*.gd"), *ROOT.glob("tests/**/*.gd"), *ROOT.glob("tools/*.gd")]):
        relative = script.relative_to(ROOT).as_posix()
        run(relative.replace("/", "_"), ["--headless", "--path", ".", "--check-only", "--script", relative])
    run("movement", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/run_tests.gd"])
    run("combat", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/combat_tests.gd"])
    run("alpha", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/alpha_tests.gd"])
    run("office", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/office_tests.gd"])
    run("incident", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/incident_tests.gd"])
    run("operations", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/operations_tests.gd"])
    run("scene_flow", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/scene_flow_tests.gd"])
    run("presentation", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/presentation_tests.gd"])
    run("progression", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/progression_tests.gd"])
    run("burnout", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/burnout_tests.gd"])
    run("stabilization", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/stabilization_tests.gd"])
    run("narrative", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/narrative_tests.gd"])
    run("release", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/release_tests.gd"])
    run("chapter_progress", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/chapter_progress_tests.gd"])
    run("voice", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/voice_tests.gd"])
    run("environment", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/environment_tests.gd"])
    run("pantry", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/pantry_tests.gd"])
    run("encounter", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/encounter_tests.gd"])
    run("skeleton_bodies", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/skeleton_tests.gd"])
    run("skill_impact", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/skill_impact_tests.gd"])
    run("duel", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/duel_tests.gd"])
    run("sword_motion", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/sword_motion_tests.gd"])
    run("opening_stare", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/opening_stare_tests.gd"])
    run("coworker_aid", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/coworker_aid_tests.gd"])
    run("female_outfits", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/female_outfit_tests.gd"])
    run("hero_outfit", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/hero_outfit_tests.gd"])
    run("coworker_restoration", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/coworker_restoration_tests.gd"])
    run("finale", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/finale_tests.gd"])
    run("departure", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/departure_tests.gd"])
    run("nightlife", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/nightlife_tests.gd"])
    run("rage", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/rage_tests.gd"])
    run("interface", ["--headless", "--fixed-fps", "60", "--path", ".", "--script", "tests/interface_tests.gd"])
    print("All checks passed. Graphical review and human playtesting remain separate.")
