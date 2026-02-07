require("globals")
-- 1. Setup Bar and Defaults
SBAR.begin_config() -- Pauses redraw for faster loading

local bracker_spacer_module = require("items.bracket_spacer")
local lpad = DEFAULT_ITEM.background.padding_left
local rpad = DEFAULT_ITEM.background.padding_right

local separator_module = require("items.separator")

-- Left Side
require("items.menus")
separator_module.create("menu_separator")

-- Right Side (Order: Right -> Left)
require("items.calendar")
bracker_spacer_module.create("spacer_1", rpad + lpad)
require("items.volume") -- Volume Slider
bracker_spacer_module.create("spacer_2", lpad)
require("items.pomodoro") -- Timer
require("items.theme_picker")
require("items.battery") -- Battery Level
require("items.cpu") -- CPU %
bracker_spacer_module.create("spacer_3", rpad)
require("items.network") -- Net Speed
bracker_spacer_module.create("spacer_4", rpad)
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
	require("items.spaces")
	require("items.front_app")
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
