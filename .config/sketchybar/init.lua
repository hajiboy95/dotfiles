require("globals")
-- 1. Setup Bar and Defaults
SBAR.begin_config() -- Pauses redraw for faster loading

local separator_module = require("items.separator")

-- Left Side
require("items.menus")
separator_module.create("menu_separator")

-- Right Side (Order: Right -> Left)
require("items.theme_picker")
require("items.calendar")
require("items.control_center")
require("items.battery")
require("items.volume")
require("items.pomodoro")

SBAR.add("bracket", "right.bracket", { "theme_picker", "pomodoro" }, { background = { drawing = true } })
separator_module.create("spotify_separator", "right")
require("items.spotify")

-- Spaces widget: loaded directly, no boot-wait needed. The
-- widget carries its own get_state watchdog (polls until the
-- KiwiDesk IPC socket answers, then goes event-driven), so the
-- space items draw immediately and populate the moment KiwiDesk
-- is up — no pgrep/sleep gate required.
require("items.spaces")
separator_module.create("resources_separator")
require("items.resources")

-- 4. Finalize
SBAR.end_config()

SBAR.event_loop() -- This keeps the lua process alive
