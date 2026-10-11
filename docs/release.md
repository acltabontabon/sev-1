# Release engineering

## Tagged GitHub releases (0.2.47 onward)

The creator has accepted unsigned, unnotarized distribution for this personal
project. Developer ID certificates and notarization are not release requirements.
This does not close gameplay, visual, audio or performance acceptance gates.

`.github/workflows/release.yml` runs on `v*` tag pushes. Native `windows-2022` and
Intel `macos-15-intel` runners check out Git LFS assets, install official Godot
4.7.2 standard and templates (verified against official SHA-512 sums), run the full
validator, export x86-64 only and run packaged headless gameplay smoke. Windows
uses the runner's Inno Setup 6 compiler and verifies silent installation, installed
gameplay smoke and uninstallation. Mac builds and verifies a drag-to-Applications
DMG. Packages include installation, changelog, testing and license notes.

Both builds must pass before a draft GitHub release is created, assets/checksums/
source manifests uploaded, and the release published. Build failures leave logs
in Actions artifacts. Publication retries use the same tag and replace its assets;
manual retries must select an existing version tag, not `main`. Do not move a
published tag. Headless runner checks do not prove ordinary GPU/audio compatibility.

For the next release, update `config/version` in `project.godot`, all version/path
fields in `export_presets.cfg`, `VERSION` in `tools/release.py`, the README version,
and add its entry to root `CHANGELOG.md`. Validate, commit on main, then:

```sh
git push origin main
git tag -a v0.2.48 -m "SEV-1 0.2.48"
git push origin v0.2.48
```

Tag and changelog/project/preset versions must agree. The pipeline requires no
signing secrets. Only its publication job has `contents: write` permission.
[Install and unsigned-app instructions](install.md) own user-facing setup.

The existing `sh tools/release.sh` remains a separate local universal Mac tester
gate with an ad-hoc integrity signature. CI temporarily overrides its preset to
Intel and disables signing in its isolated checkout, restoring it after export.
No paid identity or notarization is used by either path.

## Historical local tester evidence


Milestone 12 moved the version to **0.2.0**; `tools/release.py` derives archive and
staging names from `VERSION`. The sections below describe the 0.1.0 baseline workflow,
which is unchanged apart from the version and the larger asset set (fonts, textures,
props, sound effects and music, all inside the resource package).

## Baseline and disposition

Inspected clean `main` at `1a074b5` on 10 October 2026. Read direction/design/roadmap
and implementation documentation, Input Map, incident states, reset ownership,
provenance, and historical performance evidence. Baseline import, parsing and all
341 existing assertions passed with normal macOS user-directory permissions.
The first sandbox attempt failed on certificate/editor-settings access, not gameplay.

| Severity | Audit finding | Disposition |
| --- | --- | --- |
| P0 for standalone delivery | No export templates, preset or standalone build | Official matching templates obtained; macOS preset/export/signature and packaged smoke implemented |
| P1 usability | No title, explicit navigation or saved settings | Local application screen owner and native ConfigFile preferences implemented |
| P1 reliability risk | New screens could compete with decisions, reports, focus and R | Ten application lifecycle cycles cover those boundaries; original incident/combat suites preserved |
| P1 | Cold first-render and first-use frame hitches | Reproduced and phase/CPU-timed; open creator performance acceptance gate |
| P1 public distribution | No Developer ID/notarization | Ad-hoc local tester build only; credentials/public distribution remain a human follow-up |
| P2 | Native models, approximate animation/hit cones, synthesized sound, unmeasured human balance/pacing | Preserved as declared temporary content; tester questionnaire supplied |
| P3 | Windows runtime, controller/remapping, later chapters | Deferred; Windows preset only, no compatibility claim |

No incomplete incident beat required adding new gameplay. Existing technical tests
cover opening, live enemy combat, investigation, both upgrades, all corporate paths,
debt, Burnout, boss shield/copies, victory/defeat and clean retries. No combat values
were changed without human evidence. Audio source samples were inspected for clipping;
all players now route through Effects, including dynamically created melee/cue audio.
There is no score/voice track. Listening acceptance remains required.

## Build

