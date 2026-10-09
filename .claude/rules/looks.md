---
paths:
  - ".config/sketchybar/looks.lua"
  - ".config/sketchybar/helpers/shapes.lua"
  - ".config/sketchybar/helpers/theme.lua"
  - ".config/sketchybar/items/theme_picker.lua"
---

# Colour schemes and looks

Canonical for the theme system (AGENTS.md §3 indexes it). It mirrors
KiwiDesk's own split of palette and look; its rulings (design
decisions, "A palette is a color recipe", "A bundled look is total")
are the reference — see AGENTS.md §5.

- **A colour scheme (`looks.lua`) carries colour only.** No font,
  glow, size or shape rides on a palette. KiwiDesk retracted a
  palette that switched glow on (#578): a later colour-only palette
  could never switch it off again.
- **A look (`helpers/shapes.lua`) is total.** Every look writes
  every key it owns — shape, sizes, gaps, margins, font, glass —
  including zeros, so nothing of the previous look lingers. A new
  key goes into every preset and into the KiwiDesk look's profile
  read-back in the same change.
- **Never write edges** (`app_bar.set_edge`, `space_bar.set_edge`).
- **A look never alters a palette's character.** It may cap the
  pill alpha for glass or a flat tint, and switch to the scheme's
  `glass{}` variant; it never swaps a palette's hue for another.
  If a look needs a different colour, pair it with another palette
  (`M.palettes`).
- **Liquid Glass is one switch.** Shelf, drag, sticky and shortcut
  panel follow the same value. Sketchybar cannot draw real glass,
  so a look where both bars must match (Strip) paints one flat
  colour on both, with no sketchybar blur.
- **Retiling keys are not re-sent unchanged.** Thickness, margins
  and gaps each retile every Space; picking the active look again
  forces a full send.
- **The KiwiDesk look reads the profile, never writes it.** CLI
  writes are live only, so the profile file is the user's truth.
- **Check contrast, not hue.** Light text over a glass or tint pill,
  dark text over an opaque bright one; the picker's dot must stay
  visible on the popup (`swatch`).
