---
# dsh-go:managed — the dsh-go app keeps this skill up to date; delete this line to keep your own edits.
name: dsh-go-plugin
description: Write a small local plugin for the dsh-go phone app that appears in the **phone's native UI** — capsules above the composer, actions in the long-press message menu, status strips, native panels, tool-result cards — and can read aloud, stop on speech, and show captions; check it with the bundled checker and install it on the current host. Load this first when the person wants to add something to the dsh-go app that needs logic or data, e.g. "a button above the input that translates the clipboard into English", "add Save to notes to the long-press menu", "show today's usage above the input", "a panel for my to-dos", "draw this tool's result as a card", "a button that reads replies aloud". Only for the dsh-go phone native UI; for Cordis plugins, the Harness Web UI / desktop, or anything the person calls a web plugin, use the official cordis-plugin-development skill, not this skill's folders or install path. Write a small local DSH plugin that shows up natively in the dsh-go phone app; for Cordis / Harness Web UI plugins use the official skill instead.
whenToUse: The user wants to add something of their own to the dsh-go phone app (phone app / native UI) that needs logic or data. For fixed buttons, layout, theme or hiding things use the dsh-go-ui skill (ui.json) instead. For Cordis plugins or the Harness Web UI / desktop, use the official cordis-plugin-development skill — different directory and install entry.
---

# Write a local plugin for dsh-go

A plugin is an npm package folder on the host: the `dshGo` manifest in
`package.json` declares what appears in the app, and `lib/index.js`
handles taps and pushes data inside the engine. The app only draws the
declarations and JSON views; it never runs plugin code.

## Division of labour with the official skills (settle the surface first)

This skill covers only the **dsh-go phone app's native UI**. Creative
mode also loads the official `cordis-plugin-development`, which covers
**Harness Web UI / desktop** plugins — different folders, manifests and
install entries. **Settle the UI surface before choosing a skill**; never
go by load order and never mix them:

| What the person wants | Use | Folder / install |
|---|---|---|
| Capsules, menu items, status strips, native panels, tool-result cards, read-aloud / captions in the phone app | This skill | `$DSH_HOME/dsh-go/plugins/<name>/`, `dsh plugin --profile web add <folder>` |
| Change the dsh-go app's own look (top-bar buttons, theme, hidden elements) | `dsh-go-ui` (ui.json) | `$DSH_HOME/dsh-go/ui.json` |
| Cordis / Harness Web UI plugins, decorations, slots, MCP, pages | Official `cordis-plugin-development` | Build the package in the workspace + `plugin_manager` → `install_bundle` |
| Agent presets, Cordis compositions | Official composition skills | Official flow |

- When the person does not name a surface: inside this app the default
  target is the dsh-go phone native UI (`AGENTS.md` says the same); but
  if they explicitly want the web UI / desktop, follow the official
  skill.
- The official skill's "do not build packages outside the workspace, do
  not build under `$DSH_HOME`, do not hand-write a profile's
  package.json / cordis.patch.yml" is about **Cordis bundles**. A dsh-go
  native plugin is not a Cordis bundle: it is an npm package under
  `$DSH_HOME/dsh-go/plugins/`, installed with
  `dsh plugin --profile web add`. The two rules govern different things;
  they do not conflict, and their folders and install paths are not
  interchangeable.
- When both sides can do the same "add a button": build the native
  version in dsh-go first; if the person also wants the web UI, let the
  official skill make a separate one.

## Decide which one first

| What the person wants | Approach |
|---|---|
| Fixed-text buttons, top-bar buttons, hidden elements, theme | No plugin — use the dsh-go-ui skill to edit ui.json |
| A button that reads the clipboard / composer / a reply, or computes something | This skill: `composer.actions` / `message.actions` + `on(id)` |
| A number always in sight | This skill: `composer.strip` + `strip(id)` |
| A full page of information | This skill: `panels` + `panel(id)` |
| An occasional but handy tool | This skill: `composer.tools` (plus panel; needs a newer app) |
| Act on the whole chat: export, archive | This skill: `session.actions` (right sidebar Info; needs a newer app) |
| A number visible every turn | This skill: `turn.note` + `turnNote(id)` (turn footer; needs a newer app) |
| Draw a tool's result as a card | This skill: the tool's `output.presentationMeta` returns `{ "dsh-go/view": view }`; no manifest needed |
| Read replies aloud, stop on speech, follow-along captions | This skill: `capabilities` + `media` / `micro` / `overlays` (see "Sound and captions") |

