---
# dsh-go:managed — the dsh-go app keeps this skill up to date; delete this line to keep your own edits.
name: dsh-go-support
description: Troubleshooting and feedback for the dsh-go phone app — read the on-device diagnostics the app writes (see the "On-device diagnostics" section of AGENTS.md, usually `$DSH_HOME/dsh-app/diagnostics.md`), work through the symptom checklist, and produce a redacted environment summary and issue draft. Load this first when the person reports lag, heat, battery drain, connection trouble, crashes, failed updates, plugins not working, or phone-control failures, or asks to report a bug. Diagnose and report dsh-go problems from the on-device diagnostics snapshot.
whenToUse: The person reports a problem with DSH Go (lag, heat, battery, connection, crash, update, plugin, phone control) or asks to file an issue. Not for changing the app's UI (dsh-go-ui) or writing a plugin (dsh-go-plugin).
---

# dsh-go troubleshooting and feedback

This skill does one thing: **get the facts first, then conclude**. The app
writes its own on-device diagnostics; the path and the rules are in the
"On-device diagnostics" section of the global instructions — read that
first, then follow the checklist below. Do not prescribe from "it might
be…".

## 1. Read the diagnostics first

```sh
# Read these paths with an available file tool (never send the whole
# diagnostics anywhere):
# $DSH_HOME/dsh-app/diagnostics.md        the automatic environment snapshot
# $DSH_HOME/dsh-app/diagnostics-manual.md the report the person published (check first when present)
# Under direct launch the path carries a rootfs prefix; AGENTS.md wins.
```

This is a bounded snapshot the app collects from its own state, what
Android exposes, and runtime logs: version, device, runtime, connection,
performance, recent errors the app caught, and the tails of engine/failure
logs. Parts may be missing when a source is unavailable or stale. The
Markdown has a size budget and logs keep only a limited tail — it is not
the full history.

Full error messages the app caught live in bounded in-process memory;
newer versions also persist error categories, a few of the app's own
source locations, and content-free voice stages. On Android 11+ the
system may report this app's historical process-exit reasons; exit
descriptions and raw traces are not read. These records are not a full
crash stack; missing, unavailable or empty results are not evidence of
health. The diagnostics bundle is not system logcat either: a normal app
cannot read other apps' or system logs beyond Android's permission and
version limits — do not assume full system logs or bypass permissions.
When logcat is truly needed, explain the scope and privacy risk first
and let the person choose a lawful way to collect it; contents vary by
Android version, device and permissions.

- First check that an available report's generation time, app version and
  device match this report; another device's or an old report is not this
  incident. Read this incident's manual report first, then fill in the
  environment from the automatic snapshot. Only when every available
  report is missing or stale, ask the person to publish one via
  **Settings → Diagnostics → Let AI see diagnostics**, then read it; do
  not keep asking for a refresh because another file is missing. Older
  versions having only the main snapshot is normal.
- When a newer version offers `mcp__phone__diagnostics`, a
  troubleshooting request is enough to call it yourself: `refresh:true`
  by default, take `summary`, `evidence`, `appErrors`, `voice`, `engine`
  or `failure` by `section` — no screen reading or phone control needed
  first. Check `collectedAt`, `refreshed` and `code`; a failed refresh
  must not present an old snapshot as this incident; `refresh:false`
  reads the cache only. Each section is bounded and may be marked
  `truncated`. The tool collects no system input-method evidence,
  exports no arbitrary paths, and sends nothing on the person's behalf.
  When the tool is missing or unavailable, read the existing snapshot;
  do not call repeatedly to pressure the person into permissions.
- When information is short, the person can export a ZIP from the
  diagnostics feature: built from the same collection — summary,
  settings, and where available crash categories, engine/failure log
  tails and app errors. Logs are still capped, not complete, and crash
  detail is not full. The person checks it and keeps or uploads it
  themselves; never send it for them.

After the person taps **Let AI see diagnostics**, only the fixed
`diagnostics-manual.md` in the same folder is written atomically, for the
AI to read this collection's system input-method evidence; automatic
refresh writes only `diagnostics.md`; the two never overwrite each
other. Check generation time, device and version separately; an old
manual report is not a new incident. With only the main snapshot on an
older version, read what exists and do not infer the fault is absent.
The path is the main snapshot's folder; direct/safe modes locate it the
same way per AGENTS.

**Look yourself before asking the person a pile of questions**; ask only
for what the diagnostics do not contain.

## 2. Check by symptom

### Crashes / exits during voice replies
- Read `evidence` and `voice` first: line up the error location, voice
  stage and process-exit time to tell a native crash from an abnormal
  exit or memory reclaim. Requesting playback is not playback; with no
  system stack, say it is unknown — do not equate a model reply error
  with an app crash.
