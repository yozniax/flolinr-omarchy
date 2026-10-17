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

## 0.10.1 — presentation only

`CompactDialog.qml` supplies shared 11px/light body fonts, a 13px header, and
quiet theme-aware borders/text for every feature dialog. FeaturePanel sizes
settings/Markdown to their content; AI retains a bounded preview area. The
calendar is capped at 400×460 and its activity list at 72px, with scrolling for
smaller available heights. Sidebar calendar-tree state has been removed; both
calendar key actions open the modal. Today's note stays above the Rolls area.
`FlolinrIcon.contentScale` defaults to 0.75 without changing layout dimensions
or the original SVG. No user data/schema/settings migration is involved.

## 0.11.0 — file-based outline interchange

`FileTransfer.qml` wraps QtQuick.Dialogs.FileDialog, attached to the editor's
actual Qt window through Window.window. Import uses OpenFile; Export uses
SaveFile with Markdown/OPML/Plaintext filters and matching default suffixes.
Qt handles overwrite confirmation. `FeatureController.transfer` starts the
helper only after file selection is accepted. Cancelling never starts I/O.
FeaturePanel now handles only settings and AI; no import/export path field remains.

`interchange.py` implements OPML 2.0 text/hierarchy and indentation-based plaintext;
Markdown stays in Model.js. Imports become fresh validated nodes and a new Roll.
OPML rejects DTD/entity declarations, excessive depth/item counts and XML-invalid
characters. File URLs are decoded as local paths, including Unicode and spaces.
Exports publish complete files by atomic replacement only after the SaveFile
confirmation; new-location copies remain exclusive and never overwrite.

The standalone file chooser has a QtTest smoke test that works without the
Quickshell core plugin. It verifies actual parent window attachment, opening,
OpenFile/SaveFile modes, format filters and suffix updates using Qt's fallback
dialog in an offscreen window. Native GTK/portal appearance is still a live-session
check. Reference: https://doc.qt.io/qt-6/qml-qtquick-dialogs-filedialog.html
OPML format: https://opml.org/spec2.opml

## 0.11.1 — native chooser crash workaround

Import was clicked at 12:46 and 12:47 on 2026-10-16. Cores 88374 and 92445
show SIGABRT, with GLib `g_malloc`/GVariant construction, GIO D-Bus calls, and
(in the first stack) GTK and GVFS directory-monitor creation. The journal reports
`failed to allocate 4 bytes`; available RAM was approximately 7 GiB when examined.
This identifies the failing native chooser path, not a proven root cause of the
allocation failure. No core was extracted and no global GTK settings were changed.

`FileTransfer.qml` now sets FileDialog.DontUseNativeDialog for both modes. This
avoids the GTK chooser while retaining Qt's format selection and overwrite
confirmation. Regression checks assert the option explicitly and repeatedly
open/reject Import/Export. Earlier offscreen tests only exercised Qt's fallback,
so they did not cover the actual GTK path. The workaround forces the tested path
regardless of the host's platform theme. The sidebar Import link is separate from
the editor's Export link. Live compositor operation still needs confirmation.

## 0.11.2 — Workflowy import compatibility

The user's selected Workflowy export failed XML parsing because a text attribute
contained one literal U+0008. A read-only run of the complete bridge → imported
node → validated workspace path now accepts all 1,616 items (maximum depth 10).
No private source document or imported content is included in the repository.

The OPML decoder removes only XML-invalid literal characters and invalid numeric
character references, preserving legal tabs/newlines and ordinary text. It returns
warnings so the editor shows a completion notice. DTD/entity rejection runs AFTER
normalization to prevent obfuscated declarations from bypassing the check.
The original import file is never rewritten. Other import failures now appear in
a modal instead of only the transient status label. A palette binding loop seen
in the journal was also removed by assigning buttonText its color directly.

## 0.12.0 — AI connection adapters

`AiSettings.js` validates and migrates non-secret profiles (`aiConnections`,
`activeAiConnectionId`). New installations are deliberately unconfigured; old
explicit `aiCommand` arrays migrate to a custom profile. `AppSettings.qml` applies
saved AI profiles on FileView.onSaved without redirecting the active workspace.
`FeaturePanel.qml` owns unsaved profile edits and clears password input on switch
and close. A test cannot become a branch preview. Failed generations invalidate
application snapshots. No login or model request is performed automatically.
CLI auth status checks run locally when a profile is selected.

