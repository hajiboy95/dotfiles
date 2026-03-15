local icon_map = require("helpers.icon_map")

-- ==========================================================
-- STATE
-- ==========================================================
local spaces_store = {} -- keyed by workspace_id
local space_item_list = {} -- for the bracket
local workspace_order = {} -- keeps insertion order for padding logic

local current_focused_workspace = nil
local WINDOW_SPAWN_DELAY = 0.5 -- seconds until macOS registers a newly spawned window in list-windows

-- ==========================================================
-- 1. AEROSPACE MODE INDICATOR
-- ==========================================================
SBAR.add("event", "aerospace_workspace_change")
SBAR.add("event", "aerospace_mode_change")

local mode_indicator = SBAR.add("item", "aerospace_mode", {
	position = "left",
	icon = { string = "", padding_right = 0 },
	background = { drawing = true },
	drawing = false,
})

local function update_mode_display(mode)
	local parsed = mode:gsub("^%s*(.-)%s*$", "%1")
	local active = (parsed ~= "main" and parsed ~= "")
	mode_indicator:set({ drawing = active, label = { drawing = active } })
end

mode_indicator:subscribe("aerospace_mode_change", function(env)
	update_mode_display(env.INFO or "")
end)

SBAR.exec("aerospace list-modes --current", function(mode)
	update_mode_display(mode)
end)

-- ==========================================================
-- HELPERS
-- ==========================================================

-- Padding: only the last visible item gets default padding.
local function refresh_all_paddings()
	local last_visible_id = nil
	for _, id in ipairs(workspace_order) do
		local d = spaces_store[id]
		if d and d.should_show then
			last_visible_id = id
		end
	end

	for id, data in pairs(spaces_store) do
		if data.should_show then
			local padding = (id == last_visible_id) and DEFAULT_ITEM.label.padding_right or 0
			data.item:set({ label = { padding_right = padding } })
		end
	end
end

-- Draw (or hide) one workspace item given pre-fetched info.
local function apply_space(workspace_id, icon_strip, is_focused, monitor_id)
	local data = spaces_store[workspace_id]
	if not data then
		return
	end

	local has_content = (icon_strip ~= "")
	local should_show = has_content or is_focused

	-- Always update cache so refresh_all_paddings() is accurate.
	local changed = (
		data.should_show ~= should_show
		or data.icon_strip ~= icon_strip
		or data.is_focused ~= is_focused
		or data.monitor_id ~= monitor_id
	)

	data.should_show = should_show
	data.icon_strip = icon_strip
	data.is_focused = is_focused
	data.monitor_id = monitor_id

	if not changed then
		-- Nothing visual changed for this item, but paddings may still need fixing.
		refresh_all_paddings()
		return
	end

	if not should_show then
		data.item:set({ drawing = false })
		refresh_all_paddings()
		return
	end

	local label_icon = icon_strip
	if is_focused and label_icon == "" then
		label_icon = "􀍼"
	end

	data.item:set({
		display = monitor_id,
		drawing = true,
		icon = {
			string = workspace_id,
			color = is_focused and COLORS.accent_color or COLORS.disabled_color,
			font = { size = DEFAULT_ITEM.icon.font.size * 1.1 },
			padding_right = DEFAULT_ITEM.icon.padding_right * 0.5,
		},
		label = {
			string = label_icon,
			color = is_focused and COLORS.accent_color or COLORS.disabled_color,
			drawing = true,
			font = { family = "sketchybar-app-font", style = "Regular", size = DEFAULT_ITEM.label.font.size * 1.1 },
			y_offset = 1,
		},
	})

	refresh_all_paddings()
end

