-- ==========================================================
-- CPU INDICATOR
-- ==========================================================

local core_count = 1 -- default fallback
local handle = io.popen("sysctl -n machdep.cpu.thread_count")
if handle then
	local result = handle:read("*a")
	core_count = tonumber(result) or 1
	handle:close()
end

local cpu = SBAR.add("item", "cpu", {
	position = "left",
	update_freq = 2,
	icon = "􀧓",
})

local function cpu_update()
	SBAR.exec("ps -A -o %cpu | awk '{s+=$1} END {print s}'", function(total_load)
		local load = tonumber(total_load) or 0
		local used = math.floor(load / core_count)
		local color = (used > 80 and 0xffff4444) or (used > 60 and 0xffffa500) or nil
		cpu:set({
			icon = { color = color or DEFAULT_ITEM.icon.color },
			label = { string = math.floor(used) .. "%", color = color or DEFAULT_ITEM.label.color },
		})
	end)
end

cpu:subscribe("routine", cpu_update)

-- ==========================================================
-- RAM / MEMORY INDICATOR
-- ==========================================================

local memory = SBAR.add("item", "memory", {
	position = "left",
	update_freq = 5,
	icon = "􀫦",
})

local function memory_update()
	SBAR.exec("memory_pressure | grep 'System-wide memory free percentage:' | awk '{print 100-$5}'", function(result)
		local used = tonumber(result) or 0
		local color = (used > 80 and 0xffff4444) or (used > 60 and 0xffffa500) or nil
		memory:set({
			icon = { color = color or DEFAULT_ITEM.icon.color },
			label = { string = math.floor(used) .. "%", color = color or DEFAULT_ITEM.label.color },
		})
	end)
end

memory:subscribe("routine", memory_update)

-- ==========================================================
-- NETWORK INDICATOR (Stacked Up/Down)
-- ==========================================================

-- 1. Configuration
local interface = "en0" -- WiFi usually en0, Ethernet might be en1
local popup_width = 50 -- Fixed width to prevent jitter when numbers change
local position = "left"

-- 2. Helper: Format speed (kbps vs Mbps)
local function format_speed(speed_val)
	local speed = tonumber(speed_val) or 0
	if speed > 999 then
		return string.format("%4.0f Mbps", speed / 1000)
	else
		return string.format("%4.0f kbps", speed)
	end
end

-- 3. Create Network Items
-- Top Layer: Upload Speed
local network_up = SBAR.add("item", "network_up", {
	position = position,
	width = 0, -- Width 0 allows it to overlap with the item below it
	update_freq = 2,
	y_offset = 5, -- Shift Up
	label = {
		font = { style = "Heavy", size = DEFAULT_ITEM.label.font.size / 2 },
		string = "   0 kbps",
		width = popup_width,
	},
	icon = {
		font = { family = "SF Pro", style = "Heavy", size = DEFAULT_ITEM.icon.font.size / 2 },
		string = "􀄨",
		color = COLORS.disabled_color,
		highlight_color = COLORS.accent_color,
	},
})

-- Bottom Layer: Download Speed
local network_down = SBAR.add("item", "network_down", {
	position = position,
	y_offset = -5, -- Shift Down
	label = {
		font = { style = "Heavy", size = DEFAULT_ITEM.label.font.size / 2 },
		string = "   0 kbps",
		width = popup_width,
	},
	icon = {
		font = { family = "SF Pro", style = "Heavy", size = DEFAULT_ITEM.icon.font.size / 2 },
		string = "􀄩",
		color = COLORS.disabled_color,
		highlight_color = COLORS.accent_color,
		padding_left = 10,
	},
})

-- 4. Update Logic
local function network_update()
	-- `ifstat` gives us current throughput. -b = simpler output, 0.1 = sample time, 1 = count
	SBAR.exec("ifstat -i " .. interface .. " -b 0.1 1 | tail -n1", function(result)
		local down, up = result:match("(%d+%.?%d*)%s+(%d+%.?%d*)")
		down = tonumber(down) or 0
		up = tonumber(up) or 0

		-- Update Down (Bottom)
		network_down:set({
			label = { string = format_speed(down) },
			icon = { highlight = (down > 0) }, -- Highlight icon if active
		})

		-- Update Up (Top)
		network_up:set({
			label = { string = format_speed(up) },
			icon = { highlight = (up > 0) }, -- Highlight icon if active
		})
	end)
end

network_up:subscribe("routine", network_update)

-- ==========================================================
-- FINAL BRACKET (Unified Background)
-- ==========================================================

-- Wrap CPU, RAM, and Network into one single bracket
SBAR.add("bracket", "resources.bracket", {
	"cpu",
	"memory",
	"network_up", -- Top part of stack
	"network_down", -- Bottom part of stack (defines the width)
}, {
	background = { drawing = true },
})

-- ==========================================================
-- FORCE INITIAL UPDATES
-- ==========================================================
-- Call these immediately so we don't wait 2-5s for the first numbers
cpu_update()
memory_update()
network_update()
