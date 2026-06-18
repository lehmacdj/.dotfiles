---
description: "Authoring GIMP 3 plug-ins in Script-Fu — script-fu-register-filter, SF-* parameter types, menu registration, installing via symlink into the active version's scripts dir, headless testing with (load), and well-behaved-plugin conventions."
user-invocable: true
---

For writing GIMP 3 Script-Fu plug-ins (`.scm`) that register into the menus and
take a dialog of parameters — as opposed to one-off batch automation.

This skill is the *authoring* counterpart to the `gimp` skill. That skill owns
the shell invocation pattern, API discovery (GIR / bundled scripts / probing),
and the verified GIMP 3 signature gotchas. **Read it for anything about calling
the PDB**; this skill only adds the plug-in scaffolding on top.

Bundled scripts are the best registration examples to crib from:
`/Applications/GIMP.app/Contents/Resources/share/gimp/3.0/scripts/*.scm`
(e.g. `addborder.scm`, `round-corners.scm`).

## Skeleton

```scheme
(define (script-fu-my-thing image drawables  arg1 arg2)   ; note: drawables is a VECTOR
  (let* ((res (gimp-image-get-resolution image)))         ; DPI, if you size in mm
    (gimp-image-undo-group-start image)                   ; one undo step
    (gimp-context-push)                                   ; don't clobber user FG/BG/etc.
    (gimp-context-set-foreground '(0 0 0))
    ;; ... do work on a NEW named layer where possible ...
    (gimp-context-pop)
    (gimp-image-undo-group-end image)
    (gimp-displays-flush)))                               ; repaint the canvas

(script-fu-register-filter "script-fu-my-thing"
  _"My _Thing..."                 ; menu label (the _ marks the mnemonic)
  _"What it does (tooltip)."      ; description
  "Author Name"
  "Author Name"                   ; copyright
  "2026"                          ; date
  "*"                             ; image types: "*" any | "RGB*" | "GRAY*" ...
  SF-ONE-OR-MORE-DRAWABLE         ; drawable arity (see below)
  SF-ADJUSTMENT _"Some size (mm)" '(0 0 100 0.1 1 2 1)
  SF-OPTION     _"Mode" '(_"A" _"B" _"C")
  SF-TOGGLE     _"Flatten" FALSE)

(script-fu-menu-register "script-fu-my-thing" "<Image>/Filters/Render")
```

- `script-fu-register-filter` is the GIMP 3 form for filters that act on an open
  image. The function then receives `image` and `drawables` (a vector — use
  `(vector-ref drawables 0)` for the first) *before* your declared parameters.
- Use plain `script-fu-register` instead for procedures that create/output an
  image and don't operate on an existing drawable (omit the drawable-arity arg).
- Wrap user-facing strings in `_"..."` so they're translatable.

## SF-* parameter types

| Type | Spec | Passed to fn |
|------|------|--------------|
| `SF-ONE-OR-MORE-DRAWABLE` / `SF-ONE-DRAWABLE` | (arity slot, not a param) | a vector of drawables |
| `SF-ADJUSTMENT _"label" '(val min max step page digits type)` | `digits` = decimals; `type` 0=slider 1=spinbox | number |
| `SF-OPTION _"label" '(_"a" _"b" ...)` | dropdown | 0-based index |
| `SF-TOGGLE _"label" FALSE` | checkbox | `TRUE`/`FALSE` (1/0) |
| `SF-COLOR _"label" '(r g b)` | color button | `(r g b)` list |
| `SF-VALUE` / `SF-STRING` / `SF-ADJUSTMENT` etc. | | number / string |

## Installing — prefer a symlink

**Symlinking the repo's `.scm` into the scripts dir is preferred** to copying:
edits in the repo go live with just a *Refresh Scripts*, and there's no stale
duplicate to forget about.

```sh
# macOS (use the ACTIVE version dir — see gotcha below)
ln -sfn /abs/path/to/repo/plugin/my-thing.scm \
  ~/Library/Application\ Support/GIMP/3.2/scripts/
```