`ai_backend.py` owns presets, auth status, terminal login, generation and Secret
Service access. Keys travel to the helper and secret-tool over stdin, never argv,
and never return to QML. Keyring records are scoped to connection ID, provider
and endpoint fingerprint; changing a compatible URL cannot forward the old key.
No keyring fallback file exists. Provider error bodies / raw CLI stderr are not
shown because they can echo private text or credentials. HTTP redirects are
rejected, remote HTTP is refused, and API response size is bounded. Test requests
contain a fixed sentence rather than any editor data. OpenAI uses Responses with
store=false; Anthropic Messages and Ollama native /api/chat have separate adapters.
Compatible endpoints use /chat/completions. Plain model IDs are user-entered so
there is no background model-list network request.

References: official OpenAI documentation at
https://developers.openai.com/codex/auth and
https://developers.openai.com/api/docs/guides/text ;
https://docs.ollama.com/api/chat ; installed CLI --help for version-specific flags.
Codex preset ignores user config, disables shell/web tools and uses a read-only
sandbox in a fresh temporary directory. Claude preset disables tools, MCP,
settings sources and slash commands. Custom CLI behavior is user-controlled.

Repeatable tests cover profile migration / secret stripping, UI provider selection
and password clearing, fixed test input, CLI argument contracts / auth status,
keyring stdin handling, missing-keyring failures, response parsing, HTTP auth
errors and redirect refusal against a local mock server. The QML fixture supplies
only theme singletons, allowing the real settings panel to run without Quickshell.

Live checks on this terminal: Codex reported ChatGPT authentication and the actual
preset returned the exact fixed connection-test outline. Secret Service stored,
read and removed a dummy value successfully. No notes were sent. Other real
providers need the user's own credentials / local model and were covered by mocks.

## 0.12.1 — outline cursor editing

OutlineNode intercepts unmodified arrow keys only at visual/text boundaries; Qt
continues to handle intra-item movement, wrapping and Shift selection. Navigation
uses visible rows (respecting collapse/zoom) and carries the caret's horizontal
position to the first/last visual line of the destination. Deferred delegate focus
accepts an explicit cursor target; Enter focuses position zero instead of the end.
The zoom title participates in navigation and splitting; splitting the zoom root
opens its parent view to expose the new sibling.

Model.splitNode preserves the original ID and descendants and inserts a sibling
after its branch. Selected text is removed before splitting; the suffix retains
newlines and inherits color. Splitting is a single structural undo snapshot. The
existing inputMethodComposing guard bypasses editing key handlers during IME
composition. Automated Qt tests exercise the actual TextArea's Enter, selection,
Shift+Enter, wrapping, arrow boundaries and modifier behavior; actual Japanese IME
candidate confirmation remains a manual desktop check.

## 0.12.2 — Backspace merge

Unmodified Backspace at an unselected cursor position zero joins the preceding
visible item (or zoom title for its first child). Model.mergeNode keeps destination
identity/metadata, concatenates text without inserting whitespace and reparents
the removed node's descendants under the destination. Collapsed predecessors are
expanded; hidden text is never selected as a merge destination. Structural merge
uses the existing undo snapshot, and deferred focus restores the caret to the seam.
Model tests cover sibling/parent/deeper destinations and child preservation; actual
Qt key tests cover boundary merge, ordinary deletion and selection deletion.

## 0.12.3 — categorized shortcut help

Keybindings.helpSections uses action IDs to group the existing catalog; it never
matches descriptions by default key. Every configurable action occurs exactly once.
The dialog adds section headings, separators and a responsive key/description grid,
with vertical scrolling and no horizontal overflow. Node tests cover remaps and
complete action coverage; Qt tests exercise rendering, scrolling and live bindings.
Backspace's reported no-op was followed by the user's confirmation that it works;
no speculative Backspace / IME behavior change was applied.

## 0.12.4 — Enter inserts on the next visible row

