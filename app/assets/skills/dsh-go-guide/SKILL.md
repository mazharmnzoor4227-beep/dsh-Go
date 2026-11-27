---
# dsh-go:managed — the dsh-go app keeps this skill up to date; delete this line to keep your own edits.
name: dsh-go-guide
description: The dsh-go app's own user guide — where each feature is, what each setting does, what an action deletes. Covers chat, models, engine and remote hosts, phone control, web mode, pets, companion, workshop, sharing, plugins, tavern, subagents and agent teams, terminal, workspaces, automations and settings. Load it first when the user asks how to use the dsh-go app itself.
whenToUse: The user asks how to use the dsh-go app itself. Not for changing the app's layout (dsh-go-ui) or writing a plugin (dsh-go-plugin).
---

# dsh-go user guide

The guide pages live in this skill directory: `README.md` and `en/`. Read only what the question needs.

1. Read `README.md` first for the version and the page list. Then read only the one or two pages the question is about (`en/`). Reply in the user's language (English, Hindi, or Urdu); never reply in Chinese.
2. Answer only from the guide. Write entry paths and button names exactly as the page writes them. If the guide does not cover it, say so plainly; do not guess or borrow steps from the web version or other apps.
3. Conclusion first, then the entry point and steps, as short as possible.
4. When an entry line carries a `dshgo://open/...` link, include it unchanged, for example `[Open phone control](dshgo://open/phone)`. Use only links that appear in the guide.
5. For delete, reset, uninstall, permission, or loosened-confirmation actions, state the consequences first: what is deleted, what stays, and whether it can be undone.
6. Read-only: do not change settings, run commands, operate the phone, or install or uninstall anything for the user. If they ask you to change something directly, tell them where to change it.
7. If the user's app version (Settings, About) differs from the README version, or the description does not match their screen, say the interface may have changed and the app itself wins.

Platform check: determine Android versus iOS before giving setup advice. On iOS read 04-phone-control and 03-engine-hosts: CoreDevice capability checks, optional XCTest, Remote Pairing and actual PiP state govern behavior. Android accessibility/background:true/ADB/Shizuku instructions do not apply. A successful connection is not proof of input support; never replay an uncertain action through another backend.
