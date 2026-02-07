require("globals")
-- 1. Setup Bar and Defaults
SBAR.begin_config() -- Pauses redraw for faster loading

local separator_module = require("items.separator")

-- Left Side
require("items.menus")
separator_module.create("menu_separator")

-- Right Side (Order: Right -> Left)
require("items.calendar")
require("items.control_center")
require("items.theme_picker")
require("items.battery")
require("items.volume")
require("items.pomodoro")

SBAR.add("bracket", "right.bracket", { "cal.icon", "pomodoro" }, { background = { drawing = true } })
require("items.spofity")
-- Reset on unlock
require("items.unlock_reset")

-- 4. Finalize
SBAR.end_config()

-- 5. Setup a "delayed loader" for Spaces
SBAR.add("event", "aerospace_is_ready")
local spaces_loader = SBAR.add("item", { drawing = false })

spaces_loader:subscribe("aerospace_is_ready", function()
	-- This code runs only when the background waiter finishes
	SBAR.begin_config()
	local space_bracket_items = require("items.spaces")
	require("items.front_app")
	table.insert(space_bracket_items, "front_app")
	SBAR.add("bracket", "spaces.bracket", space_bracket_items, { background = { drawing = true } })
	separator_module.create("front_app_separator")
	require("items.resources")
	SBAR.end_config()

	spaces_loader:delete()
end)

-- 6. Run the wait loop in the BACKGROUND
-- We use bash to wait, so Lua can continue to the event_loop immediately
SBAR.exec([[bash -c '
    while ! aerospace list-workspaces --all > /dev/null 2>&1; do sleep 0.5; done
    sketchybar --trigger aerospace_is_ready
' &]])

SBAR.event_loop() -- This keeps the lua process alive
