---
# dsh-go:managed — delete this line to keep your own edits.
name: pet-theme
description: Turn pet material into a pet pack dsh-go can import — a clawd-on-desk theme, GIF/PNG/WebP stickers, a frame folder, an Aseprite export, or a single image. Use for "make this theme into a pet", "turn these stickers into a pet", "can this be imported?" and /pet-theme.
---

# Make a pet

Convert a material folder into a pet pack zip; the person picks it under
Settings → Pets → Import. The scripts live in scripts/.

Supported (detected from the folder's contents; one kind per folder):

- clawd-on-desk theme: theme.json + assets/
- Images: GIF / APNG / WebP / PNG, one animation per file; the filename
  gives the state (idle, thinking, working, error, done, sleep, walk,
  poke, drag, tickle, and similar English or Chinese words)
- Frame folders: walk/01.png, hello_01.png — the folder or prefix is the
  animation name
- Aseprite exports: JSON + atlas PNG, split by frameTags
- A single image: a static idle pet

Animations that match no state go to the idle theatre, so nothing is wasted.

## Steps

1. Get the material folder (git clone --depth 1 for a link, unzip for a
   zip). If the folder has neither theme.json nor images, stop and say
   what is supported.
2. Install dependencies only if missing: python3 -m pip install Pillow numpy
3. Convert:

       python3 <scripts>/pet_theme_convert.py --input <folder> --out /tmp/pet-pack --id <id> --input-name <name> [--source <link>]

   Pixel art (small, hard edges) keeps its size and draws crisply; other
   material is drawn smoothly on a 144 canvas. Add --crisp to force crisp.
4. Validate — it must PASS:

       python3 <scripts>/pet_pack_check.py /tmp/pet-pack/<id> --compat-reactions

5. Pack:

       cd /tmp/pet-pack/<id> && python3 -m zipfile -c <output path>/<id>.zip pack.json *.png

   On the phone, output to /sdcard/Download/DSH-Go/.
6. Finish: tell the person where to import it; the author and license show
   at the bottom of the pet page. Conversions are for personal use only —
   never bundle third-party material (especially CC BY-NC-SA fan work)
   into a release or the market.

## Boundaries

- One kind of material per folder; keep mixed material separate.
- Split sprite sheets into frames first, or export Aseprite JSON.
- States come from filename matching; when nothing matches, the first
  image is the idle and the rest go to the theatre.
- Do not hand-edit the generated pack.json, do not skip validation, and
  do not upload the person's material anywhere.
