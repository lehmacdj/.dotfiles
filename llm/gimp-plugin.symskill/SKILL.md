---
description: "Authoring GIMP 3 plug-ins in Script-Fu — script-fu-register-filter, SF-* parameter types, menu registration, installing via symlink, the Refresh-Scripts registration-cache gotcha, headless testing, and well-behaved-plugin conventions."
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
# macOS
ln -sf /abs/path/to/repo/plugin/my-thing.scm \
  ~/Library/Application\ Support/GIMP/3.0/scripts/
```

Scripts dir per OS:
- macOS: `~/Library/Application Support/GIMP/3.0/scripts/`
- Linux: `~/.config/GIMP/3.0/scripts/`
- Windows: `%APPDATA%\GIMP\3.0\scripts\`

Then in GIMP: **Filters → Script-Fu → Refresh Scripts** (no restart needed). The
command appears at whatever path you gave `script-fu-menu-register`.

## The registration-cache gotcha (this *will* bite headless testing)

GIMP caches plug-in registrations. A **brand-new or just-edited** script is
**not** picked up by a fresh `gimp-console` batch run — only scripts already in
the cache (from a prior GUI run / Refresh) auto-register. Symptom: your proc
reads as an unbound variable and the batch *hangs* (script-fu deadlocks on
error; `timeout` is the escape — see the `gimp` skill).

For headless testing, **explicitly `(load ...)` the file first**, then call it:

```scheme
(load "/abs/path/to/plugin/my-thing.scm")
(let* ((img (car (gimp-image-new 800 600 RGB))) ...)
  (gimp-image-set-resolution img 300 300)
  (script-fu-my-thing img (make-vector 1 layer)  arg1 arg2)
  (file-png-export RUN-NONINTERACTIVE img "/abs/out.png" -1)
  (gimp-quit 0))
```

Verify registration separately with
`(defined? (quote script-fu-my-thing))` after load. In the GUI, Refresh Scripts
(or restart) is what populates the cache.

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
