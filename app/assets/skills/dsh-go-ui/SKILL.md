---
# dsh-go:managed — the dsh-go app keeps this skill up to date; delete this line to keep your own edits.
name: dsh-go-ui
description: Configure the dsh-go phone app's native UI ($DSH_HOME/dsh-go/ui.json) — top-bar buttons, quick capsules above the composer, new-chat suggestion cards, drawer grouping and sorting, density, hidden elements, theme and accent colour, tablet shortcuts, plugin seats. This changes only the **dsh-go phone app's native UI**; for the Harness Web UI / desktop, Cordis plugins or web plugins, use the official skills, not this one. Load this first when the person wants the app itself to look or behave differently, e.g. "swap the top-bar XX for YY", "add a summarize button above the input", "put a few common questions on the new-chat page", "sort the drawer by creation time", "hide the turn footer", "switch to dark / teal", "add ctrl+k to open search". Change how the dsh-go phone app's native screens look and behave by editing ui.json; the Harness Web UI / Cordis plugins are the official skills' business.
whenToUse: The user asks to change the dsh-go app (phone app / native UI) itself. Not for the Harness Web UI, Cordis plugins or DSH settings; anything that needs logic or data is a plugin (dsh-go-plugin).
---

# dsh-go UI configuration (ui.json)

The dsh-go app reads `$DSH_HOME/dsh-go/ui.json` (`DSH_HOME` defaults to
`~/.dsh`) and changes its own native UI from the declarations inside.
After saving, wired keys take effect within a second or two — no restart.

**Only some keys are wired today; see the "What takes effect" table
below.** Unwired keys are still parsed and validated by the app, but the
UI does not change — never promise the person that writing a key makes
it take effect.

The file only declares; it cannot execute: no scripts, no network
requests, nothing installed. Buttons can do only the four actions below,
and only when the person taps them.

## Division of labour with the official skills

- **This skill**: changes the dsh-go phone app's native UI (ui.json).
- **dsh-go-plugin**: adds capsules, menus, status strips, native panels
  and tool cards to the phone app; use it when logic or data is needed,
  not ui.json.
- **Official skills such as `cordis-plugin-development`**: Harness Web
  UI / desktop plugins, decorations, slots, pages and MCP; they live in
  the workspace and install via `plugin_manager → install_bundle`.
- When the person does not name a UI surface, the phone default is the
  dsh-go native UI; settle the surface before choosing a skill — do not
  go by load order. Never mix the two configuration kinds (ui.json /
  Cordis bundle), and do not apply web-plugin methods to the app.

## How to change it

1. Read the existing file first: `cat "$DSH_HOME/dsh-go/ui.json"` (create
   it if missing; `mkdir -p` if the folder does not exist).
2. Change only what the person asked for; keep every other key as-is.
   Never delete their earlier configuration.
3. Write it back: strict JSON, UTF-8, no comments, no trailing commas,
   at most 64 KiB. Write a temp file first, then `mv` it over.
4. Self-check: `node "$DSH_HOME/skills/dsh-go-ui/scripts/check.mjs"`. The
   output is the app parser's judgement, **not a count of UI effects**;
   only wired keys in the table below change the UI:
   - `error /composer/quickActions/2/action/url: only https links are supported`: that item has no effect; the rest work as usual;
   - `ignored`: parts the app does not know or that exceed a limit;
   - `note`: auto-corrected (e.g. over-long text truncated) and still effective;
   - `ui.json not applied: …`: the whole file was not read (syntax error, wrong version); the app keeps the last valid configuration.
   Fix until no `error` remains. Add `--json` for machine-readable
   output. The checker's "applied N items" is only the count of
   declarations the parser accepted — never relay it as "took effect".
