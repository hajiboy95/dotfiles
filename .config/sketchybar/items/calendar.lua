-- 1. THE TIME (Top Line)
local cal_time = SBAR.add("item", "cal.time", {
	position = "right",
	width = 0, -- Stack logic
	y_offset = 5, -- Vertical lift (symmetric with the date)
	label = {
		font = { size = DEFAULT_ITEM.label.font.size * 0.85 },
		align = "right",
		padding_right = 0,
		padding_left = DEFAULT_ITEM.icon.padding_left,
	},
})

-- 2. THE DATE (Bottom Line)
local cal_date = SBAR.add("item", "cal.date", {
	position = "right",
	y_offset = -5, -- Vertical drop
	-- Hack like the time: script fonts such as Apple Chancery set
	-- old-style figures, whose digits drop below the line ("02").
	label = {
		font = { size = DEFAULT_ITEM.label.font.size * 0.7 },
		color = COLORS.secondary_accent,
		padding_right = 0,
		padding_left = DEFAULT_ITEM.icon.padding_left,
	},
	icon = { drawing = false },
})

-- 4. UPDATE LOGIC
local function update_calendar()
	cal_date:set({ label = { string = os.date("%a %b %d"):upper() } })
	cal_time:set({ label = { string = os.date("%H:%M") } })
end

-- 5. SUBSCRIPTIONS & INTERACTION
cal_time:subscribe({ "routine", "system_woke" }, update_calendar)
-- 5 s: the clock turns at most 5 s late (os.date is in-process).
cal_time:set({ update_freq = 5 })

-- Click: the month view (items/calendar_popup.lua), anchored at the
-- pill's right end (CAL_VIEW_ANCHOR, made first in init.lua) so it lines
-- up with the pill instead of stopping at the clock.
local month_view = require("items.calendar_popup")(CAL_VIEW_ANCHOR)
local function click_event()
	month_view.toggle()
end

-- Attach click to the whole group
cal_time:subscribe("mouse.clicked", click_event)
cal_date:subscribe("mouse.clicked", click_event)

update_calendar()

THEME.on_change(function()
	cal_date:set({ label = { color = COLORS.secondary_accent } })
end)
