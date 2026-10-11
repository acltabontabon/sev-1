# Install SEV-1

Download the package for your computer from the
[GitHub Releases page](https://github.com/acltabontabon/sev-1/releases).
Godot is bundled: no editor, Python or developer tools are required.

## Windows (x86-64)

Windows 10 or newer, keyboard/mouse and a Vulkan-capable GPU are required for
the current Forward+ renderer. Download `SEV-1-<version>-windows-x86_64-setup.exe`
and run it. The installer uses your user account, requires no administrator access,
and offers a desktop shortcut. Launch SEV-1 from the Start menu.
Uninstall through Settings → Apps; your saved progress/settings stay in your user
profile. Reinstalling/updating keeps them.

The installer is unsigned. Windows may show SmartScreen's unknown-publisher prompt:
if you trust this project and downloaded it from the release above, choose
**More info → Run anyway** when available.

## Intel Mac (x86-64)

macOS 14 or newer, keyboard/mouse and a Metal-capable GPU are required.
Download `SEV-1-<version>-macos-x86_64.dmg`, open it, and drag
**SEV-1 Friday Deployment.app** onto **Applications**. Eject the disk image, then
open the app from Applications. To uninstall, move the app to Trash; saves/settings
stay in `~/Library/Application Support/SEV-1/`.

This personal project is unsigned and unnotarized. If macOS blocks it, attempt to
open it, then use **System Settings → Privacy & Security → Open Anyway** and confirm.
If macOS labels the download damaged and that option is unavailable, only for this
trusted download you can remove the app's quarantine attribute in Terminal:

```sh
xattr -dr com.apple.quarantine "/Applications/SEV-1 Friday Deployment.app"
```

This release targets Intel Macs only; Apple Silicon is not a supported target for
these CI packages. No system-wide security settings need to change.

## Play and feedback

Choose **Acknowledge Incident**. WASD moves, mouse aims the camera, left-click/F
attacks, right-click/Q dodges, E interacts, and Escape pauses. The title's
**Onboarding Docs** lists all special moves. Stage One completion saves; Stage Two
is coming later. See the included `TESTING.md` for playtest feedback.

Automated headless checks cover logic and package launch. They do not establish
GPU compatibility, audio quality, frame rate or fun on your computer.