Scripts dir per OS (note the version segment — see gotcha below):
- macOS: `~/Library/Application Support/GIMP/<ver>/scripts/`
- Linux: `~/.config/GIMP/<ver>/scripts/`
- Windows: `%APPDATA%\GIMP\<ver>\scripts\`

Then in GIMP: **Filters → Script-Fu → Refresh Scripts** (no restart needed). The
command appears at whatever path you gave `script-fu-menu-register` — and, for a
`register-filter`, only when an **image is open** (it's an `<Image>` filter).

### Gotcha: the config-dir version segment must match the running GIMP

`<ver>` tracks GIMP's **major.minor**, not a fixed `3.0`. GIMP 3.2.x reads
`.../GIMP/3.2/`, GIMP 3.0.x reads `.../GIMP/3.0/`. Stale dirs from older
installs linger and will silently swallow your script if you guess wrong — the
scan only looks in the *active* version's dir. Confirm before installing:

```sh
/Applications/GIMP.app/Contents/MacOS/gimp-console --version    # -> 3.2.4
ls -la ~/Library/Application\ Support/GIMP/*/pluginrc           # newest mtime = live dir
```

The dir whose `pluginrc` was touched on the last GIMP run is the live one; drop
your script in *that* `scripts/`. Reliable cross-check: find an add-on GIMP
currently sees and install next to it.

Note: `gimp-console -b` eval mode (the `gimp` skill's invocation) does **not**
scan the user `scripts/` dir at all, so `(defined? …)` there is **not** a valid
test of GUI registration — only of an explicit `(load …)`.

## Headless testing (this *will* bite if you skip the `(load …)`)

`gimp-console --batch-interpreter=plug-in-script-fu-eval -b …` does **not** run
the script-fu directory scan, so **no** user `scripts/` file is registered in
that mode — verified: even a trivial freshly-dropped script reads as undefined
there, while bundled procs are present. This is *not* a cache staleness issue;
the scan just doesn't happen in eval mode. Symptom if you call your proc without
loading it: unbound-variable error and the batch *hangs* (script-fu deadlocks;
`timeout` is the escape — see the `gimp` skill).

So for headless testing, **explicitly `(load ...)` the file first**, then call
it:

```scheme
(load "/abs/path/to/plugin/my-thing.scm")
(let* ((img (car (gimp-image-new 800 600 RGB))) ...)
  (gimp-image-set-resolution img 300 300)
  (script-fu-my-thing img (make-vector 1 layer)  arg1 arg2)
  (file-png-export RUN-NONINTERACTIVE img "/abs/out.png" -1)
  (gimp-quit 0))
```

Verify registration separately with `(defined? (quote script-fu-my-thing))`
*after* the load. The GUI (or **Refresh Scripts**) is the only thing that runs
the real scan that wires the proc into the menus.

## Well-behaved-plugin conventions

- **Undo group**: wrap all mutation in `gimp-image-undo-group-start` /
  `...-end`. If the proc errors between them, GIMP warns *"left image undo in
  inconsistent state, closing open undo groups"* — a reliable signal that a PDB
  call inside failed (find it by inserting `gimp-message` checkpoints, since the
  deadlock hides the real error).
- **Context**: `gimp-context-push` / `...-pop` around any
  `gimp-context-set-*` so you restore the user's foreground/background/paint
  settings.
- **`gimp-displays-flush`** at the very end so an interactive canvas updates.
- Prefer drawing onto a **new, named layer** over mutating the user's layers, so
  the result is identifiable and easy to delete.
- A syntax/registration error makes Refresh Scripts **silently skip** the file
  (menu item just never appears). Check **Filters → Script-Fu → Console** or
  load the file there to surface the error.

## Tests

Add a headless regression test when you write a plug-in (and offer to even when
not asked — it's easy to skip but cheap to keep). Structure is up to you and the
plug-in; a shell script driving `gimp-console` that builds a synthetic image,
runs the proc, and checks the result is plenty.

A few things that bite, however you organise it:
- The runner is `gimp-console --batch-interpreter=plug-in-script-fu-eval -b`,
  which **does not scan the scripts dir** (see above) — `(load …)` the plug-in
  yourself before calling it, and wrap the run in `timeout` (script-fu deadlocks
  on error).
- Asserting on *structure* via PDB queries (`gimp-drawable-get-width/height`,
  `-get-offsets`, `gimp-image-get-item-position`, canvas size, layer names)
  catches most regressions without touching a pixel.
- For pixel/geometry checks, exporting a PNG and measuring it (e.g. pillow via
  `uv run`) is far less painful than `gimp-drawable-get-pixel`, whose script-fu
  return shape is build-dependent. Flatten a **duplicate** with a known
  background first so transparency renders deterministically.
- Don't rely on `gimp-quit`'s exit code for pass/fail; print `PASS:`/`FAIL:`
  lines and have the shell decide, and confirm a sentinel line was reached so an
  early GIMP error counts as a failure rather than a pass.

`~/src/gimp/cricut-sensor-marks/plugin/tests/` is one worked example.
