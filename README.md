# MacFS

Open every app in fullscreen. Tiny native macOS menu-bar agent — one Swift file, zero dependencies, no Xcode.

When an app launches, MacFS puts its windows into fullscreen (native macOS fullscreen, own Space). If you exit fullscreen manually, it stays that way until you relaunch the app.

## Install (from release)

1. Download `MacFS.zip` from [Releases](../../releases) and unzip.
2. Move `MacFS.app` to `/Applications`.
3. First launch: right-click the app → **Open** → **Open**. (It's not notarized; see below.)
4. Grant **System Settings → Privacy & Security → Accessibility → MacFS**.
5. Optional, start at login: **System Settings → General → Login Items → +** → add MacFS.

The app lives in the menu bar (⛶ icon). No Dock icon, no windows.

## Menu

- **Auto-fullscreen at launch** — toggle the feature on/off.
- **Skip frontmost app** — exclude the app you're currently using (e.g. Calculator).
- **Open skip list…** — edit the exclusion list (one bundle id per line) in a text editor.
- **Quit MacFS**

## Build from source

Requires only the Command Line Tools (`xcode-select --install`).

```sh
./install.sh   # builds MacFS.app, copies to /Applications, starts at login
```

Re-running `install.sh` after changing the source changes the binary hash, so macOS will ask you to re-grant Accessibility (remove the old entry first).

## Uninstall

```sh
launchctl unload ~/Library/LaunchAgents/local.macfs.plist
rm ~/Library/LaunchAgents/local.macfs.plist
rm -rf /Applications/MacFS.app ~/Library/Application\ Support/MacFS
```
Then remove MacFS from the Accessibility list.

## Notarization

Releases are ad-hoc signed, so Gatekeeper shows a warning on first launch (step 3 above). Proper notarization requires a paid Apple Developer account; not planned. Build from source if you prefer.

## How it works

Observes `NSWorkspace.didLaunchApplicationNotification`, then sets the Accessibility `AXFullScreen` attribute on each standard window (retrying briefly while the app creates its windows). Falls back to a synthesized ⌃⌘F for apps that ignore the attribute. Logs: `log stream --predicate 'subsystem == "local.macfs"'`.

## License

MIT
