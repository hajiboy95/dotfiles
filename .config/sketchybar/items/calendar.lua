local settings = {
	font = {
		numbers = "SketchyBar App Font:Bold:13.0", -- Or your preferred bold font
		text = "SketchyBar App Font:Semibold:10.0",
	},
}

-- 1. THE ICON (Left side of the pill)
local cal_icon = SBAR.add("item", "cal.icon", {
	position = "right",
	icon = {
		string = "􀐫",
		padding_left = 0,
	},
	label = { drawing = false }, -- Icon only
})

-- 2. THE TIME (Top Line)
local cal_time = SBAR.add("item", "cal.time", {
	position = "right",
	width = 0, -- Stack logic
	y_offset = 4, -- Vertical lift
	label = {
		font = settings.font.numbers,
		align = "right",
		padding_right = 2,
		padding_left = DEFAULT_ITEM.icon.padding_left,
	},
})

-- 3. THE DATE (Bottom Line)
local cal_date = SBAR.add("item", "cal.date", {
	position = "right",
	y_offset = -6, -- Vertical drop
	label = {
		font = settings.font.text,
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
cal_icon:subscribe("routine", update_calendar)
cal_icon:set({ update_freq = 30 })

local function click_event()
	SBAR.exec("open -a Calendar")
end

-- Attach click to the whole group
cal_icon:subscribe("mouse.clicked", click_event)
cal_time:subscribe("mouse.clicked", click_event)
cal_date:subscribe("mouse.clicked", click_event)

update_calendar()