-- Fetch window list for one workspace, then call apply_space.
local function fetch_and_apply(workspace_id)
	if not APPLICATION_MENU_COLLAPSED then
		return
	end

	local focused = current_focused_workspace
	if not focused then
		return
	end -- still waiting for init

	local is_focused = (focused == workspace_id)
	local cmd = "aerospace list-windows --workspace "
		.. workspace_id
		.. " --format '%{app-name}|%{monitor-appkit-nsscreen-screens-id}'"

	SBAR.exec(cmd, function(windows)
		local icon_strip = ""
		local monitor_id = "1"

		for line in windows:gmatch("[^\r\n]+") do
			local app, mid = line:match("^(.*)|(.-)$")
			if app and app ~= "" then
				icon_strip = icon_strip .. (icon_map[app] or icon_map["Default"] or "􀔆")
				if mid and mid ~= "" then
					monitor_id = mid
				end
			end
		end

		apply_space(workspace_id, icon_strip, is_focused, monitor_id)
	end)
end

-- ==========================================================
-- CENTRAL DISPATCHER
-- One single place that decides what to refresh and when.
-- ==========================================================
local global_close_timer = nil -- debounce for window-close events

local function dispatch_update(event_name, focused_workspace)
	-- Keep global focus state in sync.
	if focused_workspace then
		current_focused_workspace = focused_workspace
	end

	if event_name == "space_windows_change" then
		-- Window spawn/close: macOS doesn't immediately reflect the new state in list-windows.
		-- Delay ALL workspace refreshes until macOS has caught up with the new window state.
		if global_close_timer then
			SBAR.delay_cancel(global_close_timer)
		end
		global_close_timer = SBAR.delay(WINDOW_SPAWN_DELAY, function()
			global_close_timer = nil
			for _, id in ipairs(workspace_order) do
				fetch_and_apply(id)
			end
		end)
	else
		-- Immediate: workspace switch, front-app switch, display change.
		-- Cancel any pending close timer so it doesn't fire on stale data.
		if global_close_timer then
			SBAR.delay_cancel(global_close_timer)
			global_close_timer = nil
		end
		for _, id in ipairs(workspace_order) do
			fetch_and_apply(id)
		end
	end
end

-- ==========================================================
-- 3. CREATE WORKSPACE ITEMS
-- ==========================================================
local handle = io.popen("aerospace list-workspaces --all")

if handle then
	local workspaces = handle:read("*a")
	handle:close()

	for workspace_id in workspaces:gmatch("[^\r\n]+") do
		table.insert(workspace_order, workspace_id)

		local space = SBAR.add("item", "space." .. workspace_id, {
			position = "left",
			icon = { string = workspace_id },
			drawing = false,
		})

		table.insert(space_item_list, space.name)

		spaces_store[workspace_id] = {
			item = space,
			should_show = false,
			icon_strip = "",
			is_focused = false,
			monitor_id = "1",
		}

		-- ── Single shared subscriber per space item ──
		-- We only use the space item for click + hover; ALL event routing
		-- goes through ONE dedicated item below (dispatcher_item).
		space:subscribe("mouse.clicked", function()
			SBAR.exec("aerospace workspace " .. workspace_id)
		end)

		space:subscribe({ "mouse.entered", "mouse.exited" }, function(env)
			if not APPLICATION_MENU_COLLAPSED then
				return
			end
			local is_entering = (env.SENDER == "mouse.entered")
			local is_this_focused = (workspace_id == current_focused_workspace)
			if not is_this_focused then
				space:set({
					icon = { color = is_entering and COLORS.accent_color or COLORS.disabled_color },
					label = { color = is_entering and COLORS.accent_color or COLORS.disabled_color },
				})
			end
		end)
	end
end

-- ==========================================================
-- 4. CENTRAL EVENT DISPATCHER ITEM (replaces per-item subs)
-- ==========================================================
local dispatcher = SBAR.add("item", "spaces.dispatcher", { drawing = false })

dispatcher:subscribe("aerospace_workspace_change", function(env)
	local new_focus = env.FOCUSED_WORKSPACE

	-- Bounce animation only for the newly focused space.
	if new_focus then
		local data = spaces_store[new_focus]
		if data then
			SBAR.animate("sin", 10, function()
				data.item:set({ y_offset = 6 })
				SBAR.animate("sin", 10, function()
					data.item:set({ y_offset = 0 })
				end)
			end)
		end
	end

	dispatch_update("aerospace_workspace_change", new_focus)
end)

