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

## Agent skills
Skills live as `<name>.symskill/` directories (usually under `llm/`), each
containing a `SKILL.md`. `install` links a `.symskill` into all three agent
skill dirs: `~/.claude/skills/`, `~/.codex/skills/`, `~/.gemini/skills/`.

`SKILL.md` starts with frontmatter (`description:` and `user-invocable: true`);
the skill name comes from the directory, so there is no `name:` field.

### Published skills
Skills under `llm/plugin/skills/` are additionally published through the
`devin-skills` Cowork plugin declared in `.claude-plugin/marketplace.json`.
These directories carry no suffix, since a plugin skill's command name comes
from its directory name; `install` links them into all three agent skill dirs
under that plain name. Publish a skill by moving it there and dropping the
`.symskill` suffix — no manifest edit is needed, and the plugin version
tracks the repo's commit SHA so a push is picked up as an update.

Note that installing the plugin locally as well would duplicate these skills:
plugin skills are always namespaced (`/devin-skills:gimp`) and coexist with the
unprefixed `/gimp` that `install` provides, rather than overriding it.
