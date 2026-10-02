local icons = {
	_100 = "􀊩",
	_66 = "􀊧",
	_33 = "􀊥",
	_10 = "􀊡",
	_0 = "􀊣",
}

local volume_slider = SBAR.add("slider", 100, {
	position = "right",
	updates = true,
	label = { drawing = false },
	icon = { drawing = false },
	slider = {
		highlight_color = COLORS.accent_color,
		width = 0,
		background = {
			height = 6,
			corner_radius = 3,
			-- The track: a faint wash of the idle colour, not
			-- sketchybar's default black.
			color = LOOK.with_alpha(COLORS.disabled_color, 0x40),
		},
		knob = {
			string = "􀀁",
			drawing = false,
		},
	},
})

local volume_icon = SBAR.add("item", "volume_icon", {
	position = "right",
	label = { drawing = false },
})

-- background must carry at least one real property: an empty
-- { background = {} } makes SbarLua emit a property-less `--set
-- volume.bracket`, which desyncs the daemon's parser and spams
-- "Expected <key>=<value>" errors (KiwiDesk issue #24). drawing=false
-- keeps the previous (undrawn) appearance; set it true for a bg.
SBAR.add("bracket", "volume.bracket", {
	volume_icon.name,
	volume_slider.name,
}, {
	background = { drawing = false },
})

volume_slider:subscribe("mouse.clicked", function(env)
	SBAR.exec("osascript -e 'set volume output volume " .. env["PERCENTAGE"] .. "'")
end)

volume_slider:subscribe("volume_change", function(env)
	-- INFO is empty for some devices (e.g. a muted HDMI output).
	local volume = tonumber(env.INFO)
	if not volume then
		return
	end
	local icon = icons._0
	if volume > 60 then
		icon = icons._100
	elseif volume > 30 then
		icon = icons._66
	elseif volume > 10 then
		icon = icons._33
	elseif volume > 0 then
		icon = icons._10
	end

	volume_icon:set({ icon = icon })
	volume_slider:set({ slider = { percentage = volume } })
end)

local function animate_slider_width(width)
	-- Run the animation
	SBAR.animate("tanh", 30.0, function()
		volume_slider:set({
			slider = { width = width },
		})
	end)
end

-- 6. THE AUTO-CLOSE LOGIC
-- When mouse leaves the slider, wait 0.1 second then check if we should close
volume_slider:subscribe("mouse.exited", function()
	SBAR.delay(0.1, function()
		animate_slider_width(0)
	end)
end)

-- Expand on hover over icon (Optional, but makes it feel native)
-- Expand on hover over icon (Left Click) | Open Settings (Right Click)
volume_icon:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "right" then
		SBAR.exec("open /System/Library/PreferencePanes/Sound.prefPane")
	else
		animate_slider_width(100)
	end
end)

THEME.on_change(function()
	volume_slider:set({
		slider = {
			highlight_color = COLORS.accent_color,
			background = { color = LOOK.with_alpha(COLORS.disabled_color, 0x40) },
		},
	})
end)

-- Scroll on the icon or the slider: volume up/down in 5% steps (the
-- slider and icon follow through volume_change).
local function on_scroll(env)
	local delta = tonumber(env.SCROLL_DELTA) or 0
	if delta == 0 then
		return
	end
	local step = delta > 0 and 5 or -5
	SBAR.exec("osascript -e 'set volume output volume ((output volume of (get volume settings)) + " .. step .. ")'")
end
volume_icon:subscribe("mouse.scrolled", on_scroll)
volume_slider:subscribe("mouse.scrolled", on_scroll)
