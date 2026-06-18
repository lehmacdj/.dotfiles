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
skill dirs: `~/.claude/skills/`, `~/.codex/skills/`, `~/.gemini/skills/`. Use
`.symclaudeskill` for a Claude-only skill.

`SKILL.md` starts with frontmatter (`description:` and `user-invocable: true`);
the skill name comes from the directory, so there is no `name:` field.