dispatcher:subscribe({ "space_windows_change", "front_app_switched", "display_change" }, function(env)
	dispatch_update(env.SENDER, nil)
end)

-- ==========================================================
-- 5. SPACE SEPARATOR
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
-- 6. FRONT APP (Integrated)
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
-- 7. BRACKET
-- ==========================================================
local spaces_bracket = SBAR.add("bracket", space_item_list, {
	background = { drawing = true },
})

-- ==========================================================
-- 8. FRONT APP UPDATER
-- ==========================================================
local is_app_focused = false

local function update_front_app()
	SBAR.exec("aerospace list-windows --focused --format '%{app-name}'", function(app_name)
		local name = app_name:gsub("\n", "")
		is_app_focused = (name ~= "")

		if is_app_focused then
			front_app:set({
				drawing = true,
				icon = { string = icon_map[name] or icon_map["Default"] or "APP" },
				label = { string = name },
			})
			if APPLICATION_MENU_COLLAPSED then
				space_separator:set({ drawing = true })
			end
		else
			front_app:set({ drawing = false })
			space_separator:set({ drawing = false })
		end
	end)
end

-- Same delay: front app may not yet reflect the newly focused window at event time.
front_app:subscribe("space_windows_change", function()
	SBAR.delay(WINDOW_SPAWN_DELAY, update_front_app)
end)
front_app:subscribe({ "aerospace_workspace_change", "front_app_switched" }, function()
	update_front_app()
end)

-- ==========================================================
-- 9. SWAP CONTROLLER (Curtain / Fade Effect)
-- ==========================================================
local swap_manager = SBAR.add("item", { drawing = false })

SBAR.add("event", "fade_in_spaces")
SBAR.add("event", "fade_out_spaces")

swap_manager:subscribe("fade_in_spaces", function()
	SBAR.exec("aerospace list-workspaces --focused", function(focused_name)
		focused_name = focused_name:gsub("\n", "")

		-- Reset widths/colors first.
		for _, data in pairs(spaces_store) do
			if data.should_show then
				data.item:set({ width = 0, icon = { color = 0x00000000 }, label = { color = 0x00000000 } })
			end
		end
		if is_app_focused then
			front_app:set({ width = 0, icon = { color = 0x00000000 }, label = { color = 0x00000000 } })
		end

		-- Animate in.
		SBAR.animate("tanh", APPLICATION_MENU_TRANSITION_FRAMES, function()
			spaces_bracket:set({ background = { drawing = true } })

			for id, data in pairs(spaces_store) do
				if data.should_show then
					local color = (id == focused_name) and COLORS.accent_color or COLORS.disabled_color
					data.item:set({ width = "dynamic", icon = { color = color }, label = { color = color } })
				end
			end

			space_separator:set({ drawing = is_app_focused })

			if is_app_focused then
				front_app:set({ width = "dynamic", icon = { color = 0xffffffff }, label = { color = 0xffffffff } })
			end
		end)
	end)
end)

swap_manager:subscribe("fade_out_spaces", function()
	SBAR.animate("tanh", APPLICATION_MENU_TRANSITION_FRAMES, function()
		spaces_bracket:set({ background = { drawing = false } })

		for _, data in pairs(spaces_store) do
			if data.should_show then
				data.item:set({
					width = 0,
					icon = { color = COLORS.transparent },
					label = { color = COLORS.transparent },
				})
			end
		end

		space_separator:set({ drawing = false })
		front_app:set({ width = 0, icon = { color = COLORS.transparent }, label = { color = COLORS.transparent } })
	end)
end)

-- ==========================================================
-- 10. INITIAL LOAD
-- ==========================================================
-- Fetch focused workspace ONCE, then do a single pass over all spaces.
SBAR.exec("aerospace list-workspaces --focused", function(f)
	current_focused_workspace = f:gsub("\n", "")
	for _, id in ipairs(workspace_order) do
		fetch_and_apply(id)
	end
end)

update_front_app()
