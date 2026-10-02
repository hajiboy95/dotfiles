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

-- CPU and GPU draw as live graphs (one sample per tick, 0..1) with
-- the current percentage beside them. GPU load is ioreg's "Device
-- Utilization %" of the Apple GPU: no sudo, ~20 ms a read.
local graph_width = 140

-- CPU, GPU and RAM as compact "icon NN%" items in the bar. A click on
-- any of them opens a popup (like the pomodoro's) with a line graph
-- per metric (one sample per tick, 0..1); the graphs record while the
-- popup is closed, so they open with history. GPU load is ioreg's
-- "Device Utilization %" of the Apple GPU: no sudo, ~20 ms a read.
local popup_anchor = "cpu"

local function load_color(used)
	return (used > 80 and COLORS.red) or (used > 60 and COLORS.orange) or nil
end

local metrics = {}

local function add_metric(name, icon, update_freq, command, parse)
	local compact = SBAR.add("item", name, {
		position = "left",
		icon = { string = icon, padding_right = DEFAULT_ITEM.icon.padding_right * 0.5 },
		label = { string = "0%", padding_right = 0 },
	})
	local graph = SBAR.add("graph", name .. ".graph", graph_width, {
		position = "popup." .. popup_anchor,
		graph = {
			color = COLORS.accent_color,
			fill_color = 0x00000000, -- line only, no filled area
			line_width = 1.5,
		},
		-- The graph spans the icon's own band, centred on its line, so
		-- 0% sits level with the icon's bottom and 100% with its top.
		background = {
			height = 16,
			y_offset = DEFAULT_ITEM.icon.y_offset,
			drawing = true,
			color = 0x00000000,
			border_width = 0,
		},
		icon = { string = icon, padding_left = 10, padding_right = 6 },
		label = {
			string = "0%",
			padding_left = 6,
			padding_right = 10,
			width = 44,
			align = "right",
		},
	})

	local function update()
		SBAR.exec(command, function(result)
			local used = math.max(0, math.min(parse(result), 100))
			local color = load_color(used)
			local icon_color = color or DEFAULT_ITEM.icon.color
			local label = { string = math.floor(used) .. "%", color = color or DEFAULT_ITEM.label.color }
			graph:push({ used / 100 })
			compact:set({ icon = { color = icon_color }, label = label })
			graph:set({ icon = { color = icon_color }, label = label })
		end)
	end

	-- One clock per metric, on the compact item: it ticks whether or
	-- not the graph is drawn.
	compact:set({ update_freq = update_freq })
	compact:subscribe("routine", update)
	table.insert(metrics, { compact = compact, graph = graph, update = update })
	return compact, graph
end

local function toggle_popup()
	local anchor = metrics[1].compact
	local open = anchor:query().popup.drawing == "on"
	anchor:set({ popup = { drawing = not open } })
end

add_metric("cpu", "􀧓", 2, "ps -A -o %cpu | awk '{s+=$1} END {print s}'", function(r)
	return (tonumber(r) or 0) / core_count
end)
add_metric(
	"gpu",
	"󰢮",
	2,
	[[ioreg -r -d 1 -c IOAccelerator | grep -o '"Device Utilization %"=[0-9]*' | head -1 | cut -d= -f2]],
	function(r)
		return tonumber(r) or 0
	end
)
add_metric(
	"memory",
	"􀫦",
	5,
	"memory_pressure | grep 'System-wide memory free percentage:' | awk '{print 100-$5}'",
	function(r)
		return tonumber(r) or 0
	end
)

metrics[1].compact:set({ popup = { align = "left" } })
-- Click, not hover: sketchybar reports leaving the bar but not
-- leaving a popup, so a hover-opened popup left downward stays open.
for _, m in ipairs(metrics) do
	m.compact:subscribe("mouse.clicked", toggle_popup)
	m.graph:subscribe("mouse.clicked", toggle_popup)
end
metrics[1].compact:subscribe("mouse.exited.global", function()
	metrics[1].compact:set({ popup = { drawing = false } })
end)

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
local pad_r = 4
local arrow_shift = pad_r * 0.75
-- Top Layer: Upload Speed
local network_up = SBAR.add("item", "network_up", {
	position = position,
	width = 0, -- Width 0 allows it to overlap with the item below it
	update_freq = 2,
	y_offset = 5, -- Shift Up
	label = {
		font = { size = DEFAULT_ITEM.label.font.size * 0.75 },
		string = "0 kbps",
		width = popup_width,
	},
	icon = {
		font = { size = DEFAULT_ITEM.icon.font.size * 0.75 },
		string = "",
		color = COLORS.disabled_color,
		highlight_color = COLORS.accent_color,
		padding_right = pad_r,
	},
})

-- Bottom Layer: Download Speed
local network_down = SBAR.add("item", "network_down", {
	position = position,
	y_offset = -5, -- Shift Down
	label = {
		font = { size = DEFAULT_ITEM.label.font.size * 0.75 },
		string = "   0 kbps",
		width = popup_width,
	},
	icon = {
		font = { size = DEFAULT_ITEM.icon.font.size * 0.75 },
		string = "",
		color = COLORS.disabled_color,
		highlight_color = COLORS.accent_color,
		padding_left = DEFAULT_ITEM.icon.padding_left + arrow_shift,
		padding_right = pad_r - arrow_shift,
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
	"gpu",
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
for _, m in ipairs(metrics) do
	m.update()
end
network_update()

THEME.on_change(function()
	for _, m in ipairs(metrics) do
		m.graph:set({ graph = { color = COLORS.accent_color } })
		m.update()
	end
	for _, item in ipairs({ network_up, network_down }) do
		item:set({ icon = { color = COLORS.disabled_color, highlight_color = COLORS.accent_color } })
	end
end)