Capsules, menus, strips and panels appear only on hosts with the dsh-go
bridge: the phone's on-device engine has it (`/etc/dsh-app/runtime.json`
exists); other hosts get tool cards only.

## Steps

1. **Create the folder** (under `$DSH_HOME/dsh-go/plugins/`, kept across
   engine resets; `DSH_HOME` defaults to `~/.dsh`):
   ```sh
   P="${DSH_HOME:-$HOME/.dsh}/dsh-go/plugins/local-quote"
   mkdir -p "$(dirname "$P")" && cp -r "${DSH_HOME:-$HOME/.dsh}/skills/dsh-go-plugin/template" "$P"
   ```
2. **Rename**: `name` in `package.json`, `name` in `cordis.patch.yml`
   and `name` in `lib/index.js` must agree — start with `local-`,
   lowercase letters, digits and `-`.
3. **Write the manifest** (`package.json` → `dshGo`, table below);
   declare only what is used; `wants` only what is truly read.
4. **Write the handlers** (`lib/index.js`): everything inside
   `ctx.inject(['dshGo'], (ctx) => { … })`.
5. **Self-check**, fixing until no "error" remains:
   ```sh
   node "${DSH_HOME:-$HOME/.dsh}/skills/dsh-go-plugin/kit/bin/check.mjs" "$P" --load
   ```
   `--load` loads your code in an isolated environment: whether the
   handlers exist and whether the views your view functions draw can be
   drawn by the app. `--json` is for machines; `--lang en` picks the
   language; `--budget toolCard|panel|strip` checks view budgets as a
   tool card, panel or strip; `--app <version>` judges `minApp` against
   a target app version (without it, judged as 999.0.0, so `minApp` is
   never blocked — always write it when checking a target version);
   newer fields such as panel placement are not version-checked.
6. **Install** (takes effect at once, no restart):
   ```sh
   dsh plugin --profile web add "$P"
   ```
   The phone's on-device engine uses the `web` profile. The install is a
   link to this folder: do not delete the folder.
7. **After code changes**: manifest (`package.json`) changes are re-read
   automatically; `lib/` code changes need the person to restart the
   engine on the app's Engine page.
8. **Tell the person** what changed and where to see it: capsules sit
   above the composer; menu items are in the long-press menu on
   assistant messages, grouped by plugin; strips sit above the composer;
   panels are under the Plugins tab on the chat details page or in All
   features. The first time a button reads the clipboard / composer / a
   message, the app asks the person once.

Uninstall: `dsh plugin --profile web remove local-quote`, then delete
the folder.

## Manifest (`package.json` → `dshGo`)

```json
{
  "v": 1,
  "title": { "en": "Quote" },
  "icon": "bolt",
  "wants": ["clipboard"],
  "contributes": {
    "composer.actions": [
      { "id": "summarize", "label": "Summarize", "effect": { "type": "insert", "text": "Summarize the conversation above in three points." } },
      { "id": "paste-quote", "label": { "en": "Quote clip" }, "icon": "document" }
    ],
    "message.actions": [{ "id": "save", "label": "Save to notes", "icon": "note" }],
    "composer.strip":   [{ "id": "today", "icon": "chart", "panel": "stats" }],
    "panels":           [{ "id": "stats", "title": "Stats", "icon": "chart", "placement": ["session.tab", "features"] }]
  }
}
```

| Slot | Per plugin | Text limit | Fields | Tap |
|---|---|---|---|---|
| `composer.actions` | 2 | `label` 10 chars | `id` `label` `icon?` `effect?` | With `effect`: the app runs it directly, no code; otherwise calls `on(id)` |
| `message.actions` | 2 | `label` 12 chars | Same as above | Same as above |
| `composer.strip` | 1 | `text` 24 chars | `id` `icon?` `text?` `panel?` | `panel` → opens that panel; otherwise `on(id)` |
| `panels` | 4 | `title` 16 chars | `id` `title` `icon?` `placement?` `presentation?` `view?` | Buttons / rows / options in the view → `actions` |
| `composer.tools` | 2 | `label` 8 chars | `id` `label` `icon?` `effect?` `panel?` `requires?` | `panel` / `effect` run by the app (write only one); otherwise `on(id)` |
| `session.actions` | 2 | `label` 12 chars | `id` `label` `icon?` `effect?` `requires?` | Same as capsules |
| `turn.note` | 1 | 16 chars per segment | `id` | Not tappable; in `turnNote(id, (scope, emit) => …)` call `emit({ turnIndex: { text, tone? } })` |