- **Automatic fault analysis** is off by default. Only with the person's
  explicit consent does it send allow-listed structured facts to the
  on-device engine's model (possibly billed) — never raw logs,
  recordings, message text, credentials or system input-method
  evidence. The analysis session has no tools, fixes nothing
  automatically and files no public issue; failures or unclear results
  are not retried automatically; closing it or switching hosts stops new
  requests; what was sent cannot be recalled.
- When analysis records fail to read or write, automatic analysis
  pauses; the local recovery entry on the diagnostics page only restores
  records and skips stored faults — it does not resend old requests to
  the model. Do not work around this by deleting settings, replaying
  prompts or clearing data on your own.

### Lag / dropped frames / unresponsive touch
First separate "app UI" slowness from "engine/model" slowness:
- In diagnostics check `Performance` (tier, temperature), `Environment`
  (runtime state is one line; on-device vs remote), `Recent errors`.
- On-device engine + heavy work (npm install, many files) competes with
  the UI for CPU; a laggy UI then is normal — suggest a remote host or
  waiting for the task to finish.
- Lag while a long reply streams: check reply length and code-block
  count; that is rendering cost, not network.
- Have the person try **Settings → Performance → Light** once (blur,
  motion and pets off). If it improves at once, it is effects cost, not
  the engine.
- On high-refresh devices, compare **Settings → Performance → Refresh
  rate** on "System" or "Auto"; "Highest" drops frames more easily on
  low-end phones.
- Still laggy: have the person note "which page, what action, how long",
  and export the diagnostics bundle.

### Heat / battery drain
- Main sources: the resident on-device engine, phone control
  (accessibility / floating bar), pets, high refresh rate. In
  diagnostics check whether `Environment` is running and, in `Settings`,
  auto-start on-device engine / visual replies / phone storage.
- When not in use, have the person **stop the on-device engine**
  (Settings → On-device engine → Stop) or use a remote host; turn phone
  control off when unused.
- Check the temperature tier in diagnostics `Performance`; long
  streaming output heats the phone by itself — that is normal.
- Do not tell the person to change system battery optimization or
  accessibility permissions to "speed things up" — explain such changes
  first and let them tap themselves.

### Cannot connect remotely / stuck "Reconnecting"
- Confirm first: host and phone are signed in to the same account; the
  host-side plugin is running (`/remote status` on the host).
- **Two TUIs / two dsh instances on the host sharing one `DSH_HOME`**
  kick each other's connection (the plugin pauses auto-reconnect) — the
  most common "phone online but cannot connect". Have the person keep
  one instance, or give the second its own `DSH_HOME`.
- When LAN/P2P fails it falls back to TURN/Relay — high latency but
  connected; check `Connection` in diagnostics.
- For host logs, have the person export or paste the relevant lines on
  the host; do not guess from the phone.

### Engine will not start / safe mode
- In diagnostics check `Environment` phase, error, safeReason, strikes,
  and whether `Bundled runtime / Installed` agree.
- Common causes: runtime not installed properly, low storage, a plugin
  crashing startup (safe mode exists for this), direct launch failing
  back to proot.
- First have the person tap **Retry** or **Start in safe mode** on
  **Settings → On-device engine** and read the failure reason in the
  **logs** (tap **Install runtime** only when the runtime is not
  installed; do not confuse it with Reset — Reset deletes chats,
  workspaces, plugins and settings; see
  `docs/guide/en/03-engine-hosts.md`). For plugin trouble, point them to
  **Settings → Plugins** to disable the recently installed one.
- For more clues, have the person export the diagnostics bundle; it
  still holds only limited logs — absence does not mean nothing
  happened.

### Update will not install
- First check whether the app can update directly: since 1.0.16 updates
  can install via Shizuku or self-connected ADB, and the downloaded
  package can be exported for manual install; the entry points are the
  update prompt and **Settings → General → Check for updates**.
- The system install confirmation never appears / counts as cancelled:
  common on some ROMs (HyperOS, ColorOS, …). Have the person download
  `dsh-go-<version>-arm64.apk` manually from GitHub Releases, or allow
  this app to install unknown sources in system settings.
- Package parse failure: usually an incomplete download — download
  again and compare against `SHA256SUMS`.

### Engine killed by the system, auto-restarted / last turn interrupted
- Since 1.0.16 an abnormal engine exit tries an automatic restart; a
  "restarted" style notice means it recovered once, not a new fault.
- If the process was killed mid-reply, the reply may stop halfway; have
  the person resend or retry — do not conclude the model or network is
  broken.
- Repeated restarts: export the diagnostics bundle and check
  `Recent errors` and `Environment` phase/strikes; if it still will not
  start, follow "Engine will not start" above.
- Check the launch path: diagnostics › Developer options shows
  direct/proot/tawcroot and similar launch routes; tawcroot is an
  accelerated launch that falls back on failure — do not treat it as the
  fault itself.

