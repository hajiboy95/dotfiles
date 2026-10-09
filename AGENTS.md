# dotfiles — Agent & Contributor Guidelines

Binding rules for humans and AI agents (Claude Code, Cursor, Codex)
working on this repository. Read this file before changing anything.

This file is the **hub**: the repo's shape, the rules that apply
everywhere, an index of the topic rules, and references. Topic rules
live one level down in [`.claude/rules/`](.claude/rules/), one file
per topic. Claude Code loads a rule file automatically when you edit
a file its `paths:` glob matches; everyone else follows the links in
§3. When a rule file and its one-line row in §3 disagree, the rule
file wins and the row is what to fix.

## 1. Repo shape

A fresh Mac becomes this desk with one `./setup.sh`: Homebrew and the
`Brewfile`, zsh, Ghostty, SketchyBar and KiwiDesk, linked into `$HOME`
with GNU Stow.

| Path | What |
|---|---|
| `setup.sh`, `Brewfile` | Bootstrap and the app list |
| `.zshrc`, `.zshenv`, `.env_power.zsh` | Shell |
| `.config/sketchybar/` | The bar, in Lua (SbarLua) — see §3 |
| `.config/KiwiDesk/init.lua` | KiwiDesk event hooks; `gui.json` and `profiles/` stay local |
| `.config/ghostty`, `starship.toml`, `direnv/`, `raycast_scripts/` | Other tools |
| `scripts/`, `bash_helpers/`, `notebook_cleaning/` | Repo-only helpers |

SketchyBar layout: `init.lua` adds items in order; `globals.lua` sets
the globals (`SBAR`, `LOOK`/`COLORS`, `DEFAULT_ITEM`, `THEME`);
`looks.lua` holds colour schemes; `helpers/shapes.lua` holds looks;
`helpers/theme.lua` switches both live; `items/` holds one module per
bar item.

## 2. Rules that apply everywhere

1. **Stow links everything not in `.stow-local-ignore` into `$HOME`.**
   A new repo-only file or directory (docs, agent files, helper
   scripts) goes into `.stow-local-ignore` in the same commit, or it
   lands in your home folder — `.claude/` would merge into the global
   `~/.claude`.
2. **Per-machine state stays out of git.** The theme picker's
   `active_theme.txt` / `active_look.txt`, KiwiDesk's `gui.json` and
   `profiles/` are local. Add new state files to `.gitignore`.
3. **The pre-commit hook owns style:** stylua and luacheck for Lua,
   ruff for Python, shellcheck for shell. Stylua parses Lua 5.1 only:
   no bitwise operators (`&`, `|`, `>>`) — use arithmetic.
4. **Colour must survive red-green colour-vision deficiency.** An
   on/off or active mark differs in shape or lightness, not hue
   alone; pairs that must separate sit on the blue↔yellow axis.
5. **KiwiDesk CLI writes are live only.** `kiwidesk <group>.set_*`
   changes the running app and never saves into a profile. Never
   edit `~/.config/KiwiDesk/profiles/*.json` from a script; read it.
6. **Comments explain why**, in the surrounding code's density. Keep
   commit messages in Conventional Commits form.
7. **Write a rule as an obligation, not a claim about the tree.**
   "Set a pill's drawing flag after its colour" cannot go stale;
   "only theme.lua touches pills" is false the day someone adds a
   second caller, and an agent reads it as fact. Name the enforcing
   check inline when one exists.

## 3. Topic rules (index)

| Rule | Loads for | One line |
|---|---|---|
| [sketchybar.md](.claude/rules/sketchybar.md) | `.config/sketchybar/**` | Sketchybar's real limits and this config's idioms: live theme switches, no `--reload`, colour-then-drawing order, popup rows |
| [looks.md](.claude/rules/looks.md) | `looks.lua`, `helpers/shapes.lua`, `helpers/theme.lua` | A palette is colour only; a look is total, never touches edges, never alters a palette's character |

## 4. Subagents

| Agent | Use it |
|---|---|
| [bar-designer](.claude/agents/bar-designer.md) | Before inventing a bar, popup or look design, and to grade one. Advisory and read-only. |

Agent files are hand-written and committed. They **point** at rule
files and KiwiDesk's docs by path; they never copy rule text, which
goes stale unnoticed.

## 5. References

KiwiDesk — the tiling window manager this desk runs:

- GitHub: <https://github.com/KiwiCanopy/KiwiDesk>
- Site and docs: <https://kiwidesk.kiwicanopy.com/docs/> —
  [user guide](https://kiwidesk.kiwicanopy.com/docs/user-guide/),
  [CLI](https://kiwidesk.kiwicanopy.com/docs/cli/),
  [Lua reference](https://kiwidesk.kiwicanopy.com/docs/lua-reference/),
  [design decisions](https://kiwidesk.kiwicanopy.com/docs/design-decisions/),
  [UI patterns](https://kiwidesk.kiwicanopy.com/docs/ui-patterns/),
  [recipes](https://kiwidesk.kiwicanopy.com/docs/recipes/)
- From the binary, offline and always current:
  `kiwidesk list_commands --json`, `kiwidesk help <command>`
- Local checkout (when present):
  `~/Desktop/Second_Brain/3_Ressourcen/Github/KiwiDesk` — `docs/`,
  `.claude/rules/` (e.g. `bars.md`, `borders.md`, `gui.md`), and the
  bundled looks and palettes under
  `Sources/KiwiDeskCore/Resources/`

SketchyBar:

- Docs: <https://felixkratz.github.io/SketchyBar/>
- Lua API (SbarLua): <https://github.com/FelixKratz/SbarLua>
- Live state: `sketchybar --query <item|bar>`
