---
description: "Headless / batch operations on GIMP .xcf files via script-fu (listing layers, exporting layers as PNGs, running PDB procedures from the shell)"
user-invocable: true
---

For automating GIMP operations from the shell on macOS.

## Invocation pattern

```bash
timeout 30 /Applications/GIMP.app/Contents/MacOS/gimp-console \
  --batch-interpreter=plug-in-script-fu-eval \
  -b "<scheme code ending in (gimp-quit 0)>" 2>&1
```

- `--batch-interpreter=...` is required in GIMP 3; without it `-b` hangs silently.
- The scheme must end with `(gimp-quit 0)` — GIMP does not auto-exit after a batch command.
- Always wrap with `timeout`. On script error, `gimp-console` and the script-fu plug-in process deadlock waiting on each other over their IPC pipe; `(gimp-quit 0)` is the only clean teardown. `timeout` is the escape hatch when a script errors before reaching it.
- The Bash tool needs `dangerouslyDisableSandbox: true` so GIMP can write its config under `~/Library/Application Support/GIMP/3.0/`.

## Expected timing (macOS, MacPorts build)

Pick the `timeout` to match the actual workload — overkill timeouts just delay the feedback when something is genuinely wedged.

| Operation                                 | Expected | Suggested `timeout` |
|-------------------------------------------|----------|---------------------|
| Pure startup (`(gimp-quit 0)` only)       | ~2-3s    | 10s                 |
| Startup + load one `.xcf` (≤200MB)        | +1-3s    | 15s                 |
| Listing/walking all layers                | ~3-5s    | 15s                 |
| Single-layer export (load + merge + PNG)  | ~3-6s    | 30s                 |
| N-layer export (loading file each loop)   | ~3-6s × N | scale with N       |

If `timeout` fires with no stderr from script-fu, the script most likely errored before reaching `(gimp-quit 0)` — re-run with a smaller probe to surface the message.

## Error visibility

When a script errors, script-fu prints to stderr a line like:
```
Error: eval: unbound variable: <name>
Stopping at failing batch command [0]: (<your code>)
```
and then hangs (until `timeout`). Just let errors propagate — they're informative on their own.

## API discovery

GIMP 3 changed many script-fu signatures from 2.x; do not trust memory.

- Bundled scheme examples (good for real-world patterns): `/Applications/GIMP.app/Contents/Resources/share/gimp/3.0/scripts/*.scm`
- Static GIR for library API: `/Applications/GIMP.app/Contents/Resources/share/gir-1.0/Gimp-3.0.gir`
- Runtime-registered procs (`file-*`, `plug-in-*`) are not in the GIR. Probe by calling with wrong/missing args — the deprecation warning prints the canonical named-arg form, e.g.:
  ```
  Please use named arguments: (file-png-export #:run-mode 1 #:image 1 #:file ... #:options -1)
  ```
  which reveals the arg names and order.
- `(defined? (quote some-proc-name))` returns whether a symbol is bound.

## Verified GIMP 3 signatures and gotchas

- `gimp-image-get-layers` returns `(vector)` not `(count vector)` — use `(car r)`, not `(cadr r)`.
- Use `gimp-drawable-get-{offsets,width,height}`; `gimp-item-get-offsets` does not exist.
- `gimp-item-get-parent` returns `(-1)` for top-level items.
- PNG export is `file-png-export` (not `file-png-save`):
  `(file-png-export RUN-NONINTERACTIVE image path -1)` where `-1` means NULL options. Positional args still work but emit a deprecation warning.
- `gimp-image-merge-visible-layers` silently returns NULL ("PDB procedure returned NULL GIMP object" warning) when only one top-level layer is visible. To flatten a group into a single layer at its natural bbox, use `gimp-group-layer-merge` instead.
- Merge-type constants: `EXPAND-AS-NECESSARY=0`, `CLIP-TO-IMAGE=1`, `CLIP-TO-BOTTOM-LAYER=2`, `FLATTEN-IMAGE=3`.

