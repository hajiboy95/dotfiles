-- ==========================================================
-- TAILSCALE: state, exit node, and a menu to change them
-- ==========================================================
-- The app-font Tailscale glyph: accent while connected, dimmed
-- otherwise; the exit node's name shows while one routes traffic.
-- Right click connects/disconnects. Left click opens a menu:
-- Connect/Disconnect, Open Settings, then every
-- peer offering an exit node (the active one ticked; clicking it
-- again turns it off).

local app_icon = require("helpers.app_font")
local glyph = app_icon(":tailscale:", "󰖂", DEFAULT_ITEM.icon.font.size)
local max_nodes = 6 -- exit-node rows kept ready in the menu

local tailscale = SBAR.add("item", "tailscale", {
	position = "right",
	update_freq = 15,
	icon = { string = glyph.string, font = glyph.font },
	label = { drawing = false, font = LOOK.word_font() },
	-- Every popup row is one height; there is no per-row size, so
	-- the section is marked by its caption rather than dividers.
	popup = { align = "right", height = 28 },
})

THEME.track_word(tailscale)

local function close_menu()
	tailscale:set({ popup = { drawing = false } })
end

-- Every row carries a tick slot so labels line up. The tick is always
-- drawn, transparent when off: an empty icon string drops its width.
local tick_off = 0x00000000
local function row(name, text)
	local item = SBAR.add("item", "tailscale." .. name, {
		position = "popup." .. tailscale.name,
		icon = {
			string = "✓",
			color = tick_off,
			width = 18,
			padding_left = DEFAULT_ITEM.icon.padding_left,
			padding_right = 0,
		},
		label = {
			string = text,
			font = LOOK.word_font(),
			width = 130, -- equal rows: the hover highlight spans the menu
			padding_left = 2,
			padding_right = DEFAULT_ITEM.icon.padding_right,
		},
	})
	THEME.track_word(item)
	item:subscribe("mouse.entered", function()
		item:set({ background = { drawing = true, color = 0x33ffffff } })
	end)
	item:subscribe("mouse.exited", function()
		item:set({ background = { drawing = false } })
	end)
	return item
end

local toggle_row = row("toggle", "Connect")
local open_row = row("open", "Open Settings…")
-- Section caption: no hover, no click.
local exits_header = SBAR.add("item", "tailscale.exit_header", {
	position = "popup." .. tailscale.name,
	icon = { drawing = false },
	label = {
		string = "EXIT NODE",
		color = COLORS.disabled_color,
		font = LOOK.word_font(0.75),
		-- Flush left, ahead of the rows: a section header.
		padding_left = DEFAULT_ITEM.icon.padding_left,
	},
})
THEME.track_word(exits_header, 0.75)
local node_rows = {}
for i = 1, max_nodes do
	node_rows[i] = row("exit_" .. i, "")
	node_rows[i]:set({ drawing = false })
end

local state = { up = false, nodes = {}, active = "" }

local function run(command)
	close_menu()
	SBAR.exec(command .. " >/dev/null 2>&1; sketchybar --trigger tailscale_refresh")
end

local function render()
	tailscale:set({
		drawing = true,
		icon = {
			-- Switched on = engaged, like a running timer: accent.
			color = state.up and COLORS.accent_color or COLORS.disabled_color,
			padding_right = (state.up and state.active ~= "") and 4 or DEFAULT_ITEM.icon.padding_right,
		},
		-- The chosen exit node: accent, with the icon.
		label = {
			drawing = state.up and state.active ~= "",
			string = state.active,
			color = COLORS.accent_color,
		},
	})
	toggle_row:set({ label = { string = state.up and "Disconnect" or "Connect" } })
	local show_exits = state.up and #state.nodes > 0
	exits_header:set({ drawing = show_exits })
	for i, item in ipairs(node_rows) do
		local node = state.nodes[i]
		if show_exits and node then
			item:set({
				drawing = true,
				icon = { color = node.host == state.active and DEFAULT_ITEM.label.color or tick_off },
				label = {
					string = node.host,
					color = node.online and DEFAULT_ITEM.label.color or COLORS.disabled_color,
				},
			})
		else
			item:set({ drawing = false })
		end
	end
end

-- Python prints "<state>|<active exit host>", then "<host>|<ip>|<online>"
-- per peer that offers an exit node.
local function update()
	SBAR.exec(
		[[command -v tailscale >/dev/null && tailscale status --json 2>/dev/null | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    print("Missing|"); sys.exit()
peers = list((d.get("Peer") or {}).values())
active = next((p.get("HostName", "") for p in peers if p.get("ExitNode")), "")
print((d.get("BackendState") or "Stopped") + "|" + active)
for p in peers:
    if p.get("ExitNodeOption"):
        ip = (p.get("TailscaleIPs") or [""])[0]
        print(p.get("HostName", "") + "|" + ip + "|" + ("1" if p.get("Online") else "0"))' || echo 'Missing|']],
		function(result)
			local first, rest = result:match("^([^\n]*)\n?(.*)$")
			local backend, active = (first or ""):match("^(%w+)|(.*)$")
			if not backend or backend == "Missing" then
				tailscale:set({ drawing = false })
				return
			end
			state.up = backend == "Running"
			state.active = active or ""
			state.nodes = {}
			for host, ip, online in (rest or ""):gmatch("([^|\n]+)|([^|\n]*)|(%d)") do
				table.insert(state.nodes, { host = host, ip = ip, online = online == "1" })
			end
			render()
		end
	)
end

local function toggle_connection()
	if state.up then
		run("tailscale down")
	else
		-- `up` refuses if the last `up` used flags it does not repeat;
		-- the app then takes over.
		run("tailscale up || open -a Tailscale")
	end
end
toggle_row:subscribe("mouse.clicked", toggle_connection)
for i, item in ipairs(node_rows) do
	item:subscribe("mouse.clicked", function()
		local node = state.nodes[i]
		if not node then
			return
		end
		-- The ticked node again: route directly instead.
		local target = node.host == state.active and "" or node.ip
		run("tailscale set --exit-node=" .. target)
	end)
end
open_row:subscribe("mouse.clicked", function()
	close_menu()
	SBAR.exec("open -a Tailscale")
end)

SBAR.add("event", "tailscale_refresh")
tailscale:subscribe({ "routine", "system_woke", "tailscale_refresh" }, update)
-- Left click: the menu. Right click: connect/disconnect at once,
-- like the pomodoro's right-click start/stop.
tailscale:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "right" then
		toggle_connection()
		return
	end
	local open = tailscale:query().popup.drawing == "on"
	tailscale:set({ popup = { drawing = not open } })
	if not open then
		update()
	end
end)
tailscale:subscribe("mouse.exited.global", close_menu)
update()

THEME.on_change(function()
	exits_header:set({ label = { color = COLORS.disabled_color } })
	-- The theme pass sets every icon to the text colour; these ticks
	-- are alignment-only and stay invisible.
	for _, item in ipairs({ toggle_row, open_row }) do
		item:set({ icon = { color = tick_off } })
	end
	render()
end)
