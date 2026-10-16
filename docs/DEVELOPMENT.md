# Development notes — 0.9.0

## References checked on 2026-10-16

- [Official plugin development guide](https://plugins.omarchy.org/develop.html)
- [Omarchy shell development conventions](https://github.com/omacom/omarchy/blob/quattro/agents/skills/shell-dev.md)
- [Plugin runtime reference](https://github.com/omacom/omarchy/blob/quattro/docs/omarchy-shell.md)
- Installed implementations: `/usr/share/omarchy/shell/services/PluginShellApi.qml`,
  `Ui/BarWidget.qml`, `shell.qml` and the built-in plugins.

These documents describe the runtime contract. The component split below is a
Flolinr design decision, not a framework-required directory structure.

## Runtime ownership

`manifest.json` deliberately declares both `panel` and `bar-widget`.
Unlike a small clock popout, Flolinr is an independent editing window, with a
single keep-loaded panel owning its notes. Each monitor can create a bar button,
but that button only toggles the same panel through its scoped shell API.
It must not create a nested Outliner, which would create multiple note writers.

The entry point is an `Item`, with shell-injected `shell` and `manifest`,
`opened`, `open(payloadJson)`, `close()` and `toggle()` lifecycle methods.
Repeated open calls do not reset editing focus. The native window and shell
hide route flush dirty data. Updates preserve the existing plugin ID and schema.
All code runs within the existing shell; no standalone Quickshell is launched.

| File | Responsibility |
|---|---|
| `Outliner.qml` | Panel lifecycle, editing session, navigation and dialog coordination |
| `OutlineNode.qml` | Item rendering, text editing and fixed editing keys; color requests are signals |
| `WorkspaceStore.qml` | One file reader/writer, atomic synchronous flush, load-error write protection |
| `Model.js` | Outline operations, workspace validation, version migration and serialization |
| `KeyboardSettings.qml` | Watched user overrides and last-valid-setting behavior |
| `Keybindings.js` | Action defaults, validation and action-based help labels |
| `ShortcutsDialog.qml` | Self-contained shortcut help using explicit properties |
| `ActionLink.qml` | Shared keyboard-accessible text action |
| `BarWidget.qml` | Left-click toggle only; no storage or polling |

Theme references use `Commons.Color`, avoiding the QtQuick Color type name
collision introduced in Qt 6.12. Fonts use `Commons.Style.fontFamily`.
Settings use `FileView.watchChanges`. The daily clock uses Quickshell's shared
clock, and focus retries are bounded. There is no recurring external probe.

Content remains at `~/.local/share/flolinr/outline.json`, including when
XDG_DATA_HOME differs, to preserve the installed prototype's data location.
Keybinding configuration and installer state honor XDG_CONFIG_HOME and
XDG_STATE_HOME. Installation never copies or resets user notes or settings.

The decoder accepts v1 and v2. The encoder validates a detached snapshot before
replacing a file. User-authored text is never translated during loading, even
when it matches an old starter message. Corrupt input keeps the UI unready and
the file store unwritable. Errors leave dirty edits in memory for retry.

## Repeatable checks

```sh
node tests/model.test.cjs
node tests/keybindings.test.cjs
omarchy plugin validate .
```

For `qmllint`, the import directory must contain a `qs` entry pointing at the
installed shell. Create this temporary import mapping outside the plugin;
Omarchy correctly rejects symlinks inside an installable plugin folder.

```sh
IMPORT_ROOT=$(mktemp -d)
ln -s /usr/share/omarchy/shell "$IMPORT_ROOT/qs"
/usr/lib/qt6/bin/qmllint -I "$IMPORT_ROOT" ./*.qml
rm "$IMPORT_ROOT/qs"
rmdir "$IMPORT_ROOT"
```

Installed Quickshell metadata and dynamic host objects may produce warnings
about `QProcess::ExitStatus`, the bar's injected `shell` property, or the
`edit()` method of a dynamically instantiated ListView delegate. These do not
replace runtime checks. A generic Qt `qmltestrunner` cannot load this system's
Quickshell core plugin, which is hosted by the shell executable.

## Manual integration checks

After installation in an active Omarchy session:

1. Open from the bar and `omarchy-shell shell summon yozniax.flolinr '{}'`.
2. Edit with Japanese IME; Enter confirms IME input before creating a new item.
3. Check indent/outdent, branch move, zoom, color selection and Undo/Redo.
4. Swap two keybindings and disable one; verify help and actual shortcuts agree.
5. Write invalid settings; verify the previous settings remain and help shows an error.
6. Close with Ctrl+W, native window close, and `omarchy-shell shell hide yozniax.flolinr`.
7. Reopen, disable/re-enable, and restart the shell; confirm content persists.
8. Use multiple monitors; all bar buttons must operate the same editor.
9. With an isolated data file, verify malformed data is preserved and saving is disabled.

The source tree is separate from the installed copy. `python scripts/install.py`
validates a staged runtime-only package, backs up the installed copy, then installs
the complete directory with two same-filesystem renames. An installation failure
restores the previous directory. No system-owned files are edited.

## Hot-reload observation on 2026-10-16

The first 0.9.0 installation generated many file-change events and triggered a
Quickshell SIGSEGV during reload (PID 35135). The shell restarted automatically.
The core places the fault in Qt QML garbage collection; JIT frames are unresolved,
so the precise cause is unconfirmed. Available memory ruled out exhaustion.
A prior Quickshell crash was also recorded at 09:48, before this refactoring.

The panel now follows the installed `dev-gallery/GalleryPanel.qml` example:
host-initiated close is guarded and never calls shell.hide back recursively;
user-initiated close goes through requestClose. The installer switches a fully
staged directory instead of writing each live runtime file. These reduce
reentrant lifecycle calls and partial updates, but do not prove a fix for the
underlying Qt crash. Check the shell journal after updates.

## 0.10.0 additions

`AppSettings.qml` resolves settings before activating `WorkspaceStore`. A path change
copies the workspace to a new target or preserves an existing target and requires a
shell reload; it never redirects an unsaved editor in place. `WorkspaceStore` watches
external edits, rejects conflicting reloads while dirty, and blocks writes on missing
or malformed data. This is conflict detection, not a distributed merge protocol.

`QuickCapture.qml` is a second lightweight window routed through the SAME panel and
writer using `{ "mode": "capture" }`. It does not create another storage owner.
`FeatureController.qml` uses `bridge.py` for Markdown files, new-location copies,
and an explicitly requested stdin/stdout LLM CLI. `FeaturePanel.qml` owns previews
and applies AI output only on request with a branch snapshot check and Undo.

Markdown exchange preserves text/hierarchy, not Flolinr metadata. Search carries
stable Roll/node IDs across all Rolls and dates. The app identity icon is the
user-provided `flolinr.svg`, drawn by `FlolinrIcon.qml` with theme-colored strokes.

Claude CLI flags were checked against https://code.claude.com/docs/en/cli-reference .
Hyprland window rules were checked against
https://wiki.hypr.land/Configuring/Basics/Window-Rules/ and the installed Lua helpers.
The added Super+Ctrl+M binding was checked against default/user config files.
Compositor IPC is unavailable from this execution environment: `hyprctl reload`
and `hyprctl configerrors` fail with a socket timeout error. `luac -p` validates
Lua syntax, but actual key routing and floating-window behavior still need a live
session check. Likewise, the real LLM CLI could not start through mise's network
version lookup; fake-CLI integration tests cover the adapter without sending notes.