## Recipe: list all layers (with names, IDs, group nesting)

```scheme
(define INPUT "/abs/path/to/file.xcf")
(define (walk lst depth)
  (for-each
    (lambda (lid)
      (let* ((name (car (gimp-item-get-name lid)))
             (is-group (= (car (gimp-item-is-group lid)) 1)))
        (gimp-message (string-append (make-string (* depth 2) #\space)
                                     (number->string lid) " " name
                                     (if is-group " [GROUP]" "")))
        (if is-group
            (walk (vector->list (car (gimp-item-get-children lid)))
                  (+ depth 1)))))
    lst))
(let ((image (car (gimp-file-load RUN-NONINTERACTIVE INPUT "x"))))
  (walk (vector->list (car (gimp-image-get-layers image))) 0)
  (gimp-quit 0))
```

Layer names appear on stderr as `script-fu-Warning: <name>` lines.

## Recipe: export layers/groups as PNGs (one PNG per layer, sized to its bbox)

Each output PNG has a canvas equal to the layer's bounding box. Works for both regular layers and groups (groups are flattened via `gimp-group-layer-merge`). Sibling layers are hidden so they don't bleed through.

```scheme
(define INPUT "/abs/path/to/file.xcf")
(define OUTDIR "/abs/path/to/out/")          ; trailing slash
(define NAMES (list "layer-a" "layer-b"))    ; exact layer names

(define (find-by-name items name)
  (if (null? items) #f
      (let* ((item (car items))
             (iname (car (gimp-item-get-name item))))
        (if (equal? iname name) item
            (let ((sub (if (= 1 (car (gimp-item-is-group item)))
                           (find-by-name (vector->list (car (gimp-item-get-children item))) name)
                           #f)))
              (if sub sub (find-by-name (cdr items) name)))))))

(define (hide-recursive item)
  (gimp-item-set-visible item 0)
  (if (= 1 (car (gimp-item-is-group item)))
      (for-each hide-recursive
                (vector->list (car (gimp-item-get-children item))))))

(define (show-ancestors item)
  (let ((p (car (gimp-item-get-parent item))))
    (if (not (= p -1))
        (begin (gimp-item-set-visible p 1) (show-ancestors p)))))

(define (export-one name)
  (let* ((image (car (gimp-file-load RUN-NONINTERACTIVE INPUT "x")))
         (top (vector->list (car (gimp-image-get-layers image))))
         (target (find-by-name top name)))
    (if (not target)
        (begin (gimp-message (string-append "NOT FOUND: " name))
               (gimp-image-delete image))
        (let* ((flat (if (= 1 (car (gimp-item-is-group target)))
                         (car (gimp-group-layer-merge target))
                         target))
               (off (gimp-drawable-get-offsets flat))
               (ox (car off)) (oy (cadr off))
               (w (car (gimp-drawable-get-width flat)))
               (h (car (gimp-drawable-get-height flat))))
          (for-each hide-recursive
                    (vector->list (car (gimp-image-get-layers image))))
          (gimp-item-set-visible flat 1)
          (show-ancestors flat)
          (gimp-image-resize image w h (- 0 ox) (- 0 oy))
          (file-png-export RUN-NONINTERACTIVE image
                           (string-append OUTDIR name ".png") -1)
          (gimp-image-delete image)
          (gimp-message (string-append "exported " name " ("
                                       (number->string w) "x"
                                       (number->string h) ")"))))))

(for-each export-one NAMES)
(gimp-quit 0)
```

Workflow:
1. Run the listing recipe first to discover the available layer names. If the user gave a pattern (e.g. "ending in `_sticker`"), filter the list and confirm the targets before exporting.
2. Substitute `INPUT`, `OUTDIR`, `NAMES`, run with a `timeout` scaled to `~6 × len(NAMES)` plus a few seconds.
3. `script-fu-Warning: exported <name> (WxH)` lines confirm each output.