Model.splitNode inserts before existing expanded children as the first child, so
existing parentage and ordering do not change. Leaf nodes create a sibling; folded
branches create a visible sibling after their hidden subtree. The zoom root is
considered expanded irrespective of its saved collapsed flag. Text splitting,
selection handling, color inheritance and position-zero focus remain intact.
Model tests cover expanded/folded branches, nested leaves, zoom roots, and merging
the new item back with Backspace.

## 0.13.0 — AI scope follows the right body

The right header owns the AI link, enabled independently of focusedNode. Generation
captures activeRollId plus zoom, and snapshots the entire Roll or zoom-root subtree,
including collapsed descendants. scopeSnapshot/applyScope support multi-root Roll
previews while reusing applyBranch's single-root / identity preservation for zoom.
Roll metadata and outside subtrees stay unchanged. Apply checks current Roll, zoom
and snapshot before the existing undo transaction. The backend prompt uses the
matching root-count contract, and the dialog explicitly identifies this scope.
Tests cover full-Roll forest output, hidden descendants, zoom boundaries, stale
snapshots and the visible scope labels. Fixed connection tests remain note-free.

## 0.13.1 — workspace path chooser

FeaturePanel's Browse link uses the same forced Qt Quick FileDialog backend as
import/export. SaveFile mode supports existing and new JSON paths; confirmation
of overwrite is disabled because accepting only updates the draft TextField.
The existing location/save path remains the sole writer and preserves existing
workspaces. File URLs are encoded per path segment and decoded on acceptance to
preserve Unicode, spaces, hashes and percent signs. Cancellation leaves the draft
unchanged; closing settings also closes the chooser. The picker attaches to the
popup parent's actual window. Qt tests cover these paths and native-backend flags.

### Rich Markdown AI conversion (0.14.0)

`markdown` uses the same `scopeSnapshot` selection as other AI tasks: the entire
Roll or the zoom root and its descendants, including collapsed nodes. The backend
uses a document prompt rather than the bullet-outline replacement contract. Output
is kept as text, never passed through `importMarkdown` / `applyScope`.
`aiTask` and `aiPreviewReady` prevent applying document output as outline nodes or
saving a stale preview after failed generation. The dedicated Qt Quick SaveFile
chooser confirms overwrites and exports through the existing atomic bridge with
workspace protection. Export success has a separate signal so it cannot replace
the preview with a status message. No live AI service is used by these tests.

Tests: `tests/test_ai_backend.py`, `tests/test_bridge.py`, `tests/features.test.cjs`,
and QtTest `tests/tst_aiconnections.qml` with `-import tests/fixtures`.

### UI languages (0.15.0)

`I18n.qml` is a local QML singleton declared in `qmldir`; `Translations.js` owns
the nine supported locale codes, native language names, English wording overrides,
and eight complete translation columns. UI bindings call `I18n.t` and depend on
the singleton language property, so they refresh without rebuilding the editor.
Use numbered placeholders to preserve user values, paths, and localized word order.
Do not pass user-authored Roll names or note text through the translation catalog.
Provider diagnostics not in the catalog retain their original text. Qt-owned
file-picker chrome uses the shell's Qt translations, while our picker titles and
format labels follow the Flolinr language setting.

`language` defaults to `en`, with unsupported codes falling back to English.
AppSettings includes it in validation and atomic writes and applies it only after
a successful save. It remains separate from the outline workspace. Existing AI
profiles and paths survive save/reload. Language selection is a settings draft
until saved; canceling leaves the current language unchanged.

`tests/translations.test.cjs` checks all catalog columns, placeholders, literal UI
translation calls, shortcut descriptions and fallback behavior. Qt tests exercise
all language choices and narrow-window AI layouts. `tests/test_language_settings.py`
uses real Quickshell FileView writes in a temporary XDG directory and restarts a
fresh process for each locale. It never loads or writes the user's workspace.

### Expansion guidance (0.15.1)

Expand now opens an optional instruction editor instead of immediately sending
a request. The panel passes its draft through FeatureController as `instructions`;
the backend validates the type and a 10,000-character limit and adds it only to
expansion prompts, ahead of a separately labeled source outline. Existing scope
and bullet-output constraints are retained. Other tasks ignore the field. Closing
the panel clears it; opening expansion invalidates any previous preview. Tests
cover UI submission, empty input, cross-task isolation and backend validation.
