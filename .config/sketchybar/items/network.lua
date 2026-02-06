-- 1. Configuration
local interface = "en0"

-- 2. Helper to format (kbps vs Mbps)
local function format_speed(speed_val)
	local speed = tonumber(speed_val) or 0
	if speed > 999 then
		return string.format("%.0f Mbps", speed / 1000)
	else
		return string.format("%.0f kbps", speed)
	end
end

-- 3. Create the Items (Stacked)

-- Network Up (Top Layer)
local network_up = SBAR.add("item", "network_up", {
	position = "right",
	width = 0, -- Allows stacking
	update_freq = 2, -- Frequency in seconds
	y_offset = 4,
	background = { drawing = false },
	label = {
		font = { family = "SF Pro", style = "Heavy", size = 8.0 },
		string = "0 kbps",
		align = "right",
		width = 50, -- FIXED WIDTH: Prevents shifting
	},
	icon = {
		font = { family = "SF Pro", style = "Heavy", size = 8.0 },
		string = "􀄨",
		color = COLORS.disabled_color,
		highlight_color = COLORS.accent_color,
		padding_right = 0,
	},
})

-- Network Down (Bottom Layer)
local network_down = SBAR.add("item", "network_down", {
	position = "right",
	y_offset = -4,
	background = { drawing = false },
	label = {
		font = { family = "SF Pro", style = "Heavy", size = 8.0 },
		string = "0 kbps",
		align = "right",
		width = 50, -- FIXED WIDTH: Matches the top item
	},
	icon = {
		font = { family = "SF Pro", style = "Heavy", size = 8.0 },
		string = "􀄩",
		color = COLORS.disabled_color,
		highlight_color = COLORS.accent_color,
	},
})

-- 4. Create the Bracket (The Single Shared Background)
SBAR.add("bracket", "network.bracket", {
	network_up.name,
	network_down.name,
}, {
	background = {},
})

-- 5. Update Function
local function network_update()
	SBAR.exec("ifstat -i " .. interface .. " -b 0.1 1 | tail -n1", function(result)
		local down, up = result:match("(%d+%.?%d*)%s+(%d+%.?%d*)")
		down = tonumber(down) or 0
		up = tonumber(up) or 0

		network_down:set({
			label = { string = format_speed(down) },
			icon = { highlight = (down > 0) },
		})

		network_up:set({
			label = { string = format_speed(up) },
			icon = { highlight = (up > 0) },
		})
	end)
end

-- 6. Subscription
network_up:subscribe("routine", network_update)