### Plugin not working / blank settings page
- Have the person confirm the plugin is installed on the **current
  host**, in the current profile, and enabled in the plugin market.
- A remote host's plugins live on the host, not the phone; the app only
  has the entry point.
- A plugin crashing the engine lands in safe mode; disable the plugin
  and start again.

### Input method / keyboard problems
- Read the existing snapshot and what the person already gave first; ask
  only for missing reproduction steps, times, or the input method. Do
  not re-ask for an environment already given, and never ask for real
  chat content. Check the snapshot time against the event.
- Keep apart what the person observed: losing focus, the keyboard
  hiding, and the input connection closing — retain the observations,
  do not merge them into one claim. A normal snapshot has no complete
  focus/keyboard event log; this collection's system evidence records
  known show/hide requests or connection closes — it does not directly
  prove the keyboard was visible, nor that the Flutter input was
  rebuilt.
- When basic information is short and the current version supports it,
  a higher-privilege read-only diagnostic may be offered: explain the
  purpose, collection scope and privacy risk first, ask whether the
  person agrees, and let them approve this collection themselves on the
  native confirmation screen. It reuses only an already configured,
  running high-privilege channel, reads recent system input-method
  requests emitted by this app's process, and returns bounded
  structured events (show/hide requests or input-connection closes,
  time, source, identifiable reason) — never raw system log lines. An
  existing channel grant is not consent for this diagnostic. Do not
  trigger system permission requests yourself; when the channel is
  unavailable or the person declines, cancels or collection fails, say
  so plainly — it is not fault evidence, and do not bypass consent.
- After one collection, the person taps **Let AI see diagnostics** and
  you read the system input-method evidence in the snapshot; for more
  bounded events, export the ZIP. Collection results live only in app
  memory and are gone after clearing or restart; exported files are not
  recalled. Do not collect in a loop, run stress tests, or install test
  APKs on your own.
- Events carry no input text; raw logs are read transiently during
  collection and discarded. Other logs, screenshots and bundles may
  still contain private material. Android 12 or some ROMs may produce
  no matching logs; `noEvents`, an unknown reason, or a missing
  `fromUser` is not evidence of health, and unknown is not `false`.
  When evidence is insufficient, say so; do not blame the input method,
  the app or the system on these events alone.

### Phone control failures
- Check the phone-control and accessibility state in diagnostics; not
  ready or not collected does not mean off. Ask the person only when
  information is short; some ROMs switch accessibility services off by
  themselves.
- Sensitive pages (passwords/payments) being unreadable is system
  policy, not a bug; have the person hand off.
- Floating bar misbehaving: have the person turn phone control off and
  on again.
- Several tasks at once: background tasks have a cap; beyond it, later
  submissions queue or are refused — have the person wait for the
  previous one or reduce parallelism.
- To confirm the chain works: **Settings → Phone control** has a
  self-check; handle the item it names, and do not conclude from other
  items in its place.
- Live background preview looks frozen or black: confirm do-not-disturb
  mode and the background cap first, then check the diagnostics
  `Phone control (on-device)` section — do not declare accessibility
  broken outright.

## 3. Produce feedback (issue draft)

When the person wants to report, give a **paste-ready** draft; do not
send it for them:

```md
## Environment
- App: <version> (<build>)
- Device: <vendor model> · Android <version> (SDK <n>)
- Runtime: <bundled version> / <DSH version> / Node <version>, launch <proot|direct>
- Connection: <on-device | remote | not connected>

## What happens
<one or two sentences>

## Steps to reproduce
1. …
2. …

## Expected / actual
…

## Diagnostics
<the relevant sections of the diagnostics file: recent errors, performance, connection; full bundle attached>
```

- Copy the environment section straight from diagnostics; never invent
  it.
- The full diagnostics bundle (zip) is attached by the person
  themselves to a GitHub issue or sent to a maintainer; it contains
  engine logs — **never forward it through you**.
- Remind the person: scan before pasting for their own paths, account
  names or device names they do not want public.

## 4. Privacy lines

- Diagnostics tries to redact but cannot guarantee completeness;
  **paths, device models, account nicknames, chat screenshots and
  logs** can still expose personal information. Before sharing, the
  person checks by hand and decides what to keep or cover.
- Never repeat, echo or write into a file any token, API key,
  verification code or chat text verbatim.
- Never, without asking the person first: change system settings,
  install or uninstall apps, clear data, or restart the engine.

## 5. When to say "enough"

- Diagnostics plus three sentences from the person reproduce it → give
  the draft; ask for no more logs.
- Diagnostics missing, logs not matching, or it only happens on a
  specific network/device → only then ask for the full bundle.
- When unsure, say "the current data cannot locate it yet", then list
  **one** next thing needed — never five at once.
