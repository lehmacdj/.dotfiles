Tampermonkey userscripts, kept in sync with the browser via Tampermonkey's
native auto-update. Each script's `@updateURL`/`@downloadURL` point at its own
raw URL on `main`, so Tampermonkey pulls changes from this repo:

    https://raw.githubusercontent.com/lehmacdj/.dotfiles/main/tampermonkey/<name>.user.js

## Editing a script
- **Always bump `@version`** when you change a script. Tampermonkey only updates
  an installed script when the remote `@version` is *higher* than the local one;
  edits pushed without a version bump are ignored.
- Updates are one-way (repo => browser) and not instant: Tampermonkey checks on
  an interval (force it via the dashboard's "Check for userscript updates"), and
  `raw.githubusercontent.com` caches for ~5 min.

## Adding a new script
1. Create `<name>.user.js` with `@updateURL` and `@downloadURL` both set to this
   file's own raw URL (see the pattern above).
2. Commit and push.
3. Install it once by opening that raw URL in Firefox (Tampermonkey intercepts
   `*.user.js` and prompts to install). Auto-update only updates scripts that
   are already installed — a new file is invisible to Tampermonkey until this
   one-time install.
