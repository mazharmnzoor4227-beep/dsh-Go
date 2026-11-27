# dsh-go:managed — the dsh-go app keeps this skill up to date; delete this line to keep your own edits.
name: antigravity-cli
description: Google Antigravity CLI (agy) inside this app's Linux (PRoot Ubuntu) environment — install it, sign in with a Google account, and run it as a coding agent from the terminal. Use when the user asks for Antigravity, agy, or Google's coding agent on the phone.
whenToUse: The user asks to install, set up, sign in to, or run Google Antigravity CLI (agy) in this app.
---

# Antigravity CLI (agy) in dsh-go

The app's Linux environment is PRoot Ubuntu 24.04 (glibc, arm64), which runs
Google's official Antigravity CLI binary. Install and use it from the bash
tool; do not try to run the desktop Antigravity app or IDE here.

## Install (once)

Run the whole install as ONE bash call using this script. It is safe to
re-run: every step checks what is already done, so if a call is
interrupted (engine restart, timeout), run the same script again and it
continues where it left off instead of starting over.

```bash
export PATH="$HOME/.local/bin:$PATH"
if command -v agy >/dev/null 2>&1; then
  agy --version
  exit 0
fi
# curl ships with the current runtime; older runtimes may lack it.
if ! command -v curl >/dev/null 2>&1; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y -qq --no-install-recommends curl ca-certificates
fi
# Download with retries; -C - resumes a partial file after an interruption.
curl -fsSL --retry 5 --retry-delay 3 -C - https://antigravity.google/cli/install.sh -o /tmp/agy-install.sh
bash /tmp/agy-install.sh
agy --version
```

Notes:

- The installer detects arm64 and puts the binary in `~/.local/bin/agy`.
- Download the script first and run it as a file; piping straight to
  bash can time out.
- Never split the install across several short calls (a separate
  `which curl`, then a separate `apt-get`): one call runs to completion,
  and re-running it after an interruption is the recovery path.
- If `apt-get` reports a lock or a half-configured package after an
  interruption, run `dpkg --configure -a` once, then re-run the script.

## Sign in

Run `agy` once and follow its Google sign-in prompt. Sign-in opens a browser
flow; if the browser does not open automatically, show the user the sign-in
URL from the terminal output and let them complete it in their browser, then
paste back any code the CLI asks for. Never ask for or store the user's
Google password.

## Use

- Interactive: `agy` in a project folder.
- One-shot task: `agy -p "<task>"` and report the result.
- Keep `~/.local/bin` on PATH in every shell call that uses `agy`.

## Alternative: Antigravity models via a server

If the user has Antigravity accounts on their own server (for example an
OmniRoute gateway), they can instead add it in Settings → Providers with the
"Custom server" preset: base URL = the server's OpenAI-compatible endpoint,
key = the gateway key. That route uses Antigravity models as the chat model;
the CLI above is a separate coding agent in the terminal.
