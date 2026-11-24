local icon_map = require("helpers.icon_map")

-- ==========================================================
-- KIWIDESK CLI
-- One place for the binary path. sketchybar runs under launchd
-- with a minimal PATH, so every candidate is absolute. Point a
-- dev build at it with a symlink:
--   ln -sfn /path/to/KiwiDesk/.build/release/KiwiDesk \
--     ~/.local/bin/kiwidesk
-- or export KIWIDESK_BIN before sketchybar starts. Once the
-- Homebrew cask ships (1.0) the brew prefix candidate wins on
-- its own.
-- ==========================================================
local KIWIDESK_DEFAULT = os.getenv("HOME") .. "/.local/bin/kiwidesk"

local function resolve_kiwidesk()
	-- Built here rather than as a literal: an unset KIWIDESK_BIN would be a
	-- nil hole that stops ipairs on the first index.
	local candidates = {}
	if os.getenv("KIWIDESK_BIN") then
		candidates[#candidates + 1] = os.getenv("KIWIDESK_BIN")
	end
	candidates[#candidates + 1] = KIWIDESK_DEFAULT
	candidates[#candidates + 1] = "/opt/homebrew/bin/kiwidesk"
	candidates[#candidates + 1] = "/usr/local/bin/kiwidesk"

	for _, candidate in ipairs(candidates) do
		local handle = io.open(candidate, "r")
		if handle then
			handle:close()
			return candidate
		end
	end
	-- Nothing found: return the default so a failure names the binary
	-- instead of concatenating nil.
	return KIWIDESK_DEFAULT
end

local KIWIDESK = resolve_kiwidesk()
local JQ = "/opt/homebrew/bin/jq"

local function kiwidesk_cmd(args)
	return "'" .. KIWIDESK .. "' " .. args
end

-- ==========================================================
-- DEBUG LOGGING (leftover from the #24 investigation)
-- Opt-in only: launch sketchybar with KIWIDESK_DEBUG=1 to
-- write to ~/.config/sketchybar/kiwidesk_debug.log.
-- ==========================================================
local KD_DEBUG = (os.getenv("KIWIDESK_DEBUG") == "1")
local KD_LOG_PATH = os.getenv("HOME") .. "/.config/sketchybar/kiwidesk_debug.log"
local kd_seq = 0
local kd_log_handle = nil
if KD_DEBUG then
	kd_log_handle = io.open(KD_LOG_PATH, "a")
end

local function kd_log(msg)
	if not kd_log_handle then
		return
	end
	kd_seq = kd_seq + 1
	kd_log_handle:write(string.format("%s #%d %s\n", os.date("%H:%M:%S"), kd_seq, msg))
	kd_log_handle:flush()
end

kd_log("=== script (re)loaded ===")

-- ==========================================================
-- STATE
-- ==========================================================
local spaces_store = {}
local space_item_list = {}
local has_data = false
local workspace_names = { "1", "2", "3", "4", "􀖇", "􀫀" }
local current_focused_workspace = "1"
local is_app_focused = false
-- Spaces on show on some screen (every screen's, not only the
-- focused one), so hover and the fade keep them bright.
local shown_workspaces = {}

local function is_on_show(workspace_id)
	return workspace_id == current_focused_workspace or shown_workspaces[workspace_id] == true
end

-- ==========================================================
-- INITIALIZE SPACES VISUALLY
-- ==========================================================
for _, workspace_id in ipairs(workspace_names) do
	local space = SBAR.add("item", "space." .. workspace_id, {
		position = "left",
		icon = { string = workspace_id, color = COLORS.disabled_color },
		label = { drawing = false },
		drawing = true,
	})

	table.insert(space_item_list, space.name)

	local win_items = {}
	spaces_store[workspace_id] = {
		item = space,
		win_items = win_items,
	}

	local function on_click()
		kd_log("on_click focus_space " .. workspace_id)
		os.execute(kiwidesk_cmd("focus_space " .. workspace_id))
	end

	space:subscribe("mouse.clicked", on_click)

	local function on_hover(env)
		if not APPLICATION_MENU_COLLAPSED then
			return
		end
		local is_entering = (env.SENDER == "mouse.entered")
		if not is_on_show(workspace_id) then
			local color = is_entering and COLORS.accent_color or COLORS.disabled_color
			space:set({
				icon = { color = color },
			})
			for _, win_item in ipairs(win_items) do
				win_item:set({
					label = { color = color },
				})
			end
		end
	end

	space:subscribe({ "mouse.entered", "mouse.exited" }, on_hover)

	-- Pre-create 5 window items per space using label (to align perfectly vertically!)
	for i = 1, 5 do
		local win_item = SBAR.add("item", "space." .. workspace_id .. ".win." .. i, {
			position = "left",
			icon = { drawing = false },
			label = {
				string = "",
				font = {
					family = "sketchybar-app-font",
					style = "Regular",
					size = 14.0,
				},
				color = COLORS.disabled_color,
				padding_left = 2,
				padding_right = 2,
			},
			drawing = false,
		})

		table.insert(space_item_list, win_item.name)
		table.insert(win_items, win_item)

		win_item:subscribe("mouse.clicked", on_click)
		win_item:subscribe({ "mouse.entered", "mouse.exited" }, on_hover)
	end
end

-- ==========================================================
-- SPACE SEPARATOR
-- ==========================================================
local space_separator = SBAR.add("item", "space_separator", {
	position = "left",
	label = { drawing = false },
	icon = {
		string = "|",
		padding_left = 0,
		padding_right = DEFAULT_ITEM.icon.padding_right,
	},
})

table.insert(space_item_list, space_separator.name)

-- ==========================================================
-- FRONT APP
-- ==========================================================
local front_app = SBAR.add("item", "front_app", {
	position = "left",
	icon = {
		font = { family = "sketchybar-app-font", style = "Regular", size = DEFAULT_ITEM.icon.font.size * 1.1 },
		padding_right = DEFAULT_ITEM.icon.padding_right * 0.5,
		padding_left = DEFAULT_ITEM.icon.padding_left * 0.5,
	},
	label = { font = { size = DEFAULT_ITEM.label.font.size * 1.1 } },
	drawing = false,
})

table.insert(space_item_list, front_app.name)

-- ==========================================================
-- BRACKET CREATION
-- ==========================================================
local spaces_bracket = SBAR.add("bracket", "spaces.bracket", space_item_list, {
	background = { drawing = true },
})

-- Not in THEME.pills: its pill hides while the app menu is open, and
-- setting a colour would turn it back on.
THEME.on_change(function()
	spaces_bracket:set({
		background = {
			drawing = APPLICATION_MENU_COLLAPSED,
			color = COLORS.background,
			border_color = COLORS.background_border,
		},
	})
end)

-- ==========================================================
-- SCREENS & AREAS
-- Each Space draws on its own screen's bar; on a screen split
-- into areas, each area's Spaces sit together, in the areas'
-- order across the screen, with a gap between areas.
-- ==========================================================
local SKETCHYBAR = "/opt/homebrew/bin/sketchybar"
-- The Space item's own padding_left (default.lua sets none on
-- the item); the area gap replaces it.
local SPACE_PADDING = 0
local AREA_GAP = 12
local last_order = ""

-- KiwiDesk's `display` is the list_monitors id, the same number
-- SketchyBar reports as DirectDisplayID; an item's `display`
-- takes SketchyBar's arrangement-id. Rebuilt on every update,
-- since a screen's id changes when it reconnects.
local function arrangement_ids()
	local ids = {}
	for _, d in ipairs(SBAR.query("displays")) do
		ids[d.DirectDisplayID] = d["arrangement-id"]
	end
	return ids
end

-- Orders the items by screen, then area, then workspace_names,
-- and moves them only when that grouping changes.
local function group_by_area(spaces, arrangement)
	local order = {}
	for i, key in ipairs(workspace_names) do
		local w = spaces[key]
		order[i] = {
			key = key,
			index = i,
			-- A Space on no screen goes last.
			screen = (w and arrangement[w.display]) or math.huge,
			area = (w and w.area) or 0,
		}
	end
	table.sort(order, function(a, b)
		if a.screen ~= b.screen then
			return a.screen < b.screen
		end
		if a.area ~= b.area then
			return a.area < b.area
		end
		return a.index < b.index
	end)

	local names, gaps = {}, {}
	for i, s in ipairs(order) do
		local prev = order[i - 1]
		local new_area = prev ~= nil and prev.screen == s.screen and prev.area ~= s.area
		gaps[i] = new_area and "|" or ""
		table.insert(names, spaces_store[s.key].item.name)
		for _, win_item in ipairs(spaces_store[s.key].win_items) do
			table.insert(names, win_item.name)
		end
	end
	-- The separator and front app stay after the Spaces.
	table.insert(names, "space_separator")
	table.insert(names, "front_app")

	local joined = table.concat(names, " ")
	local grouping = joined .. table.concat(gaps, ",")
	if grouping == last_order then
		return
	end
	for i, s in ipairs(order) do
		spaces_store[s.key].item:set({
			padding_left = SPACE_PADDING + (gaps[i] ~= "" and AREA_GAP or 0),
		})
	end
	-- Remembered only once the reorder ran, so a failed one retries.
	if os.execute(SKETCHYBAR .. " --reorder " .. joined) then
		last_order = grouping
	end
end

-- ==========================================================
-- CONNECTION & UPDATE MANAGEMENT
-- ==========================================================
local function update_spaces()
	kd_log("update_spaces BEGIN (io.popen get_state)")
	local t0 = os.clock()
	-- list_monitors gives each split screen's areas; the filter
	-- writes a Space's area as its place on its screen (0 for the
	-- left or top area, and on a screen that is not split).
	local handle = io.popen(
		kiwidesk_cmd("get_state")
			.. " 2>/dev/null | "
			.. JQ
			.. ' -r --arg mon "$('
			.. kiwidesk_cmd("list_monitors")
			.. ' 2>/dev/null)" '
			.. "'(($mon | fromjson? // []) "
			.. "| map((.areas // []) | sort_by(.y, .x)"
			.. " | to_entries | map({key: .value.key, value: .key}))"
			.. " | add // [] | from_entries) as $place"
			.. ' | .active_space, "---SPACES---", '
			.. '(.spaces[] | "\\(.id):\\(.focused):'
			.. "\\(.shown):\\(.display):"
			.. '\\($place[.area // ""] // 0):'
			.. '\\(.windows | join(","))"), '
			.. '"---WINDOWS---", '
			.. '(.windows[] | "\\(.id):\\(.app):'
			.. "\\(.floating)\")' 2>/dev/null"
	)
	if not handle then
		kd_log("update_spaces ABORT: io.popen returned nil")
		return
	end

	local active_space = handle:read("*l")
	kd_log(string.format("update_spaces active_space=%q (popen cpu=%.4fs)", tostring(active_space), os.clock() - t0))
	if not active_space or active_space == "" then
		handle:close()
		kd_log("update_spaces ABORT: empty active_space")
		return
	end

	local line = handle:read("*l")
	if line ~= "---SPACES---" then
		handle:close()
		kd_log(string.format("update_spaces ABORT: bad marker=%q", tostring(line)))
		return
	end

	has_data = true

	local spaces = {}
	line = handle:read("*l")
	while line and line ~= "---WINDOWS---" do
		local id, focused_win, shown, display, area, windows_str =
			line:match("([^:]+):([^:]*):(%a+):([^:]*):(%d+):(.*)")
		if id then
			local window_ids = {}
			if windows_str and windows_str ~= "" then
				for win_id in windows_str:gmatch("([^,]+)") do
					table.insert(window_ids, tonumber(win_id))
				end
			end
			spaces[id] = {
				focused = tonumber(focused_win),
				shown = (shown == "true"),
				display = tonumber(display),
				area = tonumber(area),
				windows = window_ids,
			}
		end
		line = handle:read("*l")
	end

	local windows = {}
	line = handle:read("*l")
	while line do
		local id, app, floating = line:match("([^:]+):([^:]+):([^:]+)")
		if id and app then
			windows[tonumber(id)] = {
				app = app,
				floating = (floating == "true"),
			}
		end
		line = handle:read("*l")
	end
	handle:close()

	do
		local n_spaces, n_windows = 0, 0
		for _ in pairs(spaces) do
			n_spaces = n_spaces + 1
		end
		for _ in pairs(windows) do
			n_windows = n_windows + 1
		end
		kd_log(string.format("update_spaces END active=%q spaces=%d windows=%d", active_space, n_spaces, n_windows))
	end

	current_focused_workspace = active_space
	local active_app_name = nil
	local arrangement = arrangement_ids()

	for _, ws_name in ipairs(workspace_names) do
		local w = spaces[ws_name]
		local is_focused = (ws_name == active_space)
		shown_workspaces[ws_name] = (w ~= nil and w.shown)
		local on_show = is_on_show(ws_name)
		-- A Space on no screen draws on the focused screen.
		local where = (w and arrangement[w.display]) or "active"
		local space_data = spaces_store[ws_name]

		if space_data then
			space_data.item:set({
				display = where,
				icon = { color = on_show and COLORS.accent_color or COLORS.disabled_color },
			})
			for _, win_item in ipairs(space_data.win_items) do
				win_item:set({ display = where })
			end

			local win_count = 0
			if w and w.windows and #w.windows > 0 then
				for _, win_id in ipairs(w.windows) do
					local win = windows[win_id]
					if win and win_count < 5 then
						win_count = win_count + 1
						local win_item = space_data.win_items[win_count]
						local icon = icon_map[win.app] or icon_map["Default"] or ":default:"

						local icon_color
						if is_focused and w.focused == win_id then
							icon_color = COLORS.space_focused_window or COLORS.secondary_accent or 0xff4E9F3D
						elseif on_show then
							icon_color = COLORS.accent_color
						else
							icon_color = COLORS.disabled_color
						end

						win_item:set({
							label = {
								string = icon,
								color = icon_color,
							},
							drawing = true,
						})

						if is_focused and w.focused == win_id then
							active_app_name = win.app
						end
					end
				end
			end

			for i = win_count + 1, 5 do
				space_data.win_items[i]:set({ drawing = false })
			end
		end
	end

	group_by_area(spaces, arrangement)

	-- Update front focused app
	is_app_focused = (active_app_name and active_app_name ~= "")
	if is_app_focused then
		front_app:set({
			drawing = APPLICATION_MENU_COLLAPSED,
			icon = { string = icon_map[active_app_name] or icon_map["Default"] or "APP" },
			label = { string = active_app_name },
		})
		if APPLICATION_MENU_COLLAPSED then
			space_separator:set({ drawing = true })
		end
	else
		front_app:set({ drawing = false })
		space_separator:set({ drawing = false })
	end
end

-- Subscribe to the KiwiDesk update event. KiwiDesk itself never
-- triggers sketchybar events — hooks in ~/.config/KiwiDesk/
-- init.lua run `sketchybar --trigger kiwidesk_update` on every
-- relevant KiwiDesk event (space/focus/layout/window changes).
SBAR.add("event", "kiwidesk_update")

local event_item = SBAR.add("item", { drawing = false })
event_item:subscribe("kiwidesk_update", function()
	update_spaces()
end)

-- Initial update
update_spaces()

-- Self-heal: on a cold start (sketchybar loads before the
-- KiwiDesk socket is up, e.g. the reload KiwiDesk triggers
-- while its own config is still loading) the initial update
-- fails silently and nothing retries until the next space or
-- focus event. Poll until the first successful read, then
-- stop and go back to being purely event-driven.
local watchdog = SBAR.add("item", { drawing = false, update_freq = 2 })
watchdog:subscribe("routine", function()
	if has_data then
		watchdog:set({ update_freq = 0 })
	else
		update_spaces()
	end
end)

-- ==========================================================
-- SWAP CONTROLLER (Curtain / Fade Effect)
-- ==========================================================
local swap_manager = SBAR.add("item", { drawing = false })

SBAR.add("event", "fade_in_spaces")
SBAR.add("event", "fade_out_spaces")

swap_manager:subscribe("fade_in_spaces", function()
	local handle = io.popen(kiwidesk_cmd("get_state") .. " 2>/dev/null | " .. JQ .. " -r '.active_space' 2>/dev/null")
	if handle then
		local active = handle:read("*l")
		if active and active ~= "" then
			current_focused_workspace = active
		end
		handle:close()
	end

	-- Reset widths/colors first to 0
	for _, data in pairs(spaces_store) do
		data.item:set({ width = 0, icon = { color = 0x00000000 }, label = { color = 0x00000000 } })
		for _, win_item in ipairs(data.win_items) do
			win_item:set({ width = 0, label = { color = 0x00000000 } })
		end
	end
	if is_app_focused then
		front_app:set({ width = 0, icon = { color = 0x00000000 }, label = { color = 0x00000000 } })
	end

	-- Animate in
	SBAR.animate("tanh", APPLICATION_MENU_TRANSITION_FRAMES, function()
		spaces_bracket:set({ background = { drawing = true } })

		for id, data in pairs(spaces_store) do
			local color = is_on_show(id) and COLORS.accent_color or COLORS.disabled_color
			data.item:set({ width = "dynamic", icon = { color = color }, label = { color = color } })
			for _, win_item in ipairs(data.win_items) do
				win_item:set({ width = "dynamic" })
			end
		end

		space_separator:set({ drawing = is_app_focused })

		if is_app_focused then
			front_app:set({ width = "dynamic", icon = { color = 0xffffffff }, label = { color = 0xffffffff } })
		end
	end)
end)

swap_manager:subscribe("fade_out_spaces", function()
	SBAR.animate("tanh", APPLICATION_MENU_TRANSITION_FRAMES, function()
		spaces_bracket:set({ background = { drawing = false } })

		for _, data in pairs(spaces_store) do
			data.item:set({
				width = 0,
				icon = { color = COLORS.transparent },
				label = { color = COLORS.transparent },
			})
			for _, win_item in ipairs(data.win_items) do
				win_item:set({
					width = 0,
					label = { color = COLORS.transparent },
				})
			end
		end

		space_separator:set({ drawing = false })
		front_app:set({ width = 0, icon = { color = COLORS.transparent }, label = { color = COLORS.transparent } })
	end)
end)
