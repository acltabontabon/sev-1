#!/usr/bin/env python3
"""Build native unsigned release packages after the full validator passes."""
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from release import run, digest, VERSION, LOGS


def release_notes(tag):
    if tag != f"v{VERSION}":
        raise SystemExit(f"Tag {tag!r} must match project version v{VERSION}")
    text = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
    match = re.search(rf"^## \[{re.escape(VERSION)}\][^\n]*\n(.*?)(?=^## |\Z)", text, re.M | re.S)
    if not match:
        raise SystemExit(f"Missing changelog entry for {VERSION}")
    return match.group(1).strip() + "\n"


def main():
    tag = sys.argv[1] if len(sys.argv) == 2 else ""
    notes = release_notes(tag)
    project = (ROOT / "project.godot").read_text()
    if f'config/version="{VERSION}"' not in project:
        raise SystemExit("Project version and release helper disagree")
    windows = sys.platform == "win32"
    if not windows and sys.platform != "darwin":
        raise SystemExit("Run packaging on native Windows or macOS")
    target = "windows-x86_64" if windows else "macos-x86_64"
    out = ROOT / "builds/ci" / target
    if out.exists():
        shutil.rmtree(out)
    stage = out / "stage"
    stage.mkdir(parents=True)
    LOGS.mkdir(exist_ok=True)
    godot = ["sh", str(ROOT / "tools/godot.sh")]
    run("ci_version", [*godot, "--version"])
    presets = ROOT / "export_presets.cfg"
    original = presets.read_text()
    for key in ("application/short_version", "application/version", "application/file_version", "application/product_version"):
        if f'{key}="{VERSION}"' not in original:
            raise SystemExit(f"Preset {key} must match {VERSION}")
    # Only this isolated CI checkout changes: local tester export keeps its ad-hoc signature.
    ci_presets = original.replace('binary_format/architecture="universal"', 'binary_format/architecture="x86_64"').replace('codesign/codesign=3', 'codesign/codesign=0')
    ci_presets = ci_presets.replace('[preset.1.options]', '[preset.1.options]\ndebug/export_console_wrapper=2')
    presets.write_text(ci_presets)
    try:
        app = stage / ("SEV-1.exe" if windows else "SEV-1 Friday Deployment.app")
        run("ci_export", [*godot, "--headless", "--path", str(ROOT), "--export-release", "Windows Desktop" if windows else "macOS", str(app)], timeout=600)
    finally:
        presets.write_text(original)
    if windows:
        executable = stage / "SEV-1.console.exe"
        if not executable.is_file():
            raise SystemExit("Windows export is missing its diagnostic console wrapper")
        if not (stage / "SEV-1.pck").is_file():
            raise SystemExit("Windows export is missing its PCK")
    else:
        info = plistlib.loads((app / "Contents/Info.plist").read_bytes())
        if info["CFBundleShortVersionString"] != VERSION:
            raise SystemExit("Mac bundle version mismatch")
        executable = app / "Contents/MacOS" / info["CFBundleExecutable"]
        if run("ci_architecture", ["lipo", "-archs", str(executable)]) != "x86_64":
            raise SystemExit("Mac export must contain Intel x86_64 only")
        if not list((app / "Contents/Resources").glob("*.pck")):
            raise SystemExit("Mac export is missing its PCK")
    with tempfile.TemporaryDirectory(prefix="sev1-ci-smoke-") as temporary:
        smoke = run("ci_smoke", [str(executable), "--headless", "--fixed-fps", "60", "--", "--release-smoke"], timeout=300, cwd=temporary)
        if "RESULT: 0 failure(s)" not in smoke:
            raise SystemExit("Packaged gameplay smoke did not report success")
    for source, name in [("CHANGELOG.md", "CHANGELOG.md"), ("docs/install.md", "INSTALL.md"), ("docs/testing.md", "TESTING.md"), ("docs/asset_licenses.md", "ASSET_LICENSES.md"), ("THIRD_PARTY_NOTICES.txt", "THIRD_PARTY_NOTICES.txt")]:
        shutil.copy2(ROOT / source, stage / name)
    if windows:
        compiler = Path(os.environ.get("ProgramFiles(x86)", "C:/Program Files (x86)")) / "Inno Setup 6/ISCC.exe"
        run("ci_installer", [str(compiler), f"/DAppVersion={VERSION}", f"/DSourceDir={stage}", f"/DOutputDir={out}", str(ROOT / "tools/windows_installer.iss")], timeout=300)
        installer = out / f"SEV-1-{VERSION}-{target}-setup.exe"
        with tempfile.TemporaryDirectory(prefix="sev1-install-") as temporary:
            installed = Path(temporary) / "game"
            run("ci_install", [str(installer), "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART", "/SP-", "/TASKS=", f"/DIR={installed}"], timeout=120)
            if digest(installed / "SEV-1.exe") != digest(app) or digest(installed / "SEV-1.pck") != digest(stage / "SEV-1.pck"):
                raise SystemExit("Installed game differs from tested export")
            smoke = run("ci_installed_smoke", [str(installed / "SEV-1.console.exe"), "--headless", "--fixed-fps", "60", "--", "--release-smoke"], timeout=300, cwd=temporary)
            if "RESULT: 0 failure(s)" not in smoke:
                raise SystemExit("Installed game smoke failed")
            run("ci_uninstall", [str(installed / "unins000.exe"), "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART"], timeout=120)
    else:
        (stage / "Applications").symlink_to("/Applications", target_is_directory=True)
        installer = out / f"SEV-1-{VERSION}-{target}.dmg"
        run("ci_dmg", ["hdiutil", "create", "-volname", f"SEV-1 {VERSION}", "-srcfolder", str(stage), "-format", "UDZO", str(installer)], timeout=300)
        run("ci_dmg_verify", ["hdiutil", "verify", str(installer)])
    manifest = {"version": VERSION, "tag": tag, "source_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(), "platform": target, "godot": "4.7.2.stable", "signed": False, "notarized": False, "source_validation": "passed (workflow prerequisite)", "packaged_headless_smoke": "passed", "human_playtest": "pending", "installer": installer.name, "sha256": digest(installer)}
    (out / f"manifest-{target}.json").write_text(json.dumps(manifest, indent=2) + "\n")
    (out / f"SHA256SUMS-{target}.txt").write_text(f"{digest(installer)}  {installer.name}\n")
    (out / "release-notes.md").write_text(notes, encoding="utf-8")
    print(f"Built {installer}")


if __name__ == "__main__":
    main()