Use Godot **4.7.2 stable standard**. Install matching templates from the
[official archive](https://godotengine.org/download/archive/4.7.2-stable/) through
Godot's Manage Export Templates. The expected macOS location is
`~/Library/Application Support/Godot/export_templates/4.7.2.stable/` with `version.txt`
and `macos.zip`. This machine has only the macOS and Windows x86-64 templates extracted
from the official TPZ, not every platform. No automatic engine upgrade is performed.

```sh
sh tools/release.sh
```

The shell entry invokes one standard-library Python helper. It verifies the pinned
engine/templates/resources, runs the full validator, exports, checks plist/PCK and
ad-hoc signature, launches outside the repository, completes packaged smoke, then
creates a ZIP and SHA-256 manifest. Each subprocess has a deadline and logged engine
errors fail the build even with exit code zero. Logs live under ignored `logs/`.
A failed rebuild removes the old success manifest but preserves prior artifacts;
do not distribute an old ZIP as evidence that a failed build passed.

Outputs under ignored `builds/releases/<version>/` (now `0.2.0`):

- `SEV-1 Friday Deployment.app`
- `SEV-1-Friday-Deployment-<version>-macOS.zip` containing the app and tester/license notes
- `manifest.json` with source revision/dirty state/content digest, template hash,
  archive hash, validation/smoke results and honest signing/platform limits

The preset excludes development tests/tools/docs/builds from the runtime resources.
Engine notices are explicitly included. ASTC import is enabled for Apple Silicon.
No original app icon existed; the default Godot icon remains. The Windows preset
is x86-64 with a separate PCK. It has not been runtime-tested or declared supported.

## Packaged verification

Godot release templates do not support the editor's external `--script` harness.
A small opt-in `-- --release-smoke` probe therefore lives alongside the application
screen code. Without that explicit flag it never runs or modifies the game.
The probe uses the exported main scene/resources, performs real F attacks with normal
boss windows and live AI, traverses upgrades/management, verifies victory/restart/death
and menu cleanup, then exits nonzero on failure. Elevated health and staged positions
make it a technical test rather than normal play. Preferences use a separate test path.
Graphical mode additionally captures title/opening/combat/boss/victory under the app's
user directory. The regular release script runs headless; graphical checks are separate.

```sh
"builds/releases/0.2.0/SEV-1 Friday Deployment.app/Contents/MacOS/SEV-1 Friday Deployment" --resolution 1920x1080 --fixed-fps 60 -- --release-smoke
```

This accelerated graphical probe is not a frame-time benchmark. Source graphical
probes remain available for measured performance:

```sh
sh tools/godot.sh --path . --resolution 1920x1080 --script tests/stabilization_preview.gd
sh tools/godot.sh --path . --resolution 1920x1080 --script tests/incident_preview.gd -- --burnout --measure
```

## Signing and remaining acceptance

The bundle is universal arm64/x86-64, **ad-hoc signed**, with no Apple team identity,
Developer ID signing or notarization. `codesign --verify --deep --strict` checks local
integrity; it is not Gatekeeper/notarization approval. See
[Godot macOS distribution documentation](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_macos.html).
Do not embed signing credentials in source or claim trusted public distribution.

Only the current M2 Pro is the graphical execution/performance baseline. Another-Mac,
Intel, minimum OS and Windows runtime tests are outstanding. The first-use hitches
and ordinary human gameplay/audio acceptance remain open. A successful build produces
a local tester candidate; **Milestone 10 is not creator-accepted**
until the remaining gameplay/performance gates are explicitly accepted or resolved.
Unsigned public distribution was subsequently accepted for the personal project;
see the tagged-release policy above.


## Verified checkpoint

The full suite passed **487 assertions**: 341 existing plus 146 release checks,
with imports and every script parse passing. The release workflow completed export,
plist/PCK checks, ad-hoc signature verification, standalone headless launch, and a
packaged real-melee smoke run through both upgrades, management, six enemies, victory,
restart, damage-triggered defeat, and menu cleanup. The ZIP is extracted and its
signature/executable integrity checked before a successful manifest is written.

A separate packaged Forward+/Metal run at 1920×1080 completed the same sequence with
no logged engine errors. Title, office/combat, boss and postmortem frames were captured;
menu/settings/controls/pause/report layouts were also rendered at 1280×720. The smoke
simulation is accelerated, with elevated health and staged positions; its 1:19 incident
time is not ordinary player pacing. The final report action row and narrower combat
status column address clipping/marker overlap observed during this review.

The twelve source WAVs have no clipped 16-bit samples. Peak levels range from −25.6
to −4.1 dBFS before existing per-player attenuation; this verifies sample bounds, not
perceived loudness or a finished mix. No external sound was introduced.

Native Computer Use inspection timed out; engine-rendered captures and packaged
input simulation provide graphical/technical evidence, not a human playthrough.
The current lifecycle performance result and remaining P1 gates are recorded in
[release notes](release_notes.md). No release-ready or human-accepted claim is made.

## Milestone 11 isolated voice candidate

`sh tools/release.sh --voice-candidate` keeps version 0.1.0 but exports under
`builds/releases/0.1.0-voices` so the earlier tester package is preserved. It includes
VOICES.md and VOICE_PROVENANCE.json beside the app and usual tester documentation.
On 10 October 2026, checkpoint `a7462ee` passed the complete gate, including all
22 packaged voice resources, combat smoke, and ZIP signature verification. See
[voice validation evidence](voices.md#recorded-evidence--10-october-2026).
Human listening, notarization and Windows acceptance remain separate.

## 0.2.46 — Stage One saves and Replay (11 October 2026)

Built from a frozen source copy so concurrent scene-flow work could not change files
between validation and export. Outputs are in `builds/releases/0.2.46/`: the Mac app,
`SEV-1-Friday-Deployment-0.2.46-macOS.zip`, and `manifest.json`. The manifest records
that exact copy's source commit, dirty state and digest, rather than claiming the
live checkout is identical. Later HUD performance edits are outside this package.

Full validation, export, bundle/ZIP signature verification, standalone launch and
packaged headless real-melee smoke passed. The packaged probe verified earlier tester
unlock, saving on victory, saved-progress title, Replay Stage One and disk completion
surviving replay. Final graphical menu smoke passed at 1280×720, Forward+/Metal on
Apple M2 Pro. The saved title was inspected from an engine capture; the tester unlock
screen was also inspected in the actual app through native UI. The app was left on
its title without changing the player's chapter save. These are layout/behavior
checks, not a performance measurement or a human combat playthrough.

The first frozen-copy import reported missing theme fonts before importing them;
retrying after import completed passed the entire gate. A preliminary full graphical
combat probe did not complete its staged route (six downstream assertions failed).
Final verification covers headless packaged combat and rendered menus; full graphical
combat/audio/fun acceptance remains a creator playtest checkpoint.

Evidence: `logs/save_rebuild_final_validation.log`, `logs/save_rebuild_final_smoke.log`,
and `logs/save_rebuild_final_menus.log`. Build output and captures are ignored. The app
is ad-hoc signed, not notarized; Windows runtime acceptance remains open.
