This repo stores my dotfiles / most of the config that I need to setup a new computer.

## Configuration Files
Configuration files are stored with a suffix that tells the `install` script where it should be symlinked. e.g.:
- `<file>.symdot` => `~/.<file>`
- `<file>.symconfig` => `~/.config/<file>`
- `<file>.symclaude` / `.symcodex` / `.symgemini` => `~/.claude/` / `~/.codex/` / `~/.gemini/`

Files may be in any subdirectory of the repo; this is used to organize config files.

After adding, renaming, or moving any `.sym*` file, run `./install` to create
the symlinks — don't hand-create them with `ln`. `install` is idempotent (skips
already-correct links) and a plain run does not touch Homebrew (that's `--all`).

## Scripts
`bin/` is on `PATH`: an executable placed there is available as a command
everywhere, with no install step.

## Agent skills
Every skill lives as a suffix-free `llm/skills/<name>/` directory containing a
`SKILL.md`. `install` links each one into all three agent skill dirs:
`~/.claude/skills/`, `~/.codex/skills/`, `~/.gemini/skills/`.

Only directories are linked; hidden ones and stray files are ignored.

`llm/` is also the root of the `devin-skills` Cowork plugin declared in
`.claude-plugin/marketplace.json`, which is why skills live in `llm/skills/`
and carry no suffix: that is the directory the plugin scans by default, and a
plugin skill's command name comes from its directory name. Adding a skill there
publishes it — no manifest edit — and the plugin version tracks the repo's
commit SHA, so pushing is what ships an update.

Two consequences of `llm/` being the plugin root:
- Files in `llm/` named exactly `settings.json`, or directories named
  `agents/`, `hooks/`, `commands/`, `bin/`, or `monitors/`, would be loaded as
  plugin components. The existing agent config files are safe only because
  their `.sym*` suffixes stop the names from matching.
- The plugin is personal, so installing it *and* running `install` on the same
  machine would list every skill twice: plugin skills are always namespaced
  (`/devin-skills:gimp`) and coexist with the unprefixed `/gimp` rather than
  overriding it.
