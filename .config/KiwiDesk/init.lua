-- KiwiDesk config (init.lua)
--
-- Settings are GUI-managed (gui.json) — the Settings app owns
-- gaps, layouts, keybindings, rules, etc. This file carries only
-- the behavioral glue the GUI can't express: event hooks.
--
-- Event hooks run regardless of GUI management: the structured
-- loader resets the managed *binds* block, but KiwiDesk.on hooks
-- still fire.

-- ==========================================================
-- SKETCHYBAR BRIDGE
-- ==========================================================
-- KiwiDesk never triggers sketchybar itself. These hooks fire
-- the custom `kiwidesk_update` event that the spaces widget
-- (items/spaces.lua) subscribes to; its handler re-queries full
-- state via `get_state`, so any state-changing event just needs
-- to poke it once.
for _, event in ipairs({
	"space_change",
	"layout_change",
	"focus_change",
	"native_space_change",
	"window_created",
	"window_destroyed",
	"window_moved_to_space",
}) do
	KiwiDesk.on(event, function()
		KiwiDesk.exec("sketchybar --trigger kiwidesk_update")
	end)
end
