#!/usr/bin/env python3
"""Small macOS release gate. No credentials or network access required."""
import datetime
import hashlib
import json
from pathlib import Path
import plistlib
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
VERSION = "0.2.16"
OUT = ROOT / "builds/releases" / VERSION
LOGS = ROOT / "logs"
APP = OUT / "SEV-1 Friday Deployment.app"
ERROR = re.compile(r"SCRIPT ERROR:|(?:^|\n)ERROR:|Parse Error:|FAIL:")


def run(name, args, timeout=180, cwd=ROOT):
    try:
        result = subprocess.run(args, cwd=cwd, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, text=True, timeout=timeout)
    except subprocess.TimeoutExpired as exc:
        output = exc.stdout or b""
        (LOGS / f"release_{name}.log").write_bytes(output if isinstance(output, bytes) else output.encode())
        raise SystemExit(f"FAIL {name}: timeout; see logs/release_{name}.log")
    (LOGS / f"release_{name}.log").write_text(result.stdout)
    if result.returncode or ERROR.search(result.stdout):
        raise SystemExit(f"FAIL {name}: see logs/release_{name}.log\n{result.stdout[-2500:]}")
    print(f"PASS {name}", flush=True)
    return result.stdout.strip()


def digest(path):
    h = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def main():
    if sys.platform != "darwin":
        raise SystemExit("This release script requires macOS (codesign and ditto). Windows preset is preparatory only.")
    global OUT, APP
    if sys.argv[1:] == ["--voice-candidate"]:
        OUT = ROOT / "builds/releases" / (VERSION + "-voices")
        APP = OUT / "SEV-1 Friday Deployment.app"
    elif len(sys.argv) != 1:
        raise SystemExit("Usage: sh tools/release.sh [--voice-candidate] (always validates before export)")
    OUT.mkdir(parents=True, exist_ok=True)
    LOGS.mkdir(exist_ok=True)
    # Remove only the stale success marker, never previous artifacts, before any gate.
    manifest = OUT / "manifest.json"
    manifest.unlink(missing_ok=True)
    godot = ["sh", str(ROOT / "tools/godot.sh")]
    version = run("version", [*godot, "--version"])
    templates = Path.home() / "Library/Application Support/Godot/export_templates/4.7.2.stable"
    if not (templates / "macos.zip").is_file() or not (templates / "version.txt").is_file():
        raise SystemExit("Missing Godot 4.7.2 standard templates. Install the official TPZ via Godot > Manage Export Templates. See docs/release.md.")
    if (templates / "version.txt").read_text().strip() != "4.7.2.stable":
        raise SystemExit("Template version mismatch: require 4.7.2.stable")
    for resource in ["game/release/front_end.tscn", "game/incidents/missing_transaction.tscn", "THIRD_PARTY_NOTICES.txt", "docs/testing.md", "docs/release_notes.md"]:
        if not (ROOT / resource).is_file():
            raise SystemExit(f"Missing required release resource: {resource}")
    run("validation", [sys.executable, "tools/validate.py"], timeout=600)
    run("export", [*godot, "--headless", "--path", ".", "--export-release", "macOS", str(APP)], timeout=300)
    info = plistlib.loads((APP / "Contents/Info.plist").read_bytes())
    if info["CFBundleShortVersionString"] != VERSION or info["CFBundleIdentifier"] != "com.mayhemprod.sev1":
        raise SystemExit("Unexpected application version or identifier")
    executable = APP / "Contents/MacOS" / info["CFBundleExecutable"]
    if not list((APP / "Contents/Resources").glob("*.pck")):
        raise SystemExit("Export is missing its resource package")
    run("signature", ["codesign", "--verify", "--deep", "--strict", str(APP)])
    signature = run("signing_identity", ["codesign", "-dv", str(APP)])
    if "Signature=adhoc" not in signature:
        raise SystemExit("Expected an ad-hoc test build; inspect signing identity before distributing")
    with tempfile.TemporaryDirectory(prefix="sev1-release-") as temporary:
        run("launch", [str(executable), "--headless", "--verbose", "--quit-after", "10"], cwd=temporary)
        smoke = run("smoke", [str(executable), "--headless", "--fixed-fps", "60", "--", "--release-smoke"], cwd=temporary)
        if "RESULT: 0 failure(s)" not in smoke:
            raise SystemExit("Smoke probe did not report successful completion")
    for source, name in [("docs/testing.md", "TESTING.md"), ("docs/release_notes.md", "RELEASE_NOTES.md"), ("docs/asset_licenses.md", "ASSET_LICENSES.md"), ("THIRD_PARTY_NOTICES.txt", "THIRD_PARTY_NOTICES.txt"), ("docs/voices.md", "VOICES.md"), ("assets/audio/voices/provenance.json", "VOICE_PROVENANCE.json")]:
        shutil.copy2(ROOT / source, OUT / name)
    archive = OUT / f"SEV-1-Friday-Deployment-{VERSION}-macOS.zip"
    # Archive app plus tester documents; a fresh staging directory avoids stale files.
    with tempfile.TemporaryDirectory(prefix="sev1-package-") as temporary:
        staging = Path(temporary) / f"SEV-1-Friday-Deployment-{VERSION}"
        staging.mkdir()
        run("stage", ["ditto", str(APP), str(staging / APP.name)])
        for name in ["TESTING.md", "RELEASE_NOTES.md", "ASSET_LICENSES.md", "THIRD_PARTY_NOTICES.txt", "VOICES.md", "VOICE_PROVENANCE.json"]:
            shutil.copy2(OUT / name, staging / name)
        run("zip", ["ditto", "-c", "-k", "--keepParent", str(staging), str(archive)])
    with tempfile.TemporaryDirectory(prefix="sev1-unzip-") as temporary:
        run("unzip", ["ditto", "-x", "-k", str(archive), temporary])
        unpacked = Path(temporary) / f"SEV-1-Friday-Deployment-{VERSION}" / APP.name
        run("archive_signature", ["codesign", "--verify", "--deep", "--strict", str(unpacked)])
        if digest(unpacked / "Contents/MacOS" / executable.name) != digest(executable):
            raise SystemExit("Archived executable differs from tested build")
    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    dirty = bool(subprocess.check_output(["git", "status", "--porcelain"], cwd=ROOT, text=True))
    source_hash = hashlib.sha256()
    sources = [ROOT / "project.godot", ROOT / "export_presets.cfg", ROOT / "default_bus_layout.tres", ROOT / "THIRD_PARTY_NOTICES.txt"]
    for directory in ["game", "assets", "tools", "tests", "docs"]:
        sources.extend(p for p in (ROOT / directory).rglob("*") if p.is_file() and "__pycache__" not in p.parts)
    for path in sorted(sources):
        source_hash.update(str(path.relative_to(ROOT)).encode())
        source_hash.update(path.read_bytes())
    manifest.write_text(json.dumps({"version": VERSION, "built_at_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "godot": version, "source_commit": commit, "source_dirty": dirty, "source_sha256": source_hash.hexdigest(),
        "template_sha256": digest(templates / "macos.zip"), "archive": archive.name, "archive_sha256": digest(archive),
        "signing": "ad-hoc", "notarized": False, "validation": "passed", "packaged_headless_smoke": "passed",
        "graphical_and_human_acceptance": "See release notes; not established by this script", "windows_runtime_tested": False}, indent=2) + "\n")
    print(f"Built local test release: {archive}\nAd-hoc signed; NOT notarized. Human acceptance remains separate.")


if __name__ == "__main__":
    main()
