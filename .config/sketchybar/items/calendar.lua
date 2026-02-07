-- 1. THE TIME (Top Line)
local cal_time = SBAR.add("item", "cal.time", {
	position = "right",
	width = 0, -- Stack logic
	y_offset = 4, -- Vertical lift
	label = {
		font = { size = DEFAULT_ITEM.label.font.size * 0.85 },
		align = "right",
		padding_right = 2,
		padding_left = DEFAULT_ITEM.icon.padding_left,
	},
})

-- 2. THE DATE (Bottom Line)
local cal_date = SBAR.add("item", "cal.date", {
	position = "right",
	y_offset = -6, -- Vertical drop
	label = {
		font = { size = DEFAULT_ITEM.label.font.size * 0.7 },
		color = COLORS.secondary_accent,
		padding_right = 2,
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
cal_time:subscribe("routine", update_calendar)
cal_time:set({ update_freq = 30 })

local function click_event()
	SBAR.exec("open -a Calendar")
end

-- Attach click to the whole group
cal_time:subscribe("mouse.clicked", click_event)
cal_date:subscribe("mouse.clicked", click_event)

update_calendar()
