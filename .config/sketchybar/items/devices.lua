-- ==========================================================
-- BLUETOOTH DEVICE BATTERIES
-- ==========================================================
-- Connected devices that report a battery, by kind (headphones,
-- mouse, keyboard, speaker); earbuds count their lowest bud. Sits
-- beside the Mac's battery; hidden when none is connected. Polled
-- every 10 s (system_profiler ~0.1 s).

local glyphs = {
	Headphones = "󰋋",
	Headset = "󰋎",
	Mouse = "󰍽",
	Keyboard = "󰌌",
	Speaker = "󰓃",
	Gamepad = "󰊗",
}
local fallback_glyph = "󰂯" -- Bluetooth

local devices = SBAR.add("item", "devices", {
	position = "right",
	update_freq = 10, -- macOS sends no connect event; poll
	drawing = false,
	icon = { drawing = false },
	label = { padding_left = DEFAULT_ITEM.icon.padding_left },
})

-- Collapsed: one device shows its glyph, several fold into one
-- Bluetooth glyph. Hover expands to every device with its percentage.
-- Low devices (<= 20%) replace the folded glyph, each with its
-- percentage, in red.
local readings, hovering = {}, false

local function entry(r)
	return r.glyph .. " " .. r.pct .. "%"
end

local function render()
	if #readings == 0 then
		devices:set({ drawing = false })
		return
	end
	local parts, low = {}, false
	for _, r in ipairs(readings) do
		low = low or r.pct <= 20
	end
	if hovering then
		for _, r in ipairs(readings) do
			table.insert(parts, entry(r))
		end
	elseif low then
		-- Only the low devices, each with its percentage: the folded
		-- glyph would say nothing they do not.
		for _, r in ipairs(readings) do
			if r.pct <= 20 then
				table.insert(parts, entry(r))
			end
		end
	else
		table.insert(parts, #readings == 1 and readings[1].glyph or fallback_glyph)
	end
	devices:set({
		drawing = true,
		label = {
			string = table.concat(parts, "  "),
			-- One label has one colour: the hover list stays neutral so
			-- a healthy device never reads red; collapsed, red warns.
			color = (low and not hovering) and COLORS.red or DEFAULT_ITEM.label.color,
		},
	})
end

local function update()
	SBAR.exec(
		[[system_profiler SPBluetoothDataType -json 2>/dev/null | python3 -c '
import json, re, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit()
for ctl in data.get("SPBluetoothDataType", []):
    for dev in ctl.get("device_connected") or []:
        for name, info in dev.items():
            levels = [int(re.sub(r"\D", "", v)) for k, v in info.items()
                      if k.startswith("device_batteryLevel") and k != "device_batteryLevelCase"
                      and re.search(r"\d", str(v))]
            if levels:
                print(info.get("device_minorType", "") + "|" + str(min(levels)))']],
		function(result)
			readings = {}
			for kind, level in result:gmatch("([^|\n]*)|(%d+)") do
				table.insert(readings, { glyph = glyphs[kind] or fallback_glyph, pct = tonumber(level) })
			end
			render()
		end
	)
end

devices:subscribe({ "routine", "system_woke" }, update)
devices:subscribe("mouse.entered", function()
	hovering = true
	render()
end)
devices:subscribe("mouse.exited", function()
	hovering = false
	render()
end)
devices:subscribe("mouse.clicked", function()
	SBAR.exec("open 'x-apple.systempreferences:com.apple.BluetoothSettings'")
end)
update()

THEME.on_change(render)
