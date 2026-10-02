-- ==========================================================
-- NEXT CALENDAR EVENT (only when one starts within 30 min)
-- ==========================================================
-- helpers/events (EventKit) prints "<minutes>|<title>". The first
-- run asks for calendar access for sketchybar. Click opens Calendar.

local config_dir = os.getenv("CONFIG_DIR")
local events_bin = config_dir .. "/helpers/events/bin/events"
local max_chars = 24

local next_event = SBAR.add("item", "next_event", {
	position = "right",
	update_freq = 60,
	drawing = false,
	icon = { string = "󰃭", padding_right = 4 },
	label = { font = LOOK.word_font() },
})
THEME.track_word(next_event)

local function truncate(text)
	if (utf8.len(text) or #text) <= max_chars then
		return text
	end
	local cut = utf8.offset(text, max_chars + 1)
	return cut and (text:sub(1, cut - 1) .. "…") or text
end

local function update()
	SBAR.exec(events_bin .. " 30 2>/dev/null", function(result)
		local minutes, title = result:match("^(%d+)|([^\n]*)")
		if not minutes then
			next_event:set({ drawing = false })
			return
		end
		local soon = tonumber(minutes) <= 5
		next_event:set({
			drawing = true,
			icon = { color = soon and COLORS.orange or DEFAULT_ITEM.icon.color },
			label = { string = "in " .. minutes .. "m · " .. truncate(title) },
		})
	end)
end

next_event:subscribe({ "routine", "system_woke" }, update)
next_event:subscribe("mouse.clicked", function()
	SBAR.exec("open -a Calendar")
end)
update()

THEME.on_change(update)
