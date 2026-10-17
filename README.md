# Flolinr for Omarchy

A quiet outliner for Omarchy — for ideas, daily notes, and whatever comes next.

<img width="1070" height="481" alt="screenshot-2026-10-17_13-46-12" src="https://github.com/user-attachments/assets/d8121b28-71ae-4061-9b93-6e3855bb8d03" />

A keyboard-first outliner for Omarchy. Organize ideas into nested items, zoom into a branch, keep a dated daily memo, and search across your workspace.

<img width="2160" height="1310" alt="screenshot-2026-10-17_13-42-10" src="https://github.com/user-attachments/assets/0e824bad-4bf8-4528-afcc-18fc803af6fa" />

## Install

```sh
omarchy plugin add https://github.com/yozniax/flolinr-omarchy.git --enable
```

## Open Flolinr

Click the Flolinr icon in the Omarchy bar, or open the main window from a terminal:

```sh
omarchy-shell shell summon yozniax.flolinr '{}'
```

Flolinr opens with five starter Rolls that introduce its main workflows. Create your own Roll with **Ctrl+Shift+N**. Rename it with **Ctrl+Shift+R**. Drag Rolls in the sidebar to reorder them.

## Work with an outline

- Type to edit an item. **Enter** inserts an item below; **Shift+Enter** adds a line within the item.
- **Tab** and **Shift+Tab** indent or outdent an item with its descendants. **Alt+Up** and **Alt+Down** move a branch among its siblings.
- Click an item's bullet to zoom into that branch. Use **Alt+Left** to go to its parent or **Ctrl+Home** to return to the Roll root. Click the triangle to collapse or expand children.
- Press **Ctrl+F** to search every Roll and daily memo, including archived Rolls. Select a result and press **Enter** to open it.
- Changes save automatically. Press **Ctrl+S** to save now, **Ctrl+Z** to undo, or **Ctrl+Shift+Z** to redo.
- Type `/` in an item to open the command menu. Use **Up/Down** and **Enter** to choose a command.

Available commands:

| Command | Use |
| --- | --- |
| `/insert` | Embed an image, file, Markdown, plain text, or code in the outline. |
| `/date` | Insert a date. |
| `/link` | Link to a Roll or an item in the workspace. |
| `/template` | Insert a saved outline template. |

Embedded files keep their place in the outline and can be expanded, collapsed, or deleted. AI editing preserves embedded content.

## Today's Memo and Quick Capture

**Today's Memo** is a separate note for the current local date. Open it from the sidebar or press **Ctrl+Shift+T**. Use **Ctrl+Shift+D** for the calendar; **Ctrl+Shift+L** opens the calendar directly. Each date has its own memo, available from the calendar and workspace search.

Quick Capture opens a small window without opening the main editor. It has three modes:

- **Quick note** saves one line when you press **Enter**.
- **Outline** saves multiple lines as nested items.
- **Checklist** saves the same outline with checklist items.

Each submission creates an `HH:MM` parent item in today's memo and saves the captured content beneath it. In Outline and Checklist, use **Tab** to indent and **Shift+Tab** to outdent; **Ctrl+Enter** saves. **Esc** closes Quick Capture. A failed save leaves the draft available for retry.

The suggested global shortcut is **Super+Ctrl+M**. Global shortcuts belong to Hyprland, so add or change the binding in `~/.config/hypr/bindings.lua`. The command to open Quick Capture is:

```sh
omarchy-shell shell summon yozniax.flolinr '{"mode":"capture"}'
```

For Omarchy's Lua bindings, the shortcut can be added like this:

```lua
o.bind("SUPER + CTRL + M", "Flolinr quick capture", [[omarchy-shell shell summon yozniax.flolinr '{"mode":"capture"}']])
```

## Search, files, and AI

Search spans all Rolls and dated memos, including archived and folded content. Choosing a result opens its location in context.

Import and Export support **OPML, Markdown, and plain text**. Import creates a new Roll; Export writes the current Roll. Use the Import link in the sidebar and Export in the open Roll's toolbar.

From the **AI** action, summarize, expand, or reorder the current Roll or zoomed branch. **Convert to Markdown** creates a rich Markdown document that you can save as a `.md` file. Review the target scope before running an action. AI is optional: configure a local CLI or an API connection in Settings. No AI service is contacted until you run an AI action or connection test.

## Keyboard shortcuts

These are the default application shortcuts. Open the shortcut guide with **Ctrl+/**; it shows any customized bindings too.

| Shortcut | Action |
| --- | --- |
| **Ctrl+F** | Search the workspace |
| **Ctrl+Shift+N** | Create a Roll |
| **Ctrl+Shift+T** | Open Today's Memo |
| **Ctrl+Shift+D** | Open the activity calendar |
| **Ctrl+Shift+L** | Open the calendar |
| **Ctrl+PgUp / Ctrl+PgDown** | Switch Rolls |
| **Ctrl+Up / Ctrl+Down** | Focus the previous / next item |
| **Alt+Right / Alt+Left** | Zoom in / go to the parent |
| **Ctrl+Home** | Return to the Roll root |
| **Ctrl+Shift+Space** | Collapse / expand the focused item |
| **Alt+Up / Alt+Down** | Move the item branch |
| **Ctrl+Z / Ctrl+Shift+Z** | Undo / redo |
| **Ctrl+S** | Save now |
| **Ctrl+W** | Save and close Flolinr |
| **Ctrl+/** | Open the shortcut guide |

To customize shortcuts, create `~/.config/flolinr/keybindings.json` and include only the actions you want to change. For example:

```json
{
  "newRoll": "Ctrl+N",
  "today": "Alt+T",
  "color": ""
}
```

An empty value disables that shortcut. See [`keybindings.example.json`](keybindings.example.json) for all configurable actions.

## Settings and data

Settings lets you choose the interface language, workspace file, templates, and optional AI connections. Flolinr supports English, Chinese (Simplified and Traditional), Danish, French, German, Italian, Japanese, Korean, Polish, Portuguese, Russian, and Spanish.

By default, your workspace is stored in `~/.local/share/flolinr/outline.json`. Settings and shortcut overrides are stored in `~/.config/flolinr/`. You can choose another workspace file in Settings, including a file in a synced folder. Notes and settings are kept outside the plugin directory and remain when you remove Flolinr. Sync services and conflict-free multi-device editing are not built in.

## Feedback

Found a bug or have an idea? [Open a GitHub issue](https://github.com/yozniax/flolinr-omarchy/issues/new). Include what you expected, what happened, steps to reproduce, and your Omarchy and Flolinr versions. Please do not post private notes, API keys, or other secrets.

## Update or remove

```sh
omarchy plugin update yozniax.flolinr
omarchy plugin remove yozniax.flolinr
```

Removing the plugin leaves your workspace and settings files in place.

## License

MIT