The app also has global caps: 8 capsules above the composer in total, 8
plus-panel tools, 2 turn notes at once, 8 note-feed entries; extras are
not shown. A panel button's pending label is at most 16 chars.

- `title`, `label`, `text` are strings or `{ "en": "…" }`; every
  language must fit the limit. Plugin `title` ≤ 24 chars.
- `id`: starts with a letter or digit; letters, digits and `_ . -`;
  ≤ 40 chars; **unique across the whole plugin** (across slots too).
- `wants`: `clipboard` and `draft` (composer text) go only to capsules
  and `composer.tools`; `message` (the long-pressed reply's text) only
  to menu items.
- `placement`: `session.tab` (chat details page; scope carries
  sessionId; the default), `features` (All features), `chat.panel` (the
  sheet the Plugins capsule above the chat composer opens; scope carries
  sessionId), `plugin` (panels in the plugin's own entry; newer app).
  A string or an array; values an older app does not know are ignored,
  and a panel placed only in `plugin` falls back to `session.tab`.
- `presentation`: `page` (pushes a full page; default) or `sheet`
  (sheet); only newer apps honour it — older apps ignore it and open a
  page.
- View functions judge what the app can draw from `caps.surfaces`
  (e.g. `hasSurface(caps, 'chat.panel')`); when they cannot tell, fall
  back to `session.tab`.
- Static `effect` may only use `insert` `command` `open` `link`
  `toast` `copy`.
- `icon`: bolt star sparkle heart flag bookmark pin bell clock alarm calendar todo note document folder search code terminal globe chart lightbulb book puzzle robot chat mail translate image camera mic link summary wrench bug travel school home play refresh archive team wallet palette coin money speaker read copy quote share edit write save paste add remove delete clear fork regenerate reply select-text qr download downloads external info warning check done success error question pending running tip list table panel sidebar menu more expand collapse file folder-open workspace storage pdf zip slides article text diff gallery audio music video video-file play-video pause stop replay generate-image generate-video diagram plugin bot agent skill model tool workflow goal plan job automation command trajectory web web-search browser history time today timezone schedule repeat reminder user account group chats mention invite announcement reaction poll notification send community forum feedback wechat qq telegram discord phone computer cloud server power restart retry theme color text-size pet featured badge favorite settings

Unknown icons draw as the default icon, without an error. Do not use
lock, key or shield style icons to imply safety or privacy: the app
does not guarantee those meanings, and they mislead.
- `minApp`: optional minimum app version (e.g. `"1.0.16"`). Below it,
  the native part is not shown and the person is told to update.
- `capabilities`: optional capability list. `files` means picking
  files/images with the system picker (see "Picking files and images");
  on older apps and bridges without negotiation, ordinary panels still
  open.

## Handlers (`ctx.dshGo`)

```js
export const name = 'local-quote'
export function apply(ctx) {
  ctx.inject(['dshGo'], (ctx) => {
    // Capsule / menu item / strip taps: (scope, event) → effect
    ctx.dshGo.on('paste-quote', (scope, event) => scope.clipboard ? { insert: `> ${scope.clipboard}` } : { toast: 'The clipboard has no text' })

    // Strip: push { text ≤ 24, icon?, tone? }; return a cancel function
    ctx.dshGo.strip('today', (scope, emit, caps) => {
      const tick = () => emit({ text: `Today ${count()}` })
      tick()
      const timer = setInterval(tick, 60_000)
      return () => clearInterval(timer)
    })

    // Panel: view (structure) + data (push whole objects; the bridge diffs) + view tap handlers
    ctx.dshGo.panel('stats', {
      view: (scope, caps) => ({ type: 'stack', children: [
        { type: 'metric', label: 'Today', value: { $: 'data.today' } },
        { type: 'actions', items: [{ label: 'Reset', action: 'reset' }] },
      ] }),
      data: (scope, emit, caps) => { emit({ today: count() }); return () => {} },
      actions: { reset: (scope, event) => ({ toast: 'Reset', patch: { today: 0 } }) },
    })
  })
}
```

| Parameter | Contents |
|---|---|
| `scope` | `{ sessionId?, turnId?, messageId?, callId? }`; on taps also the declared `clipboard` / `draft` / `message` |
| `event` | `{ surface, id, action?, value?, locale }`; panel taps: `action` is the view's action id, `value` is args (`options` → `{ value }`, `confirm` → `{ confirmed }`) |
| `caps` | View functions: `{ protocol, app, locale, surfaces, components }`; data functions: `{ protocol, locale }` |

**Returned effects** (at most 4 at once; only those returned within 3
seconds of the tap run):

| Form | Effect |
|---|---|
| `{ insert: '…' }` | Puts text into the composer (≤ 2000 chars); **never sent automatically** |
| `{ toast: '…' }` | A one-line notice (≤ 40 chars) |
| `{ copy: '…' }` | Copies (≤ 8000 chars) |
| `{ link: 'https://…' }` | Opens in the browser after the person confirms; https only |
| `{ open: 'panel:stats' }` / `{ open: 'page id' }` | Opens this plugin's panel or an app page |
| `{ command: 'compact' }` | Runs a slash command in the current chat |
| `{ refresh: true }` / `{ patch: {…} }` | Panel refetches its view / merges data |
| Several keys in one object | All run in order, e.g. `{ copy: md, toast: 'Copied' }` |

**Slow work (model calls, network) uses deferred effects**: return
`pending` first and the app shows a wait; the result arrives within 60
seconds and may only be `insert` `copy` `toast` `patch`; at most 2 per
plugin at once; `signal` fires on cancel / timeout / disconnect — stop
when it does.

```js
ctx.dshGo.on('translate', (scope) => ({
  pending: { label: 'Translating', timeoutMs: 60_000 },
  result: async (signal) => ({ insert: await translate(scope.clipboard, signal) }),
}))
```

## Views (panels, tool cards)

A JSON component tree. Any value may be a binding `{ "$": "data.a.b" }`
taken from the pushed data; a missing value shows "—". Tool cards have
no data — write values directly.

**Pick the view version first**: no `v` on the root, or `v: 1`, uses v1
components and the original styling; for the newer controls, structural
components or bounded styles, write `v: 2` on the root. The manifest's
`dshGo.v` stays `1` — separate from the view version.

The table below lists only the v1 basics. The full v2 components and
fields are in the bundled `kit/schema/view.schema.json`; the app repo's
`docs/plugins/components.md`, `styles.md` and `inputs.md` cover the new
components, styles and forms. Do not reject v2 just because a component
is not in the table. For older apps, degrade via `caps.components` /
the SDK's `adaptView`, keeping text in basic fields such as `text`.

```json
{"v":2,"type":"stack","accent":"teal","children":[
  {"type":"text","text":"Example","style":{"size":"title","weight":"bold"}},
  {"type":"emptyState","title":"Nothing here yet"}
]}
```

| Component | Fields |
|---|---|
| `stack` / `row` | `children` (row wraps on narrow screens); the root may carry `title` |
| `text` | `text`, `tone?: muted` |
| `metric` | `label` `value` `tone?: good\|warn\|bad\|info` `caption?` |
| `chart` | `kind: bar\|hbar\|line\|donut` `categories` `series: [{ name?, values }]` `unit?` `caption?` |
| `compare` | `items: [{ title, badge?, rows: [[name, value]] }]` (2–4 items) |
| `steps` | `items: [{ label, status: done\|current\|todo\|failed, detail? }]` |
| `callout` | `text` `tone?: info\|good\|warn\|bad` |
| `list` | `items: [{ title, subtitle?, trailing?, icon?, tone?, action? }]` (≤ 50) |
| `keyValue` | `items: [[name, value], …]` or `[{ label, value, tone? }]` or `{ name: value }` (≤ 24) |
| `progress` | `value` `max?` (default 100) `label?` `caption?` `tone?` |
| `table` | `columns: [text \| { label, align? }]` (≤ 8) `rows: [[…]]` (≤ 50) |
| `actions` | `items: [{ label, action, icon?, style?: primary\|plain }]` (≤ 4, at most one primary) |
| `options` | `id` `options: [{ label, value? }]` `multi?` `selected?` |
| `confirm` | `id` `confirmLabel?` `cancelLabel?` |
| `image` | `src`: a same-origin `/dsh-go/v1/…` path or a ≤ 64 KiB `data:image/…`; `alt?` `aspect?` |

`action` is an action id string, or `{ "id": "open", "args": { … } }`
(args ≤ 1 KiB). Limits: panels 32 KiB / 120 components / 8 levels; tool
cards 8 KiB / 40 components / 6 levels, not tappable in phase 0.

Tool cards:

```js
presentationMeta: (args, value) => {
  try {   // Throwing, or returning undefined / NaN, fails the whole tool call
    const text = JSON.stringify({ type: 'stack', title: `${value.city} · Today`, children: [{ type: 'metric', label: 'Temp', value: `${value.temp}°` }] })
    return text.length < 8000 ? { 'dsh-go/view': JSON.parse(text) } : {}
  } catch { return {} }
},
```

## Picking files and images (NA v1.3, optional)

After a tap, a plugin can open the system picker; the selection goes to
the current host and the plugin reads bytes through a one-time handle —
it never gets a phone file path.

- Add `"capabilities": ["files"]` to the manifest; the button that
  starts the pick gets `"requires": ["files"]`; in a panel, show the
  pick button only when `caps.features?.includes('files')`, otherwise
  show plain explanatory text.
- Effect: `effects.pickFile('selected', { maxFiles: 2 })` or
  `effects.pickImage(...)`; without the SDK, return
  `{ type: 'pickFile', action: 'selected', maxFiles: 2 }`. `maxFiles`
  defaults to 1 and accepts only 1–4.
- The callback is the same panel's `actions[action]`, or falls back to
  `ctx.dshGo.on(contribution id, handler)`; `event.value` is
  `{ status: 'selected', files: [{ handle, name, bytes, mediaType, access }] }`,
  `cancelled`, or `error`.
- Inside the callback, read bytes with
  `ctx.dshGo.readPickedFile(handle)` (an independent copy). The handle
  is valid only within that pending callback: after it ends, times out,
  unloads or disconnects, it reads nothing. Do not store handles, and
  do not build paths from `name`.
- Older apps, older bridges and DSH Remote relays do not negotiate this
  capability; panels still open. `dshGo.v` stays `1` — do not write
  `1.3`.
- The call that starts a pick must come from a user gesture
  (`userGesture`); it cannot fire by itself in the background.

## Sound and captions (v1.2, optional)

Add `"capabilities": ["audio", "voice", "micro", "overlay"]` (only the
ones used) to the manifest, and `media: [{ id }]`, `micro: [{ id }]`,
`overlays: [{ id, channel }]` to `contributes` (each ≤ 2; ids unique
across contributions); buttons that need sound get
`"requires": ["audio"]`.

```js
ctx.dshGo.on('read', (scope) => [   // One instance: the app treats it as one session
  { type: 'audio', op: 'play', instance: 'reading', src: 'media:speech', key: 'k1' },
  { type: 'voice', op: 'start', instance: 'reading' },
  { type: 'overlay', op: 'show', instance: 'reading', id: 'subtitle' },
])
ctx.dshGo.media('speech', async (scope, { key, signal }) => ({ body: wavBuffer, contentType: 'audio/wav' }))   // whole clip, ≤ 16 MiB, within 30 s
ctx.dshGo.micro('caption', { data: (scope, emit) => { emit({ text: 'Reading here', progress: 0.3 }); return () => {} } })   // only { text ≤ 240 chars, progress 0–1 }
ctx.dshGo.onCapability((scope, { event }) => {})   // audio.ended / voice.speechStart / …; return values do not run
```

Slow work (TTS) belongs in `media`, not in `on`. The app handles:
stopping playback before notifying on speech, asking the person whether
it may listen, foreground only, and stopping listening and captions
when the sound ends. Without TTS, synthesise placeholder audio the way
`examples/plugins/dsh-go-example-readaloud` does.

## Rules

- v1 keeps the original styling; v2 may use the documented colours,
  semantic sizes, weights, spans and container styles. No arbitrary
  CSS, font files, sizes, opacity, gradients or animation parameters;
  actual geometry, readable colours and content bounds stay the app's
  decision.
- Copy is short; errors read like plain English ("The clipboard has no
  text"), never raw exception text.
- No secrets or tokens in views, manifests or code; clipboard / message
  content read is used for that one tap only.
- Nothing with side effects without a tap; `insert` never sends.
- Write fields per the chosen view version's schema and component
  catalogue, and validate with the bundled checker; do not invent
  unsupported fields. Full documentation is in the app repo's
  `docs/plugins/`.