5. On-device (the phone's engine) there is also
   `$DSH_HOME/dsh-go/ui.status.json`: what the app actually read; compare
   against it.
6. Tell the person what changed. To undo an item, delete its key; wired
   items (`theme.mode`, `plugins.seats`) can also be reset in the app's
   settings via "From ui.json" → "Restore default", which only makes the
   app ignore that item and does not change the file.

Full field definitions are in `schema.json` in the same folder; examples
in `examples/`.

## What takes effect

| Key | State |
|---|---|
| `theme.mode` | Wired: light/dark switching works |
| `composer.quickActions` | Wired: capsules above the composer work |
| `hide.pluginCapsule` | Wired: hides the app's plugin entry |
| `plugins.seats` | Wired: plugin seats work |
| `header.actions` | Validated only, not wired yet |
| `emptyState.suggestions` | Validated only, not wired yet |
| `drawer.groups` / `drawer.sort` / `drawer.filter` | Validated only, not wired yet |
| `density` | Validated only, not wired yet |
| `theme.accent` / `theme.accentPreset` | Validated only, not wired yet |
| `pet` | Validated only, not wired yet |
| `shortcuts` | Validated only, not wired yet |
| Other `hide` items | Validated only, not wired yet |

For unwired keys, tell the person plainly "this item is not applied to
the UI yet" — never invent an effect.

## Fields

```json
{
  "version": 1,
  "header": { "actions": ["schedule", "detail", "newChat",
    { "id": "daily", "icon": "bolt", "label": "Daily", "action": { "type": "send", "text": "Write today's daily report from the template" } }] },
  "composer": { "quickActions": [
    { "label": "Summarize", "action": { "type": "send", "text": "Summarize the conversation above in three points" } },
    { "label": "Compact", "action": { "type": "command", "name": "compact" } } ] },
  "emptyState": { "suggestions": [
    { "title": "See today's to-dos", "subtitle": "Read TODO.md in the workspace", "action": { "type": "send", "text": "Read TODO.md and tell me what to do first today" } } ] },
  "drawer": { "groups": ["pinned", "folders", "today", "yesterday", "thisWeek", "earlier"], "sort": "activity", "filter": "all" },
  "density": "compact",
  "hide": ["turnFooter", "tokenCount"],
  "theme": { "mode": "system", "accentPreset": "daiqing" },
  "shortcuts": [ { "keys": "ctrl+k", "action": { "type": "open", "page": "search" } } ],
  "plugins": { "seats": { "conversation.input.dock": { "dsh-cost-meter": "hidden" } } }
}
```

| Key | Form |
|---|---|
| `version` | Required, `1` |
| `header.actions` | Buttons on the right of the chat top bar, in order. Built-ins: `newChat` (new chat), `detail` (chat details), `schedule` (scheduled-task clock), `agents` (subagent capsule), `model` (model capsule). Built-ins not listed are hidden; `[]` hides all. At most 3 custom buttons: `id` (starts with a lowercase letter; letters, digits and -), `icon` (below), `label` (≤ 8 chars), `action` |
| `composer.quickActions` | Capsules above the composer, ≤ 8; `label` ≤ 10 chars + `action`. They fold away while a reply generates |
| `emptyState.suggestions` | Suggestion cards on the new-chat page, ≤ 6; `title` ≤ 20 chars, `subtitle` (optional) ≤ 40 chars, `action` |
| `drawer.groups` | Order and visibility of chat-list groups: `pinned`, `folders`, `today`, `yesterday`, `thisWeek`, `earlier`; groups not listed are hidden |
| `drawer.sort` | `activity` (recent activity) or `created` (creation time) |
| `drawer.filter` | Filter when the drawer opens: `all`, `running`, `pending`, `unread` |
| `density` | `compact` or `comfortable` |
| `hide` | Elements to hide: `turnFooter` (turn footer), `tokenCount`, `reasoningDetails` (reasoning), `activityStrip` (activity strip while generating), `whaleTail` (whale-tail animation), `todoPill` (to-do bar), `goalBar` (goal bar), `pluginCapsule` (the app-drawn Plugins entry above the chat composer) |
| `theme.mode` | `system`, `light`, `dark` |
| `theme.accentPreset` | `mist` (mist blue), `daiqing` (teal), `dusk` (dusk violet), `turquoise`, `amber`, `graphite` |
| `theme.accent` | Custom accent `#RRGGBB` (the app adjusts it to pass contrast); mutually exclusive with `accentPreset` |
| `pet` | `id`, `position` (`top-left` / `top-right` / `bottom-left` / `bottom-right`), `quiet` (boolean). Validated only today; does not change the UI |
| `shortcuts` | Tablet external-keyboard shortcuts, ≤ 20: `keys` such as `ctrl+k`, `ctrl+shift+n`, `alt+1`, `f5` (must include ctrl or alt, F keys excepted; no meta/cmd/win; `ctrl+a/c/v/x/y/z`, `ctrl+shift+v/z`, `alt+f4` are taken) + `action` |
| `plugins.seats` | How plugins appear in the native UI: `{ "<slot>": { "<npm package>": "native" \| "island" \| "web" \| "hidden" } }` (drawn natively / embedded web / opened in the web UI / hidden). Slot names are in `schema.json` under `x-dsh-go.slots.known`; `unseatable` lists the app's own UI, which takes no plugins |

Icons (`icon`): bolt star sparkle heart flag bookmark pin bell clock alarm calendar todo note document folder search code terminal globe chart lightbulb book puzzle robot chat mail translate image camera mic link summary wrench bug travel school home play refresh archive team wallet palette

To hide the Plugins entry on the chat page, add `pluginCapsule` to the
existing `hide` array, e.g. `{"version":1,"hide":["pluginCapsule"]}`. It
hides only the app's aggregate entry — it does not disable plugins, hide
plugins' own quick capsules, or change the All features / Chat details
entries. Removing the item, or restoring defaults on the UI configuration
page, shows it again. `plugins.seats` configures plugin slots, not this
app entry; do not substitute `chat.panel` / `dsh-go.panel` seat settings.

## Actions (action)

| `type` | Fields | When the person taps |
|---|---|---|
| `send` | `text` (≤ 2000 chars) | Puts the text into the composer; the person sends it themselves — never sent automatically |
| `open` | `page` | Opens an app page: `new-chat`, `settings`, `search`, `files`, `terminal`, `jobs`, `skills`, `schedules`, `models`, `plugins`, `cordis`, `engine`, `web`, `session-detail`, `workspaces`, `account`, `remote`, `phone`, `notifications`, `diagnostics`, … — the full list is `$defs.page` in `schema.json` |
| `command` | `name` (no `/`), `args` (optional, one line) | Runs `/name args` in the current chat |
| `link` | `url` (only `https://`) | Asks for confirmation, then opens in the browser |

## Notes

- Each host has its own ui.json; the app uses the connected host's.
- One wrong item affects only that item; on a whole-file syntax error
  the app keeps the last valid configuration.
- Never put secrets or tokens in the file.
- Do not invent fields or values; anything not in the table above is
  unknown to the app.
