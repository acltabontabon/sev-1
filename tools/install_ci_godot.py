#!/usr/bin/env python3
"""Install the pinned official editor/templates on a GitHub Windows or Mac runner."""
import hashlib
import os
from pathlib import Path
import subprocess
import sys
import urllib.request
import zipfile

VERSION = "4.7.2"
BASE = f"https://github.com/godotengine/godot/releases/download/{VERSION}-stable"


def main():
    work = Path(os.environ["RUNNER_TEMP"]) / "sev1-godot"
    work.mkdir(parents=True, exist_ok=True)
    sums = urllib.request.urlopen(f"{BASE}/SHA512-SUMS.txt", timeout=60).read().decode()
    checksums = {line.split()[1].lstrip("*"): line.split()[0] for line in sums.splitlines() if line.strip()}
    windows = sys.platform == "win32"
    editor_name = f"Godot_v{VERSION}-stable_" + ("win64.exe.zip" if windows else "macos.universal.zip")
    templates_name = f"Godot_v{VERSION}-stable_export_templates.tpz"
    for name in (editor_name, templates_name):
        target = work / name
        urllib.request.urlretrieve(f"{BASE}/{name}", target)
        with target.open("rb") as source:
            checksum = hashlib.file_digest(source, "sha512").hexdigest()
        if checksum != checksums[name]:
            raise SystemExit(f"Official checksum mismatch: {name}")
    if windows:
        with zipfile.ZipFile(work / editor_name) as archive:
            archive.extractall(work)
        editor = work / f"Godot_v{VERSION}-stable_win64_console.exe"
        templates = Path(os.environ["APPDATA"]) / "Godot/export_templates" / f"{VERSION}.stable"
    else:
        subprocess.run(["ditto", "-x", "-k", str(work / editor_name), str(work)], check=True)
        editor = work / "Godot.app/Contents/MacOS/Godot"
        templates = Path.home() / "Library/Application Support/Godot/export_templates" / f"{VERSION}.stable"
    templates.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(work / templates_name) as archive:
        for name in ("version.txt", "macos.zip", "windows_release_x86_64.exe", "windows_release_x86_64_console.exe", "windows_debug_x86_64.exe"):
            (templates / name).write_bytes(archive.read(f"templates/{name}"))
    with open(os.environ["GITHUB_ENV"], "a", encoding="utf-8") as env:
        env.write(f"GODOT_BIN={editor.as_posix()}\n")
    print(f"Installed official Godot {VERSION}, SHA-512 verified")


if __name__ == "__main__":
    main()
