---
paths:
  - ".config/sketchybar/**"
---

# SketchyBar

Canonical for the bar (AGENTS.md §3 indexes it). Each rule names what
it protects against; most were learned by breaking it.

## Switching and drawing

- **Switch themes live through `THEME.apply` / `THEME.apply_look`,
  never `sketchybar --reload`.** A reload flashes the whole bar. An
  item with colour logic of its own registers `THEME.on_change`; a
  label showing a word (not a number or icon) registers
  `THEME.track_word` so it follows the look's font.
- **Setting a background's colour turns it on.** To keep one hidden
  (a pill under Strip, a bracket that fades), set its colour first
  and its `drawing` flag in a **separate, later** `set`. One table
  with both fails at random: Lua table order is not defined.
  Recolour pills only through `THEME.pills`, never a regex over
  every item.
- **Run anything that hides pills after the theme hooks.** A hook
  that recolours a bracket switches it back on.

## Layout facts

- Right-side items lay out in the order `init.lua` adds them; a
  `--move` at load runs before the items exist.
- A popup is one column or one row. Every row has the popup's one
  height, so a 1 pt divider still costs a full row; use a caption or
  nothing. There is no popup x offset, only `align` and `y_offset`.
- Rows of a menu share a fixed label `width` so the hover highlight
  spans the menu (the `tailscale.lua` idiom).
- Hiding popup rows under the cursor can fire
  `mouse.exited.global`; guard a page switch with a short
  ignore-exit delay.
- An empty icon string drops its width: keep a transparent glyph
  where rows must align.

## Fonts and glyphs

- Numbers and icons stay Hack Nerd Font (equal-width digits stop
  readouts from jittering). Words use `LOOK.word_font()`.
- A family sketchybar cannot find falls back to the system font, so
  `helpers/fontstyle` asks macOS for a real style; no answer means
  stay on Hack.
- Check a new Nerd Font glyph renders before committing it.

## KiwiDesk from the bar

- Talk to KiwiDesk through one `SBAR.exec` per change, every verb
  run even if another is refused, silent without the CLI
  (`kiwi_shell` in `looks.lua`, `kiwidesk_command` in
  `helpers/shapes.lua`).
- After load, prefer `SBAR.exec` (async) to `io.popen`: a blocking
  call freezes the bar while it runs. Cache what must stay sync
  (as `style_of` does).
