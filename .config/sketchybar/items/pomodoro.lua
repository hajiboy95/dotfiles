-- 1. CONFIGURATION
local default_duration = 25 * 60
local sound_path = "/System/Library/PrivateFrameworks/ScreenReader.framework/Versions/A/Resources/Sounds/"
local active_timer_end = nil

-- 2. HELPERS
local function play_sound(file)
	SBAR.exec("afplay " .. sound_path .. file)
end
local function format_time(seconds)
	local m = math.floor(seconds / 60)
	local s = seconds % 60
	return string.format("%02d:%02d", m, s)
end

-- 4. CREATE MAIN ITEM
local timer = SBAR.add("item", "pomodoro", {
	position = "right",
	icon = { string = "􀐱", y_offset = 1 },
	label = { drawing = false },
	update_freq = 0, -- Don't update unless running
})

-- 5. LOGIC: Stop
local function stop_timer()
	active_timer_end = nil
	timer:set({
		label = { drawing = false },
		update_freq = 0,
		popup = { drawing = false },
	})
	play_sound("TrackingOff.aiff")
end

-- 6. LOGIC: Start
local function start_timer(duration_seconds)
	if not duration_seconds then
		return
	end
	active_timer_end = os.time() + duration_seconds
	timer:set({
		update_freq = 1, -- Start ticking every second
		popup = { drawing = false },
	})
	play_sound("TrackingOn.aiff")
	timer:trigger("routine")
end

local function open_custom_settimer()
	SBAR.exec(
		'osascript -e \'display dialog "Enter time (MM:SS or Minutes):" '
			.. 'default answer "" '
			.. 'with title "Set Timer" '
			.. 'buttons {"Cancel", "Start"} '
			.. 'default button "Start"\'',
		function(result)
			-- 1. Try to match "MM:SS" format first (e.g., 5:30)
			local m, s = result:match("text returned:(%d+):(%d+)")
			if m and s then
				start_timer(tonumber(m) * 60 + tonumber(s))
				return
			end

			-- 2. Fallback to just "Minutes" (e.g., 25)
			local m_only = result:match("text returned:(%d+)")
			if m_only then
				start_timer(tonumber(m_only) * 60)
			end
		end
	)
end

-- 7. LOGIC: Update Loop
timer:subscribe("routine", function()
	if not active_timer_end then
		return
	end
	local now = os.time()
	local remaining = active_timer_end - now
	if remaining > 0 then
		timer:set({ label = { string = format_time(remaining), drawing = true } })
	else
		active_timer_end = nil
		timer:set({ label = { string = "Done!" }, update_freq = 0 })
		play_sound("GuideSuccess.aiff")
	end
end)

-- 8. CREATE POPUP MENU
local presets = { 5, 10, 25, 45 }

for _, mins in ipairs(presets) do
	local p = SBAR.add("item", "timer." .. mins, {
		position = "popup." .. timer.name,
		label = {
			padding_left = DEFAULT_ITEM.icon.padding_left,
			padding_right = DEFAULT_ITEM.icon.padding_right,
			string = string.format("%2d Minutes", mins),
		},
		icon = { drawing = false },
	})

	p:subscribe("mouse.clicked", function()
		start_timer(mins * 60)
	end)

	-- Add hover highlight so the user knows they are clicking it
	p:subscribe("mouse.entered", function()
		p:set({ background = { drawing = true, color = 0x33ffffff } })
	end)
	p:subscribe("mouse.exited", function()
		p:set({ background = { drawing = false } })
	end)
end

-- 9. CREATE "CUSTOM" INPUT ITEM
local custom = SBAR.add("item", "timer.custom", {
	position = "popup." .. timer.name,
	icon = { drawing = false },
	label = {
		string = "Custom...",
		padding_left = DEFAULT_ITEM.icon.padding_left,
		padding_right = DEFAULT_ITEM.icon.padding_right,
	},
})

custom:subscribe("mouse.clicked", function()
	timer:set({ popup = { drawing = false } })
	open_custom_settimer()
end)

custom:subscribe("mouse.entered", function()
	custom:set({ background = { drawing = true, color = 0x33ffffff } })
end)
custom:subscribe("mouse.exited", function()
	custom:set({ background = { drawing = false } })
end)

-- 10. MOUSE INTERACTIONS
timer:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "right" then
		if active_timer_end then
			stop_timer()
		else
			start_timer(default_duration)
		end
	else
		local is_drawing = timer:query().popup.drawing
		timer:set({ popup = { drawing = (is_drawing == "off") } })
	end
end)

-- Event Handling
timer:subscribe({ "mouse.exited.global" }, function()
	timer:set({ popup = { drawing = false } })
end)
